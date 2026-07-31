package crawler

import "encoding/json"

type Crawler interface {
	CanCrawl(content string) bool
	Crawl(content string, config Config) []CrawlerResult
}

type TitleParser interface {
	CanParse(rawTitle string) bool
	Parse(rawTitle string) ParsedTitle
}

type Config struct {
	Id                 string `json:"id" yaml:"id"`
	Name               string `json:"name" yaml:"name"`
	BaseUrl            string `json:"base_url" yaml:"base_url"`
	ItemSelector       string `json:"item_selector" yaml:"item_selector"`
	TitleSelector      string `json:"title_selector" yaml:"title_selector"`
	LinkSelector       string `json:"link_selector" yaml:"link_selector"`
	PopularitySelector string `json:"popularity_selector" yaml:"popularity_selector"`
	SizeSelector       string `json:"size_selector" yaml:"size_selector"`
	IsActive           bool   `json:"is_active" yaml:"is_active"`
}

type CrawlerResult struct {
	Title      string `json:"title,omitempty"`
	Link       string `json:"link,omitempty"`
	Popularity string `json:"popularity,omitempty"`
	Size       string `json:"size,omitempty"`
	Source     string `json:"source,omitempty"`
}

type ParsedTitle struct {
	AudioTerm          StringOrList `json:"audio_term,omitempty"`
	Device             StringOrList `json:"device,omitempty"`
	Episode            StringOrList `json:"episode,omitempty"`
	EpisodeTitle       StringOrList `json:"episode_title,omitempty"`
	FileChecksum       StringOrList `json:"file_checksum,omitempty"`
	FileExtension      StringOrList `json:"file_extension,omitempty"`
	Language           StringOrList `json:"language,omitempty"`
	Other              StringOrList `json:"other,omitempty"`
	Part               StringOrList `json:"part,omitempty"`
	ReleaseGroup       StringOrList `json:"release_group,omitempty"`
	ReleaseInformation StringOrList `json:"release_information,omitempty"`
	ReleaseVersion     StringOrList `json:"release_version,omitempty"`
	Season             StringOrList `json:"season,omitempty"`
	Source             StringOrList `json:"source,omitempty"`
	Subtitles          StringOrList `json:"subtitles,omitempty"`
	Title              StringOrList `json:"title,omitempty"`
	Type               StringOrList `json:"type,omitempty"`
	VideoResolution    StringOrList `json:"video_resolution,omitempty"`
	VideoTerm          StringOrList `json:"video_term,omitempty"`
	Volume             StringOrList `json:"volume,omitempty"`
	Year               StringOrList `json:"year,omitempty"`
}

type StringOrList []string

func (sol *StringOrList) UnmarshalJSON(data []byte) error {
	var list []string
	if err := json.Unmarshal(data, &list); err == nil {
		*sol = list
		return nil
	}

	var single string
	if err := json.Unmarshal(data, &single); err != nil {
		return err
	}

	*sol = []string{single}
	return nil
}
