import 'dart:async';

import 'package:komorebi/src/core/services/server_media_api.dart';
import 'package:komorebi/src/features/dashboard/domain/media_models.dart';
import 'package:komorebi/src/features/profile/profile_management_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_providers.g.dart';

class EmptyCurrentProfileException implements Exception {
  @override
  String toString() {
    return 'No profile selected.';
  }
}

@riverpod
class DashboardAnimeNotifier extends _$DashboardAnimeNotifier {
  @override
  Future<MediaPage> build({
    AnimeStatusFilter? status = AnimeStatusFilter.watching,
  }) async {
    final currentProfile = ref.watch(currentProfileProvider);

    if (currentProfile.value == null || currentProfile.value?.id == null) {
      throw EmptyCurrentProfileException();
    }

    final profile = currentProfile.requireValue!;
    final serverApi = ref.watch(serverMediaApiProvider);

    return serverApi.getUserAnimeList(
      profileId: profile.id!,
      status: status?.apiValue,
    );
  }
}

@riverpod
class DashboardMangaNotifier extends _$DashboardMangaNotifier {
  @override
  Future<MediaPage> build(MangaStatusFilter? status) async {
    final currentProfile = ref.watch(currentProfileProvider);

    if (currentProfile.value == null || currentProfile.value?.id == null) {
      throw EmptyCurrentProfileException();
    }

    final profile = currentProfile.requireValue!;
    final serverApi = ref.watch(serverMediaApiProvider);

    return serverApi.getUserMangaList(
      profileId: profile.id!,
      status: status?.apiValue,
    );
  }
}
