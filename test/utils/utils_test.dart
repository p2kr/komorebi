import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:komorebi/models/profiles_table.dart';
import 'package:komorebi/services/database.dart';
import 'package:komorebi/utils/utils.dart';

void main() {
  group('Utils - String formatting and helpers', () {
    test('given name when getInitials called then returns correct uppercase initials', () {
      // Given & When & Then
      expect(getInitials(null), equals('??'));
      expect(getInitials(''), equals('??'));
      expect(getInitials('A'), equals('A'));
      expect(getInitials('Dash'), equals('DA'));
      expect(getInitials('myAnimeList'), equals('MY'));
    });

    test('given dateTime when getDateOnly called then returns formatted date or fallback', () {
      // Given
      final testDate = DateTime(2026, 7, 7, 12, 0, 0);
      final expectedFormat = DateFormat().add_yMd().format(testDate.toLocal());

      // When & Then
      expect(getDateOnly(null), equals('???'));
      expect(getDateOnly(testDate), equals(expectedFormat));
    });
  });

  group('Utils - Widget helpers', () {
    testWidgets('given SyncType when getSyncTypeIcon called then returns correct widget structure', (WidgetTester tester) async {
      // Given & When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                getSyncTypeIcon(SyncType.OAUTH),
                getSyncTypeIcon(SyncType.SANDBOX),
                getSyncTypeIcon(null),
              ],
            ),
          ),
        ),
      );

      // Then
      expect(find.byIcon(Icons.key_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_add_alt), findsOneWidget);
      expect(find.byIcon(Icons.no_accounts_outlined), findsOneWidget);
    });

    testWidgets('given Profile when getAvatar called then builds CircleAvatar with appropriate child or provider', (WidgetTester tester) async {
      // Given
      final profileWithAvatar = Profile(
        id: 1,
        username: 'Dash',
        avatarUrl: 'https://example.com/avatar.png',
        syncType: SyncType.OAUTH,
        connectedOn: DateTime(2026, 1, 1),
        isActive: true,
        accessToken: 'token',
        animeListJson: null,
      );

      final profileWithoutAvatar = Profile(
        id: 2,
        username: 'Komorebi',
        avatarUrl: null,
        syncType: SyncType.SANDBOX,
        connectedOn: DateTime(2026, 1, 1),
        isActive: true,
        accessToken: null,
        animeListJson: null,
      );

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                getAvatar(profileWithAvatar, radius: 24),
                getAvatar(profileWithoutAvatar, radius: 24),
                getAvatar(null, radius: 24),
              ],
            ),
          ),
        ),
      );

      // Then
      final avatars = tester.widgetList<CircleAvatar>(find.byType(CircleAvatar)).toList();
      expect(avatars.length, equals(3));

      // First avatar has CachedNetworkImageProvider
      expect(avatars[0].foregroundImage, isA<CachedNetworkImageProvider>());
      expect(avatars[0].child, isNull);

      // Second avatar has Text initials
      expect(avatars[1].foregroundImage, isNull);
      expect(find.text('KO'), findsOneWidget);
      expect(avatars[1].child, isNotNull);

      // Third avatar (null profile) has null child
      expect(avatars[2].foregroundImage, isNull);
      expect(avatars[2].child, isNull);
    });
  });
}
