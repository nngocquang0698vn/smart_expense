import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:smart_expense/app/providers.dart";
import "package:smart_expense/app/theme/theme_controller.dart";
import "package:smart_expense/app/theme/theme_settings.dart";
import "package:smart_expense/shared/design_system/tokens/app_colors.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  tearDown(() {
    container.dispose();
  });

  test("build loads ThemeSettings from SharedPreferences", () async {
    final stored = ThemeSettings(
      seedColor: Colors.indigo,
      themePreference: AppThemePreference.dark,
    );
    SharedPreferences.setMockInitialValues({
      "themeSettings": json.encode(stored.toJson()),
    });
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );

    final settings = container.read(themeControllerProvider);
    expect(settings.themePreference, AppThemePreference.dark);
    expect(settings.seedColor.toARGB32(), Colors.indigo.toARGB32());
  });

  test("build returns defaults when prefs empty", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );

    expect(container.read(themeControllerProvider), const ThemeSettings());
  });

  test("update persists and updates state", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    container.listen(themeControllerProvider, (_, _) {});

    final next = const ThemeSettings(
      themePreference: AppThemePreference.dark,
      enableAccentColors: true,
      seedColor: AppColors.brandYellow,
    );
    await container.read(themeControllerProvider.notifier).update(next);

    expect(container.read(themeControllerProvider), next);
    final raw = prefs.getString("themeSettings");
    expect(raw, isNotNull);
    expect(ThemeSettings.fromJson(raw!), next);
  });

  test("update with same settings does not write prefs again", () async {
    final initial = const ThemeSettings(
      themePreference: AppThemePreference.dark,
    );
    SharedPreferences.setMockInitialValues({
      "themeSettings": json.encode(initial.toJson()),
    });
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    container.listen(themeControllerProvider, (_, _) {});

    await container.read(themeControllerProvider.notifier).update(initial);

    expect(prefs.getString("themeSettings"), json.encode(initial.toJson()));
  });
}
