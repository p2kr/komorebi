import 'package:html/parser.dart' as parser;
import 'package:komorebi/models/api/crawler_config.dart';
// 'package:html/dom.dart' not required directly; parser provides needed types.

class CrawlerEngine {
  final CrawlerConfig config;

  CrawlerEngine(this.config);

  List<CrawlerResult> parseHtml({required String rawHtml}) {
    final document = parser.parse(rawHtml);
    final List<CrawlerResult> results = [];

    final elements = document.querySelectorAll(config.itemSelector);
    for (var element in elements) {
      // package:html's Element doesn't provide `matches`, so fall back to
      // checking whether the document's selector result contains this element.
      var titleElement =
          element.querySelector(config.titleSelector) ??
          (document.querySelectorAll(config.titleSelector).contains(element)
              ? element
              : null);
      final title = titleElement?.text.trim() ?? element.text.trim();

      var linkElement =
          element.querySelector(config.linkSelector) ??
          (document.querySelectorAll(config.linkSelector).contains(element)
              ? element
              : null);
      final downloadUrl = linkElement?.attributes['href'] ?? '';

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
