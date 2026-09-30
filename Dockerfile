# Tag: p2kr/komorebi

# ===================================================
# Stage 1: Build Backend (komorebi-server)
# ===================================================
FROM golang:1.27-alpine AS backend-builder
WORKDIR /usr/src/komorebi-server

# Copy backend source code
COPY komorebi-server/ .

# Ensure .env exists to prevent build script warnings
RUN touch .env

# Download dependencies and compile the release binary
# go install github.com/swaggo/swag/v2/cmd/swag@latest
RUN go mod download && \
    go generate && \
    CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -trimpath -o komorebi-server main.go

# ===================================================
# Stage 2: Build Frontend (komorebi-web)
# ===================================================
FROM node:26-alpine AS frontend-builder
WORKDIR /app/komorebi-web

# Enable Yarn 4 via corepack
RUN npm install -g corepack && corepack enable

# Copy dependency manifests first for Docker layer caching
COPY komorebi-web/package.json komorebi-web/yarn.lock komorebi-web/.yarnrc.yml ./

# Install dependencies
RUN yarn install --immutable

# Copy frontend source
COPY komorebi-web/ ./

ARG PUBLIC_MAL_CLIENT_ID=
ARG PUBLIC_ANILIST_CLIENT_ID=
ARG PUBLIC_API_URL=

ENV PUBLIC_MAL_CLIENT_ID=$PUBLIC_MAL_CLIENT_ID
ENV PUBLIC_ANILIST_CLIENT_ID=$PUBLIC_ANILIST_CLIENT_ID
ENV PUBLIC_API_URL=$PUBLIC_API_URL

# Build static output to build/
RUN yarn build

# ===================================================
# Stage 3: Runtime Image
# ===================================================
# Attach Ffmpeg and Ffprobe binaries
FROM mwader/static-ffmpeg:latest AS ff
FROM alpine:latest AS runner

RUN apk --no-cache add ca-certificates tzdata

# Set WORKDIR so that ../static resolves correctly if default is ../static
# The default frontend.staticPath is "../static", so if we are in /usr/app/server,
# it will resolve to /usr/app/static
WORKDIR /usr/app/server

# Default environment configuration
ENV APP_ENV=prod
ENV PORT=8081
ENV BINDING=0.0.0.0

# Copy compiled backend binary
COPY --from=backend-builder /usr/src/komorebi-server/komorebi-server /usr/app/server/komorebi-server

# Copy built frontend assets into static/
COPY --from=frontend-builder /app/komorebi-web/build /usr/app/static

# Copy ffmpeg & ffprobe
COPY --from=ff /ffmpeg /usr/local/bin/
COPY --from=ff /ffprobe /usr/local/bin/

# Verify installation
RUN ffmpeg -version && ffprobe -version

EXPOSE ${PORT}

ENTRYPOINT ["/usr/app/server/komorebi-server"]
