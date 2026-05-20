import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_storage.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("canShowAutoPrompt is true before any dismiss", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = PwaInstallStorage(prefs);
    expect(storage.canShowAutoPrompt, isTrue);
  });

  test("first dismiss blocks auto prompt until cooldown", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = PwaInstallStorage(prefs);
    await storage.recordDismiss();
    expect(storage.canShowAutoPrompt, isFalse);
    expect(storage.dismissCount, 1);
  });

  test("third dismiss permanently blocks auto prompt", () async {
    SharedPreferences.setMockInitialValues({"pwa_install_dismiss_count": 3});
    final prefs = await SharedPreferences.getInstance();
    final storage = PwaInstallStorage(prefs);
    expect(storage.canShowAutoPrompt, isFalse);
  });

  test("markFirstCompleteTransactionSaved returns true only once", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = PwaInstallStorage(prefs);
    expect(await storage.markFirstCompleteTransactionSaved(), isTrue);
    expect(await storage.markFirstCompleteTransactionSaved(), isFalse);
  });
}
