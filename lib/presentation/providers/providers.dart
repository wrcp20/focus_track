import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/window_tracker_service.dart';
import '../../core/services/window_info.dart';
import '../../data/repositories/activity_repository_impl.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/focus_repository_impl.dart';
import '../../domain/entities/activity_session.dart';
import '../../domain/entities/app_category.dart';
import '../../domain/entities/focus_session.dart';

// ─── Repositorios ─────────────────────────────────────────────────────────

final activityRepoProvider = Provider((_) => ActivityRepositoryImpl());
final categoryRepoProvider  = Provider((_) => CategoryRepositoryImpl());
final focusRepoProvider     = Provider((_) => FocusRepositoryImpl());

// ─── WindowTracker ────────────────────────────────────────────────────────

final windowTrackerProvider = Provider<WindowTrackerService>((ref) {
  final tracker = WindowTrackerService();
  tracker.init();
  ref.onDispose(tracker.stop);
  return tracker;
});

// ─── Categorías ───────────────────────────────────────────────────────────

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<AppCategory>>(
        CategoriesNotifier.new);

class CategoriesNotifier extends AsyncNotifier<List<AppCategory>> {
  @override
  Future<List<AppCategory>> build() =>
      ref.read(categoryRepoProvider).getAllCategories();

  Future<void> reload() => update((_) =>
      ref.read(categoryRepoProvider).getAllCategories());

  Future<void> create(AppCategory cat) async {
    await ref.read(categoryRepoProvider).createCategory(cat);
    await reload();
  }

  Future<void> update_(AppCategory cat) async {
    await ref.read(categoryRepoProvider).updateCategory(cat);
    await reload();
  }

  Future<void> delete(int id) async {
    await ref.read(categoryRepoProvider).deleteCategory(id);
    await reload();
  }
}

// ─── Fecha seleccionada ───────────────────────────────────────────────────

final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// ─── Sesiones del día ─────────────────────────────────────────────────────

final dailySessionsProvider =
    FutureProvider.family<List<ActivitySession>, DateTime>((ref, date) async {
  return ref.read(activityRepoProvider).getSessionsForDay(date);
});

final durationByCategoryProvider =
    FutureProvider.family<Map<int?, Duration>, DateTime>((ref, date) async {
  return ref.read(activityRepoProvider).getDurationByCategory(date);
});

// ─── Tracker (rastreo automático) ────────────────────────────────────────

final trackerNotifierProvider =
    AsyncNotifierProvider<TrackerNotifier, TrackerState>(TrackerNotifier.new);

class TrackerState {
  final bool isTracking;
  final WindowInfo? currentWindow;
  final ActivitySession? activeSession;

  const TrackerState({
    this.isTracking = false,
    this.currentWindow,
    this.activeSession,
  });

  TrackerState copyWith({
    bool? isTracking,
    WindowInfo? currentWindow,
    ActivitySession? activeSession,
    bool clearSession = false,
  }) => TrackerState(
        isTracking: isTracking ?? this.isTracking,
        currentWindow: currentWindow ?? this.currentWindow,
        activeSession: clearSession ? null : (activeSession ?? this.activeSession),
      );
}

class TrackerNotifier extends AsyncNotifier<TrackerState> {
  StreamSubscription<WindowInfo?>? _sub;
  int? _activeSessionId;

  @override
  Future<TrackerState> build() async {
    ref.onDispose(() {
      _sub?.cancel();
    });
    return const TrackerState();
  }

  Future<void> startTracking() async {
    if (kIsWeb) {
      // En web no hay tracking automático
      state = const AsyncData(TrackerState(isTracking: false));
      return;
    }
    final tracker = ref.read(windowTrackerProvider);
    tracker.start();

    _sub?.cancel();
    _sub = tracker.onWindowChange.listen(_onWindowChanged);

    state = AsyncData(state.value!.copyWith(isTracking: true));
  }

  void stopTracking() {
    _sub?.cancel();
    ref.read(windowTrackerProvider).stop();
    state = AsyncData(state.value!.copyWith(isTracking: false));
  }

  Future<void> _onWindowChanged(WindowInfo? info) async {
    // Cerrar sesión anterior
    if (_activeSessionId != null) {
      await ref
          .read(activityRepoProvider)
          .endSession(_activeSessionId!, DateTime.now());
      _activeSessionId = null;
    }

    if (info == null) {
      state = AsyncData(state.value!.copyWith(
        currentWindow: null,
        clearSession: true,
      ));
      return;
    }

    // Categorizar automáticamente
    final category = await ref
        .read(categoryRepoProvider)
        .matchCategory(info.appName, info.windowTitle, null);

    // Abrir nueva sesión
    final session = ActivitySession(
      appName: info.appName,
      windowTitle: info.windowTitle,
      startedAt: DateTime.now(),
      categoryId: category?.id,
      isProductive: category?.productive ?? true,
    );

    _activeSessionId =
        await ref.read(activityRepoProvider).startSession(session);

    state = AsyncData(state.value!.copyWith(
      currentWindow: info,
      activeSession: session.copyWith(id: _activeSessionId),
    ));

    // Refrescar la lista de sesiones del día
    final today = DateTime.now();
    final date = DateTime(today.year, today.month, today.day);
    ref.invalidate(dailySessionsProvider(date));
    ref.invalidate(durationByCategoryProvider(date));
  }
}

// ─── Focus (Pomodoro) ─────────────────────────────────────────────────────

final focusNotifierProvider =
    AsyncNotifierProvider<FocusNotifier, FocusTimerState>(FocusNotifier.new);

class FocusTimerState {
  final bool isRunning;
  final FocusSession? session;
  final Duration elapsed;
  final int targetMinutes;

  const FocusTimerState({
    this.isRunning = false,
    this.session,
    this.elapsed = Duration.zero,
    this.targetMinutes = 25,
  });

  double get progress =>
      elapsed.inSeconds / Duration(minutes: targetMinutes).inSeconds;

  Duration get remaining =>
      Duration(minutes: targetMinutes) - elapsed;

  FocusTimerState copyWith({
    bool? isRunning,
    FocusSession? session,
    Duration? elapsed,
    int? targetMinutes,
  }) => FocusTimerState(
        isRunning: isRunning ?? this.isRunning,
        session: session ?? this.session,
        elapsed: elapsed ?? this.elapsed,
        targetMinutes: targetMinutes ?? this.targetMinutes,
      );
}

class FocusNotifier extends AsyncNotifier<FocusTimerState> {
  Timer? _ticker;

  @override
  Future<FocusTimerState> build() async {
    ref.onDispose(() => _ticker?.cancel());
    return const FocusTimerState();
  }

  Future<void> start({int minutes = 25}) async {
    _ticker?.cancel();

    final session = FocusSession(
      startedAt: DateTime.now(),
      targetMinutes: minutes,
    );

    final id = await ref.read(focusRepoProvider).startSession(session);

    state = AsyncData(FocusTimerState(
      isRunning: true,
      session: session.copyWith(id: id),
      targetMinutes: minutes,
    ));

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final s = state.value!;
      final newElapsed = s.elapsed + const Duration(seconds: 1);

      if (newElapsed >= Duration(minutes: s.targetMinutes)) {
        _complete();
      } else {
        state = AsyncData(s.copyWith(elapsed: newElapsed));
      }
    });
  }

  Future<void> stop() async {
    _ticker?.cancel();
    final s = state.value!;
    if (s.session?.id != null) {
      await ref.read(focusRepoProvider).endSession(
            s.session!.id!,
            endedAt: DateTime.now(),
            completed: false,
          );
    }
    state = const AsyncData(FocusTimerState());
  }

  Future<void> _complete() async {
    _ticker?.cancel();
    final s = state.value!;
    if (s.session?.id != null) {
      await ref.read(focusRepoProvider).endSession(
            s.session!.id!,
            endedAt: DateTime.now(),
            completed: true,
          );
    }
    state = AsyncData(s.copyWith(isRunning: false));
  }

  void setTargetMinutes(int minutes) {
    if (state.value?.isRunning ?? false) return;
    state = AsyncData(
        state.value!.copyWith(targetMinutes: minutes));
  }
}
