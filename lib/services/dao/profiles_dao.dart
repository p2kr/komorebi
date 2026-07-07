import 'package:drift/drift.dart';
import 'package:komorebi/models/profiles_table.dart';
import 'package:komorebi/services/database.dart';

part 'profiles_dao.g.dart';

@DriftAccessor(tables: [Profiles])
class ProfilesDao extends DatabaseAccessor<AppDatabase>
    with _$ProfilesDaoMixin {
  ProfilesDao(super.attachedDatabase);

  /// Stream all Profiles present in DB. Exclude inactive ones.
  Stream<List<Profile>> getAllProfiles() {
    return (select(profiles)..where((t) => t.isActive)).watch();
  }

  /// Fetch profile by id
  Future<Profile?> getProfile(int id) {
    return (select(
      profiles,
    )..where((t) => t.id.equals(id) & t.isActive)).getSingleOrNull();
  }

  /// Stream profile by id
  Stream<Profile?> watchProfile(int id) {
    return (select(
      profiles,
    )..where((t) => t.id.equals(id) & t.isActive)).watchSingleOrNull();
  }

  /// Fetch latest created profile
  Future<Profile?> getLatestProfile() {
    return (select(profiles)
          ..where((t) => t.isActive)
          ..orderBy([
            (p) => OrderingTerm(
              expression: p.connectedOn,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Stream latest created profile
  Stream<Profile?> watchLatestProfile() {
    return (select(profiles)
          ..where((t) => t.isActive)
          ..orderBy([
            (p) => OrderingTerm(
              expression: p.connectedOn,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(1))
        .watchSingleOrNull();
  }

  /// Insert new profile
  Future<int> insertProfile(ProfilesCompanion profile) {
    return transaction(() => into(profiles).insert(profile));
  }

  /// Insert or update profile on conflict by username, removing any duplicates
  Future<int> insertOrUpdateProfile(ProfilesCompanion profile) async {
    return transaction(() async {
      final usernameVal = profile.username.value;
      final existingList = await (select(
        profiles,
      )..where((t) => t.username.equals(usernameVal))).get();
      if (existingList.isNotEmpty) {
        // Keep the first one and delete any duplicate rows with the same username
        final primary = existingList.first;
        if (existingList.length > 1) {
          final duplicateIds = existingList.skip(1).map((e) => e.id).toList();
          await (delete(profiles)..where((t) => t.id.isIn(duplicateIds))).go();
        }
        await (update(
          profiles,
        )..where((t) => t.id.equals(primary.id))).write(profile);
        return primary.id;
      } else {
        return await into(profiles).insert(profile);
      }
    });
  }

  /// Remove duplicate profiles with the same username, keeping only the most relevant one.
  Future<void> cleanDuplicateProfiles() async {
    await transaction(() async {
      final all = await select(profiles).get();
      final seenUsernames = <String, Profile>{};
      final duplicateIds = <int>[];

      for (final profile in all) {
        if (seenUsernames.containsKey(profile.username)) {
          final existing = seenUsernames[profile.username]!;
          final existingIsOauth = existing.syncType == SyncType.OAUTH;
          final profileIsOauth = profile.syncType == SyncType.OAUTH;
          if (profileIsOauth && !existingIsOauth) {
            duplicateIds.add(existing.id);
            seenUsernames[profile.username] = profile;
          } else if (!profileIsOauth && existingIsOauth) {
            duplicateIds.add(profile.id);
          } else if (profile.connectedOn.isAfter(existing.connectedOn)) {
            duplicateIds.add(existing.id);
            seenUsernames[profile.username] = profile;
          } else {
            duplicateIds.add(profile.id);
          }
        } else {
          seenUsernames[profile.username] = profile;
        }
      }

      if (duplicateIds.isNotEmpty) {
        await (delete(profiles)..where((t) => t.id.isIn(duplicateIds))).go();
      }
    });
  }

  ///  Delete a profile
  Future<int> deleteProfile(int id) {
    return transaction(
      () => (delete(profiles)..where((t) => t.id.equals(id))).go(),
    );
  }
}
