import 'package:flutter_test/flutter_test.dart';
import 'package:komorebi/crawlers/crawler_engine.dart';
import 'package:komorebi/models/api/crawler_config.dart';

void main() {
  group('CrawlerEngine Tests', () {
    test('parses Nyaa RSS correctly', () {
      const config = CrawlerConfig(
        id: 'nyaa',
        name: 'Nyaa.si Anime Torrents',
        baseUrl: 'https://nyaa.si/?page=rss&q={title}+{number}&c=1_2&f=0',
        itemSelector: 'item',
        titleSelector: 'title',
        linkSelector: 'link',
        isActive: true,
      );

      const sampleRss = '''
        <rss version="2.0">
          <channel>
            <item>
              <title>[SubsPlease] One Piece - 1080 (1080p) [12345678].mkv</title>
              <link>https://nyaa.si/download/123456.torrent</link>
            </item>
          </channel>
        </rss>
      ''';

      final engine = CrawlerEngine(config);
      final results = engine.parseHtml(rawHtml: sampleRss);

      expect(results.length, equals(1));
      expect(
        results.first.title,
        equals('[SubsPlease] One Piece - 1080 (1080p) [12345678].mkv'),
      );
      expect(
        results.first.downloadUrl,
        equals('https://nyaa.si/download/123456.torrent'),
      );
      expect(results.first.source, equals('nyaa'));
    });

    test('parses RSS item correctly', () {
      const config = CrawlerConfig(
        id: 'subsplease',
        name: 'SubsPlease RSS',
        baseUrl: 'https://subsplease.org/rss/?r=1080',
        itemSelector: 'item',
        titleSelector: 'title',
        linkSelector: 'link',
        isActive: true,
      );

      const sampleRss = '''
        <rss>
          <channel>
            <item>
              <title>[SubsPlease] Bleach - 12 (1080p)</title>
              <link>https://subsplease.org/download/bleach-12.torrent</link>
            </item>
          </channel>
        </rss>
      ''';

      final engine = CrawlerEngine(config);
      final results = engine.parseHtml(rawHtml: sampleRss);

      expect(results.length, equals(1));
      expect(results.first.title, equals('[SubsPlease] Bleach - 12 (1080p)'));
      expect(
        results.first.downloadUrl,
        equals('https://subsplease.org/download/bleach-12.torrent'),
      );
      expect(results.first.source, equals('subsplease'));
    });

    test(
      'returns empty list immediately if config is disabled (isActive == false)',
      () {
        const config = CrawlerConfig(
          id: 'disabled_provider',
          name: 'Disabled Provider',
          baseUrl: 'https://example.com/search?q={title}',
          itemSelector: 'item',
          titleSelector: 'title',
          linkSelector: 'link',
          isActive: false,
        );

        const sampleRss = '''
        <rss>
          <channel>
            <item>
              <title>Should Not Be Parsed</title>
              <link>https://example.com/item.torrent</link>
            </item>
          </channel>
        </rss>
      ''';

        final engine = CrawlerEngine(config);
        final results = engine.parseHtml(rawHtml: sampleRss);

        expect(results, isEmpty);
      },
    );
  });
}
