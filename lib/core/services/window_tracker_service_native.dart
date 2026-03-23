import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'window_info.dart';

// ─── Win32 FFI typedefs ────────────────────────────────────────────────────

typedef _GetFgWinNative = IntPtr Function();
typedef _GetFgWinDart   = int    Function();

typedef _GetWinTextNative = Int32 Function(IntPtr, Pointer<Utf16>, Int32);
typedef _GetWinTextDart   = int   Function(int,   Pointer<Utf16>, int);

typedef _GetPidNative = Uint32 Function(IntPtr, Pointer<Uint32>);
typedef _GetPidDart   = int    Function(int,   Pointer<Uint32>);

typedef _OpenProcessNative = IntPtr Function(Uint32, Bool, Uint32);
typedef _OpenProcessDart   = int    Function(int,   bool, int);

typedef _QueryImageNative = Bool Function(IntPtr, Uint32, Pointer<Utf16>, Pointer<Uint32>);
typedef _QueryImageDart   = bool Function(int,   int,   Pointer<Utf16>, Pointer<Uint32>);

typedef _CloseHandleNative = Bool Function(IntPtr);
typedef _CloseHandleDart   = bool Function(int);

// ─── WindowTrackerService ──────────────────────────────────────────────────

/// Rastrea la ventana activa del sistema usando Win32 FFI (solo Windows).
/// En Web devuelve null — no hay acceso al sistema de archivos del OS.
class WindowTrackerService {
  static const _pollInterval = Duration(seconds: 5);

  _GetFgWinDart?   _getForegroundWindow;
  _GetWinTextDart? _getWindowText;
  _GetPidDart?     _getWindowThreadProcessId;
  _OpenProcessDart?  _openProcess;
  _QueryImageDart?   _queryFullProcessImageName;
  _CloseHandleDart?  _closeHandle;

  StreamController<WindowInfo?>? _controller;
  Timer? _timer;
  WindowInfo? _lastInfo;
  bool _initialized = false;

  Stream<WindowInfo?> get onWindowChange =>
      _controller?.stream ?? const Stream.empty();

  void init() {
    if (kIsWeb || _initialized) return;
    try {
      final user32   = DynamicLibrary.open('user32.dll');
      final kernel32 = DynamicLibrary.open('kernel32.dll');

      _getForegroundWindow = user32
          .lookupFunction<_GetFgWinNative, _GetFgWinDart>('GetForegroundWindow');
      _getWindowText = user32
          .lookupFunction<_GetWinTextNative, _GetWinTextDart>('GetWindowTextW');
      _getWindowThreadProcessId = user32
          .lookupFunction<_GetPidNative, _GetPidDart>('GetWindowThreadProcessId');
      _openProcess = kernel32
          .lookupFunction<_OpenProcessNative, _OpenProcessDart>('OpenProcess');
      _queryFullProcessImageName = kernel32
          .lookupFunction<_QueryImageNative, _QueryImageDart>('QueryFullProcessImageNameW');
      _closeHandle = kernel32
          .lookupFunction<_CloseHandleNative, _CloseHandleDart>('CloseHandle');

      _initialized = true;
    } catch (e) {
      debugPrint('[WindowTracker] Error cargando Win32: $e');
    }
  }

  void start() {
    if (kIsWeb) return;
    if (!_initialized) init();
    _controller = StreamController<WindowInfo?>.broadcast();
    _timer = Timer.periodic(_pollInterval, (_) => _poll());
    _poll();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _controller?.close();
    _controller = null;
    _lastInfo = null;
  }

  WindowInfo? currentWindow() {
    if (kIsWeb || !_initialized) return null;
    return _readActiveWindow();
  }

  void _poll() {
    final info = _readActiveWindow();
    if (info != _lastInfo) {
      _lastInfo = info;
      _controller?.add(info);
    }
  }

  WindowInfo? _readActiveWindow() {
    if (_getForegroundWindow == null) return null;

    final hwnd = _getForegroundWindow!();
    if (hwnd == 0) return null;

    // ── Título de ventana ─────────────────────────────────────────────────
    // Utf16 no es SizedNativeType: asignamos Uint16 y casteamos a Pointer<Utf16>
    String? title;
    final titleBuf = calloc<Uint16>(512);
    try {
      final len = _getWindowText!(hwnd, titleBuf.cast<Utf16>(), 512);
      if (len > 0) title = titleBuf.cast<Utf16>().toDartString(length: len);
    } finally {
      calloc.free(titleBuf);
    }

    // ── PID del proceso ───────────────────────────────────────────────────
    final pidPtr = calloc<Uint32>();
    int pid = 0;
    try {
      _getWindowThreadProcessId!(hwnd, pidPtr);
      pid = pidPtr.value;
    } finally {
      calloc.free(pidPtr);
    }
    if (pid == 0) return null;

    // ── Ruta del ejecutable ───────────────────────────────────────────────
    String? execPath;
    // PROCESS_QUERY_LIMITED_INFORMATION = 0x1000
    final hProcess = _openProcess!(0x1000, false, pid);
    if (hProcess != 0) {
      final pathBuf   = calloc<Uint16>(1024);
      final sizePtr   = calloc<Uint32>();
      sizePtr.value   = 1024;
      try {
        final ok = _queryFullProcessImageName!(
            hProcess, 0, pathBuf.cast<Utf16>(), sizePtr);
        if (ok) execPath = pathBuf.cast<Utf16>().toDartString(length: sizePtr.value);
      } finally {
        calloc.free(pathBuf);
        calloc.free(sizePtr);
        _closeHandle!(hProcess);
      }
    }

    final appName = _appNameFromPath(execPath) ??
        _appNameFromTitle(title) ??
        'Desconocido';

    return WindowInfo(
      appName: appName,
      windowTitle: title,
      executablePath: execPath,
    );
  }

  String? _appNameFromPath(String? path) {
    if (path == null || path.isEmpty) return null;
    final parts = path.replaceAll('\\', '/').split('/');
    final exe   = parts.last;
    final name  = exe.contains('.')
        ? exe.substring(0, exe.lastIndexOf('.'))
        : exe;
    return name.isEmpty ? null : _capitalize(name);
  }

  String? _appNameFromTitle(String? title) {
    if (title == null || title.isEmpty) return null;
    final parts = title.split(' - ');
    return parts.last.trim().isEmpty ? null : parts.last.trim();
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
