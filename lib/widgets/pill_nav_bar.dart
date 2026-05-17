import "package:flutter/material.dart";

import "../core/strings.dart";

class PillNavBar extends StatelessWidget {
  const PillNavBar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.fab,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final Widget fab;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      elevation: 6,
      shadowColor: Colors.black26,
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavIcon(
              icon: Icons.home_rounded,
              selected: currentIndex == 0,
              onTap: () => onSelect(0),
              tooltip: AppStrings.navHome,
            ),
            _NavIcon(
              icon: Icons.fact_check_rounded,
              selected: currentIndex == 1,
              onTap: () => onSelect(1),
              tooltip: AppStrings.navPending,
            ),
            fab,
            _NavIcon(
              icon: Icons.pie_chart_outline_rounded,
              selected: currentIndex == 2,
              onTap: () => onSelect(2),
              tooltip: AppStrings.navAnalytics,
            ),
            _NavIcon(
              icon: Icons.person_rounded,
              selected: currentIndex == 3,
              onTap: () => onSelect(3),
              tooltip: AppStrings.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: selected ? cs.primary : cs.onSurfaceVariant),
        ),
      ),
    );
  }
}
