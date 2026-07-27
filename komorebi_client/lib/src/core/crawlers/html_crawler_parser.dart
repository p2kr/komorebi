import 'package:html/dom.dart';
import 'package:html/parser.dart' as parser;
import 'package:komorebi/src/core/crawlers/crawler_parser.dart';
import 'package:komorebi/src/models/api/crawler_config.dart';

class HtmlCrawlerParser implements CrawlerParser {
  @override
  bool canParse(String content, CrawlerConfig config) => true;

  Element? _selectElement(Element element, String selector) {
    if (selector.isEmpty) return null;

    try {
      final found = element.querySelector(selector);
      if (found != null) return found;
    } catch (_) {}

    final nthMatch = RegExp(
      r':nth-(?:child|of-type)\((\d+)\)',
    ).firstMatch(selector);
    if (nthMatch != null) {
      final index = int.tryParse(nthMatch.group(1) ?? '');
      if (index != null && index > 0 && index <= element.children.length) {
        return element.children[index - 1];
      }
    }

    return null;
  }

  @override
  List<CrawlerResult> parse({
    required String content,
    required CrawlerConfig config,
  }) {
    try {
      final document = parser.parse(content);
      final elements = document.querySelectorAll(config.itemSelector);
      if (elements.isEmpty) return [];

      final matchedTitleElements = config.titleSelector.isNotEmpty
          ? document.querySelectorAll(config.titleSelector).toSet()
          : <dynamic>{};
      final matchedLinkElements = config.linkSelector.isNotEmpty
          ? document.querySelectorAll(config.linkSelector).toSet()
          : <dynamic>{};

      final List<CrawlerResult> results = [];

      for (var element in elements) {
        try {
          final titleElement = config.titleSelector.isNotEmpty
              ? (_selectElement(element, config.titleSelector) ??
                    (matchedTitleElements.contains(element) ? element : null))
              : null;

          final rawTitle =
              (titleElement?.attributes['title']?.isNotEmpty == true)
                  ? titleElement!.attributes['title']!
                  : (titleElement?.text ?? element.text);
          final title = CrawlerParserUtils.cleanString(rawTitle);

          final linkElement = config.linkSelector.isNotEmpty
              ? (_selectElement(element, config.linkSelector) ??
                    (matchedLinkElements.contains(element) ? element : null))
              : null;

          String downloadUrl =
              linkElement?.attributes[CrawlerParserUtils.hrefAttr] ??
              linkElement?.attributes[CrawlerParserUtils.urlAttr] ??
              '';

          if (downloadUrl.isEmpty && linkElement != null) {
            final linkText = CrawlerParserUtils.cleanString(linkElement.text);
            if (linkText.isNotEmpty) {
              downloadUrl = linkText;
            } else if (linkElement.parent != null) {
              final nodes = linkElement.parent!.nodes;
              final index = nodes.indexOf(linkElement);
              if (index != -1 && index + 1 < nodes.length) {
                downloadUrl = CrawlerParserUtils.cleanString(
                  nodes[index + 1].text,
                );
              }
            }
          }

          if (downloadUrl.isNotEmpty && config.baseUrl.isNotEmpty) {
            try {
              final baseUri = Uri.parse(config.baseUrl);
              if (!downloadUrl.startsWith(CrawlerParserUtils.magnetPrefix) &&
                  !downloadUrl.startsWith(CrawlerParserUtils.httpPrefix) &&
                  !downloadUrl.startsWith(CrawlerParserUtils.httpsPrefix)) {
                downloadUrl = baseUri.resolve(downloadUrl).toString();
              }
            } catch (_) {}
          }

          double popularity = 0;
          if (config.popularitySelector != null &&
              config.popularitySelector!.isNotEmpty) {
            final popElement = _selectElement(
              element,
              config.popularitySelector!,
            );
            popularity =
                CrawlerParserUtils.parsePopularity(popElement?.text) ?? 0;
          }

          String? size;
          if (config.sizeSelector != null && config.sizeSelector!.isNotEmpty) {
            final sizeElement = _selectElement(element, config.sizeSelector!);
            final rawSize = CrawlerParserUtils.cleanString(sizeElement?.text);
            if (rawSize.isNotEmpty) {
              size = rawSize;
            }
          }

          if (title.isNotEmpty || downloadUrl.isNotEmpty) {
            results.add(
              CrawlerResult(
                title: title,
                downloadUrl: downloadUrl,
                source: config.id,
                popularity: popularity,
                size: size,
              ),
            );
          }
        } catch (_) {
          // Swallow per-item errors to allow remaining items to parse
        }
      }

      return results;
    } catch (_) {
      return [];
    }
  }
}
