import "package:flutter/material.dart";

/// Căn giữa theo chiều dọc; chỉ scroll khi nội dung thật sự cao hơn viewport.
class OnboardingPageLayout extends StatelessWidget {
  const OnboardingPageLayout({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minContentHeight = (constraints.maxHeight - padding.vertical)
            .clamp(0.0, double.infinity);

        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minContentHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [child],
            ),
          ),
        );
      },
    );
  }
}
