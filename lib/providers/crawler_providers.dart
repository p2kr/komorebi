import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:komorebi/crawlers/crawler_engine.dart';
import 'package:komorebi/models/api/crawler_config.dart';
import 'package:komorebi/services/crawler/crawler_api.dart';
import 'package:komorebi/utils/dio.dart';
import 'package:komorebi/utils/talker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part "crawler_providers.g.dart";

typedef CrawlerResponse = ({List<CrawlerResult> results, bool isFetching});

final _dio = getDioWithLogger();

@riverpod
Stream<CrawlerResponse> getCrawlerResults(
  Ref ref, [
  String? title,
  String? number,
    ]) {
  if (title == null || number == null || title.isEmpty || number.isEmpty) {
    return Stream.value((results: <CrawlerResult>[], isFetching: false));
  }

  final cancelToken = CancelToken();
  ref.onDispose(() => cancelToken.cancel('Provider disposed'));

  final controller = StreamController<CrawlerResponse>();
  final List<CrawlerResult> accumulatedResults = [];

  controller.add((results: accumulatedResults, isFetching: true));

  int pending = CrawlerApi.crawlerConfigs.length;
  if (pending == 0) {
    controller.add((results: accumulatedResults, isFetching: false));
    controller.close();
    return controller.stream;
  }

  for (final config in CrawlerApi.crawlerConfigs) {
    Future(() async {
      try {
        final url = config.baseUrl
            .replaceAll("{title}", title)
            .replaceAll("{number}", number);

        final resp = await _dio.get(url, cancelToken: cancelToken);

        if (resp.statusCode == HttpStatus.ok) {
          final data = resp.data as String;
          // Parse HTML in a background isolate
          final parsed = await Isolate.run(() {
            final engine = CrawlerEngine(config);
            return engine.parseHtml(rawHtml: data);
          });

          accumulatedResults.addAll(parsed);
          // Yield the new results to the stream
          if (!controller.isClosed) {
            controller.add(
                (results: List.of(accumulatedResults), isFetching: true));
          }
        }
      } catch (e, t) {
        if (!cancelToken.isCancelled) {
          talker.warning("crawler failed for ${config.name}", e, t);
        }
      } finally {
        pending--;
        if (pending == 0 && !controller.isClosed) {
          controller.add((results: accumulatedResults, isFetching: false));
          controller.close();
        }
      }
    });
  }

  return controller.stream;
}
