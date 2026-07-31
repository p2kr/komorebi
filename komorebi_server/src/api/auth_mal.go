package api

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	dbClient "komorebi_server/src/db/generated"
	"komorebi_server/src/media"
	"komorebi_server/src/utils"

	"github.com/gin-gonic/gin"
)

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

func startMalOAuthLogin(c *gin.Context) {
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
		provider:     media.ProviderMAL,
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
}

func handleMalOAuthCallback(c *gin.Context, session *authSession, code string) {
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
		Fail(c, http.StatusInternalServerError, "AUTH_ERROR", "OAuth token exchange failed")
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := io.ReadAll(resp.Body)
		session.errChan <- fmt.Errorf("token error (%d): %s", resp.StatusCode, string(bodyBytes))
		Fail(c, http.StatusBadRequest, "AUTH_ERROR", "OAuth authentication failed")
		return
	}

	var tokenResp MalTokenResponse
	_ = json.NewDecoder(resp.Body).Decode(&tokenResp)

	reqURL, _ := http.NewRequestWithContext(c.Request.Context(), http.MethodGet, "https://api.myanimelist.net/v2/users/@me", nil)
	reqURL.Header.Set("Authorization", "Bearer "+tokenResp.AccessToken)

	userResp, err := http.DefaultClient.Do(reqURL)
	if err != nil {
		session.errChan <- err
		Fail(c, http.StatusInternalServerError, "AUTH_ERROR", "Failed to fetch user profile")
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
		Fail(c, http.StatusInternalServerError, "AUTH_ERROR", "Failed to save profile")
		return
	}

	session.resultChan <- savedProfile

	Ok(c, nil)
}
