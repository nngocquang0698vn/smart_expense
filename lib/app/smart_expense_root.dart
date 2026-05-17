import "package:flutter/material.dart";

import "../core/constants.dart";
import "../core/strings.dart";
import "../core/theme_notifier.dart";
import "../data/ledger_repository.dart";
import "../repo_scope.dart";
import "../screens/main_shell.dart";
import "../screens/onboarding_screen.dart";
import "../shared/widgets/app_loading_state.dart";
import "../theme/app_theme.dart";

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
    final meta = await widget.repo.getMeta();
    if (!mounted) return;
    setState(() => _onboarded = meta["onboarded"] == true);
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
            final settings = widget.themeNotifier.settings;
            return MaterialApp(
              title: AppStrings.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.build(settings, brightness: Brightness.light),
              darkTheme: AppTheme.build(settings, brightness: Brightness.dark),
              themeMode: settings.themePreference.materialThemeMode,
              themeAnimationDuration: AppDurations.theme,
              themeAnimationCurve: Curves.easeInOut,
              home: _onboarded == null
                  ? const Scaffold(
                      body: AppLoadingState(message: AppStrings.loading),
                    )
                  : _onboarded!
                  ? const MainShell()
                  : OnboardingScreen(repo: widget.repo, onDone: _syncMeta),
            );
          },
        ),
      ),
    );
  }
}
