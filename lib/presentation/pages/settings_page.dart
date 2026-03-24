import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Configuración'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Rastreo (solo Windows) ──
          if (!kIsWeb) ...[
            _SectionHeader('Rastreo automático'),
            Card(
              child: Column(
                children: [
                  Consumer(
                    builder: (context, ref, _) {
                      final trackerAsync = ref.watch(trackerNotifierProvider);
                      return trackerAsync.when(
                        data: (state) => SwitchListTile(
                          title: const Text('Rastreo activo'),
                          subtitle: Text(state.isTracking
                              ? 'Registrando actividad de ventanas'
                              : 'Rastreo pausado'),
                          value: state.isTracking,
                          onChanged: (v) {
                            if (v) {
                              ref
                                  .read(trackerNotifierProvider.notifier)
                                  .startTracking();
                            } else {
                              ref
                                  .read(trackerNotifierProvider.notifier)
                                  .stopTracking();
                            }
                          },
                        ),
                        loading: () => const ListTile(
                            title: Text('Rastreo activo'),
                            trailing: CircularProgressIndicator()),
                        error: (e, _) =>
                            ListTile(title: Text('Error: $e')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── Apariencia ──
          _SectionHeader('Apariencia'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.palette_outlined, size: 20),
                      const SizedBox(width: 12),
                      Text('Tema',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('Sistema'),
                        icon: Icon(Icons.brightness_auto_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Claro'),
                        icon: Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Oscuro'),
                        icon: Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (s) =>
                        ref.read(themeModeProvider.notifier).state = s.first,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Sesiones de Foco ──
          _SectionHeader('Sesiones de Foco'),
          Card(
            child: Column(
              children: [
                _FocusDurationTile(ref: ref),
                const Divider(height: 1),
                _BreakDurationTile(ref: ref),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── IA con Claude ──
          _SectionHeader('Inteligencia Artificial'),
          const Card(child: _ApiKeyTile()),
          const SizedBox(height: 24),

          // ── Acerca de ──
          _SectionHeader('Acerca de'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  title: Text('FocusTrack'),
                  subtitle: Text('v1.0.0 — Alternativa open-source a Rize.io'),
                  leading: Icon(Icons.bolt),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Plataforma'),
                  subtitle: Text(
                      kIsWeb ? 'Web (modo dashboard)' : 'Windows Desktop'),
                  leading: Icon(
                      kIsWeb ? Icons.web : Icons.desktop_windows_outlined),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Focus duration tile ──────────────────────────────────────────────────────

class _FocusDurationTile extends ConsumerWidget {
  const _FocusDurationTile({required this.ref});
  final WidgetRef ref;

  static const _options = [15, 20, 25, 30, 45, 60];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final current = int.tryParse(
            settingsAsync.value?['focus_duration'] ?? '') ??
        25;

    return ListTile(
      title: const Text('Duración de foco'),
      subtitle: Text('$current minutos'),
      leading: const Icon(Icons.timer_outlined),
      trailing: DropdownButton<int>(
        value: _options.contains(current) ? current : 25,
        underline: const SizedBox(),
        items: _options
            .map((m) => DropdownMenuItem(value: m, child: Text('$m min')))
            .toList(),
        onChanged: (v) {
          if (v != null) {
            ref
                .read(settingsProvider.notifier)
                .set('focus_duration', '$v');
          }
        },
      ),
    );
  }
}

// ── Break duration tile ──────────────────────────────────────────────────────

class _BreakDurationTile extends ConsumerWidget {
  const _BreakDurationTile({required this.ref});
  final WidgetRef ref;

  static const _options = [5, 10, 15, 20];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final current = int.tryParse(
            settingsAsync.value?['break_duration'] ?? '') ??
        5;

    return ListTile(
      title: const Text('Duración del descanso'),
      subtitle: Text('$current minutos'),
      leading: const Icon(Icons.coffee_outlined),
      trailing: DropdownButton<int>(
        value: _options.contains(current) ? current : 5,
        underline: const SizedBox(),
        items: _options
            .map((m) => DropdownMenuItem(value: m, child: Text('$m min')))
            .toList(),
        onChanged: (v) {
          if (v != null) {
            ref
                .read(settingsProvider.notifier)
                .set('break_duration', '$v');
          }
        },
      ),
    );
  }
}

// ── API Key tile ─────────────────────────────────────────────────────────────

class _ApiKeyTile extends ConsumerStatefulWidget {
  const _ApiKeyTile();

  @override
  ConsumerState<_ApiKeyTile> createState() => _ApiKeyTileState();
}

class _ApiKeyTileState extends ConsumerState<_ApiKeyTile> {
  bool _obscure = true;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final val = ref.read(settingsProvider).value?['claude_api_key'] ?? '';
      _ctrl.text = val;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    ref
        .read(settingsProvider.notifier)
        .set('claude_api_key', _ctrl.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('API key guardada'),
          duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context, ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.vpn_key_outlined, size: 20),
              const SizedBox(width: 12),
              Text('Clave API de Claude',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Habilita auto-categorización IA y resúmenes del día',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              hintText: 'sk-ant-api03-...',
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: IconButton(
                icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Consigue tu key en console.anthropic.com',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              FilledButton.tonal(
                onPressed: _save,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
