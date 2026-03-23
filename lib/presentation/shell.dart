import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/app_sidebar.dart';
import 'pages/dashboard_page.dart';
import 'pages/timeline_page.dart';
import 'pages/focus_page.dart';
import 'pages/categories_page.dart';
import 'pages/reports_page.dart';
import 'pages/settings_page.dart';
import 'providers/providers.dart';

/// Pantalla raíz con sidebar y contenido central
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  NavSection _current = NavSection.dashboard;

  @override
  void initState() {
    super.initState();
    // Arrancar rastreo automático en Windows al iniciar
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(trackerNotifierProvider.notifier).startTracking();
      });
    }
  }

  Widget _body() => switch (_current) {
        NavSection.dashboard  => const DashboardPage(),
        NavSection.timeline   => const TimelinePage(),
        NavSection.focus      => const FocusPage(),
        NavSection.reports    => const ReportsPage(),
        NavSection.categories => const CategoriesPage(),
        NavSection.settings   => const SettingsPage(),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            current: _current,
            onSelect: (s) => setState(() => _current = s),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _body()),
        ],
      ),
    );
  }
}
