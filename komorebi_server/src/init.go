package src

import (
	"komorebi_server/src/crawler"
	"komorebi_server/src/db"
	"komorebi_server/src/utils"
)

// Init initializes all settings before starting the application
func Init() {
	utils.InitDir()
	utils.InitDefaultLogger()
	utils.InitValidator()
	utils.InitEnv()

	db.InitDbClient()
	crawler.InitCrawler()
}

// Close closes all resources before exiting the application
func Close() {
	db.CloseDbClient()
}
