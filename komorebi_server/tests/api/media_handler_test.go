package api

import (
	"encoding/json"
	. "komorebi_server/src/api"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestMediaEndpointsRegistration(t *testing.T) {
	r := InitRouter()

	req, _ := http.NewRequest(http.MethodGet, "/api/v1/media/anime?username=test", nil)
	w := httptest.NewRecorder()

	r.ServeHTTP(w, req)

	// Since network call to MAL without valid token will return error status (500),
	// check that the route responded with our JSON error format instead of 404.
	if w.Code == http.StatusNotFound {
		t.Fatalf("expected route /api/v1/media/anime to be registered, but got 404")
	}

	var res Response
	if err := json.NewDecoder(w.Body).Decode(&res); err != nil {
		t.Fatalf("failed to decode response JSON: %v", err)
	}

	if res.Success {
		t.Errorf("expected failure response for unauthenticated MAL request, got success")
	}
}
