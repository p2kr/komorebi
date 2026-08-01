package utils

import (
	"fmt"
	"os"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

var logger *zap.Logger

// InitDefaultLogger Inits the default logger
func InitDefaultLogger() {
	var l zap.Config
	if os.Getenv("GIN_MODE") != "release" {
		l = zap.NewDevelopmentConfig()
	} else {
		l = zap.NewProductionConfig()
	}

	logPath := AppLogsPath()
	l.OutputPaths = []string{"stdout", logPath}
	l.EncoderConfig.EncodeTime = zapcore.ISO8601TimeEncoder

	var err error
	logger, err = l.Build()
	if err != nil {
		fmt.Println("Failed to build logger:", err)
		logger = zap.NewNop()
	}

	logger.Info("Logger initialized at ", zap.String("path", logPath))

	defer func(logger *zap.Logger) {
		err := logger.Sync()
		if err != nil {
			logger.Error("Failed to sync logger", zap.Error(err))
		}
	}(logger)

}

func Logger() *zap.Logger {
	if logger == nil {
		InitDefaultLogger()
	}
	return logger
}
