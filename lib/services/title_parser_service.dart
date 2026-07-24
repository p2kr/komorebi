import 'dart:convert';
import 'dart:io';

import 'package:komorebi/models/api/crawler_config.dart';
import 'package:komorebi/utils/talker.dart';
import 'package:path/path.dart' as path;
import 'package:quiver/collection.dart';

/// Supported title parser types.
enum TitleParserType { anitomy, regex, disabled }

/// Simplified Title Parser Service supporting configurable parser strategy and LRU caching.
class TitleParserService {
  static const int defaultCacheCapacity = 500;
  static const String jsonFormatFlag = '--format=json';

  static final TitleParserService instance = TitleParserService._();

  TitleParserService._() : _cache = LruMap(maximumSize: defaultCacheCapacity);

  TitleParserType type = TitleParserType.anitomy;
  final LruMap<String, CrawlerParsedTitle?> _cache;
  static String? _resolvedExePath;

  static String? get executablePath {
    if (_resolvedExePath != null && File(_resolvedExePath!).existsSync()) {
      return _resolvedExePath;
    }
    final candidateSubpaths = [
      path.join('assets', 'bin', 'anitomy-win.exe'),
      path.join(Directory.current.path, 'assets', 'bin', 'anitomy-win.exe'),
      path.join('assets', 'bin', 'anitomy.exe'),
      path.join('assets', 'bin', 'anitomy'),
      path.join('bin', 'anitomy-win.exe'),
      path.join('bin', 'anitomy.exe'),
      path.join('bin', 'anitomy'),
    ];
    for (final candidate in candidateSubpaths) {
      if (File(candidate).existsSync()) {
        _resolvedExePath = candidate;
        return candidate;
      }
    }
    return null;
  }

  /// Parses a raw title string using the active parser strategy with LRU caching.
  Future<CrawlerParsedTitle?> parseTitle(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty || type == TitleParserType.disabled) return null;

    if (_cache.containsKey(trimmed)) return _cache[trimmed];

    CrawlerParsedTitle? parsed;
    if (type == TitleParserType.anitomy) {
      parsed = await parseWithAnitomy(trimmed, executablePath);
    } else if (type == TitleParserType.regex) {
      parsed = parseWithRegex(trimmed);
    }

    _cache[trimmed] = parsed;
    return parsed;
  }

  /// Executes native Anitomy CLI tool for title parsing.
  static Future<CrawlerParsedTitle?> parseWithAnitomy(
    String title,
    String? exePath,
  ) async {
    if (exePath == null) {
      talker.warning("Anitomy executable not found in bin directory.");
      return null;
    }
    try {
      final result = await Process.run(exePath, [jsonFormatFlag, title]);
      if (result.exitCode == 0 && result.stdout.toString().isNotEmpty) {
        return CrawlerParsedTitle.fromJson(
          jsonDecode(result.stdout.toString()),
        );
      }
    } catch (e, st) {
      talker.error("Failed to run Anitomy executable", e, st);
    }
    return null;
  }

  /// Fallback regex title parsing logic.
  static CrawlerParsedTitle? parseWithRegex(String title) {
    final group = RegExp(r'^\[([^\]]+)\]').firstMatch(title)?.group(1);
    final season = RegExp(
      r'\b(?:S|Season)\s*0*(\d+)\b',
      caseSensitive: false,
    ).firstMatch(title)?.group(1);
    final ep = RegExp(
      r'\b(?:E|Episode|Ep|-)\s*0*(\d{1,4})\b',
      caseSensitive: false,
    ).firstMatch(title)?.group(1);
    final res = RegExp(
      r'\b(2160p|1080p|720p|480p|4k)\b',
      caseSensitive: false,
    ).firstMatch(title)?.group(1);

    final clean = title
        .replaceAll(RegExp(r'^\[[^\]]+\]\s*'), '')
        .replaceAll(RegExp(r'\([^)]+\)'), '')
        .replaceAll(RegExp(r'\[[^\]]+\]'), '')
        .replaceAll(
          RegExp(r'\b(?:S|Season)\s*0*\d+\b', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'\b(?:E|Episode|Ep)\s*0*\d+\b', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return CrawlerParsedTitle(
      title: clean.isNotEmpty ? [clean] : null,
      releaseGroup: group != null ? [group] : null,
      season: season != null ? [season] : null,
      episode: ep != null ? [ep] : null,
      videoResolution: res != null ? [res] : null,
    );
  }

  /// Parses titles for a list of [CrawlerResult] items and returns updated results.
  Future<List<CrawlerResult>> parseAndAttach(
    List<CrawlerResult> results,
  ) async {
    final updated = <CrawlerResult>[];
    for (final res in results) {
      if (res.parsedTitle != null) {
        updated.add(res);
      } else {
        final parsed = await parseTitle(res.title);
        updated.add(res.copyWith(parsedTitle: parsed));
      }
    }
    return updated;
  }

  void clearCache() => _cache.clear();
}
