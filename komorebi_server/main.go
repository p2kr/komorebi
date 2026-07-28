package main

import (
	"komorebi_server/src"
	"komorebi_server/src/api"
	"komorebi_server/src/utils"
	"log/slog"
)

var logger = utils.GetLogger()

func main() {
	logger.Info("starting application")

	// Initialize settings
	src.Init()

	// Close resources
	defer src.Close()

	// Initialize Gin router
	router := api.InitRouter()

	err := router.Run(":8080") // TODO: generate port and set in file
	if err != nil {
		slog.Error("error starting application", "err", err)
	}

}
