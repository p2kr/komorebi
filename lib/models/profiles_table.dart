import 'package:drift/drift.dart';

class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get username => text()();

  TextColumn get avatarUrl => text().nullable()();

  IntColumn get syncType => intEnum<SyncType>().clientDefault(
    () => SyncType.SANDBOX.index,
  )(); // oauth | sandbox

  DateTimeColumn get connectedAt =>
      dateTime().clientDefault(() => DateTime.timestamp())();

  BoolColumn get isActive => boolean().clientDefault(() => true)();

  TextColumn get accessToken => text().nullable()();

  TextColumn get animeListJson =>
      text().nullable()(); // Serialized watching list data
}

enum SyncType { OAUTH, SANDBOX }
