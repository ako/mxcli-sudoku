#!/usr/bin/env python3
"""A minimal OTLP/HTTP trace collector, written for one purpose: flame charts.

The console span exporter prints a name and an id but no timings and no parent,
so it cannot be turned into a flame chart. OTLP carries start/end nanoseconds
and parent_span_id, which is everything a flame chart needs.

Rather than depend on the protobuf runtime, this walks the wire format directly
— OTLP's field numbers are stable and only a handful are needed:

  ExportTraceServiceRequest { resource_spans = 1 }
  ResourceSpans            { scope_spans = 2 }
  ScopeSpans               { scope = 1, spans = 2 }
  Span { trace_id=1 span_id=2 parent_span_id=4 name=5 kind=6
         start_unix_nano=7 end_unix_nano=8 attributes=9 }
  KeyValue { key=1 value=2 }   AnyValue { string=1 bool=2 int=3 double=4 }

Each span is appended to the output file as one JSON object per line.

  scripts/otlp-collect.py [--port 4318] [--out spans.jsonl]
"""
import argparse, gzip, json, struct, sys
from http.server import BaseHTTPRequestHandler, HTTPServer

WIRE_VARINT, WIRE_I64, WIRE_LEN, WIRE_I32 = 0, 1, 2, 5


def fields(buf):
    """Yield (field_number, wire_type, value) for one protobuf message."""
    i, n = 0, len(buf)
    while i < n:
        key, i = _varint(buf, i)
        fnum, wt = key >> 3, key & 7
        if wt == WIRE_VARINT:
            val, i = _varint(buf, i)
        elif wt == WIRE_I64:
            val, i = struct.unpack_from("<Q", buf, i)[0], i + 8
        elif wt == WIRE_LEN:
            ln, i = _varint(buf, i)
            val, i = buf[i:i + ln], i + ln
        elif wt == WIRE_I32:
            val, i = struct.unpack_from("<I", buf, i)[0], i + 4
        else:                                    # groups: not used by OTLP
            raise ValueError(f"wire type {wt}")
        yield fnum, wt, val


def _varint(buf, i):
    shift = result = 0
    while True:
        b = buf[i]; i += 1
        result |= (b & 0x7F) << shift
        if not b & 0x80:
            return result, i
        shift += 7


def sub(buf, want):
    """All length-delimited submessages with field number `want`."""
    return [v for f, wt, v in fields(buf) if f == want and wt == WIRE_LEN]


def any_value(buf):
    for f, _, v in fields(buf):
        if f == 1: return v.decode("utf-8", "replace")   # string
        if f == 2: return bool(v)                        # bool
        if f == 3: return int(v)                         # int
        if f == 4: return struct.unpack("<d", struct.pack("<Q", v))[0]
    return None


def attributes(span_buf):
    out = {}
    for kv in sub(span_buf, 9):
        key = val = None
        for f, wt, v in fields(kv):
            if f == 1 and wt == WIRE_LEN: key = v.decode("utf-8", "replace")
            elif f == 2 and wt == WIRE_LEN: val = any_value(v)
        if key is not None:
            out[key] = val
    return out


def parse_span(buf, scope):
    s = {"scope": scope}
    for f, wt, v in fields(buf):
        if   f == 1 and wt == WIRE_LEN: s["trace_id"] = v.hex()
        elif f == 2 and wt == WIRE_LEN: s["span_id"] = v.hex()
        elif f == 4 and wt == WIRE_LEN: s["parent_id"] = v.hex()
        elif f == 5 and wt == WIRE_LEN: s["name"] = v.decode("utf-8", "replace")
        elif f == 6 and wt == WIRE_VARINT: s["kind"] = v
        elif f == 7 and wt == WIRE_I64: s["start"] = v
        elif f == 8 and wt == WIRE_I64: s["end"] = v
    s.setdefault("parent_id", "")
    s["attrs"] = attributes(buf)
    return s


def parse_request(body):
    spans = []
    for rs in sub(body, 1):                       # resource_spans
        for ss in sub(rs, 2):                     # scope_spans
            scope = ""
            for isc in sub(ss, 1):                # instrumentation scope
                for f, wt, v in fields(isc):
                    if f == 1 and wt == WIRE_LEN:
                        scope = v.decode("utf-8", "replace")
            for sp in sub(ss, 2):                 # spans
                spans.append(parse_span(sp, scope))
    return spans


class Handler(BaseHTTPRequestHandler):
    out = None

    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        if self.headers.get("Content-Encoding") == "gzip":
            body = gzip.decompress(body)
        try:
            spans = parse_request(body) if self.path.endswith("/v1/traces") else []
        except Exception as e:                    # never wedge the exporter
            print(f"decode error: {e}", file=sys.stderr)
            spans = []
        for s in spans:
            Handler.out.write(json.dumps(s) + "\n")
        Handler.out.flush()
        self.send_response(200)
        self.send_header("Content-Type", "application/x-protobuf")
        self.send_header("Content-Length", "0")
        self.end_headers()

    def log_message(self, *a):                    # keep stdout for our own use
        pass


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=4318)
    ap.add_argument("--out", default="spans.jsonl")
    args = ap.parse_args()
    Handler.out = open(args.out, "a", buffering=1)
    print(f"OTLP/HTTP collector on :{args.port} -> {args.out}", flush=True)
    HTTPServer(("127.0.0.1", args.port), Handler).serve_forever()


if __name__ == "__main__":
    main()
