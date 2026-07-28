package api

import (
	"komorebi_server/src/db"
	dbClient "komorebi_server/src/db/generated"
	"net/http"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

func GetAllAppConfigs(c *gin.Context) {
	configs, err := dbClient.New(db.GetDbClient()).GetAllConfigs(c)
	if err != nil {
		logger.Error("error in fetching all configs", zap.Error(err))
		Fail(c, http.StatusInternalServerError, "DB_ERROR", err.Error())
		return
	}
	Ok(c, configs)
}

func GetAppConfig(c *gin.Context) {
	configKey := c.Query("config_key")
	if configKey == "" {
		configKey = c.Query("key")
	}

	config, err := dbClient.New(db.GetDbClient()).GetConfig(c, configKey)
	if err != nil {
		logger.Error("error in fetching config", zap.Error(err))
		Fail(c, http.StatusInternalServerError, "DB_ERROR", err.Error())
		return
	}
	Ok(c, config)
}

func SetAppConfig(c *gin.Context) {
	var req dbClient.AppConfig

	err := c.ShouldBindJSON(&req)
	if err != nil {
		Fail(c, http.StatusBadRequest, "INVALID_DATA", err.Error())
		return
	}
	err = db.ValidateAppConfig(req)
	if err != nil {
		Fail(c, http.StatusBadRequest, "INVALID_DATA", err.Error())
		return
	}

	tx, err := db.GetDbClient().Begin()
	if err != nil {
		logger.Error("error obtaining txn in setting config", zap.Error(err))
		Fail(c, http.StatusInternalServerError, "DB_ERROR", err.Error())
		return
	}

	appConfig, err := dbClient.New(tx).SetConfig(c, dbClient.SetConfigParams{
		ConfigKey:   req.ConfigKey,
		ConfigValue: req.ConfigValue,
	})

	if err != nil {
		_ = tx.Rollback()
		logger.Error("error in setting config", zap.Error(err))
		Fail(c, http.StatusInternalServerError, "DB_ERROR", err.Error())
		return
	}

	if err := tx.Commit(); err != nil {
		logger.Error("error committing transaction for setting config", zap.Error(err))
		Fail(c, http.StatusInternalServerError, "DB_ERROR", err.Error())
		return
	}

	Ok(c, appConfig)
}

func DeleteAppConfig(c *gin.Context) {
	configKey := c.Query("config_key")
	if configKey == "" {
		configKey = c.Query("key")
	}

	if configKey == "" {
		var body struct {
			ConfigKey string `json:"config_key"`
		}
		if err := c.ShouldBindJSON(&body); err == nil {
			configKey = body.ConfigKey
		}
	}

	if configKey == "" {
		Fail(c, http.StatusBadRequest, "BAD_REQUEST", "config_key is required")
		return
	}

	err := dbClient.New(db.GetDbClient()).DeleteConfig(c, configKey)
	if err != nil {
		logger.Error("error deleting config", zap.Error(err))
		Fail(c, http.StatusInternalServerError, "DB_ERROR", err.Error())
		return
	}

	Ok(c, gin.H{"config_key": configKey, "deleted": true})
}
