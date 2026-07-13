import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komorebi/models/db/profiles_table.dart';
import 'package:komorebi/providers/common_providers.dart';
import 'package:komorebi/providers/profile_management_provider.dart';
import 'package:komorebi/services/database.dart';
import 'package:komorebi/utils/constants.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [dbProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('CurrentProfileNotifier Tests', () {
    test(
      'given empty DB when currentProfileProvider read then returns null',
      () async {
        // Given empty DB

        // When
        final profile = await container.read(currentProfileProvider.future);

        // Then
        expect(profile, isNull);
      },
    );

    test(
      'given profiles in DB without config when currentProfileProvider read then returns latest profile and sets LAST_USED_PROFILE config',
      () async {
        // Given
        await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(
            username: 'User1',
            connectedOn: drift.Value(DateTime(2025, 1, 1)),
          ),
        );
        final id2 = await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(
            username: 'User2',
            connectedOn: drift.Value(DateTime(2026, 1, 1)),
          ),
        );

        // When
        final profile = await container.read(currentProfileProvider.future);
        final configVal = await db.configsDao.getConfig(
          Settings.LAST_USED_PROFILE.name,
        );

        // Then
        expect(profile, isNotNull);
        expect(profile!.id, equals(id2));
        expect(profile.username, equals('User2'));
        expect(configVal?.configValue, equals(id2.toString()));
      },
    );

    test(
      'given LAST_USED_PROFILE config when currentProfileProvider read then returns configured profile',
      () async {
        // Given
        final id1 = await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(
            username: 'ConfiguredUser',
            connectedOn: drift.Value(DateTime(2025, 1, 1)),
          ),
        );
        await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(
            username: 'NewerUser',
            connectedOn: drift.Value(DateTime(2026, 1, 1)),
          ),
        );
        await db.configsDao.setConfig(
          Settings.LAST_USED_PROFILE.name,
          id1.toString(),
        );

        // When
        final profile = await container.read(currentProfileProvider.future);

        // Then
        expect(profile, isNotNull);
        expect(profile!.id, equals(id1));
        expect(profile.username, equals('ConfiguredUser'));
      },
    );

    test(
      'given invalid LAST_USED_PROFILE config when currentProfileProvider read then falls back to latest profile',
      () async {
        // Given
        final id1 = await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(username: 'FallbackUser'),
        );
        await db.configsDao.setConfig(
          Settings.LAST_USED_PROFILE.name,
          '9999',
        ); // Non-existent ID

        // When
        final profile = await container.read(currentProfileProvider.future);

        // Then
        expect(profile, isNotNull);
        expect(profile!.id, equals(id1));
        expect(profile.username, equals('FallbackUser'));
      },
    );

    test(
      'given new profile when updateCurrentProfile called then updates state and saves config in DB',
      () async {
        // Given
        await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(username: 'InitialUser'),
        );
        final id2 = await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(username: 'NewActiveUser'),
        );
        await container.read(currentProfileProvider.future); // Initialize state

        final newProfile = (await db.profilesDao.getProfile(id2))!;

        // When
        await container
            .read(currentProfileProvider.notifier)
            .updateCurrentProfile(newProfile);
        final state = container.read(currentProfileProvider);
        final configVal = await db.configsDao.getConfig(
          Settings.LAST_USED_PROFILE.name,
        );

        // Then
        expect(state.value?.id, equals(id2));
        expect(state.value?.username, equals('NewActiveUser'));
        expect(configVal?.configValue, equals(id2.toString()));
      },
    );
  });

  group('allProfilesProvider Tests', () {
    test(
      'given multiple profiles in DB when allProfilesProvider read then streams all active profiles',
      () async {
        // Given
        await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(username: 'Alpha'),
        );
        await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(username: 'Beta'),
        );

        // When
        final listCompleter = Completer<List<Profile>>();
        container.listen(allProfilesProvider, (previous, next) {
          if (next is AsyncData<List<Profile>> && !listCompleter.isCompleted) {
            listCompleter.complete(next.value);
          }
        }, fireImmediately: true);
        final profiles = await listCompleter.future;

        // Then
        expect(profiles.length, equals(2));
        expect(profiles.map((p) => p.username), containsAll(['Alpha', 'Beta']));
      },
    );
  });

  group('handleProfileDeletion Tests', () {
    test(
      'given active profile and another profile exist when handleProfileDeletion called then invalidates currentProfileProvider, falls back to latest profile and updates Settings.LAST_USED_PROFILE',
      () async {
        // Given
        final id1 = await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(
            username: 'ActiveUser',
            connectedOn: drift.Value(DateTime(2025, 1, 1)),
          ),
        );
        final id2 = await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(
            username: 'LatestFallbackUser',
            connectedOn: drift.Value(DateTime(2026, 1, 1)),
          ),
        );
        await db.configsDao.setConfig(
          Settings.LAST_USED_PROFILE.name,
          id1.toString(),
        );

        // Verify initial state read returns ActiveUser
        var currentProfile = await container.read(
          currentProfileProvider.future,
        );
        expect(currentProfile?.id, equals(id1));
        expect(currentProfile?.username, equals('ActiveUser'));

        // When (replicates handleProfileDeletion: delete from db + invalidate provider)
        await db.profilesDao.deleteProfile(id1);
        container.invalidate(currentProfileProvider);
        currentProfile = await container.read(currentProfileProvider.future);
        final configVal = await db.configsDao.getConfig(
          Settings.LAST_USED_PROFILE.name,
        );

        // Then
        expect(currentProfile, isNotNull);
        expect(currentProfile?.id, equals(id2));
        expect(currentProfile?.username, equals('LatestFallbackUser'));
        expect(configVal?.configValue, equals(id2.toString()));
      },
    );

    test(
      'given only active profile exists when handleProfileDeletion called then invalidates currentProfileProvider, deletes Settings.LAST_USED_PROFILE config and returns null',
      () async {
        // Given
        final id1 = await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(
            username: 'SingleUser',
            connectedOn: drift.Value(DateTime(2025, 1, 1)),
          ),
        );
        await db.configsDao.setConfig(
          Settings.LAST_USED_PROFILE.name,
          id1.toString(),
        );

        // Verify initial state read returns SingleUser
        var currentProfile = await container.read(
          currentProfileProvider.future,
        );
        expect(currentProfile?.id, equals(id1));
        expect(currentProfile?.username, equals('SingleUser'));

        // When (replicates handleProfileDeletion: delete from db + invalidate provider)
        await db.profilesDao.deleteProfile(id1);
        container.invalidate(currentProfileProvider);
        currentProfile = await container.read(currentProfileProvider.future);
        final configVal = await db.configsDao.getConfig(
          Settings.LAST_USED_PROFILE.name,
        );

        // Then
        expect(currentProfile, isNull);
        expect(configVal, isNull);
      },
    );
  });
}
