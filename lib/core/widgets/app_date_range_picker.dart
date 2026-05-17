import "package:flutter/material.dart";

import "../constants.dart";
import "../date_format.dart";
import "../strings.dart";
import "../theme/app_finance_colors.dart";
import "app_date_picker_support.dart";

Future<DateTimeRange?> showAppDateRangePicker(
  BuildContext context, {
  DateTimeRange? initialRange,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  final now = DateTime.now();
  final first = firstDate ?? DateTime(2000);
  final last = lastDate ?? DateTime(now.year + 2, 12, 31);
  final initial =
      initialRange ??
      DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);

  return showDateRangePicker(
    context: context,
    firstDate: first,
    lastDate: last,
    initialDateRange: initial,
    locale: const Locale("vi", "VN"),
    helpText: AppStrings.dateRangeTitle,
    builder: wrapDatePickerDialog,
  );
}

class AppDateRangePicker extends StatelessWidget {
  const AppDateRangePicker({
    super.key,
    this.startDate,
    this.endDate,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTimeRange?> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;

  bool get _hasRange => startDate != null && endDate != null;

  String _rangeLabel() {
    if (!_hasRange) return AppStrings.dateRangeNotSelected;
    return "${formatTransactionDate(startDate!)} – ${formatTransactionDate(endDate!)}";
  }

  Future<void> _pick(BuildContext context) async {
    if (!enabled) return;
    final range = await showAppDateRangePicker(
      context,
      initialRange: _hasRange
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (range != null) onChanged(range);
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.financeColors;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: finance.fieldBorder),
      ),
      tileColor: finance.fieldFill,
      title: const Text(AppStrings.dateRangeTitle),
      subtitle: Text(_rangeLabel()),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasRange && enabled)
            TextButton(
              onPressed: () => onChanged(null),
              child: const Text(AppStrings.dateRangeClear),
            ),
          Icon(Icons.date_range, color: finance.textMuted),
        ],
      ),
      onTap: enabled ? () => _pick(context) : null,
    );
  }
}
