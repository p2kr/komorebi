package media

import "encoding/json"

// Raw MAL JSON structs for deserialization

type rawMalPicture struct {
	Medium string `json:"medium"`
	Large  string `json:"large"`
}

type rawMalAltTitles struct {
	Synonyms []string `json:"synonyms"`
	En       string   `json:"en"`
	Ja       string   `json:"ja"`
}

type rawMalNamedNode struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
}

type rawMalAnimeListStatus struct {
	Status             string   `json:"status"`
	Score              float64  `json:"score"`
	NumEpisodesWatched int      `json:"num_episodes_watched"`
	IsRewatching       bool     `json:"is_rewatching"`
	UpdatedAt          string   `json:"updated_at"`
	Tags               []string `json:"tags"`
	Comments           string   `json:"comments"`
}

type rawMalMangaListStatus struct {
	Status          string   `json:"status"`
	Score           float64  `json:"score"`
	NumVolumesRead  int      `json:"num_volumes_read"`
	NumChaptersRead int      `json:"num_chapters_read"`
	IsRereading     bool     `json:"is_rereading"`
	UpdatedAt       string   `json:"updated_at"`
	Tags            []string `json:"tags"`
	Comments        string   `json:"comments"`
}

type RawMalNode struct {
	ID                int               `json:"id"`
	Title             string            `json:"title"`
	MainPicture       *rawMalPicture    `json:"main_picture"`
	AlternativeTitles *rawMalAltTitles  `json:"alternative_titles"`
	Synopsis          string            `json:"synopsis"`
	Mean              *float64          `json:"mean"`
	Rank              *int              `json:"rank"`
	Popularity        *int              `json:"popularity"`
	NumEpisodes       *int              `json:"num_episodes"`
	NumChapters       *int              `json:"num_chapters"`
	NumVolumes        *int              `json:"num_volumes"`
	MediaType         string            `json:"media_type"`
	Status            string            `json:"status"`
	Genres            []rawMalNamedNode `json:"genres"`
	MyListStatus      *json.RawMessage  `json:"my_list_status"`
}

type rawMalItem struct {
	Node       RawMalNode       `json:"node"`
	ListStatus *json.RawMessage `json:"list_status"`
}

type rawMalPaging struct {
	Previous string `json:"previous"`
	Next     string `json:"next"`
}

type rawMalResponse struct {
	Data   []rawMalItem `json:"data"`
	Paging rawMalPaging `json:"paging"`
}
