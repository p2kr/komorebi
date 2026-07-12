import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:komorebi/models/mal_models.dart';
import 'package:komorebi/providers/dashboard_providers.dart';
import 'package:komorebi/screens/dashboard/anime_tile.dart';

enum MediaType { anime, manga }

class Dashboard extends HookConsumerWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                initialSelection: animeOrManga.value,
                label: const Text("Media type"),
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: MediaType.anime, label: "Anime"),
                  DropdownMenuEntry(
                    value: MediaType.manga,
                    label: "Manga",
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
                      initialSelection: animeStatus.value,
                      label: const Text("Anime Status"),
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
                      label: const Text("Manga Status"),
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
                  label: Text("Error: $e. [Click to Refresh]"),
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

const statusMap = {
  "all": "All",
  "watching": "Watching",
  "completed": "Completed",
  "onHold": "On Hold",
  "dropped": "Dropped",
  "planToWatch": "Plan to Watch",
  "reading": "Reading",
  "planToRead": "Plan to Read",
};
