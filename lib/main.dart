import "package:flutter/material.dart";
import "package:intl/date_symbol_data_local.dart";
import "package:shared_preferences/shared_preferences.dart";

import "app/smart_expense_root.dart";
import "core/theme_notifier.dart";
import "data/app_database.dart";
import "data/ledger_repository.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting("vi");

  final prefs = await SharedPreferences.getInstance();
  final db = await AppDatabase.open();
  final repo = LedgerRepository(db);
  await repo.ensureDefaults();

  runApp(SmartExpenseRoot(repo: repo, themeNotifier: ThemeNotifier(prefs)));
}
