import '../../domain/entities/focus_session.dart';

class FocusSessionModel extends FocusSession {
  const FocusSessionModel({
    super.id,
    required super.startedAt,
    super.endedAt,
    super.targetMinutes,
    super.completed,
    super.notes,
  });

  factory FocusSessionModel.fromMap(Map<String, dynamic> m) => FocusSessionModel(
        id: m['id'] as int?,
        startedAt: DateTime.parse(m['started_at'] as String),
        endedAt: m['ended_at'] != null
            ? DateTime.parse(m['ended_at'] as String)
            : null,
        targetMinutes: m['target_min'] as int,
        completed: (m['completed'] as int) == 1,
        notes: m['notes'] as String?,
      );

  factory FocusSessionModel.fromEntity(FocusSession e) => FocusSessionModel(
        id: e.id,
        startedAt: e.startedAt,
        endedAt: e.endedAt,
        targetMinutes: e.targetMinutes,
        completed: e.completed,
        notes: e.notes,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'target_min': targetMinutes,
        'completed': completed ? 1 : 0,
        'notes': notes,
      };
}
