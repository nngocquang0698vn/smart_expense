import "package:flutter/widgets.dart";

import "package:smart_expense/shared/design_system/design_system.dart";

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= AppBreakpoints.desktop && desktop != null) {
      return desktop!(context);
    }
    if (width >= AppBreakpoints.tablet && tablet != null) {
      return tablet!(context);
    }
    return mobile(context);
  }
}
