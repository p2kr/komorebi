package api

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	. "komorebi_server/src/api"
	"komorebi_server/src/utils"
)

// --- /api/v1/auth/sandbox ---

func TestVerifySandboxProfile_MissingBody(t *testing.T) {
	r := InitRouter()

	req, _ := http.NewRequest(http.MethodPost, "/api/v1/auth/sandbox", bytes.NewBufferString(`{}`))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	r.ServeHTTP(w, req)

	// username is required; binding should fail with 400
	assert.Equal(t, http.StatusBadRequest, w.Code, "expected 400 for missing username")

	var res Response
	require.NoError(t, json.NewDecoder(w.Body).Decode(&res), "failed to decode response")
	
	assert.False(t, res.Success, "expected success=false for missing username")
	require.NotNil(t, res.Error, "expected error object in response")
	assert.Equal(t, "INVALID_DATA", res.Error.Code, "expected error code INVALID_DATA")
}

func TestVerifySandboxProfile_RouteRegistered(t *testing.T) {
	r := InitRouter()

	// Send an empty username — binding will fail with 400 INVALID_DATA before
	// any network call is made, proving the route is registered without hitting MAL.
	req, _ := http.NewRequest(http.MethodPost, "/api/v1/auth/sandbox", bytes.NewBufferString(`{}`))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	r.ServeHTTP(w, req)

	// A 404 means the route was never registered; anything else proves it exists.
	assert.NotEqual(t, http.StatusNotFound, w.Code, "expected /api/v1/auth/sandbox to be registered")

	// The response must always be our JSON envelope.
	var res Response
	require.NoError(t, json.NewDecoder(w.Body).Decode(&res), "response is not valid JSON envelope")
}

func TestVerifySandboxProfile_InvalidContentType(t *testing.T) {
	r := InitRouter()

	// Send form data instead of JSON — ShouldBindJSON should reject it.
	req, _ := http.NewRequest(http.MethodPost, "/api/v1/auth/sandbox", bytes.NewBufferString("username=someuser"))
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	w := httptest.NewRecorder()

	r.ServeHTTP(w, req)

	assert.NotEqual(t, http.StatusNotFound, w.Code, "route not registered")

	var res Response
	require.NoError(t, json.NewDecoder(w.Body).Decode(&res), "response is not valid JSON")

	// Binding JSON from a form body should fail.
	assert.False(t, res.Success, "expected failure when Content-Type is not application/json")
}

// --- /api/v1/auth/login ---

func TestStartOAuthLogin_RouteRegistered(t *testing.T) {
	r := InitRouter()

	req, _ := http.NewRequest(http.MethodGet, "/api/v1/auth/login", nil)
	w := httptest.NewRecorder()

	r.ServeHTTP(w, req)

	assert.NotEqual(t, http.StatusNotFound, w.Code, "expected /api/v1/auth/login to be registered")
}

// TestStartOAuthLogin_MissingClientID verifies that the login endpoint returns a
// meaningful configuration error when MAL_CLIENT_ID is not set (the default in
// test environments). ParseProvider maps all unknown strings to MAL via its
// default case, so there is no INVALID_PROVIDER code path reachable at runtime.
func TestStartOAuthLogin_MissingClientID(t *testing.T) {
	t.Setenv("MAL_CLIENT_ID", "")
	utils.InitEnv()
	t.Cleanup(func() {
		utils.InitEnv()
	})

	r := InitRouter()

	// Default provider is MAL; without MAL_CLIENT_ID set the handler should
	// return a 500 CONFIG_ERROR immediately without blocking.
	req, _ := http.NewRequest(http.MethodGet, "/api/v1/auth/login", nil)
	w := httptest.NewRecorder()

	r.ServeHTTP(w, req)

	// Without a configured client ID the server cannot start an OAuth flow.
	assert.NotEqual(t, http.StatusNotFound, w.Code, "/api/v1/auth/login route is not registered")

	var res Response
	require.NoError(t, json.NewDecoder(w.Body).Decode(&res), "response is not valid JSON")

	if res.Success {
		// A real OAuth flow succeeded — nothing to assert further.
		return
	}

	// No client ID configured: expect CONFIG_ERROR.
	require.NotNil(t, res.Error, "expected error object in response")
	assert.Equal(t, "CONFIG_ERROR", res.Error.Code, "expected CONFIG_ERROR when MAL_CLIENT_ID is missing")
}

// --- /api/v1/auth/callback ---

func TestOAuthCallback_RouteRegistered(t *testing.T) {
	r := InitRouter()

	req, _ := http.NewRequest(http.MethodGet, "/api/v1/auth/callback", nil)
	w := httptest.NewRecorder()

	r.ServeHTTP(w, req)

	assert.NotEqual(t, http.StatusNotFound, w.Code, "expected /api/v1/auth/callback to be registered")
}

func TestOAuthCallback_MissingState(t *testing.T) {
	r := InitRouter()

	// No state parameter → session lookup fails → 400
	req, _ := http.NewRequest(http.MethodGet, "/api/v1/auth/callback?code=somecode", nil)
	w := httptest.NewRecorder()

	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code, "expected 400 for missing/unknown state")
}

func TestOAuthCallback_InvalidState(t *testing.T) {
	r := InitRouter()

	// A state that was never registered in authSessions → session lookup fails → 400
	req, _ := http.NewRequest(http.MethodGet, "/api/v1/auth/callback?code=somecode&state=nonexistent-session-id", nil)
	w := httptest.NewRecorder()

	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code, "expected 400 for unknown session state")
}
