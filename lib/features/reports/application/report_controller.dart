import "package:flutter/foundation.dart";
import "package:flutter/material.dart" show DateTimeRange;
import "package:intl/intl.dart";

import "../../../data/date_filter.dart";
import "../../../data/ledger_repository.dart";
import "../../../data/models/category_model.dart";
import "report_view_model.dart";

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
      final formatter = DateFormat("dd/MM", "vi");
      return "${formatter.format(customRange!.start)} - ${formatter.format(customRange!.end)}";
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
