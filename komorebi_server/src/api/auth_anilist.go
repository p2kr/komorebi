package api

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
)

func startAniListOAuthLogin(c *gin.Context) {
	// Dummy AniList OAuth login
	Fail(c, http.StatusNotImplemented, "NOT_IMPLEMENTED", "AniList OAuth not yet implemented")
}

func handleAniListOAuthCallback(c *gin.Context, session *authSession, code string) {
	// Dummy AniList OAuth callback
	session.errChan <- fmt.Errorf("AniList OAuth not yet implemented")
	Fail(c, http.StatusNotImplemented, "AUTH_ERROR", "AniList OAuth not yet implemented")
}
