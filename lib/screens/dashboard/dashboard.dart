import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/models/mal_models.dart';
import 'package:komorebi/providers/dashboard_providers.dart';
import 'package:komorebi/screens/dashboard/anime_tile.dart';

enum MediaType { anime, manga }

class Dashboard extends HookConsumerWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);

    final statusMap = useMemoized(() => _getStatusMap(s), [s]);

    final animeOrManga = useState(MediaType.anime);

    // Make the state nullable so `null` can represent "All"
    final animeStatus = useState<MalAnimeStatus?>(null);
    final mangaStatus = useState<MalMangaStatus?>(null);

    final animeList = ref.watch(
      dashboardAnimeProvider(status: animeStatus.value),
    );
    // final mangaList = ref.watch(dashboardMangaProvider(mangaStatus.value));

    // fetch all currently watching animes/manga from api for current user
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter menu
          Wrap(
            spacing: 8,
            children: [
              DropdownMenu(
                selectOnly: true,
                initialSelection: animeOrManga.value,
                label: Text(s.mediaType),
                dropdownMenuEntries: [
                  DropdownMenuEntry(value: MediaType.anime, label: s.anime),
                  DropdownMenuEntry(
                    value: MediaType.manga,
                    label: s.manga,
                    enabled: false,
                    trailingIcon: Icon(Icons.construction_outlined),
                  ),
                ],
                onSelected: (value) {
                  if (value != null) {
                    animeOrManga.value = value;
                  }
                },
              ),

              // Anime Status
              animeOrManga.value == MediaType.anime
                  // Type the DropdownMenu as nullable
                  ? DropdownMenu<MalAnimeStatus?>(
                      selectOnly: true,
                      initialSelection: animeStatus.value,
                      label: Text(s.animeStatus),
                      dropdownMenuEntries: [
                        // Inject the "All" entry at the top with a null value
                        DropdownMenuEntry(
                          value: null,
                          label: statusMap['all']!,
                        ),
                        for (var status in MalAnimeStatus.values)
                          DropdownMenuEntry(
                            value: status,
                            label: statusMap[status.name]!,
                          ),
                      ],
                      onSelected: (value) {
                        animeStatus.value = value;
                      },
                    )
                  :
                    // Manga Status
                    DropdownMenu<MalMangaStatus?>(
                      initialSelection: mangaStatus.value,
                      label: Text(s.mangaStatus),
                      dropdownMenuEntries: [
                        DropdownMenuEntry(
                          value: null,
                          label: statusMap['all']!,
                        ),
                        for (var status in MalMangaStatus.values)
                          DropdownMenuEntry(
                            value: status,
                            label: statusMap[status.name]!,
                          ),
                      ],
                      onSelected: (value) {
                        mangaStatus.value = value;
                      },
                    ),
            ],
          ),

          Divider(),

          // Anime tiles
          Expanded(
            child: animeList.when(
              data: (animeItem) => GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 550,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  mainAxisExtent: 300, // Fixed height for tiles
                ),
                itemCount: animeItem.data.length,
                itemBuilder: (context, index) {
                  return AnimeTile(animeItem: animeItem.data[index]);
                },
              ),
              error: (e, t) => Center(
                child: TextButton.icon(
                  icon: Icon(Icons.refresh_outlined),
                  iconAlignment: .end,
                  onPressed: () {
                    ref.invalidate(
                      dashboardAnimeProvider(status: animeStatus.value),
                    );
                  },
                  label: Text(S.of(context).errorClickToRefresh(e.toString())),
                ),
              ),
              loading: () => Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, String> _getStatusMap(S s) => {
  "all": s.all,
  "watching": s.watching,
  "completed": s.completed,
  "onHold": s.onHold,
  "dropped": s.dropped,
  "planToWatch": s.planToWatch,
  "reading": s.reading,
  "planToRead": s.planToRead,
};
