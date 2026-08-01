package db

import (
	"encoding/json"
	dbClient "komorebi_server/src/db/generated"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestProfileJSON(t *testing.T) {
	now := time.Now().UnixMilli()
	avatar := "https://example.com/pic.jpg"
	token := "token123"

	original := dbClient.Profile{
		ID:          42,
		Username:    "alice",
		AvatarUrl:   &avatar,
		SyncType:    "MAL",
		AccessToken: &token,
		CreatedAt:   now,
		UpdatedAt:   now,
	}

	data, err := json.Marshal(original)
	require.NoError(t, err, "failed to marshal Profile")

	var unmarshaled dbClient.Profile
	err = json.Unmarshal(data, &unmarshaled)
	require.NoError(t, err, "failed to unmarshal Profile")

	assert.Equal(t, original.ID, unmarshaled.ID, "ID mismatch")
	assert.Equal(t, original.Username, unmarshaled.Username, "Username mismatch")
	assert.Equal(t, original.SyncType, unmarshaled.SyncType, "SyncType mismatch")
	require.NotNil(t, unmarshaled.AvatarUrl, "expected AvatarUrl to be non-nil")
	assert.Equal(t, avatar, *unmarshaled.AvatarUrl, "AvatarUrl mismatch")
	// AccessToken has json:"-" tag so it is intentionally omitted from JSON
	assert.Nil(t, unmarshaled.AccessToken, "AccessToken should be nil after JSON unmarshal due to json:\"-\" tag")

	// Test with nil pointers
	originalNil := dbClient.Profile{
		ID:       1,
		Username: "bob",
		SyncType: "ANILIST",
	}

	dataNil, err := json.Marshal(originalNil)
	require.NoError(t, err, "failed to marshal Profile with nil pointers")

	var unmarshaledNil dbClient.Profile
	require.NoError(t, json.Unmarshal(dataNil, &unmarshaledNil), "failed to unmarshal Profile")

	assert.Nil(t, unmarshaledNil.AvatarUrl, "expected nil AvatarUrl")
	assert.Nil(t, unmarshaledNil.AccessToken, "expected nil AccessToken")
}

func TestAppConfigJSON(t *testing.T) {
	val := "light_mode"
	cfg := dbClient.AppConfig{
		ID:          1,
		ConfigKey:   "theme",
		ConfigValue: &val,
		CreatedAt:   time.Now().UnixMilli(),
		UpdatedAt:   time.Now().UnixMilli(),
	}

	data, err := json.Marshal(cfg)
	require.NoError(t, err, "failed to marshal AppConfig")

	var decoded dbClient.AppConfig
	require.NoError(t, json.Unmarshal(data, &decoded), "failed to unmarshal AppConfig")

	assert.Equal(t, "theme", decoded.ConfigKey, "expected ConfigKey 'theme'")
	require.NotNil(t, decoded.ConfigValue, "expected ConfigValue to be non-nil")
	assert.Equal(t, "light_mode", *decoded.ConfigValue, "expected ConfigValue 'light_mode'")
}

func TestVaultItemJSON(t *testing.T) {
	parsedTitle := "Clean Title"
	totalBytes := int64(104857600)
	msg := "Downloading..."
	speed := 1024.5

	item := dbClient.VaultItem{
		ID:            10,
		Title:         "Raw Title",
		ParsedTitle:   &parsedTitle,
		TotalBytes:    &totalBytes,
		DownloadUrl:   "https://example.com/file.mp4",
		Status:        "DOWNLOADING",
		Progress:      45.5,
		DownloadSpeed: &speed,
		Message:       &msg,
	}

	data, err := json.Marshal(item)
	require.NoError(t, err, "failed to marshal VaultItem")

	var decoded dbClient.VaultItem
	require.NoError(t, json.Unmarshal(data, &decoded), "failed to unmarshal VaultItem")

	assert.Equal(t, int64(10), decoded.ID, "expected ID 10")
	assert.Equal(t, "Raw Title", decoded.Title, "expected Title 'Raw Title'")
	require.NotNil(t, decoded.ParsedTitle, "expected ParsedTitle to be non-nil")
	assert.Equal(t, parsedTitle, *decoded.ParsedTitle, "expected ParsedTitle mismatch")
	require.NotNil(t, decoded.TotalBytes, "expected TotalBytes to be non-nil")
	assert.Equal(t, totalBytes, *decoded.TotalBytes, "expected TotalBytes mismatch")
	assert.Equal(t, 45.5, decoded.Progress, "expected Progress mismatch")
	require.NotNil(t, decoded.DownloadSpeed, "expected DownloadSpeed to be non-nil")
	assert.Equal(t, speed, *decoded.DownloadSpeed, "expected DownloadSpeed mismatch")
}

func TestAppLogJSON(t *testing.T) {
	details := "Stacktrace snippet"
	now := time.Now().UnixMilli()

	appLog := dbClient.AppLog{
		ID:        1,
		Timestamp: now,
		Level:     "ERROR",
		Category:  "NETWORK",
		Message:   "Connection timed out",
		Details:   &details,
		CreatedAt: now,
		UpdatedAt: now,
	}

	data, err := json.Marshal(appLog)
	require.NoError(t, err, "failed to marshal AppLog")

	var decoded dbClient.AppLog
	require.NoError(t, json.Unmarshal(data, &decoded), "failed to unmarshal AppLog")

	assert.Equal(t, "ERROR", decoded.Level)
	assert.Equal(t, "NETWORK", decoded.Category)
	assert.Equal(t, "Connection timed out", decoded.Message)
	require.NotNil(t, decoded.Details)
	assert.Equal(t, details, *decoded.Details)
}

func TestLookupModelsJSON(t *testing.T) {
	ck := dbClient.ConfigKey{Key: "theme"}
	ckData, err := json.Marshal(ck)
	require.NoError(t, err, "failed to marshal ConfigKey")
	var unmarshaledCK dbClient.ConfigKey
	require.NoError(t, json.Unmarshal(ckData, &unmarshaledCK))
	assert.Equal(t, "theme", unmarshaledCK.Key, "ConfigKey unmarshal failed")

	ll := dbClient.LogLevel{Name: "INFO"}
	llData, err := json.Marshal(ll)
	require.NoError(t, err, "failed to marshal LogLevel")
	var unmarshaledLL dbClient.LogLevel
	require.NoError(t, json.Unmarshal(llData, &unmarshaledLL))
	assert.Equal(t, "INFO", unmarshaledLL.Name, "LogLevel unmarshal failed")

	st := dbClient.SyncType{Name: "MAL"}
	stData, err := json.Marshal(st)
	require.NoError(t, err, "failed to marshal SyncType")
	var unmarshaledST dbClient.SyncType
	require.NoError(t, json.Unmarshal(stData, &unmarshaledST))
	assert.Equal(t, "MAL", unmarshaledST.Name, "SyncType unmarshal failed")

	vis := dbClient.VaultItemStatus{Name: "COMPLETED"}
	visData, err := json.Marshal(vis)
	require.NoError(t, err, "failed to marshal VaultItemStatus")
	var unmarshaledVIS dbClient.VaultItemStatus
	require.NoError(t, json.Unmarshal(visData, &unmarshaledVIS))
	assert.Equal(t, "COMPLETED", unmarshaledVIS.Name, "VaultItemStatus unmarshal failed")
}
