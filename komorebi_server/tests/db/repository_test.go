package db

import (
	"komorebi_server/src"
	"komorebi_server/src/db"
	dbClient "komorebi_server/src/db/generated"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func init() {
	src.Init()
}

func TestValidateProfile(t *testing.T) {
	validToken := "my-access-token"
	emptyToken := ""
	whitespaceToken := "   "
	avatar := "https://example.com/avatar.png"

	testCases := []struct {
		name    string
		profile dbClient.Profile
		wantErr bool
		errMsg  string
	}{
		{
			name: "valid profile with all fields",
			profile: dbClient.Profile{
				Username:    "johndoe",
				SyncType:    "MAL",
				AccessToken: &validToken,
				AvatarUrl:   &avatar,
			},
			wantErr: false,
		},
		{
			name: "valid profile with optional nil fields",
			profile: dbClient.Profile{
				Username: "johndoe",
				SyncType: "MAL",
			},
			wantErr: false,
		},
		{
			name: "missing sync type - empty string",
			profile: dbClient.Profile{
				Username: "johndoe",
				SyncType: "",
			},
			wantErr: true,
			errMsg:  "SyncType is required",
		},
		{
			name: "missing sync type - whitespace only",
			profile: dbClient.Profile{
				Username: "johndoe",
				SyncType: "   ",
			},
			wantErr: true,
			errMsg:  "SyncType is required",
		},
		{
			name: "missing username - empty string",
			profile: dbClient.Profile{
				Username: "",
				SyncType: "MAL",
			},
			wantErr: true,
			errMsg:  "username is required",
		},
		{
			name: "missing username - whitespace only",
			profile: dbClient.Profile{
				Username: "  \t \n ",
				SyncType: "MAL",
			},
			wantErr: true,
			errMsg:  "username is required",
		},
		{
			name: "invalid access token - empty string",
			profile: dbClient.Profile{
				Username:    "johndoe",
				SyncType:    "MAL",
				AccessToken: &emptyToken,
			},
			wantErr: true,
			errMsg:  "accessToken is invalid",
		},
		{
			name: "invalid access token - whitespace only",
			profile: dbClient.Profile{
				Username:    "johndoe",
				SyncType:    "MAL",
				AccessToken: &whitespaceToken,
			},
			wantErr: true,
			errMsg:  "accessToken is invalid",
		},
	}

	for _, tt := range testCases {
		t.Run(tt.name, func(t *testing.T) {
			err := db.ValidateProfile(tt.profile)
			if tt.wantErr {
				require.Error(t, err, "ValidateProfile() expected an error")
				assert.EqualError(t, err, tt.errMsg, "ValidateProfile() error message mismatch")
			} else {
				require.NoError(t, err, "ValidateProfile() expected no error")
			}
		})
	}
}

func TestValidateAppConfig(t *testing.T) {
	val := "dark"

	testCases := []struct {
		name    string
		config  dbClient.AppConfig
		wantErr bool
		errMsg  string
	}{
		{
			name: "valid app config with value",
			config: dbClient.AppConfig{
				ConfigKey:   "theme",
				ConfigValue: &val,
			},
			wantErr: false,
		},
		{
			name: "valid app config with nil value",
			config: dbClient.AppConfig{
				ConfigKey:   "theme",
				ConfigValue: nil,
			},
			wantErr: false,
		},
		{
			name: "missing config key - empty",
			config: dbClient.AppConfig{
				ConfigKey: "",
			},
			wantErr: true,
			errMsg:  "ConfigKey is required",
		},
		{
			name: "missing config key - whitespace",
			config: dbClient.AppConfig{
				ConfigKey: "   ",
			},
			wantErr: true,
			errMsg:  "ConfigKey is required",
		},
	}

	for _, tt := range testCases {
		t.Run(tt.name, func(t *testing.T) {
			err := db.ValidateAppConfig(tt.config)
			if tt.wantErr {
				require.Error(t, err, "ValidateAppConfig() expected an error")
				assert.EqualError(t, err, tt.errMsg, "ValidateAppConfig() error message mismatch")
			} else {
				require.NoError(t, err, "ValidateAppConfig() expected no error")
			}
		})
	}
}
