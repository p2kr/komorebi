package api

import (
	"strconv"

	"komorebi_server/src/db"
	dbClient "komorebi_server/src/db/generated"
	"komorebi_server/src/media"
	"komorebi_server/src/utils"
	"net/http"

	"github.com/gin-gonic/gin"
)

type mediaParams struct {
	client      media.Client
	username    string
	status      string
	accessToken string
}

func parseMediaParams(c *gin.Context) (*mediaParams, bool) {
	idStr := c.Query("profile_id")

	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil || id <= 0 {
		Fail(c, http.StatusBadRequest, "INVALID_ID", "profile_id query parameter is required and must be an integer")
		return nil, false
	}

	queries := dbClient.New(db.GetDbClient())
	foundProfile, err := queries.FindProfileById(c.Request.Context(), id)
	if err != nil {
		Fail(c, http.StatusNotFound, "PROFILE_NOT_FOUND", "Profile not found")
		return nil, false
	}

	var accessToken string
	if foundProfile.AccessToken != nil {
		accessToken = *foundProfile.AccessToken
	}

	status := c.Query("status")

	return &mediaParams{
		client:      resolveMediaClient(foundProfile.SyncType),
		username:    foundProfile.Username,
		status:      status,
		accessToken: accessToken,
	}, true
}

func resolveMediaClient(syncTypeStr string) media.Client {
	provider := media.ParseProvider(syncTypeStr)

	switch provider {
	case media.ProviderAniList:
		return media.NewAniListClient(nil)
	case media.ProviderMAL:
		fallthrough
	default:
		return media.NewMalClient(utils.GetEnv().MalClientID, nil)
	}
}

// GetUserAnimeList handles GET /api/v1/media/anime
func GetUserAnimeList(c *gin.Context) {
	p, ok := parseMediaParams(c)
	if !ok {
		return
	}
	res, err := p.client.GetUserAnimeList(c.Request.Context(), p.username, p.status, p.accessToken)
	if err != nil {
		Fail(c, http.StatusInternalServerError, "FETCH_ANIME_FAILED", err.Error())
		return
	}

	Ok(c, res)
}

// GetUserMangaList handles GET /api/v1/media/manga
func GetUserMangaList(c *gin.Context) {
	p, ok := parseMediaParams(c)
	if !ok {
		return
	}
	res, err := p.client.GetUserMangaList(c.Request.Context(), p.username, p.status, p.accessToken)
	if err != nil {
		Fail(c, http.StatusInternalServerError, "FETCH_MANGA_FAILED", err.Error())
		return
	}

	Ok(c, res)
}
