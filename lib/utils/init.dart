import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/find_locale.dart';
import 'package:intl/intl.dart';
import 'package:komorebi/models/database.dart';
import 'package:komorebi/utils/talker.dart';
import 'package:window_manager/window_manager.dart';

Future<void> doInitialConfigurations() async {
  talker.debug("entered init.doInitialConfigurations");

  // setup db
  setupDb();
  // setup i18n
  await setupL10N();
  // setup app window
  await setupAppWindow();

  talker.debug("exited init.doInitialConfigurations successfully");
}

void setupDb() {
  if (kDebugMode) {
    // create dummy entries
    final db = AppDatabase();
    db.into(db.profiles).insert(ProfilesCompanion(username: Value("Dummy")));
    db.close();
  }
}

Future<void> setupL10N() async {
  Intl.defaultLocale = await findSystemLocale();
  talker.debug("default locale set to ${Intl.defaultLocale}");
}

/// Apply window options only for desktop platforms
Future<void> setupAppWindow() async {
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = WindowOptions(center: true);

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.maximize(); //TODO: Make it configurable
      await windowManager.show();
      await windowManager.focus();
    });
  }
}
