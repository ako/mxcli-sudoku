#!/usr/bin/env python3
"""Flame chart for one microflow, from OTLP spans captured by otlp-collect.py.

  scripts/flame.py spans.jsonl                       # newest microflow trace
  scripts/flame.py spans.jsonl --flow ACT_SelectCell # a specific one
  scripts/flame.py spans.jsonl --flow ACT_Hint --min-ms 0.5
  scripts/flame.py spans.jsonl --list                # what is in the file

Identical consecutive siblings are folded into one row ("x81"), because a loop
over 81 cells otherwise prints 81 identical lines and hides the shape.
"""
import argparse, json, sys
from collections import defaultdict

BAR = "█"


def load(path):
    spans = []
    with open(path) as fh:
        for line in fh:
            line = line.strip()
            if line:
                spans.append(json.loads(line))
    return spans


def label(s, with_service=False):
    """A readable name: microflow spans carry their qualified name as an attr."""
    n = s.get("name", "?")
    mf = s.get("attrs", {}).get("mx.microflow.name")
    if mf and n.startswith("Microflow "):
        n = f"Microflow {mf}"
    if with_service and s.get("service"):
        n = f"[{s['service']}] {n}"
    return n


def is_db(s):
    return s.get("scope", "").startswith("io.opentelemetry.jdbc")


def build(spans):
    by_id = {s["span_id"]: s for s in spans}
    kids = defaultdict(list)
    for s in spans:
        kids[s.get("parent_id", "")].append(s)
    for lst in kids.values():
        lst.sort(key=lambda s: s["start"])
    return by_id, kids


def fold(children):
    """Collapse runs of same-named siblings into (span, count, total_ns)."""
    out = []
    for c in children:
        if out and label(out[-1][0]) == label(c):
            prev, n, tot = out[-1]
            out[-1] = (prev, n + 1, tot + (c["end"] - c["start"]))
        else:
            out.append((c, 1, c["end"] - c["start"]))
    return out


def services(root, kids):
    out, stack = set(), [root]
    while stack:
        s = stack.pop()
        out.add(s.get("service", ""))
        stack.extend(kids.get(s["span_id"], []))
    return {x for x in out if x}


def render(root, kids, min_ms, width=44, multi=False):
    total = root["end"] - root["start"] or 1
    lines = []

    def walk(span, count, group_ns, depth):
        dur = group_ns
        ms = dur / 1e6
        frac = dur / total
        if ms < min_ms and depth > 0:
            return
        bar = BAR * max(1, round(frac * width))
        name = label(span, with_service=multi)
        if count > 1:
            name += f"  x{count}"
        tag = "  [db]" if is_db(span) else ""
        lines.append(
            f"{'  ' * depth}{name}{tag}".ljust(60)[:60]
            + f"{ms:9.2f}ms {frac * 100:6.1f}%  {bar}"
        )
        # Recurse into the first member of a folded group only; its siblings are
        # the same shape and would triple the output.
        for child, n, tot in fold(kids.get(span["span_id"], [])):
            walk(child, n, tot, depth + 1)

    walk(root, 1, root["end"] - root["start"], 0)
    return lines


def summarize(root, kids, all_spans):
    """Roll up the subtree under root: time in DB, per-microflow, per-activity."""
    subtree = []

    def collect(sid):
        for c in kids.get(sid, []):
            subtree.append(c)
            collect(c["span_id"])

    collect(root["span_id"])
    total = root["end"] - root["start"] or 1

    db = [s for s in subtree if is_db(s)]
    db_ns = sum(s["end"] - s["start"] for s in db)

    flows = [s for s in subtree if s["name"].startswith("Microflow ")]
    acts = defaultdict(lambda: [0, 0])
    for s in subtree:
        if is_db(s) or s["name"].startswith("Microflow "):
            continue
        acts[s["name"]][0] += 1
        acts[s["name"]][1] += s["end"] - s["start"]

    out = [
        f"total                {total / 1e6:9.2f}ms",
        f"database             {db_ns / 1e6:9.2f}ms  {db_ns / total * 100:5.1f}%   ({len(db)} queries)",
        f"sub-microflows       {len(flows)}",
    ]
    if flows:
        for f in flows:
            d = f["end"] - f["start"]
            out.append(f"    {label(f):<40}{d / 1e6:9.2f}ms  {d / total * 100:5.1f}%")
    out.append("activities (by total time)")
    for name, (n, ns) in sorted(acts.items(), key=lambda kv: -kv[1][1])[:8]:
        out.append(f"    {name:<40}{ns / 1e6:9.2f}ms  {n:5d}x")
    if db:
        out.append("queries (by total time)")
        agg = defaultdict(lambda: [0, 0])
        for s in db:
            agg[s["name"]][0] += 1
            agg[s["name"]][1] += s["end"] - s["start"]
        for name, (n, ns) in sorted(agg.items(), key=lambda kv: -kv[1][1])[:8]:
            out.append(f"    {name:<40}{ns / 1e6:9.2f}ms  {n:5d}x")
    return out


def colour(s):
    n = s["name"]
    if is_db(s):                       return "#FF6B6B"   # queries
    if n.startswith("Microflow "):     return "#5FD3C4"   # a flow boundary
    if n.startswith(("Commit", "Change", "CreateAndChange", "ChangeList")):
        return "#F5A623"                                  # writes
    if n.startswith(("Retrieve", "Aggregate")):
        return "#7FB3FF"                                  # reads
    return "#4A5160"                                      # control flow


def html(root, kids, path, multi=False):
    """A self-contained flame chart: nested divs, width proportional to time."""
    total = root["end"] - root["start"] or 1
    rows = []

    def walk(span, depth):
        left = (span["start"] - root["start"]) / total * 100
        width = (span["end"] - span["start"]) / total * 100
        if width < 0.05:
            return
        ms = (span["end"] - span["start"]) / 1e6
        rows.append(
            f'<div class="s" style="left:{left:.4f}%;width:{width:.4f}%;'
            f'top:{depth * 22}px;background:{colour(span)}" '
            f'title="{label(span, with_service=True)} — {ms:.2f}ms">'
            f'<span>{label(span, with_service=multi)}</span></div>'
        )
        for c in kids.get(span["span_id"], []):
            walk(c, depth + 1)

    walk(root, 0)

    def depth_of(sid, d=0):
        ch = kids.get(sid, [])
        return d if not ch else max(depth_of(c["span_id"], d + 1) for c in ch)

    height = (depth_of(root["span_id"]) + 1) * 22 + 10
    with open(path, "w") as fh:
        fh.write(f"""<!doctype html><meta charset="utf-8">
<title>{label(root)} — flame chart</title>
<style>
 body{{background:#0B0D12;color:#E6E9EF;font:13px/1.4 ui-monospace,SFMono-Regular,Menlo,monospace;margin:24px}}
 h1{{font-size:15px;font-weight:600;margin:0 0 4px}}
 .meta{{color:#8B93A7;margin-bottom:16px}}
 .chart{{position:relative;height:{height}px}}
 .s{{position:absolute;height:20px;border-radius:3px;overflow:hidden;
     white-space:nowrap;box-sizing:border-box;padding:0 5px;line-height:20px;
     color:#0B0D12;font-size:11px;border:1px solid rgba(11,13,18,.55)}}
 .s span{{pointer-events:none}}
 .s:hover{{outline:2px solid #fff;z-index:9}}
 .key{{margin-top:18px;color:#8B93A7}} .key i{{display:inline-block;width:10px;height:10px;
     border-radius:2px;margin:0 5px 0 14px;vertical-align:middle;font-style:normal}}
</style>
<h1>{label(root)}</h1>
<div class="meta">{total / 1e6:.2f} ms total &middot; trace {root['trace_id']}</div>
<div class="chart">{''.join(rows)}</div>
<div class="key">width = duration, nesting = call depth
 <i style="background:#5FD3C4"></i>microflow
 <i style="background:#7FB3FF"></i>retrieve
 <i style="background:#F5A623"></i>write
 <i style="background:#FF6B6B"></i>database
 <i style="background:#4A5160"></i>control flow</div>
""")
    return path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("spans")
    ap.add_argument("--flow", default=None, help="microflow name substring")
    ap.add_argument("--min-ms", type=float, default=0.2)
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--root", default=None, help="span id to use as the root")
    ap.add_argument("--html", default=None, help="also write an HTML flame chart here")
    args = ap.parse_args()

    spans = load(args.spans)
    if not spans:
        sys.exit("no spans")
    by_id, kids = build(spans)

    if args.list:
        seen = defaultdict(int)
        for s in spans:
            if s["name"].startswith("Microflow "):
                seen[label(s)] += 1
        for k, v in sorted(seen.items(), key=lambda kv: -kv[1]):
            print(f"{v:5d}  {k}")
        return

    if args.root:
        root = by_id[args.root]
    else:
        cands = [s for s in spans if s["name"].startswith("Microflow ")]
        if args.flow:
            cands = [s for s in cands if args.flow in label(s)]
        if not cands:
            sys.exit(f"no microflow span matching {args.flow!r}")
        # The outermost call: prefer depth 1, then the longest, then the newest.
        cands.sort(key=lambda s: (s.get("attrs", {}).get("mx.microflow.depth", 9),
                                  -(s["end"] - s["start"])))
        root = cands[0]

    svcs = services(root, kids)
    multi = len(svcs) > 1
    print(f"trace {root['trace_id']}   root {label(root)}"
          + (f"   apps: {', '.join(sorted(svcs))}" if multi else ""))
    print("-" * 100)
    for line in render(root, kids, args.min_ms, multi=multi):
        print(line)
    print("-" * 100)
    for line in summarize(root, kids, spans):
        print(line)
    if args.html:
        print(f"\nwrote {html(root, kids, args.html, multi)}")


if __name__ == "__main__":
    main()
