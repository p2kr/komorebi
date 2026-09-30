# Komorebi (木漏れ日)

A unified anime and manga tracking and collection management application that aggregates your lists across multiple services into a single interface.

---

## What is Komorebi?

Komorebi connects with third-party anime and manga tracking platforms (currently **AniList** and **MyAnimeList**) to provide a consolidated view of your watch and read lists, metadata, and progress.

### Key Functionality

- **Multi-Service Sync**: Connect both AniList and MyAnimeList accounts to view and manage your lists in one place.
- **Data Harmonization**: Standardizes differing scoring scales (e.g. 0–100 vs 0–10) to a uniform 0.0–10.0 scale, and normalizes release statuses, formats, and media types across providers.
- **OAuth & Sandbox Modes**: Link accounts securely via OAuth for full sync, or add usernames in Sandbox mode for read-only tracking without needing credentials.
- **Local Persistence**: Stores user accounts, preferences, and data locally in SQLite for fast access.
- **All-in-One Deployment**: The backend can serve the pre-built web client directly, allowing the entire application to run as a single standalone executable.
- **Internationalization**: Full interface localization with multi-language support.

---

## Project Structure

- [`komorebi-server`](https://github.com/p2kr/komorebi-server): Backend service that handles provider API integrations, data normalization, SQLite storage, and web client delivery.
- [`komorebi-web`](https://github.com/p2kr/komorebi-web): Web interface for managing lists, discovering media, and configuring accounts.

---

## Getting Started

### Prerequisites

- **Go** (1.27+)
- **Node.js** (v26+) & **Yarn**

### 1. Clone the Repository

Clone with submodules to get both the server and web client:

```bash
git clone --recursive https://github.com/p2kr/komorebi.git
cd komorebi
```

If already cloned without submodules:

```bash
git submodule update --init --recursive
```

---

## Development

### 1. Running the Backend

```bash
cd komorebi-server
go mod tidy
go run main.go
```

The server defaults to running on port `8080` or the port defined in your configuration.

### 2. Running the Web Client

```bash
cd komorebi-web
yarn install
yarn dev
```

The web client runs on `http://localhost:5173`.

---

## Standalone Production Build

To build both the frontend and backend for deployment:

1. **Build the web frontend:**
   ```bash
   cd komorebi-web
   yarn install
   yarn build
   ```

2. **Build the server release binary:**
   ```bash
   cd ../komorebi-server
   go generate
   go build -o komorebi-server main.go
   ```

3. **Run the server:**
   ```bash
   ./komorebi-server
   ```
   Open `http://127.0.0.1:8081` (or your configured port) in your browser.

---

## Docker Build & Deployment

You can build and run the complete application using Docker. The multi-stage `Dockerfile` automatically builds the frontend static assets, compiles the Go release binary, and packages everything into a minimal runtime image with FFmpeg included:

```bash
# Build the Docker image
docker build -t komorebi .

# Run the container
docker run -d -p 8081:8081 --name komorebi komorebi
```

The application will be accessible at `http://localhost:8081`.

---

## Documentation

- [Backend Documentation (`komorebi-server/README.md`)](https://github.com/p2kr/komorebi-server/blob/master/README.md)
- [Web Client Documentation (`komorebi-web/README.md`)](https://github.com/p2kr/komorebi-web/blob/main/README.md)
- [Architecture & Context](https://github.com/p2kr/komorebi-server/blob/master/docs/CONTEXT.md)
- [OpenAPI Specification](https://github.com/p2kr/komorebi-server/blob/master/docs/openapi.yaml)

---

## License

Licensed under the [AGPL-3.0 License](https://github.com/p2kr/komorebi-web/blob/main/package.json).
