// Exportación condicional:
// - Web          → stub vacío (sin FFI)
// - Windows/Desktop → implementación nativa Win32 FFI
export 'window_tracker_service_web.dart'
    if (dart.library.ffi) 'window_tracker_service_native.dart';
