package api

import (
	"komorebi_server/src/crawler"
	"net/http"

	"github.com/gin-gonic/gin"
)

// FindDownloadableMedia finds downloadable media based on the given query
func FindDownloadableMedia(c *gin.Context) {
	query := c.Query("query")

	crawlerEngine, err := crawler.NewCrawlerEngine(query)
	if err != nil {
		Fail(c, http.StatusBadRequest, "CRAWLER_ENGINE_ERROR", err.Error())
		return
	}

	results := crawlerEngine.Begin()

	Ok(c, results)
}
