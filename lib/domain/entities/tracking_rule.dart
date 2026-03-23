enum MatchType { app, url, title }

class TrackingRule {
  final int? id;
  final String pattern;
  final MatchType matchType;
  final int categoryId;
  final int priority;

  const TrackingRule({
    this.id,
    required this.pattern,
    required this.matchType,
    required this.categoryId,
    this.priority = 0,
  });

  bool matches(String appName, String? windowTitle, String? url) {
    final p = pattern.toLowerCase();
    return switch (matchType) {
      MatchType.app   => appName.toLowerCase().contains(p),
      MatchType.url   => (url ?? '').toLowerCase().contains(p),
      MatchType.title => (windowTitle ?? '').toLowerCase().contains(p),
    };
  }

  TrackingRule copyWith({
    int? id,
    String? pattern,
    MatchType? matchType,
    int? categoryId,
    int? priority,
  }) => TrackingRule(
    id: id ?? this.id,
    pattern: pattern ?? this.pattern,
    matchType: matchType ?? this.matchType,
    categoryId: categoryId ?? this.categoryId,
    priority: priority ?? this.priority,
  );
}
