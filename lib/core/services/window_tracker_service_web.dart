import 'dart:async';
import 'window_info.dart';

/// Stub para Web — dart:ffi no disponible en el navegador.
/// El rastreo automático no es posible desde un contexto web.
class WindowTrackerService {
  Stream<WindowInfo?> get onWindowChange => const Stream.empty();

  void init() {}
  void start() {}
  void stop() {}
  WindowInfo? currentWindow() => null;
}
