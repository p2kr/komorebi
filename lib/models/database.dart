import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:komorebi/utils/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'accounts_table.dart';
import 'config_table.dart';
import 'logs_table.dart';
import 'queue_items_table.dart';

part 'database.g.dart';

// part 'accounts_table.dart';
// part 'queue_items_table.dart';
// part 'logs_table.dart';

@DriftDatabase(tables: [Accounts, QueueItems, Logs, Config])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, DB_LOCATION));
    return NativeDatabase(file, logStatements: true);
  });
}
