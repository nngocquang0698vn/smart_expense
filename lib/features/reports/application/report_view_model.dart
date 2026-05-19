import "package:smart_expense/features/transactions/domain/entities/category.dart";

class ReportCategorySlice {
  const ReportCategorySlice({
    required this.category,
    required this.amount,
    required this.id,
  });

  final LedgerCategory category;
  final int amount;
  final String id;
}

class ReportViewModel {
  const ReportViewModel({
    required this.income,
    required this.expense,
    required this.slices,
  });

  const ReportViewModel.empty() : income = 0, expense = 0, slices = const [];

  final int income;
  final int expense;
  final List<ReportCategorySlice> slices;

  int get balance => income - expense;

  int get sliceTotal => slices.fold(0, (sum, slice) => sum + slice.amount);
}

class ReportViewModelBuilder {
  const ReportViewModelBuilder();

  ReportViewModel build({
    required Map<String, int> totals,
    required Map<String, int> breakdown,
    required List<LedgerCategory> categories,
  }) {
    final categoryMap = {
      for (final category in categories) category.id: category,
    };
    final slices =
        breakdown.entries
            .where((entry) => entry.value > 0)
            .map((entry) {
              final category = categoryMap[entry.key];
              if (category == null) return null;
              return ReportCategorySlice(
                category: category,
                amount: entry.value,
                id: entry.key,
              );
            })
            .whereType<ReportCategorySlice>()
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    return ReportViewModel(
      income: totals["income"] ?? 0,
      expense: totals["expense"] ?? 0,
      slices: slices,
    );
  }
}
