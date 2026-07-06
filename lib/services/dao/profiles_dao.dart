import 'package:drift/drift.dart';
import 'package:komorebi/models/profiles_table.dart';
import 'package:komorebi/services/database.dart';

part 'profiles_dao.g.dart';

@DriftAccessor(tables: [Profiles])
class ProfilesDao extends DatabaseAccessor<AppDatabase>
    with _$ProfilesDaoMixin {
  ProfilesDao(super.attachedDatabase);

  /// Stream all Profiles present in DB. Exclude inactive ones.
  Stream<List<Profile>> watchProfiles() {
    return (select(profiles)..where((t) => t.isActive)).watch();
  }

  /// Fetch profile by id
  Stream<Profile> watchProfile(int id) {
    return (select(profiles)..where((t) => t.id.equals(id) & t.isActive))
        .watchSingle(); //SingleOrNull();
  }

  /// Fetch latest created profile
  Stream<Profile> watchLatestProfile() {
    return (select(profiles)
          ..where((t) => t.isActive)
          ..orderBy([
            (p) => OrderingTerm(
              expression: p.connectedOn,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(1))
        .watchSingle();
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
