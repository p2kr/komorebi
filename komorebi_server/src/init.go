package src

import (
	"komorebi_server/src/db"
	"komorebi_server/src/utils"
)

// Init initializes all settings before starting the application
func Init() {
	utils.InitDefaultLogger()
	utils.InitEnv()
	db.InitDbClient()
}

func Close() {
	db.CloseDbClient()
}
