package api

import (
	"encoding/json"
	. "komorebi_server/src/api"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestMediaEndpointsRegistration(t *testing.T) {
	r := InitRouter()

	req, _ := http.NewRequest(http.MethodGet, "/api/v1/media/anime?username=test", nil)
	w := httptest.NewRecorder()

	r.ServeHTTP(w, req)

	// Since network call to MAL without valid token will return error status (500),
	// check that the route responded with our JSON error format instead of 404.
	assert.NotEqual(t, http.StatusNotFound, w.Code, "expected route /api/v1/media/anime to be registered")

	var res Response
	require.NoError(t, json.NewDecoder(w.Body).Decode(&res), "failed to decode response JSON")

	assert.False(t, res.Success, "expected failure response for unauthenticated MAL request")
}
