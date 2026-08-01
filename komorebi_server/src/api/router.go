package api

import (
	"komorebi_server/src/utils"
	"log/slog"
	"net/http"
	"time"

	ginzap "github.com/gin-contrib/zap"
	"github.com/gin-gonic/gin"
)

var router *gin.Engine
var startTime = time.Now()

var logger = utils.Logger()

func InitRouter() *gin.Engine {
	//gin.SetMode(gin.ReleaseMode)
	router = gin.New()

	setupMiddlewares()
	setupTrustedProxies()
	setupRoutesV1()

	return router
}

func healthCheck(c *gin.Context) {
	Ok(c, map[string]any{
		"version":  "1.0.0",
		"uptime":   time.Since(startTime).String(),
		"base_url": "/api/v1",
	})
}

func setupTrustedProxies() {
	trustedProxies := []string{"127.0.0.1"}
	trustedProxies = append(trustedProxies, utils.Env().TrustedProxies...)
	err := router.SetTrustedProxies(trustedProxies)
	if err != nil {
		slog.Error("error setting trusted proxies", "err", err)
	}
}

func setupMiddlewares() {
	router.Use(ginzap.Ginzap(utils.Logger(), "2006-01-02 15:04:05 07:00", true))
	router.Use(ginzap.RecoveryWithZap(utils.Logger(), true))
}

func setupRoutesV1() {
	router.GET("/", func(ctx *gin.Context) {
		Fail(ctx, http.StatusNotFound, "API_VERSION_TO_USE", "/api/v1")
	})
	v1 := router.Group("/api/v1")
	{
		v1.Any("/", healthCheck)
		v1.Any("/health", healthCheck)
	}
	{
		profile := v1.Group("/profile")
		profile.GET("/getAll", GetAllProfiles)
		profile.POST("/add", AddNewProfile)
		profile.DELETE("/delete", DeleteProfile)
	}
	{
		auth := v1.Group("/auth")
		auth.GET("/login", StartOAuthLogin)
		auth.GET("/callback", OAuthCallback)
		auth.POST("/sandbox", VerifySandboxProfile)
	}
	{
		config := v1.Group("/config")
		config.GET("/getAll", GetAllAppConfigs)
		config.GET("/get", GetAppConfig)
		config.POST("/set", SetAppConfig)
		config.DELETE("/delete", DeleteAppConfig)
	}
	{
		media := v1.Group("/media")
		media.GET("/anime", GetUserAnimeList)
		media.GET("/manga", GetUserMangaList)
	}
	{
		v1.GET("/crawler/fetch", FindDownloadableMedia)
		// v1.GET("/crawler/download", nil)
	}
}
