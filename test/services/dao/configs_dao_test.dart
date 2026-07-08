import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komorebi/services/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('ConfigsDao Tests', () {
    test('given no config when getConfig called then returns null', () async {
      // Given & When
      final config = await db.configsDao.getConfig('NON_EXISTENT');

      // Then
      expect(config, isNull);
    });

    test('given key and value when setConfig called then inserts and retrieves config', () async {
      // Given
      const key = 'LAST_USED_PROFILE';
      const val = '101';

      // When
      await db.configsDao.setConfig(key, val);
      final config = await db.configsDao.getConfig(key);

      // Then
      expect(config, isNotNull);
      expect(config!.configKey, equals(key));
      expect(config.configValue, equals(val));
    });

    test('given existing config when setConfig called with new value then updates config', () async {
      // Given
      const key = 'THEME_MODE';
      await db.configsDao.setConfig(key, 'dark');

      // When
      await db.configsDao.setConfig(key, 'light');
      final config = await db.configsDao.getConfig(key);

      // Then
      expect(config, isNotNull);
      expect(config!.configValue, equals('light'));
    });

    test('given existing config when deleteConfig called then removes config', () async {
      // Given
      const key = 'TEMP_KEY';
      await db.configsDao.setConfig(key, 'value');

      // When
      final rowsDeleted = await db.configsDao.deleteConfig(key);
      final config = await db.configsDao.getConfig(key);

      // Then
      expect(rowsDeleted, equals(1));
      expect(config, isNull);
    });

    test('given multiple configs when getAllConfigs called then returns Map of all configs', () async {
      // Given
      await db.configsDao.setConfig('key1', 'val1');
      await db.configsDao.setConfig('key2', 'val2');

      // When
      final map = await db.configsDao.getAllConfigs();

      // Then
      expect(map.length, equals(2));
      expect(map['key1'], equals('val1'));
      expect(map['key2'], equals('val2'));
    });
  });
}
