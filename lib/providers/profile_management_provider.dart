import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:komorebi/providers/common_providers.dart';
import 'package:komorebi/services/database.dart';
import 'package:komorebi/utils/constants.dart';
import 'package:komorebi/utils/talker.dart';

class _CurrentProfileNotifier extends StreamNotifier<Profile> {
  @override
  Stream<Profile> build() async* {
    // ref.keepAlive();

    final db = ref.read(dbProvider);
    // check configs for [LAST_USED_PROFILE]. If present, search in db, else fetch last created.
    final lastUsedProfileId = await db.configsDao.getConfig(
      Settings.LAST_USED_PROFILE.name,
    );
    if (lastUsedProfileId != null && lastUsedProfileId.configValue != null) {
      talker.info("fetched last used profile from config");
      yield* db.profilesDao.watchProfile(
        int.parse(lastUsedProfileId.configValue!),
      );
    } else {
      talker.info("using latest profile as last used profile");
      yield* db.profilesDao.watchLatestProfile();
    }
  }

  void updateCurrentProfile(Profile newProfile) {
    // Update the current profile in the database and return the updated profile
    final db = ref.read(dbProvider);
    db.configsDao.setConfig(
      Settings.LAST_USED_PROFILE.name,
      newProfile.id.toString(),
    );
  }
}

class AllProfilesNotifier extends StreamNotifier<List<Profile>> {
  @override
  Stream<List<Profile>> build() async* {
    final db = ref.read(dbProvider);
    yield* db.profilesDao.watchProfiles();
  }
}

// PROVIDERS

final currentProfileProvider = StreamNotifierProvider(
  _CurrentProfileNotifier.new,
);

final allProfilesProvider = StreamNotifierProvider(AllProfilesNotifier.new);
