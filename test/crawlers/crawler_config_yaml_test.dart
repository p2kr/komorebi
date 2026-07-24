import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:komorebi/models/api/crawler_config.dart';
import 'package:yaml/yaml.dart';

dynamic _convertNode(dynamic node) {
  if (node is YamlMap) {
    return node.map(
      (key, value) => MapEntry(key.toString(), _convertNode(value)),
    );
  } else if (node is YamlList) {
    return node.map((item) => _convertNode(item)).toList();
  }
  return node;
}

void main() {
  group('crawler_config.yaml Verification Tests', () {
    test(
      'crawler_config.yaml exists, is valid YAML, and deserializes correctly into CrawlerConfig',
      () {
        final file = File('assets/configs/crawler_config.yaml');
        expect(
          file.existsSync(),
          isTrue,
          reason: 'assets/configs/crawler_config.yaml should exist',
        );

        final yamlString = file.readAsStringSync();
        final yaml = loadYaml(yamlString);
        expect(
          yaml,
          isA<YamlMap>(),
          reason: 'Root YAML element should be a map',
        );

        final dartMap = _convertNode(yaml) as Map<String, dynamic>;
        expect(
          dartMap,
          isNotEmpty,
          reason: 'crawler_config.yaml should not be empty',
        );

        final parsedConfigs = <String, CrawlerConfig>{};

        for (final entry in dartMap.entries) {
          final configMap = Map<String, dynamic>.from(entry.value as Map);
          configMap['id'] = entry.key;

          final config = CrawlerConfig.fromJson(configMap);
          parsedConfigs[entry.key] = config;

          expect(config.id, equals(entry.key));
          expect(config.name.trim(), isNotEmpty);
          expect(config.baseUrl.trim(), isNotEmpty);
          expect(config.itemSelector.trim(), isNotEmpty);
          expect(config.titleSelector.trim(), isNotEmpty);
          expect(config.linkSelector.trim(), isNotEmpty);
        }

        expect(parsedConfigs.containsKey('nyaa'), isTrue);
        expect(parsedConfigs.containsKey('animetosho'), isTrue);
        expect(parsedConfigs.containsKey('tokyotosho'), isTrue);
        expect(parsedConfigs.containsKey('subsplease'), isTrue);
        expect(parsedConfigs.containsKey('erairaws'), isTrue);
      },
    );
  });
}
