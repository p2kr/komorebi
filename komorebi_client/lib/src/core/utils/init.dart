import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:app_links/app_links.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/find_locale.dart';
import 'package:intl/intl.dart';
import 'package:komorebi/src/core/providers/common_providers.dart';
import 'package:komorebi/src/core/services/crawler/crawler_api.dart';
import 'package:komorebi/src/core/services/database.dart';
import 'package:komorebi/src/core/utils/constants.dart';
import 'package:komorebi/src/core/utils/dio.dart';
import 'package:komorebi/src/core/utils/talker.dart';
import 'package:komorebi/src/features/local_collection/vault_providers.dart';
import 'package:komorebi/src/features/profile/profile_management_provider.dart';
import 'package:libtorrent_flutter/libtorrent_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:window_manager/window_manager.dart';
import 'package:windows_single_instance/windows_single_instance.dart';

final StreamController<Uri> deepLinkController =
    StreamController<Uri>.broadcast();

Future<void> doInitialConfigurations(List<String> args) async {
  talker.debug("entered init.doInitialConfigurations");

  // setup deep link
  setupDeepLinkStream();
  // setup single instance
  await setupSingleInstanceAndArgs(args);
  // setup db
  await setupDb();
  // setup i18n
  await setupL10N();
  // setup app window
  await setupAppWindow();
  // setup crawler configs
  await setupCrawler();
  // add additional licences to about section
  await setupAdditionalLicences();
  // setup libtorrent
  await setupLibtorrent();
  // setup media kit
  setupMediaKit();

  talker.debug("exited init.doInitialConfigurations successfully");
}

void setupMediaKit() {
  MediaKit.ensureInitialized();
}

/// Called in [HomePage]'s initState only.
void initializeSettings(WidgetRef ref) {
  // Load current profile
  ref.read(currentProfileProvider);
  ref.read(allProfilesProvider);

  // Load alternate tile settings
  ref.read(swapAlternateTitleProvider.notifier).load();

  // Initialize download queue
  ref.read(downloadQueueProvider);
}

/// Apply window options for desktop platforms
Future<void> setupAppWindow() async {
  await windowManager.ensureInitialized();
  try {
    await protocolHandler.register('komorebi');
    await protocolHandler.register('mal_viewer');
    talker.debug(
      "Registered custom protocol schemes: komorebi:// and mal_viewer://",
    );
  } catch (e, t) {
    talker.warning("Failed to register custom protocol schemes: ", e, t);
  }
  WindowOptions windowOptions = const WindowOptions(
    center: true,
    minimumSize: Size(800, 600),
  );

  await windowManager.waitUntilReadyToShow(windowOptions);
  await windowManager.show();
  await windowManager.center(animate: true);
  await windowManager.focus();
  await windowManager.maximize(); //TODO: Make it configurable
}

Future<void> setupDb() async {
  final db = AppDatabase();
  try {
    await db.vaultItemsDao.recoverOrphanedDownloads();
    talker.debug("recovered orphaned active downloads from previous sessions");
  } catch (e, stack) {
    talker.warning("failed during db startup recovery: ", e, stack);
  }
  await db.close();
}

Future<void> setupL10N() async {
  Intl.defaultLocale = await findSystemLocale();
  talker.debug("default locale set to ${Intl.defaultLocale}");
}

Future<void> setupSingleInstanceAndArgs(List<String> args) async {
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    try {
      await WindowsSingleInstance.ensureSingleInstance(
        args,
        "komorebi_app_instance_channel",
        onSecondWindow: (newArgs) async {
          talker.info("second instance attempted with args: $newArgs");
          if (newArgs.isNotEmpty) {
            for (final arg in newArgs) {
              _processAndAddDeepLink(arg, "WindowsSingleInstance");
            }
          }
          await windowManager.show();
          await windowManager.focus();
        },
      );
    } catch (e, stack) {
      talker.warning(
        "WindowsSingleInstance pipe creation failed (likely a background process is holding the handle): ",
        e,
        stack,
      );
    }
  }

  if (args.isNotEmpty) {
    for (final arg in args) {
      _processAndAddDeepLink(arg, "InitialArgs");
    }
  }
}

void setupDeepLinkStream() {
  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen((uri) {
    _processAndAddDeepLink(uri.toString(), "AppLinks");
  });
  protocolHandler.addListener(_DeepLinkProtocolListener());
}

void _processAndAddDeepLink(String rawInput, String source) {
  talker.info("Processing potential deep link from $source: $rawInput");
  var clean = rawInput.trim().replaceAll('"', '').replaceAll("'", "");
  String? uriString;
  if (clean.contains('komorebi://')) {
    uriString = clean.substring(clean.indexOf('komorebi://'));
  } else if (clean.contains('mal_viewer://')) {
    uriString = clean.substring(clean.indexOf('mal_viewer://'));
  }

  if (uriString != null) {
    try {
      final uri = Uri.parse(uriString);
      talker.info("Successfully parsed deep link URI ($source): $uri");
      deepLinkController.add(uri);
    } catch (e, stack) {
      talker.error(
        "Failed to parse deep link URI ($source): $uriString",
        e,
        stack,
      );
    }
  } else {
    talker.debug(
      "Input from $source did not contain custom deep link scheme: $rawInput",
    );
  }
}

class _DeepLinkProtocolListener extends ProtocolListener {
  @override
  void onProtocolUrlReceived(String url) {
    _processAndAddDeepLink(url, "ProtocolHandler");
  }
}

Future<void> setupCrawler() async {
  await CrawlerApi.loadConfigs();
}

Future<void> setupAdditionalLicences() async {
  Dio? dio;
  try {
    dio = getDioWithLogger();

    final anitomyLicenceResp = await dio.get(
      "https://raw.githubusercontent.com/erengy/anitomy/refs/heads/develop/LICENSE",
    );

    LicenseRegistry.addLicense(() async* {
      if (anitomyLicenceResp.statusCode == HttpStatus.ok) {
        final data =
            anitomyLicenceResp.data ?? "Mozilla Public License Version 2.0";
        yield LicenseEntryWithLineBreaks(["erengy/anitomy"], data);
      }
    });
  } catch (e, t) {
    talker.warning("error fetching licence for anitomy", e, t);
  } finally {
    dio?.close();
  }
}

Future<void> setupLibtorrent() async {
  String downloadDirectory = join(
    (await getApplicationSupportDirectory()).path,
    VAULT_LOC,
  );
  talker.debug("setting up vault at $downloadDirectory");
  await LibtorrentFlutter.init(defaultSavePath: downloadDirectory);
}
