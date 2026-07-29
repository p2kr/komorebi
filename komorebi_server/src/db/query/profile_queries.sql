-- name: GetAllProfiles :many
SELECT *
FROM profiles
ORDER BY updated_at DESC;

-- name: InsertProfile :one
INSERT INTO profiles (username, avatar_url, sync_type, access_token)
VALUES (?, ?, ?, ?)
RETURNING *;

-- name: UpdateProfile :one
UPDATE profiles
SET avatar_url= ?,
    access_token= ?
WHERE id = ?
RETURNING *;

-- name: UpdateProfileByUsernameAndSyncType :one
UPDATE profiles
SET avatar_url   = ?,
    access_token = ?
WHERE username = ?
  AND sync_type = ?
RETURNING *;

-- name: FindProfileByUsername :many
SELECT *
FROM profiles
WHERE username = ?;

-- name: FindProfileByUsernameAndSyncType :one
SELECT *
FROM profiles
WHERE username = ?
  AND sync_type = ?;

-- name: DeleteProfileById :exec
DELETE
FROM profiles
WHERE id = ?;

-- name: FindProfileById :one
SELECT *
FROM profiles
WHERE id = ?;