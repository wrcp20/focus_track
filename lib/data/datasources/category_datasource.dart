import '../../core/database/database_helper.dart';
import '../models/category_model.dart';
import '../models/tracking_rule_model.dart';

class CategoryDatasource {
  final DatabaseHelper _db;
  CategoryDatasource({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  Future<List<CategoryModel>> getAllCategories() async {
    final db = await _db.database;
    final maps = await db.query('categories', orderBy: 'name ASC');
    return maps.map(CategoryModel.fromMap).toList();
  }

  Future<int> insertCategory(CategoryModel cat) async {
    final db = await _db.database;
    return db.insert('categories', cat.toMap());
  }

  Future<void> updateCategory(CategoryModel cat) async {
    final db = await _db.database;
    await db.update('categories', cat.toMap(),
        where: 'id = ?', whereArgs: [cat.id]);
  }

  Future<void> deleteCategory(int id) async {
    final db = await _db.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TrackingRuleModel>> getAllRules() async {
    final db = await _db.database;
    final maps =
        await db.query('tracking_rules', orderBy: 'priority DESC, id ASC');
    return maps.map(TrackingRuleModel.fromMap).toList();
  }

  Future<int> insertRule(TrackingRuleModel rule) async {
    final db = await _db.database;
    return db.insert('tracking_rules', rule.toMap());
  }

  Future<void> deleteRule(int id) async {
    final db = await _db.database;
    await db.delete('tracking_rules', where: 'id = ?', whereArgs: [id]);
  }
}
