import '../../domain/entities/app_category.dart';
import '../../domain/entities/tracking_rule.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_datasource.dart';
import '../models/category_model.dart';
import '../models/tracking_rule_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryDatasource _ds;
  CategoryRepositoryImpl({CategoryDatasource? ds})
      : _ds = ds ?? CategoryDatasource();

  @override
  Future<List<AppCategory>> getAllCategories() => _ds.getAllCategories();

  @override
  Future<int> createCategory(AppCategory category) {
    final model = CategoryModel.fromEntity(category);
    return _ds.insertCategory(model);
  }

  @override
  Future<void> updateCategory(AppCategory category) {
    final model = CategoryModel.fromEntity(category);
    return _ds.updateCategory(model);
  }

  @override
  Future<void> deleteCategory(int id) => _ds.deleteCategory(id);

  @override
  Future<List<TrackingRule>> getAllRules() => _ds.getAllRules();

  @override
  Future<int> createRule(TrackingRule rule) {
    final model = TrackingRuleModel.fromEntity(rule);
    return _ds.insertRule(model);
  }

  @override
  Future<void> deleteRule(int id) => _ds.deleteRule(id);

  @override
  Future<AppCategory?> matchCategory(
      String appName, String? windowTitle, String? url) async {
    final rules = await _ds.getAllRules();
    final categories = await _ds.getAllCategories();

    // Ordenar por prioridad desc y encontrar primera coincidencia
    final sorted = [...rules]..sort((a, b) => b.priority.compareTo(a.priority));
    for (final rule in sorted) {
      if (rule.matches(appName, windowTitle, url)) {
        try {
          return categories.firstWhere((c) => c.id == rule.categoryId);
        } catch (_) {
          continue;
        }
      }
    }
    return null;
  }
}
