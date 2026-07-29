package api

import (
	"context"
	"crypto/rand"
	"database/sql"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"komorebi_server/src/db"
	dbClient "komorebi_server/src/db/generated"
	"komorebi_server/src/media"
	"komorebi_server/src/utils"
	"net/http"
	"net/url"
	"os/exec"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

type authSession struct {
	codeVerifier string
	resultChan   chan *dbClient.Profile
	errChan      chan error
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

// StartOAuthLogin initiates full server-side OAuth flow for MAL
func StartOAuthLogin(c *gin.Context) {
	provider := media.ParseProvider(c.DefaultQuery("provider", string(media.ProviderMAL)))

	if provider == media.ProviderMAL {
		clientID := utils.GetEnv().MalClientID
		if clientID == "" {
			Fail(c, http.StatusInternalServerError, "CONFIG_ERROR", "MAL_CLIENT_ID is not configured on server")
			return
		}

		codeVerifier := generateCodeVerifier()
		sessionID := generateCodeVerifier()[:16]

		resChan := make(chan *dbClient.Profile, 1)
		errChan := make(chan error, 1)

		authSessionsMu.Lock()
		authSessions[sessionID] = &authSession{
			codeVerifier: codeVerifier,
			resultChan:   resChan,
			errChan:      errChan,
		}
		authSessionsMu.Unlock()

		authURL := fmt.Sprintf(
			"https://myanimelist.net/v1/oauth2/authorize?response_type=code&client_id=%s&code_challenge=%s&code_challenge_method=plain&redirect_uri=%s&state=%s",
			url.QueryEscape(clientID),
			url.QueryEscape(codeVerifier),
			url.QueryEscape(utils.OauthRedirectUrl),
			url.QueryEscape(sessionID),
		)

		_ = openBrowser(authURL)

		select {
		case profile := <-resChan:
			Ok(c, profile)
		case err := <-errChan:
			Fail(c, http.StatusInternalServerError, "OAUTH_ERROR", err.Error())
		case <-time.After(5 * time.Minute):
			Fail(c, http.StatusRequestTimeout, "TIMEOUT", "Authentication timed out")
		case <-c.Request.Context().Done():
			Fail(c, 499, "CANCELLED", "Client cancelled request")
		}

		authSessionsMu.Lock()
		delete(authSessions, sessionID)
		authSessionsMu.Unlock()
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
		c.Data(http.StatusBadRequest, "text/html; charset=utf-8", []byte("<html><body><h2>Invalid or expired authentication session.</h2></body></html>"))
		return
	}

	clientID := utils.GetEnv().MalClientID

	data := url.Values{}
	data.Set("client_id", clientID)
	data.Set("code", code)
	data.Set("code_verifier", session.codeVerifier)
	data.Set("grant_type", "authorization_code")
	data.Set("redirect_uri", utils.OauthRedirectUrl)

	resp, err := http.Post("https://myanimelist.net/v1/oauth2/token", "application/x-www-form-urlencoded", strings.NewReader(data.Encode()))
	if err != nil {
		session.errChan <- err
		c.Data(http.StatusInternalServerError, "text/html; charset=utf-8", []byte("<html><body><h2>OAuth token exchange failed.</h2></body></html>"))
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := io.ReadAll(resp.Body)
		session.errChan <- fmt.Errorf("token error (%d): %s", resp.StatusCode, string(bodyBytes))
		c.Data(http.StatusBadRequest, "text/html; charset=utf-8", []byte("<html><body><h2>OAuth authentication failed.</h2></body></html>"))
		return
	}

	var tokenResp MalTokenResponse
	_ = json.NewDecoder(resp.Body).Decode(&tokenResp)

	reqURL, _ := http.NewRequestWithContext(c.Request.Context(), http.MethodGet, "https://api.myanimelist.net/v2/users/@me", nil)
	reqURL.Header.Set("Authorization", "Bearer "+tokenResp.AccessToken)

	userResp, err := http.DefaultClient.Do(reqURL)
	if err != nil {
		session.errChan <- err
		c.Data(http.StatusInternalServerError, "text/html; charset=utf-8", []byte("<html><body><h2>Failed to fetch user profile.</h2></body></html>"))
		return
	}
	defer userResp.Body.Close()

	var userInfo MalUserInfo
	_ = json.NewDecoder(userResp.Body).Decode(&userInfo)

	profile := dbClient.Profile{
		Username:    userInfo.Name,
		SyncType:    media.ProviderMAL.String(),
		AvatarUrl:   &userInfo.Picture,
		AccessToken: &tokenResp.AccessToken,
	}

	savedProfile, err := saveProfile(c, profile)
	if err != nil {
		session.errChan <- err
		c.Data(http.StatusInternalServerError, "text/html; charset=utf-8", []byte("<html><body><h2>Failed to save profile.</h2></body></html>"))
		return
	}

	session.resultChan <- savedProfile

	c.Data(http.StatusOK, "text/html; charset=utf-8", []byte(`
		<!DOCTYPE html>
		<html>
		<head>
			<title>Authentication Successful</title>
			<style>
				body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0f172a; color: #f8fafc; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
				.card { background: #1e293b; padding: 2rem 3rem; border-radius: 1rem; text-align: center; box-shadow: 0 10px 25px rgba(0,0,0,0.5); }
				h1 { color: #38bdf8; margin-bottom: 0.5rem; }
				p { color: #94a3b8; }
			</style>
		</head>
		<body>
			<div class="card">
				<h1>🌸 Authentication Successful!</h1>
				<p>Your MyAnimeList account has been connected to Komorebi.<br>You can close this window and return to the app.</p>
			</div>
		</body>
		</html>
	`))
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
		clientID := utils.GetEnv().MalClientID
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
