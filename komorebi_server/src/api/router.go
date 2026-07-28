package api

import (
	"komorebi_server/src/utils"
	"log/slog"
	"time"

	ginzap "github.com/gin-contrib/zap"
	"github.com/gin-gonic/gin"
)

var router *gin.Engine
var startTime = time.Now()

var logger = utils.GetLogger()

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
		"version": "1.0.0",
		"uptime":  time.Since(startTime).String(),
	})
}

func setupTrustedProxies() {
	err := router.SetTrustedProxies(
		[]string{"127.0.0.1"},
	)
	if err != nil {
		slog.Error("error setting trusted proxies", "err", err)
	}
}

func setupMiddlewares() {
	router.Use(ginzap.Ginzap(utils.GetLogger(), "2006-01-02 15:04:05 07:00", true))
	router.Use(ginzap.RecoveryWithZap(utils.GetLogger(), true))
}

func setupRoutesV1() {
	v1 := router.Group("/api/v1")
	{
		v1.Any("/", healthCheck)
		v1.Any("/health", healthCheck)
	}
	{
		v1.GET("/getAllProfiles", GetAllProfiles)
		v1.POST("/addNewProfile", AddNewProfile)
		v1.DELETE("/deleteProfile", DeleteProfile)
		v1.POST("/deleteProfile", DeleteProfile)
	}
	{
		v1.GET("/getAllConfigs", GetAllAppConfigs)
		v1.GET("/getConfig", GetAppConfig)
		v1.POST("/setConfig", SetAppConfig)
		v1.DELETE("/deleteConfig", DeleteAppConfig)
		v1.POST("/deleteConfig", DeleteAppConfig)
	}
}
