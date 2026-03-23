import '../entities/app_category.dart';
import '../entities/tracking_rule.dart';

abstract class CategoryRepository {
  Future<List<AppCategory>> getAllCategories();
  Future<int> createCategory(AppCategory category);
  Future<void> updateCategory(AppCategory category);
  Future<void> deleteCategory(int id);

  Future<List<TrackingRule>> getAllRules();
  Future<int> createRule(TrackingRule rule);
  Future<void> deleteRule(int id);

  /// Devuelve la categoría que coincide con la app/url/título activos
  Future<AppCategory?> matchCategory(
      String appName, String? windowTitle, String? url);
}
