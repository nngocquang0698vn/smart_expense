import "package:flutter/material.dart";

import "package:smart_expense/core/constants/app_constants.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/shared/design_system/theme/app_finance_colors.dart";

class TransactionTypeToggle extends StatelessWidget {
  const TransactionTypeToggle({
    super.key,
    required this.isIncome,
    required this.onChanged,
    this.showSelectedIcon = true,
    this.onSideChanged,
  });

  final bool isIncome;
  final ValueChanged<bool> onChanged;
  final bool showSelectedIcon;
  final VoidCallback? onSideChanged;

  @override
  Widget build(BuildContext context) {
    final finance = context.financeColors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        color: finance.fieldFill,
        border: Border.all(color: finance.fieldBorder),
      ),
      child: SegmentedButton<bool>(
        showSelectedIcon: showSelectedIcon,
        segments: [
          ButtonSegment(value: false, label: Text(context.l10n.expense)),
          ButtonSegment(value: true, label: Text(context.l10n.income)),
        ],
        selected: {isIncome},
        onSelectionChanged: (selection) {
          onChanged(selection.first);
          onSideChanged?.call();
        },
      ),
    );
  }
}
