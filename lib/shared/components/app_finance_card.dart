import "package:flutter/material.dart";

import "package:smart_expense/shared/design_system/design_system.dart";

class AppFinanceCard extends StatelessWidget {
  const AppFinanceCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.card,
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.backgroundColor,
    this.highlighted = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  /// Viền đậm kiểu input đang focus (vd. giao dịch đang chọn).
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final color =
        backgroundColor ?? Theme.of(context).cardTheme.color ?? cs.surface;
    final borderColor = highlighted
        ? cs.primary
        : (isDark ? AppColors.darkSurfaceAlt : AppColors.border);
    final borderWidth = highlighted ? 2.0 : 1.0;

    final content = Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
