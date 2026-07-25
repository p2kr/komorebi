import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:komorebi/models/api/crawler_config.dart';
import 'package:komorebi/models/db/config_table.dart';
import 'package:komorebi/models/db/profiles_table.dart';
import 'package:komorebi/models/db/vault_items_table.dart';
import 'package:komorebi/services/dao/configs_dao.dart';
import 'package:komorebi/services/dao/profiles_dao.dart';
import 'package:komorebi/services/dao/vault_items_dao.dart';
import 'package:komorebi/utils/constants.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Profiles, Configs, VaultItems],
  daos: [ProfilesDao, ConfigsDao, VaultItemsDao],
)
class AppDatabase extends _$AppDatabase {
  // After generating code, this class needs to define a `schemaVersion` getter
  // and a constructor telling drift where the database should be stored.
  // These are described in the getting started guide: https://drift.simonbinder.eu/setup/
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: DB_NAME,
      native: const DriftNativeOptions(
        // By default, `driftDatabase` from `package:drift_flutter` stores the
        // database files in `getApplicationDocumentsDirectory()`.
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}

extension ForceDbRefresh on AppDatabase {
  /// Simple helper to quickly bust the cache of a specific table
  void forceRefreshTable(TableInfo table) {
    notifyUpdates({TableUpdate.onTable(table)});
  }

  void forceRefreshTables(Set<TableInfo> tables) {
    notifyUpdates(tables.map((table) => TableUpdate.onTable(table)).toSet());
  }
}
