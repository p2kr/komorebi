import 'package:drift/drift.dart';
import 'package:komorebi/models/config_table.dart';
import 'package:komorebi/services/database.dart';

part 'configs_dao.g.dart';

@DriftAccessor(tables: [Configs])
class ConfigsDao extends DatabaseAccessor<AppDatabase> with _$ConfigsDaoMixin {
  ConfigsDao(super.attachedDatabase);
}
