CREATE TABLE IF NOT EXISTS log_levels
(
    name TEXT PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS sync_types
(
    name TEXT PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS vault_item_statuses
(
    name TEXT PRIMARY KEY
);


CREATE TABLE IF NOT EXISTS config_keys
(
    key TEXT PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS app_configs
(
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    config_key   TEXT    NOT NULL UNIQUE REFERENCES config_keys (key),
    config_value TEXT,
    created_at   INTEGER NOT NULL DEFAULT (unixepoch('subsec') * 1000),
    updated_at   INTEGER NOT NULL DEFAULT (unixepoch('subsec') * 1000)
);

CREATE TABLE IF NOT EXISTS app_logs
(
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp  INTEGER NOT NULL DEFAULT (unixepoch('subsec') * 1000),
    level      TEXT    NOT NULL DEFAULT 'debug' REFERENCES log_levels (name),
    category   TEXT    NOT NULL DEFAULT 'system',
    message    TEXT    NOT NULL,
    details    TEXT,
    created_at INTEGER NOT NULL DEFAULT (unixepoch('subsec') * 1000),
    updated_at INTEGER NOT NULL DEFAULT (unixepoch('subsec') * 1000)
);

CREATE TABLE IF NOT EXISTS profiles
(
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    username     TEXT    NOT NULL,
    avatar_url   TEXT,
    sync_type    TEXT    NOT NULL DEFAULT 'sandbox' REFERENCES sync_types (name),
    access_token TEXT,
    created_at   INTEGER NOT NULL DEFAULT (unixepoch('subsec') * 1000),
    updated_at   INTEGER NOT NULL DEFAULT (unixepoch('subsec') * 1000),
    UNIQUE (username, sync_type)
);

CREATE TABLE IF NOT EXISTS vault_items
(
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    title          TEXT    NOT NULL,
    parsed_title   TEXT,
    file_path      TEXT,
    total_bytes    BIGINT,
    download_url   TEXT    NOT NULL,
    status         TEXT    NOT NULL DEFAULT 'pending' REFERENCES vault_item_statuses (name),
    download_bytes BIGINT,
    progress       REAL    NOT NULL DEFAULT 0,
    download_speed REAL,
    message        TEXT,
    created_at     INTEGER NOT NULL DEFAULT (unixepoch('subsec') * 1000),
    updated_at     INTEGER NOT NULL DEFAULT (unixepoch('subsec') * 1000)
);

-- Triggers to automatically update updated_at on ROW update
CREATE TRIGGER IF NOT EXISTS update_app_configs_updated_at
    AFTER UPDATE
    ON app_configs
    FOR EACH ROW
    WHEN OLD.updated_at IS NEW.updated_at AND OLD.updated_at IS NOT (unixepoch('subsec') * 1000)
BEGIN
    UPDATE app_configs SET updated_at = (unixepoch('subsec') * 1000) WHERE id = OLD.id;
END;

CREATE TRIGGER IF NOT EXISTS update_app_logs_updated_at
    AFTER UPDATE
    ON app_logs
    FOR EACH ROW
    WHEN OLD.updated_at IS NEW.updated_at AND OLD.updated_at IS NOT (unixepoch('subsec') * 1000)
BEGIN
    UPDATE app_logs SET updated_at = (unixepoch('subsec') * 1000) WHERE id = OLD.id;
END;

CREATE TRIGGER IF NOT EXISTS update_profiles_updated_at
    AFTER UPDATE
    ON profiles
    FOR EACH ROW
    WHEN OLD.updated_at IS NEW.updated_at AND OLD.updated_at IS NOT (unixepoch('subsec') * 1000)
BEGIN
    UPDATE profiles SET updated_at = (unixepoch('subsec') * 1000) WHERE id = OLD.id;
END;

CREATE TRIGGER IF NOT EXISTS update_vault_items_updated_at
    AFTER UPDATE
    ON vault_items
    FOR EACH ROW
    WHEN OLD.updated_at IS NEW.updated_at AND OLD.updated_at IS NOT (unixepoch('subsec') * 1000)
BEGIN
    UPDATE vault_items SET updated_at = (unixepoch('subsec') * 1000) WHERE id = OLD.id;
END;
