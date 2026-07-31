package utils

import (
	"os"
	"path"
)

const (
	AppDbDriver      = "sqlite"
	OauthRedirectUrl = "https://p2kr.github.io/komorebi/"
)

func AppDir() string {
	dir, err := os.UserConfigDir()
	if err != nil {
		panic(err)
	}
	return path.Join(dir, "com.p2kr", "Komorebi")
}

func AppDbPath() string   { return path.Join(AppDir(), "app_db.db") }
func AppLogsPath() string { return path.Join(AppDir(), "server_logs.log") }
