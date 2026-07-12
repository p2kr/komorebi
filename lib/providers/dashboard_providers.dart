import 'dart:async';

import 'package:komorebi/models/mal_models.dart';
import 'package:komorebi/providers/profile_management_provider.dart';
import 'package:komorebi/utils/mal_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part "dashboard_providers.g.dart";

class EmptyCurrentProfileException implements Exception {
  @override
  String toString() {
    return "No profile selected.";
  }
}

@riverpod
class DashboardAnimeNotifier extends _$DashboardAnimeNotifier {
  @override
  Future<MalPaginated<MalAnimeListItem>> build({
    MalAnimeStatus? status = .watching,
  }) {
    final currentProfile = ref.watch(currentProfileProvider);

    if (currentProfile.value == null) {
      throw EmptyCurrentProfileException();
    }

    // fetch the currently [status] anime list from api
    final api = MalApi(defaultAccessToken: currentProfile.value!.accessToken);

    ref.onDispose(() {
      api.dispose();
    });

    return api.getUserAnimeList(
      username: currentProfile.requireValue!.username,
      status: status,
      fields: [
        "synopsis",
        "media_type",
        "my_list_status",
        "rating",
        "mean",
        "num_episodes",
        "popularity",
        "alternative_titles",
      ],
    );
  }
}

@riverpod
class DashboardMangaNotifier extends _$DashboardMangaNotifier {
  @override
  Future<MalPaginated<MalMangaListItem>> build(MalMangaStatus? status) {
    final currentProfile = ref.watch(currentProfileProvider);

    if (currentProfile.value == null) {
      throw (EmptyCurrentProfileException());
    }

    // fetch the currently [status] manga list from api
    final api = MalApi(defaultAccessToken: currentProfile.value!.accessToken);

    ref.onDispose(() {
      api.dispose();
    });

    return api.getUserMangaList(
      username: currentProfile.requireValue!.username,
      status: status,
    );
  }
}
