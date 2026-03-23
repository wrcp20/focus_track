// Exportación condicional:
// - Web  → stub vacío (flutter_local_notifications no soporta web)
// - Desktop/Mobile → implementación nativa
export 'notification_service_web.dart'
    if (dart.library.io) 'notification_service_native.dart';
