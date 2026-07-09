import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:komorebi/models/profiles_table.dart';
import 'package:komorebi/providers/common_providers.dart';
import 'package:komorebi/services/database.dart';
import 'package:komorebi/utils/constants.dart';
import 'package:komorebi/utils/talker.dart';

class CurrentProfileNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    ref.keepAlive();

    final db = ref.watch(dbProvider);

    // check configs for [LAST_USED_PROFILE]. If present & valid, search in db, else fetch last created.
    final lastUsedProfileConfig = await db.configsDao.getConfig(
      Settings.LAST_USED_PROFILE.name,
    );
    final configVal = lastUsedProfileConfig?.configValue;
    final configId = configVal != null ? int.tryParse(configVal) : null;

    if (configId != null) {
      final configuredProfile = await db.profilesDao.getProfile(configId);
      if (configuredProfile != null) {
        talker.debug("fetched last used profile from config: $configId");
        return configuredProfile;
      } else {
        talker.debug(
          "configured profile $configId is no longer available; falling back to latest profile",
        );
      }
    }

    final latestProfile = await db.profilesDao.getLatestProfile();
    if (latestProfile != null) {
      talker.debug("using latest profile as last used profile");
      await db.configsDao.setConfig(
        Settings.LAST_USED_PROFILE.name,
        latestProfile.id.toString(),
      );
    } else if (configId != null) {
      await db.configsDao.deleteConfig(Settings.LAST_USED_PROFILE.name);
    }
    return latestProfile;
  }

  /// Updates the current profile as [LAST_USED_PROFILE]
  Future<void> updateCurrentProfile(Profile newProfile) async {
    final db = ref.read(dbProvider);

    state = await AsyncValue.guard(() async {
      await db.configsDao.setConfig(
        Settings.LAST_USED_PROFILE.name,
        newProfile.id.toString(),
      );
      talker.info(
        "Updated active profile to ${newProfile.username}[${newProfile.id}]",
      );
      return newProfile;
    });
    // ref.invalidateSelf(); // not required since we are directly watching db
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
      db.forceRefreshTable(db.profiles);
    });
  }

  return db.profilesDao.getAllProfiles();
});
