import '../../domain/entities/app_category.dart';

class CategoryModel extends AppCategory {
  const CategoryModel({
    super.id,
    required super.name,
    required super.color,
    required super.icon,
    super.productive,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> m) => CategoryModel(
        id: m['id'] as int?,
        name: m['name'] as String,
        color: m['color'] as String,
        icon: m['icon'] as String,
        productive: (m['productive'] as int) == 1,
      );

  factory CategoryModel.fromEntity(AppCategory e) => CategoryModel(
        id: e.id,
        name: e.name,
        color: e.color,
        icon: e.icon,
        productive: e.productive,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'color': color,
        'icon': icon,
        'productive': productive ? 1 : 0,
      };
}
