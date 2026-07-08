import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/models/profiles_table.dart';
import 'package:komorebi/providers/profile_management_provider.dart';
import 'package:komorebi/screens/appbar/profile_management.dart';
import 'package:komorebi/services/database.dart';

void main() {
  group('noActiveProfileWidget Helper Tests', () {
    testWidgets('given context when noActiveProfileWidget called then builds icon and text', (WidgetTester tester) async {
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
              builder: (context) => Column(
                children: noActiveProfileWidget(context),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.byIcon(Icons.no_accounts_outlined), findsOneWidget);
      expect(find.text(S.current.noActiveProfile), findsOneWidget);
    });
  });

  group('ProfileManagementPopup Widget Tests', () {
    testWidgets('given no profiles when popup rendered then shows noActiveProfile and noProfilesFound', (WidgetTester tester) async {
      // Given
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProfileProvider.overrideWith(() => MockCurrentProfileNotifier(null)),
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
            home: const Scaffold(
              body: ProfileManagementPopup(),
            ),
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
    });

    testWidgets('given profiles when popup rendered then displays active profile and other profiles list', (WidgetTester tester) async {
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
            currentProfileProvider.overrideWith(() => MockCurrentProfileNotifier(primary)),
            allProfilesProvider.overrideWith((ref) => Stream.value([secondary])),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            home: const Scaffold(
              body: ProfileManagementPopup(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.text('PrimaryUser'), findsOneWidget);
      expect(find.text(S.current.otherConnectedProfiles), findsOneWidget);
      expect(find.text('SecondaryUser'), findsOneWidget);
    });
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
