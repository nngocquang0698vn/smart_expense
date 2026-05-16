import "package:flutter/material.dart";
import "package:intl/date_symbol_data_local.dart";
import "package:shared_preferences/shared_preferences.dart";

import "core/strings.dart";
import "core/theme_notifier.dart";
import "data/app_database.dart";
import "data/ledger_repository.dart";
import "repo_scope.dart";
import "screens/main_shell.dart";
import "screens/onboarding_screen.dart";
import "shared/widgets/app_loading_state.dart";
import "theme/app_theme.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting("vi");

  final prefs = await SharedPreferences.getInstance();
  final db = await AppDatabase.open();
  final repo = LedgerRepository(db);
  await repo.ensureDefaults();

  runApp(
    SmartExpenseRoot(
      repo: repo,
      themeNotifier: ThemeNotifier(prefs),
    ),
  );
}

class SmartExpenseRoot extends StatefulWidget {
  const SmartExpenseRoot({
    super.key,
    required this.repo,
    required this.themeNotifier,
  });

  final LedgerRepository repo;
  final ThemeNotifier themeNotifier;

  @override
  State<SmartExpenseRoot> createState() => _SmartExpenseRootState();
}

class _SmartExpenseRootState extends State<SmartExpenseRoot> {
  bool? _onboarded;

  @override
  void initState() {
    super.initState();
    _syncMeta();
  }

  Future<void> _syncMeta() async {
    final m = await widget.repo.getMeta();
    if (!mounted) return;
    setState(() => _onboarded = m["onboarded"] == true);
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      notifier: widget.themeNotifier,
      child: RepoScope(
        notifier: widget.repo,
        child: ListenableBuilder(
          listenable: widget.themeNotifier,
          builder: (context, _) {
            final s = widget.themeNotifier.settings;
            return MaterialApp(
              title: AppStrings.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.build(s, brightness: Brightness.light),
              darkTheme: AppTheme.build(s, brightness: Brightness.dark),
              themeMode: s.themePreference.materialThemeMode,
              themeAnimationDuration: const Duration(milliseconds: 300),
              themeAnimationCurve: Curves.easeInOut,
              home: _onboarded == null
                  ? const Scaffold(
                      body: AppLoadingState(message: AppStrings.loading),
                    )
                  : _onboarded!
                      ? const MainShell()
                      : OnboardingScreen(
                          repo: widget.repo,
                          onDone: _syncMeta,
                        ),
            );
          },
        ),
      ),
    );
  }
}
