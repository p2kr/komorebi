import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/models/profiles_table.dart';
import 'package:komorebi/providers/common_providers.dart';
import 'package:komorebi/providers/profile_management_provider.dart';
import 'package:komorebi/screens/appbar/profile_management.dart';
import 'package:komorebi/services/database.dart';
import 'package:komorebi/utils/constants.dart';

void main() {
  group('noActiveProfileWidget Helper Tests', () {
    testWidgets(
      'given context when noActiveProfileWidget called then builds icon and text',
      (WidgetTester tester) async {
        // Given & When
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) =>
                    Column(children: noActiveProfileWidget(context)),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Then
        expect(find.byIcon(Icons.no_accounts_outlined), findsOneWidget);
        expect(find.text(S.current.noActiveProfile), findsOneWidget);
      },
    );
  });

  group('ProfileManagementPopup Widget Tests', () {
    testWidgets(
      'given no profiles when popup rendered then shows noActiveProfile and noProfilesFound',
      (WidgetTester tester) async {
        // Given
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // When
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentProfileProvider.overrideWith(
                () => MockCurrentProfileNotifier(null),
              ),
              allProfilesProvider.overrideWith((ref) => Stream.value([])),
            ],
            child: MaterialApp(
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: S.delegate.supportedLocales,
              home: const Scaffold(body: ProfileManagementPopup()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Then
        expect(find.byIcon(Icons.no_accounts_outlined), findsOneWidget);
        expect(find.text(S.current.noActiveProfile), findsOneWidget);
        expect(find.text(S.current.noProfilesFound), findsOneWidget);
        expect(find.text(S.current.linkAnotherMalOauth), findsOneWidget);
        expect(find.text(S.current.quickSandboxLink), findsOneWidget);
        expect(find.text(S.current.disconnectActiveProfile), findsOneWidget);
      },
    );

    testWidgets(
      'given profiles when popup rendered then displays active profile and other profiles list',
      (WidgetTester tester) async {
        // Given
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final primary = Profile(
          id: 1,
          username: 'PrimaryUser',
          avatarUrl: null,
          syncType: SyncType.OAUTH,
          connectedOn: DateTime.now(),
          isActive: true,
          accessToken: null,
          animeListJson: null,
        );
        final secondary = Profile(
          id: 2,
          username: 'SecondaryUser',
          avatarUrl: null,
          syncType: SyncType.SANDBOX,
          connectedOn: DateTime.now(),
          isActive: true,
          accessToken: null,
          animeListJson: null,
        );

        // When
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentProfileProvider.overrideWith(
                () => MockCurrentProfileNotifier(primary),
              ),
              allProfilesProvider.overrideWith(
                (ref) => Stream.value([secondary]),
              ),
            ],
            child: MaterialApp(
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: S.delegate.supportedLocales,
              home: const Scaffold(body: ProfileManagementPopup()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Then
        expect(find.text('PrimaryUser'), findsOneWidget);
        expect(find.text(S.current.otherConnectedProfiles), findsOneWidget);
        expect(find.text('SecondaryUser'), findsOneWidget);
      },
    );

    testWidgets(
      'given active profile when Disconnect active profile button clicked then confirmation dialog DELETE @username ? appears',
      (WidgetTester tester) async {
        // Given
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final db = AppDatabase(NativeDatabase.memory());

        await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(
            username: 'ActiveUser',
            connectedOn: drift.Value(DateTime.now()),
          ),
        );

        // When
        await tester.pumpWidget(
          ProviderScope(
            overrides: [dbProvider.overrideWithValue(db)],
            child: MaterialApp(
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: S.delegate.supportedLocales,
              home: const Scaffold(body: ProfileManagementPopup()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('ActiveUser'), findsNWidgets(2));

        final disconnectButton = find.text(S.current.disconnectActiveProfile);
        expect(disconnectButton, findsOneWidget);

        await tester.tap(disconnectButton);
        await tester.pumpAndSettle();

        // Then
        expect(find.text('DELETE @ActiveUser ?'), findsOneWidget);
        expect(find.text('YES'), findsOneWidget);
        expect(find.text('NO'), findsOneWidget);

        // Unmount ProviderScope to flush Drift StreamQueryStore cleanup timer before test completion
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 500));
        await db.close();
      },
    );

    testWidgets(
      'given active profile when Disconnect active profile confirmed with YES then calls handleProfileDeletion, removes profile, updates providers and closes dialog',
      (WidgetTester tester) async {
        // Given
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final db = AppDatabase(NativeDatabase.memory());

        final profileId = await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(
            username: 'DeleteUser',
            connectedOn: drift.Value(DateTime.now()),
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [dbProvider.overrideWithValue(db)],
            child: MaterialApp(
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: S.delegate.supportedLocales,
              home: const Scaffold(body: ProfileManagementPopup()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('DeleteUser'), findsNWidgets(2));

        // When Disconnect active profile is clicked and YES is confirmed
        await tester.tap(find.text(S.current.disconnectActiveProfile));
        await tester.pumpAndSettle();

        expect(find.text('DELETE @DeleteUser ?'), findsOneWidget);

        await tester.tap(find.text('YES'));
        await tester.pumpAndSettle();

        // Then dialog closes
        expect(find.text('DELETE @DeleteUser ?'), findsNothing);

        // Profile removed from database
        final dbProfile = await db.profilesDao.getProfile(profileId);
        expect(dbProfile, isNull);

        // currentProfileProvider and allProfilesProvider updated
        expect(find.text(S.current.noActiveProfile), findsOneWidget);
        expect(find.text(S.current.noProfilesFound), findsOneWidget);
        expect(find.text('DeleteUser'), findsNothing);

        // Unmount ProviderScope to flush Drift StreamQueryStore cleanup timer before test completion
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 500));
        await db.close();
      },
    );

    testWidgets(
      'given active profile and secondary profile when Disconnect active profile confirmed with YES then removes active profile and updates providers to fallback profile',
      (WidgetTester tester) async {
        // Given
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final db = AppDatabase(NativeDatabase.memory());

        final primaryId = await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(
            username: 'PrimaryUser',
            connectedOn: drift.Value(DateTime(2025, 1, 1)),
          ),
        );
        final secondaryId = await db.profilesDao.insertProfile(
          ProfilesCompanion.insert(
            username: 'SecondaryUser',
            connectedOn: drift.Value(DateTime(2026, 1, 1)),
          ),
        );
        await db.configsDao.setConfig(
          Settings.LAST_USED_PROFILE.name,
          primaryId.toString(),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [dbProvider.overrideWithValue(db)],
            child: MaterialApp(
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: S.delegate.supportedLocales,
              home: const Scaffold(body: ProfileManagementPopup()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('PrimaryUser'), findsNWidgets(2));
        expect(find.text('SecondaryUser'), findsOneWidget);

        // When Disconnect active profile is clicked and confirmed
        await tester.tap(find.text(S.current.disconnectActiveProfile));
        await tester.pumpAndSettle();

        expect(find.text('DELETE @PrimaryUser ?'), findsOneWidget);

        await tester.tap(find.text('YES'));
        await tester.pumpAndSettle();

        // Then dialog closes
        expect(find.text('DELETE @PrimaryUser ?'), findsNothing);

        // Primary user removed from database
        final dbProfile = await db.profilesDao.getProfile(primaryId);
        expect(dbProfile, isNull);

        // currentProfileProvider updated to SecondaryUser
        final fallbackProfile = await db.profilesDao.getProfile(secondaryId);
        expect(fallbackProfile, isNotNull);
        expect(find.text('PrimaryUser'), findsNothing);
        expect(find.text('SecondaryUser'), findsNWidgets(2));

        // Unmount ProviderScope to flush Drift StreamQueryStore cleanup timer before test completion
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 500));
        await db.close();
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
