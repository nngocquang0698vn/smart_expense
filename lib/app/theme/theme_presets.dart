import "package:flutter/material.dart";

import "package:smart_expense/shared/design_system/tokens/app_colors.dart";

class ThemePreset {
  const ThemePreset(this.nameVi, this.color);

  final String nameVi;
  final Color color;
}

const List<ThemePreset> kThemePresets = [
  ThemePreset("Xanh hồng ngọc", AppColors.brandGreen),
  ThemePreset("Xanh biển đậm", Color(0xFF1D4ED8)),
  ThemePreset("Chàm", Color(0xFF4338CA)),
  ThemePreset("Tím", Color(0xFF7C3AED)),
  ThemePreset("Hồng đậm", Color(0xFFDB2777)),
  ThemePreset("Cam đỏ", Color(0xFFEA580C)),
  ThemePreset("Vàng nâu", Color(0xFFD97706)),
  ThemePreset("Xanh ngọc", Color(0xFF0891B2)),
  ThemePreset("Xám xịn", Color(0xFF475569)),
];
