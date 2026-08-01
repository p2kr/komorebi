package api

import (
	"encoding/json"
	"komorebi_server/src/api"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestResponseJSON(t *testing.T) {
	t.Run("marshal success response without error or meta", func(t *testing.T) {
		resp := api.Response{
			Success: true,
			Data:    map[string]string{"foo": "bar"},
		}
		data, err := json.Marshal(resp)
		require.NoError(t, err, "failed to marshal Response")

		var decoded api.Response
		require.NoError(t, json.Unmarshal(data, &decoded), "failed to unmarshal Response")

		assert.True(t, decoded.Success, "expected Success to be true")
		assert.Nil(t, decoded.Error, "expected Error to be nil")
		assert.Nil(t, decoded.Meta, "expected Meta to be nil")
	})

	t.Run("marshal error response", func(t *testing.T) {
		resp := api.Response{
			Success: false,
			Error: &api.ErrorInfo{
				Code:    "INVALID_INPUT",
				Message: "Field username is required",
			},
		}
		data, err := json.Marshal(resp)
		require.NoError(t, err, "failed to marshal Response")

		var decoded api.Response
		require.NoError(t, json.Unmarshal(data, &decoded), "failed to unmarshal Response")

		assert.False(t, decoded.Success, "expected Success to be false")
		require.NotNil(t, decoded.Error, "expected Error to be non-nil")
		assert.Equal(t, "INVALID_INPUT", decoded.Error.Code, "expected code 'INVALID_INPUT'")
		assert.Equal(t, "Field username is required", decoded.Error.Message, "expected message 'Field username is required'")
	})

	t.Run("marshal response with meta pagination", func(t *testing.T) {
		resp := api.Response{
			Success: true,
			Data:    []string{"item1", "item2"},
			Meta: &api.Meta{
				Page:       1,
				PerPage:    10,
				Total:      2,
				TotalPages: 1,
			},
		}
		data, err := json.Marshal(resp)
		require.NoError(t, err, "failed to marshal Response")

		var decoded api.Response
		require.NoError(t, json.Unmarshal(data, &decoded), "failed to unmarshal Response")

		require.NotNil(t, decoded.Meta, "expected Meta to be non-nil")
		assert.Equal(t, 1, decoded.Meta.Page, "unexpected Meta value for Page")
		assert.Equal(t, 10, decoded.Meta.PerPage, "unexpected Meta value for PerPage")
		assert.Equal(t, 2, decoded.Meta.Total, "unexpected Meta value for Total")
		assert.Equal(t, 1, decoded.Meta.TotalPages, "unexpected Meta value for TotalPages")
	})
}

func TestOkHelper(t *testing.T) {
	gin.SetMode(gin.TestMode)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)

	api.Ok(c, map[string]string{"result": "success"})

	assert.Equal(t, http.StatusOK, w.Code, "expected status 200")

	var resp api.Response
	require.NoError(t, json.Unmarshal(w.Body.Bytes(), &resp), "failed to unmarshal body")

	assert.True(t, resp.Success, "expected resp.Success to be true")
}

func TestFailHelper(t *testing.T) {
	gin.SetMode(gin.TestMode)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)

	api.Fail(c, http.StatusBadRequest, "BAD_REQUEST", "invalid payload")

	assert.Equal(t, http.StatusBadRequest, w.Code, "expected status 400")

	var resp api.Response
	require.NoError(t, json.Unmarshal(w.Body.Bytes(), &resp), "failed to unmarshal body")

	assert.False(t, resp.Success, "expected resp.Success to be false")
	require.NotNil(t, resp.Error, "expected resp.Error to be non-nil")
	assert.Equal(t, "BAD_REQUEST", resp.Error.Code, "expected code 'BAD_REQUEST'")
	assert.Equal(t, "invalid payload", resp.Error.Message, "expected message 'invalid payload'")
}
