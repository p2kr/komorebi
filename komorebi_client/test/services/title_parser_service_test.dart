import 'package:flutter_test/flutter_test.dart';
import 'package:komorebi/src/core/services/title_parser_service.dart';

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

    test('parses title successfully for item', () async {
      service.type = TitleParserType.regex;
      final parsed = await service.parseTitle(
        '[SubsPlease] Bleach - 12 (1080p)',
      );
      expect(parsed, isNotNull);
      expect(parsed?.releaseGroup, contains('SubsPlease'));
    });
  });
}
