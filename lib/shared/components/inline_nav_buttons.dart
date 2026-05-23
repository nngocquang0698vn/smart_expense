import "package:flutter/material.dart";

import "package:smart_expense/shared/design_system/design_system.dart";

enum InlineNavVariant { surface, onDark }

/// Cặp nút Trước / Sau — dùng spacing, radius và màu từ design system.
class InlineNavButtons extends StatelessWidget {
  const InlineNavButtons({
    super.key,
    required this.previousLabel,
    required this.nextLabel,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    this.variant = InlineNavVariant.surface,
  });

  final String previousLabel;
  final String nextLabel;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final InlineNavVariant variant;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NavButton(
          label: previousLabel,
          icon: Icons.chevron_left_rounded,
          enabled: canGoPrevious,
          onPressed: onPrevious,
          variant: variant,
          iconAfterLabel: false,
        ),
        const SizedBox(width: AppSpacing.xxs),
        _NavButton(
          label: nextLabel,
          icon: Icons.chevron_right_rounded,
          enabled: canGoNext,
          onPressed: onNext,
          variant: variant,
          iconAfterLabel: true,
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
    required this.variant,
    required this.iconAfterLabel,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;
  final InlineNavVariant variant;
  final bool iconAfterLabel;

  @override
  Widget build(BuildContext context) {
    final finance = context.financeColors;

    final Color fg;
    final Color border;
    final Color? fill;

    switch (variant) {
      case InlineNavVariant.onDark:
        fg = enabled ? Colors.white : Colors.white38;
        border = enabled ? Colors.white54 : Colors.white24;
        fill = enabled ? Colors.white.withValues(alpha: 0.1) : null;
      case InlineNavVariant.surface:
        fg = enabled ? finance.fieldText : finance.textMuted;
        border = enabled ? finance.fieldBorder : finance.fieldBorder.withValues(alpha: 0.5);
        fill = enabled ? finance.fieldFill : finance.fieldFill.withValues(alpha: 0.5);
    }

    final iconWidget = Icon(icon, size: 18, color: fg);
    final labelWidget = Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: fg,
        fontWeight: AppTypography.semibold,
      ),
    );

    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        foregroundColor: fg,
        backgroundColor: fill,
        side: BorderSide(color: border, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: AppTypography.semibold,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!iconAfterLabel) ...[iconWidget, const SizedBox(width: 2), labelWidget],
          if (iconAfterLabel) ...[labelWidget, const SizedBox(width: 2), iconWidget],
        ],
      ),
    );
  }
}
