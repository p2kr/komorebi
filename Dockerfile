# ===================================================
# Stage 1: Build Backend (komorebi-server) & Generate TS Bindings
# ===================================================
FROM rust:1-slim-bookworm AS backend-builder
WORKDIR /usr/src/komorebi-server

# Install git (required by Cargo to fetch git dependencies like anitomy-rs) and build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy backend source code
COPY komorebi-server/ .

# Ensure .env exists to prevent build script warnings
RUN touch .env

# Export TypeScript bindings for the frontend using cargo ts-rs
RUN mkdir -p /usr/src/komorebi-web/src/lib/models/bindings \
    && cargo ts-rs

# Compile the release binary
RUN cargo build --release

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

# Copy generated TypeScript bindings from backend-builder
COPY --from=backend-builder /usr/src/komorebi-web/src/lib/models/bindings/ ./src/lib/models/bindings/

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

WORKDIR /usr/app

# Default environment configuration
ENV LOCO_ENV=production
ENV PORT=5150
ENV BINDING=0.0.0.0

# Copy compiled backend binary
COPY --from=backend-builder /usr/src/komorebi-server/target/release/komorebi_server-cli /usr/app/komorebi_server-cli

# Copy configuration and assets (crawler configs, initial assets)
COPY --from=backend-builder /usr/src/komorebi-server/config /usr/app/config
COPY --from=backend-builder /usr/src/komorebi-server/assets /usr/app/assets

# Copy built frontend assets into static/ for Loco's static file middleware
COPY --from=frontend-builder /app/komorebi-web/build /usr/app/static

EXPOSE 5150

ENTRYPOINT ["/usr/app/komorebi_server-cli"]
CMD ["start"]
