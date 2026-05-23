import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:smart_expense/app/providers.dart";
import "package:smart_expense/features/settings/application/user_preferences_controller.dart";
import "package:smart_expense/features/settings/domain/user_preferences.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  tearDown(() {
    container.dispose();
  });

  test("defaults quickConfirmPending to true", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );

    expect(
      container.read(userPreferencesControllerProvider).quickConfirmPending,
      isTrue,
    );
  });

  test("update persists quickConfirmPending", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );

    await container
        .read(userPreferencesControllerProvider.notifier)
        .update(const UserPreferences(quickConfirmPending: false));

    expect(
      container.read(userPreferencesControllerProvider).quickConfirmPending,
      isFalse,
    );

    final raw = prefs.getString("userPreferences");
    expect(raw, isNotNull);
    final decoded = jsonDecode(raw!) as Map<String, dynamic>;
    expect(decoded["quickConfirmPending"], isFalse);
  });
}
