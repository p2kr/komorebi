import 'package:drift/drift.dart';

class Configs extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get configKey => text().unique()();

  TextColumn get configValue => text().nullable()();
}
