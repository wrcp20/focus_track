import '../entities/activity_session.dart';

abstract class ActivityRepository {
  Future<List<ActivitySession>> getSessionsForDay(DateTime date);
  Future<List<ActivitySession>> getSessionsRange(DateTime from, DateTime to);
  Future<ActivitySession?> getActiveSession();
  Future<int> startSession(ActivitySession session);
  Future<void> endSession(int id, DateTime endedAt);
  Future<void> updateCategory(int id, int? categoryId, bool isProductive);
  Future<void> deleteSession(int id);

  /// Resumen: duración total por categoría para un día
  Future<Map<int?, Duration>> getDurationByCategory(DateTime date);
}
