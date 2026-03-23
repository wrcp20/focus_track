import '../../domain/entities/activity_session.dart';
import '../../domain/repositories/activity_repository.dart';
import '../datasources/activity_datasource.dart';
import '../models/activity_session_model.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final ActivityDatasource _ds;
  ActivityRepositoryImpl({ActivityDatasource? ds})
      : _ds = ds ?? ActivityDatasource();

  @override
  Future<List<ActivitySession>> getSessionsForDay(DateTime date) =>
      _ds.getSessionsForDay(date);

  @override
  Future<List<ActivitySession>> getSessionsRange(
          DateTime from, DateTime to) =>
      _ds.getSessionsRange(from, to);

  @override
  Future<ActivitySession?> getActiveSession() => _ds.getActiveSession();

  @override
  Future<int> startSession(ActivitySession session) {
    final model = ActivitySessionModel.fromEntity(session);
    return _ds.insert(model);
  }

  @override
  Future<void> endSession(int id, DateTime endedAt) =>
      _ds.end(id, endedAt);

  @override
  Future<void> updateCategory(int id, int? categoryId, bool isProductive) =>
      _ds.updateCategory(id, categoryId, isProductive);

  @override
  Future<void> deleteSession(int id) => _ds.delete(id);

  @override
  Future<Map<int?, Duration>> getDurationByCategory(DateTime date) async {
    final raw = await _ds.getDurationByCategory(date);
    return raw
        .map((k, v) => MapEntry(k, Duration(seconds: v)));
  }
}
