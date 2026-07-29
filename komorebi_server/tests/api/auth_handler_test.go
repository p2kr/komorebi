package api

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	. "komorebi_server/src/api"
)

// --- /api/v1/auth/sandbox ---

func TestVerifySandboxProfile_MissingBody(t *testing.T) {
	r := InitRouter()

	req, _ := http.NewRequest(http.MethodPost, "/api/v1/auth/sandbox", bytes.NewBufferString(`{}`))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	r.ServeHTTP(w, req)

	// username is required; binding should fail with 400
	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for missing username, got %d", w.Code)
	}

	var res Response
	if err := json.NewDecoder(w.Body).Decode(&res); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}
	if res.Success {
		t.Error("expected success=false for missing username")
	}
	if res.Error == nil {
		t.Fatal("expected error object in response")
	}
	if res.Error.Code != "INVALID_DATA" {
		t.Errorf("expected error code INVALID_DATA, got %q", res.Error.Code)
	}
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
	if w.Code == http.StatusNotFound {
		t.Fatal("expected /api/v1/auth/sandbox to be registered, got 404")
	}

	// The response must always be our JSON envelope.
	var res Response
	if err := json.NewDecoder(w.Body).Decode(&res); err != nil {
		t.Fatalf("response is not valid JSON envelope: %v", err)
	}
}

func TestVerifySandboxProfile_InvalidContentType(t *testing.T) {
	r := InitRouter()

	// Send form data instead of JSON — ShouldBindJSON should reject it.
	req, _ := http.NewRequest(http.MethodPost, "/api/v1/auth/sandbox", bytes.NewBufferString("username=someuser"))
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	w := httptest.NewRecorder()

	r.ServeHTTP(w, req)

	if w.Code == http.StatusNotFound {
		t.Fatal("route not registered")
	}

	var res Response
	if err := json.NewDecoder(w.Body).Decode(&res); err != nil {
		t.Fatalf("response is not valid JSON: %v", err)
	}
	// Binding JSON from a form body should fail.
	if res.Success {
		t.Error("expected failure when Content-Type is not application/json")
	}
}

// --- /api/v1/auth/login ---

func TestStartOAuthLogin_RouteRegistered(t *testing.T) {
	r := InitRouter()

	req, _ := http.NewRequest(http.MethodGet, "/api/v1/auth/login", nil)
	w := httptest.NewRecorder()

	r.ServeHTTP(w, req)

	if w.Code == http.StatusNotFound {
		t.Fatal("expected /api/v1/auth/login to be registered, got 404")
	}
}

// TestStartOAuthLogin_MissingClientID verifies that the login endpoint returns a
// meaningful configuration error when MAL_CLIENT_ID is not set (the default in
// test environments). ParseProvider maps all unknown strings to MAL via its
// default case, so there is no INVALID_PROVIDER code path reachable at runtime.
func TestStartOAuthLogin_MissingClientID(t *testing.T) {
	r := InitRouter()

	// Default provider is MAL; without MAL_CLIENT_ID set the handler should
	// return a 500 CONFIG_ERROR immediately without blocking.
	req, _ := http.NewRequest(http.MethodGet, "/api/v1/auth/login", nil)
	w := httptest.NewRecorder()

	r.ServeHTTP(w, req)

	// Without a configured client ID the server cannot start an OAuth flow.
	if w.Code == http.StatusNotFound {
		t.Fatal("/api/v1/auth/login route is not registered")
	}

	var res Response
	if err := json.NewDecoder(w.Body).Decode(&res); err != nil {
		t.Fatalf("response is not valid JSON: %v", err)
	}

	if res.Success {
		// A real OAuth flow succeeded — nothing to assert further.
		return
	}

	// No client ID configured: expect CONFIG_ERROR.
	if res.Error == nil {
		t.Fatal("expected error object in response")
	}
	if res.Error.Code != "CONFIG_ERROR" {
		t.Errorf("expected CONFIG_ERROR when MAL_CLIENT_ID is missing, got %q", res.Error.Code)
	}
}

// --- /api/v1/auth/callback ---

func TestOAuthCallback_RouteRegistered(t *testing.T) {
	r := InitRouter()

	req, _ := http.NewRequest(http.MethodGet, "/api/v1/auth/callback", nil)
	w := httptest.NewRecorder()

	r.ServeHTTP(w, req)

	if w.Code == http.StatusNotFound {
		t.Fatal("expected /api/v1/auth/callback to be registered, got 404")
	}
}

func TestOAuthCallback_MissingState(t *testing.T) {
	r := InitRouter()

	// No state parameter → session lookup fails → 400
	req, _ := http.NewRequest(http.MethodGet, "/api/v1/auth/callback?code=somecode", nil)
	w := httptest.NewRecorder()

	r.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for missing/unknown state, got %d", w.Code)
	}
}

func TestOAuthCallback_InvalidState(t *testing.T) {
	r := InitRouter()

	// A state that was never registered in authSessions → session lookup fails → 400
	req, _ := http.NewRequest(http.MethodGet, "/api/v1/auth/callback?code=somecode&state=nonexistent-session-id", nil)
	w := httptest.NewRecorder()

	r.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for unknown session state, got %d", w.Code)
	}
}
