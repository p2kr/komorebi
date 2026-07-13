import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komorebi/models/db/profiles_table.dart';
import 'package:komorebi/services/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('ProfilesDao - Basic CRUD', () {
    test(
      'given new profile when insertProfile called then inserts and retrieves profile',
      () async {
        // Given
        final companion = ProfilesCompanion.insert(
          username: 'Dash',
          syncType: const drift.Value(SyncType.OAUTH),
          isActive: const drift.Value(true),
        );

        // When
        final id = await db.profilesDao.insertProfile(companion);
        final profile = await db.profilesDao.getProfile(id);

        // Then
        expect(profile, isNotNull);
        expect(profile!.id, equals(id));
        expect(profile.username, equals('Dash'));
        expect(profile.syncType, equals(SyncType.OAUTH));
        expect(profile.isActive, isTrue);
      },
    );

    test(
      'given inactive profile when getAllProfiles called then excludes inactive profile',
      () async {
        // Given
        await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(
            username: 'ActiveUser',
            isActive: const drift.Value(true),
          ),
        );
        await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(
            username: 'InactiveUser',
            isActive: const drift.Value(false),
          ),
        );

        // When
        final stream = db.profilesDao.getAllProfiles();
        final profiles = await stream.first;

        // Then
        expect(profiles.length, equals(1));
        expect(profiles.first.username, equals('ActiveUser'));
      },
    );

    test(
      'given existing profile when deleteProfile called then removes profile from DB',
      () async {
        // Given
        final id = await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(username: 'ToDelete'),
        );

        // When
        final rowsDeleted = await db.profilesDao.deleteProfile(id);
        final profile = await db.profilesDao.getProfile(id);

        // Then
        expect(rowsDeleted, equals(1));
        expect(profile, isNull);
      },
    );
  });

  group('ProfilesDao - Queries and Streams', () {
    test(
      'given multiple profiles when getLatestProfile called then returns most recently connected profile',
      () async {
        // Given
        final olderDate = DateTime(2025, 1, 1);
        final newerDate = DateTime(2026, 1, 1);

        await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(
            username: 'OlderUser',
            connectedOn: drift.Value(olderDate),
          ),
        );
        await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(
            username: 'NewerUser',
            connectedOn: drift.Value(newerDate),
          ),
        );

        // When
        final latest = await db.profilesDao.getLatestProfile();

        // Then
        expect(latest, isNotNull);
        expect(latest!.username, equals('NewerUser'));
      },
    );

    test(
      'given profile when watchProfile called then emits updates on changes',
      () async {
        // Given
        final id = await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(username: 'StreamUser'),
        );

        // When & Then
        expect(
          db.profilesDao.watchProfile(id),
          emitsInOrder([
            isA<Profile>().having((p) => p.username, 'username', 'StreamUser'),
            isNull,
          ]),
        );

        await db.profilesDao.deleteProfile(id);
      },
    );

    test(
      'given profiles when watchLatestProfile called then emits latest profile',
      () async {
        // Given
        await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(
            username: 'FirstUser',
            connectedOn: drift.Value(DateTime(2025, 1, 1)),
          ),
        );

        // When & Then
        expect(
          db.profilesDao.watchLatestProfile(),
          emitsInOrder([
            isA<Profile>().having((p) => p.username, 'username', 'FirstUser'),
            isA<Profile>().having((p) => p.username, 'username', 'SecondUser'),
          ]),
        );

        await Future.delayed(const Duration(milliseconds: 50));
        await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(
            username: 'SecondUser',
            connectedOn: drift.Value(DateTime(2026, 1, 1)),
          ),
        );
      },
    );
  });

  group('ProfilesDao - Conflict resolution and cleanup', () {
    test(
      'given existing profile when insertOrUpdateProfile called with same username then updates existing without duplicating',
      () async {
        // Given
        final id1 = await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(
            username: 'Dash',
            syncType: const drift.Value(SyncType.SANDBOX),
          ),
        );

        // When
        final id2 = await db.profilesDao.insertOrUpdateProfile(
          ProfilesCompanion.insert(
            username: 'Dash',
            syncType: const drift.Value(SyncType.OAUTH),
            accessToken: const drift.Value('new_token'),
          ),
        );

        final all = await db.profilesDao.getAllProfiles().first;
        final updatedProfile = await db.profilesDao.getProfile(id1);

        // Then
        expect(id2, equals(id1));
        expect(all.length, equals(1));
        expect(updatedProfile!.syncType, equals(SyncType.OAUTH));
        expect(updatedProfile.accessToken, equals('new_token'));
      },
    );

    test(
      'given existing OAUTH profile when insertOrUpdateProfile called with SANDBOX profile then prioritizes OAUTH and does not overwrite',
      () async {
        // Given
        final id1 = await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(
            username: 'Dash',
            syncType: const drift.Value(SyncType.OAUTH),
            accessToken: const drift.Value('oauth_token'),
          ),
        );

        // When
        final id2 = await db.profilesDao.insertOrUpdateProfile(
          ProfilesCompanion.insert(
            username: 'Dash',
            syncType: const drift.Value(SyncType.SANDBOX),
          ),
        );

        final all = await db.profilesDao.getAllProfiles().first;
        final updatedProfile = await db.profilesDao.getProfile(id1);

        // Then
        expect(id2, equals(id1));
        expect(all.length, equals(1));
        expect(updatedProfile!.syncType, equals(SyncType.OAUTH));
        expect(updatedProfile.accessToken, equals('oauth_token'));
      },
    );

    test(
      'given duplicate SANDBOX and OAUTH profiles when insertOrUpdateProfile called then prioritizes OAUTH as primary and removes duplicate',
      () async {
        // Given
        await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(
            username: 'MultiUser',
            syncType: const drift.Value(SyncType.SANDBOX),
            connectedOn: drift.Value(DateTime(2025, 1, 1)),
            isActive: const drift.Value(false),
          ),
        );
        final oauthId = await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(
            username: 'MultiUser',
            syncType: const drift.Value(SyncType.OAUTH),
            connectedOn: drift.Value(DateTime(2025, 6, 1)),
            accessToken: const drift.Value('existing_oauth_token'),
            isActive: const drift.Value(true),
          ),
        );

        // When
        final resultId = await db.profilesDao.insertOrUpdateProfile(
          ProfilesCompanion.insert(
            username: 'MultiUser',
            syncType: const drift.Value(SyncType.OAUTH),
            accessToken: const drift.Value('updated_oauth_token'),
          ),
        );

        final remaining = await db.profilesDao.getAllProfiles().first;
        final resultProfile = await db.profilesDao.getProfile(resultId);

        // Then
        expect(resultId, equals(oauthId));
        expect(remaining.length, equals(1));
        expect(resultProfile!.syncType, equals(SyncType.OAUTH));
        expect(resultProfile.accessToken, equals('updated_oauth_token'));
      },
    );

    test(
      'given duplicate profiles in DB when cleanDuplicateProfiles called then retains OAuth or latest profile',
      () async {
        // Given - manually inserting duplicates by avoiding unique constraint with different isActive/syncType
        await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(
            username: 'DuplicateUser',
            syncType: const drift.Value(SyncType.SANDBOX),
            connectedOn: drift.Value(DateTime(2025, 1, 1)),
            isActive: const drift.Value(false),
          ),
        );
        await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(
            username: 'DuplicateUser',
            syncType: const drift.Value(SyncType.OAUTH),
            connectedOn: drift.Value(DateTime(2025, 6, 1)),
            isActive: const drift.Value(true),
          ),
        );

        // When
        await db.profilesDao.cleanDuplicateProfiles();
        final remaining = await db.profilesDao.getAllProfiles().first;

        // Then
        expect(remaining.length, equals(1));
        expect(remaining.first.username, equals('DuplicateUser'));
        expect(remaining.first.syncType, equals(SyncType.OAUTH));
      },
    );
  });
}
