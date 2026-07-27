#!/usr/bin/env python3
"""Assemble one queryable view over everything the app emits.

Four sources that otherwise need four different tools:

  model catalog   mxcli's CATALOG.* (entities, microflows, pages)  -> JSON
  app data        the app's own PostgreSQL                         -> ATTACHed live
  traces          OTLP spans from scripts/otlp-collect.py          -> JSONL
  metrics         the /prometheus scrape                           -> text
  logs            .mxcli/runtime.log                               -> text

DuckDB reads all of them in place — no ETL, no loading step — so a question
that spans two of them is one SQL query instead of a script.

  scripts/warehouse.py build                 # gather sources, create the views
  scripts/warehouse.py sql "SELECT …"        # ad-hoc query
  scripts/warehouse.py hot-microflows        # canned: cost vs model complexity
  scripts/warehouse.py hot-tables            # canned: query time vs live rows
"""
import argparse, json, os, pathlib, re, subprocess, sys

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
SPANS = os.environ.get("MXCLI_SPANS", str(WH / "spans.jsonl"))


def catalog(query, out):
    """mxcli --json still prints human chatter first (a catalog refresh, then
    'Found N result(s)'), so take everything from the opening bracket."""
    mx = str(MXCLI) if MXCLI.exists() else "mxcli"
    r = subprocess.run([mx, "-p", PROJECT, "--json", "-c", query],
                       capture_output=True, text=True)
    i = r.stdout.find("[")
    if i < 0:
        sys.exit(f"no JSON from mxcli for: {query}\n{r.stdout[:300]}{r.stderr[:300]}")
    out.write_text(r.stdout[i:])
    return out


def build():
    WH.mkdir(parents=True, exist_ok=True)
    catalog("SELECT Name, QualifiedName, ModuleName, Folder, ActivityCount, "
            "Complexity, ReturnType FROM CATALOG.MICROFLOWS", WH / "microflows.json")
    catalog("SELECT Name, QualifiedName, ModuleName FROM CATALOG.ENTITIES",
            WH / "entities.json")

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
    for t in ("microflows", "entities", "spans", "metrics", "logs"):
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
    def view(name, path, extra=""):
        if pathlib.Path(path).exists() and pathlib.Path(path).stat().st_size:
            con.execute(f"CREATE OR REPLACE VIEW {name} AS "
                        f"SELECT *{extra} FROM read_json_auto('{path}')")
    view("microflows", WH / "microflows.json")
    view("entities", WH / "entities.json")
    view("metrics", WH / "metrics.jsonl")
    view("logs", WH / "logs.jsonl")
    view("spans", SPANS, extra=', ("end" - "start")/1e6 AS ms')
    return con


HOT_MICROFLOWS = """
SELECT  m.Name AS microflow, count(*) AS calls,
        round(avg(s.ms), 2) AS avg_ms, round(max(s.ms), 2) AS max_ms,
        m.ActivityCount::INT AS activities, m.Complexity::INT AS mccabe
FROM    spans s
JOIN    microflows m ON s.attrs."mx.microflow.name" = m.QualifiedName
GROUP BY ALL ORDER BY avg_ms DESC"""

HOT_TABLES = """
SELECT  coalesce(e.Name, '(system)') AS entity,
        lower(s.attrs."db.sql.table") AS tbl,
        s.attrs."db.operation" AS op,
        count(*) AS queries, round(sum(s.ms), 2) AS total_ms
FROM    spans s
LEFT JOIN entities e ON lower('sudoku$' || e.Name) = lower(s.attrs."db.sql.table")
WHERE   s.scope LIKE 'io.opentelemetry.jdbc%' AND s.attrs."db.sql.table" IS NOT NULL
GROUP BY ALL ORDER BY total_ms DESC"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("command", choices=["build", "sql", "hot-microflows", "hot-tables"])
    ap.add_argument("query", nargs="?")
    args = ap.parse_args()
    if args.command == "build":
        build()
        return
    con = connect()
    q = {"sql": args.query, "hot-microflows": HOT_MICROFLOWS,
         "hot-tables": HOT_TABLES}[args.command]
    if not q:
        sys.exit("give a query")
    con.sql(q).show(max_rows=40)


if __name__ == "__main__":
    main()
