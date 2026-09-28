# Komorebi — build task runner
# Usage: just <recipe>
# Requires: just, go, yarn (v4 via corepack), docker

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
build-server:
    go build -o komorebi-server main.go

[working-directory("komorebi-web")]
_install:
    yarn install --immutable

[parallel]
[working-directory("komorebi-web")]
build-web: _install
    yarn build

[parallel]
build: build-server build-web

# ── Format / Fix ─────────────────────────────────────────────────────────────

[parallel]
fmt: fmt-server fmt-web

[working-directory("komorebi-server")]
fmt-server:
    go fmt ./...
    go vet ./...
    gofumpt -w -extra .

[working-directory("komorebi-web")]
fmt-web:
    yarn format

# ── Docker ───────────────────────────────────────────────────────────────────

docker-build:
    docker build -t {{ image }}:{{ tag }} .

docker-run:
    docker run --rm -p 8080:8080 {{ image }}:{{ tag }}

# Build and run docker image
docker: docker-build docker-run

# ── Package / Deploy ─────────────────────────────────────────────────────────

# Package production release into a deployable zip file
[windows]
deploy-zip output="komorebi.zip": build
    @$staging = Join-Path ([System.IO.Path]::GetTempPath()) ("komorebi-deploy-" + [System.Guid]::NewGuid().ToString()); \
    try { \
        New-Item -ItemType Directory -Path (Join-Path $staging "configs") -Force | Out-Null; \
        New-Item -ItemType Directory -Path (Join-Path $staging "assets") -Force | Out-Null; \
        New-Item -ItemType Directory -Path (Join-Path $staging "static") -Force | Out-Null; \
        $binPath = "komorebi-server/komorebi-server.exe"; \
        if (-not (Test-Path $binPath)) { $binPath = "komorebi-server/komorebi-server" }; \
        if (-not (Test-Path $binPath)) { throw "Server release binary not found" }; \
        Copy-Item -Path $binPath -Destination $staging; \
        Copy-Item -Path "komorebi-server/configs/config-prod.toml" -Destination (Join-Path $staging "configs"); \
        if (Test-Path "komorebi-server/assets/main.sqlite") { \
            Copy-Item -Path "komorebi-server/assets/main.sqlite" -Destination (Join-Path $staging "assets"); \
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
    mkdir -p "$staging/configs" "$staging/assets" "$staging/static"; \
    if [ -f "komorebi-server/komorebi-server" ]; then \
        cp "komorebi-server/komorebi-server" "$staging/"; \
        chmod +x "$staging/komorebi-server"; \
    elif [ -f "komorebi-server/komorebi-server.exe" ]; then \
        cp "komorebi-server/komorebi-server.exe" "$staging/"; \
    else \
        echo "Error: Server release binary not found" >&2; exit 1; \
    fi; \
    cp "komorebi-server/configs/config-prod.toml" "$staging/configs/"; \
    [ -f "komorebi-server/assets/main.sqlite" ] && cp "komorebi-server/assets/main.sqlite" "$staging/assets/" || true; \
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
