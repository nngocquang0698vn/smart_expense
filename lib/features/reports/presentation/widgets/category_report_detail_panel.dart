import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/features/reports/application/report_category_detail_args.dart";
import "package:smart_expense/features/reports/presentation/widgets/category_report_detail_body.dart";
import "package:smart_expense/shared/components/app_empty_state.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

/// Panel chi tiết hạng mục (desktop master-detail).
class CategoryReportDetailPanel extends ConsumerWidget {
  const CategoryReportDetailPanel({
    super.key,
    required this.args,
    required this.onClose,
  });

  final ReportCategoryDetailArgs? args;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (args == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: AppEmptyState(
            message: context.l10n.reportSelectCategoryHint,
            icon: Icons.touch_app_outlined,
          ),
        ),
      );
    }

    return CategoryReportDetailBody(
      args: args!,
      onClose: onClose,
      embeddedInPanel: true,
    );
  }
}
