import "package:flutter/material.dart";
import "package:intl/intl.dart";

import "../repo_scope.dart";
import "../widgets/add_options_sheet.dart";
import "../widgets/fab_center.dart";
import "../widgets/pill_nav_bar.dart";
import "analytics_screen.dart";
import "home_screen.dart";
import "pending_screen.dart";
import "profile_screen.dart";

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _page = 0;

  void _goPending() => setState(() => _page = 1);

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
        final mobile = constraints.maxWidth < 1000;
        if (mobile) {
          // Cap system bottom inset to prevent Chrome DevTools from
          // reporting inflated viewPadding that breaks layout.
          final sysBtm = MediaQuery.of(context).viewPadding.bottom.clamp(0.0, 60.0);
          // PillNavBar intrinsic height: 8(top) + 56(row) + 8(bottom) = 72px
          // Plus gap (12px) plus system inset.
          final navBarHeight = 72.0 + 12.0 + sysBtm;
          return Scaffold(
            extendBody: true,
            body: IndexedStack(index: _page, children: pages),
            bottomNavigationBar: SizedBox(
              height: navBarHeight,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12.0 + sysBtm),
                child: PillNavBar(
                  currentIndex: _page,
                  onSelect: (i) => setState(() => _page = i),
                  fab: FabCenter(
                    onPressed: () => handleAddFab(context, repo),
                  ),
                ),
              ),
            ),
          );
        }

        final now = DateTime.now();
        final timeText = DateFormat("HH:mm", "vi").format(now);
        final dateText = DateFormat("EEEE, d MMM y", "vi").format(now);
        return Scaffold(
          backgroundColor: const Color(0xFFEAF7FF),
          body: SafeArea(
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 288,
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDDF4FF), Color(0xFFCDEFFF)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timeText,
                            style: const TextStyle(
                              color: Color(0xFF00544D),
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateText,
                            style: TextStyle(
                              color: const Color(0xFF00544D).withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _DesktopNavItem(
                            icon: Icons.home_rounded,
                            label: "Trang chủ",
                            active: _page == 0,
                            onTap: () => setState(() => _page = 0),
                          ),
                          _DesktopNavItem(
                            icon: Icons.fact_check_rounded,
                            label: "Đối soát",
                            active: _page == 1,
                            onTap: () => setState(() => _page = 1),
                          ),
                          _DesktopNavItem(
                            icon: Icons.pie_chart_rounded,
                            label: "Báo cáo",
                            active: _page == 2,
                            onTap: () => setState(() => _page = 2),
                          ),
                          _DesktopNavItem(
                            icon: Icons.person_rounded,
                            label: "Cá nhân",
                            active: _page == 3,
                            onTap: () => setState(() => _page = 3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5FBFF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IndexedStack(index: _page, children: pages),
                      ),
                    ),
                  ],
                  ),
                  Positioned(
                    right: 24,
                    bottom: 24,
                    child: FloatingActionButton(
                      onPressed: () => handleAddFab(context, repo),
                      child: const Icon(Icons.add),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
    );
  }
}

class _DesktopNavItem extends StatelessWidget {
  const _DesktopNavItem({
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: active ? const Color(0xFF00544D) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, color: active ? Colors.white : const Color(0xFF00544D)),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xFF00544D),
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
