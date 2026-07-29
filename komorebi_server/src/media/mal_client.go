package media

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"komorebi_server/src/utils"
	"net/http"
	"net/url"
	"time"

	"go.uber.org/zap"
)

const (
	DefaultMalBaseURL = "https://api.myanimelist.net/v2"
	DefaultUserAgent  = "Komorebi-App/1.0"

	MalAnimeFields = "synopsis,media_type,my_list_status,rating,mean,num_episodes,popularity,alternative_titles,genres"
	MalMangaFields = "synopsis,media_type,my_list_status,mean,num_chapters,num_volumes,popularity,alternative_titles,genres"
)

var logger = utils.GetLogger()

type MalClient struct {
	BaseURL    string
	HTTPClient *http.Client
	ClientID   string
}

func NewMalClient(clientID string, httpClient *http.Client) *MalClient {
	if httpClient == nil {
		httpClient = &http.Client{Timeout: 15 * time.Second}
	}
	return &MalClient{
		BaseURL:    DefaultMalBaseURL,
		HTTPClient: httpClient,
		ClientID:   clientID,
	}
}

// GetUserAnimeList fetches an anime list from MyAnimeList and normalizes it.
func (c *MalClient) GetUserAnimeList(ctx context.Context, username string, status string, accessToken string) (*PaginatedResponse, error) {
	raw, err := c.fetchMalList(ctx, MalListTypeAnime, username, status, MalAnimeFields, accessToken)
	if err != nil {
		return nil, err
	}
	return c.normalizeResponse(raw, MapMalAnimeToItem), nil
}

// GetUserMangaList fetches a manga list from MyAnimeList and normalizes it.
func (c *MalClient) GetUserMangaList(ctx context.Context, username string, status string, accessToken string) (*PaginatedResponse, error) {
	raw, err := c.fetchMalList(ctx, MalListTypeManga, username, status, MalMangaFields, accessToken)
	if err != nil {
		return nil, err
	}
	return c.normalizeResponse(raw, MapMalMangaToItem), nil
}

func (c *MalClient) fetchMalList(ctx context.Context, listType MalListType, username string, status string, fields string, accessToken string) (*rawMalResponse, error) {
	if username == "" {
		username = "@me"
	}
	u := fmt.Sprintf("%s/users/%s/%s", c.BaseURL, username, listType.String())

	reqURL, err := url.Parse(u)
	if err != nil {
		logger.Error("invalid MAL endpoint URL", zap.Error(err), zap.String("url", u))
		return nil, fmt.Errorf("invalid endpoint URL: %w", err)
	}

	q := reqURL.Query()
	if status != "" {
		q.Set("status", status)
	}
	q.Set("fields", fields)
	q.Set("limit", "100")
	reqURL.RawQuery = q.Encode()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, reqURL.String(), nil)
	if err != nil {
		logger.Error("failed to create MAL request", zap.Error(err))
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("User-Agent", DefaultUserAgent)
	if accessToken != "" {
		req.Header.Set("Authorization", "Bearer "+accessToken)
	} else if c.ClientID != "" {
		req.Header.Set("X-MAL-CLIENT-ID", c.ClientID)
	}

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		logger.Error("network error fetching MAL list", zap.Error(err), zap.String("type", listType.String()), zap.String("user", username))
		return nil, fmt.Errorf("network error fetching %s: %w", listType.String(), err)
	}
	defer func(Body io.ReadCloser) {
		err := Body.Close()
		if err != nil {
			logger.Error("error closing response body", zap.Error(err))
		}
	}(resp.Body)

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		logger.Warn("MAL API returned non-success status code", zap.Int("status_code", resp.StatusCode), zap.String("user", username))
		return nil, fmt.Errorf("MAL API error: status code %d", resp.StatusCode)
	}

	var raw rawMalResponse
	if err := json.NewDecoder(resp.Body).Decode(&raw); err != nil {
		logger.Error("failed to parse MAL response JSON", zap.Error(err))
		return nil, fmt.Errorf("failed to parse MAL response JSON: %w", err)
	}

	return &raw, nil
}

func (c *MalClient) normalizeResponse(raw *rawMalResponse, mapper func(node *RawMalNode, rawListStatus *json.RawMessage) Item) *PaginatedResponse {
	items := make([]Item, 0, len(raw.Data))
	for _, rawItem := range raw.Data {
		items = append(items, mapper(&rawItem.Node, rawItem.ListStatus))
	}

	var prev, next *string
	if raw.Paging.Previous != "" {
		p := raw.Paging.Previous
		prev = &p
	}
	if raw.Paging.Next != "" {
		n := raw.Paging.Next
		next = &n
	}

	return &PaginatedResponse{
		Data: items,
		Paging: PagingInfo{
			Previous:    prev,
			Next:        next,
			HasNextPage: next != nil,
		},
	}
}

// mapBaseNodeToItem maps shared node fields between anime and manga.
func mapBaseNodeToItem(node *RawMalNode) Item {
	item := Item{
		ID:       node.ID,
		IDMal:    &node.ID,
		Provider: "mal",
		Title: Title{
			UserPreferred: node.Title,
			Romanized:     node.Title,
		},
	}

	if node.AlternativeTitles != nil {
		item.Title.English = node.AlternativeTitles.En
		item.Title.Native = node.AlternativeTitles.Ja
		item.Synonyms = node.AlternativeTitles.Synonyms
	}

	if node.MainPicture != nil {
		item.CoverImage = CoverImage{
			Medium: node.MainPicture.Medium,
			Large:  node.MainPicture.Large,
		}
	}

	if node.Synopsis != "" {
		syn := node.Synopsis
		item.Synopsis = &syn
	}
	if node.MediaType != "" {
		fmtStr := node.MediaType
		item.Format = &fmtStr
	}
	if node.Status != "" {
		st := node.Status
		item.Status = &st
	}

	item.MeanScore = node.Mean
	item.Rank = node.Rank
	item.Popularity = node.Popularity

	genres := make([]string, 0, len(node.Genres))
	for _, g := range node.Genres {
		genres = append(genres, g.Name)
	}
	item.Genres = genres

	return item
}

// MapMalAnimeToItem converts a raw MAL anime node into a clean Item.
func MapMalAnimeToItem(node *RawMalNode, rawListStatus *json.RawMessage) Item {
	item := mapBaseNodeToItem(node)
	item.Episodes = node.NumEpisodes

	statusData := rawListStatus
	if statusData == nil || len(*statusData) == 0 {
		statusData = node.MyListStatus
	}

	if statusData != nil && len(*statusData) > 0 {
		var s rawMalAnimeListStatus
		if err := json.Unmarshal(*statusData, &s); err == nil {
			st := s.Status
			var scoreVal *float64
			if s.Score > 0 {
				sc := s.Score
				scoreVal = &sc
			}
			prog := s.NumEpisodesWatched
			var commentsVal *string
			if s.Comments != "" {
				c := s.Comments
				commentsVal = &c
			}
			var updatedVal *string
			if s.UpdatedAt != "" {
				u := s.UpdatedAt
				updatedVal = &u
			}
			item.ListStatus = &ListStatus{
				Status:       &st,
				Score:        scoreVal,
				Progress:     &prog,
				IsRewatching: s.IsRewatching,
				Tags:         s.Tags,
				Comments:     commentsVal,
				UpdatedAt:    updatedVal,
			}
		}
	}

	return item
}

// MapMalMangaToItem converts a raw MAL manga node into a clean Item.
func MapMalMangaToItem(node *RawMalNode, rawListStatus *json.RawMessage) Item {
	item := mapBaseNodeToItem(node)
	item.Chapters = node.NumChapters
	item.Volumes = node.NumVolumes

	statusData := rawListStatus
	if statusData == nil || len(*statusData) == 0 {
		statusData = node.MyListStatus
	}

	if statusData != nil && len(*statusData) > 0 {
		var s rawMalMangaListStatus
		if err := json.Unmarshal(*statusData, &s); err == nil {
			st := s.Status
			var scoreVal *float64
			if s.Score > 0 {
				sc := s.Score
				scoreVal = &sc
			}
			prog := s.NumChaptersRead
			vol := s.NumVolumesRead
			var commentsVal *string
			if s.Comments != "" {
				c := s.Comments
				commentsVal = &c
			}
			var updatedVal *string
			if s.UpdatedAt != "" {
				u := s.UpdatedAt
				updatedVal = &u
			}
			item.ListStatus = &ListStatus{
				Status:          &st,
				Score:           scoreVal,
				Progress:        &prog,
				ProgressVolumes: &vol,
				IsRewatching:    s.IsRereading,
				Tags:            s.Tags,
				Comments:        commentsVal,
				UpdatedAt:       updatedVal,
			}
		}
	}

	return item
}
