import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:komorebi/providers/common_providers.dart';
import 'package:komorebi/services/database.dart';
import 'package:komorebi/utils/constants.dart';
import 'package:komorebi/utils/talker.dart';

class CurrentProfileNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    // ref.keepAlive();

    final db = ref.watch(dbProvider);

    // check configs for [LAST_USED_PROFILE]. If present & valid, search in db, else fetch last created.
    final lastUsedProfileConfig = await db.configsDao.getConfig(
      Settings.LAST_USED_PROFILE.name,
    );
    final configId = lastUsedProfileConfig?.configValue != null
        ? int.tryParse(lastUsedProfileConfig!.configValue!)
        : null;

    if (configId != null) {
      final configuredProfile = await db.profilesDao.getProfile(configId);
      if (configuredProfile != null) {
        talker.info("fetched last used profile from config: $configId");
        return configuredProfile;
      } else {
        talker.info(
          "configured profile $configId is no longer available; falling back to latest profile",
        );
      }
    }

    talker.info("using latest profile as last used profile");
    final latestProfile = await db.profilesDao.getLatestProfile();
    if (latestProfile != null) {
      await db.configsDao.setConfig(
        Settings.LAST_USED_PROFILE.name,
        latestProfile.id.toString(),
      );
    }
    return latestProfile;
  }

  /// Updates the current profile as [LAST_USED_PROFILE]
  Future<void> updateCurrentProfile(Profile newProfile) async {
    final db = ref.read(dbProvider);
    await db.configsDao.setConfig(
      Settings.LAST_USED_PROFILE.name,
      newProfile.id.toString(),
    );
    ref.invalidateSelf();
  }
}

// PROVIDERS

final currentProfileProvider =
    AsyncNotifierProvider<CurrentProfileNotifier, Profile?>(
      CurrentProfileNotifier.new,
    );

final allProfilesProvider = StreamProvider<List<Profile>>((ref) {
  // ref.keepAlive();

  final db = ref.watch(dbProvider);

  if (kDebugMode) {
    ref.onResume(() {
      talker.debug("allProfilesProvider refreshed!");
      db.forceRefreshTable(db.profiles);
    });
  }

  return db.profilesDao.getAllProfiles();
});
