import "package:flutter/material.dart";

import "../constants.dart";
import "../date_format.dart";
import "../strings.dart";
import "../theme/app_finance_colors.dart";
import "app_date_picker_support.dart";

enum AppDatePickerStyle { card, listTile }

Future<DateTime?> showAppDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate ?? DateTime(2000),
    lastDate: lastDate ?? DateTime(now.year + 2, 12, 31),
    locale: const Locale("vi", "VN"),
    builder: wrapDatePickerDialog,
  );
}

class AppDatePicker extends StatelessWidget {
  const AppDatePicker({
    super.key,
    required this.date,
    required this.onDateChanged,
    this.style = AppDatePickerStyle.listTile,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
  });

  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;
  final AppDatePickerStyle style;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    if (!enabled) return;
    final picked = await showAppDatePicker(
      context,
      initialDate: date,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) onDateChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    if (style == AppDatePickerStyle.card) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.calendar_today_rounded),
          title: Text(formatTransactionDate(date)),
          subtitle: const Text(AppStrings.transactionDate),
          trailing: const Icon(Icons.chevron_right),
          onTap: enabled ? () => _pick(context) : null,
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
      onTap: enabled ? () => _pick(context) : null,
    );
  }
}
