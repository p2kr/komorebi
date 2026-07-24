import 'package:flutter_test/flutter_test.dart';
import 'package:komorebi/models/api/crawler_config.dart';
import 'package:komorebi/services/title_parser_service.dart';

void main() {
  group('TitleParserService Tests', () {
    final service = TitleParserService.instance;

    setUp(() {
      service.type = TitleParserType.anitomy;
    });

    tearDown(() {
      service.clearCache();
    });

    test('locates anitomy executable path successfully', () {
      final exe = TitleParserService.executablePath;
      expect(exe, isNotNull);
      expect(exe!.contains('anitomy'), isTrue);
    });

    test('parses title using anitomy executable', () async {
      final parsed = await service.parseTitle(
        '[SubsPlease] One Piece - 1080 (1080p) [12345678].mkv',
      );
      expect(parsed, isNotNull);
      expect(parsed?.title, contains('One Piece'));
      expect(parsed?.releaseGroup, contains('SubsPlease'));
      expect(parsed?.fileExtension, contains('mkv'));
    });

    test('swaps parser type to regex', () async {
      service.type = TitleParserType.regex;
      final parsed = await service.parseTitle(
        '[SubsPlease] One Piece - 1080 (1080p).mkv',
      );
      expect(parsed, isNotNull);
      expect(parsed?.releaseGroup, contains('SubsPlease'));
      expect(parsed?.videoResolution, contains('1080p'));
    });

    test('swaps parser type to disabled', () async {
      service.type = TitleParserType.disabled;
      final parsed = await service.parseTitle(
        '[SubsPlease] One Piece - 1080 (1080p).mkv',
      );
      expect(parsed, isNull);
    });

    test('attaches parsed titles to CrawlerResult list', () async {
      service.type = TitleParserType.anitomy;
      const results = [
        CrawlerResult(
          title: '[SubsPlease] Bleach - 12 (1080p)',
          downloadUrl: 'https://example.com/bleach.torrent',
          source: 'nyaa',
        ),
      ];

      final updated = await service.parseAndAttach(results);
      expect(updated.length, equals(1));
      expect(updated.first.parsedTitle, isNotNull);
      expect(updated.first.parsedTitle?.title, contains('Bleach'));
    });
  });
}
