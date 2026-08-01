package utils

import (
	"os"
)

func InitDir() {
	dir := AppDir()
	err := os.MkdirAll(dir, os.ModePerm)
	if err != nil {
		panic(err)
	}
}
