import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Actividad reportada por la extensión de navegador
class BrowserActivity {
  final String url;
  final String? title;
  const BrowserActivity({required this.url, this.title});
}

/// Servidor HTTP local en localhost:27432 para recibir URLs desde la extensión
/// de Chrome/Firefox.
///
/// Endpoints:
///   GET  /status    → {"status": "running", "port": 27432}
///   POST /activity  → body: {"url": "...", "title": "...", "favicon": "..."}
class BrowserExtensionServer {
  static const port = 27432;

  final _controller = StreamController<BrowserActivity>.broadcast();
  HttpServer? _server;

  Stream<BrowserActivity> get activities => _controller.stream;

  Future<void> start() async {
    if (_server != null) return;
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      _serve(_server!);
    } catch (_) {
      // Puerto ocupado u otro error — ignorar silenciosamente
    }
  }

  void stop() {
    _server?.close(force: true);
    _server = null;
  }

  Future<void> _serve(HttpServer server) async {
    await for (final req in server) {
      _handleRequest(req);
    }
  }

  Future<void> _handleRequest(HttpRequest req) async {
    // CORS — permite llamadas desde cualquier extensión de navegador
    req.response.headers
      ..add('Access-Control-Allow-Origin', '*')
      ..add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
      ..add('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method == 'OPTIONS') {
      req.response.statusCode = HttpStatus.ok;
      await req.response.close();
      return;
    }

    final path = req.uri.path;

    if (req.method == 'GET' && path == '/status') {
      req.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json;
      req.response.write(jsonEncode({'status': 'running', 'port': port}));
      await req.response.close();
      return;
    }

    if (req.method == 'POST' && path == '/activity') {
      try {
        final body = await utf8.decoder.bind(req).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final url = (json['url'] as String?)?.trim() ?? '';
        final title = json['title'] as String?;
        if (url.isNotEmpty && Uri.tryParse(url) != null) {
          _controller.add(BrowserActivity(url: url, title: title));
        }
        req.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json;
        req.response.write(jsonEncode({'ok': true}));
      } catch (_) {
        req.response.statusCode = HttpStatus.badRequest;
      }
      await req.response.close();
      return;
    }

    req.response.statusCode = HttpStatus.notFound;
    await req.response.close();
  }
}
