import 'package:drift/drift.dart';

class QueueItems extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get animeId => integer().nullable()();

  TextColumn get animeTitle => text()();

  IntColumn get episodeNumber => integer()();

  TextColumn get downloadUrl => text()();

  TextColumn get title => text()();

  TextColumn get status => text().clientDefault(
    () => 'pending',
  )(); // 'pending' | 'downloading' | 'completed' | 'failed'
  RealColumn get progress => real()();

  TextColumn get priority =>
      text().clientDefault(() => "normal")(); // 'normal' | 'high'
  DateTimeColumn get addedAt =>
      dateTime().clientDefault(() => DateTime.timestamp())();

  TextColumn get errorMessage => text().nullable()();
}
