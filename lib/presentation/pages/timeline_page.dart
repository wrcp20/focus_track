import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/activity_session.dart';
import '../providers/providers.dart';
import '../widgets/duration_text.dart';

class TimelinePage extends ConsumerWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(selectedDateProvider);
    final sessionsAsync = ref.watch(dailySessionsProvider(today));
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Línea de Tiempo'),
        actions: [
          // Navegar entre días
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Día anterior',
            onPressed: () => ref
                .read(selectedDateProvider.notifier)
                .state = today.subtract(const Duration(days: 1)),
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
            data: (cats) => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, i) {
                final s = sessions[sessions.length - 1 - i]; // más reciente arriba
                final cat =
                    s.categoryId != null
                        ? cats.where((c) => c.id == s.categoryId).firstOrNull
                        : null;
                return _TimelineItem(session: s, categoryName: cat?.name, categoryColor: cat?.color);
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final ActivitySession session;
  final String? categoryName;
  final String? categoryColor;

  const _TimelineItem({
    required this.session,
    this.categoryName,
    this.categoryColor,
  });

  Color get _color {
    if (categoryColor == null) return Colors.grey;
    final h = categoryColor!.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Línea de tiempo
          SizedBox(
            width: 56,
            child: Column(
              children: [
                Text(
                  timeFormat.format(session.startedAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      width: 2,
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Indicador de color + card
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: _color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Contenido
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(session.appName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            if (session.windowTitle != null &&
                                session.windowTitle!.isNotEmpty)
                              Text(
                                session.windowTitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant),
                              ),
                            if (categoryName != null)
                              Chip(
                                label: Text(categoryName!),
                                visualDensity: VisualDensity.compact,
                                side: BorderSide(color: _color),
                                labelStyle: TextStyle(
                                    fontSize: 11, color: _color),
                                padding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                      ),
                      DurationText(
                        session.duration,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
