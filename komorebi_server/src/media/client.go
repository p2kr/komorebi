package media

import "context"

// Client defines the interface contract for media provider clients (MAL, AniList, etc.).
type Client interface {
	GetUserAnimeList(ctx context.Context, accessToken string, username string, status string) (*PaginatedResponse, error)
	GetUserMangaList(ctx context.Context, accessToken string, username string, status string) (*PaginatedResponse, error)
}
