class FocusSession {
  final int? id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int targetMinutes;
  final bool completed;
  final String? notes;

  const FocusSession({
    this.id,
    required this.startedAt,
    this.endedAt,
    this.targetMinutes = 25,
    this.completed = false,
    this.notes,
  });

  Duration get elapsed {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  Duration get target => Duration(minutes: targetMinutes);

  bool get isActive => endedAt == null;

  double get progress =>
      (elapsed.inSeconds / target.inSeconds).clamp(0.0, 1.0);

  FocusSession copyWith({
    int? id,
    DateTime? startedAt,
    DateTime? endedAt,
    int? targetMinutes,
    bool? completed,
    String? notes,
  }) => FocusSession(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    targetMinutes: targetMinutes ?? this.targetMinutes,
    completed: completed ?? this.completed,
    notes: notes ?? this.notes,
  );
}
