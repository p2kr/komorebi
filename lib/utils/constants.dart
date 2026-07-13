const APP_NAME = "Komorebi";

/// komorebi (all lower case)
const KOMOREBI = "komorebi";

const DB_NAME = "app_db";
const DB_FILE_NAME = "$DB_NAME.sqlite";

/// komorebi://auth-callback
const MAL_OAUTH_REDIRECT_URL = "komorebi://auth-callback";

/// Set of configs stored in db
enum Settings {
  LAST_USED_PROFILE,
  THEME_MODE,
  LANGUAGE,
  AUTO_UPDATE,
  AUTO_UPDATE_INTERVAL,
  ANIME_CRAWLER_CONFIGS,
  MANAGA_CRAWLER_CONFIGS,
  SWAP_ALTERNATE_TITLE,
}
