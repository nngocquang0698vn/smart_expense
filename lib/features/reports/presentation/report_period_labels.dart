import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/features/transactions/domain/entities/date_filter.dart";

String localizedAnalyticsPeriodLabel(
  AppLocalizations l10n,
  AnalyticsPeriod period,
) {
  switch (period) {
    case AnalyticsPeriod.week:
      return l10n.reportPeriodWeek;
    case AnalyticsPeriod.month:
      return l10n.reportPeriodMonth;
    case AnalyticsPeriod.quarter:
      return l10n.reportPeriodQuarter;
    case AnalyticsPeriod.year:
      return l10n.reportPeriodYear;
    case AnalyticsPeriod.custom:
      return l10n.reportPeriodCustom;
  }
}
