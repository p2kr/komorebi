package db

import (
	"errors"
	dbClient "komorebi_server/src/db/generated"
	"strings"

	"go.uber.org/zap"
)

func ValidateProfile(p dbClient.Profile) error {
	logger.Info("Validating profile", zap.Any("profile", p))
	//if p.ID <= 0 {
	//	return errors.New("ID is required")
	//}
	if len(strings.TrimSpace(p.SyncType)) <= 0 {
		return errors.New("SyncType is required")
	}
	if len(strings.TrimSpace(p.Username)) <= 0 {
		return errors.New("username is required")
	}
	if p.AccessToken != nil && len(strings.TrimSpace(*p.AccessToken)) <= 0 {
		return errors.New("accessToken is invalid")
	}

	return nil
}

func ValidateAppConfig(c dbClient.AppConfig) error {
	logger.Info("Validating app config", zap.Any("config", c))
	if len(strings.TrimSpace(c.ConfigKey)) <= 0 {
		return errors.New("ConfigKey is required")
	}
	return nil
}
