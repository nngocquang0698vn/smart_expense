import "package:flutter/material.dart";

import "../../../data/date_filter.dart";

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
    final d = await showDatePicker(
      context: context,
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
          title: const Text("Chọn năm"),
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
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange:
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
                "Bộ lọc thời gian",
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
                    title: DateFilterSelection(
                      preset: DateFilterPreset.last30Days,
                    ).label(),
                    onTap: () => setState(
                      () => sel = const DateFilterSelection(
                        preset: DateFilterPreset.last30Days,
                      ),
                    ),
                  ),
                  _tile(
                    selected: sel.preset == DateFilterPreset.thisWeek,
                    title: DateFilterSelection(
                      preset: DateFilterPreset.thisWeek,
                    ).label(),
                    onTap: () => setState(
                      () => sel = const DateFilterSelection(
                        preset: DateFilterPreset.thisWeek,
                      ),
                    ),
                  ),
                  _tile(
                    selected: sel.preset == DateFilterPreset.thisMonth,
                    title: DateFilterSelection(
                      preset: DateFilterPreset.thisMonth,
                    ).label(),
                    onTap: () => setState(
                      () => sel = const DateFilterSelection(
                        preset: DateFilterPreset.thisMonth,
                      ),
                    ),
                  ),
                  _tile(
                    selected: sel.preset == DateFilterPreset.thisYear,
                    title: DateFilterSelection(
                      preset: DateFilterPreset.thisYear,
                    ).label(),
                    onTap: () => setState(
                      () => sel = const DateFilterSelection(
                        preset: DateFilterPreset.thisYear,
                      ),
                    ),
                  ),
                  _tile(
                    selected: sel.preset == DateFilterPreset.allTime,
                    title: DateFilterSelection(
                      preset: DateFilterPreset.allTime,
                    ).label(),
                    onTap: () => setState(
                      () => sel = const DateFilterSelection(
                        preset: DateFilterPreset.allTime,
                      ),
                    ),
                  ),
                  _tile(
                    selected: sel.preset == DateFilterPreset.pickMonth,
                    title: "Theo tháng…",
                    subtitle: sel.preset == DateFilterPreset.pickMonth
                        ? sel.label()
                        : null,
                    onTap: _pickMonth,
                  ),
                  _tile(
                    selected: sel.preset == DateFilterPreset.pickYear,
                    title: "Theo năm…",
                    subtitle: sel.preset == DateFilterPreset.pickYear
                        ? sel.label()
                        : null,
                    onTap: _pickYear,
                  ),
                  _tile(
                    selected: sel.preset == DateFilterPreset.custom,
                    title: "Khoảng ngày tuỳ chọn…",
                    subtitle: sel.preset == DateFilterPreset.custom
                        ? sel.label()
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
                child: const Text("Áp dụng"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
