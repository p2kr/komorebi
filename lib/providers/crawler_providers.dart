import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:komorebi/crawlers/crawler_engine.dart';
import 'package:komorebi/models/api/crawler_config.dart';
import 'package:komorebi/services/crawler/crawler_api.dart';
import 'package:komorebi/services/title_parser_service.dart';
import 'package:komorebi/utils/dio.dart';
import 'package:komorebi/utils/search_ranker.dart';
import 'package:komorebi/utils/talker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part "crawler_providers.g.dart";

typedef CrawlerResponse = ({
  List<CrawlerResult> results,
  bool isFetching,
  bool hasSearched,
  String rawQuery,
});

final _dio = getDioWithLogger();

@riverpod
class GetCrawlerResults extends _$GetCrawlerResults {
  CancelToken? _cancelToken;

  @override
  CrawlerResponse build() {
    ref.onDispose(() => _cancelToken?.cancel('Provider disposed'));
    return (
      results: <CrawlerResult>[],
      isFetching: false,
      hasSearched: false,
      rawQuery: "",
    );
  }

  Future<void> fetch({required String title}) async {
    if (title.isEmpty) {
      state = (
        results: <CrawlerResult>[],
        isFetching: false,
        hasSearched: false,
        rawQuery: title,
      );
      return;
    }

    _cancelToken?.cancel('New fetch started');
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    state = (
      results: <CrawlerResult>[],
      isFetching: true,
      hasSearched: true,
      rawQuery: title,
    );

    await Future.wait(
      CrawlerApi.crawlerConfigs.map(
        (config) => _crawlSingle(config, title, cancelToken),
      ),
    );

    if (!cancelToken.isCancelled) {
      final ranked = await SearchRanker.rankResults(
        query: title,
        results: state.results,
        configs: CrawlerApi.crawlerConfigs,
      );
      if (!cancelToken.isCancelled) {
        state = (
          results: ranked,
          isFetching: false,
          hasSearched: true,
          rawQuery: title,
        );
      }
    }
  }

  Future<void> _crawlSingle(
    CrawlerConfig config,
    String title,
    CancelToken cancelToken,
  ) async {
    try {
      final url = config.baseUrl
          .replaceAll("{title}", title)
          .replaceAll("+{number}", "")
          .replaceAll("{number}", "");

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
          () => CrawlerEngine(config).parse(rawHtml: rawHtml),
        );

        if (!cancelToken.isCancelled && parsed.isNotEmpty) {
          final withAnitomy = await TitleParserService.instance.parseAndAttach(
            parsed,
          );
          final combined = [...state.results, ...withAnitomy];
          final ranked = await SearchRanker.rankResults(
            query: title,
            results: combined,
            configs: CrawlerApi.crawlerConfigs,
          );

          if (!cancelToken.isCancelled) {
            state = (
              results: ranked,
              isFetching: true,
              hasSearched: true,
              rawQuery: title,
            );
          }
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
    state = (
      results: <CrawlerResult>[],
      isFetching: false,
      hasSearched: false,
      rawQuery: "",
    );
  }
}
