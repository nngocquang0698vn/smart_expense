import "package:flutter/material.dart";

/// Scroll + căn giữa theo chiều dọc cho từng trang onboarding.
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
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
