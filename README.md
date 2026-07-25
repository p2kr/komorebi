# 🌸 Komorebi (木漏れ日)

**An All-in-One Native Flutter Desktop Application for Consuming, Archiving, and Synchronizing Manga & Anime from
MyAnimeList/AniList.**

![Version](https://img.shields.io/badge/Version-1.0.0-8A2BE2?style=for-the-badge)
![Dart](https://img.shields.io/badge/Dart-3.12%2B-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-3.24%2B-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Platform](https://img.shields.io/badge/Platforms-Windows%20%7C%20Linux-0078D4?style=for-the-badge&logo=windows&logoColor=white)
![SQLite Drift](https://img.shields.io/badge/Drift%20SQLite-2.34%2B-003B57?style=for-the-badge&logo=sqlite&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-3.3%2B-6F42C1?style=for-the-badge&logo=dart&logoColor=white)
[![Codecov](https://img.shields.io/codecov/c/github/p2kr/komorebi?style=for-the-badge&logo=codecov&logoColor=white)](https://codecov.io/gh/p2kr/komorebi)
![License: AGPL v3](https://img.shields.io/badge/License-AGPLv3-blue.svg?style=for-the-badge)

---

## 📌 Overview

**Komorebi** is a powerful, standalone application built with Flutter, tailored specifically for **Windows** and
**Linux** desktop platforms. Designed as an evolution of web-frontend and Node-backend media synchronizers, Komorebi
eliminates
the need to run external local backend servers or browser extensions. Everything runs within a high-performance unified
native binary.

Whether you are synchronizing your watching progress with **MyAnimeList (MAL)** or **AniList**, browsing streaming
archives ad-free via
our embedded loopback proxy, or downloading high-bitrate media directly to your hard drive, Komorebi delivers a
seamless, premium experience.

---

## ✨ Key Features

- 🖥️ **Native Desktop Architecture**: Powered by Flutter and `window_manager`, offering custom window dimensions,
  borderless layouts, drag-handling, and native system OS integration.
- ⚡ **Zero Local Host Requirement**: Eliminates external Node.js servers. Leveraging Dart's native `dart:io`, Komorebi
  directly reads and writes files to your system without browser sandbox restrictions.
- 🔑 **OAuth 2.0 PKCE & Deep Linking**: Native deep-linking integration (`komorebi://auth-callback`) and PKCE flow for
  secure, 1-click MyAnimeList/AniList authentication with a hosted redirect landing page.
- 🛡️ **Embedded Adblock Loopback Proxy**: Features an internal HTTP loopback server (`LocalAdblockProxy`) running on
  port `3001` that intercepts requests, strips tracking scripts, removes ad banners, and purges unwanted popups/iframes
  before serving HTML to inline web views.
- 💾 **Relational SQLite Persistence (Drift)**: A robust, type-safe SQLite database layer managing user profiles
  (`Profiles`), download queues (`QueueItems`), audit logs (`Logs`), and app configuration (`Configs`).
- 🕷️ **HTML Scraper & Crawler Engine**: Built-in CSS selector extraction engine (`CrawlerEngine`) powered by
  `package:html` and `dio` to traverse media directories and extract streaming or download links.
- 🌗 **Curated Obsidian Aesthetic**: Designed with a sleek, dark/light monochrome visual identity using premium
  typography (**Inter**, **JetBrains Mono**, and **Playfair Display**).
- 📊 **Real-Time Diagnostics Terminal**: Integrated audit logging and debugging console powered by `talker` with level
  and category filters for instant developer feedback.

---

## 🏗️ Architecture & Data Flow

```mermaid
graph TD
    subgraph GUI["Desktop UI Layer (Flutter / Riverpod)"]
        A["Main Window / Custom Titlebar"] --> B["Adblock WebView / Browser Mode"]
        A --> C["MyAnimeList / AniList Profile Switcher"]
        A --> D["Diagnostics Terminal"]
    end

    subgraph Engine["Core Engine & Network Layer"]
        B -->|HTTP Requests| E["LocalAdblockProxy (Loopback Server :3001)"]
        E -->|Sanitizes DOM & Strips Ads| F["External Streaming Sites"]
        C -->|OAuth PKCE Deep Link| G["MAL / AniList REST APIs / Auth Redirect"]
        H["CrawlerEngine (CSS Selector Parser)"] -->|Extracts Media| F
    end

    subgraph Storage["Persistence & File System (dart:io / Drift)"]
        I["Drift SQLite Database (Profiles, Queue, Logs, Configs)"]
        J["Local Hard Drive (Media & Downloads)"]
    end

    GUI <--> Storage
    Engine <--> Storage
```

---

## 🛠️ Technology Stack

| Feature                    | Dart / Flutter Package              | Purpose                                                                             |
|:---------------------------|:------------------------------------|:------------------------------------------------------------------------------------|
| **State Management**       | `flutter_riverpod` (^3.3.2)         | Reactive separation of business logic, download states, and UI.                     |
| **Database & Persistence** | `drift` (^2.34.0) + `drift_flutter` | Type-safe relational SQLite database (`Profiles`, `QueueItems`, `Logs`, `Configs`). |
| **REST & Networking**      | `dio` (^5.10.0)                     | High-performance HTTP client with download progress streams and interceptors.       |
| **OAuth 2.0 & Deep Links** | `protocol_handler` + `app_links`    | Custom URI scheme handling (`komorebi://auth-callback`) and PKCE token flow.        |
| **HTML Parser & Scraper**  | `html` (^0.15.6)                    | DOM traversal and CSS selector querying engine (`CrawlerEngine`).                   |
| **Adblock Proxy Server**   | `dart:io` (`HttpServer`)            | Embedded loopback server to fetch, sanitize, and proxy streaming sites.             |
| **Window Management**      | `window_manager` (^0.5.1)           | Custom title bars, window framing, centering, and size constraints.                 |
| **Logging & Diagnostics**  | `talker` (^5.1.17)                  | Structured logging engine and visual `DiagnosticWindow` console viewer.             |
| **Localization**           | `flutter_intl` + `intl`             | ARB-based multi-language support and deferred loading.                              |

---

## 📈 Development Progress Dashboard

| Phase | Title                                 |       Status       | Progress | Key Implemented Components                                                                                                              |
|:-----:|:--------------------------------------|:------------------:|:--------:|:----------------------------------------------------------------------------------------------------------------------------------------|
| **1** | **Bootstrap & Window Controls**       |  🟢 **Completed**  |   100%   | Project setup, `window_manager` initialization, monochrome obsidian theme.                                                              |
| **2** | **Local Database (Drift SQLite)**     |  🟢 **Completed**  |   100%   | `AppDatabase` setup, schemas (`Profiles`, `QueueItems`, `Logs`, `Configs`), DAOs, and generated queries.                                |
| **3** | **MAL / AniList Sync & PKCE Auth**    |  🟢 **Completed**  |   100%   | MAL v2 & AniList API clients, PKCE OAuth 2.0 flow with deep linking (`komorebi://auth-callback`), token exchange, and account switcher. |
| **4** | **Scraper & HTML Parsing Engine**     | 🟡 **In Progress** |   33%    | `CrawlerEngine` DOM and CSS selector extractor implemented.                                                                             |
| **5** | **Adblock Proxy & Sandboxed WebView** | 🟡 **In Progress** |   80%    | Embedded `LocalAdblockProxy` loopback HTTP server & HTML sanitizer implemented.                                                         |
| **6** | **Downloader & Queue Worker**         | ⚪ **Not Started** |    0%    | Pending background queue scheduler and real-time progress tracking.                                                                     |
| **7** | **Offline Media Kit Player**          | ⚪ **Not Started** |    0%    | Pending `media_kit` MPV hardware-accelerated video player integration.                                                                  |
| **8** | **Diagnostics Terminal & Polish**     | 🟡 **In Progress** |   66%    | Integrated `talker` logger and category/level filtered `DiagnosticWindow` log terminal viewer.                                          |

---

## 🚀 Getting Started

### Prerequisites

- **Dart SDK**: Version `^3.12.2` or higher
- **Flutter SDK**: Version `^3.24.0` or higher (compatible with Dart 3.12+)
- **Platform Development Tools**:
    - **Windows**: Visual Studio 2022 with C++ Desktop Development workload
  - **Linux**: `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`

### Installation & Build

1. **Clone the repository**:
   ```bash
   git clone https://github.com/p2kr/komorebi.git
   cd komorebi
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run Code Generation** *(required for Drift database & localization)*:
   ```bash
   # Generate Drift database schemas
   dart run build_runner build --delete-conflicting-outputs

   # Generate localization (intl) files
   dart run intl_utils:generate
   ```

4. **Run the application**:
   ```bash
   # For Windows Desktop
   flutter run -d windows

   # For Linux Desktop
   flutter run -d linux
   ```

---

## 📁 Project Structure

```text
lib/
├── crawlers/          # HTML parsing engines and DOM scraper logic (crawler_engine.dart)
├── intl/              # ARB localization files and generated localization classes
├── models/            # Drift SQLite table schemas and database data models
├── network/           # Embedded HTTP loopback proxy server (proxy_server.dart)
├── providers/         # Riverpod state providers, timers, and profile management
├── screens/           # UI screens (AppBar, Browser Mode, Crawlers, Dashboard, Discover, Local Collection, Settings)
├── services/          # Database, DAOs (ProfilesDao, ConfigsDao), MAL sync handler, and title parser
├── themes/            # Monochrome obsidian theme definitions and typography
├── utils/             # Constants, window initialization, Talker diagnostics, and MAL API client
├── widgets/           # Reusable UI components and scraping result tiles
└── main.dart          # Application entry point and ProviderScope bootstrap
```

---

## 📖 Documentation & References

For comprehensive engineering details, architectural blueprints, and migration guidelines from the legacy web stack,
explore our internal documentation:

- 🗺️ **[roadmap.md](file:///c:/Users/Prince/Documents/CODE/mal_viewer/docs/roadmap.md)**: Full Phase-by-Phase technical
  transition plan, code mapping, and schema blueprints.
- 📝 **[react_instructions.md](file:///c:/Users/Prince/Documents/CODE/mal_viewer/docs/react_instructions.md)**: Developer
  handover documentation detailing the original React/Express architecture and features.

---

## 📄 License

This project is licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0)** - see
the [LICENSE](file:///c:/Users/Prince/Documents/CODE/mal_viewer/LICENSE) file for details.

