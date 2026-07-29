package utils

import "path"

const (
	AppDbDriver      = "sqlite"
	OauthRedirectUrl = "https://p2kr.github.io/komorebi/"
)

func AppDbPath() string   { return path.Join("com.p2kr", "Komorebi", "app_db.db") }
func AppLogsPath() string { return path.Join("com.p2kr", "Komorebi", "server_logs.log") }
