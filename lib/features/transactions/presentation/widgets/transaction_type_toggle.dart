import "package:flutter/material.dart";

import "../../../../core/constants.dart";
import "../../../../core/strings.dart";
import "../../../../theme/app_finance_colors.dart";

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
        borderRadius: BorderRadius.circular(AppRadius.container),
        color: finance.fieldFill,
        border: Border.all(color: finance.fieldBorder),
      ),
      child: SegmentedButton<bool>(
        showSelectedIcon: showSelectedIcon,
        segments: const [
          ButtonSegment(value: false, label: Text(AppStrings.expense)),
          ButtonSegment(value: true, label: Text(AppStrings.income)),
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
