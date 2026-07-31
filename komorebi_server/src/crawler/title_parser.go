package crawler

type AnitomyTitleParser struct{}

func (p *AnitomyTitleParser) CanParse(rawTitle string) bool {
	return true
}

func (p *AnitomyTitleParser) Parse(rawTitle string) ParsedTitle {
	return ParsedTitle{}
}

// ---------- //

type RegexTitleParser struct{}

func (p *RegexTitleParser) CanParse(rawTitle string) bool {
	return true
}

func (p *RegexTitleParser) Parse(rawTitle string) ParsedTitle {
	return ParsedTitle{}
}
