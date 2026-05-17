import "package:flutter/material.dart";

import "../../../../core/constants.dart";
import "../../../../core/date_format.dart";
import "../../../../core/strings.dart";
import "../../../../core/theme/app_finance_colors.dart";

enum TransactionDatePickerStyle { card, listTile }

class TransactionDatePickerField extends StatelessWidget {
  const TransactionDatePickerField({
    super.key,
    required this.date,
    required this.onDateChanged,
    this.style = TransactionDatePickerStyle.card,
    this.firstDate,
    this.lastDate,
  });

  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;
  final TransactionDatePickerStyle style;
  final DateTime? firstDate;
  final DateTime? lastDate;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: firstDate ?? DateTime(2000),
      lastDate:
          lastDate ?? DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) onDateChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    if (style == TransactionDatePickerStyle.card) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.calendar_today_rounded),
          title: Text(formatTransactionDate(date)),
          subtitle: const Text(AppStrings.transactionDate),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _pick(context),
        ),
      );
    }

    final finance = context.financeColors;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: finance.fieldBorder),
      ),
      tileColor: finance.fieldFill,
      title: const Text(AppStrings.transactionDate),
      subtitle: Text(formatTransactionDateLong(date)),
      trailing: Icon(Icons.calendar_month, color: finance.textMuted),
      onTap: () => _pick(context),
    );
  }
}
