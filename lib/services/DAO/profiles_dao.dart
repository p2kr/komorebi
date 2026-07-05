import 'package:drift/drift.dart';
import 'package:komorebi/models/database.dart';
import 'package:komorebi/models/profiles_table.dart';

part 'profiles_dao.g.dart';

@DriftAccessor(tables: [Profiles])
class ProfilesDao extends DatabaseAccessor<AppDatabase>
    with _$ProfilesDaoMixin {
  ProfilesDao(super.attachedDatabase);

  /// Stream all Profiles present in DB. Exclude inactive ones.
  Stream<List<Profile>> watchProfiles() {
    return (select(profiles)..where((t) => t.isActive)).watch();
  }
}
