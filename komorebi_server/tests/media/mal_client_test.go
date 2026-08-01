package media

import (
	"encoding/json"
	"komorebi_server/src"
	. "komorebi_server/src/media"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func init() {
	src.Init()
}

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
	require.NoError(t, json.Unmarshal([]byte(rawJSON), &node), "failed to unmarshal test JSON")

	item := MapMalAnimeToItem(&node, nil)

	assert.EqualValues(t, 1, item.ID, "expected ID 1")
	assert.Equal(t, "Cowboy Bebop", item.Title.UserPreferred)
	assert.Equal(t, "Cowboy Bebop", item.Title.Romanized)
	assert.Equal(t, "Cowboy Bebop", item.Title.English)
	assert.Equal(t, "カウボーイビバップ", item.Title.Native)
	assert.Equal(t, "https://example.com/med.jpg", item.CoverImage.Medium)
	require.NotNil(t, item.Episodes)
	assert.EqualValues(t, 26, *item.Episodes)
	require.Len(t, item.Genres, 2)
	assert.Equal(t, "Action", item.Genres[0])
	require.NotNil(t, item.ListStatus)
	require.NotNil(t, item.ListStatus.Status)
	assert.Equal(t, "watching", *item.ListStatus.Status)
	require.NotNil(t, item.ListStatus.Progress)
	assert.EqualValues(t, 12, *item.ListStatus.Progress)
	require.NotNil(t, item.ListStatus.Score)
	assert.EqualValues(t, 9, *item.ListStatus.Score)
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
	require.NoError(t, json.Unmarshal([]byte(rawNodeJSON), &node), "failed to unmarshal test node JSON")

	rawStatus := json.RawMessage(rawStatusJSON)
	item := MapMalMangaToItem(&node, &rawStatus)

	assert.EqualValues(t, 100, item.ID, "expected ID 100")
	require.NotNil(t, item.Chapters)
	assert.EqualValues(t, 162, *item.Chapters)
	require.NotNil(t, item.Volumes)
	assert.EqualValues(t, 18, *item.Volumes)
	require.NotNil(t, item.ListStatus)
	require.NotNil(t, item.ListStatus.Progress)
	assert.EqualValues(t, 162, *item.ListStatus.Progress)
}
