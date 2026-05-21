import "package:flutter/material.dart";

abstract final class AppNotificationTokens {
  static const Duration durationNormal = Duration(seconds: 3);
  static const Duration durationLong = Duration(seconds: 4);

  static const double maxWidth = 520;
  static const double compactMobileWidth = 360;
  static const double mobileHorizontalMargin = 16;
  static const double compactMobileHorizontalMargin = 12;
  static const double wideHorizontalMargin = 32;
  static const double topMargin = 12;
  static const double mobileRadius = 16;
  static const double wideRadius = 20;
  static const EdgeInsets compactMobilePadding = EdgeInsets.fromLTRB(
    12,
    10,
    6,
    10,
  );
  static const EdgeInsets mobilePadding = EdgeInsets.fromLTRB(16, 12, 8, 12);
  static const EdgeInsets widePadding = EdgeInsets.fromLTRB(18, 14, 10, 14);
  static const double iconBoxSize = 36;
  static const double iconSize = 20;
  static const double closeButtonSize = 40;
  static const double compactCloseButtonSize = 36;

  static const double shadowAlpha = 0.14;
  static const double shadowBlur = 24;
  static const Offset shadowOffset = Offset(0, 10);

  static const double toneBackgroundAlpha = 0.12;
  static const double toneBorderAlpha = 0.22;

  static const int titleMaxLines = 2;
  static const int messageMaxLines = 3;

  static double horizontalMargin(double width, double tabletBreakpoint) {
    if (width <= compactMobileWidth) return compactMobileHorizontalMargin;
    if (width < tabletBreakpoint) return mobileHorizontalMargin;
    return wideHorizontalMargin;
  }

  static double radius(double width, double tabletBreakpoint) {
    return width < tabletBreakpoint ? mobileRadius : wideRadius;
  }

  static EdgeInsets padding(double width, double tabletBreakpoint) {
    if (width <= compactMobileWidth) return compactMobilePadding;
    if (width < tabletBreakpoint) return mobilePadding;
    return widePadding;
  }

  static double closeButtonSizeFor(double width) {
    return width <= compactMobileWidth
        ? compactCloseButtonSize
        : closeButtonSize;
  }
}
