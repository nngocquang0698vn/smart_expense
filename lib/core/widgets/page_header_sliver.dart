import "package:flutter/material.dart";

import "../constants.dart";

/// Compact page title row — same layout on phone and desktop.
///
/// Avoids [SliverAppBar.large] on mobile, which leaves a tall empty band above
/// the title when the page has little scrollable content (Báo cáo, Cá nhân).
class PageHeaderSliver extends StatelessWidget {
  const PageHeaderSliver({
    super.key,
    required this.title,
    this.actions = const [],
  });

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;
    final topInset = MediaQuery.paddingOf(context).top;

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isDesktop ? 20 : 16,
          isDesktop ? 16 : topInset + 8,
          isDesktop ? 20 : 16,
          12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (actions.isNotEmpty) ...actions,
          ],
        ),
      ),
    );
  }
}
