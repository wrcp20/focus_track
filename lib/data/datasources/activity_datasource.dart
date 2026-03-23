import '../../core/database/database_helper.dart';
import '../models/activity_session_model.dart';

class ActivityDatasource {
  final DatabaseHelper _db;
  ActivityDatasource({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  Future<List<ActivitySessionModel>> getSessionsForDay(DateTime date) async {
    final db = await _db.database;
    final dayStart = DateTime(date.year, date.month, date.day).toIso8601String();
    final dayEnd   = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    final maps = await db.query(
      'activity_sessions',
      where: 'started_at BETWEEN ? AND ?',
      whereArgs: [dayStart, dayEnd],
      orderBy: 'started_at ASC',
    );
    return maps.map(ActivitySessionModel.fromMap).toList();
  }

  Future<List<ActivitySessionModel>> getSessionsRange(
      DateTime from, DateTime to) async {
    final db = await _db.database;
    final maps = await db.query(
      'activity_sessions',
      where: 'started_at BETWEEN ? AND ?',
      whereArgs: [from.toIso8601String(), to.toIso8601String()],
      orderBy: 'started_at ASC',
    );
    return maps.map(ActivitySessionModel.fromMap).toList();
  }

  Future<ActivitySessionModel?> getActiveSession() async {
    final db = await _db.database;
    final maps = await db.query(
      'activity_sessions',
      where: 'ended_at IS NULL',
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ActivitySessionModel.fromMap(maps.first);
  }

  Future<int> insert(ActivitySessionModel session) async {
    final db = await _db.database;
    return db.insert('activity_sessions', session.toMap());
  }

  Future<void> end(int id, DateTime endedAt) async {
    final db = await _db.database;
    // Calculamos desde started_at
    final rows = await db.query('activity_sessions',
        where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return;
    final startedAt = DateTime.parse(rows.first['started_at'] as String);
    final dur = endedAt.difference(startedAt).inSeconds;

    await db.update(
      'activity_sessions',
      {'ended_at': endedAt.toIso8601String(), 'duration_sec': dur},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateCategory(
      int id, int? categoryId, bool isProductive) async {
    final db = await _db.database;
    await db.update(
      'activity_sessions',
      {'category_id': categoryId, 'is_productive': isProductive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('activity_sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<int?, int>> getDurationByCategory(DateTime date) async {
    final db = await _db.database;
    final dayStart =
        DateTime(date.year, date.month, date.day).toIso8601String();
    final dayEnd =
        DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    final rows = await db.rawQuery('''
      SELECT category_id, SUM(duration_sec) as total
      FROM activity_sessions
      WHERE started_at BETWEEN ? AND ?
        AND duration_sec IS NOT NULL
      GROUP BY category_id
    ''', [dayStart, dayEnd]);

    return {
      for (final r in rows)
        r['category_id'] as int?: r['total'] as int? ?? 0,
    };
  }
}
