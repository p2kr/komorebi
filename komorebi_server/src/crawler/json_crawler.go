package crawler

type JsonCrawlerEngine struct{}

func (e *JsonCrawlerEngine) CanCrawl(content string) bool {
	return true
}

func (e *JsonCrawlerEngine) Crawl(content string, config Config) []CrawlerResult {
	var results []CrawlerResult

	return results
}
