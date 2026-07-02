import 'package:drift/drift.dart';

class QueueItems extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get animeId => integer().nullable()();

  TextColumn get animeTitle => text()();

  IntColumn get episodeNumber => integer()();

  TextColumn get downloadUrl => text()();

  TextColumn get title => text()();

  TextColumn get status => text().withDefault(
    const Constant('pending'),
  )(); // 'pending' | 'downloading' | 'completed' | 'failed'
  RealColumn get progress => real()();

  TextColumn get priority =>
      text().withDefault(const Constant("normal"))(); // 'normal' | 'high'
  DateTimeColumn get addedAt =>
      dateTime().withDefault(Constant(DateTime.timestamp()))();

  TextColumn get errorMessage => text().nullable()();
}
