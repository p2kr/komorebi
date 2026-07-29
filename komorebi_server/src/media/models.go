package media

import "strings"

// Provider represents media service providers (MAL, AniList, etc.).
type Provider string

const (
	ProviderMAL     Provider = "mal"
	ProviderAniList Provider = "anilist"
	ProviderSandbox Provider = "sandbox"
)

func (p Provider) String() string {
	return string(p)
}

func ParseProvider(s string) Provider {
	switch strings.ToLower(s) {
	case "anilist":
		return ProviderAniList
	case "sandbox":
		return ProviderSandbox
	case "mal":
		fallthrough
	default:
		return ProviderMAL
	}
}

// MalListType represents the MyAnimeList list type (animelist vs mangalist).
type MalListType string

const (
	MalListTypeAnime MalListType = "animelist"
	MalListTypeManga MalListType = "mangalist"
)

func (l MalListType) String() string {
	return string(l)
}

// Title contains title variants harmonized across MAL and AniList.
type Title struct {
	Romanized     string `json:"romanized,omitempty"`
	English       string `json:"english,omitempty"`
	Native        string `json:"native,omitempty"`
	UserPreferred string `json:"user_preferred,omitempty"`
}

// CoverImage contains image URL variants and optional accent color code.
type CoverImage struct {
	ExtraLarge string  `json:"extra_large,omitempty"`
	Large      string  `json:"large,omitempty"`
	Medium     string  `json:"medium,omitempty"`
	Color      *string `json:"color,omitempty"`
}

// ListStatus represents user library status details.
type ListStatus struct {
	Status          *string  `json:"status,omitempty"`
	Score           *float64 `json:"score,omitempty"`
	Progress        *int     `json:"progress,omitempty"`
	ProgressVolumes *int     `json:"progress_volumes,omitempty"`
	IsRewatching    bool     `json:"is_rewatching"`
	RepeatCount     *int     `json:"repeat_count,omitempty"`
	Tags            []string `json:"tags,omitempty"`
	Comments        *string  `json:"comments,omitempty"`
	UpdatedAt       *string  `json:"updated_at,omitempty"`
}

// Item represents a harmonized anime or manga entry.
type Item struct {
	ID          int         `json:"id"`
	IDMal       *int        `json:"id_mal,omitempty"`
	Provider    string      `json:"provider"`
	Title       Title       `json:"title"`
	CoverImage  CoverImage  `json:"cover_image"`
	BannerImage *string     `json:"banner_image,omitempty"`
	Synopsis    *string     `json:"synopsis,omitempty"`
	Format      *string     `json:"format,omitempty"`
	Status      *string     `json:"status,omitempty"`
	Season      *string     `json:"season,omitempty"`
	SeasonYear  *int        `json:"season_year,omitempty"`
	MeanScore   *float64    `json:"mean_score,omitempty"`
	Rank        *int        `json:"rank,omitempty"`
	Popularity  *int        `json:"popularity,omitempty"`
	Episodes    *int        `json:"episodes,omitempty"`
	Chapters    *int        `json:"chapters,omitempty"`
	Volumes     *int        `json:"volumes,omitempty"`
	Duration    *int        `json:"duration,omitempty"`
	Genres      []string    `json:"genres,omitempty"`
	Synonyms    []string    `json:"synonyms,omitempty"`
	IsAdult     bool        `json:"is_adult"`
	ListStatus  *ListStatus `json:"list_status,omitempty"`
}

// PagingInfo describes pagination metadata.
type PagingInfo struct {
	Previous    *string `json:"previous,omitempty"`
	Next        *string `json:"next,omitempty"`
	HasNextPage bool    `json:"has_next_page"`
	Page        int     `json:"page,omitempty"`
	PerPage     int     `json:"per_page,omitempty"`
}

// PaginatedResponse is the pagination wrapper for media item lists.
type PaginatedResponse struct {
	Data   []Item     `json:"data"`
	Paging PagingInfo `json:"paging"`
}
