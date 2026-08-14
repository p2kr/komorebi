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

- [`komorebi-server`](./komorebi-server): Backend service that handles provider API integrations, data normalization, SQLite storage, and web client delivery.
- [`komorebi-web`](./komorebi-web): Web interface for managing lists, discovering media, and configuring accounts.

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

### Running the Backend

```bash
cd komorebi-server
cargo run
```

The server starts on `http://127.0.0.1:8080` with API routes under `/api/v1`.

### Running the Web Client

```bash
cd komorebi-web
yarn install
yarn dev
```

The web client runs on `http://localhost:5173`.

---

## Standalone Production Build

To package both frontend and backend into a single binary:

1. **Build the web frontend:**
   ```bash
   cd komorebi-web
   yarn build
   ```

2. **Build the server binary:**
   ```bash
   cd ../komorebi-server
   cargo build --release
   ```

3. **Run the standalone executable:**
   ```bash
   ./target/release/komorebi-server
   ```
   Open `http://127.0.0.1:8080` in your browser.

---

## Documentation

- [Backend Documentation (`komorebi-server/README.md`)](./komorebi-server/README.md)
- [Web Client Documentation (`komorebi-web/README.md`)](./komorebi-web/README.md)
- [Architecture & Context](./komorebi-server/docs/CONTEXT.md)
- [OpenAPI Specification](./komorebi-server/docs/openapi.yaml)

---

## License

Licensed under the [AGPL-3.0 License](./komorebi-web/package.json).
