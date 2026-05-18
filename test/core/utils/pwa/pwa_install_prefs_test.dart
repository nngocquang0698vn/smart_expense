import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_prefs.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("snooze hides banner until expiry", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PwaInstallPrefs(await SharedPreferences.getInstance());
    expect(prefs.canShowBanner, isTrue);

    await prefs.snooze();
    expect(prefs.canShowBanner, isFalse);
    expect(prefs.snoozeUntil, isNotNull);
  });

  test("neverShow blocks banner", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PwaInstallPrefs(await SharedPreferences.getInstance());
    await prefs.setNeverShow();
    expect(prefs.canShowBanner, isFalse);
    expect(prefs.neverShow, isTrue);
  });

  test("resetPrompt clears dismiss state", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PwaInstallPrefs(await SharedPreferences.getInstance());
    await prefs.setNeverShow();
    await prefs.snooze();
    await prefs.resetPrompt();
    expect(prefs.canShowBanner, isTrue);
    expect(prefs.neverShow, isFalse);
  });
}
