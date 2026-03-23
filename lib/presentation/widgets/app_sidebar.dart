import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum NavSection { dashboard, timeline, focus, reports, categories, settings }

class AppSidebar extends StatelessWidget {
  final NavSection current;
  final ValueChanged<NavSection> onSelect;

  const AppSidebar({
    super.key,
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: AppColors.sidebarWidth,
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo / título
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bolt, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'FocusTrack',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),
          const SizedBox(height: 8),

          _NavItem(
            icon: Icons.dashboard_outlined,
            iconSelected: Icons.dashboard,
            label: 'Dashboard',
            selected: current == NavSection.dashboard,
            onTap: () => onSelect(NavSection.dashboard),
          ),
          _NavItem(
            icon: Icons.timeline_outlined,
            iconSelected: Icons.timeline,
            label: 'Línea de Tiempo',
            selected: current == NavSection.timeline,
            onTap: () => onSelect(NavSection.timeline),
          ),
          _NavItem(
            icon: Icons.timer_outlined,
            iconSelected: Icons.timer,
            label: 'Foco',
            selected: current == NavSection.focus,
            onTap: () => onSelect(NavSection.focus),
          ),
          _NavItem(
            icon: Icons.bar_chart_outlined,
            iconSelected: Icons.bar_chart,
            label: 'Reportes',
            selected: current == NavSection.reports,
            onTap: () => onSelect(NavSection.reports),
          ),

          const Spacer(),
          const Divider(height: 1),
          const SizedBox(height: 8),

          _NavItem(
            icon: Icons.label_outline,
            iconSelected: Icons.label,
            label: 'Categorías',
            selected: current == NavSection.categories,
            onTap: () => onSelect(NavSection.categories),
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            iconSelected: Icons.settings,
            label: 'Configuración',
            selected: current == NavSection.settings,
            onTap: () => onSelect(NavSection.settings),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData iconSelected;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.iconSelected,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected
            ? theme.colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  selected ? iconSelected : icon,
                  size: 20,
                  color: selected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: selected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
