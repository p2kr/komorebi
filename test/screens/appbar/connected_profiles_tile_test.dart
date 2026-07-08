import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komorebi/models/profiles_table.dart';
import 'package:komorebi/providers/common_providers.dart';
import 'package:komorebi/providers/profile_management_provider.dart';
import 'package:komorebi/screens/appbar/connected_profiles_tile.dart';
import 'package:komorebi/services/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('isCurrentProfileTile Helper Tests', () {
    test(
      'given matching profile ID when isCurrentProfileTile called then returns true',
      () {
        // Given
        final profile = Profile(
          id: 1,
          username: 'Dash',
          avatarUrl: null,
          syncType: SyncType.SANDBOX,
          connectedOn: DateTime.now(),
          isActive: true,
          accessToken: null,
          animeListJson: null,
        );
        final asyncProfile = AsyncValue.data(profile);

        // When
        final result = isCurrentProfileTile(profile, asyncProfile);

        // Then
        expect(result, isTrue);
      },
    );

    test(
      'given different profile ID when isCurrentProfileTile called then returns false',
      () {
        // Given
        final profile1 = Profile(
          id: 1,
          username: 'Dash',
          avatarUrl: null,
          syncType: SyncType.SANDBOX,
          connectedOn: DateTime.now(),
          isActive: true,
          accessToken: null,
          animeListJson: null,
        );
        final profile2 = Profile(
          id: 2,
          username: 'Komorebi',
          avatarUrl: null,
          syncType: SyncType.SANDBOX,
          connectedOn: DateTime.now(),
          isActive: true,
          accessToken: null,
          animeListJson: null,
        );
        final asyncProfile = AsyncValue.data(profile2);

        // When
        final result = isCurrentProfileTile(profile1, asyncProfile);

        // Then
        expect(result, isFalse);
      },
    );

    test(
      'given null active profile when isCurrentProfileTile called then returns true',
      () {
        // Given
        final profile = Profile(
          id: 1,
          username: 'Dash',
          avatarUrl: null,
          syncType: SyncType.SANDBOX,
          connectedOn: DateTime.now(),
          isActive: true,
          accessToken: null,
          animeListJson: null,
        );
        const asyncProfile = AsyncValue<Profile?>.data(null);

        // When
        final result = isCurrentProfileTile(profile, asyncProfile);

        // Then
        expect(result, isTrue);
      },
    );
  });

  group('ConnectedProfilesTile Widget Tests', () {
    testWidgets(
      'given profile when rendered then displays username and syncType and handles tap',
      (WidgetTester tester) async {
        // Given
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final profile1 = Profile(
          id: 10,
          username: 'ActiveUser',
          avatarUrl: null,
          syncType: SyncType.SANDBOX,
          connectedOn: DateTime.now(),
          isActive: true,
          accessToken: null,
          animeListJson: null,
        );
        final profile2 = Profile(
          id: 20,
          username: 'OtherUser',
          avatarUrl: null,
          syncType: SyncType.OAUTH,
          connectedOn: DateTime.now(),
          isActive: true,
          accessToken: null,
          animeListJson: null,
        );

        await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(
            username: 'ActiveUser',
            syncType: const drift.Value(SyncType.SANDBOX),
          ),
        );
        await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(
            username: 'OtherUser',
            syncType: const drift.Value(SyncType.OAUTH),
          ),
        );

        // When
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              dbProvider.overrideWithValue(db),
              currentProfileProvider.overrideWith(
                () => MockCurrentProfileNotifier(profile1),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(body: ConnectedProfilesTile(profile: profile2)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Then
        expect(find.text('OtherUser'), findsOneWidget);
        expect(find.text('OAUTH'), findsOneWidget);
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);

        // Tap on tile
        await tester.tap(find.text('OtherUser'));
        await tester.pump();
      },
    );
  });
}

class MockCurrentProfileNotifier extends CurrentProfileNotifier {
  final Profile? initialProfile;
  MockCurrentProfileNotifier(this.initialProfile);

  @override
  Future<Profile?> build() async {
    return initialProfile;
  }

  @override
  Future<void> updateCurrentProfile(Profile newProfile) async {
    state = AsyncValue.data(newProfile);
  }
}
