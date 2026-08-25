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

- **Rust** (latest stable toolchain) & Cargo
- **Node.js** (v20+) & **Yarn**

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

### 1. Generate TypeScript Bindings

The web frontend relies on TypeScript definitions generated from backend Rust DTOs via `ts-rs`:

```bash
cd komorebi-server
cargo ts-rs
```

### 2. Running the Backend

```bash
cd komorebi-server
# Apply migrations
cargo loco db migrate

# Start development server
cargo loco start
```

The server starts on `http://127.0.0.1:5150` with API routes under `/api/v1`.

### 3. Running the Web Client

```bash
cd komorebi-web
yarn install
yarn dev
```

The web client runs on `http://localhost:5173`.

---

## Standalone Production Build

To build both the frontend and backend for deployment:

1. **Export TypeScript bindings:**
   ```bash
   cd komorebi-server
   cargo ts-rs
   ```

2. **Build the web frontend:**
   ```bash
   cd ../komorebi-web
   yarn install
   yarn build
   ```

3. **Build the server release binary:**
   ```bash
   cd ../komorebi-server
   cargo build --release
   ```

4. **Run the server:**
   ```bash
   ./target/release/komorebi_server-cli start
   ```
   Open `http://127.0.0.1:5150` in your browser.

---

## Docker Build & Deployment

You can build and run the complete application using Docker. The multi-stage `Dockerfile` automatically generates TypeScript bindings with `cargo ts-rs`, builds the frontend static assets, compiles the release binary, and packages everything into a minimal runtime image:

```bash
# Build the Docker image
docker build -t komorebi .

# Run the container
docker run -d -p 5150:5150 --name komorebi komorebi
```

The application will be accessible at `http://localhost:5150`.

---

## Documentation

- [Backend Documentation (`komorebi-server/README.md`)](https://github.com/p2kr/komorebi-server/blob/master/README.md)
- [Web Client Documentation (`komorebi-web/README.md`)](https://github.com/p2kr/komorebi-web/blob/main/README.md)
- [Architecture & Context](https://github.com/p2kr/komorebi-server/blob/master/docs/CONTEXT.md)
- [OpenAPI Specification](https://github.com/p2kr/komorebi-server/blob/master/docs/openapi.yaml)

---

## License

Licensed under the [AGPL-3.0 License](https://github.com/p2kr/komorebi-web/blob/main/package.json).
