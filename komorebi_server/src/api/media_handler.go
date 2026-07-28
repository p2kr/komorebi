package api

import (
	"komorebi_server/src/media"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

type mediaParams struct {
	client      media.Client
	username    string
	status      string
	accessToken string
}

func parseMediaParams(c *gin.Context) mediaParams {
	username := c.Query("username")
	status := c.Query("status")
	accessToken := c.Query("access_token")

	if accessToken == "" {
		authHeader := c.GetHeader("Authorization")
		if after, ok := strings.CutPrefix(authHeader, "Bearer "); ok {
			accessToken = after
		}
	}

	return mediaParams{
		client:      resolveMediaClient(c),
		username:    username,
		status:      status,
		accessToken: accessToken,
	}
}

func resolveMediaClient(c *gin.Context) media.Client {
	provider := strings.ToLower(c.Query("provider"))
	syncType := strings.ToLower(c.Query("sync_type"))

	if provider == "" && syncType != "" {
		if strings.Contains(syncType, "anilist") {
			provider = "anilist"
		} else if strings.Contains(syncType, "mal") {
			provider = "mal"
		}
	}

	clientID := c.Query("client_id")

	switch provider {
	case "anilist":
		return media.NewAniListClient(nil)
	case "mal":
		fallthrough
	default:
		return media.NewMalClient(clientID, nil)
	}
}

// GetUserAnimeList handles GET /api/v1/media/anime
func GetUserAnimeList(c *gin.Context) {
	p := parseMediaParams(c)
	res, err := p.client.GetUserAnimeList(c.Request.Context(), p.accessToken, p.username, p.status)
	if err != nil {
		Fail(c, http.StatusInternalServerError, "FETCH_ANIME_FAILED", err.Error())
		return
	}

	Ok(c, res)
}

// GetUserMangaList handles GET /api/v1/media/manga
func GetUserMangaList(c *gin.Context) {
	p := parseMediaParams(c)
	res, err := p.client.GetUserMangaList(c.Request.Context(), p.accessToken, p.username, p.status)
	if err != nil {
		Fail(c, http.StatusInternalServerError, "FETCH_MANGA_FAILED", err.Error())
		return
	}

	Ok(c, res)
}
