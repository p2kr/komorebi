import 'dart:io';

import 'package:dio/dio.dart';
import 'package:komorebi/crawlers/crawler_engine.dart';
import 'package:komorebi/models/api/crawler_config.dart';
import 'package:komorebi/services/crawler/crawler_api.dart';
import 'package:komorebi/utils/dio.dart';
import 'package:komorebi/utils/talker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part "crawler_providers.g.dart";

@riverpod
Future<List<CrawlerResult>> getCrawlerResults(
  Ref ref, [
  String? title,
  String? number,
]) async {
  if (title == null || number == null || title.isEmpty || number.isEmpty) {
    return [];
  }

  Dio? dio;
  final List<CrawlerResult> crawlerResults = [];

  try {
    dio = getDioWithLogger();

    final futures = CrawlerApi.crawlerConfigs.map((config) async {
      try {
        final url = config.baseUrl
            .replaceAll("{title}", title)
            .replaceAll("{number}", number);
        final resp = await dio!.get(url);

        if (resp.statusCode == HttpStatus.ok) {
          final engine = CrawlerEngine(config);
          // Directly adding to the shared list here:
          crawlerResults.addAll(engine.parseHtml(rawHtml: resp.data));
        }
      } catch (e, t) {
        talker.warning("crawler failed for ${config.name}", e, t);
      }
    });

    // We still have to wait for all the tasks to finish before returning
    await Future.wait(futures);
  } finally {
    dio?.close();
  }

  return crawlerResults;
}
