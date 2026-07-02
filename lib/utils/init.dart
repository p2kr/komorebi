import 'dart:io';

import 'package:intl/intl.dart';
import 'package:komorebi/utils/talker.dart';

import 'package:window_manager/window_manager.dart';

Future<void> doInitialConfigurations() async {
  talker.debug("entered init.doInitialConfigurations");

  // setup db
  setupDb();
  // setup i18n
  setupI18N();
  // setup app window
  await setupAppWindow();

  talker.debug("exited init.doInitialConfigurations successfully");
}

void setupDb() {
  //TODO: Nothing to add yet
}

void setupI18N() {
  Intl.defaultLocale = 'en_US';
}

Future<void> setupAppWindow() async {
  await windowManager.ensureInitialized();
  // Apply window options only for desktop platforms
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    WindowOptions windowOptions = WindowOptions(center: true);

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.maximize(); //TODO: Make it configurable
      await windowManager.show();
      await windowManager.focus();
    });
  }
}
