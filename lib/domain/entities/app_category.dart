class AppCategory {
  final int? id;
  final String name;
  final String color;  // Hex "#6366F1"
  final String icon;   // 'code', 'meeting', 'chat', etc.
  final bool productive;

  const AppCategory({
    this.id,
    required this.name,
    required this.color,
    required this.icon,
    this.productive = true,
  });

  AppCategory copyWith({
    int? id,
    String? name,
    String? color,
    String? icon,
    bool? productive,
  }) => AppCategory(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color ?? this.color,
    icon: icon ?? this.icon,
    productive: productive ?? this.productive,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AppCategory && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
