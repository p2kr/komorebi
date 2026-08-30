# Komorebi — build task runner
# Usage: just <recipe>
# Requires: just, cargo, yarn (v4 via corepack), docker

set minimum-version := "1.58.0"

[windows]
set shell := ["powershell", "-NoLogo", "-NoProfile", "-Command"]

image := "p2kr/komorebi"
tag := "latest"

# List available recipes
default:
    @just --list

# ── Build ────────────────────────────────────────────────────────────────────

[working-directory("komorebi-server")]
ts-bindings:
    cargo ts-rs

[working-directory("komorebi-server")]
build-server:
    cargo build --release

[working-directory("komorebi-web")]
_install:
    yarn install --immutable

[parallel]
[working-directory("komorebi-web")]
build-web: ts-bindings _install
    yarn build

[parallel]
build: build-server build-web

# ── Format / Fix ─────────────────────────────────────────────────────────────

[parallel]
fmt: fmt-server fmt-web

[working-directory("komorebi-server")]
fmt-server:
    cargo clippy --fix --allow-dirty --allow-staged
    cargo fmt

[working-directory("komorebi-web")]
fmt-web:
    yarn format

# ── Docker ───────────────────────────────────────────────────────────────────

docker-build:
    docker build -t {{ image }}:{{ tag }} .

docker-run:
    docker run --rm -p 5150:5150 {{ image }}:{{ tag }}

# Build and run docker image
docker: docker-build docker-run

# ── Package / Deploy ─────────────────────────────────────────────────────────

# Package production release into a deployable zip file
[windows]
deploy-zip output="komorebi.zip": build
    @$staging = Join-Path ([System.IO.Path]::GetTempPath()) ("komorebi-deploy-" + [System.Guid]::NewGuid().ToString()); \
    try { \
        New-Item -ItemType Directory -Path (Join-Path $staging "config") -Force | Out-Null; \
        New-Item -ItemType Directory -Path (Join-Path $staging "assets") -Force | Out-Null; \
        New-Item -ItemType Directory -Path (Join-Path $staging "static") -Force | Out-Null; \
        $binPath = "komorebi-server/target/release/komorebi_server-cli.exe"; \
        if (-not (Test-Path $binPath)) { $binPath = "komorebi-server/target/release/komorebi_server-cli" }; \
        if (-not (Test-Path $binPath)) { throw "Server release binary not found" }; \
        Copy-Item -Path $binPath -Destination $staging; \
        Copy-Item -Path "komorebi-server/config/production.yaml" -Destination (Join-Path $staging "config"); \
        if (Test-Path "komorebi-server/assets/crawler_configs.yaml") { \
            Copy-Item -Path "komorebi-server/assets/crawler_configs.yaml" -Destination (Join-Path $staging "assets"); \
        }; \
        if (Test-Path "komorebi-server/assets/dht.json") { \
            Copy-Item -Path "komorebi-server/assets/dht.json" -Destination (Join-Path $staging "assets"); \
        }; \
        if (-not (Test-Path "komorebi-web/build")) { throw "Frontend build not found at komorebi-web/build" }; \
        Copy-Item -Path "komorebi-web/build/*" -Destination (Join-Path $staging "static") -Recurse; \
        $outDir = Split-Path -Parent "{{ output }}"; \
        if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }; \
        $outPath = [System.IO.Path]::GetFullPath("{{ output }}"); \
        if (Test-Path $outPath) { Remove-Item -Path $outPath -Force }; \
        Compress-Archive -Path "$staging/*" -DestinationPath $outPath -Force; \
        Write-Host "Created production deployment package: $outPath"; \
    } \
    finally { \
        if (Test-Path $staging) { Remove-Item -Path $staging -Recurse -Force }; \
    }

[unix]
deploy-zip output="komorebi.zip": build
    @set -e; \
    staging="$(mktemp -d)"; \
    trap 'rm -rf "$staging"' EXIT; \
    mkdir -p "$staging/config" "$staging/assets" "$staging/static"; \
    if [ -f "komorebi-server/target/release/komorebi_server-cli" ]; then \
        cp "komorebi-server/target/release/komorebi_server-cli" "$staging/"; \
        chmod +x "$staging/komorebi_server-cli"; \
    elif [ -f "komorebi-server/target/release/komorebi_server-cli.exe" ]; then \
        cp "komorebi-server/target/release/komorebi_server-cli.exe" "$staging/"; \
    else \
        echo "Error: Server release binary not found" >&2; exit 1; \
    fi; \
    cp "komorebi-server/config/production.yaml" "$staging/config/"; \
    [ -f "komorebi-server/assets/crawler_configs.yaml" ] && cp "komorebi-server/assets/crawler_configs.yaml" "$staging/assets/" || true; \
    [ -f "komorebi-server/assets/dht.json" ] && cp "komorebi-server/assets/dht.json" "$staging/assets/" || true; \
    if [ ! -d "komorebi-web/build" ]; then \
        echo "Error: Frontend build not found at komorebi-web/build" >&2; exit 1; \
    fi; \
    cp -r komorebi-web/build/* "$staging/static/"; \
    out_dir="$(dirname "{{ output }}")"; \
    [ "$out_dir" != "." ] && mkdir -p "$out_dir"; \
    rm -f "{{ output }}"; \
    abs_out="$(cd "$(dirname "{{ output }}")" 2>/dev/null && pwd)/$(basename "{{ output }}")"; \
    (cd "$staging" && zip -r -q "$abs_out" .); \
    echo "Created production deployment package: {{ output }}"

