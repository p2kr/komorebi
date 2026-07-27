import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:komorebi/src/models/api/crawler_config.dart';
import 'package:komorebi/src/providers/vault_providers.dart';
import 'package:komorebi/src/core/themes/theme.dart';
import 'package:komorebi/src/shared/widgets/chips.dart';
import 'package:quiver/strings.dart';

class ScrapingResultTile extends ConsumerWidget {
  final CrawlerResult crawlerResult;

  const ScrapingResultTile({super.key, required this.crawlerResult});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          alignment: .center,
          width: 50,
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: context.colorScheme.outlineVariant),
          ),
          child: AutoSizeText(badgeLabel ?? '?', maxLines: 2),
        ),
        title: Text(crawlerResult.title, maxLines: 3, overflow: .ellipsis),
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
          onPressed: () async {
            bool wasAdded = await ref
                .read(downloadQueueProvider.notifier)
                .addToQueue(crawlerResult);

            // Show snackbar for queuing download
            String? snackbarMessage;
            if (wasAdded) {
              snackbarMessage = getSnackbarMsg(crawlerResult);
            } else {
              snackbarMessage = "Item already in queue";
            }
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
            }
          },
          icon: Icon(Icons.save_alt_outlined, size: 18),
          label: SizedBox(
            width: 130,
            child: AutoSizeText.rich(
              TextSpan(
                text: "Download",
                children: downloadLabel != null
                    ? [
                        TextSpan(
                          text: "\n$downloadLabel",
                          style: context.textTheme.labelMedium?.copyWith(
                            color: context.colorScheme.onPrimary,
                          ),
                        ),
                      ]
                    : null,
              ),
              maxLines: 2,
            ),
          ),
        ),
      ),
    );
  }
}

String getSnackbarMsg(CrawlerResult res) {
  String? season = res.parsedTitle?.season?.firstOrNull;
  String? episode = res.parsedTitle?.episode?.firstOrNull;
  String title = res.parsedTitle?.title?.firstOrNull ?? res.title;

  String s = season == null ? "" : "S$season ";
  String e = episode == null ? "" : "E$episode ";

  return "Queued [$s$e$title] for download";
}

String? normalizeResolution(List<String>? resolutions) {
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

String? formatEpisodeSeasonBadge(CrawlerParsedTitle? parsed) {
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

String? formatSubtitles(CrawlerParsedTitle? parsed) {
  if (parsed?.subtitles == null || parsed!.subtitles!.isEmpty) return null;
  final joined = parsed.subtitles!.where((s) => isNotBlank(s)).join(', ');
  return joined.isEmpty ? null : joined;
}

String? formatLanguage(CrawlerParsedTitle? parsed) {
  if (parsed?.language == null || parsed!.language!.isEmpty) return null;
  final joined = parsed.language!.where((s) => isNotBlank(s)).join(', ');
  return joined.isEmpty ? null : joined;
}

String? formatDownloadButtonLabel({
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
  return null;
}
