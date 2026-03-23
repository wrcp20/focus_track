import 'package:flutter/material.dart';

/// Formatea una Duration como "2h 34m" o "45m" o "< 1m"
class DurationText extends StatelessWidget {
  final Duration duration;
  final TextStyle? style;

  const DurationText(this.duration, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return Text(_format(duration), style: style);
  }

  static String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    if (m > 0) return '${m}m';
    return '< 1m';
  }

  static String format(Duration d) => _format(d);
}
