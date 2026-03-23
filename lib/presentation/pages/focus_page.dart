import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class FocusPage extends ConsumerWidget {
  const FocusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusAsync = ref.watch(focusNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Sesión de Foco'),
      ),
      body: focusAsync.when(
        data: (state) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Selector de duración (solo cuando no está corriendo)
                  if (!state.isRunning) ...[
                    Text('Duración de la sesión',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 15, label: Text('15m')),
                        ButtonSegment(value: 25, label: Text('25m')),
                        ButtonSegment(value: 45, label: Text('45m')),
                        ButtonSegment(value: 60, label: Text('60m')),
                      ],
                      selected: {state.targetMinutes},
                      onSelectionChanged: (s) => ref
                          .read(focusNotifierProvider.notifier)
                          .setTargetMinutes(s.first),
                    ),
                    const SizedBox(height: 48),
                  ],

                  // Reloj circular
                  _FocusRing(
                    progress: state.isRunning ? state.progress : 0,
                    elapsed: state.elapsed,
                    remaining: state.remaining,
                    isRunning: state.isRunning,
                    targetMinutes: state.targetMinutes,
                  ),

                  // Indicador de calidad (durante la sesión)
                  if (state.isRunning) ...[
                    const SizedBox(height: 16),
                    _QualityIndicator(
                      interruptions: state.interruptions,
                      score: state.qualityScore,
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Botones
                  if (!state.isRunning)
                    FilledButton.icon(
                      onPressed: () => ref
                          .read(focusNotifierProvider.notifier)
                          .start(minutes: state.targetMinutes),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Iniciar Sesión de Foco'),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(240, 52)),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () =>
                          ref.read(focusNotifierProvider.notifier).stop(),
                      icon: const Icon(Icons.stop),
                      label: const Text('Detener'),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(200, 48),
                          foregroundColor:
                              Theme.of(context).colorScheme.error),
                    ),

                  const SizedBox(height: 32),

                  // Historial del día
                  _TodayFocusSummary(),
                ],
              ),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ─── Quality Indicator ────────────────────────────────────────────────────

class _QualityIndicator extends StatelessWidget {
  final int interruptions;
  final int score;
  const _QualityIndicator(
      {required this.interruptions, required this.score});

  Color _scoreColor(BuildContext context) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Theme.of(context).colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _scoreColor(context).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _scoreColor(context).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt,
              color: _scoreColor(context), size: 18),
          const SizedBox(width: 6),
          Text('Score: $score',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _scoreColor(context))),
          const SizedBox(width: 16),
          Icon(Icons.warning_amber_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 16),
          const SizedBox(width: 4),
          Text('$interruptions interrupcion${interruptions == 1 ? '' : 'es'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ─── Focus Ring ───────────────────────────────────────────────────────────

class _FocusRing extends StatelessWidget {
  final double progress;
  final Duration elapsed;
  final Duration remaining;
  final bool isRunning;
  final int targetMinutes;

  const _FocusRing({
    required this.progress,
    required this.elapsed,
    required this.remaining,
    required this.isRunning,
    required this.targetMinutes,
  });

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(240, 240),
            painter: _RingPainter(
              progress: progress.clamp(0.0, 1.0),
              color: isRunning
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              trackColor:
                  theme.colorScheme.outline.withValues(alpha: 0.15),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isRunning) ...[
                Text(
                  _fmt(remaining),
                  style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary),
                ),
                Text('restante',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ] else ...[
                Text('${targetMinutes}m',
                    style: theme.textTheme.displaySmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('de foco',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _RingPainter(
      {required this.progress,
      required this.color,
      required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const stroke = 12.0;

    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke);

    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── Resumen del día ──────────────────────────────────────────────────────

class _TodayFocusSummary extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final date = DateTime(today.year, today.month, today.day);
    final sessionsAsync = ref.watch(focusSessionsDailyProvider(date));

    return sessionsAsync.when(
      data: (sessions) {
        final completed = sessions.where((s) => s.completed).length;
        final totalMin = sessions
            .fold<int>(0, (a, s) => a + s.targetMinutes);
        final avgScore = sessions.isEmpty
            ? null
            : sessions
                    .where((s) => s.completed)
                    .fold<int>(0, (acc, s) => acc + 100) ~/
                sessions.length; // simplificado

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Hoy',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MiniStat(
                        label: 'Sesiones', value: '${sessions.length}'),
                    _MiniStat(
                        label: 'Completadas', value: '$completed'),
                    _MiniStat(
                        label: 'Minutos',
                        value: '$totalMin'),
                    if (avgScore != null)
                      _MiniStat(
                          label: 'Score', value: '$avgScore'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color:
                    Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
