import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:komorebi/models/api/crawler_config.dart';
import 'package:komorebi/utils/talker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:retry/retry.dart';
import 'package:yaml/yaml.dart';

abstract class CrawlerApi {
  static const configPath = "assets/configs/crawler_config.yaml";

  static final List<CrawlerConfig> crawlerConfigs = [];

  /// Ensures the asset is copied to the destination file if it doesn't exist
  static Future<void> _ensureAssetCopied(File destinationFile) async {
    if (await destinationFile.exists() &&
        await destinationFile.length() > 0 &&
        !kDebugMode) {
      talker.debug("crawler config file already exists");
      return;
    }

    final configBytes = await rootBundle.load(configPath);
    final bytes = configBytes.buffer.asUint8List(
      configBytes.offsetInBytes,
      configBytes.lengthInBytes,
    );

    // Write to a temporary file first
    final tempFile = File('${destinationFile.path}.tmp');
    await tempFile.writeAsBytes(bytes, flush: true);
    // Atomic renaming
    await tempFile.rename(destinationFile.path);
  }

  /// Loads crawler configurations from the bundled YAML asset into memory.
  ///
  /// This method ensures the bundled asset at [configPath] is copied into the
  /// application's support directory (so the file can be read and re-written
  /// later). It then reads the YAML file, converts it to native Dart maps/lists
  /// and constructs `CrawlerConfig` objects which are stored in the
  /// static [crawlerConfigs] list.
  ///
  /// Behavior notes:
  /// - A `retry` wrapper is used with up to 2 attempts. If the first attempt
  ///   fails, the `onRetry` callback will log an error and delete the local
  ///   file so the asset can be recopied from the bundle on the next attempt.
  /// - Any fatal errors that escape the retry loop are logged via `talker.error`
  ///   but not rethrown here.
  ///
  /// Important: this must be called only after Flutter bindings are
  /// initialized (so `rootBundle` and `getApplicationSupportDirectory` are
  /// available), e.g. from an async initialization routine in the app.
  static Future<void> loadConfigs() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File(join(dir.path, basename(configPath)));

      await retry(
        () async {
          await _ensureAssetCopied(file);

          final yamlString = await file.readAsString();
          final YamlMap yaml = loadYaml(yamlString);
          final dartMap = _convertNode(yaml) as Map<String, dynamic>;

          crawlerConfigs.clear();

          for (var entry in dartMap.entries) {
            entry.value['id'] = entry.key;
            crawlerConfigs.add(CrawlerConfig.fromJson(entry.value));
          }
        },
        maxAttempts: 2,
        delayFactor: const Duration(milliseconds: 100),
        onRetry: (e) async {
          talker.error(
            "error loading config, wiping local file and retrying...",
            e,
          );

          if (await file.exists()) {
            await file.delete();
          }
        },
      );
    } catch (e, t) {
      talker.error(
        "critical error: unable to load or reinit crawler configuration",
        e,
        t,
      );
    }
  }
}

// Recursive deep conversion for both Maps and Lists
dynamic _convertNode(dynamic node) {
  if (node is YamlMap) {
    return node.map((key, value) {
      return MapEntry(key.toString(), _convertNode(value));
    });
  } else if (node is YamlList) {
    return node.map((item) => _convertNode(item)).toList();
  }
  return node;
}
