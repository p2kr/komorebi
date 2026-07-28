import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/src/features/dashboard/dashboard_providers.dart';
import 'package:komorebi/src/features/dashboard/domain/media_models.dart';
import 'package:komorebi/src/features/dashboard/media_tile.dart';
import 'package:komorebi/src/features/profile/profile_management_provider.dart';

enum MediaType { anime, manga }

class Dashboard extends HookConsumerWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);

    final statusMap = useMemoized(() => _getStatusMap(s), [s]);

    final animeOrManga = useState(MediaType.anime);

    // Make the state nullable so `null` can represent "All"
    final animeStatus = useState<AnimeStatusFilter?>(null);
    final mangaStatus = useState<MangaStatusFilter?>(null);

    final currentProfile = ref.watch(currentProfileProvider);

    if (currentProfile.isLoading && !currentProfile.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentProfile.value == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              s.noActiveProfile,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    final animeList = ref.watch(
      dashboardAnimeProvider(status: animeStatus.value),
    );

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
                    trailingIcon: const Icon(Icons.construction_outlined),
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
                  ? DropdownMenu<AnimeStatusFilter?>(
                      selectOnly: true,
                      initialSelection: animeStatus.value,
                      label: Text(s.animeStatus),
                      dropdownMenuEntries: [
                        DropdownMenuEntry(
                          value: null,
                          label: statusMap['all']!,
                        ),
                        for (var status in AnimeStatusFilter.values)
                          DropdownMenuEntry(
                            value: status,
                            label: statusMap[status.name]!,
                          ),
                      ],
                      onSelected: (value) {
                        animeStatus.value = value;
                      },
                    )
                  : DropdownMenu<MangaStatusFilter?>(
                      initialSelection: mangaStatus.value,
                      label: Text(s.mangaStatus),
                      dropdownMenuEntries: [
                        DropdownMenuEntry(
                          value: null,
                          label: statusMap['all']!,
                        ),
                        for (var status in MangaStatusFilter.values)
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

          const Divider(),

          // Media tiles
          Expanded(
            child: animeList.when(
              data: (animeItem) => GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 550,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  mainAxisExtent: 300,
                ),
                itemCount: animeItem.data.length,
                itemBuilder: (context, index) {
                  return MediaTile(mediaItem: animeItem.data[index]);
                },
              ),
              error: (e, t) => Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.refresh_outlined),
                  iconAlignment: IconAlignment.end,
                  onPressed: () {
                    ref.invalidate(
                      dashboardAnimeProvider(status: animeStatus.value),
                    );
                  },
                  label: Text(S.of(context).errorClickToRefresh(e.toString())),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, String> _getStatusMap(S s) => {
  'all': s.all,
  'watching': s.watching,
  'completed': s.completed,
  'onHold': s.onHold,
  'dropped': s.dropped,
  'planToWatch': s.planToWatch,
  'reading': s.reading,
  'planToRead': s.planToRead,
};
