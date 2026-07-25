const APP_NAME = "Komorebi";

/// komorebi (all lower case)
const KOMOREBI = "komorebi";

const DB_NAME = "app_db";
const DB_FILE_NAME = "$DB_NAME.sqlite";

/// https://p2kr.github.io/komorebi/
const MAL_OAUTH_REDIRECT_URL = "https://p2kr.github.io/komorebi/";

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
