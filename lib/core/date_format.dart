import "package:intl/intl.dart";

/// Transaction list / picker date (`16/05/2026`).
String formatTransactionDate(DateTime date) =>
    DateFormat("dd/MM/yyyy", "vi").format(date);

/// Editor list tile subtitle (`16 thg 5, 2026`).
String formatTransactionDateLong(DateTime date) =>
    DateFormat.yMMMd("vi").format(date);

/// Day group header (`Thứ Bảy, 16 thg 5, 2026`).
String formatDayHeader(DateTime day) => DateFormat.yMMMEd("vi").format(day);

/// Compact day label on transaction rows (`16 thg 5`).
String formatDayShort(DateTime date) => DateFormat.MMMd("vi").format(date);

/// Shell sidebar clock (`14:30`).
String formatShellTime(DateTime now) => DateFormat("HH:mm", "vi").format(now);

/// Shell sidebar date (`Thứ Bảy, 16 thg 5, 2026`).
String formatShellDate(DateTime now) =>
    DateFormat("EEEE, d MMM y", "vi").format(now);

/// Report chart axis / filter chip (`16/05`).
String formatReportAxis(DateTime date) => DateFormat("dd/MM", "vi").format(date);

/// Quick-entry auto title timestamp (`16/05 14:30`).
String formatQuickEntryTimestamp(DateTime date) =>
    DateFormat("dd/MM HH:mm").format(date);
