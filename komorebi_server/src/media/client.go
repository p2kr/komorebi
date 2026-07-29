package media

import "context"

// Client defines the interface contract for media provider clients (MAL, AniList, etc.).
type Client interface {
	GetUserAnimeList(ctx context.Context, username string, status string, accessToken string) (*PaginatedResponse, error)
	GetUserMangaList(ctx context.Context, username string, status string, accessToken string) (*PaginatedResponse, error)
}
