package db

import (
	"context"
	"database/sql"
	_ "embed"
	"komorebi_server/src/utils"
	"os"
	"path/filepath"

	"go.uber.org/zap"
	_ "modernc.org/sqlite"
)

var logger = utils.GetLogger()
var sqlClient *sql.DB

//go:embed schema/schema.sql
var ddl string

//go:embed schema/seed.sql
var seedDdl string

func getDbFileName() string {
	dbPath := utils.AppDbPath()

	logger.Info("db path", zap.String("path", dbPath))

	err := os.MkdirAll(filepath.Dir(dbPath), os.ModePerm)
	if err != nil {
		logger.Error("error in creating db directory", zap.Error(err))
	}
	return dbPath
}

func InitDbClient() {
	var err error
	dbPath := getDbFileName() + "?_pragma=foreign_keys(1)" // &_time_format=sqlite
	sqlClient, err = sql.Open(utils.AppDbDriver, dbPath)
	if err != nil {
		logger.Error("error in opening db", zap.Error(err))
		panic(err)
	}

	ExecuteDDL()
}

func ExecuteDDL() {
	_, err := sqlClient.ExecContext(context.Background(), "PRAGMA foreign_keys = ON;")
	if err != nil {
		logger.Error("error in enabling foreign keys", zap.Error(err))
	}
	_, err = sqlClient.ExecContext(context.Background(), ddl)
	if err != nil {
		logger.Error("error in executing ddl", zap.Error(err))
		panic(err)
	}
	_, err = sqlClient.ExecContext(context.Background(), seedDdl)
	if err != nil {
		logger.Error("error in executing seed ddl", zap.Error(err))
	}
}

func CloseDbClient() {
	if sqlClient != nil {
		err := sqlClient.Close()
		if err != nil {
			logger.Error("error in closing db", zap.Error(err))
		}
	} else {
		logger.Warn("db is not initialized")
	}
}

func GetDbClient() *sql.DB {
	return sqlClient
}
