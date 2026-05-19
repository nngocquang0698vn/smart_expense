import "package:flutter_test/flutter_test.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:smart_expense/app/providers.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_controller.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_prefs.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_service.dart";
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

  test("evaluateBanner shows banner on web when prefs allow", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    service = _FakePwaInstallService();
    container = createContainer(prefs: prefs);
    container.listen(pwaInstallControllerProvider, (_, _) {});

    container.read(pwaInstallControllerProvider.notifier).evaluateBanner(
          isWeb: true,
        );

    expect(container.read(pwaInstallControllerProvider).bannerVisible, isTrue);
    expect(
      container.read(pwaInstallControllerProvider).platform,
      PwaPlatformKind.androidChrome,
    );
  });

  test("evaluateBanner hides when standalone", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    service = _FakePwaInstallService(isStandalone: true);
    container = createContainer(prefs: prefs);
    container.listen(pwaInstallControllerProvider, (_, _) {});

    container.read(pwaInstallControllerProvider.notifier).evaluateBanner(
          isWeb: true,
        );

    expect(
      container.read(pwaInstallControllerProvider).bannerVisible,
      isFalse,
    );
  });

  test("evaluateBanner hides when neverShow", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await PwaInstallPrefs(prefs).setNeverShow();
    service = _FakePwaInstallService();
    container = createContainer(prefs: prefs);
    container.listen(pwaInstallControllerProvider, (_, _) {});

    container.read(pwaInstallControllerProvider.notifier).evaluateBanner(
          isWeb: true,
        );

    expect(
      container.read(pwaInstallControllerProvider).bannerVisible,
      isFalse,
    );
  });

  test("evaluateBanner hides when snoozed", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await PwaInstallPrefs(prefs).snooze();
    service = _FakePwaInstallService();
    container = createContainer(prefs: prefs);
    container.listen(pwaInstallControllerProvider, (_, _) {});

    container.read(pwaInstallControllerProvider.notifier).evaluateBanner(
          isWeb: true,
        );

    expect(
      container.read(pwaInstallControllerProvider).bannerVisible,
      isFalse,
    );
  });

  test("snooze hides banner and blocks prefs", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    service = _FakePwaInstallService();
    container = createContainer(prefs: prefs);
    container.listen(pwaInstallControllerProvider, (_, _) {});

    final notifier = container.read(pwaInstallControllerProvider.notifier);
    notifier.evaluateBanner(isWeb: true);
    expect(container.read(pwaInstallControllerProvider).bannerVisible, isTrue);

    await notifier.snooze();

    expect(
      container.read(pwaInstallControllerProvider).bannerVisible,
      isFalse,
    );
    expect(PwaInstallPrefs(prefs).canShowBanner, isFalse);
  });

  test("evaluateBanner refreshes canNativeInstall from service", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    service = _FakePwaInstallService(canNativePrompt: false);
    container = createContainer(prefs: prefs);
    container.listen(pwaInstallControllerProvider, (_, _) {});

    final notifier = container.read(pwaInstallControllerProvider.notifier);
    notifier.evaluateBanner(isWeb: true);
    expect(
      container.read(pwaInstallControllerProvider).canNativeInstall,
      isFalse,
    );

    service.canNativePrompt = true;
    notifier.evaluateBanner(isWeb: true);
    expect(
      container.read(pwaInstallControllerProvider).canNativeInstall,
      isTrue,
    );
  });

  test("neverShowAgain hides banner", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    service = _FakePwaInstallService();
    container = createContainer(prefs: prefs);
    container.listen(pwaInstallControllerProvider, (_, _) {});

    final notifier = container.read(pwaInstallControllerProvider.notifier);
    notifier.evaluateBanner(isWeb: true);

    await notifier.neverShowAgain();

    expect(
      container.read(pwaInstallControllerProvider).bannerVisible,
      isFalse,
    );
    expect(PwaInstallPrefs(prefs).neverShow, isTrue);
  });
}
