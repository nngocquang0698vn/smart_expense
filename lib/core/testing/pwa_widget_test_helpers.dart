import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
// Chỉ dùng từ widget test; flutter_test là SDK test package.
// ignore: depend_on_referenced_packages
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/app/providers.dart";
import "package:smart_expense/core/testing/pwa_install_test_support.dart";
import "package:smart_expense/core/utils/pwa/pwa_providers.dart";

/// Pump widget PWA với [ProviderScope] overrides (dùng trong widget test).
Future<void> pumpPwaWidget(
  WidgetTester tester, {
  required FakePwaInstallService service,
  required Widget child,
  Map<String, Object>? prefs,
}) async {
  SharedPreferences.setMockInitialValues(prefs ?? {});
  final shared = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(shared),
        pwaInstallServiceProvider.overrideWithValue(service),
      ],
      child: MaterialApp(
        locale: const Locale("vi", "VN"),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
}
