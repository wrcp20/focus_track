import '../../domain/entities/activity_session.dart';

class ActivitySessionModel extends ActivitySession {
  const ActivitySessionModel({
    super.id,
    required super.appName,
    super.windowTitle,
    super.url,
    required super.startedAt,
    super.endedAt,
    super.durationSec,
    super.categoryId,
    super.isProductive,
  });

  factory ActivitySessionModel.fromMap(Map<String, dynamic> m) =>
      ActivitySessionModel(
        id: m['id'] as int?,
        appName: m['app_name'] as String,
        windowTitle: m['window_title'] as String?,
        url: m['url'] as String?,
        startedAt: DateTime.parse(m['started_at'] as String),
        endedAt: m['ended_at'] != null
            ? DateTime.parse(m['ended_at'] as String)
            : null,
        durationSec: m['duration_sec'] as int?,
        categoryId: m['category_id'] as int?,
        isProductive: (m['is_productive'] as int) == 1,
      );

  factory ActivitySessionModel.fromEntity(ActivitySession e) =>
      ActivitySessionModel(
        id: e.id,
        appName: e.appName,
        windowTitle: e.windowTitle,
        url: e.url,
        startedAt: e.startedAt,
        endedAt: e.endedAt,
        durationSec: e.durationSec,
        categoryId: e.categoryId,
        isProductive: e.isProductive,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'app_name': appName,
        'window_title': windowTitle,
        'url': url,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'duration_sec': durationSec,
        'category_id': categoryId,
        'is_productive': isProductive ? 1 : 0,
      };
}
