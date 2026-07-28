package media

import (
	"encoding/json"
	. "komorebi_server/src/media"
	"testing"
)

func TestMapMalAnimeToItem(t *testing.T) {
	rawJSON := `{
		"id": 1,
		"title": "Cowboy Bebop",
		"main_picture": {
			"medium": "https://example.com/med.jpg",
			"large": "https://example.com/large.jpg"
		},
		"alternative_titles": {
			"synonyms": ["Bebop"],
			"en": "Cowboy Bebop",
			"ja": "カウボーイビバップ"
		},
		"synopsis": "Space bounty hunters in 2071.",
		"mean": 8.75,
		"rank": 30,
		"popularity": 40,
		"num_episodes": 26,
		"media_type": "tv",
		"status": "finished_airing",
		"genres": [
			{"id": 1, "name": "Action"},
			{"id": 24, "name": "Sci-Fi"}
		],
		"my_list_status": {
			"status": "watching",
			"score": 9,
			"num_episodes_watched": 12,
			"is_rewatching": false,
			"tags": ["favorite"],
			"comments": "Great show!"
		}
	}`

	var node RawMalNode
	if err := json.Unmarshal([]byte(rawJSON), &node); err != nil {
		t.Fatalf("failed to unmarshal test JSON: %v", err)
	}

	item := MapMalAnimeToItem(&node, nil)

	if item.ID != 1 {
		t.Errorf("expected ID 1, got %d", item.ID)
	}
	if item.Title.UserPreferred != "Cowboy Bebop" || item.Title.Romanized != "Cowboy Bebop" {
		t.Errorf("expected title 'Cowboy Bebop', got '%s'", item.Title.UserPreferred)
	}
	if item.Title.English != "Cowboy Bebop" || item.Title.Native != "カウボーイビバップ" {
		t.Errorf("unexpected alt titles: %+v", item.Title)
	}
	if item.CoverImage.Medium != "https://example.com/med.jpg" {
		t.Errorf("unexpected medium cover image: %s", item.CoverImage.Medium)
	}
	if item.Episodes == nil || *item.Episodes != 26 {
		t.Errorf("expected 26 episodes, got %v", item.Episodes)
	}
	if len(item.Genres) != 2 || item.Genres[0] != "Action" {
		t.Errorf("unexpected genres: %v", item.Genres)
	}
	if item.ListStatus == nil {
		t.Fatal("expected list status to be non-nil")
	}
	if item.ListStatus.Status == nil || *item.ListStatus.Status != "watching" {
		t.Errorf("expected status 'watching', got %v", item.ListStatus.Status)
	}
	if item.ListStatus.Progress == nil || *item.ListStatus.Progress != 12 {
		t.Errorf("expected progress 12, got %v", item.ListStatus.Progress)
	}
	if item.ListStatus.Score == nil || *item.ListStatus.Score != 9 {
		t.Errorf("expected score 9, got %v", item.ListStatus.Score)
	}
}

func TestMapMalMangaToItem(t *testing.T) {
	rawNodeJSON := `{
		"id": 100,
		"title": "Monster",
		"num_chapters": 162,
		"num_volumes": 18,
		"media_type": "manga",
		"status": "finished"
	}`

	rawStatusJSON := `{
		"status": "completed",
		"score": 10,
		"num_chapters_read": 162,
		"num_volumes_read": 18,
		"is_rereading": false
	}`

	var node RawMalNode
	if err := json.Unmarshal([]byte(rawNodeJSON), &node); err != nil {
		t.Fatalf("failed to unmarshal test node JSON: %v", err)
	}

	rawStatus := json.RawMessage(rawStatusJSON)
	item := MapMalMangaToItem(&node, &rawStatus)

	if item.ID != 100 {
		t.Errorf("expected ID 100, got %d", item.ID)
	}
	if item.Chapters == nil || *item.Chapters != 162 {
		t.Errorf("expected 162 chapters, got %v", item.Chapters)
	}
	if item.Volumes == nil || *item.Volumes != 18 {
		t.Errorf("expected 18 volumes, got %v", item.Volumes)
	}
	if item.ListStatus == nil || item.ListStatus.Progress == nil || *item.ListStatus.Progress != 162 {
		t.Errorf("unexpected list status progress: %+v", item.ListStatus)
	}
}
