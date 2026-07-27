package main

import (
	"komorebi_server/src/api"
	"komorebi_server/src/utils"
	"log/slog"
)

func main() {
	slog.Info("starting application")

	// Initialize settings
	utils.Init()

	// Initialize Gin router
	router := api.InitRouter()

	err := router.Run(":8080") // TODO: generate port and set in file
	if err != nil {
		slog.Error("error starting application: ", err)
	}

}
