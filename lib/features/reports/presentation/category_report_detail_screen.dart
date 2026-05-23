import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/features/reports/application/report_category_detail_args.dart";
import "package:smart_expense/features/reports/presentation/widgets/category_report_detail_body.dart";

/// Báo cáo chi tiết hạng mục — full screen (mobile).
class CategoryReportDetailScreen extends ConsumerWidget {
  const CategoryReportDetailScreen({super.key, required this.args});

  final ReportCategoryDetailArgs args;

  static Route<void> route(ReportCategoryDetailArgs args) {
    return MaterialPageRoute<void>(
      builder: (_) => CategoryReportDetailScreen(args: args),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: CategoryReportDetailBody(
          args: args,
          showPeriodFilters: true,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
