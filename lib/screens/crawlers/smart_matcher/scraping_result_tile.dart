import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:komorebi/models/api/crawler_config.dart';
import 'package:komorebi/themes/theme.dart';
import 'package:komorebi/widgets/chips.dart';

class ScrapingResultTile extends StatelessWidget {
  final CrawlerResult crawlerResult;

  const ScrapingResultTile({super.key, required this.crawlerResult});

  static String? normalizeResolution(List<String>? resolutions) {
    if (resolutions == null || resolutions.isEmpty) return null;
    final combined = resolutions.join(' ').toLowerCase();

    if (combined.contains('2160') || combined.contains('4k')) return '4K';
    if (combined.contains('1080')) return '1080p';
    if (combined.contains('720')) return '720p';
    if (combined.contains('480')) return '480p';

    final first = resolutions.first.trim();
    if (first.length > 8) return null;
    return first.isEmpty ? null : first;
  }

  static String? formatEpisodeSeasonBadge(CrawlerParsedTitle? parsed) {
    if (parsed == null) return null;
    final season = (parsed.season != null && parsed.season!.isNotEmpty)
        ? parsed.season!.first
        : null;
    final episode = (parsed.episode != null && parsed.episode!.isNotEmpty)
        ? parsed.episode!.first
        : null;

    if (season != null && episode != null) {
      return 'S$season\nE$episode';
    }
    if (episode != null) {
      return 'EP\n$episode';
    }
    if (season != null) {
      return 'S$season';
    }
    return null;
  }

  static String? formatSubtitles(CrawlerParsedTitle? parsed) {
    if (parsed?.subtitles == null || parsed!.subtitles!.isEmpty) return null;
    final joined = parsed.subtitles!
        .where((s) => s.trim().isNotEmpty)
        .join(', ');
    return joined.isEmpty ? null : joined;
  }

  static String? formatLanguage(CrawlerParsedTitle? parsed) {
    if (parsed?.language == null || parsed!.language!.isEmpty) return null;
    final joined = parsed.language!
        .where((s) => s.trim().isNotEmpty)
        .join(', ');
    return joined.isEmpty ? null : joined;
  }

  static String formatDownloadButtonLabel({
    required String? resolution,
    required String? size,
  }) {
    final resText = resolution != null && resolution.isNotEmpty
        ? resolution
        : null;
    final sizeText = size != null && size.isNotEmpty ? size : null;

    if (resText != null && sizeText != null) {
      return '$resText \u00B7 $sizeText';
    }
    if (resText != null) {
      return resText;
    }
    if (sizeText != null) {
      return sizeText;
    }
    return 'Download';
  }

  @override
  Widget build(BuildContext context) {
    final resolution = normalizeResolution(
      crawlerResult.parsedTitle?.videoResolution,
    );
    final badgeLabel = formatEpisodeSeasonBadge(crawlerResult.parsedTitle);
    final subtitlesLabel = formatSubtitles(crawlerResult.parsedTitle);
    final languageLabel = formatLanguage(crawlerResult.parsedTitle);
    final downloadLabel = formatDownloadButtonLabel(
      resolution: resolution,
      size: crawlerResult.size,
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.colorScheme.surfaceBright),
      ),
      child: ListTile(
        // isThreeLine: true,
        titleAlignment: ListTileTitleAlignment.center,
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: context.colorScheme.outlineVariant),
          ),
          child: AutoSizeText(
            badgeLabel ?? 'N/A',
            // textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),
        title: Text(crawlerResult.title),
        subtitle: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            SimpleChip(label: crawlerResult.source),
            SimpleChip(
              label: crawlerResult.popularity % 1 == 0
                  ? crawlerResult.popularity.toInt().toString()
                  : crawlerResult.popularity.toString(),
              icon: Icons.person,
            ),
            if (languageLabel != null)
              SimpleChip(label: languageLabel, icon: Icons.language_outlined),
            if (subtitlesLabel != null)
              SimpleChip(label: subtitlesLabel, icon: Icons.subtitles_outlined),
          ],
        ),
        trailing: FilledButton.icon(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: VisualDensity.compact,
          ),
          onPressed: () {
            // TODO: Initiate download
          },
          icon: Icon(Icons.save_alt_outlined, size: 18),
          label: SizedBox(
            width: 130,
            child: AutoSizeText.rich(
              TextSpan(
                text: "Download\n",
                children: [
                  TextSpan(
                    text: downloadLabel,
                    //"$resolution \u00B7 ${crawlerResult.size}",
                    style: context.textTheme.labelMedium?.copyWith(
                      color: context.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
              maxLines: 2,
            ),
          ),
        ),
      ),
    );
  }
}
