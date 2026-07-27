FROM mcr.microsoft.com/devcontainers/base:bookworm

# Install Adoptium JDK 21 (required by MxBuild), Node.js 22, and utility tools
RUN apt-get update && apt-get install -y --no-install-recommends wget apt-transport-https gpg ca-certificates curl && \
    wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor -o /etc/apt/keyrings/adoptium.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb bookworm main" > /etc/apt/sources.list.d/adoptium.list && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
       temurin-21-jdk \
       nodejs \
       postgresql-client \
       kafkacat \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install playwright-cli plus the bundled Chromium (headless shell).
# @playwright/cli ships its OWN playwright-core, so browsers must be installed
# via that bundled core (matching revision) — NOT via a transient "npx
# playwright", which resolves a different package and cache. Browsers go under a
# world-readable PLAYWRIGHT_BROWSERS_PATH so the non-root "vscode" user finds
# them (a root-owned ~/.cache/ms-playwright would be invisible to it).
#
# On Linux arm64 the chrome/msedge *channels* have no distribution and the alpha
# CLI's browserName:chromium resolution is unreliable, so we pin the bundled
# Chromium headless-shell through a stable symlink referenced by
# .playwright/cli.config.json (executablePath). The symlink keeps the config
# revision-proof as the headless-shell build number changes.
# @playwright/cli is pinned (not @latest): it is a young package whose CLI
# surface still shifts between releases, and an unexpected bump has silently
# broken browser provisioning before. Bump deliberately after re-verifying the
# flow below. NOTE: the npm package version (0.1.x) is independent of the
# playwright-core version the CLI's --version reports (e.g. 1.59.0-alpha).
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright
RUN npm install -g @playwright/cli@0.1.15 && \
    CORE="$(npm root -g)/@playwright/cli/node_modules/playwright-core/cli.js" && \
    node "$CORE" install --with-deps chromium chromium-headless-shell && \
    chmod -R a+rX "$PLAYWRIGHT_BROWSERS_PATH" && \
    ln -sf "$PLAYWRIGHT_BROWSERS_PATH"/chromium_headless_shell-*/chrome-linux/headless_shell /usr/local/bin/mx-headless-shell
