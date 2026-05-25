import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/app/providers.dart";
import "package:smart_expense/core/utils/date_range.dart";
import "package:smart_expense/features/reports/application/report_category_detail_args.dart";
import "package:smart_expense/features/transactions/domain/entities/category.dart";
import "package:smart_expense/features/transactions/domain/entities/ledger_transaction.dart";

typedef CategoryReportDetailData = ({
  List<LedgerTransaction> transactions,
  Map<String, LedgerCategory> categoriesById,
});

final categoryReportDetailProvider = FutureProvider.autoDispose
    .family<CategoryReportDetailData, ReportCategoryDetailArgs>((
      ref,
      args,
    ) async {
      final repo = ref.read(ledgerRepositoryProvider);
      final results = await Future.wait([
        repo.transactionsForCategory(
          categoryId: args.categoryId,
          period: args.period,
          custom: args.customRange == null
              ? null
              : AppDateRange.daysInclusive(
                  start: args.customRange!.start,
                  end: args.customRange!.end,
                ),
        ),
        repo.categories(),
      ]);

      final categories = results[1] as List<LedgerCategory>;
      return (
        transactions: results[0] as List<LedgerTransaction>,
        categoriesById: {for (final c in categories) c.id: c},
      );
    });
