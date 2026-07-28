import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komorebi/src/core/providers/common_providers.dart';
import 'package:komorebi/src/core/services/api/config_api_service.dart';
import 'package:komorebi/src/core/services/api/profile_api_service.dart';
import 'package:komorebi/src/core/services/database.dart';
import 'package:komorebi/src/core/utils/constants.dart';
import 'package:komorebi/src/features/profile/profile.dart';
import 'package:komorebi/src/features/profile/profile_management_provider.dart';
import 'package:komorebi/src/features/settings/app_config.dart';

import '../fakes/fake_profile_api_service.dart';

class FakeConfigApiService implements ConfigApiService {
  final Map<String, String> configs = {};

  @override
  Dio get dio => throw UnimplementedError();

  @override
  Future<AppConfig?> getConfig(String key) async {
    if (!configs.containsKey(key)) return null;
    return AppConfig(id: 1, configKey: key, configValue: configs[key]);
  }

  @override
  Future<AppConfig> setConfig(String key, String value) async {
    configs[key] = value;
    return AppConfig(id: 1, configKey: key, configValue: value);
  }

  @override
  Future<void> deleteConfig(String key) async {
    configs.remove(key);
  }

  @override
  Future<List<AppConfig>> getAllConfigs() async {
    return configs.entries
        .map((e) => AppConfig(id: 1, configKey: e.key, configValue: e.value))
        .toList();
  }
}

void main() {
  late AppDatabase db;
  late FakeProfileApiService fakeApi;
  late FakeConfigApiService fakeConfigApi;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    fakeApi = FakeProfileApiService();
    fakeConfigApi = FakeConfigApiService();
    container = ProviderContainer(
      overrides: [
        dbProvider.overrideWithValue(db),
        profileApiServiceProvider.overrideWithValue(fakeApi),
        configApiServiceProvider.overrideWithValue(fakeConfigApi),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('CurrentProfileNotifier Tests', () {
    test(
      'given empty profiles when currentProfileProvider read then returns null',
      () async {
        final profile = await container.read(currentProfileProvider.future);
        expect(profile, isNull);
      },
    );

    test(
      'given profiles without config when currentProfileProvider read then returns latest profile and sets LAST_USED_PROFILE config',
      () async {
        fakeApi.profiles.addAll([
          Profile(
            id: 1,
            username: 'User1',
            syncType: SyncType.sandbox,
            createdAt: DateTime(2025, 1, 1),
          ),
          Profile(
            id: 2,
            username: 'User2',
            syncType: SyncType.mal,
            createdAt: DateTime(2026, 1, 1),
          ),
        ]);

        final profile = await container.read(currentProfileProvider.future);
        final configVal = await fakeConfigApi.getConfig(
          Settings.LAST_USED_PROFILE.name,
        );

        expect(profile, isNotNull);
        expect(profile!.id, equals(2));
        expect(profile.username, equals('User2'));
        expect(configVal?.configValue, equals('2'));
      },
    );

    test(
      'given LAST_USED_PROFILE config when currentProfileProvider read then returns configured profile',
      () async {
        fakeApi.profiles.addAll([
          Profile(
            id: 1,
            username: 'ConfiguredUser',
            syncType: SyncType.sandbox,
            createdAt: DateTime(2025, 1, 1),
          ),
          Profile(
            id: 2,
            username: 'NewerUser',
            syncType: SyncType.mal,
            createdAt: DateTime(2026, 1, 1),
          ),
        ]);
        await fakeConfigApi.setConfig(Settings.LAST_USED_PROFILE.name, '1');

        final profile = await container.read(currentProfileProvider.future);

        expect(profile, isNotNull);
        expect(profile!.id, equals(1));
        expect(profile.username, equals('ConfiguredUser'));
      },
    );

    test(
      'given invalid LAST_USED_PROFILE config when currentProfileProvider read then falls back to latest profile',
      () async {
        fakeApi.profiles.add(
          Profile(
            id: 1,
            username: 'FallbackUser',
            syncType: SyncType.sandbox,
            createdAt: DateTime(2025, 1, 1),
          ),
        );
        await fakeConfigApi.setConfig(Settings.LAST_USED_PROFILE.name, '9999');

        final profile = await container.read(currentProfileProvider.future);

        expect(profile, isNotNull);
        expect(profile!.id, equals(1));
        expect(profile.username, equals('FallbackUser'));
      },
    );

    test(
      'given new profile when updateCurrentProfile called then updates state and saves config in DB',
      () async {
        final profile1 = Profile(
          id: 1,
          username: 'InitialUser',
          syncType: SyncType.sandbox,
          createdAt: DateTime(2025, 1, 1),
        );
        final profile2 = Profile(
          id: 2,
          username: 'NewActiveUser',
          syncType: SyncType.mal,
          createdAt: DateTime(2026, 1, 1),
        );
        fakeApi.profiles.addAll([profile1, profile2]);
        await container.read(currentProfileProvider.future);

        await container
            .read(currentProfileProvider.notifier)
            .updateCurrentProfile(profile2);
        final state = container.read(currentProfileProvider);
        final configVal = await fakeConfigApi.getConfig(
          Settings.LAST_USED_PROFILE.name,
        );

        expect(state.value?.id, equals(2));
        expect(state.value?.username, equals('NewActiveUser'));
        expect(configVal?.configValue, equals('2'));
      },
    );
  });

  group('allProfilesProvider Tests', () {
    test(
      'given multiple profiles when allProfilesProvider read then returns all profiles',
      () async {
        fakeApi.profiles.addAll([
          Profile(
            id: 1,
            username: 'Alpha',
            syncType: SyncType.sandbox,
            createdAt: DateTime.now(),
          ),
          Profile(
            id: 2,
            username: 'Beta',
            syncType: SyncType.mal,
            createdAt: DateTime.now(),
          ),
        ]);

        final profiles = await container.read(allProfilesProvider.future);

        expect(profiles.length, equals(2));
        expect(profiles.map((p) => p.username), containsAll(['Alpha', 'Beta']));
      },
    );
  });
}
