import "package:flutter/material.dart";

import "package:smart_expense/shared/design_system/design_system.dart";

class AiVoiceParseButton extends StatelessWidget {
  const AiVoiceParseButton({
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final finance = context.financeColors;
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: finance.incomeAmount,
        backgroundColor: finance.incomeAmount.withValues(alpha: 0.12),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        minimumSize: const Size(0, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: finance.incomeAmount,
              ),
            )
          : const Icon(Icons.auto_awesome_rounded, size: 18),
      label: const Text("AI đọc ghi âm"),
    );
  }
}
