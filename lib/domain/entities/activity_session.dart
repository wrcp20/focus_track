class ActivitySession {
  final int? id;
  final String appName;
  final String? windowTitle;
  final String? url;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationSec;
  final int? categoryId;
  final bool isProductive;

  const ActivitySession({
    this.id,
    required this.appName,
    this.windowTitle,
    this.url,
    required this.startedAt,
    this.endedAt,
    this.durationSec,
    this.categoryId,
    this.isProductive = true,
  });

  Duration get duration {
    if (durationSec != null) return Duration(seconds: durationSec!);
    if (endedAt != null) return endedAt!.difference(startedAt);
    return Duration.zero;
  }

  bool get isActive => endedAt == null;

  ActivitySession copyWith({
    int? id,
    String? appName,
    String? windowTitle,
    String? url,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSec,
    int? categoryId,
    bool? isProductive,
  }) => ActivitySession(
    id: id ?? this.id,
    appName: appName ?? this.appName,
    windowTitle: windowTitle ?? this.windowTitle,
    url: url ?? this.url,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    durationSec: durationSec ?? this.durationSec,
    categoryId: categoryId ?? this.categoryId,
    isProductive: isProductive ?? this.isProductive,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ActivitySession && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
