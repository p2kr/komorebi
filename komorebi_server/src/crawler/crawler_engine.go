package crawler

import (
	"errors"
	"io"
	"net/http"
	"strings"

	"go.uber.org/zap"
)

type CrawlerEngine struct {
	query        string
	configs      []Config
	crawlers     []Crawler
	titleParsers []TitleParser
}

// NewCrawlerEngine creates a new CrawlerEngine with the given query
func NewCrawlerEngine(query string) (*CrawlerEngine, error) {
	if len(query) == 0 {
		return nil, errors.New("query is empty")
	}
	if len(GetLoadedConfigsList()) == 0 {
		return nil, errors.New("no configs loaded")
	}

	// TODO: Add validation for crawlers and title parsers

	return &CrawlerEngine{
		query:        query,
		configs:      GetLoadedConfigsList(),
		crawlers:     []Crawler{&HtmlCrawlerEngine{}, &JsonCrawlerEngine{}},
		titleParsers: []TitleParser{&AnitomyTitleParser{}, &RegexTitleParser{}},
	}, nil
}

// Parse parses the content and returns the results
// It runs concurrently for each config and crawler
func (e *CrawlerEngine) Begin() []CrawlerResult {
	var results []CrawlerResult

	for _, config := range e.configs {
		// TODO: Make it concurrent
		results = append(results, e.crawlSingle(config)...)
	}

	return results
}

func (e *CrawlerEngine) crawlSingle(config Config) []CrawlerResult {
	var results []CrawlerResult

	if !config.IsActive {
		logger.Info("crawler is not active", zap.String("id", config.Id))
		return results
	}

	url := strings.ReplaceAll(config.BaseUrl, "query", e.query)

	// Hit the search query and extract html/json
	resp, err := http.Get(url)
	if err != nil {
		logger.Error("error fetching ", zap.String("url", url))
		return results
	}
	defer resp.Body.Close()

	// Read the response body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		logger.Error("error reading body", zap.String("url", url))
		return results
	}
	content := string(body)

	// check if content conforms to html or json
	// if not, return early
	// if so, crawl using the first appropriate crawler
	for _, crawler := range e.crawlers {
		if crawler.CanCrawl(content) {
			results = append(results, crawler.Crawl(content, config)...)
			break
		}
	}

	return results
}

func (e *CrawlerEngine) parseTitle(rawTitle string) ParsedTitle {
	var parsedTitle ParsedTitle
	for _, parser := range e.titleParsers {
		if parser.CanParse(rawTitle) {
			parsedTitle = parser.Parse(rawTitle)
			break
		}
	}
	return parsedTitle
}
