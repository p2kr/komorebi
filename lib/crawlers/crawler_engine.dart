import 'package:html/parser.dart' as parser;
// 'package:html/dom.dart' not required directly; parser provides needed types.

class CrawledItem {
  final String title;
  final String downloadUrl;

  CrawledItem({required this.title, required this.downloadUrl});
}

class CrawlerEngine {
  List<CrawledItem> parseHtml({
    required String rawHtml,
    required String itemSelector,
    required String titleSelector,
    required String linkSelector,
  }) {
    final document = parser.parse(rawHtml);
    final List<CrawledItem> results = [];

    final elements = document.querySelectorAll(itemSelector);
    for (var element in elements) {
      // package:html's Element doesn't provide `matches`, so fall back to
      // checking whether the document's selector result contains this element.
      var titleElement = element.querySelector(titleSelector) ??
          (document.querySelectorAll(titleSelector).contains(element)
              ? element
              : null);
      final title = titleElement?.text.trim() ?? element.text.trim();

      var linkElement = element.querySelector(linkSelector) ??
          (document.querySelectorAll(linkSelector).contains(element)
              ? element
              : null);
      final downloadUrl = linkElement?.attributes['href'] ?? '';

      if (title.isNotEmpty || downloadUrl.isNotEmpty) {
        results.add(CrawledItem(title: title, downloadUrl: downloadUrl));
      }
    }

    return results;
  }
}