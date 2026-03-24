import 'dart:async';

/// Actividad reportada por la extensión de navegador
class BrowserActivity {
  final String url;
  final String? title;
  const BrowserActivity({required this.url, this.title});
}

/// Stub para web — no hay servidor HTTP local
class BrowserExtensionServer {
  Stream<BrowserActivity> get activities => const Stream.empty();
  Future<void> start() async {}
  void stop() {}
}
