#!/usr/bin/env bash
# OpenTelemetry for the local Mendix runtime: metrics now, traces on request.
#
# Metrics and traces arrive by two completely different routes.
#
#   METRICS are built in. The runtime carries Micrometer and a /prometheus
#   servlet on the admin port, but registers no registry until you configure
#   one — until then /prometheus answers 503. 'configure' turns it on live,
#   no restart. mxcli's run --local sends a fixed set of runtime settings and
#   has no way to pass Metrics.*, so this has to be re-applied after every
#   restart.
#
#   TRACES need the OpenTelemetry Java agent. The runtime ships only the OTel
#   *API*; the agent that implements it is at runtime/agents/. mxcli spawns the
#   JVM as `java -jar <launcher> <deploydir>` with no hook for JVM arguments,
#   so the only way in is JAVA_TOOL_OPTIONS on the mxcli process — which this
#   script prints for you ('agent-env'), since a running JVM cannot be changed.
#
#   scripts/otel.sh configure          # Prometheus registry + sane span filters
#   scripts/otel.sh metrics            # the Mendix counters, readably
#   scripts/otel.sh raw                # the whole Prometheus scrape
#   scripts/otel.sh agent-env          # what to export before starting the app
#   scripts/otel.sh spans              # span volume by name, from runtime.log
#   scripts/otel.sh trace [substring]  # one request as a tree
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG="$ROOT/Sudoku/.mxcli/runtime.log"
ADMIN="${MXCLI_ADMIN_URL:-http://127.0.0.1:8090}"
ADMIN_PASS="${MXCLI_ADMIN_PASS:-mxcli-local-dev}"
DEPLOY="${MXCLI_DEPLOY_DIR:-$ROOT/Sudoku/deployment}"
RUNTIME_DIR="${MXCLI_RUNTIME_DIR:-$(ls -d /root/.mxcli/runtime/*/runtime 2>/dev/null | tail -1)}"
DB_NAME="${MXCLI_DB_NAME:-sudoku}"
DB_HOST="${MXCLI_DB_HOST:-127.0.0.1:5432}"
DB_USER="${MXCLI_DB_USER:-mendix}"
DB_PASS="${MXCLI_DB_PASSWORD:-mendix}"

# Activity spans that are pure noise on a compute-heavy microflow. The solver
# in this app emits ~110k spans per deal without these; ~400 with them.
SUPPRESS='["CreateOrChangeVariable","Loop","Gateway","RetrieveFromCache"]'

auth() { printf 'X-M2EE-Authentication: %s' "$(printf '%s' "$ADMIN_PASS" | base64 | tr -d '\n')"; }
scrape() { curl -s -m 10 -H "$(auth)" "$ADMIN/prometheus"; }

configure() {
  # update_configuration REPLACES the runtime settings, so the connection
  # details mxcli sent at boot have to be repeated or the runtime loses them.
  local body
  body=$(python3 - "$DEPLOY" "$RUNTIME_DIR" "$DB_HOST" "$DB_NAME" "$DB_USER" "$DB_PASS" "$SUPPRESS" <<'PY'
import json, sys
deploy, rt, host, name, user, pw, suppress = sys.argv[1:8]
print(json.dumps({"action": "update_configuration", "params": {
    "BasePath": deploy, "RuntimePath": rt, "DTAPMode": "D",
    "DatabaseType": "PostgreSQL", "DatabaseHost": host, "DatabaseName": name,
    "DatabaseUserName": user, "DatabasePassword": pw,
    "Metrics.ApplicationTags": {"app": name, "env": "dev"},
    "Metrics.Registries": [{"type": "prometheus", "settings": {"step": "PT10S"}}],
    "OpenTelemetry._RuntimeSpanFilters": json.loads(suppress),
}}))
PY
)
  curl -s -m 15 -H "$(auth)" -H 'Content-Type: application/json' -d "$body" "$ADMIN/" | python3 -m json.tool
  echo "Prometheus registry + span filters applied (re-run after every restart)."
}

case "${1:-}" in
  configure) configure ;;

  metrics)
    out=$(scrape)
    case "$out" in *"No PrometheusMeterRegistry"*|"") echo "no registry yet — run: $0 configure" >&2; exit 1 ;; esac
    # Several families are reported per queue / per handler, so sum by name —
    # the totals are what you want when watching one interaction.
    printf '%s\n' "$out" | awk '
      /^mx_runtime_stats_/ && !/^#/ {
        split($1, a, "{"); name = a[1]; sub(/^mx_runtime_stats_/, "", name)
        sum[name] += $2; n[name]++ }
      END { for (k in sum) printf "  %-44s %12.3f%s\n", k, sum[k],
              (n[k] > 1 ? "   (" n[k] " series)" : "") }' | sort ;;

  raw) scrape ;;

  agent-env)
    agent="$RUNTIME_DIR/agents/opentelemetry-javaagent.jar"
    [ -f "$agent" ] || { echo "no agent at $agent" >&2; exit 1; }
    cat <<EOF
# Export these, then start the app in the SAME shell. JAVA_TOOL_OPTIONS must be
# appended to, not replaced — this sandbox already uses it for the TLS proxy.
export JAVA_TOOL_OPTIONS="\${JAVA_TOOL_OPTIONS:-} -javaagent:$agent"
export OTEL_SERVICE_NAME=sudoku
export OTEL_TRACES_EXPORTER=console      # or otlp, with OTEL_EXPORTER_OTLP_ENDPOINT
export OTEL_METRICS_EXPORTER=none
export OTEL_LOGS_EXPORTER=none
# then: scripts/run-app.sh   &&   scripts/otel.sh configure
EOF
    ;;

  spans)
    [ -f "$LOG" ] || { echo "no runtime log — is the app running?" >&2; exit 1; }
    n=$(grep -ac LoggingSpanExporter "$LOG")
    echo "$n span(s) in runtime.log, by name:"
    grep -a LoggingSpanExporter "$LOG" |
      sed -E "s/.*LoggingSpanExporter - '([^']*)'.*/\1/" | sort | uniq -c | sort -rn | head -25 ;;

  trace)
    [ -f "$LOG" ] || { echo "no runtime log — is the app running?" >&2; exit 1; }
    want="${2:-Microflow }"
    # Find the newest trace id containing a matching span, then print that
    # whole trace in order. Mendix tags microflow spans with mx.microflow.depth,
    # which is enough to indent the tree.
    tid=$(grep -a LoggingSpanExporter "$LOG" | grep -a -- "$want" | tail -1 |
          sed -E "s/.*' : ([0-9a-f]{32}) .*/\1/")
    [ -n "$tid" ] || { echo "no span matching '$want'" >&2; exit 1; }
    echo "trace $tid"
    grep -a "$tid" "$LOG" | sed -E "s/.*LoggingSpanExporter - '([^']*)'.*/\1/" |
      awk '{ printf "  %s\n", $0 }' ;;

  *) sed -n '2,26p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' ;;
esac
