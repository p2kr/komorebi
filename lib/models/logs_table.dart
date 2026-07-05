import 'package:drift/drift.dart';

class Logs extends Table {
  IntColumn get id => integer().autoIncrement()();

  DateTimeColumn get timestamp =>
      dateTime().clientDefault(() => DateTime.timestamp())();

  TextColumn get level =>
      text().clientDefault(() => "info")(); // 'info' | 'warning' | 'error'
  TextColumn get category =>
      text()(); // 'crawler' | 'network' | 'mal' | 'fs' | 'queue'
  TextColumn get message => text()();

  TextColumn get details => text().nullable()();
}
