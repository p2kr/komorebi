package crawler

type HtmlCrawlerEngine struct{}

func (e *HtmlCrawlerEngine) CanCrawl(content string) bool {
	return true
}

func (e *HtmlCrawlerEngine) Crawl(content string, config Config) []CrawlerResult {
	var results []CrawlerResult

	return results
}
