import "package:flutter/material.dart";

abstract final class AppColors {
  static const Color brandGreen = Color(0xFF006B68);
  static const Color brandGreenDark = Color(0xFF004C4A);
  static const Color brandGreenLight = Color(0xFFE6F4F3);

  static const Color brandYellow = Color(0xFFFFC62F);
  static const Color brandYellowDark = Color(0xFFD9A000);
  static const Color brandYellowLight = Color(0xFFFFF6D8);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0284C7);

  static const Color background = Color(0xFFF6F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF1F5F9);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);

  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE5E7EB);

  static const Color darkBackground = Color(0xFF071A1A);
  static const Color darkSurface = Color(0xFF0F2A29);
  static const Color darkSurfaceAlt = Color(0xFF123634);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);

  static const Color income = Color(0xFF16A34A);
  static const Color expense = Color(0xFFDC2626);
  static const Color historyBadge = brandGreen;

  static const Color surfaceAccent = brandGreenLight;
  static const Color onSurfaceAccent = brandGreenDark;

  static const Color desktopScaffold = Color(0xFFEAF7F6);
  static const Color desktopContent = Color(0xFFF6FBFA);
  static const Color sidebarGradientTop = Color(0xFFE6F4F3);
  static const Color sidebarGradientBottom = Color(0xFFCFEAE8);

  /// Backward-compatible alias used by existing theme settings.
  static const Color brand = brandGreen;
}
