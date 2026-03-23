import '../../domain/entities/tracking_rule.dart';

class TrackingRuleModel extends TrackingRule {
  const TrackingRuleModel({
    super.id,
    required super.pattern,
    required super.matchType,
    required super.categoryId,
    super.priority,
  });

  factory TrackingRuleModel.fromMap(Map<String, dynamic> m) => TrackingRuleModel(
        id: m['id'] as int?,
        pattern: m['pattern'] as String,
        matchType: _parseType(m['match_type'] as String),
        categoryId: m['category_id'] as int,
        priority: m['priority'] as int,
      );

  factory TrackingRuleModel.fromEntity(TrackingRule e) => TrackingRuleModel(
        id: e.id,
        pattern: e.pattern,
        matchType: e.matchType,
        categoryId: e.categoryId,
        priority: e.priority,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'pattern': pattern,
        'match_type': matchType.name,
        'category_id': categoryId,
        'priority': priority,
      };

  static MatchType _parseType(String s) => switch (s) {
        'url'   => MatchType.url,
        'title' => MatchType.title,
        _       => MatchType.app,
      };
}
