import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/src/core/providers/common_providers.dart';
import 'package:komorebi/src/core/services/api/profile_api_service.dart';
import 'package:komorebi/src/core/services/database.dart';
import 'package:komorebi/src/features/appbar/profile_management.dart';
import 'package:komorebi/src/features/profile/profile.dart';
import 'package:komorebi/src/features/profile/profile_management_provider.dart';

import '../../fakes/fake_profile_api_service.dart';

void main() {
  group('noActiveProfileWidget Helper Tests', () {
    testWidgets(
      'given context when noActiveProfileWidget called then builds icon and text',
      (WidgetTester tester) async {
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

        expect(find.byIcon(Icons.no_accounts_outlined), findsOneWidget);
        expect(find.text(S.current.noActiveProfile), findsOneWidget);
      },
    );
  });

  group('ProfileManagementPopup Widget Tests', () {
    testWidgets(
      'given no profiles when popup rendered then shows noActiveProfile and noProfilesFound',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeApi = FakeProfileApiService();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              profileApiServiceProvider.overrideWithValue(fakeApi),
              currentProfileProvider.overrideWith(
                () => MockCurrentProfileNotifier(null),
              ),
              allProfilesProvider.overrideWith((ref) => Future.value([])),
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
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final primary = Profile(
          id: 1,
          username: 'PrimaryUser',
          avatarUrl: null,
          syncType: SyncType.mal,
          createdAt: DateTime.now(),
        );
        final secondary = Profile(
          id: 2,
          username: 'SecondaryUser',
          avatarUrl: null,
          syncType: SyncType.sandbox,
          createdAt: DateTime.now(),
        );

        final fakeApi = FakeProfileApiService();
        fakeApi.profiles.addAll([primary, secondary]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              profileApiServiceProvider.overrideWithValue(fakeApi),
              currentProfileProvider.overrideWith(
                () => MockCurrentProfileNotifier(primary),
              ),
              allProfilesProvider.overrideWith(
                (ref) => Future.value([secondary]),
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

        expect(find.text('PrimaryUser'), findsOneWidget);
        expect(find.text(S.current.otherConnectedProfiles), findsOneWidget);
        expect(find.text('SecondaryUser'), findsOneWidget);
      },
    );

    testWidgets(
      'given active profile when Disconnect active profile button clicked then confirmation dialog DELETE @username ? appears',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final db = AppDatabase(NativeDatabase.memory());
        final fakeApi = FakeProfileApiService();
        final profile = Profile(
          id: 1,
          username: 'ActiveUser',
          syncType: SyncType.sandbox,
          createdAt: DateTime.now(),
        );
        fakeApi.profiles.add(profile);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              dbProvider.overrideWithValue(db),
              profileApiServiceProvider.overrideWithValue(fakeApi),
              currentProfileProvider.overrideWith(
                () => MockCurrentProfileNotifier(profile),
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

        expect(find.text('ActiveUser'), findsNWidgets(2));

        final disconnectButton = find.text(S.current.disconnectActiveProfile);
        expect(disconnectButton, findsOneWidget);

        await tester.tap(disconnectButton);
        await tester.pumpAndSettle();

        expect(find.text('DELETE @ActiveUser ?'), findsOneWidget);
        expect(find.text('YES'), findsOneWidget);
        expect(find.text('NO'), findsOneWidget);

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
