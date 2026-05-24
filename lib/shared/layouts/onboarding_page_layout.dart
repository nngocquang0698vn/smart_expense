import "package:flutter/material.dart";

/// Căn giữa theo chiều dọc; chỉ scroll khi nội dung thật sự cao hơn viewport.
class OnboardingPageLayout extends StatelessWidget {
  const OnboardingPageLayout({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
    this.alignToTop = false,
  });

  final Widget child;
  final EdgeInsets padding;

  /// Tall scrollable pages (e.g. PWA guide) start at top instead of centering.
  final bool alignToTop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minContentHeight = (constraints.maxHeight - padding.vertical)
            .clamp(0.0, double.infinity);

        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: alignToTop ? 0 : minContentHeight,
            ),
            child: Column(
              mainAxisAlignment: alignToTop
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [child],
            ),
          ),
        );
      },
    );
  }
}
