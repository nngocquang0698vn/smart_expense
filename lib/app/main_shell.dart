import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:smart_expense/core/utils/date_format.dart";

import "package:smart_expense/core/constants/app_constants.dart";
import "package:smart_expense/shared/components/fab_center.dart";
import "package:smart_expense/shared/components/pill_nav_bar.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_controller.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_listener.dart";
import "package:smart_expense/shared/components/pwa/pwa_install_actions.dart";
import "package:smart_expense/features/dashboard/presentation/dashboard_screen.dart";
import "package:smart_expense/features/transactions/presentation/pending/pending_screen.dart";
import "package:smart_expense/features/reports/presentation/analytics_screen.dart";
import "package:smart_expense/features/settings/presentation/profile_screen.dart";
import "package:smart_expense/features/transactions/presentation/add_options_sheet.dart";
import "package:smart_expense/shared/design_system/theme/app_chrome_theme.dart";
import "package:smart_expense/shared/design_system/theme/app_layout_theme.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/app/providers.dart";

// Navigation item descriptor — keeps the desktop and mobile nav in sync.
class _NavItem {
  const _NavItem({required this.icon, required this.labelOf});

  final IconData icon;
  final String Function(AppLocalizations l10n) labelOf;
}

const _navItems = [
  _NavItem(icon: Icons.home_rounded, labelOf: _homeLabel),
  _NavItem(icon: Icons.fact_check_rounded, labelOf: _pendingLabel),
  _NavItem(icon: Icons.pie_chart_rounded, labelOf: _analyticsLabel),
  _NavItem(icon: Icons.person_rounded, labelOf: _profileLabel),
];

String _homeLabel(AppLocalizations l10n) => l10n.navHome;
String _pendingLabel(AppLocalizations l10n) => l10n.navPending;
String _analyticsLabel(AppLocalizations l10n) => l10n.navAnalytics;
String _profileLabel(AppLocalizations l10n) => l10n.navProfile;

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _page = 0;
  bool _pwaBootstrapped = false;
  final _pageStackKey = GlobalKey(debugLabel: "main-page-stack");
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardScreen(onOpenPendingTab: _goPending),
      const PendingScreen(),
      const AnalyticsScreen(),
      ProfileScreen(onOpenPending: _goPending),
    ];
  }

  void _goPending() => setState(() => _page = 1);

  void _selectPage(int index) => setState(() => _page = index);

  void _onPwaEvent() {
    if (!mounted) return;
    ref.read(pwaInstallControllerProvider.notifier).refresh();
  }

  void _bootstrapPwaIfNeeded() {
    if (!kIsWeb || _pwaBootstrapped) return;
    _pwaBootstrapped = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final notifier = ref.read(pwaInstallControllerProvider.notifier);
      await notifier.recordSession();
      listenPwaInstallAvailable(_onPwaEvent);
      listenPwaInstalled(() {
        ref.read(pwaInstallControllerProvider.notifier).markInstalled();
      });
      if (!mounted) return;
      await PwaInstallActions.showPostActionCtaIfNeeded(context, ref);
    });
  }

  @override
  void dispose() {
    if (kIsWeb) {
      cancelPwaInstallAvailableListener();
      cancelPwaInstalledListener();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _bootstrapPwaIfNeeded();
    final repo = ref.watch(ledgerRepositoryProvider);
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < AppBreakpoints.desktop;
        final navItems = _navItems
            .map(
              (item) => PillNavItem(icon: item.icon, label: item.labelOf(l10n)),
            )
            .toList(growable: false);
        return _ResponsiveShell(
          isMobile: isMobile,
          page: _page,
          pageStackKey: _pageStackKey,
          pages: _pages,
          navItems: navItems,
          onSelect: _selectPage,
          onFab: () => handleAddFab(context, repo),
        );
      },
    );
  }
}

class _ResponsiveShell extends StatelessWidget {
  const _ResponsiveShell({
    required this.isMobile,
    required this.page,
    required this.pageStackKey,
    required this.pages,
    required this.navItems,
    required this.onSelect,
    required this.onFab,
  });

  final bool isMobile;
  final int page;
  final GlobalKey pageStackKey;
  final List<Widget> pages;
  final List<PillNavItem> navItems;
  final ValueChanged<int> onSelect;
  final VoidCallback onFab;

  @override
  Widget build(BuildContext context) {
    // Cap system bottom inset to prevent Chrome DevTools from reporting
    // inflated viewPadding that breaks layout.
    final sysBtm = MediaQuery.of(context).viewPadding.bottom.clamp(0.0, 60.0);
    // PillNavBar intrinsic height: 8(top) + 56(row) + 8(bottom) = 72 px.
    final navBarHeight = 72.0 + 12.0 + sysBtm;
    final now = DateTime.now();
    final cs = Theme.of(context).colorScheme;
    final contentColor =
        Theme.of(context).extension<AppLayoutTheme>()?.desktopContentColor ??
        cs.surface;

    return Scaffold(
      extendBody: isMobile,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: !isMobile,
        bottom: !isMobile,
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: isMobile ? 0 : 288,
                  child: isMobile
                      ? const SizedBox.shrink()
                      : _Sidebar(
                          now: now,
                          items: navItems,
                          selectedIndex: page,
                          onSelect: onSelect,
                        ),
                ),
                SizedBox(width: isMobile ? 0 : 12),
                Expanded(
                  child: Container(
                    margin: isMobile
                        ? EdgeInsets.zero
                        : const EdgeInsets.fromLTRB(0, 10, 10, 10),
                    decoration: isMobile
                        ? null
                        : BoxDecoration(
                            color: contentColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                    child: IndexedStack(
                      key: pageStackKey,
                      index: page,
                      children: pages,
                    ),
                  ),
                ),
              ],
            ),
            if (!isMobile)
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
      bottomNavigationBar: isMobile
          ? SizedBox(
              height: navBarHeight,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12.0 + sysBtm),
                child: PillNavBar(
                  currentIndex: page,
                  items: navItems,
                  onSelect: onSelect,
                  fab: FabCenter(onPressed: onFab),
                ),
              ),
            )
          : null,
    );
  }
}

// ── Sidebar ───────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.now,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  final DateTime now;
  final List<PillNavItem> items;
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
          ...items.asMap().entries.map(
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
