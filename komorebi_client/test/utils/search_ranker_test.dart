import 'package:flutter_test/flutter_test.dart';
import 'package:komorebi/src/models/api/crawler_config.dart';
import 'package:komorebi/src/core/utils/search_ranker.dart';

void main() {
  group('SearchRanker Tests', () {
    const config1 = CrawlerConfig(
      id: 'config_1',
      name: 'Tracker 1',
      baseUrl: 'https://tracker1.com/q={title}',
      itemSelector: 'item',
      titleSelector: 'title',
      linkSelector: 'link',
      isActive: true,
    );

    const config2 = CrawlerConfig(
      id: 'config_2',
      name: 'Tracker 2',
      baseUrl: 'https://tracker2.com/q={title}',
      itemSelector: 'item',
      titleSelector: 'title',
      linkSelector: 'link',
      isActive: true,
    );

    final configs = [config1, config2];

    test('ranks exact season and episode matches higher', () async {
      final results = [
        const CrawlerResult(
          title: 'Shingeki no Kyojin S3 - 01',
          downloadUrl: 'url1',
          source: 'config_1',
          popularity: 100,
          parsedTitle: CrawlerParsedTitle(
            title: ['Shingeki no Kyojin'],
            season: ['3'],
            episode: ['1'],
            videoResolution: ['1080p'],
          ),
        ),
        const CrawlerResult(
          title: 'Shingeki no Kyojin S1 - 01',
          downloadUrl: 'url2',
          source: 'config_2',
          popularity: 500,
          parsedTitle: CrawlerParsedTitle(
            title: ['Shingeki no Kyojin'],
            season: ['1'],
            episode: ['1'],
            videoResolution: ['1080p'],
          ),
        ),
      ];

      final ranked = await SearchRanker.rankResults(
        query: 'Shingeki no Kyojin S3 E1',
        results: results,
        configs: configs,
      );

      expect(ranked.first.title, equals('Shingeki no Kyojin S3 - 01'));
    });

    test('falls back to popularity ranking when parsedTitle is null', () async {
      final results = [
        const CrawlerResult(
          title: 'Random Title Low Pop',
          downloadUrl: 'url1',
          source: 'config_1',
          popularity: 10,
          parsedTitle: null,
        ),
        const CrawlerResult(
          title: 'Random Title High Pop',
          downloadUrl: 'url2',
          source: 'config_2',
          popularity: 500,
          parsedTitle: null,
        ),
      ];

      final ranked = await SearchRanker.rankResults(
        query: 'Attack on Titan',
        results: results,
        configs: configs,
      );

      expect(ranked.first.title, equals('Random Title High Pop'));
    });

    test(
      'preserves result from earlier declared config when scores and titles match',
      () async {
        final results = [
          const CrawlerResult(
            title: 'One Piece - 1080 (1080p)',
            downloadUrl: 'url_from_config2',
            source: 'config_2',
            popularity: 100,
            parsedTitle: CrawlerParsedTitle(
              title: ['One Piece'],
              episode: ['1080'],
              videoResolution: ['1080p'],
            ),
          ),
          const CrawlerResult(
            title: 'One Piece - 1080 (1080p)',
            downloadUrl: 'url_from_config1',
            source: 'config_1',
            popularity: 100,
            parsedTitle: CrawlerParsedTitle(
              title: ['One Piece'],
              episode: ['1080'],
              videoResolution: ['1080p'],
            ),
          ),
        ];

        final ranked = await SearchRanker.rankResults(
          query: 'One Piece 1080',
          results: results,
          configs: configs,
        );

        expect(
          ranked.length,
          equals(1),
        ); // Deduplicated duplicate title with same score
        expect(
          ranked.first.source,
          equals('config_1'),
        ); // Config 1 comes first in configs
      },
    );
  });
}
