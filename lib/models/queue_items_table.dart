import 'package:drift/drift.dart';

class QueueItems extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get animeId => integer().nullable()();

  TextColumn get animeTitle => text()();

  IntColumn get episodeNumber => integer()();

  TextColumn get downloadUrl => text()();

  TextColumn get title => text()();

  IntColumn get status => intEnum<Status>().clientDefault(
    () => Status.PENDING.index,
  )(); // 'pending' | 'downloading' | 'completed' | 'failed'

  RealColumn get progress => real()();

  IntColumn get priority => intEnum<Priority>().clientDefault(
    () => Priority.NORMAL.index,
  )(); // 'normal' | 'medium' | 'high'

  DateTimeColumn get addedAt =>
      dateTime().clientDefault(() => DateTime.timestamp())();

  TextColumn get errorMessage => text().nullable()();
}

enum Status { PENDING, DOWNLOADING, COMPLETED, FAILED }

enum Priority { NORMAL, MEDIUM, HIGH }
