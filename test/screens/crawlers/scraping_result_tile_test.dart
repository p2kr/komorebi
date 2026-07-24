import 'package:flutter_test/flutter_test.dart';
import 'package:komorebi/models/api/crawler_config.dart';
import 'package:komorebi/screens/crawlers/smart_matcher/scraping_result_tile.dart';

void main() {
  group('ScrapingResultTile Tests', () {
    test('normalizes 1920x1080 to 1080p', () {
      expect(
        ScrapingResultTile.normalizeResolution(['1920x1080']),
        equals('1080p'),
      );
    });

    test('normalizes combined resolution string to 1080p', () {
      expect(
        ScrapingResultTile.normalizeResolution(['1920x1080', 'x265', '10bit']),
        equals('1080p'),
      );
    });

    test('normalizes 720p and 1280x720', () {
      expect(
        ScrapingResultTile.normalizeResolution(['1280x720']),
        equals('720p'),
      );
      expect(ScrapingResultTile.normalizeResolution(['720p']), equals('720p'));
    });

    test('normalizes 4k and 2160', () {
      expect(
        ScrapingResultTile.normalizeResolution(['3840x2160']),
        equals('4K'),
      );
      expect(ScrapingResultTile.normalizeResolution(['4K']), equals('4K'));
    });

    test('returns null for empty or null resolution list', () {
      expect(ScrapingResultTile.normalizeResolution(null), isNull);
      expect(ScrapingResultTile.normalizeResolution([]), isNull);
    });

    test('formats season and episode badge string across two lines', () {
      expect(
        ScrapingResultTile.formatEpisodeSeasonBadge(
          const CrawlerParsedTitle(season: ['3'], episode: ['23']),
        ),
        equals('S3\nE23'),
      );
    });

    test('formats episode only badge string across two lines', () {
      expect(
        ScrapingResultTile.formatEpisodeSeasonBadge(
          const CrawlerParsedTitle(episode: ['12']),
        ),
        equals('EP\n12'),
      );
    });

    test('formats season only badge string', () {
      expect(
        ScrapingResultTile.formatEpisodeSeasonBadge(
          const CrawlerParsedTitle(season: ['2']),
        ),
        equals('S2'),
      );
    });

    test('returns null for null parsed title', () {
      expect(ScrapingResultTile.formatEpisodeSeasonBadge(null), isNull);
    });

    test('formats subtitles correctly', () {
      expect(
        ScrapingResultTile.formatSubtitles(
          const CrawlerParsedTitle(subtitles: ['English', 'Spanish']),
        ),
        equals('English, Spanish'),
      );
      expect(
        ScrapingResultTile.formatSubtitles(
          const CrawlerParsedTitle(subtitles: []),
        ),
        isNull,
      );
      expect(ScrapingResultTile.formatSubtitles(null), isNull);
    });

    test('formats language correctly', () {
      expect(
        ScrapingResultTile.formatLanguage(
          const CrawlerParsedTitle(language: ['Japanese']),
        ),
        equals('Japanese'),
      );
      expect(
        ScrapingResultTile.formatLanguage(
          const CrawlerParsedTitle(language: []),
        ),
        isNull,
      );
      expect(ScrapingResultTile.formatLanguage(null), isNull);
    });

    test('formats download button label with resolution and size', () {
      expect(
        ScrapingResultTile.formatDownloadButtonLabel(
          resolution: '1080p',
          size: '1.35 GB',
        ),
        equals('1080p | 1.35 GB'),
      );
      expect(
        ScrapingResultTile.formatDownloadButtonLabel(
          resolution: '720p',
          size: null,
        ),
        equals('720p'),
      );
      expect(
        ScrapingResultTile.formatDownloadButtonLabel(
          resolution: null,
          size: '500 MB',
        ),
        equals('500 MB'),
      );
      expect(
        ScrapingResultTile.formatDownloadButtonLabel(
          resolution: null,
          size: null,
        ),
        equals('Download'),
      );
    });
  });
}
