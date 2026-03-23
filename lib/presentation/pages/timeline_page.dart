import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/activity_session.dart';
import '../../domain/entities/app_category.dart';
import '../providers/providers.dart';
import '../widgets/duration_text.dart';

class TimelinePage extends ConsumerStatefulWidget {
  const TimelinePage({super.key});

  @override
  ConsumerState<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends ConsumerState<TimelinePage> {
  bool _visualMode = true;

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(selectedDateProvider);
    final sessionsAsync = ref.watch(dailySessionsProvider(today));
    final categoriesAsync = ref.watch(categoriesProvider);
    final isToday = _isToday(today);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Línea de Tiempo'),
        actions: [
          // Toggle vista visual / lista
          IconButton(
            icon: Icon(_visualMode ? Icons.view_list : Icons.view_timeline),
            tooltip: _visualMode ? 'Vista lista' : 'Vista visual',
            onPressed: () => setState(() => _visualMode = !_visualMode),
          ),
          // Navegar entre días
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Día anterior',
            onPressed: () => ref.read(selectedDateProvider.notifier).state =
                today.subtract(const Duration(days: 1)),
          ),
          TextButton(
            onPressed: () {
              final now = DateTime.now();
              ref.read(selectedDateProvider.notifier).state =
                  DateTime(now.year, now.month, now.day);
            },
            child: Text(
              DateFormat('d MMM', 'es').format(today),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Día siguiente',
            onPressed: () {
              final next = today.add(const Duration(days: 1));
              final now = DateTime.now();
              if (next.isBefore(DateTime(now.year, now.month, now.day + 1))) {
                ref.read(selectedDateProvider.notifier).state = next;
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timeline,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text('Sin actividad en este día'),
                ],
              ),
            );
          }

          return categoriesAsync.when(
            data: (cats) => _visualMode
                ? _VisualTimeline(
                    sessions: sessions, categories: cats, isToday: isToday)
                : _ListTimeline(sessions: sessions, categories: cats),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

// ─── Vista Visual Tipo Gantt ───────────────────────────────────────────────

class _VisualTimeline extends StatefulWidget {
  final List<ActivitySession> sessions;
  final List<AppCategory> categories;
  final bool isToday;

  const _VisualTimeline(
      {required this.sessions,
      required this.categories,
      required this.isToday});

  @override
  State<_VisualTimeline> createState() => _VisualTimelineState();
}

class _VisualTimelineState extends State<_VisualTimeline> {
  final _scrollController = ScrollController();
  static const double _pxPerMinute = 1.8;
  static const double _pxPerHour = _pxPerMinute * 60; // 108px/hora
  static const double _labelWidth = 52.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToStart());
  }

  void _scrollToStart() {
    double targetMinutes;
    if (widget.sessions.isNotEmpty) {
      final first = widget.sessions.first.startedAt;
      targetMinutes =
          (first.hour * 60 + first.minute - 30).toDouble().clamp(0, 24 * 60);
    } else {
      final now = DateTime.now();
      targetMinutes = (now.hour * 60 - 60).toDouble().clamp(0, 24 * 60);
    }
    _scrollController.animateTo(
      targetMinutes * _pxPerMinute,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  Color _hexColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalHeight = 24 * _pxPerHour;

    return SingleChildScrollView(
      controller: _scrollController,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etiquetas de hora
          SizedBox(
            width: _labelWidth,
            height: totalHeight,
            child: Stack(
              children: List.generate(24, (h) {
                return Positioned(
                  top: h * _pxPerHour - 8,
                  child: SizedBox(
                    width: _labelWidth - 8,
                    child: Text(
                      '${h.toString().padLeft(2, '0')}:00',
                      textAlign: TextAlign.right,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                );
              }),
            ),
          ),
          // Divisor
          Container(
              width: 1,
              height: totalHeight,
              color:
                  theme.colorScheme.outline.withValues(alpha: 0.3)),
          // Área de sesiones
          Expanded(
            child: SizedBox(
              height: totalHeight,
              child: Stack(
                children: [
                  // Líneas de hora
                  ...List.generate(24, (h) => Positioned(
                        top: h * _pxPerHour,
                        left: 0,
                        right: 0,
                        child: Container(
                            height: 1,
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.12)),
                      )),
                  // Bloques de sesión
                  ...widget.sessions.map((s) => _buildBlock(context, s)),
                  // Línea de tiempo actual
                  if (widget.isToday) _buildNowLine(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlock(BuildContext context, ActivitySession s) {
    final theme = Theme.of(context);
    final startMin = s.startedAt.hour * 60 + s.startedAt.minute;
    final endDt = s.endedAt ?? DateTime.now();
    final endMin = endDt.hour * 60 + endDt.minute;
    final durMin = (endMin - startMin).clamp(1, 24 * 60);

    final top = startMin * _pxPerMinute;
    final height = (durMin * _pxPerMinute).clamp(3.0, double.infinity);

    final cat = s.categoryId != null
        ? widget.categories
            .where((c) => c.id == s.categoryId)
            .firstOrNull
        : null;
    final color =
        cat != null ? _hexColor(cat.color) : theme.colorScheme.outline;

    return Positioned(
      top: top,
      left: 4,
      right: 4,
      height: height,
      child: GestureDetector(
        onTap: () => _showDetail(context, s, cat),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: height >= 18
              ? Text(
                  s.appName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildNowLine(BuildContext context) {
    final now = DateTime.now();
    final top = (now.hour * 60 + now.minute) * _pxPerMinute;
    return Positioned(
      top: top - 1,
      left: 0,
      right: 0,
      child: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle)),
          Expanded(
              child:
                  Container(height: 2, color: Colors.red.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  void _showDetail(
      BuildContext context, ActivitySession s, AppCategory? cat) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.appName,
                style: Theme.of(ctx)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            if (s.windowTitle != null && s.windowTitle!.isNotEmpty)
              Text(s.windowTitle!,
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.access_time, size: 16),
              const SizedBox(width: 6),
              Text(DateFormat('HH:mm').format(s.startedAt)),
              if (s.endedAt != null) ...[
                Text(' → '),
                Text(DateFormat('HH:mm').format(s.endedAt!)),
              ],
              const SizedBox(width: 12),
              DurationText(s.duration),
            ]),
            if (cat != null) ...[
              const SizedBox(height: 8),
              Chip(label: Text(cat.name)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Vista Lista ──────────────────────────────────────────────────────────

class _ListTimeline extends StatelessWidget {
  final List<ActivitySession> sessions;
  final List<AppCategory> categories;

  const _ListTimeline(
      {required this.sessions, required this.categories});

  Color _hexColor(String? hex) {
    if (hex == null) return Colors.grey;
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, i) {
        final s = sessions[sessions.length - 1 - i];
        final cat = s.categoryId != null
            ? categories.where((c) => c.id == s.categoryId).firstOrNull
            : null;
        final color = _hexColor(cat?.color);
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 56,
                child: Column(children: [
                  Text(
                    DateFormat('HH:mm').format(s.startedAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  Expanded(
                    child: Center(
                      child: Container(
                          width: 2,
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.3)),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 8),
              Column(children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 2),
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ]),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.appName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                          fontWeight: FontWeight.bold)),
                              if (s.windowTitle != null &&
                                  s.windowTitle!.isNotEmpty)
                                Text(s.windowTitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant)),
                              if (cat != null)
                                Chip(
                                  label: Text(cat.name),
                                  visualDensity: VisualDensity.compact,
                                  side: BorderSide(color: color),
                                  labelStyle:
                                      TextStyle(fontSize: 11, color: color),
                                  padding: EdgeInsets.zero,
                                ),
                            ],
                          ),
                        ),
                        DurationText(s.duration,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                      ]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
