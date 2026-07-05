import 'package:drift/drift.dart';

class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get username => text()();

  TextColumn get avatarUrl => text().nullable()();

  TextColumn get syncType => text()(); // 'oauth' | 'sandbox'
  DateTimeColumn get connectedAt => dateTime()();

  BoolColumn get isActive => boolean()();

  TextColumn get accessToken => text().nullable()();

  TextColumn get animeListJson =>
      text().nullable()(); // Serialized watching list data
}
