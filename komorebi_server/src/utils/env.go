package utils

import (
	"os"

	"github.com/joho/godotenv"
	"go.uber.org/zap"
)

type EnvConfig struct {
	MalClientSecret     string
	MalClientID         string
	AnilistClientID     string
	AnilistClientSecret string
}

var currentEnv EnvConfig

func InitEnv() {
	err := godotenv.Load(".env")
	if err != nil {
		logger.Error("error loading .env file", zap.Error(err))
	}

	currentEnv = EnvConfig{
		MalClientID:         os.Getenv("MAL_CLIENT_ID"),
		MalClientSecret:     os.Getenv("MAL_CLIENT_SECRET"),
		AnilistClientID:     os.Getenv("ANILIST_CLIENT_ID"),
		AnilistClientSecret: os.Getenv("ANILIST_CLIENT_SECRET"),
	}

	if currentEnv.MalClientID == "" {
		logger.Warn("MAL_CLIENT_ID is not configured on server")
	} else if currentEnv.MalClientSecret == "" {
		logger.Warn("MAL_CLIENT_SECRET is not configured on server")
	} else if currentEnv.AnilistClientID == "" {
		logger.Warn("ANILIST_CLIENT_ID is not configured on server")
	} else if currentEnv.AnilistClientSecret == "" {
		logger.Warn("ANILIST_CLIENT_SECRET is not configured on server")
	}
}

func GetEnv() EnvConfig {
	return currentEnv
}
