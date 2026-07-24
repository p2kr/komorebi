import 'package:flutter_test/flutter_test.dart';
import 'package:komorebi/crawlers/crawler_engine.dart';
import 'package:komorebi/crawlers/html_crawler_parser.dart';
import 'package:komorebi/crawlers/json_crawler_parser.dart';
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
      final results = engine.parse(rawHtml: sampleRss);

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
      final results = engine.parse(rawHtml: sampleRss);

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
        final results = engine.parse(rawHtml: sampleRss);

        expect(results, isEmpty);
      },
    );

    test('parses popularity field when popularitySelector is provided', () {
      const config = CrawlerConfig(
        id: 'nyaa_rss',
        name: 'Nyaa RSS',
        baseUrl: 'https://nyaa.si/?page=rss&q={title}',
        itemSelector: 'item',
        titleSelector: 'title',
        linkSelector: 'link',
        popularitySelector: 'seeders',
        isActive: true,
      );

      const sampleRss = '''
        <rss version="2.0">
          <channel>
            <item>
              <title>[SubsPlease] One Piece - 1080 (1080p)</title>
              <link>https://nyaa.si/download/123456.torrent</link>
              <seeders>250</seeders>
            </item>
          </channel>
        </rss>
      ''';

      final engine = CrawlerEngine(config);
      final results = engine.parse(rawHtml: sampleRss);

      expect(results.length, equals(1));
      expect(results.first.popularity, equals(250.0));
    });

    test('parses SubsPlease API JSON response correctly', () {
      const config = CrawlerConfig(
        id: 'subsplease',
        name: 'SubsPlease API',
        baseUrl: 'https://subsplease.org/api/?f=search&tz=UTC&s={title}',
        itemSelector: 'json',
        titleSelector: 'show',
        linkSelector: 'downloads',
        isActive: true,
      );

      const sampleJson = '''
        {
          "Tensei Shitara Slime Datta Ken S4 - 15": {
            "time": "07/17/26",
            "show": "Tensei Shitara Slime Datta Ken S4",
            "episode": "15",
            "downloads": [
              {
                "res": "1080",
                "magnet": "magnet:?xt=urn:btih:1234567890abcdef",
                "filesize": "1.35 GB"
              }
            ]
          }
        }
      ''';

      final engine = CrawlerEngine(config);
      final results = engine.parse(rawHtml: sampleJson);

      expect(results.length, equals(1));
      expect(results.first.title,
          equals('Tensei Shitara Slime Datta Ken S4 - 15 (1080p)'));
      expect(
        results.first.downloadUrl,
        equals('magnet:?xt=urn:btih:1234567890abcdef'),
      );
      expect(results.first.source, equals('subsplease'));
    });

    test(
        'parses SubsPlease API JSON response with multiple resolutions correctly', () {
      const config = CrawlerConfig(
        id: 'subsplease',
        name: 'SubsPlease API',
        baseUrl: 'https://subsplease.org/api/?f=search&tz=UTC&s={title}',
        itemSelector: 'json',
        titleSelector: 'show',
        linkSelector: 'downloads',
        isActive: true,
      );

      const sampleMultiResJson = '''
        {
          "Bleach - 12": {
            "show": "Bleach",
            "episode": "12",
            "downloads": [
              {
                "res": "480",
                "magnet": "magnet:?xt=urn:btih:hash480",
                "filesize": "350 MB"
              },
              {
                "res": "720",
                "magnet": "magnet:?xt=urn:btih:hash720",
                "filesize": "650 MB"
              },
              {
                "res": "1080",
                "magnet": "magnet:?xt=urn:btih:hash1080",
                "filesize": "1.35 GB"
              }
            ]
          }
        }
      ''';

      final engine = CrawlerEngine(config);
      final results = engine.parse(rawHtml: sampleMultiResJson);

      expect(results.length, equals(3));

      expect(results[0].title, equals('Bleach - 12 (480p)'));
      expect(results[0].downloadUrl, equals('magnet:?xt=urn:btih:hash480'));
      expect(results[0].size, equals('350 MB'));

      expect(results[1].title, equals('Bleach - 12 (720p)'));
      expect(results[1].downloadUrl, equals('magnet:?xt=urn:btih:hash720'));
      expect(results[1].size, equals('650 MB'));

      expect(results[2].title, equals('Bleach - 12 (1080p)'));
      expect(results[2].downloadUrl, equals('magnet:?xt=urn:btih:hash1080'));
      expect(results[2].size, equals('1.35 GB'));
    });

    test('parses size field when sizeSelector is provided in RSS', () {
      const config = CrawlerConfig(
        id: 'nyaa_rss',
        name: 'Nyaa RSS',
        baseUrl: 'https://nyaa.si/?page=rss&q={title}',
        itemSelector: 'item',
        titleSelector: 'title',
        linkSelector: 'link',
        sizeSelector: 'size',
        isActive: true,
      );

      const sampleRss = '''
        <rss version="2.0">
          <channel>
            <item>
              <title>[SubsPlease] One Piece - 1080 (1080p)</title>
              <link>https://nyaa.si/download/123456.torrent</link>
              <size>1.2 GiB</size>
            </item>
          </channel>
        </rss>
      ''';

      final engine = CrawlerEngine(config);
      final results = engine.parse(rawHtml: sampleRss);

      expect(results.length, equals(1));
      expect(results.first.size, equals('1.2 GiB'));
    });

    test('parses JSON array format with custom selectors dynamically', () {
      const config = CrawlerConfig(
        id: 'custom_api',
        name: 'Custom Tracker',
        baseUrl: 'https://api.example.com/search',
        itemSelector: 'json',
        titleSelector: 'name',
        linkSelector: 'magnet_url',
        popularitySelector: 'seeds',
        sizeSelector: 'file_size',
        isActive: true,
      );

      const sampleJson = '''
        [
          {
            "name": "Solo Leveling - 05",
            "magnet_url": "magnet:?xt=urn:btih:abcdef123456",
            "seeds": "1.5k",
            "file_size": "450 MB"
          }
        ]
      ''';

      final engine = CrawlerEngine(config);
      final results = engine.parse(rawHtml: sampleJson);

      expect(results.length, equals(1));
      expect(results.first.title, equals('Solo Leveling - 05'));
      expect(results.first.downloadUrl,
          equals('magnet:?xt=urn:btih:abcdef123456'));
      expect(results.first.popularity, equals(1500.0));
      expect(results.first.size, equals('450 MB'));
    });

    test('resolves relative download URLs against baseUrl', () {
      const config = CrawlerConfig(
        id: 'relative_site',
        name: 'Relative Site',
        baseUrl: 'https://animetosho.org/search?q=naruto',
        itemSelector: 'div.item',
        titleSelector: 'a.title',
        linkSelector: 'a.download',
        isActive: true,
      );

      const sampleHtml = '''
        <div class="item">
          <a class="title" href="/view/123">Naruto Shippuden - 500</a>
          <a class="download" href="/download/123.torrent">Download</a>
        </div>
      ''';

      final engine = CrawlerEngine(config);
      final results = engine.parse(rawHtml: sampleHtml);

      expect(results.length, equals(1));
      expect(
        results.first.downloadUrl,
        equals('https://animetosho.org/download/123.torrent'),
      );
    });

    test(
        'handles invalid CSS selectors gracefully without throwing exception', () {
      const config = CrawlerConfig(
        id: 'invalid_selector',
        name: 'Invalid Selector Test',
        baseUrl: 'https://example.com',
        itemSelector: ':::invalid..css[selector',
        titleSelector: 'title',
        linkSelector: 'a',
        isActive: true,
      );

      const sampleHtml = '<html><body><div>Test</div></body></html>';

      final engine = CrawlerEngine(config);
      final results = engine.parse(rawHtml: sampleHtml);

      expect(results, isEmpty);
    });

    test('handles invalid JSON gracefully when itemSelector is json', () {
      const config = CrawlerConfig(
        id: 'json_test',
        name: 'JSON Test',
        baseUrl: 'https://example.com',
        itemSelector: 'json',
        titleSelector: 'title',
        linkSelector: 'link',
        isActive: true,
      );

      const sampleInvalidJson = '{ invalid json content }';

      final engine = CrawlerEngine(config);
      final results = engine.parse(rawHtml: sampleInvalidJson);

      expect(results, isEmpty);
    });

    test('JsonCrawlerParser and HtmlCrawlerParser work independently', () {
      const jsonConfig = CrawlerConfig(
        id: 'json_id',
        name: 'JSON',
        baseUrl: 'https://example.com',
        itemSelector: 'json',
        titleSelector: 'title',
        linkSelector: 'link',
        isActive: true,
      );

      final jsonParser = JsonCrawlerParser();
      expect(jsonParser.canParse('{"title": "test"}', jsonConfig), isTrue);

      final htmlParser = HtmlCrawlerParser();
      expect(htmlParser.canParse('<div>test</div>', jsonConfig), isTrue);
    });
  });
}
