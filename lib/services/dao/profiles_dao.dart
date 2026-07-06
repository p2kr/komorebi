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

  ///  Delete a profile
  Future<int> deleteProfile(int id) {
    return transaction(
      () => (delete(profiles)..where((t) => t.id.equals(id))).go(),
    );
  }
}
