import 'package:html/parser.dart' as parser;
import 'package:komorebi/models/api/crawler_config.dart';
// 'package:html/dom.dart' not required directly; parser provides needed types.

class CrawlerEngine {
  final CrawlerConfig config;

  CrawlerEngine(this.config);

  List<CrawlerResult> parseHtml({required String rawHtml}) {
    if (!config.isActive || rawHtml.trim().isEmpty) return [];

    final document = parser.parse(rawHtml);
    final elements = document.querySelectorAll(config.itemSelector);
    if (elements.isEmpty) return [];

    // Pre-evaluate title and link selector matches once to avoid O(N^2) document re-queries
    final matchedTitleElements = document
        .querySelectorAll(config.titleSelector)
        .toSet();
    final matchedLinkElements = document
        .querySelectorAll(config.linkSelector)
        .toSet();

    final List<CrawlerResult> results = [];

    for (var element in elements) {
      final titleElement =
          element.querySelector(config.titleSelector) ??
          (matchedTitleElements.contains(element) ? element : null);
      final title = titleElement?.text.trim() ?? element.text.trim();

      final linkElement =
          element.querySelector(config.linkSelector) ??
          (matchedLinkElements.contains(element) ? element : null);

      String downloadUrl =
          linkElement?.attributes['href'] ??
          linkElement?.attributes['url'] ??
          '';

      if (downloadUrl.isEmpty && linkElement != null) {
        final linkText = linkElement.text.trim();
        if (linkText.isNotEmpty) {
          downloadUrl = linkText;
        } else if (linkElement.parent != null) {
          final nodes = linkElement.parent!.nodes;
          final index = nodes.indexOf(linkElement);
          if (index != -1 && index + 1 < nodes.length) {
            downloadUrl = nodes[index + 1].text?.trim() ?? '';
          }
        }
      }

      if (title.isNotEmpty || downloadUrl.isNotEmpty) {
        results.add(
          CrawlerResult(
            title: title,
            downloadUrl: downloadUrl,
            source: config.id,
          ),
        );
      }
    }

    return results;
  }
}
