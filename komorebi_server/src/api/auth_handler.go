package api

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"io"
	"komorebi_server/src/db"
	dbClient "komorebi_server/src/db/generated"
	"komorebi_server/src/media"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"

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

// --- New OAuth / Auth Handlers ---

type ExchangeOAuthTokenRequest struct {
	Provider     string `json:"provider" binding:"required"`
	Code         string `json:"code" binding:"required"`
	CodeVerifier string `json:"code_verifier"`
	RedirectURI  string `json:"redirect_uri"`
	ClientID     string `json:"client_id"`
}

type MalTokenResponse struct {
	AccessToken string `json:"access_token"`
	TokenType   string `json:"token_type"`
	ExpiresIn   int    `json:"expires_in"`
}

type MalUserInfo struct {
	ID      int    `json:"id"`
	Name    string `json:"name"`
	Picture string `json:"picture"`
}

func ExchangeOAuthToken(c *gin.Context) {
	var req ExchangeOAuthTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		Fail(c, http.StatusBadRequest, "INVALID_DATA", err.Error())
		return
	}

	if req.Provider == "mal" {
		// Exchange code for token
		tokenURL := "https://myanimelist.net/v1/oauth2/token"
		data := url.Values{}
		data.Set("client_id", req.ClientID)
		data.Set("code", req.Code)
		data.Set("code_verifier", req.CodeVerifier)
		data.Set("grant_type", "authorization_code")
		data.Set("redirect_uri", req.RedirectURI)

		resp, err := http.Post(tokenURL, "application/x-www-form-urlencoded", strings.NewReader(data.Encode()))
		if err != nil {
			Fail(c, http.StatusInternalServerError, "OAUTH_ERROR", err.Error())
			return
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			bodyBytes, _ := io.ReadAll(resp.Body)
			Fail(c, resp.StatusCode, "OAUTH_ERROR", string(bodyBytes))
			return
		}

		var tokenResp MalTokenResponse
		if err := json.NewDecoder(resp.Body).Decode(&tokenResp); err != nil {
			Fail(c, http.StatusInternalServerError, "OAUTH_ERROR", "Failed to decode token response")
			return
		}

		// Fetch User Info
		reqURL, _ := http.NewRequestWithContext(c.Request.Context(), http.MethodGet, "https://api.myanimelist.net/v2/users/@me", nil)
		reqURL.Header.Set("Authorization", "Bearer "+tokenResp.AccessToken)
		reqURL.Header.Set("Accept", "application/json")

		userResp, err := http.DefaultClient.Do(reqURL)
		if err != nil {
			Fail(c, http.StatusInternalServerError, "OAUTH_ERROR", "Failed to fetch user info")
			return
		}
		defer userResp.Body.Close()

		if userResp.StatusCode != http.StatusOK {
			bodyBytes, _ := io.ReadAll(userResp.Body)
			Fail(c, userResp.StatusCode, "OAUTH_ERROR", string(bodyBytes))
			return
		}

		var userInfo MalUserInfo
		if err := json.NewDecoder(userResp.Body).Decode(&userInfo); err != nil {
			Fail(c, http.StatusInternalServerError, "OAUTH_ERROR", "Failed to decode user info")
			return
		}

		// Insert/Update Profile
		profile := dbClient.Profile{
			Username:    userInfo.Name,
			SyncType:    "mal",
			AvatarUrl:   &userInfo.Picture,
			AccessToken: &tokenResp.AccessToken,
		}

		saveProfileAndRespond(c, profile)
		return

	} else if req.Provider == "anilist" {
		// Implicit grant returns the token directly in the 'code' parameter mapping
		accessToken := req.Code

		query := `query { Viewer { id name avatar { large } } }`
		reqBody := map[string]string{"query": query}
		jsonBody, _ := json.Marshal(reqBody)

		reqURL, _ := http.NewRequestWithContext(c.Request.Context(), http.MethodPost, "https://graphql.anilist.co", bytes.NewBuffer(jsonBody))
		reqURL.Header.Set("Authorization", "Bearer "+accessToken)
		reqURL.Header.Set("Content-Type", "application/json")
		reqURL.Header.Set("Accept", "application/json")

		userResp, err := http.DefaultClient.Do(reqURL)
		if err != nil {
			Fail(c, http.StatusInternalServerError, "OAUTH_ERROR", "Failed to fetch anilist user info")
			return
		}
		defer userResp.Body.Close()

		if userResp.StatusCode != http.StatusOK {
			bodyBytes, _ := io.ReadAll(userResp.Body)
			Fail(c, userResp.StatusCode, "OAUTH_ERROR", string(bodyBytes))
			return
		}

		var result struct {
			Data struct {
				Viewer struct {
					Name   string `json:"name"`
					Avatar struct {
						Large string `json:"large"`
					} `json:"avatar"`
				} `json:"Viewer"`
			} `json:"data"`
		}
		if err := json.NewDecoder(userResp.Body).Decode(&result); err != nil {
			Fail(c, http.StatusInternalServerError, "OAUTH_ERROR", "Failed to decode anilist user info")
			return
		}

		profile := dbClient.Profile{
			Username:    result.Data.Viewer.Name,
			SyncType:    "anilist",
			AvatarUrl:   &result.Data.Viewer.Avatar.Large,
			AccessToken: &accessToken,
		}

		saveProfileAndRespond(c, profile)
		return
	}

	Fail(c, http.StatusBadRequest, "INVALID_PROVIDER", "Unknown provider: "+req.Provider)
}

type SandboxProfileRequest struct {
	Username string `json:"username" binding:"required"`
}

func VerifySandboxProfile(c *gin.Context) {
	var req SandboxProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		Fail(c, http.StatusBadRequest, "INVALID_DATA", err.Error())
		return
	}

	clientID := os.Getenv("MAL_CLIENT_ID")
	if clientID == "" {
		clientID = c.Query("client_id")
	}

	malClient := media.NewMalClient(clientID, nil)
	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	_, err := malClient.GetUserAnimeList(ctx, "", req.Username, "")
	if err != nil {
		logger.Error("Sandbox verification failed", zap.Error(err))
		Fail(c, http.StatusNotFound, "NOT_FOUND", "User not found on MAL")
		return
	}

	profile := dbClient.Profile{
		Username: req.Username,
		SyncType: "sandbox",
	}

	saveProfileAndRespond(c, profile)
}

func saveProfileAndRespond(c *gin.Context, profile dbClient.Profile) {
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
