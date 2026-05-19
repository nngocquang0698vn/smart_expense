import "package:flutter/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/date_symbol_data_local.dart";
import "package:shared_preferences/shared_preferences.dart";

import "package:smart_expense/features/transactions/data/app_database.dart";
import "package:smart_expense/features/transactions/data/sembast_ledger_repository.dart";
import "package:smart_expense/app/app.dart";
import "package:smart_expense/app/providers.dart";

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting("vi");

  final prefs = await SharedPreferences.getInstance();
  final db = await AppDatabase.open();
  final repo = SembastLedgerRepository(db);
  await repo.ensureDefaults();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        ledgerRepositoryProvider.overrideWithValue(repo),
      ],
      child: const SmartExpenseApp(),
    ),
  );
}
