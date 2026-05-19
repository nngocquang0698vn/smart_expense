import "package:flutter/material.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/shared/components/app_date_picker.dart";
import "package:smart_expense/shared/components/app_date_range_picker.dart";
import "package:smart_expense/features/transactions/data/date_filter.dart";

String localizedDateFilterLabel(
  AppLocalizations l10n,
  DateFilterSelection selection,
) {
  switch (selection.preset) {
    case DateFilterPreset.last30Days:
      return l10n.dateFilterLast30Days;
    case DateFilterPreset.thisWeek:
      return l10n.dateFilterThisWeek;
    case DateFilterPreset.thisMonth:
      return l10n.dateFilterThisMonth;
    case DateFilterPreset.thisYear:
      return l10n.dateFilterThisYear;
    case DateFilterPreset.allTime:
      return l10n.dateFilterAllTime;
    case DateFilterPreset.pickMonth:
      final month = selection.month ?? DateTime.now();
      return l10n.dateFilterMonthValue(month.month, month.year);
    case DateFilterPreset.pickYear:
      return l10n.dateFilterYearValue(selection.year ?? DateTime.now().year);
    case DateFilterPreset.custom:
      return l10n.dateFilterCustom;
  }
}

Future<DateFilterSelection?> showDateFilterSheet(
  BuildContext context,
  DateFilterSelection current,
) {
  return showModalBottomSheet<DateFilterSelection>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _DateFilterBody(initial: current),
  );
}

class _DateFilterBody extends StatefulWidget {
  const _DateFilterBody({required this.initial});

  final DateFilterSelection initial;

  @override
  State<_DateFilterBody> createState() => _DateFilterBodyState();
}

class _DateFilterBodyState extends State<_DateFilterBody> {
  late DateFilterSelection sel;

  @override
  void initState() {
    super.initState();
    sel = widget.initial;
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final d = await showAppDatePicker(
      context,
      initialDate: sel.month ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12),
    );
    if (d != null && mounted) {
      setState(() {
        sel = DateFilterSelection(
          preset: DateFilterPreset.pickMonth,
          month: DateTime(d.year, d.month),
        );
      });
    }
  }

  Future<void> _pickYear() async {
    final now = DateTime.now();
    final y = sel.year ?? now.year;
    final picked = await showDialog<int>(
      context: context,
      builder: (c) {
        return AlertDialog(
          title: Text(context.l10n.pickYearTitle),
          content: SizedBox(
            width: 280,
            height: 260,
            child: YearPicker(
              firstDate: DateTime(2000),
              lastDate: DateTime(now.year + 1),
              selectedDate: DateTime(y),
              onChanged: (d) => Navigator.pop(c, d.year),
            ),
          ),
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        sel = DateFilterSelection(
          preset: DateFilterPreset.pickYear,
          year: picked,
        );
      });
    }
  }

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final range = await showAppDateRangePicker(
      context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialRange:
          sel.custom ??
          DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
    );
    if (range != null && mounted) {
      setState(() {
        sel = DateFilterSelection(
          preset: DateFilterPreset.custom,
          custom: range,
        );
      });
    }
  }

  Widget _tile({
    required bool selected,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                l10n.dateFilterTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _tile(
                    selected: sel.preset == DateFilterPreset.last30Days,
                    title: localizedDateFilterLabel(
                      l10n,
                      const DateFilterSelection(
                        preset: DateFilterPreset.last30Days,
                      ),
                    ),
                    onTap: () => setState(
                      () => sel = const DateFilterSelection(
                        preset: DateFilterPreset.last30Days,
                      ),
                    ),
                  ),
                  _tile(
                    selected: sel.preset == DateFilterPreset.thisWeek,
                    title: localizedDateFilterLabel(
                      l10n,
                      const DateFilterSelection(
                        preset: DateFilterPreset.thisWeek,
                      ),
                    ),
                    onTap: () => setState(
                      () => sel = const DateFilterSelection(
                        preset: DateFilterPreset.thisWeek,
                      ),
                    ),
                  ),
                  _tile(
                    selected: sel.preset == DateFilterPreset.thisMonth,
                    title: localizedDateFilterLabel(
                      l10n,
                      const DateFilterSelection(
                        preset: DateFilterPreset.thisMonth,
                      ),
                    ),
                    onTap: () => setState(
                      () => sel = const DateFilterSelection(
                        preset: DateFilterPreset.thisMonth,
                      ),
                    ),
                  ),
                  _tile(
                    selected: sel.preset == DateFilterPreset.thisYear,
                    title: localizedDateFilterLabel(
                      l10n,
                      const DateFilterSelection(
                        preset: DateFilterPreset.thisYear,
                      ),
                    ),
                    onTap: () => setState(
                      () => sel = const DateFilterSelection(
                        preset: DateFilterPreset.thisYear,
                      ),
                    ),
                  ),
                  _tile(
                    selected: sel.preset == DateFilterPreset.allTime,
                    title: localizedDateFilterLabel(
                      l10n,
                      const DateFilterSelection(
                        preset: DateFilterPreset.allTime,
                      ),
                    ),
                    onTap: () => setState(
                      () => sel = const DateFilterSelection(
                        preset: DateFilterPreset.allTime,
                      ),
                    ),
                  ),
                  _tile(
                    selected: sel.preset == DateFilterPreset.pickMonth,
                    title: l10n.dateFilterPickMonth,
                    subtitle: sel.preset == DateFilterPreset.pickMonth
                        ? localizedDateFilterLabel(l10n, sel)
                        : null,
                    onTap: _pickMonth,
                  ),
                  _tile(
                    selected: sel.preset == DateFilterPreset.pickYear,
                    title: l10n.dateFilterPickYear,
                    subtitle: sel.preset == DateFilterPreset.pickYear
                        ? localizedDateFilterLabel(l10n, sel)
                        : null,
                    onTap: _pickYear,
                  ),
                  _tile(
                    selected: sel.preset == DateFilterPreset.custom,
                    title: l10n.dateFilterCustomRange,
                    subtitle: sel.preset == DateFilterPreset.custom
                        ? localizedDateFilterLabel(l10n, sel)
                        : null,
                    onTap: _pickCustom,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FilledButton(
                onPressed: () => Navigator.pop(context, sel),
                child: Text(l10n.apply),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
