package api

import (
	"komorebi_server/src/utils"
	"log/slog"
	"time"

	ginzap "github.com/gin-contrib/zap"
	"github.com/gin-gonic/gin"
)

var router = gin.New()

func InitRouter() *gin.Engine {
	setupMiddlewares()
	setupRoutes()
	setupTrustedProxies()

	return router
}

func setupRoutes() {
	router.GET("/", statusCheck)
}

func statusCheck(c *gin.Context) {
	c.JSON(200, gin.H{
		"status": "ok",
	})
}

func setupTrustedProxies() {
	err := router.SetTrustedProxies(
		[]string{"127.0.0.1"},
	)
	if err != nil {
		slog.Error("error setting trusted proxies: ", err)
	}
}

func setupMiddlewares() {
	router.Use(ginzap.Ginzap(utils.GetLogger(), time.RFC3339, true))
	router.Use(ginzap.RecoveryWithZap(utils.GetLogger(), true))
}
