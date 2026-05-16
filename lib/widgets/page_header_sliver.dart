import "package:flutter/material.dart";

import "../core/constants.dart";

/// Page title row that matches [HomeScreen] desktop headers on wide layouts.
///
/// On desktop the title sits on the content panel (no [SliverAppBar] fill).
/// On mobile it uses [SliverAppBar.large] with the theme app-bar colours.
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

    if (isDesktop) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (actions.isNotEmpty) ...[
                const Spacer(),
                ...actions,
              ],
            ],
          ),
        ),
      );
    }

    return SliverAppBar.large(
      title: Text(title),
      actions: actions,
    );
  }
}
