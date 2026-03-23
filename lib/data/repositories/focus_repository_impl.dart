import '../../domain/entities/focus_session.dart';
import '../../domain/repositories/focus_repository.dart';
import '../datasources/focus_datasource.dart';
import '../models/focus_session_model.dart';

class FocusRepositoryImpl implements FocusRepository {
  final FocusDatasource _ds;
  FocusRepositoryImpl({FocusDatasource? ds}) : _ds = ds ?? FocusDatasource();

  @override
  Future<List<FocusSession>> getSessionsForDay(DateTime date) =>
      _ds.getSessionsForDay(date);

  @override
  Future<FocusSession?> getActiveSession() => _ds.getActiveSession();

  @override
  Future<int> startSession(FocusSession session) {
    final model = FocusSessionModel.fromEntity(session);
    return _ds.insert(model);
  }

  @override
  Future<void> endSession(int id,
          {required DateTime endedAt, required bool completed}) =>
      _ds.end(id, endedAt: endedAt, completed: completed);
}
