// Exportación condicional:
// - Web  → stub vacío (dart:io no disponible en web)
// - Desktop/Native → servidor HTTP local para extensión de navegador
export 'browser_extension_server_web.dart'
    if (dart.library.io) 'browser_extension_server_native.dart';
