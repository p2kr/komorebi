import 'package:drift/drift.dart';

class Config extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get configKey => text()();

  TextColumn get configValue => text()();
}
