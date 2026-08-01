package db

import (
	"context"
	"database/sql"
	_ "embed"
	"komorebi_server/src/utils"
	"net/url"

	"go.uber.org/zap"
	_ "modernc.org/sqlite"
)

var logger = utils.Logger()
var sqlClient *sql.DB

//go:embed schema/schema.sql
var ddl string

//go:embed schema/seed.sql
var seedDdl string

func InitDbClient() {
	initDbClientWithPath(utils.AppDbPath())
}

// InitDbClientWithPath opens the DB at the given path and runs DDL.
// Intended for use in tests to inject an in-memory database URI.
func InitDbClientWithPath(dbPath string) {
	initDbClientWithPath(dbPath)
}

func initDbClientWithPath(rawPath string) {
	u, err := url.Parse(rawPath)
	if err != nil {
		panic(err)
	}
	q := u.Query()
	q.Set("_pragma", "foreign_keys(1)")
	u.RawQuery = q.Encode()
	sqlClient, err = sql.Open(utils.AppDbDriver, u.String())
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
