import "package:flutter/material.dart";

/// A named seed colour for the theme picker.
///
/// Each preset drives an entire [ColorScheme] through
/// [ColorScheme.fromSeed], so even a single colour produces a full
/// harmonised palette for the whole app.
class ThemePreset {
  const ThemePreset(this.nameVi, this.color);

  /// Vietnamese display name shown as a tooltip.
  final String nameVi;
  final Color color;
}

/// The ordered list of preset colours shown in the theme picker.
///
/// Kept at 9 entries so they fit comfortably in a single Wrap row on
/// typical phone widths (360 dp+).
const List<ThemePreset> kThemePresets = [
  ThemePreset("Ngọc lục bảo",  Color(0xFF00544D)), // default brand green
  ThemePreset("Xanh biển đậm", Color(0xFF1D4ED8)), // deep blue
  ThemePreset("Chàm",          Color(0xFF4338CA)), // indigo
  ThemePreset("Tím",           Color(0xFF7C3AED)), // violet
  ThemePreset("Hồng đậm",      Color(0xFFDB2777)), // pink
  ThemePreset("Cam đỏ",        Color(0xFFEA580C)), // orange-red
  ThemePreset("Vàng nâu",      Color(0xFFD97706)), // amber
  ThemePreset("Xanh ngọc",     Color(0xFF0891B2)), // cyan-teal
  ThemePreset("Xám xịn",       Color(0xFF475569)), // slate
];
