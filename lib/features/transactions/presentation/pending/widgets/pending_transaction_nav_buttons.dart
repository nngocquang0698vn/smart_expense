import "package:flutter/material.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/shared/components/inline_nav_buttons.dart";

/// Điều hướng Trước/Sau giữa các giao dịch chờ (header panel).
class PendingTransactionNavButtons extends StatelessWidget {
  const PendingTransactionNavButtons({
    super.key,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InlineNavButtons(
      previousLabel: l10n.pendingPrevious,
      nextLabel: l10n.pendingNext,
      canGoPrevious: canGoPrevious,
      canGoNext: canGoNext,
      onPrevious: onPrevious,
      onNext: onNext,
    );
  }
}
