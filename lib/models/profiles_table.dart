import 'package:drift/drift.dart';

class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get username => text()();

  TextColumn get avatarUrl => text().nullable()();

  IntColumn get syncType => intEnum<SyncType>().clientDefault(
    () => SyncType.SANDBOX.index,
  )(); // oauth | sandbox

  DateTimeColumn get connectedOn =>
      dateTime().clientDefault(() => DateTime.timestamp())();

  BoolColumn get isActive => boolean().clientDefault(() => true)();

  TextColumn get accessToken => text().nullable()();

  /// Serialized watching list data
  TextColumn get animeListJson => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {username, syncType, isActive},
  ];
}

enum SyncType { OAUTH, SANDBOX }
