package api

import (
	"database/sql"
	"errors"
	"komorebi_server/src/db"
	dbClient "komorebi_server/src/db/generated"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// AddNewProfile saves a request profile and returns the saved profile
// Check if profile already present
func AddNewProfile(c *gin.Context) {
	var profile dbClient.Profile
	err := c.ShouldBindJSON(&profile)
	if err != nil {
		Fail(c, http.StatusBadRequest, "INVALID_DATA", err.Error())
		return
	}

	err = db.ValidateProfile(profile)
	if err != nil {
		Fail(c, http.StatusBadRequest, "INVALID_DATA", err.Error())
		return
	}

	// save profile data
	tx, err := db.GetDbClient().Begin()
	if err != nil {
		Fail(c, http.StatusInternalServerError, "DB_ERROR", err.Error())
		return
	}
	defer func() {
		_ = tx.Rollback()
	}()

	queries := dbClient.New(tx)

	newProfile, err := queries.UpdateProfileByUsernameAndSyncType(c, dbClient.UpdateProfileByUsernameAndSyncTypeParams{
		AvatarUrl:   profile.AvatarUrl,
		AccessToken: profile.AccessToken,
		Username:    profile.Username,
		SyncType:    profile.SyncType,
	})
	if errors.Is(err, sql.ErrNoRows) {
		newProfile, err = queries.InsertProfile(c, dbClient.InsertProfileParams{
			Username:    profile.Username,
			SyncType:    profile.SyncType,
			AvatarUrl:   profile.AvatarUrl,
			AccessToken: profile.AccessToken,
		})
	}
	if err != nil {
		Fail(c, http.StatusInternalServerError, "DB_ERROR", err.Error())
		return
	}

	err = tx.Commit()
	if err != nil {
		Fail(c, http.StatusInternalServerError, "DB_ERROR", err.Error())
		logger.Error("error in committing transaction", zap.Error(err))
		return
	}
	Ok(c, newProfile)
}

// GetAllProfiles returns all profiles
func GetAllProfiles(c *gin.Context) {
	allProfiles, err := dbClient.New(db.GetDbClient()).GetAllProfiles(c)
	if err != nil {
		Fail(c, http.StatusInternalServerError, "DB_ERROR", err.Error())
		return
	}
	Ok(c, allProfiles)
}

// DeleteProfile deletes a profile by ID
func DeleteProfile(c *gin.Context) {
	idStr := c.Query("id")
	if idStr == "" {
		idStr = c.PostForm("id")
	}

	if idStr == "" {
		var body struct {
			ID int64 `json:"id"`
		}
		if err := c.ShouldBindJSON(&body); err == nil && body.ID > 0 {
			idStr = strconv.FormatInt(body.ID, 10)
		}
	}

	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		Fail(c, http.StatusBadRequest, "INVALID_ID", "id parameter is required and must be an integer")
		return
	}

	err = dbClient.New(db.GetDbClient()).DeleteProfileById(c, id)
	if err != nil {
		Fail(c, http.StatusInternalServerError, "DB_ERROR", err.Error())
		return
	}

	Ok(c, map[string]any{"id": id, "deleted": true})
}
