import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../widgets/duration_text.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(DateTime.now());
  }

  static DateTime _mondayOf(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  void _prevWeek() =>
      setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));
  void _nextWeek() {
    final next = _weekStart.add(const Duration(days: 7));
    if (next.isBefore(DateTime.now())) {
      setState(() => _weekStart = next);
    }
  }

  String _weekLabel() {
    final end = _weekStart.add(const Duration(days: 6));
    final fmt = DateFormat('d MMM', 'es');
    return '${fmt.format(_weekStart)} — ${fmt.format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final weeklyAsync = ref.watch(weeklyStatsProvider(_weekStart));
    final topAppsAsync = ref.watch(weeklyTopAppsProvider(_weekStart));
    final streakAsync = ref.watch(streakProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Reportes'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Selector de semana ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _prevWeek,
                    ),
                    Text(_weekLabel(),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _nextWeek,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Resumen semanal (3 tarjetas) ──
                weeklyAsync.when(
                  data: (stats) {
                    final totalWeek = stats.fold(
                        Duration.zero, (acc, d) => acc + d.total);
                    final prodWeek = stats.fold(
                        Duration.zero, (acc, d) => acc + d.productive);
                    return Row(children: [
                      Expanded(
                          child: _SmallCard(
                              label: 'Total semana',
                              value: DurationText.format(totalWeek),
                              icon: Icons.access_time,
                              color:
                                  Theme.of(context).colorScheme.primary)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _SmallCard(
                              label: 'Productivo',
                              value: DurationText.format(prodWeek),
                              icon: Icons.bolt,
                              color: Colors.green)),
                      const SizedBox(width: 12),
                      streakAsync.when(
                        data: (streak) => Expanded(
                            child: _SmallCard(
                                label: 'Racha',
                                value: '$streak día${streak == 1 ? '' : 's'}',
                                icon: Icons.local_fire_department,
                                color: Colors.deepOrange)),
                        loading: () => const Expanded(child: SizedBox()),
                        error: (e, _) => const Expanded(child: SizedBox()),
                      ),
                    ]);
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),

                const SizedBox(height: 24),

                // ── Gráfica de barras semanal ──
                weeklyAsync.when(
                  data: (stats) => _WeeklyBarChart(stats: stats),
                  loading: () =>
                      const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator())),
                  error: (e, _) => Text('Error: $e'),
                ),

                const SizedBox(height: 24),

                // ── Top apps de la semana ──
                topAppsAsync.when(
                  data: (apps) =>
                      apps.isNotEmpty ? _TopApps(apps: apps) : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                ),

              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────

class _SmallCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SmallCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final List<DayStats> stats;
  const _WeeklyBarChart({required this.stats});

  static const _days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHours = stats.isEmpty
        ? 1.0
        : stats
            .map((d) => d.total.inMinutes / 60)
            .reduce((a, b) => a > b ? a : b)
            .clamp(0.1, double.infinity);

    final bars = stats.asMap().entries.map((e) {
      final prodH = e.value.productive.inMinutes / 60;
      final nonProdH =
          (e.value.total - e.value.productive).inMinutes / 60;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: prodH + nonProdH,
            rodStackItems: [
              BarChartRodStackItem(0, prodH, theme.colorScheme.primary),
              BarChartRodStackItem(prodH, prodH + nonProdH,
                  theme.colorScheme.outline.withValues(alpha: 0.3)),
            ],
            width: 28,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('Horas por día',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              _Legend(color: theme.colorScheme.primary, label: 'Productivo'),
              const SizedBox(width: 12),
              _Legend(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  label: 'No productivo'),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxHours * 1.2,
                  barGroups: bars,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color:
                          theme.colorScheme.outline.withValues(alpha: 0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(_days[v.toInt() % 7],
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme
                                      .colorScheme.onSurfaceVariant)),
                        ),
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, gi, rod, ri) {
                        final d = stats[group.x];
                        return BarTooltipItem(
                          '${_days[group.x]}\n'
                          '${DurationText.format(d.productive)} prod.\n'
                          '${DurationText.format(d.total)} total',
                          TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 11),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ]);
  }
}

class _TopApps extends StatelessWidget {
  final List<({String appName, Duration total})> apps;
  const _TopApps({required this.apps});

  @override
  Widget build(BuildContext context) {
    final maxSeconds = apps.isEmpty
        ? 1
        : apps.map((a) => a.total.inSeconds).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top aplicaciones',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...apps.map((app) {
              final pct = app.total.inSeconds / maxSeconds;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  SizedBox(
                    width: 120,
                    child: Text(app.appName,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 56,
                    child: DurationText(app.total,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                  ),
                ]),
              );
            }),
          ],
        ),
      ),
    );
  }
}
