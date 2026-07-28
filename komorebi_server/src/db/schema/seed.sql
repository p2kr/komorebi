INSERT OR IGNORE INTO log_levels (name)
VALUES ('debug'),
       ('info'),
       ('warn'),
       ('error'),
       ('fatal'),
       ('panic');

INSERT OR IGNORE INTO sync_types (name)
VALUES ('sandbox'),
       ('mal'),
       ('anilist');

INSERT OR IGNORE INTO vault_item_statuses (name)
VALUES ('pending'),
       ('downloading'),
       ('completed'),
       ('failed');

INSERT OR IGNORE INTO config_keys (key)
VALUES ('LAST_USED_PROFILE'),
       ('THEME_MODE'),
       ('LANGUAGE'),
       ('AUTO_UPDATE'),
       ('AUTO_UPDATE_INTERVAL'),
       ('ANIME_CRAWLER_CONFIGS'),
       ('MANGA_CRAWLER_CONFIGS'),
       ('SWAP_ALTERNATE_TITLE');

