#!/usr/bin/env python3
"""Assemble one queryable view over everything the app emits.

Development only: this attaches the dev database and reads the dev container's
own telemetry. Nothing here is meant to point at a deployed environment.

Sources, none of which is copied or transformed — DuckDB reads them in place:

  model catalog   .mxcli/catalog.db (SQLite, 70 tables)   ATTACH  -> cat.*
  app data        the app's own PostgreSQL                ATTACH  -> pg.*
  traces          OTLP spans from scripts/otlp-collect.py view    -> spans
  metrics         the /prometheus scrape                  view    -> metrics
  logs            .mxcli/runtime.log                      view    -> logs

So a question that spans two of them is one SQL query instead of a script.
Run `mxcli -c "REFRESH CATALOG FULL"` first if you want activities and refs —
plain REFRESH leaves those tables empty.

  scripts/warehouse.py build                 # create the views, report row counts
  scripts/warehouse.py sql "SELECT …"        # ad-hoc query
  scripts/warehouse.py hot-microflows        # canned: cost vs model complexity
  scripts/warehouse.py hot-tables            # canned: query time vs live rows
  scripts/warehouse.py slow-activities       # canned: span time vs model activity
"""
import argparse, json, os, pathlib, re, sys

try:
    import duckdb
except ImportError:
    sys.exit("pip install duckdb")

ROOT = pathlib.Path(__file__).resolve().parent.parent
WH = ROOT / "Sudoku" / ".mxcli" / "warehouse"
PROJECT = os.environ.get("MXCLI_PROJECT", str(ROOT / "Sudoku" / "Sudoku.mpr"))
MXCLI = ROOT / "Sudoku" / "mxcli"
ADMIN = os.environ.get("MXCLI_ADMIN_URL", "http://127.0.0.1:8090")
ADMIN_PASS = os.environ.get("MXCLI_ADMIN_PASS", "mxcli-local-dev")
DB = os.environ.get("MXCLI_DB_NAME", "sudoku")
# The live span file is the one run-app.sh points the collector at. This used to
# default to a snapshot under warehouse/, which still exists from an earlier run —
# so the warehouse silently answered from 2,476 stale spans while 105,613 sat next
# door. Prefer the live file, fall back to the snapshot only if it is absent.
_LIVE_SPANS = ROOT / "Sudoku" / ".mxcli" / "spans.jsonl"
SPANS = os.environ.get(
    "MXCLI_SPANS", str(_LIVE_SPANS if _LIVE_SPANS.exists() else WH / "spans.jsonl"))
CATALOG = os.environ.get("MXCLI_CATALOG", str(ROOT / "Sudoku" / ".mxcli" / "catalog.db"))


def build():
    WH.mkdir(parents=True, exist_ok=True)

    # /prometheus is a text format; parse to JSONL so it joins like a table.
    import urllib.request, base64
    req = urllib.request.Request(f"{ADMIN}/prometheus")
    req.add_header("X-M2EE-Authentication",
                   base64.b64encode(ADMIN_PASS.encode()).decode())
    try:
        text = urllib.request.urlopen(req, timeout=10).read().decode()
    except Exception as e:
        print(f"  metrics unavailable ({e}) — run with --metrics", file=sys.stderr)
        text = ""
    with open(WH / "metrics.jsonl", "w") as fh:
        for line in text.splitlines():
            if line.startswith("#") or not line.strip():
                continue
            m = re.match(r'^([a-zA-Z_:][\w:]*)(\{(.*)\})?\s+(\S+)$', line)
            if not m:
                continue
            labels = dict(re.findall(r'(\w+)="([^"]*)"', m.group(3) or ""))
            fh.write(json.dumps({"metric": m.group(1), "labels": labels,
                                 "value": float(m.group(4))}) + "\n")

    # Runtime log -> JSONL. No trace id is emitted by the runtime, so the only
    # join key to the traces is the timestamp.
    log = ROOT / "Sudoku" / ".mxcli" / "runtime.log"
    with open(WH / "logs.jsonl", "w") as fh:
        if log.exists():
            for line in log.read_text(errors="replace").splitlines():
                m = re.match(r'^(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\.\d+) '
                             r'(\w+) - ([^:]+): (.*)$', line)
                if m:
                    fh.write(json.dumps({"ts": m.group(1), "level": m.group(2),
                                         "node": m.group(3), "message": m.group(4)}) + "\n")

    con = connect()
    print(f"warehouse at {WH / 'warehouse.duckdb'}")
    for t in ("cat.microflows_data", "cat.entities_data", "cat.activities_data",
              "cat.refs", "spans", "metrics", "logs"):
        try:
            n = con.execute(f"SELECT count(*) FROM {t}").fetchone()[0]
            print(f"  {t:<12} {n:>8}")
        except Exception as e:
            print(f"  {t:<12} unavailable ({str(e).splitlines()[0][:60]})")
    try:
        n = con.execute("SELECT count(*) FROM pg.information_schema.tables").fetchone()[0]
        print(f"  {'pg tables':<12} {n:>8}   (live, attached read-only)")
    except Exception as e:
        print(f"  pg           not attached ({str(e).splitlines()[0][:60]})")


def connect():
    con = duckdb.connect(str(WH / "warehouse.duckdb"))
    con.execute("INSTALL postgres; LOAD postgres;")
    try:
        con.execute(f"ATTACH 'host=127.0.0.1 user=mendix password=mendix dbname={DB}' "
                    "AS pg (TYPE postgres, READ_ONLY);")
    except duckdb.Error:
        pass                                   # already attached, or no database
    con.execute("INSTALL sqlite; LOAD sqlite;")
    try:
        con.execute(f"ATTACH '{CATALOG}' AS cat (TYPE sqlite, READ_ONLY);")
    except duckdb.Error:
        pass                                   # already attached, or not built yet

    def view(name, path, extra=""):
        if pathlib.Path(path).exists() and pathlib.Path(path).stat().st_size:
            con.execute(f"CREATE OR REPLACE VIEW {name} AS "
                        f"SELECT *{extra} FROM read_json_auto('{path}')")
    view("metrics", WH / "metrics.jsonl")
    view("logs", WH / "logs.jsonl")
    view("spans", SPANS, extra=', ("end" - "start")/1e6 AS ms')
    return con


HOT_MICROFLOWS = """
SELECT  m.Name AS microflow, count(*) AS calls,
        round(avg(s.ms), 2) AS avg_ms, round(max(s.ms), 2) AS max_ms,
        m.ActivityCount::INT AS activities, m.Complexity::INT AS mccabe
FROM    spans s
JOIN    cat.microflows_data m ON s.attrs."mx.microflow.name" = m.QualifiedName
GROUP BY ALL ORDER BY avg_ms DESC"""

HOT_TABLES = """
SELECT  coalesce(e.Name, '(system)') AS entity,
        lower(s.attrs."db.sql.table") AS tbl,
        s.attrs."db.operation" AS op,
        count(*) AS queries, round(sum(s.ms), 2) AS total_ms
FROM    spans s
LEFT JOIN cat.entities_data e ON lower(e.ModuleName || '$' || e.Name) = lower(s.attrs."db.sql.table")
WHERE   s.scope LIKE 'io.opentelemetry.jdbc%' AND s.attrs."db.sql.table" IS NOT NULL
GROUP BY ALL ORDER BY total_ms DESC"""


SLOW_ACTIVITIES = """
-- Span time per activity type, against how many of that type the model holds.
-- The catalog's activities_data.Id is the model GUID and Sequence is the
-- position, so this can be tightened to a per-activity join.
SELECT  s.attrs."mx.microflow.name"      AS microflow,
        s.name                            AS span,
        count(*)                          AS executions,
        round(sum(s.ms), 2)               AS total_ms,
        (SELECT count(*) FROM cat.activities_data a
          WHERE a.MicroflowQualifiedName = s.attrs."mx.microflow.name") AS activities_in_model
FROM    spans s
WHERE   s.attrs."mx.microflow.name" IS NOT NULL AND s.name NOT LIKE 'Microflow %'
GROUP BY ALL ORDER BY total_ms DESC"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("command", choices=["build", "sql", "hot-microflows",
                                        "hot-tables", "slow-activities"])
    ap.add_argument("query", nargs="?")
    args = ap.parse_args()
    if args.command == "build":
        build()
        return
    con = connect()
    q = {"sql": args.query, "hot-microflows": HOT_MICROFLOWS,
         "hot-tables": HOT_TABLES, "slow-activities": SLOW_ACTIVITIES}[args.command]
    if not q:
        sys.exit("give a query")
    con.sql(q).show(max_rows=40)


if __name__ == "__main__":
    main()
