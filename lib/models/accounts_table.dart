import 'package:drift/drift.dart';

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get username => text()();

  TextColumn get avatarUrl => text()();

  TextColumn get syncType => text()(); // 'oauth' | 'sandbox'
  DateTimeColumn get connectedAt => dateTime()();

  BoolColumn get isActive => boolean()();

  TextColumn get accessToken => text().nullable()();

  TextColumn get animeListJson =>
      text().nullable()(); // Serialized watching list data
}
