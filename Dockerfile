# ===================================================
# Stage 1: Build Backend (komorebi-server)
# ===================================================
FROM golang:1.23-bookworm AS backend-builder
WORKDIR /usr/src/komorebi-server

# Copy backend source code
COPY komorebi-server/ .

# Ensure .env exists to prevent build script warnings
RUN touch .env

# Download dependencies and compile the release binary
RUN go mod download && \
    CGO_ENABLED=1 go build -ldflags="-s -w" -o komorebi-server main.go

# ===================================================
# Stage 2: Build Frontend (komorebi-web)
# ===================================================
FROM node:22-alpine AS frontend-builder
WORKDIR /app/komorebi-web

# Enable Yarn 4 via corepack
RUN corepack enable

# Copy dependency manifests first for Docker layer caching
COPY komorebi-web/package.json komorebi-web/yarn.lock komorebi-web/.yarnrc.yml ./

# Install dependencies
RUN yarn install --immutable

# Copy frontend source
COPY komorebi-web/ ./

# Build static output to build/
RUN yarn build

# ===================================================
# Stage 3: Runtime Image
# ===================================================
FROM debian:bookworm-slim AS runner

# Install CA certificates for outgoing HTTPS requests (AniList/MAL API calls)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Set WORKDIR so that ../static resolves correctly if default is ../static
# The default frontend.staticPath is "../static", so if we are in /usr/app/server,
# it will resolve to /usr/app/static
WORKDIR /usr/app/server

# Default environment configuration
ENV APP_ENV=prod
ENV PORT=5150
ENV BINDING=0.0.0.0

# Copy compiled backend binary
COPY --from=backend-builder /usr/src/komorebi-server/komorebi-server /usr/app/server/komorebi-server

# Copy configuration and assets
COPY --from=backend-builder /usr/src/komorebi-server/configs /usr/app/server/configs
COPY --from=backend-builder /usr/src/komorebi-server/assets /usr/app/server/assets

# Copy built frontend assets into static/
COPY --from=frontend-builder /app/komorebi-web/build /usr/app/static

EXPOSE 8080

ENTRYPOINT ["/usr/app/server/komorebi-server"]
