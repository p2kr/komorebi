import 'package:drift/drift.dart';
import 'package:komorebi/models/db/config_table.dart';
import 'package:komorebi/services/database.dart';

part 'configs_dao.g.dart';

@DriftAccessor(tables: [Configs])
class ConfigsDao extends DatabaseAccessor<AppDatabase> with _$ConfigsDaoMixin {
  ConfigsDao(super.attachedDatabase);

  /// Get config value
  Future<Config?> getConfig(String key) {
    return (select(
      configs,
    )..where((t) => t.configKey.equals(key))).getSingleOrNull();
  }

  /// insert or update config
  Future<int> setConfig(String key, String value) {
    return transaction(() async {
      return into(configs).insert(
        ConfigsCompanion(configKey: Value(key), configValue: Value(value)),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  // remove a config
  Future<int> deleteConfig(String key) {
    return transaction(() async {
      return (delete(configs)..where((t) => t.configKey.equals(key))).go();
    });
  }

  /// get all configs as Map. Useful for caching
  Future<Map<String, String?>> getAllConfigs() async {
    final configsList = await select(configs).get();
    return Map.fromEntries(
      configsList.map(
        (config) => MapEntry(config.configKey, config.configValue),
      ),
    );
  }
}
