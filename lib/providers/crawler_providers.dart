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

typedef CrawlerResponse = ({
  List<CrawlerResult> results,
  bool isFetching,
  bool hasSearched,
});

final _dio = getDioWithLogger();

@riverpod
class GetCrawlerResults extends _$GetCrawlerResults {
  CancelToken? _cancelToken;

  @override
  CrawlerResponse build() {
    ref.onDispose(() => _cancelToken?.cancel('Provider disposed'));
    return (results: <CrawlerResult>[], isFetching: false, hasSearched: false);
  }

  Future<void> fetch({required String title, required String number}) async {
    if (title.isEmpty || number.isEmpty) {
      state = (
        results: <CrawlerResult>[],
        isFetching: false,
        hasSearched: false,
      );
      return;
    }

    _cancelToken?.cancel('New fetch started');
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    state = (results: <CrawlerResult>[], isFetching: true, hasSearched: true);

    await Future.wait(
      CrawlerApi.crawlerConfigs.map(
        (config) => _crawlSingle(config, title, number, cancelToken),
      ),
    );

    if (!cancelToken.isCancelled) {
      state = (results: state.results, isFetching: false, hasSearched: true);
    }
  }

  Future<void> _crawlSingle(
    CrawlerConfig config,
    String title,
    String number,
    CancelToken cancelToken,
  ) async {
    try {
      final url = config.baseUrl
          .replaceAll("{title}", title)
          .replaceAll("{number}", number);

      final resp = await _dio.get(
        url,
        cancelToken: cancelToken,
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if (resp.statusCode == HttpStatus.ok && resp.data is String) {
        final rawHtml = resp.data as String;
        final parsed = await Isolate.run(
          () => CrawlerEngine(config).parseHtml(rawHtml: rawHtml),
        );

        if (!cancelToken.isCancelled && parsed.isNotEmpty) {
          state = (
            results: [...state.results, ...parsed],
            isFetching: true,
            hasSearched: true,
          );
        }
      }
    } catch (e, t) {
      if (!cancelToken.isCancelled) {
        talker.warning("crawler failed for ${config.name}", e, t);
      }
    }
  }

  void clearResult() {
    _cancelToken?.cancel('Cleared results');
    state = (results: <CrawlerResult>[], isFetching: false, hasSearched: false);
  }
}
