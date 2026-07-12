import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:komorebi/models/mal_models.dart';
import 'package:komorebi/screens/dashboard/overflowing_list.dart';
import 'package:komorebi/screens/dashboard/synopsis_widget.dart';
import 'package:komorebi/themes/theme.dart';
import 'package:komorebi/widgets/chips.dart';

class AnimeTile extends StatelessWidget {
  const AnimeTile({super.key, required this.animeItem});

  final MalAnimeListItem animeItem;

  @override
  Widget build(BuildContext context) {
    final title = animeItem.node.title;
    final leadingImg = animeItem.node.mainPicture?.medium;
    final synopsis = animeItem.node.synopsis;
    final mediaType = animeItem.node.mediaType;
    final episodesWatched = animeItem.node.myListStatus?.numEpisodesWatched;
    final totalEpisodes = animeItem.node.numEpisodes;
    final popularity = animeItem.node.popularity;
    final meanRating = animeItem.node.mean;
    final contentRating = animeItem.node.rating?.toUpperCase();
    final alternateTitle = animeItem.node.alternativeTitles;
    final genres = animeItem.node.genres;

    return Card(
      // elevation: 2,
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Row(
              spacing: 4,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (leadingImg != null)
                  CachedNetworkImage(
                    width: 100,
                    fit: BoxFit.cover,
                    imageUrl: leadingImg,
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
                            if (mediaType != null)
                              SimpleChip(label: mediaType.toUpperCase()),
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
                            if (contentRating != null)
                              SimpleChip(
                                label: contentRating.toString(),
                                icon: Icons.numbers,
                              ),
                          ],
                        ),

                        // TITLE
                        Text(
                          title,
                          maxLines: 2,
                          style: context.textTheme.bodyLarge?.copyWith(
                            fontFamily:
                                context.textTheme.headlineSmall?.fontFamily,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Alternate title
                        if (alternateTitle?.en != null)
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
                                  alternateTitle!.en!.isEmpty
                                      ? title
                                      : alternateTitle.en!,
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
                              const Text("PROGRESS"),
                              Text(
                                "${episodesWatched ?? "?"} / ${totalEpisodes ?? "?"}",
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FilledButton.icon(
                  icon: Icon(Icons.download_sharp),
                  onPressed: () {},
                  label: Text(
                    "Get Episode ${getNextEpisodeNumber(episodesWatched, totalEpisodes)}",
                  ),
                ),
                OutlinedButton.icon(
                  icon: Icon(Icons.manage_search_outlined),
                  onPressed: () {},
                  label: Text("Crawler Options"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

int getNextEpisodeNumber(int? episodesWatched, int? totalEpisodes) {
  if (episodesWatched != null) {
    if (totalEpisodes != null) {
      return min(episodesWatched + 1, totalEpisodes);
    } else {
      return episodesWatched + 1;
    }
  }
  return 1;
}
