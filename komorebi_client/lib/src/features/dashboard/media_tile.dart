import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/src/core/providers/common_providers.dart';
import 'package:komorebi/src/core/themes/theme.dart';
import 'package:komorebi/src/features/dashboard/domain/media_models.dart';
import 'package:komorebi/src/features/dashboard/overflowing_list.dart';
import 'package:komorebi/src/features/dashboard/synopsis_widget.dart';
import 'package:komorebi/src/shared/widgets/chips.dart';
import 'package:quiver/strings.dart';

class MediaTile extends ConsumerWidget {
  const MediaTile({super.key, required this.mediaItem});

  final MediaItem mediaItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swapTitles = ref.watch(swapAlternateTitleProvider);

    final titleRomanizedOrUser = isNotBlank(mediaItem.title.userPreferred)
        ? mediaItem.title.userPreferred!
        : (mediaItem.title.romanized ?? '');
    final titleEnglish = mediaItem.title.english;

    final displayTitle = swapTitles && isNotBlank(titleEnglish)
        ? titleEnglish!
        : titleRomanizedOrUser;

    final displayAltTitle = swapTitles
        ? titleRomanizedOrUser
        : (isBlank(titleEnglish) ? titleRomanizedOrUser : titleEnglish!);

    final leadingImg =
        mediaItem.coverImage.medium ?? mediaItem.coverImage.large;
    final synopsis = mediaItem.synopsis;
    final format = mediaItem.format;
    final episodesWatched = mediaItem.listStatus?.progress;
    final totalEpisodes = mediaItem.episodes;
    final popularity = mediaItem.popularity;
    final meanRating = mediaItem.meanScore;
    final genres = mediaItem.genres;
    final nextEpisode = getNextEpisodeNumber(episodesWatched, totalEpisodes);

    return Card(
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Row(
              spacing: 4,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isNotBlank(leadingImg))
                  CachedNetworkImage(
                    width: 100,
                    fit: BoxFit.cover,
                    imageUrl: leadingImg!,
                    placeholder: (context, url) => const Placeholder(),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Column(
                      spacing: 4,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // STATISTICS
                        OverflowingStatisticsList(
                          statistics: [
                            if (isNotBlank(format))
                              SimpleChip(label: format!.toUpperCase()),
                            if (meanRating != null)
                              SimpleChip(
                                label: meanRating.toString(),
                                icon: Icons.star,
                              ),
                            if (popularity != null)
                              SimpleChip(
                                label: popularity.toString(),
                                icon: Icons.trending_up,
                              ),
                          ],
                        ),

                        // TITLE
                        Text(
                          displayTitle,
                          maxLines: 2,
                          style: context.textTheme.bodyLarge?.copyWith(
                            fontFamily: context.fontSerif,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Alternate title
                        if (isNotBlank(displayAltTitle) &&
                            displayAltTitle != displayTitle)
                          Row(
                            spacing: 4,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.transcribe_outlined,
                                size: context.textTheme.bodyMedium?.fontSize,
                              ),
                              Expanded(
                                child: Text(
                                  displayAltTitle,
                                  maxLines: 2,
                                  style: context.textTheme.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                        if (genres.isNotEmpty)
                          OverflowingGenreList(genres: genres),

                        const Spacer(),

                        // Progress bar
                        DefaultTextStyle(
                          style: context.textTheme.labelSmall!,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(S.of(context).progress),
                              Text(
                                '${episodesWatched ?? '?'} / ${totalEpisodes ?? '?'}',
                              ),
                            ],
                          ),
                        ),
                        LinearProgressIndicator(
                          value:
                              episodesWatched != null &&
                                  totalEpisodes != null &&
                                  totalEpisodes > 0
                              ? episodesWatched / totalEpisodes
                              : 0,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 8),
          SynopsisWidget(text: synopsis),
          const Divider(height: 8),

          // Buttons
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              spacing: 4,
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.download_sharp),
                    onPressed: () {
                      // TODO: Download the episode.
                    },
                    label: AutoSizeText(
                      S.of(context).getEpisode(nextEpisode),
                      maxLines: 1,
                      overflowReplacement: AutoSizeText(
                        S.of(context).epShort(nextEpisode),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.manage_search_outlined),
                    onPressed: () {
                      // TODO: Navigate to Smart Matcher
                    },
                    label: AutoSizeText(
                      S.of(context).crawlerOptions,
                      maxLines: 1,
                      overflowReplacement: AutoSizeText(S.of(context).options),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

int getNextEpisodeNumber(int? episodesWatched, int? totalEpisodes) =>
    episodesWatched != null
    ? (totalEpisodes != null
          ? min(episodesWatched + 1, totalEpisodes)
          : episodesWatched + 1)
    : 1;
