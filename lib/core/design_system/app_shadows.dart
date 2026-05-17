import "package:flutter/material.dart";

import "app_colors.dart";

abstract final class AppShadows {
  static const List<BoxShadow> none = [];

  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x140F172A), blurRadius: 20, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> focus = [
    BoxShadow(color: Color(0x1F006B68), blurRadius: 16, offset: Offset(0, 6)),
  ];

  static List<BoxShadow> tinted(Color color) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.16),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static List<BoxShadow> get brand => tinted(AppColors.brand);
}
