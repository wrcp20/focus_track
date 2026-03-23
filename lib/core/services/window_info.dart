/// Información de la ventana activa en un momento dado
class WindowInfo {
  final String appName;
  final String? windowTitle;
  final String? executablePath;

  const WindowInfo({
    required this.appName,
    this.windowTitle,
    this.executablePath,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WindowInfo &&
          appName == other.appName &&
          windowTitle == other.windowTitle;

  @override
  int get hashCode => Object.hash(appName, windowTitle);

  @override
  String toString() => 'WindowInfo($appName | $windowTitle)';
}
