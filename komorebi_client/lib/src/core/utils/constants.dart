const APP_NAME = "Komorebi";

const API_BASE_URL = "http://127.0.0.1:8080/api/v1";

/// komorebi (all lower case)
const KOMOREBI = "komorebi";

const DB_NAME = "app_db";
const DB_FILE_NAME = "$DB_NAME.sqlite";

/// https://p2kr.github.io/komorebi/
const MAL_OAUTH_REDIRECT_URL = "https://p2kr.github.io/komorebi/";

/// Vault location
const VAULT_LOC = "vault";

/// Set of configs stored in db
enum Settings {
  LAST_USED_PROFILE,
  THEME_MODE,
  LANGUAGE,
  AUTO_UPDATE,
  AUTO_UPDATE_INTERVAL,
  ANIME_CRAWLER_CONFIGS,
  MANGA_CRAWLER_CONFIGS,
  SWAP_ALTERNATE_TITLE,
}
