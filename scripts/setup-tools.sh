#!/usr/bin/env bash
#
# setup-tools.sh — idempotent, re-runnable installer for the mxcli (MDL)
# Mendix-app development toolchain.
#
# The runtime container is ephemeral: it is reclaimed after inactivity and
# re-cloned fresh on the next session. This script re-establishes everything
# that is NOT committed to git (binaries, the mxcli source clone, the ANTLR
# jar, the cached Mendix build engine + runtime) so a new session comes up
# with a working toolchain automatically (wired via the SessionStart hook in
# .claude/settings.json).
#
# What it does (detect-then-install; safe to run repeatedly):
#   A. Detect prerequisites provided by the base image (Go, JDK 21, Node,
#      PostgreSQL 16, Chromium). Warn loudly if any are missing.
#   B. Pin ANTLR 4.13.1 (jar + `antlr4` PATH shim) so `make build`'s parser
#      regeneration is deterministic and matches antlr4-go/antlr v4.13.1.
#   C. Build mxcli from source off ako/mxcli @ main and install it.
#   D. Pre-cache MxBuild + Mendix runtime for the pinned Mendix version.
#   E. Verify every component and print a summary. Fail loudly on any error.
#
# It intentionally does NOT scaffold any Mendix project/module/page/.mpr.
set -euo pipefail

# ---------------------------------------------------------------------------
# Pinned versions / locations
# ---------------------------------------------------------------------------
ANTLR_VERSION="4.13.1"
ANTLR_JAR="/opt/antlr/antlr-${ANTLR_VERSION}-complete.jar"
ANTLR_URL="https://www.antlr.org/download/antlr-${ANTLR_VERSION}-complete.jar"
ANTLR_SHIM="/usr/local/bin/antlr4"

MXCLI_REPO="https://github.com/ako/mxcli.git"
MXCLI_BRANCH="main"
MXCLI_SRC="/opt/mxcli-src"
MXCLI_BIN="/usr/local/bin/mxcli"

MENDIX_VERSION="11.12.1"
MXCLI_HOME="${HOME}/.mxcli"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# A. Detect base-image prerequisites (do not attempt to install these; they
#    are baked into the image and network-installing them is unreliable here).
# ---------------------------------------------------------------------------
log "A. Detecting base-image prerequisites"

# `java -version` writes to stderr and the JVM may prepend a "Picked up
# JAVA_TOOL_OPTIONS" line; grep the actual version line so it isn't lost.
java_version() { java -version 2>&1 | grep -i 'version' | grep -vi 'JAVA_TOOL_OPTIONS' | head -1; }

command -v go   >/dev/null 2>&1 && echo "  go:     $(go version)"      || warn "go not found — 'make build' will fail"
command -v java >/dev/null 2>&1 && echo "  java:   $(java_version)"    || warn "java (JDK 21) not found — ANTLR/runtime need it"
command -v node >/dev/null 2>&1 && echo "  node:   $(node --version)"  || warn "node not found — Playwright screenshots need it"

PG_BIN=""
for d in /usr/lib/postgresql/16/bin /usr/lib/postgresql/*/bin /usr/pgsql-16/bin; do
  if [ -x "$d/postgres" ] && [ -x "$d/initdb" ]; then PG_BIN="$d"; break; fi
done
if [ -n "$PG_BIN" ]; then
  echo "  pg:     $("$PG_BIN/postgres" --version) ($PG_BIN)"
else
  warn "PostgreSQL server (postgres/initdb) not found — 'mxcli run --local --ensure-db' needs it"
fi

CHROMIUM="${PLAYWRIGHT_BROWSERS_PATH:-/opt/pw-browsers}/chromium"
if [ -e "$CHROMIUM" ]; then
  echo "  chrome: $CHROMIUM"
else
  warn "Chromium not found at $CHROMIUM — screenshot verification needs it"
fi

# ---------------------------------------------------------------------------
# B. Pin ANTLR 4.13.1 (jar + shim first on PATH).
# ---------------------------------------------------------------------------
log "B. Pinning ANTLR ${ANTLR_VERSION}"
mkdir -p "$(dirname "$ANTLR_JAR")"
if [ ! -s "$ANTLR_JAR" ]; then
  echo "  downloading $ANTLR_URL"
  curl -fsSL -o "$ANTLR_JAR" "$ANTLR_URL"
else
  echo "  jar present: $ANTLR_JAR"
fi

# (Re)write the shim so the pinned jar is always what `antlr4` resolves to.
cat > "$ANTLR_SHIM" <<EOF
#!/usr/bin/env bash
exec java -jar ${ANTLR_JAR} "\$@"
EOF
chmod 0755 "$ANTLR_SHIM"
echo "  shim: $ANTLR_SHIM -> $ANTLR_JAR"

# ---------------------------------------------------------------------------
# C. Build mxcli from source (ako/mxcli @ main) and install it.
#    Rebuild only when missing or out of date vs. main HEAD (idempotent).
# ---------------------------------------------------------------------------
log "C. Building mxcli from ${MXCLI_REPO} (${MXCLI_BRANCH})"
export PATH="/usr/local/bin:${PATH}"
export GOTOOLCHAIN=auto   # go.mod pins the 1.26 toolchain; let go fetch it

if [ -d "$MXCLI_SRC/.git" ]; then
  git -C "$MXCLI_SRC" fetch --depth 1 origin "$MXCLI_BRANCH"
  git -C "$MXCLI_SRC" checkout -q "$MXCLI_BRANCH" 2>/dev/null || git -C "$MXCLI_SRC" checkout -qB "$MXCLI_BRANCH" origin/"$MXCLI_BRANCH"
  git -C "$MXCLI_SRC" reset --hard origin/"$MXCLI_BRANCH"
else
  rm -rf "$MXCLI_SRC"
  git clone --depth 1 --branch "$MXCLI_BRANCH" "$MXCLI_REPO" "$MXCLI_SRC"
fi

HEAD_SHA="$(git -C "$MXCLI_SRC" rev-parse --short HEAD)"
echo "  mxcli main HEAD: $HEAD_SHA"

INSTALLED_SHA="$("$MXCLI_BIN" --version 2>/dev/null | awk '{print $3}' || true)"
if [ "$INSTALLED_SHA" = "$HEAD_SHA" ]; then
  echo "  mxcli $HEAD_SHA already installed — skipping build"
else
  echo "  building (installed='${INSTALLED_SHA:-none}' target='$HEAD_SHA')"
  ( cd "$MXCLI_SRC" && make build )
  install -m 0755 "$MXCLI_SRC/bin/mxcli" "$MXCLI_BIN"
  echo "  installed $("$MXCLI_BIN" --version)"
fi

# ---------------------------------------------------------------------------
# D. Pre-cache MxBuild engine + Mendix runtime for the pinned version.
# ---------------------------------------------------------------------------
log "D. Pre-caching MxBuild + runtime ${MENDIX_VERSION}"
if [ -x "${MXCLI_HOME}/mxbuild/${MENDIX_VERSION}/modeler/mx" ]; then
  echo "  mxbuild ${MENDIX_VERSION} already cached"
else
  "$MXCLI_BIN" setup mxbuild --version "$MENDIX_VERSION"
fi

if [ -d "${MXCLI_HOME}/runtime/${MENDIX_VERSION}" ]; then
  echo "  runtime ${MENDIX_VERSION} already cached"
else
  "$MXCLI_BIN" setup mxruntime --version "$MENDIX_VERSION"
fi

# ---------------------------------------------------------------------------
# E. Verify everything and print a summary. Fail loudly on any missing piece.
# ---------------------------------------------------------------------------
log "E. Verifying toolchain"
FAIL=0
check() { # <label> <test-cmd...>
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then echo "  OK   $label"; else echo "  FAIL $label"; FAIL=1; fi
}

check "mxcli --help runs"                 "$MXCLI_BIN" --help
check "antlr4 shim present"               test -x "$ANTLR_SHIM"
check "antlr jar present"                 test -s "$ANTLR_JAR"
check "mx validator present"              test -x "${MXCLI_HOME}/mxbuild/${MENDIX_VERSION}/modeler/mx"
check "mxbuild engine present"            test -x "${MXCLI_HOME}/mxbuild/${MENDIX_VERSION}/modeler/mxbuild"
check "mendix runtime present"            test -d "${MXCLI_HOME}/runtime/${MENDIX_VERSION}"
check "postgres server present"           test -n "$PG_BIN"
check "chromium present"                  test -e "$CHROMIUM"

ANTLR_REPORTED="$(antlr4 2>&1 | grep -oi 'Version [0-9.]*' | head -1 || true)"
[ "$ANTLR_REPORTED" = "Version ${ANTLR_VERSION}" ] || { echo "  FAIL antlr reports '${ANTLR_REPORTED}', expected 'Version ${ANTLR_VERSION}'"; FAIL=1; }

echo
echo "  ---------------- Toolchain summary ----------------"
echo "  mxcli:         $("$MXCLI_BIN" --version 2>/dev/null || echo MISSING)   (ako/mxcli@${MXCLI_BRANCH} ${HEAD_SHA})"
echo "  antlr4:        ${ANTLR_REPORTED:-MISSING}"
echo "  go:            $(go version 2>/dev/null | awk '{print $3}' || echo MISSING) (GOTOOLCHAIN=auto -> go.mod toolchain)"
echo "  java:          $(java_version | sed 's/.*version //')"
echo "  node:          $(node --version 2>/dev/null || echo MISSING)"
echo "  postgres:      ${PG_BIN:-MISSING}"
echo "  chromium:      ${CHROMIUM}"
echo "  mendix:        ${MENDIX_VERSION} (mxbuild + runtime cached under ${MXCLI_HOME})"
echo "  ---------------------------------------------------"

[ "$FAIL" -eq 0 ] || die "One or more toolchain checks FAILED (see above)."
log "Toolchain ready."
