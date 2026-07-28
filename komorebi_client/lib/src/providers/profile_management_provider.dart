import 'package:komorebi/src/core/services/api/config_api_service.dart';
import 'package:komorebi/src/core/services/api/profile_api_service.dart';
import 'package:komorebi/src/core/utils/constants.dart';
import 'package:komorebi/src/core/utils/talker.dart';
import 'package:komorebi/src/models/profile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_management_provider.g.dart';

@Riverpod(keepAlive: true)
class CurrentProfileNotifier extends _$CurrentProfileNotifier {
  @override
  Future<Profile?> build() async {
    final api = ref.watch(profileApiServiceProvider);
    final configApi = ref.watch(configApiServiceProvider);

    final lastUsedProfileConfig = await configApi.getConfig(
      Settings.LAST_USED_PROFILE.name,
    );
    final configVal = lastUsedProfileConfig?.configValue;
    final configId = configVal != null ? int.tryParse(configVal) : null;

    if (configId != null) {
      final configuredProfile = await api.getProfile(configId);
      if (configuredProfile != null) {
        talker.debug("fetched last used profile from config: $configId");
        return configuredProfile;
      } else {
        talker.debug(
          "configured profile $configId is no longer available; falling back to latest profile",
        );
      }
    }

    final latestProfile = await api.getLatestProfile();
    if (latestProfile != null) {
      talker.debug("using latest profile as last used profile");
      await configApi.setConfig(
        Settings.LAST_USED_PROFILE.name,
        latestProfile.id.toString(),
      );
    } else if (configId != null) {
      await configApi.deleteConfig(Settings.LAST_USED_PROFILE.name);
    }
    return latestProfile;
  }

  /// Updates the current profile as [LAST_USED_PROFILE]
  Future<void> updateCurrentProfile(Profile newProfile) async {
    final configApi = ref.read(configApiServiceProvider);

    state = await AsyncValue.guard(() async {
      await configApi.setConfig(
        Settings.LAST_USED_PROFILE.name,
        newProfile.id.toString(),
      );
      talker.info(
        "Updated active profile to ${newProfile.username}[${newProfile.id}]",
      );
      return newProfile;
    });
  }
}

@riverpod
Future<List<Profile>> allProfiles(Ref ref) async {
  final api = ref.watch(profileApiServiceProvider);
  return await api.getAllProfiles();
}
