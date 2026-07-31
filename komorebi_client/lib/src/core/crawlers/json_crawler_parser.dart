import 'dart:convert';

import 'package:komorebi/src/core/crawlers/crawler_parser.dart';
import 'package:komorebi/src/features/crawlers/crawler_config.dart';
import 'package:quiver/strings.dart';

class JsonCrawlerParser implements CrawlerParser {
  @override
  bool canParse(String content, CrawlerConfig config) {
    if (isBlank(content)) return false;
    if (config.itemSelector.toLowerCase() == CrawlerParserUtils.jsonSelector) {
      return true;
    }
    try {
      final decoded = json.decode(content.trim());
      return decoded is Map || decoded is List;
    } catch (_) {
      return false;
    }
  }

  @override
  List<CrawlerResult> parse({
    required String content,
    required CrawlerConfig config,
  }) {
    try {
      final decoded = json.decode(content.trim());
      final List<CrawlerResult> results = [];
      final List<MapEntry<String?, dynamic>> itemsToProcess = [];

      if (decoded is List) {
        for (var item in decoded) {
          itemsToProcess.add(MapEntry(null, item));
        }
      } else if (decoded is Map<String, dynamic>) {
        final customItemPath =
            config.itemSelector.toLowerCase() != CrawlerParserUtils.jsonSelector
            ? config.itemSelector
            : null;
        final listInMap = customItemPath != null
            ? CrawlerParserUtils.getValueByPath(decoded, customItemPath)
            : CrawlerParserUtils.getFirstValueByPathList(
                decoded,
                CrawlerParserUtils.defaultItemListKeys,
              );

        if (listInMap is List) {
          for (var item in listInMap) {
            itemsToProcess.add(MapEntry(null, item));
          }
        } else {
          for (final entry in decoded.entries) {
            itemsToProcess.add(MapEntry(entry.key, entry.value));
          }
        }
      }

      final titleCandidateKeys = [
        if (config.titleSelector.isNotEmpty) config.titleSelector,
        ...CrawlerParserUtils.defaultTitleKeys,
      ];

      final downloadCandidateKeys = [
        if (config.linkSelector.isNotEmpty) config.linkSelector,
        ...CrawlerParserUtils.defaultDownloadUrlKeys,
      ];

      final sizeCandidateKeys = [
        if (config.sizeSelector != null && config.sizeSelector!.isNotEmpty)
          config.sizeSelector!,
        ...CrawlerParserUtils.defaultSizeKeys,
      ];

      final popularityCandidateKeys = [
        if (config.popularitySelector != null &&
            config.popularitySelector!.isNotEmpty)
          config.popularitySelector!,
        ...CrawlerParserUtils.defaultPopularityKeys,
      ];

      for (final entry in itemsToProcess) {
        final itemKey = entry.key;
        final itemData = entry.value;
        if (itemData is! Map) continue;

        final itemMap = itemData as Map<String, dynamic>;

        String rawTitle = CrawlerParserUtils.extractString(
          itemMap,
          titleCandidateKeys,
        );

        if (rawTitle.isEmpty && itemKey != null) {
          rawTitle = itemKey;
        } else if (itemKey != null && itemKey.length > rawTitle.length) {
          rawTitle = itemKey;
        }

        String baseTitle = CrawlerParserUtils.cleanString(rawTitle);

        final linkSelectorVal = config.linkSelector.isNotEmpty
            ? CrawlerParserUtils.getValueByPath(itemMap, config.linkSelector)
            : null;

        final downloadsList = linkSelectorVal is List
            ? linkSelectorVal
            : CrawlerParserUtils.getFirstValueByPathList(
                itemMap,
                CrawlerParserUtils.defaultDownloadListKeys,
              );

        if (downloadsList is List) {
          for (final download in downloadsList) {
            if (download is Map<String, dynamic>) {
              final res = CrawlerParserUtils.extractString(
                download,
                CrawlerParserUtils.defaultResolutionKeys,
              );
              final magnet = CrawlerParserUtils.extractString(
                download,
                downloadCandidateKeys,
              );
              final rawSize = CrawlerParserUtils.extractString(
                download,
                sizeCandidateKeys,
              );
              final size = rawSize.isNotEmpty ? rawSize : null;
              final popVal = CrawlerParserUtils.parsePopularity(
                CrawlerParserUtils.extractString(
                  download,
                  popularityCandidateKeys,
                ),
              );

              if (magnet.isNotEmpty) {
                final resTag =
                    (res.isNotEmpty &&
                        !baseTitle.toLowerCase().contains(res.toLowerCase()))
                    ? ' (${res.endsWith('p') ? res : '${res}p'})'
                    : '';
                results.add(
                  CrawlerResult(
                    title: '$baseTitle$resTag',
                    link: magnet,
                    source: config.id,
                    popularity: popVal ?? 0.0,
                    size: size,
                  ),
                );
              }
            }
          }
        } else {
          final downloadUrl = CrawlerParserUtils.extractString(
            itemMap,
            downloadCandidateKeys,
          );
          final rawSize = CrawlerParserUtils.extractString(
            itemMap,
            sizeCandidateKeys,
          );
          final size = rawSize.isNotEmpty ? rawSize : null;
          final popVal = CrawlerParserUtils.parsePopularity(
            CrawlerParserUtils.extractString(itemMap, popularityCandidateKeys),
          );

          if (baseTitle.isNotEmpty || downloadUrl.isNotEmpty) {
            results.add(
              CrawlerResult(
                title: baseTitle,
                link: downloadUrl,
                source: config.id,
                popularity: popVal ?? 0.0,
                size: size,
              ),
            );
          }
        }
      }

      return results;
    } catch (_) {
      return [];
    }
  }
}
