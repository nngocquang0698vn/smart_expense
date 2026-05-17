import "package:intl/intl.dart";

/// Avoids intl [MMM] in locale `vi`, which abbreviates months as `thg`.
const _vi = "vi";
const _monthWord = "d 'tháng' M";
const _monthWordYear = "d 'tháng' M, y";
const _weekdayMonthWordYear = "EEEE, d 'tháng' M, y";

/// Transaction list / picker date (`16/05/2026`).
String formatTransactionDate(DateTime date) =>
    DateFormat("dd/MM/yyyy", _vi).format(date);

/// Editor list tile subtitle (`16 tháng 5, 2026`).
String formatTransactionDateLong(DateTime date) =>
    DateFormat(_monthWordYear, _vi).format(date);

/// Day group header (`Thứ Bảy, 16 tháng 5, 2026`).
String formatDayHeader(DateTime day) =>
    DateFormat(_weekdayMonthWordYear, _vi).format(day);

/// Compact day label on transaction rows (`16 tháng 5`).
String formatDayShort(DateTime date) => DateFormat(_monthWord, _vi).format(date);

/// Shell sidebar clock (`14:30`).
String formatShellTime(DateTime now) => DateFormat("HH:mm", _vi).format(now);

/// Shell sidebar date (`Thứ Bảy, 16 tháng 5, 2026`).
String formatShellDate(DateTime now) =>
    DateFormat(_weekdayMonthWordYear, _vi).format(now);

/// Report chart axis / filter chip (`16/05`).
String formatReportAxis(DateTime date) => DateFormat("dd/MM", "vi").format(date);

/// Quick-entry auto title timestamp (`16/05 14:30`).
String formatQuickEntryTimestamp(DateTime date) =>
    DateFormat("dd/MM HH:mm").format(date);
