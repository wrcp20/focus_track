import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Implementación nativa de notificaciones del sistema (Windows Desktop)
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        windows: WindowsInitializationSettings(
          appName: 'FocusTrack',
          appUserModelId: 'com.focustrack.app',
          guid: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        ),
      ),
    );
    _initialized = true;
  }

  Future<void> showFocusComplete(int minutes) async {
    await init();
    await _plugin.show(
      id: 1,
      title: 'Sesión de foco completada',
      body: 'Completaste $minutes minutos de foco. ¡Tómate un descanso!',
      notificationDetails:
          const NotificationDetails(windows: WindowsNotificationDetails()),
    );
  }

  Future<void> showBreakReminder() async {
    await init();
    await _plugin.show(
      id: 2,
      title: 'Fin del descanso',
      body: '¡Es hora de volver al foco!',
      notificationDetails:
          const NotificationDetails(windows: WindowsNotificationDetails()),
    );
  }
}
