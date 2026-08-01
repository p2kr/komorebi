package utils

import (
	"os"
	"strings"

	"github.com/joho/godotenv"
	"go.uber.org/zap"
)

type EnvConfig struct {
	MalClientSecret     string `env:"MAL_CLIENT_SECRET"`
	MalClientID         string `env:"MAL_CLIENT_ID"`
	AnilistClientID     string `env:"ANILIST_CLIENT_ID"`
	AnilistClientSecret string `env:"ANILIST_CLIENT_SECRET"`

	TrustedProxies []string `env:"KOMOREBI_TRUSTED_PROXIES"`
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
	if trustedProxies, isPresent := os.LookupEnv("KOMOREBI_TRUSTED_PROXIES"); isPresent {
		currentEnv.TrustedProxies = strings.Split(trustedProxies, ",")
	} else {
		logger.Warn("KOMOREBI_TRUSTED_PROXIES is not configured on server")
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

func Env() EnvConfig {
	return currentEnv
}
