-- name: GetConfig :one
SELECT *
FROM app_configs
WHERE config_key = ?;

-- name: SetConfig :one
INSERT INTO app_configs (config_key, config_value)
VALUES (?, ?)
ON CONFLICT (config_key) DO UPDATE SET config_value = EXCLUDED.config_value
RETURNING *;

-- name: DeleteConfig :exec
DELETE
FROM app_configs
WHERE config_key = ?;

-- name: GetAllConfigs :many
SELECT *
FROM app_configs;

