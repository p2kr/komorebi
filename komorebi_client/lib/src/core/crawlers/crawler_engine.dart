import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:komorebi/src/core/crawlers/crawler_parser.dart';
import 'package:komorebi/src/core/crawlers/html_crawler_parser.dart';
import 'package:komorebi/src/core/crawlers/json_crawler_parser.dart';
import 'package:komorebi/src/models/api/crawler_config.dart';
import 'package:komorebi/src/core/services/title_parser_service.dart';

@immutable
class CrawlerEngine {
  final CrawlerConfig config;
  final List<CrawlerParser> _parsers;
  final TitleParserService _titleParser;

  CrawlerEngine(
    this.config, {
    List<CrawlerParser>? parsers,
    TitleParserService? titleParser,
  }) : _parsers = parsers ?? [JsonCrawlerParser(), HtmlCrawlerParser()],
       _titleParser = titleParser ?? TitleParserService.instance;

  Future<List<CrawlerResult>> parse({required String rawHtml}) async {
    if (!config.isActive || rawHtml.trim().isEmpty) return [];

    for (final parser in _parsers) {
      if (parser.canParse(rawHtml, config)) {
        final results = parser.parse(content: rawHtml, config: config);
        if (results.isNotEmpty ||
            config.itemSelector.toLowerCase() ==
                CrawlerParserUtils.jsonSelector) {
          return await enrichWithParsedTitles(results);
        }
      }
    }

    return [];
  }

  Future<List<CrawlerResult>> enrichWithParsedTitles(
    List<CrawlerResult> results,
  ) {
    return Future.wait(
      results.map((res) async {
        if (res.parsedTitle != null) return res;
        return res.copyWith(
          parsedTitle: await _titleParser.parseTitle(res.title),
        );
      }),
    );
  }
}
