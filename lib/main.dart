import "package:flutter/material.dart";
import "package:intl/date_symbol_data_local.dart";

import "data/app_database.dart";
import "data/ledger_repository.dart";
import "repo_scope.dart";
import "screens/main_shell.dart";
import "screens/onboarding_screen.dart";
import "theme/app_theme.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting("vi");
  final db = await AppDatabase.open();
  final repo = LedgerRepository(db);
  await repo.ensureDefaults();
  runApp(SmartExpenseRoot(repo: repo));
}

class SmartExpenseRoot extends StatefulWidget {
  const SmartExpenseRoot({super.key, required this.repo});

  final LedgerRepository repo;

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
    return RepoScope(
      notifier: widget.repo,
      child: MaterialApp(
        title: "Smart Ledger",
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: _onboarded == null
            ? const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              )
            : _onboarded!
                ? const MainShell()
                : OnboardingScreen(
                    repo: widget.repo,
                    onDone: _syncMeta,
                  ),
      ),
    );
  }
}
