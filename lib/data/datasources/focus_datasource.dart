import '../../core/database/database_helper.dart';
import '../models/focus_session_model.dart';

class FocusDatasource {
  final DatabaseHelper _db;
  FocusDatasource({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  Future<List<FocusSessionModel>> getSessionsForDay(DateTime date) async {
    final db = await _db.database;
    final dayStart = DateTime(date.year, date.month, date.day).toIso8601String();
    final dayEnd =
        DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    final maps = await db.query(
      'focus_sessions',
      where: 'started_at BETWEEN ? AND ?',
      whereArgs: [dayStart, dayEnd],
      orderBy: 'started_at ASC',
    );
    return maps.map(FocusSessionModel.fromMap).toList();
  }

  Future<FocusSessionModel?> getActiveSession() async {
    final db = await _db.database;
    final maps = await db.query(
      'focus_sessions',
      where: 'ended_at IS NULL',
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return FocusSessionModel.fromMap(maps.first);
  }

  Future<int> insert(FocusSessionModel session) async {
    final db = await _db.database;
    return db.insert('focus_sessions', session.toMap());
  }

  Future<void> end(int id,
      {required DateTime endedAt, required bool completed}) async {
    final db = await _db.database;
    await db.update(
      'focus_sessions',
      {'ended_at': endedAt.toIso8601String(), 'completed': completed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
