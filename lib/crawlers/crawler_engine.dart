import 'package:komorebi/crawlers/crawler_parser.dart';
import 'package:komorebi/crawlers/html_crawler_parser.dart';
import 'package:komorebi/crawlers/json_crawler_parser.dart';
import 'package:komorebi/models/api/crawler_config.dart';

class CrawlerEngine {
  final CrawlerConfig config;
  final List<CrawlerParser> _parsers;

  CrawlerEngine(this.config, {List<CrawlerParser>? parsers})
    : _parsers = parsers ?? [JsonCrawlerParser(), HtmlCrawlerParser()];

  List<CrawlerResult> parse({required String rawHtml}) {
    if (!config.isActive || rawHtml.trim().isEmpty) return [];

    for (final parser in _parsers) {
      if (parser.canParse(rawHtml, config)) {
        final results = parser.parse(content: rawHtml, config: config);
        if (results.isNotEmpty ||
            config.itemSelector.toLowerCase() ==
                CrawlerParserUtils.jsonSelector) {
          return results;
        }
      }
    }

    return [];
  }
}
