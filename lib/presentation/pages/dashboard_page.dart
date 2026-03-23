import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/app_category.dart';
import '../providers/providers.dart';
import '../widgets/duration_text.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(selectedDateProvider);
    final sessionsAsync = ref.watch(dailySessionsProvider(today));
    final durMapAsync = ref.watch(durationByCategoryProvider(today));
    final categoriesAsync = ref.watch(categoriesProvider);
    final tracker = ref.watch(trackerNotifierProvider);
    final prodAsync = ref.watch(productiveStatsProvider(today));
    final hourlyAsync = ref.watch(hourlyDistributionProvider(today));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, d MMMM yyyy', 'es').format(today),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                ),
              ],
            ),
            actions: [
              if (!kIsWeb)
                tracker.when(
                  data: (state) => FilledButton.icon(
                    onPressed: () {
                      if (state.isTracking) {
                        ref
                            .read(trackerNotifierProvider.notifier)
                            .stopTracking();
                      } else {
                        ref
                            .read(trackerNotifierProvider.notifier)
                            .startTracking();
                      }
                    },
                    icon: Icon(
                        state.isTracking ? Icons.pause : Icons.play_arrow),
                    label: Text(state.isTracking ? 'Pausar' : 'Rastrear'),
                    style: state.isTracking
                        ? FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.error)
                        : null,
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                ),
              const SizedBox(width: 16),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Banner web
                if (kIsWeb) ...[
                  _WebModeBanner(),
                  const SizedBox(height: 24),
                ],

                // Ventana activa (solo Windows)
                if (!kIsWeb)
                  tracker.when(
                    data: (state) =>
                        state.isTracking && state.currentWindow != null
                            ? _ActiveWindowCard(
                                appName: state.currentWindow!.appName,
                                title: state.currentWindow!.windowTitle,
                              )
                            : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                  ),

                if (!kIsWeb) const SizedBox(height: 24),

                // 3 tarjetas de resumen
                prodAsync.when(
                  data: (prod) {
                    final pct = prod.total.inSeconds > 0
                        ? (prod.productive.inSeconds /
                                prod.total.inSeconds *
                                100)
                            .round()
                        : 0;
                    return Row(children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Tiempo total',
                          value: DurationText.format(prod.total),
                          icon: Icons.access_time,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Actividades',
                          value:
                              '${sessionsAsync.value?.length ?? 0}',
                          icon: Icons.list_alt,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: '% Productivo',
                          value: '$pct%',
                          icon: Icons.bolt,
                          color: pct >= 70
                              ? Colors.green
                              : pct >= 40
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                    ]);
                  },
                  loading: () => const _StatCardsSkeleton(),
                  error: (e, _) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 24),

                // Gráfica de distribución horaria
                hourlyAsync.when(
                  data: (hourly) => hourly.isNotEmpty
                      ? _HourlyChart(hourly: hourly)
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 24),

                // Gráfica de torta por categoría
                categoriesAsync.when(
                  data: (cats) => durMapAsync.when(
                    data: (durMap) =>
                        _CategoryBreakdown(durMap: durMap, categories: cats),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),

                const SizedBox(height: 24),

                // Últimas sesiones
                sessionsAsync.when(
                  data: (sessions) => _RecentSessions(
                      sessions: sessions.reversed.take(10).toList()),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets internos ─────────────────────────────────────────────────────

class _ActiveWindowCard extends StatelessWidget {
  final String appName;
  final String? title;
  const _ActiveWindowCard({required this.appName, this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                  color: Colors.green, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rastreando ahora',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                                .withValues(alpha: 0.7),
                          )),
                  Text(appName,
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              )),
                  if (title != null)
                    Text(title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                                  .withValues(alpha: 0.8),
                            )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebModeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                color: Theme.of(context).colorScheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Modo Web — Sin rastreo automático',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          )),
                  Text(
                    'El rastreo automático requiere la app de Windows. '
                    'Aquí puedes ver reportes y gestionar sesiones de foco.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _StatCardsSkeleton extends StatelessWidget {
  const _StatCardsSkeleton();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
          3,
          (_) => Expanded(
                child: Card(
                    child: Container(height: 100, color: Colors.transparent)),
              )),
    );
  }
}

class _HourlyChart extends StatelessWidget {
  final Map<int, Duration> hourly;
  const _HourlyChart({required this.hourly});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxMinutes =
        hourly.values.map((d) => d.inMinutes).fold(1, (a, b) => a > b ? a : b);

    final bars = List.generate(24, (hour) {
      final minutes = hourly[hour]?.inMinutes.toDouble() ?? 0;
      return BarChartGroupData(
        x: hour,
        barRods: [
          BarChartRodData(
            toY: minutes,
            color: theme.colorScheme.primary,
            width: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actividad por hora',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: BarChart(
                BarChartData(
                  maxY: maxMinutes.toDouble() * 1.2,
                  barGroups: bars,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: theme.colorScheme.outline.withValues(alpha: 0.15),
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
                        interval: 4,
                        getTitlesWidget: (value, _) => Text(
                          '${value.toInt()}h',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                          BarTooltipItem(
                        '${group.x}h\n${rod.toY.round()}m',
                        TextStyle(
                            color: theme.colorScheme.onPrimary, fontSize: 11),
                      ),
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

class _CategoryBreakdown extends StatelessWidget {
  final Map<int?, Duration> durMap;
  final List<AppCategory> categories;

  const _CategoryBreakdown(
      {required this.durMap, required this.categories});

  Color _hexColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    if (durMap.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.bar_chart_outlined,
                    size: 48,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text('Sin actividad registrada hoy',
                    style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ),
      );
    }

    final total =
        durMap.values.fold<int>(0, (a, d) => a + d.inSeconds);
    final sections = <PieChartSectionData>[];
    final entries = durMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in entries) {
      final cat = entry.key != null
          ? categories.where((c) => c.id == entry.key).firstOrNull
          : null;
      final color = cat != null
          ? _hexColor(cat.color)
          : Theme.of(context).colorScheme.outline;
      final pct =
          total > 0 ? entry.value.inSeconds / total * 100 : 0.0;
      sections.add(PieChartSectionData(
        value: entry.value.inSeconds.toDouble(),
        color: color,
        title: '${pct.toStringAsFixed(0)}%',
        radius: 80,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Por categoría',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 200,
                  width: 200,
                  child: PieChart(PieChartData(sections: sections)),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: entries.map((e) {
                      final cat = e.key != null
                          ? categories
                              .where((c) => c.id == e.key)
                              .firstOrNull
                          : null;
                      final color = cat != null
                          ? _hexColor(cat.color)
                          : Theme.of(context).colorScheme.outline;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(cat?.name ?? 'Sin categoría',
                                    overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 8),
                            DurationText(e.value,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentSessions extends StatelessWidget {
  final List sessions;
  const _RecentSessions({required this.sessions});

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actividad reciente',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...sessions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.apps,
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(s.appName,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  Theme.of(context).textTheme.bodyMedium)),
                      DurationText(s.duration,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
