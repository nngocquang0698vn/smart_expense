import "package:flutter/foundation.dart";
import "package:flutter/material.dart" show DateTimeRange;
import "package:smart_expense/core/utils/date_format.dart";

import "package:smart_expense/features/transactions/data/date_filter.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";
import "package:smart_expense/features/transactions/data/models/category_model.dart";
import "package:smart_expense/features/reports/application/report_view_model.dart";

class ReportController extends ChangeNotifier {
  ReportController(
    this._repo, {
    ReportViewModelBuilder builder = const ReportViewModelBuilder(),
  }) : _builder = builder {
    _repo.addListener(load);
  }

  final LedgerRepository _repo;
  final ReportViewModelBuilder _builder;

  AnalyticsPeriod period = AnalyticsPeriod.month;
  DateTimeRange? customRange;
  bool incomeSide = false;
  bool loading = true;
  ReportViewModel viewModel = const ReportViewModel.empty();

  bool _disposed = false;

  Future<void> load() async {
    loading = true;
    _notifyIfActive();

    final results = await Future.wait([
      _repo.analyticsTotals(period: period, custom: customRange),
      _repo.categoryBreakdown(
        period: period,
        incomeSide: incomeSide,
        custom: customRange,
      ),
      _repo.categories(),
    ]);
    if (_disposed) return;

    viewModel = _builder.build(
      totals: results[0] as Map<String, int>,
      breakdown: results[1] as Map<String, int>,
      categories: results[2] as List<CategoryModel>,
    );
    loading = false;
    notifyListeners();
  }

  Future<void> selectPeriod(AnalyticsPeriod next) async {
    period = next;
    customRange = null;
    await load();
  }

  Future<void> selectCustomRange(DateTimeRange range) async {
    period = AnalyticsPeriod.custom;
    customRange = range;
    await load();
  }

  Future<void> selectIncomeSide(bool next) async {
    if (incomeSide == next) return;
    incomeSide = next;
    await load();
  }

  String periodLabel() {
    if (period == AnalyticsPeriod.custom && customRange != null) {
      return "${formatReportAxis(customRange!.start)} - ${formatReportAxis(customRange!.end)}";
    }
    return period.labelVi;
  }

  @override
  void dispose() {
    _disposed = true;
    _repo.removeListener(load);
    super.dispose();
  }

  void _notifyIfActive() {
    if (!_disposed) notifyListeners();
  }
}
