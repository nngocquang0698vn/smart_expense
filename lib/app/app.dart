import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/core/constants/app_constants.dart";
import "package:smart_expense/shared/design_system/theme/app_theme.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/app/router/app_router.dart";
import "package:smart_expense/app/theme/theme_controller.dart";

class SmartExpenseApp extends ConsumerWidget {
  const SmartExpenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeControllerProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppLocalizations.vi.appName,
      locale: AppLocalizations.vi.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(settings, brightness: Brightness.light),
      darkTheme: AppTheme.build(settings, brightness: Brightness.dark),
      themeMode: settings.themePreference.materialThemeMode,
      themeAnimationDuration: AppDurations.theme,
      themeAnimationCurve: Curves.easeInOut,
      routerConfig: router,
    );
  }
}
