import "package:flutter/material.dart";
import "package:intl/date_symbol_data_local.dart";
import "package:shared_preferences/shared_preferences.dart";

import "app/smart_expense_root.dart";
import "core/pwa/pwa_install_prefs.dart";
import "core/pwa/pwa_install_prompt_controller.dart";
import "core/pwa/pwa_install_service.dart";
import "core/pwa/pwa_scope.dart";
import "core/theme_notifier.dart";
import "data/app_database.dart";
import "data/sembast_ledger_repository.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting("vi");

  final prefs = await SharedPreferences.getInstance();
  final db = await AppDatabase.open();
  final repo = SembastLedgerRepository(db);
  await repo.ensureDefaults();

  final pwaController = PwaInstallPromptController(
    installService: createPwaInstallService(),
    prefs: PwaInstallPrefs(prefs),
  );

  runApp(
    PwaScope(
      controller: pwaController,
      child: SmartExpenseRoot(repo: repo, themeNotifier: ThemeNotifier(prefs)),
    ),
  );
}
