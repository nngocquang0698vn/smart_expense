import "package:flutter/material.dart";
import "../core/date_format.dart";

import "../core/constants.dart";
import "../core/strings.dart";
import "../core/widgets/fab_center.dart";
import "../core/widgets/pill_nav_bar.dart";
import "../core/widgets/pwa_install_banner_host.dart";
import "../features/home/presentation/home_screen.dart";
import "../features/pending/presentation/pending_screen.dart";
import "../features/reports/presentation/analytics_screen.dart";
import "../features/settings/presentation/profile_screen.dart";
import "../features/transactions/presentation/add_options_sheet.dart";
import "../core/theme/app_chrome_theme.dart";
import "../core/theme/app_layout_theme.dart";
import "repo_scope.dart";

// Navigation item descriptor — keeps the desktop and mobile nav in sync.
class _NavItem {
  const _NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

const _navItems = [
  _NavItem(icon: Icons.home_rounded, label: AppStrings.navHome),
  _NavItem(icon: Icons.fact_check_rounded, label: AppStrings.navPending),
  _NavItem(icon: Icons.pie_chart_rounded, label: AppStrings.navAnalytics),
  _NavItem(icon: Icons.person_rounded, label: AppStrings.navProfile),
];

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _page = 0;

  void _goPending() => setState(() => _page = 1);

  void _selectPage(int index) => setState(() => _page = index);

  @override
  Widget build(BuildContext context) {
    final repo = RepoScope.of(context);
    final pages = [
      HomeScreen(repo: repo, onOpenPendingTab: _goPending),
      PendingScreen(repo: repo),
      AnalyticsScreen(repo: repo),
      ProfileScreen(repo: repo, onOpenPending: _goPending),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < AppBreakpoints.desktop;
        return isMobile
            ? _MobileShell(
                page: _page,
                pages: pages,
                onSelect: _selectPage,
                onFab: () => handleAddFab(context, repo),
              )
            : _DesktopShell(
                page: _page,
                pages: pages,
                onSelect: _selectPage,
                onFab: () => handleAddFab(context, repo),
              );
      },
    );
  }
}

// ── Mobile shell ──────────────────────────────────────────────────────────────

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.page,
    required this.pages,
    required this.onSelect,
    required this.onFab,
  });

  final int page;
  final List<Widget> pages;
  final ValueChanged<int> onSelect;
  final VoidCallback onFab;

  @override
  Widget build(BuildContext context) {
    // Cap system bottom inset to prevent Chrome DevTools from reporting
    // inflated viewPadding that breaks layout.
    final sysBtm = MediaQuery.of(context).viewPadding.bottom.clamp(0.0, 60.0);
    // PillNavBar intrinsic height: 8(top) + 56(row) + 8(bottom) = 72 px.
    final navBarHeight = 72.0 + 12.0 + sysBtm;

    return Scaffold(
      extendBody: true,
      body: PwaInstallBannerHost(
        pageIndex: page,
        child: IndexedStack(index: page, children: pages),
      ),
      bottomNavigationBar: SizedBox(
        height: navBarHeight,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12.0 + sysBtm),
          child: PillNavBar(
            currentIndex: page,
            onSelect: onSelect,
            fab: FabCenter(onPressed: onFab),
          ),
        ),
      ),
    );
  }
}

// ── Desktop shell ─────────────────────────────────────────────────────────────

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    required this.page,
    required this.pages,
    required this.onSelect,
    required this.onFab,
  });

  final int page;
  final List<Widget> pages;
  final ValueChanged<int> onSelect;
  final VoidCallback onFab;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final cs = Theme.of(context).colorScheme;
    final contentColor =
        Theme.of(context).extension<AppLayoutTheme>()?.desktopContentColor ??
        cs.surface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Sidebar(now: now, selectedIndex: page, onSelect: onSelect),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                    decoration: BoxDecoration(
                      color: contentColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: PwaInstallBannerHost(
                      pageIndex: page,
                      child: IndexedStack(index: page, children: pages),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 24,
              bottom: 24,
              child: FloatingActionButton(
                onPressed: onFab,
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sidebar ───────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.now,
    required this.selectedIndex,
    required this.onSelect,
  });

  final DateTime now;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final chrome =
        Theme.of(context).extension<AppChromeTheme>() ??
        AppChromeTheme.fromSeed(cs.primary, Theme.of(context).brightness);
    final timeText = formatShellTime(now);
    final dateText = formatShellDate(now);

    return Container(
      width: 288,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            chrome.sidebarGradientTop,
            chrome.sidebarGradientMid,
            chrome.sidebarGradientBottom,
          ],
          stops: const [0.0, 0.52, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chrome.sidebarBorder.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: chrome.sidebarShadow,
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            timeText,
            style: TextStyle(
              color: cs.primary,
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            dateText,
            style: TextStyle(
              color: chrome.sidebarNavInactive,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          ..._navItems.asMap().entries.map(
            (e) => _SidebarNavItem(
              icon: e.value.icon,
              label: e.value.label,
              active: selectedIndex == e.key,
              onTap: () => onSelect(e.key),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final chrome =
        Theme.of(context).extension<AppChromeTheme>() ??
        AppChromeTheme.fromSeed(cs.primary, Theme.of(context).brightness);
    final color = active ? cs.onPrimary : chrome.sidebarNavInactive;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: active ? cs.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
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
