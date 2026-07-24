import 'package:komorebi/models/api/crawler_config.dart';

abstract class CrawlerParser {
  bool canParse(String content, CrawlerConfig config);

  List<CrawlerResult> parse({
    required String content,
    required CrawlerConfig config,
  });
}

abstract class CrawlerParserUtils {
  static const String jsonSelector = 'json';
  static const String hrefAttr = 'href';
  static const String urlAttr = 'url';
  static const String magnetPrefix = 'magnet:';
  static const String httpPrefix = 'http://';
  static const String httpsPrefix = 'https://';

  static const List<String> defaultItemListKeys = ['items', 'results', 'data'];
  static const List<String> defaultTitleKeys = ['title', 'name', 'show'];
  static const List<String> defaultDownloadListKeys = ['downloads', 'links'];
  static const List<String> defaultResolutionKeys = [
    'res',
    'resolution',
    'quality',
  ];
  static const List<String> defaultDownloadUrlKeys = [
    'magnet',
    'download_url',
    'url',
    'link',
    'download',
    'href',
  ];
  static const List<String> defaultSizeKeys = ['size', 'filesize', 'file_size'];
  static const List<String> defaultPopularityKeys = [
    'seeders',
    'popularity',
    'seeds',
  ];

  static String cleanString(String? val) {
    if (val == null) return '';
    return val.replaceAll('\u00a0', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static double? parsePopularity(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final cleaned = raw.replaceAll('\u00a0', ' ').replaceAll(',', '').trim();
    final match = RegExp(r'[-+]?\d+(?:\.\d+)?\s*[kK]?').firstMatch(cleaned);
    if (match != null) {
      final str = match.group(0)!.trim();
      if (str.toLowerCase().endsWith('k')) {
        final numPart = str.substring(0, str.length - 1).trim();
        final val = double.tryParse(numPart);
        if (val != null) return val * 1000;
      }
      return double.tryParse(str);
    }
    return null;
  }

  static dynamic getValueByPath(dynamic data, String? path) {
    if (path == null || path.isEmpty || data == null) return null;
    if (data is Map && data.containsKey(path)) return data[path];

    final parts = path.split('.');
    dynamic curr = data;
    for (final part in parts) {
      if (curr is Map && curr.containsKey(part)) {
        curr = curr[part];
      } else {
        return null;
      }
    }
    return curr;
  }

  static dynamic getFirstValueByPathList(dynamic data, List<String> paths) {
    for (final path in paths) {
      final val = getValueByPath(data, path);
      if (val != null) return val;
    }
    return null;
  }

  static String extractString(dynamic obj, List<String> candidateKeys) {
    if (obj is Map) {
      for (final key in candidateKeys) {
        final val = getValueByPath(obj, key);
        if (val != null && val.toString().trim().isNotEmpty) {
          return val.toString().trim();
        }
      }
    } else if (obj != null) {
      return obj.toString().trim();
    }
    return '';
  }
}
