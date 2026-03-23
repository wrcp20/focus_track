import '../entities/focus_session.dart';

abstract class FocusRepository {
  Future<List<FocusSession>> getSessionsForDay(DateTime date);
  Future<FocusSession?> getActiveSession();
  Future<int> startSession(FocusSession session);
  Future<void> endSession(int id, {required DateTime endedAt, required bool completed});
}
