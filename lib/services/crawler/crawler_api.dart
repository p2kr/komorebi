import 'dart:io';

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
    if (await destinationFile.exists() && await destinationFile.length() > 0) {
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
