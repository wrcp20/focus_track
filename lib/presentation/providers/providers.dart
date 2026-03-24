import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/services/claude_ai_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/window_tracker_service.dart';
import '../../core/services/window_info.dart';
import '../../data/datasources/settings_datasource.dart';
import '../../data/repositories/activity_repository_impl.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/focus_repository_impl.dart';
import '../../domain/entities/activity_session.dart';
import '../../domain/entities/app_category.dart';
import '../../domain/entities/focus_session.dart';
import '../../domain/entities/tracking_rule.dart';

// ─── Repositorios ─────────────────────────────────────────────────────────

final activityRepoProvider = Provider((_) => ActivityRepositoryImpl());
final categoryRepoProvider  = Provider((_) => CategoryRepositoryImpl());
final focusRepoProvider     = Provider((_) => FocusRepositoryImpl());

// ─── Servicios ────────────────────────────────────────────────────────────

final notificationServiceProvider = Provider((ref) {
  final service = NotificationService();
  service.init();
  return service;
});

// ─── Claude AI ────────────────────────────────────────────────────────────

final claudeAIServiceProvider = Provider<ClaudeAIService>((ref) {
  final settings = ref.watch(settingsProvider);
  final key = settings.value?['claude_api_key'];
  return ClaudeAIService((key?.isEmpty ?? true) ? null : key);
});

// ─── WindowTracker ────────────────────────────────────────────────────────

final windowTrackerProvider = Provider<WindowTrackerService>((ref) {
  final tracker = WindowTrackerService();
  tracker.init();
  ref.onDispose(tracker.stop);
  return tracker;
});

// ─── Settings ─────────────────────────────────────────────────────────────

final settingsDatasourceProvider = Provider((_) => SettingsDatasource());

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, Map<String, String>>(
        SettingsNotifier.new);

class SettingsNotifier extends AsyncNotifier<Map<String, String>> {
  @override
  Future<Map<String, String>> build() =>
      ref.read(settingsDatasourceProvider).getAll();

  Future<void> set(String key, String value) async {
    await ref.read(settingsDatasourceProvider).set(key, value);
    state = AsyncData({...?state.value, key: value});
  }

  String getValue(String key, String defaultValue) =>
      state.value?[key] ?? defaultValue;
}

// ─── Tema ─────────────────────────────────────────────────────────────────

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// ─── Categorías ───────────────────────────────────────────────────────────

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<AppCategory>>(
        CategoriesNotifier.new);

class CategoriesNotifier extends AsyncNotifier<List<AppCategory>> {
  @override
  Future<List<AppCategory>> build() =>
      ref.read(categoryRepoProvider).getAllCategories();

  Future<void> reload() => update(
      (_) => ref.read(categoryRepoProvider).getAllCategories());

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

// ─── Sesiones de foco del día ─────────────────────────────────────────────

final focusSessionsDailyProvider =
    FutureProvider.family<List<FocusSession>, DateTime>((ref, date) async {
  return ref.read(focusRepoProvider).getSessionsForDay(date);
});

// ─── Distribución horaria ─────────────────────────────────────────────────

final hourlyDistributionProvider =
    FutureProvider.family<Map<int, Duration>, DateTime>((ref, date) async {
  final sessions =
      await ref.read(activityRepoProvider).getSessionsForDay(date);
  final result = <int, Duration>{};
  for (final s in sessions) {
    if (s.endedAt == null) continue;
    var current = s.startedAt;
    final end = s.endedAt!;
    while (current.isBefore(end)) {
      final hour = current.hour;
      final nextHour =
          DateTime(current.year, current.month, current.day, hour + 1);
      final blockEnd = nextHour.isBefore(end) ? nextHour : end;
      result[hour] =
          (result[hour] ?? Duration.zero) + blockEnd.difference(current);
      current = nextHour;
    }
  }
  return result;
});

// ─── Stats de productividad del día ──────────────────────────────────────

final productiveStatsProvider = FutureProvider.family<
    ({Duration total, Duration productive}),
    DateTime>((ref, date) async {
  final sessions =
      await ref.read(activityRepoProvider).getSessionsForDay(date);
  final total =
      sessions.fold(Duration.zero, (acc, s) => acc + s.duration);
  final productive = sessions
      .where((s) => s.isProductive)
      .fold(Duration.zero, (acc, s) => acc + s.duration);
  return (total: total, productive: productive);
});

// ─── Estadísticas semanales ───────────────────────────────────────────────

class DayStats {
  final DateTime date;
  final Duration total;
  final Duration productive;
  final int sessionCount;

  const DayStats({
    required this.date,
    required this.total,
    required this.productive,
    required this.sessionCount,
  });

  double get productivePercent =>
      total.inSeconds > 0
          ? productive.inSeconds / total.inSeconds * 100
          : 0;
}

final weeklyStatsProvider =
    FutureProvider.family<List<DayStats>, DateTime>((ref, weekStart) async {
  final repo = ref.read(activityRepoProvider);
  final stats = <DayStats>[];
  for (var i = 0; i < 7; i++) {
    final date = weekStart.add(Duration(days: i));
    final sessions = await repo.getSessionsForDay(date);
    final total =
        sessions.fold(Duration.zero, (acc, s) => acc + s.duration);
    final productive = sessions
        .where((s) => s.isProductive)
        .fold(Duration.zero, (acc, s) => acc + s.duration);
    stats.add(DayStats(
      date: date,
      total: total,
      productive: productive,
      sessionCount: sessions.length,
    ));
  }
  return stats;
});

// ─── Top apps de la semana ────────────────────────────────────────────────

final weeklyTopAppsProvider = FutureProvider.family<
    List<({String appName, Duration total})>,
    DateTime>((ref, weekStart) async {
  final repo = ref.read(activityRepoProvider);
  final weekEnd = weekStart.add(const Duration(days: 7));
  final sessions = await repo.getSessionsRange(weekStart, weekEnd);
  final totals = <String, Duration>{};
  for (final s in sessions) {
    totals[s.appName] =
        (totals[s.appName] ?? Duration.zero) + s.duration;
  }
  final sorted = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sorted
      .take(8)
      .map((e) => (appName: e.key, total: e.value))
      .toList();
});

// ─── Racha de días productivos ────────────────────────────────────────────

final streakProvider = FutureProvider<int>((ref) async {
  final repo = ref.read(activityRepoProvider);
  final today = DateTime.now();
  var streak = 0;
  for (var i = 0; i < 60; i++) {
    final d = today.subtract(Duration(days: i));
    final date = DateTime(d.year, d.month, d.day);
    final sessions = await repo.getSessionsForDay(date);
    final productive = sessions
        .where((s) => s.isProductive)
        .fold(Duration.zero, (acc, s) => acc + s.duration);
    if (productive.inMinutes >= 30) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
});

// ─── Resumen IA del día ───────────────────────────────────────────────────

class AiSummaryState {
  final bool isLoading;
  final String? summary;
  final String? error;

  const AiSummaryState({
    this.isLoading = false,
    this.summary,
    this.error,
  });
}

final aiSummaryProvider =
    StateNotifierProvider<AiSummaryNotifier, AiSummaryState>(
        (ref) => AiSummaryNotifier(ref));

class AiSummaryNotifier extends StateNotifier<AiSummaryState> {
  AiSummaryNotifier(this._ref) : super(const AiSummaryState());
  final Ref _ref;

  Future<void> generate(DateTime date) async {
    state = const AiSummaryState(isLoading: true);

    final service = _ref.read(claudeAIServiceProvider);
    if (!service.hasApiKey) {
      state = const AiSummaryState(
          error: 'Configura tu API key de Claude en Configuración');
      return;
    }

    try {
      final prod = await _ref.read(productiveStatsProvider(date).future);
      final sessions = await _ref.read(dailySessionsProvider(date).future);
      final focusSessions =
          await _ref.read(focusSessionsDailyProvider(date).future);

      // Top apps del día
      final appDurations = <String, Duration>{};
      for (final s in sessions) {
        appDurations[s.appName] =
            (appDurations[s.appName] ?? Duration.zero) + s.duration;
      }
      final topApps = (appDurations.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .take(5)
          .map((e) => e.key)
          .toList();

      final dateStr = DateFormat('EEEE d MMMM', 'es').format(date);

      final summary = await service.generateDailySummary(
        date: dateStr,
        totalTime: prod.total,
        productiveTime: prod.productive,
        focusSessionCount: focusSessions.length,
        topApps: topApps,
      );

      if (summary != null) {
        state = AiSummaryState(summary: summary);
      } else {
        state =
            const AiSummaryState(error: 'Error al conectar con Claude API');
      }
    } catch (e) {
      state = AiSummaryState(error: 'Error: $e');
    }
  }

  void clear() => state = const AiSummaryState();
}

// ─── Tracker (rastreo automático) ────────────────────────────────────────

final trackerNotifierProvider =
    AsyncNotifierProvider<TrackerNotifier, TrackerState>(TrackerNotifier.new);

class TrackerState {
  final bool isTracking;
  final WindowInfo? currentWindow;
  final ActivitySession? activeSession;
  final bool lastAiCategorized;

  const TrackerState({
    this.isTracking = false,
    this.currentWindow,
    this.activeSession,
    this.lastAiCategorized = false,
  });

  TrackerState copyWith({
    bool? isTracking,
    WindowInfo? currentWindow,
    ActivitySession? activeSession,
    bool clearSession = false,
    bool? lastAiCategorized,
  }) =>
      TrackerState(
        isTracking: isTracking ?? this.isTracking,
        currentWindow: currentWindow ?? this.currentWindow,
        activeSession:
            clearSession ? null : (activeSession ?? this.activeSession),
        lastAiCategorized: lastAiCategorized ?? this.lastAiCategorized,
      );
}

class TrackerNotifier extends AsyncNotifier<TrackerState> {
  StreamSubscription<WindowInfo?>? _sub;
  int? _activeSessionId;
  // Contador de sugerencias IA por (app, categoría) para auto-crear reglas
  final Map<String, int> _aiSuggestionCounts = {};

  @override
  Future<TrackerState> build() async {
    ref.onDispose(() => _sub?.cancel());
    return const TrackerState();
  }

  Future<void> startTracking() async {
    if (kIsWeb) {
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
    // 1. Cerrar sesión anterior
    if (_activeSessionId != null) {
      await ref
          .read(activityRepoProvider)
          .endSession(_activeSessionId!, DateTime.now());
      _activeSessionId = null;
    }

    if (info == null) {
      state = AsyncData(state.value!.copyWith(
          currentWindow: null, clearSession: true, lastAiCategorized: false));
      return;
    }

    // 2. Determinar categoría: reglas DB → IA → sin categoría
    AppCategory? category = await ref
        .read(categoryRepoProvider)
        .matchCategory(info.appName, info.windowTitle, null);

    bool usedAi = false;
    if (category == null) {
      final cats = await ref.read(categoryRepoProvider).getAllCategories();
      final catNames = cats.map((c) => c.name).toList();
      final suggestion = await ref
          .read(claudeAIServiceProvider)
          .categorizeApp(info.appName, info.windowTitle, catNames);

      if (suggestion != null) {
        category =
            cats.where((c) => c.name == suggestion.category).firstOrNull;
        if (category != null) {
          usedAi = true;
          await _trackAiSuggestion(info.appName, category);
        }
      }
    }

    // 3. Crear nueva sesión
    final session = ActivitySession(
      appName: info.appName,
      windowTitle: info.windowTitle,
      startedAt: DateTime.now(),
      categoryId: category?.id,
      isProductive: category?.productive ?? true,
    );

    _activeSessionId =
        await ref.read(activityRepoProvider).startSession(session);

    // 4. Registrar interrupción si hay sesión de foco activa y app no productiva
    final focusState = ref.read(focusNotifierProvider).value;
    if (focusState != null &&
        focusState.isRunning &&
        !(category?.productive ?? true)) {
      ref.read(focusNotifierProvider.notifier).recordInterruption();
    }

    // 5. Actualizar estado
    state = AsyncData(state.value!.copyWith(
      currentWindow: info,
      activeSession: session.copyWith(id: _activeSessionId),
      lastAiCategorized: usedAi,
    ));

    // 6. Invalidar providers del día
    final today = DateTime.now();
    final date = DateTime(today.year, today.month, today.day);
    ref.invalidate(dailySessionsProvider(date));
    ref.invalidate(durationByCategoryProvider(date));
    ref.invalidate(hourlyDistributionProvider(date));
    ref.invalidate(productiveStatsProvider(date));
  }

  /// Rastrea sugerencias IA; después de 3 veces crea regla automáticamente.
  Future<void> _trackAiSuggestion(String appName, AppCategory cat) async {
    if (cat.id == null) return;
    final key = '${appName}__${cat.id}';
    _aiSuggestionCounts[key] = (_aiSuggestionCounts[key] ?? 0) + 1;
    if (_aiSuggestionCounts[key]! >= 3) {
      try {
        await ref.read(categoryRepoProvider).createRule(TrackingRule(
              pattern: appName,
              matchType: MatchType.app,
              categoryId: cat.id!,
              priority: 5,
            ));
        _aiSuggestionCounts.remove(key);
      } catch (_) {}
    }
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
  final int interruptions;

  const FocusTimerState({
    this.isRunning = false,
    this.session,
    this.elapsed = Duration.zero,
    this.targetMinutes = 25,
    this.interruptions = 0,
  });

  double get progress =>
      elapsed.inSeconds / Duration(minutes: targetMinutes).inSeconds;

  Duration get remaining => Duration(minutes: targetMinutes) - elapsed;

  /// Score de calidad: 100 - 15 puntos por cada interrupción (mínimo 0)
  int get qualityScore => (100 - interruptions * 15).clamp(0, 100);

  FocusTimerState copyWith({
    bool? isRunning,
    FocusSession? session,
    Duration? elapsed,
    int? targetMinutes,
    int? interruptions,
  }) =>
      FocusTimerState(
        isRunning: isRunning ?? this.isRunning,
        session: session ?? this.session,
        elapsed: elapsed ?? this.elapsed,
        targetMinutes: targetMinutes ?? this.targetMinutes,
        interruptions: interruptions ?? this.interruptions,
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
    final session =
        FocusSession(startedAt: DateTime.now(), targetMinutes: minutes);
    final id = await ref.read(focusRepoProvider).startSession(session);

    state = AsyncData(FocusTimerState(
      isRunning: true,
      session: session.copyWith(id: id),
      targetMinutes: minutes,
      interruptions: 0,
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

  /// Registra una interrupción (app no productiva detectada durante el foco)
  void recordInterruption() {
    final s = state.value;
    if (s == null || !s.isRunning) return;
    state = AsyncData(s.copyWith(interruptions: s.interruptions + 1));
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
    await ref
        .read(notificationServiceProvider)
        .showFocusComplete(s.targetMinutes);
    state = AsyncData(s.copyWith(isRunning: false));
  }

  void setTargetMinutes(int minutes) {
    if (state.value?.isRunning ?? false) return;
    state = AsyncData(state.value!.copyWith(targetMinutes: minutes));
  }
}
