import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Configuración'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Rastreo (solo Windows)
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

          // Foco
          _SectionHeader('Sesiones de Foco'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Duración predeterminada'),
                  subtitle: const Text('25 minutos (Pomodoro clásico)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Duración del descanso'),
                  subtitle: const Text('5 minutos'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Apariencia
          _SectionHeader('Apariencia'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Tema'),
                  subtitle: const Text('Sigue el sistema'),
                  leading: const Icon(Icons.palette_outlined),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Acerca de
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
                  subtitle: Text(kIsWeb ? 'Web (modo dashboard)' : 'Windows Desktop'),
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
