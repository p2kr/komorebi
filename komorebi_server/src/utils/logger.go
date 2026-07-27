package utils

import (
	"os"

	"go.uber.org/zap"
)

var logger *zap.Logger

// Inits the default logger
func initDefaultLogger() {
	if os.Getenv("GIN_MODE") != "release" {
		logger, _ = zap.NewDevelopment()
	}
	logger, _ = zap.NewProduction()
}

func GetLogger() *zap.Logger {
	return logger
}
