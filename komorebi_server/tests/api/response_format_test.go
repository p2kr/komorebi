package api

import (
	"encoding/json"
	"komorebi_server/src/api"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestResponseJSON(t *testing.T) {
	t.Run("marshal success response without error or meta", func(t *testing.T) {
		resp := api.Response{
			Success: true,
			Data:    map[string]string{"foo": "bar"},
		}
		data, err := json.Marshal(resp)
		if err != nil {
			t.Fatalf("failed to marshal Response: %v", err)
		}

		var decoded api.Response
		if err := json.Unmarshal(data, &decoded); err != nil {
			t.Fatalf("failed to unmarshal Response: %v", err)
		}

		if !decoded.Success {
			t.Error("expected Success to be true")
		}
		if decoded.Error != nil {
			t.Errorf("expected Error to be nil, got %+v", decoded.Error)
		}
		if decoded.Meta != nil {
			t.Errorf("expected Meta to be nil, got %+v", decoded.Meta)
		}
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
		if err != nil {
			t.Fatalf("failed to marshal Response: %v", err)
		}

		var decoded api.Response
		if err := json.Unmarshal(data, &decoded); err != nil {
			t.Fatalf("failed to unmarshal Response: %v", err)
		}

		if decoded.Success {
			t.Error("expected Success to be false")
		}
		if decoded.Error == nil {
			t.Fatal("expected Error to be non-nil")
		}
		if decoded.Error.Code != "INVALID_INPUT" {
			t.Errorf("expected code 'INVALID_INPUT', got %q", decoded.Error.Code)
		}
		if decoded.Error.Message != "Field username is required" {
			t.Errorf("expected message 'Field username is required', got %q", decoded.Error.Message)
		}
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
		if err != nil {
			t.Fatalf("failed to marshal Response: %v", err)
		}

		var decoded api.Response
		if err := json.Unmarshal(data, &decoded); err != nil {
			t.Fatalf("failed to unmarshal Response: %v", err)
		}

		if decoded.Meta == nil {
			t.Fatal("expected Meta to be non-nil")
		}
		if decoded.Meta.Page != 1 || decoded.Meta.PerPage != 10 || decoded.Meta.Total != 2 || decoded.Meta.TotalPages != 1 {
			t.Errorf("unexpected Meta values: %+v", decoded.Meta)
		}
	})
}

func TestOkHelper(t *testing.T) {
	gin.SetMode(gin.TestMode)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)

	api.Ok(c, map[string]string{"result": "success"})

	if w.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", w.Code)
	}

	var resp api.Response
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to unmarshal body: %v", err)
	}

	if !resp.Success {
		t.Error("expected resp.Success to be true")
	}
}

func TestFailHelper(t *testing.T) {
	gin.SetMode(gin.TestMode)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)

	api.Fail(c, http.StatusBadRequest, "BAD_REQUEST", "invalid payload")

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected status 400, got %d", w.Code)
	}

	var resp api.Response
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to unmarshal body: %v", err)
	}

	if resp.Success {
		t.Error("expected resp.Success to be false")
	}
	if resp.Error == nil {
		t.Fatal("expected resp.Error to be non-nil")
	}
	if resp.Error.Code != "BAD_REQUEST" {
		t.Errorf("expected code 'BAD_REQUEST', got %q", resp.Error.Code)
	}
	if resp.Error.Message != "invalid payload" {
		t.Errorf("expected message 'invalid payload', got %q", resp.Error.Message)
	}
}
