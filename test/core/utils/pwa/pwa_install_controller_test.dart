import "package:flutter_test/flutter_test.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:smart_expense/app/providers.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_controller.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_service.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_storage.dart";
import "package:smart_expense/core/utils/pwa/pwa_platform_kind.dart";
import "package:smart_expense/core/utils/pwa/pwa_providers.dart";

class _FakePwaInstallService implements PwaInstallService {
  _FakePwaInstallService({
    this.isStandalone = false,
    this.canNativePrompt = true,
  }) : userAgent =
            "mozilla/5.0 (linux; android 10; k) applewebkit/537.36 chrome/91.0";

  @override
  final bool isStandalone;

  @override
  bool canNativePrompt;

  @override
  final String? userAgent;

  @override
  Future<PwaInstallPromptResult> promptInstall() async =>
      PwaInstallPromptResult.unavailable;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late _FakePwaInstallService service;

  ProviderContainer createContainer({SharedPreferences? prefs}) {
    return ProviderContainer(
      overrides: [
        if (prefs != null) sharedPreferencesProvider.overrideWithValue(prefs),
        pwaInstallServiceProvider.overrideWithValue(service),
      ],
    );
  }

  tearDown(() {
    container.dispose();
  });

  test("build exposes service canNativeInstall", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    service = _FakePwaInstallService(canNativePrompt: false);
    container = createContainer(prefs: prefs);
    container.listen(pwaInstallControllerProvider, (_, _) {});

    expect(
      container.read(pwaInstallControllerProvider).canNativeInstall,
      isFalse,
    );
  });

  test("hides onboarding card when installed", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await PwaInstallStorage(prefs).markInstalled();
    service = _FakePwaInstallService();
    container = createContainer(prefs: prefs);
    container.listen(pwaInstallControllerProvider, (_, _) {});

    final notifier = container.read(pwaInstallControllerProvider.notifier);
    expect(notifier.shouldShowOnboardingCard(isWeb: true), isFalse);
  });

  test("hides onboarding card after third dismiss", () async {
    SharedPreferences.setMockInitialValues({"pwa_install_dismiss_count": 3});
    final prefs = await SharedPreferences.getInstance();
    service = _FakePwaInstallService();
    container = createContainer(prefs: prefs);
    container.listen(pwaInstallControllerProvider, (_, _) {});

    final notifier = container.read(pwaInstallControllerProvider.notifier);
    expect(notifier.shouldShowOnboardingCard(isWeb: true), isFalse);
  });

  test("recordDismiss increments count and blocks auto prompt", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    service = _FakePwaInstallService();
    container = createContainer(prefs: prefs);
    container.listen(pwaInstallControllerProvider, (_, _) {});

    final notifier = container.read(pwaInstallControllerProvider.notifier);
    await notifier.recordDismiss();

    expect(
      container.read(pwaInstallControllerProvider).dismissCount,
      1,
    );
    expect(
      container.read(pwaInstallControllerProvider).canShowAutoPrompt,
      isFalse,
    );
  });

  test("marks first complete transaction only once in storage", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    service = _FakePwaInstallService();
    container = createContainer(prefs: prefs);
    container.listen(pwaInstallControllerProvider, (_, _) {});

    final notifier = container.read(pwaInstallControllerProvider.notifier);
    await notifier.onFirstCompleteTransactionSaved(
      pending: false,
      complete: true,
      isWeb: true,
    );
    expect(PwaInstallStorage(prefs).firstCompleteTransactionSaved, isTrue);

    await notifier.onFirstCompleteTransactionSaved(
      pending: false,
      complete: true,
      isWeb: true,
    );
    expect(PwaInstallStorage(prefs).firstCompleteTransactionSaved, isTrue);
  });

  test("schedulePostActionCta sets flag when eligible", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    service = _FakePwaInstallService();
    container = createContainer(prefs: prefs);
    container.listen(pwaInstallControllerProvider, (_, _) {});

    container
        .read(pwaInstallControllerProvider.notifier)
        .schedulePostActionCta(isWeb: true);
    expect(
      container.read(pwaInstallControllerProvider).showPostActionCta,
      isTrue,
    );
  });

  test("refresh updates canNativeInstall from service", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    service = _FakePwaInstallService(canNativePrompt: false);
    container = createContainer(prefs: prefs);
    container.listen(pwaInstallControllerProvider, (_, _) {});

    expect(
      container.read(pwaInstallControllerProvider).canNativeInstall,
      isFalse,
    );

    service.canNativePrompt = true;
    container.read(pwaInstallControllerProvider.notifier).refresh();
    expect(
      container.read(pwaInstallControllerProvider).canNativeInstall,
      isTrue,
    );
  });
}
