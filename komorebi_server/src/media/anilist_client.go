package media

import (
	"context"
	"net/http"
	"time"
)

// AniListClient implements media.Client for AniList GraphQL API.
type AniListClient struct {
	BaseURL    string
	HTTPClient *http.Client
}

func NewAniListClient(httpClient *http.Client) *AniListClient {
	if httpClient == nil {
		httpClient = &http.Client{Timeout: 15 * time.Second}
	}
	return &AniListClient{
		BaseURL:    "https://graphql.anilist.co",
		HTTPClient: httpClient,
	}
}

// GetUserAnimeList fetches user anime list from AniList API (stub implementation).
func (c *AniListClient) GetUserAnimeList(ctx context.Context, accessToken string, username string, status string) (*PaginatedResponse, error) {
	// TODO: Full AniList GraphQL query implementation
	return &PaginatedResponse{
		Data:   []Item{},
		Paging: PagingInfo{HasNextPage: false},
	}, nil
}

// GetUserMangaList fetches user manga list from AniList API (stub implementation).
func (c *AniListClient) GetUserMangaList(ctx context.Context, accessToken string, username string, status string) (*PaginatedResponse, error) {
	// TODO: Full AniList GraphQL query implementation
	return &PaginatedResponse{
		Data:   []Item{},
		Paging: PagingInfo{HasNextPage: false},
	}, nil
}
