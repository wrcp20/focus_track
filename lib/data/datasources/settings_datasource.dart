import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';

/// Datasource para leer y escribir configuración clave-valor en SQLite
class SettingsDatasource {
  final DatabaseHelper _db;
  SettingsDatasource({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  Future<Map<String, String>> getAll() async {
    final db = await _db.database;
    final rows = await db.query('settings');
    return {for (final r in rows) r['key'] as String: r['value'] as String};
  }

  Future<void> set(String key, String value) async {
    final db = await _db.database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
