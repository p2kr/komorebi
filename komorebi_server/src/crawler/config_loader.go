package crawler

import (
	"errors"
	"komorebi_server/assets"
	"komorebi_server/src/utils"
	"os"
	"path"

	"go.uber.org/zap"
	"go.yaml.in/yaml/v4"
)

var logger = utils.GetLogger()

var loadedConfigsList []Config

// InitCrawler Initializes the crawler by loading crawler configs from assets.
func InitCrawler() {
	err := initCrawlerConfigs()
	if err != nil {
		logger.Error("Failed to init crawler configs", zap.Error(err))
	}
}

// Read crawler configs from assets
func initCrawlerConfigs() error {
	var document yaml.Node
	err := yaml.Load(getCrawlerConfigsYaml(), &document)
	if err != nil {
		logger.Error("Failed to unmarshal crawlerConfigsYaml", zap.Error(err))
		return err
	}

	if len(document.Content) == 0 {
		logger.Warn("base crawlerConfigsYaml is empty")
		return errors.New("Crawler configs are empty")
	}

	rootMap := document.Content[0]

	if rootMap.Kind != yaml.MappingNode {
		logger.Error("Expected crawlerConfigsYaml root to be a map")
		return errors.New("Expected crawlerConfigsYaml root to be a map")
	}

	var crawlerConfigsList []Config
	for i := 0; i < len(rootMap.Content); i += 2 {
		var config Config

		keyNode := rootMap.Content[i]
		valueNode := rootMap.Content[i+1]

		if err := valueNode.Decode(&config); err != nil {
			logger.Error("Failed to decode valueNode", zap.Error(err))
			continue
		}
		config.Id = keyNode.Value

		crawlerConfigsList = append(crawlerConfigsList, config)
	}

	// Copy crawlerConfigsList to loadedConfigsList TODO: atomically
	copy(loadedConfigsList, crawlerConfigsList)

	logger.Info("Loaded crawlerConfigsList", zap.Any("crawlerConfigsList", crawlerConfigsList))
	return nil
}

// Copies crawlerConfigsYaml from assets to user config directory
//   - if the file does not exist, it is created.
//   - if the file exists and is empty, it is overwritten.
//   - if the file exists and is not empty, it is read from the user config directory.
func getCrawlerConfigsYaml() []byte {
	// Get config from user config directory
	userConfigPath := path.Join(utils.AppDir(), "crawler_config.yaml")

	userConfigFile, err := os.ReadFile(userConfigPath)
	if err != nil || len(userConfigFile) == 0 {
		if !os.IsNotExist(err) {
			logger.Error("No user crawler config file", zap.Error(err))
		}
	} else {
		logger.Info("Loaded user crawler config file", zap.String("userConfigPath", userConfigPath))
		return userConfigFile
	}

	// If the file does not exist or some error occured, create it from the default config
	err = os.WriteFile(userConfigPath, assets.CrawlerConfigsYaml, os.ModePerm)
	if err != nil {
		logger.Error("Failed to create user crawler config file", zap.Error(err))
	}

	logger.Info("Created user crawler config file", zap.String("userConfigPath", userConfigPath))
	return assets.CrawlerConfigsYaml
}

func GetLoadedConfigsList() []Config {
	return loadedConfigsList
}
