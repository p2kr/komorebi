import 'package:drift/drift.dart';

class Configs extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get configKey => text()();

  TextColumn get configValue => text()();
}
