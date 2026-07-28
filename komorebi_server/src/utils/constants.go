package utils

import "path"

const (
	AppDbDriver = "sqlite"
)

func AppDbPath() string   { return path.Join("com.p2kr", "Komorebi", "app_db.db") }
func AppLogsPath() string { return path.Join("com.p2kr", "Komorebi", "server_logs.log") }
