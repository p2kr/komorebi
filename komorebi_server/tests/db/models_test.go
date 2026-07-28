package db

import (
	"encoding/json"
	dbClient "komorebi_server/src/db/generated"
	"testing"
	"time"
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
	if err != nil {
		t.Fatalf("failed to marshal Profile: %v", err)
	}

	var unmarshaled dbClient.Profile
	err = json.Unmarshal(data, &unmarshaled)
	if err != nil {
		t.Fatalf("failed to unmarshal Profile: %v", err)
	}

	if unmarshaled.ID != original.ID {
		t.Errorf("ID mismatch: got %d, want %d", unmarshaled.ID, original.ID)
	}
	if unmarshaled.Username != original.Username {
		t.Errorf("Username mismatch: got %s, want %s", unmarshaled.Username, original.Username)
	}
	if unmarshaled.SyncType != original.SyncType {
		t.Errorf("SyncType mismatch: got %s, want %s", unmarshaled.SyncType, original.SyncType)
	}
	if unmarshaled.AvatarUrl == nil || *unmarshaled.AvatarUrl != avatar {
		t.Errorf("AvatarUrl mismatch: got %v, want %s", unmarshaled.AvatarUrl, avatar)
	}
	if unmarshaled.AccessToken == nil || *unmarshaled.AccessToken != token {
		t.Errorf("AccessToken mismatch: got %v, want %s", unmarshaled.AccessToken, token)
	}

	// Test with nil pointers
	originalNil := dbClient.Profile{
		ID:       1,
		Username: "bob",
		SyncType: "ANILIST",
	}

	dataNil, err := json.Marshal(originalNil)
	if err != nil {
		t.Fatalf("failed to marshal Profile with nil pointers: %v", err)
	}

	var unmarshaledNil dbClient.Profile
	if err := json.Unmarshal(dataNil, &unmarshaledNil); err != nil {
		t.Fatalf("failed to unmarshal Profile: %v", err)
	}
	if unmarshaledNil.AvatarUrl != nil {
		t.Errorf("expected nil AvatarUrl, got %v", unmarshaledNil.AvatarUrl)
	}
	if unmarshaledNil.AccessToken != nil {
		t.Errorf("expected nil AccessToken, got %v", unmarshaledNil.AccessToken)
	}
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
	if err != nil {
		t.Fatalf("failed to marshal AppConfig: %v", err)
	}

	var decoded dbClient.AppConfig
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("failed to unmarshal AppConfig: %v", err)
	}

	if decoded.ConfigKey != "theme" {
		t.Errorf("expected ConfigKey 'theme', got %q", decoded.ConfigKey)
	}
	if decoded.ConfigValue == nil || *decoded.ConfigValue != "light_mode" {
		t.Errorf("expected ConfigValue 'light_mode', got %v", decoded.ConfigValue)
	}
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
	if err != nil {
		t.Fatalf("failed to marshal VaultItem: %v", err)
	}

	var decoded dbClient.VaultItem
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("failed to unmarshal VaultItem: %v", err)
	}

	if decoded.ID != 10 {
		t.Errorf("expected ID 10, got %d", decoded.ID)
	}
	if decoded.Title != "Raw Title" {
		t.Errorf("expected Title 'Raw Title', got %q", decoded.Title)
	}
	if decoded.ParsedTitle == nil || *decoded.ParsedTitle != parsedTitle {
		t.Errorf("expected ParsedTitle %q, got %v", parsedTitle, decoded.ParsedTitle)
	}
	if decoded.TotalBytes == nil || *decoded.TotalBytes != totalBytes {
		t.Errorf("expected TotalBytes %d, got %v", totalBytes, decoded.TotalBytes)
	}
	if decoded.Progress != 45.5 {
		t.Errorf("expected Progress 45.5, got %f", decoded.Progress)
	}
	if decoded.DownloadSpeed == nil || *decoded.DownloadSpeed != speed {
		t.Errorf("expected DownloadSpeed %f, got %v", speed, decoded.DownloadSpeed)
	}
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
	if err != nil {
		t.Fatalf("failed to marshal AppLog: %v", err)
	}

	var decoded dbClient.AppLog
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("failed to unmarshal AppLog: %v", err)
	}

	if decoded.Level != "ERROR" || decoded.Category != "NETWORK" || decoded.Message != "Connection timed out" {
		t.Errorf("mismatch in decoded AppLog fields: %+v", decoded)
	}
	if decoded.Details == nil || *decoded.Details != details {
		t.Errorf("expected Details %q, got %v", details, decoded.Details)
	}
}

func TestLookupModelsJSON(t *testing.T) {
	ck := dbClient.ConfigKey{Key: "theme"}
	ckData, err := json.Marshal(ck)
	if err != nil {
		t.Fatalf("failed to marshal ConfigKey: %v", err)
	}
	var unmarshaledCK dbClient.ConfigKey
	if err := json.Unmarshal(ckData, &unmarshaledCK); err != nil || unmarshaledCK.Key != "theme" {
		t.Errorf("ConfigKey unmarshal failed: got %+v", unmarshaledCK)
	}

	ll := dbClient.LogLevel{Name: "INFO"}
	llData, err := json.Marshal(ll)
	if err != nil {
		t.Fatalf("failed to marshal LogLevel: %v", err)
	}
	var unmarshaledLL dbClient.LogLevel
	if err := json.Unmarshal(llData, &unmarshaledLL); err != nil || unmarshaledLL.Name != "INFO" {
		t.Errorf("LogLevel unmarshal failed: got %+v", unmarshaledLL)
	}

	st := dbClient.SyncType{Name: "MAL"}
	stData, err := json.Marshal(st)
	if err != nil {
		t.Fatalf("failed to marshal SyncType: %v", err)
	}
	var unmarshaledST dbClient.SyncType
	if err := json.Unmarshal(stData, &unmarshaledST); err != nil || unmarshaledST.Name != "MAL" {
		t.Errorf("SyncType unmarshal failed: got %+v", unmarshaledST)
	}

	vis := dbClient.VaultItemStatus{Name: "COMPLETED"}
	visData, err := json.Marshal(vis)
	if err != nil {
		t.Fatalf("failed to marshal VaultItemStatus: %v", err)
	}
	var unmarshaledVIS dbClient.VaultItemStatus
	if err := json.Unmarshal(visData, &unmarshaledVIS); err != nil || unmarshaledVIS.Name != "COMPLETED" {
		t.Errorf("VaultItemStatus unmarshal failed: got %+v", unmarshaledVIS)
	}
}
