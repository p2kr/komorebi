package api

import (
	"context"
	"crypto/rand"
	"database/sql"
	"encoding/base64"
	"errors"
	"fmt"
	"komorebi_server/src/db"
	dbClient "komorebi_server/src/db/generated"
	"komorebi_server/src/media"
	"komorebi_server/src/utils"
	"net/http"
	"os/exec"
	"runtime"
	"strconv"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

type authSession struct {
	codeVerifier string
	resultChan   chan *dbClient.Profile
	errChan      chan error
	provider     media.Provider
}

var (
	authSessions   = make(map[string]*authSession)
	authSessionsMu sync.Mutex
)

func generateCodeVerifier() string {
	b := make([]byte, 32)
	_, _ = rand.Read(b)
	return base64.RawURLEncoding.EncodeToString(b)
}

func openBrowser(targetURL string) error {
	var cmd *exec.Cmd
	switch runtime.GOOS {
	case "windows":
		cmd = exec.Command("rundll32", "url.dll", "FileProtocolHandler", targetURL)
	case "darwin":
		cmd = exec.Command("open", targetURL)
	default:
		cmd = exec.Command("xdg-open", targetURL)
	}
	return cmd.Start()
}

// AddNewProfile saves a request profile and returns the saved profile
func AddNewProfile(c *gin.Context) {
	var profile dbClient.Profile
	err := c.ShouldBindBodyWithJSON(&profile)
	if err != nil {
		Fail(c, http.StatusBadRequest, "INVALID_DATA", err.Error())
		return
	}

	err = db.ValidateProfile(profile)
	if err != nil {
		Fail(c, http.StatusBadRequest, "INVALID_DATA", err.Error())
		return
	}

	saveProfileAndRespond(c, profile)
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

// StartOAuthLogin initiates full server-side OAuth flow for MAL and AniList
func StartOAuthLogin(c *gin.Context) {
	provider := media.ParseProvider(c.DefaultQuery("provider", string(media.ProviderMAL)))

	switch provider {
	case media.ProviderMAL:
		startMalOAuthLogin(c)
		return
	case media.ProviderAniList:
		startAniListOAuthLogin(c)
		return
	}

	Fail(c, http.StatusBadRequest, "INVALID_PROVIDER", "Unsupported provider: "+provider.String())
}

// OAuthCallback handles the browser redirect callback from MyAnimeList/AniList
func OAuthCallback(c *gin.Context) {
	code := c.Query("code")
	state := c.Query("state")

	authSessionsMu.Lock()
	session, exists := authSessions[state]
	authSessionsMu.Unlock()

	if !exists || session == nil {
		Fail(c, http.StatusBadRequest, "AUTH_ERROR", "Invalid or expired authentication session")
		return
	}

	switch session.provider {
	case media.ProviderMAL:
		handleMalOAuthCallback(c, session, code)
	case media.ProviderAniList:
		handleAniListOAuthCallback(c, session, code)
	default:
		Fail(c, http.StatusBadRequest, "AUTH_ERROR", "Unsupported provider in session")
	}
}

type SandboxProfileRequest struct {
	Username string `json:"username" binding:"required"`
	Provider string `json:"provider"`
}

func VerifySandboxProfile(c *gin.Context) {
	var req SandboxProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		Fail(c, http.StatusBadRequest, "INVALID_DATA", err.Error())
		return
	}

	provider := media.ParseProvider(req.Provider)
	var client media.Client

	if provider == media.ProviderAniList {
		client = media.NewAniListClient(nil)
	} else {
		clientID := utils.Env().MalClientID
		client = media.NewMalClient(clientID, nil)
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	_, err := client.GetUserAnimeList(ctx, req.Username, "", "")
	if err != nil {
		logger.Error("Sandbox verification failed", zap.Error(err))
		Fail(c, http.StatusNotFound, "NOT_FOUND", fmt.Sprintf("User not found on %s", provider.String()))
		return
	}

	profile := dbClient.Profile{
		Username: req.Username,
		SyncType: media.ProviderSandbox.String(),
	}

	saveProfileAndRespond(c, profile)
}

func saveProfile(c context.Context, profile dbClient.Profile) (*dbClient.Profile, error) {
	tx, err := db.GetDbClient().Begin()
	if err != nil {
		return nil, err
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
		return nil, err
	}

	err = tx.Commit()
	if err != nil {
		return nil, err
	}
	return &newProfile, nil
}

func saveProfileAndRespond(c *gin.Context, profile dbClient.Profile) {
	newProfile, err := saveProfile(c, profile)
	if err != nil {
		Fail(c, http.StatusInternalServerError, "DB_ERROR", err.Error())
		return
	}
	Ok(c, newProfile)
}
