import "package:flutter/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/date_symbol_data_local.dart";
import "package:shared_preferences/shared_preferences.dart";

import "package:smart_expense/core/utils/pwa/pwa_install_prefs.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_prompt_controller.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_service.dart";
import "package:smart_expense/core/utils/pwa/pwa_scope.dart";
import "package:smart_expense/app/theme/theme_notifier.dart";
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

  final pwaController = PwaInstallPromptController(
    installService: createPwaInstallService(),
    prefs: PwaInstallPrefs(prefs),
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        ledgerRepositoryProvider.overrideWithValue(repo),
        themeNotifierProvider.overrideWithValue(ThemeNotifier(prefs)),
        pwaInstallPromptControllerProvider.overrideWithValue(pwaController),
      ],
      child: PwaScope(
        controller: pwaController,
        child: const SmartExpenseApp(),
      ),
    ),
  );
}
