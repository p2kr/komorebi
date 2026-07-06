import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/find_locale.dart';
import 'package:intl/intl.dart';
import 'package:komorebi/providers/profile_management_provider.dart';
import 'package:komorebi/services/database.dart';
import 'package:komorebi/utils/constants.dart';
import 'package:komorebi/utils/talker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

Future<void> doInitialConfigurations() async {
  talker.debug("entered init.doInitialConfigurations");

  // setup db
  await setupDb();
  // setup i18n
  await setupL10N();
  // setup app window
  await setupAppWindow();

  talker.debug("exited init.doInitialConfigurations successfully");
}

Future<void> setupDb() async {
  if (kDebugMode) {
    // create dummy entries
    final db = AppDatabase();
    if (!kIsWeb) {
      talker.debug(
        "setting up dummy db entries in ${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}$DB_NAME.sqlite",
      );
    } else {
      talker.debug("setting up dummy db entries in web storage");
    }

    final count = await db.profiles
        .count()
        .getSingle(); // Get the count of profiles in the database
    if (count == 0) {
      await db
          .into(db.profiles)
          .insert(ProfilesCompanion(username: Value("Debug Dummy")));
    }
    await db.close();
  }
}

Future<void> setupL10N() async {
  Intl.defaultLocale = await findSystemLocale();
  talker.debug("default locale set to ${Intl.defaultLocale}");
}

/// Apply window options only for desktop platforms
Future<void> setupAppWindow() async {
  if (!kIsWeb) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = WindowOptions(center: true);

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.maximize(); //TODO: Make it configurable
      await windowManager.show();
      await windowManager.focus();
    });
  }
}

void initializeSettings(WidgetRef ref) {
  // Load current profile
  ref.watch(currentProfileProvider);
  ref.watch(allProfilesProvider);
}
