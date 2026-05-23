import "package:flutter/material.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/core/utils/date_format.dart";
import "package:smart_expense/features/reports/application/report_controller.dart";
import "package:smart_expense/features/reports/presentation/report_period_labels.dart";
import "package:smart_expense/features/transactions/domain/entities/date_filter.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

/// Bộ chip lọc kỳ báo cáo (Tuần / Tháng / …).
class ReportPeriodChips extends StatelessWidget {
  const ReportPeriodChips({
    super.key,
    required this.state,
    required this.onPeriodSelected,
    required this.onCustomRangePick,
  });

  final ReportState state;
  final Future<void> Function(AnalyticsPeriod period) onPeriodSelected;
  final Future<void> Function() onCustomRangePick;

  String _periodLabel(BuildContext context, AnalyticsPeriod period) {
    if (period == AnalyticsPeriod.custom &&
        state.period == AnalyticsPeriod.custom &&
        state.customRange != null) {
      return "${formatReportAxis(state.customRange!.start)} – ${formatReportAxis(state.customRange!.end)}";
    }
    return localizedAnalyticsPeriodLabel(context.l10n, period);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          for (final p in AnalyticsPeriod.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: ChoiceChip(
                label: Text(
                  p == AnalyticsPeriod.custom
                      ? (state.period == p
                            ? _periodLabel(context, p)
                            : localizedAnalyticsPeriodLabel(l10n, p))
                      : localizedAnalyticsPeriodLabel(l10n, p),
                ),
                selected: state.period == p,
                onSelected: (v) async {
                  if (!v) return;
                  if (p == AnalyticsPeriod.custom) {
                    await onCustomRangePick();
                  } else {
                    await onPeriodSelected(p);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
