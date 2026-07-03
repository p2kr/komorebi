import 'dart:convert';
import 'dart:io';
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'package:komorebi/utils/talker.dart';

class LocalAdblockProxy {
  HttpServer? _server;
  final int port = 3001;

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    talker.debug("Embedded Adblock Proxy Server listening on http://localhost:$port");

    _server!.listen((HttpRequest request) async {
      if (request.uri.path == '/proxy') {
        final targetUrl = request.uri.queryParameters['url'];
        if (targetUrl == null) {
          request.response
            ..statusCode = HttpStatus.badRequest
            ..write('Error: Query parameter "url" is required.')
            ..close();
          return;
        }

        try {
          final client = HttpClient();
          final targetReq = await client.getUrl(Uri.parse(targetUrl));
          targetReq.headers.set(HttpHeaders.userAgentHeader,
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36");

          final targetRes = await targetReq.close();

          if (targetRes.headers.contentType?.mimeType == 'text/html') {
            final rawHtml = await targetRes.transform(utf8.decoder).join();
            final sanitizedHtml = _sanitizeHtml(rawHtml, targetUrl);

            request.response
              ..headers.contentType = ContentType.html
              ..write(sanitizedHtml)
              ..close();
          } else {
            request.response.redirect(Uri.parse(targetUrl));
          }
        } catch (e) {
          request.response
            ..statusCode = HttpStatus.internalServerError
            ..write('Adblock Proxy Error: $e')
            ..close();
        }
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Not Found')
          ..close();
      }
    });
  }

  String _sanitizeHtml(String htmlContent, String targetUrl) {
    final document = parser.parse(htmlContent);

    // 1. Remove all javascript elements
    document.querySelectorAll('script').forEach((el) => el.remove());

    // 2. Remove frames linked to standard advertising hosts
    document.querySelectorAll('iframe').forEach((el) {
      final src = (el.attributes['src'] ?? '').toLowerCase();
      if (src.contains('ads') || src.contains('pop') || src.contains('click') || src.contains('banner')) {
        el.remove();
      }
    });

    // 3. Purge element nodes matching ad-selectors
    final adSelectors = [
      '.adsbygoogle', '.ad-banner', '.banner-ad', '#banner-ad',
      '#ads', '.ads', '[class*="popunder"]', '.native-ads'
    ];
    for (var selector in adSelectors) {
      document.querySelectorAll(selector).forEach((el) => el.remove());
    }

    // 4. Inject Sandboxing Header
    final body = document.querySelector('body');
    if (body != null) {
      final banner = Element.html('''
        <div id="komorebi-proxy-header" style="
          background: #0f172a;
          color: #2dd4bf;
          font-family: system-ui, -apple-system, sans-serif;
          padding: 10px 16px;
          border-bottom: 2px solid #2dd4bf;
          display: flex;
          align-items: center;
          justify-content: space-between;
          font-size: 13px;
          position: sticky;
          top: 0;
          z-index: 9999999;
        ">
          <div><strong>Komorebi Desktop Proxy:</strong> Viewing <span style="color: #94a3b8;">$targetUrl</span></div>
          <div style="background: rgba(45, 212, 191, 0.15); padding: 4px 8px; border-radius: 4px; font-weight: 500;">
            ⚡ Sandboxed Mode Active
          </div>
        </div>
      ''');
      body.nodes.insert(0, banner);
    }

    return document.outerHtml;
  }

  Future<void> stop() async {
    await _server?.close(force: true);
  }
}