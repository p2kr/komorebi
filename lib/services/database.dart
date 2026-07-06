import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:komorebi/models/config_table.dart';
import 'package:komorebi/models/logs_table.dart';
import 'package:komorebi/models/profiles_table.dart';
import 'package:komorebi/models/queue_items_table.dart';
import 'package:komorebi/services/dao/configs_dao.dart';
import 'package:komorebi/services/dao/profiles_dao.dart';
import 'package:komorebi/utils/constants.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Profiles, QueueItems, Logs, Configs],
  daos: [ProfilesDao, ConfigsDao], // QueueItemsDao, LogsDao,
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
      // If you need web support, see https://drift.simonbinder.eu/platforms/web/
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse("sqlite3.wasm"),
        driftWorker: Uri.parse("drift_worker.dart.js"),
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
