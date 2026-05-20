import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/app/providers.dart";
import "package:smart_expense/core/testing/fake_ledger_repository.dart";
import "package:smart_expense/core/testing/pwa_install_test_support.dart";
import "package:smart_expense/core/utils/pwa/pwa_providers.dart";
import "package:smart_expense/features/onboarding/presentation/onboarding_layout_metrics.dart";
import "package:smart_expense/features/onboarding/presentation/onboarding_nav_row.dart";
import "package:smart_expense/features/onboarding/presentation/onboarding_screen.dart";
import "package:smart_expense/shared/layouts/onboarding_page_layout.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LedgerRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = await createFakeLedgerRepository();
  });

  Future<void> pumpOnboarding(
    WidgetTester tester, {
    Size surfaceSize = const Size(1200, 800),
  }) async {
    await tester.binding.setSurfaceSize(surfaceSize);
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          pwaInstallServiceProvider.overrideWithValue(
            FakePwaInstallService(userAgent: kDesktopChromeUa),
          ),
        ],
        child: MaterialApp(
          locale: const Locale("vi", "VN"),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OnboardingScreen(repo: repo, onDone: () {}),
        ),
      ),
    );
    await tester.pump();
  }

  tearDown(() async {
    TestWidgetsFlutterBinding.instance.platformDispatcher.clearAllTestValues();
  });

  testWidgets("constrains onboarding content to max width on wide screens", (
    tester,
  ) async {
    await pumpOnboarding(tester);

    final constrained = tester.widget<ConstrainedBox>(
      find.byWidgetPredicate(
        (w) =>
            w is ConstrainedBox &&
            w.constraints.maxWidth == kOnboardingContentMaxWidth,
      ),
    );
    expect(constrained.constraints.maxWidth, kOnboardingContentMaxWidth);
  });

  testWidgets("shows four page indicators without PWA on VM tests", (
    tester,
  ) async {
    await pumpOnboarding(tester);
    expect(find.byType(AnimatedContainer), findsNWidgets(4));
  });

  testWidgets("skip button stays inside constrained content column", (
    tester,
  ) async {
    await pumpOnboarding(tester);

    final skipBox = tester.getRect(find.text("Bỏ qua"));
    final contentBox = tester.getRect(
      find.byWidgetPredicate(
        (w) =>
            w is ConstrainedBox &&
            w.constraints.maxWidth == kOnboardingContentMaxWidth,
      ),
    );
    expect(skipBox.right, lessThanOrEqualTo(contentBox.right + 1));
    expect(skipBox.left, greaterThanOrEqualTo(contentBox.left - 1));
  });

  testWidgets("intro page has no vertical scroll when content fits", (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpOnboarding(tester);

    final introScroll = find.descendant(
      of: find.byType(OnboardingPageLayout).at(0),
      matching: find.byType(Scrollable),
    );
    expect(
      tester.state<ScrollableState>(introScroll).position.maxScrollExtent,
      0,
    );
  });

  testWidgets(
    "intro page shows feature icon beside title not oversized above",
    (tester) async {
      await pumpOnboarding(tester);

      final titleFinder = find.text("Smart Ledger");
      final iconFinder = find.byIcon(Icons.account_balance_wallet_outlined);
      expect(titleFinder, findsOneWidget);
      expect(iconFinder, findsOneWidget);

      final titleBox = tester.getRect(titleFinder);
      final iconBox = tester.getRect(iconFinder);
      final icon = tester.widget<Icon>(iconFinder);

      expect(icon.size, lessThanOrEqualTo(32));
      expect(icon.size, greaterThan(0));
      expect(iconBox.center.dy, closeTo(titleBox.center.dy, 12));
      expect(iconBox.left, greaterThan(titleBox.left));
      expect(iconBox.top, greaterThan(titleBox.top - 8));
      expect(iconBox.top, lessThan(titleBox.bottom + 8));
    },
  );

  testWidgets("fast entry page shows bolt inline to the right of title", (
    tester,
  ) async {
    await pumpOnboarding(tester);

    await tester.tap(find.text("Tiếp theo"));
    await tester.pumpAndSettle();

    final titleFinder = find.text("Ghi chép siêu tốc");
    final boltFinder = find.byIcon(Icons.bolt);
    expect(titleFinder, findsOneWidget);
    expect(boltFinder, findsOneWidget);

    final titleBox = tester.getRect(titleFinder);
    final boltBox = tester.getRect(boltFinder);
    final bolt = tester.widget<Icon>(boltFinder);

    expect(bolt.size, lessThanOrEqualTo(32));
    expect(boltBox.center.dy, closeTo(titleBox.center.dy, 12));
    expect(boltBox.left, greaterThan(titleBox.left));
    expect(boltBox.top, lessThan(titleBox.bottom + 8));
  });

  testWidgets("name field sits above progress dots on last page", (
    tester,
  ) async {
    await pumpOnboarding(tester, surfaceSize: const Size(390, 700));
    await tester.tap(find.text("Bỏ qua"));
    await tester.pumpAndSettle();

    final fieldBox = tester.getRect(find.byType(TextField));
    final dotsBox = tester.getRect(
      find.byWidgetPredicate(
        (w) =>
            w is Padding &&
            w.padding ==
                const EdgeInsets.only(bottom: kOnboardingDotsToButtonsGap) &&
            w.child is Row,
      ),
    );
    expect(fieldBox.bottom, lessThan(dotsBox.top));
    expect(
      dotsBox.top - fieldBox.bottom,
      greaterThanOrEqualTo(kOnboardingNameFieldToDotsGap - 1),
    );
  });

  testWidgets("skip shows insights page with name field not intro content", (
    tester,
  ) async {
    await pumpOnboarding(tester, surfaceSize: const Size(390, 700));
    await tester.tap(find.text("Bỏ qua"));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.insights), findsOneWidget);
    expect(find.text("Smart Ledger"), findsNothing);
    expect(find.text("Quản lý thông minh"), findsOneWidget);
    expect(find.byType(OnboardingLastNavRow), findsOneWidget);
  });

  testWidgets("back button on last page is not clipped", (tester) async {
    await pumpOnboarding(tester, surfaceSize: const Size(390, 700));
    await tester.tap(find.text("Bỏ qua"));
    await tester.pumpAndSettle();

    final navBox = tester.getRect(find.byType(OnboardingLastNavRow));
    final backBox = tester.getRect(find.text("Quay lại"));
    expect(backBox.top, greaterThanOrEqualTo(navBox.top - 1));
    expect(backBox.bottom, lessThanOrEqualTo(navBox.bottom + 1));
  });

  testWidgets("empty name validation appears inline under name field", (
    tester,
  ) async {
    await pumpOnboarding(tester, surfaceSize: const Size(390, 700));
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(
      find.text(AppLocalizations.vi.onboardingNameRequired),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets("insights title stays stable when reaching name page", (
    tester,
  ) async {
    const phone = Size(390, 700);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpOnboarding(tester, surfaceSize: phone);
    await tester.tap(find.text("Bỏ qua"));
    await tester.pumpAndSettle();
    final skipTitleY = tester
        .getRect(find.text("Quản lý thông minh"))
        .center
        .dy;

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await pumpOnboarding(tester, surfaceSize: phone);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text("Tiếp theo"));
      await tester.pumpAndSettle();
    }
    expect(find.byType(TextField), findsOneWidget);
    final nextTitleY = tester
        .getRect(find.text("Quản lý thông minh"))
        .center
        .dy;
    expect(nextTitleY, closeTo(skipTitleY, 6));
  });

  testWidgets("second page places previous and next on one row", (
    tester,
  ) async {
    await pumpOnboarding(tester);

    await tester.tap(find.text("Tiếp theo"));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingNavRow), findsOneWidget);
    expect(find.text("Trước"), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);

    final navBox = tester.getRect(find.byType(OnboardingNavRow));
    final prevBox = tester.getRect(find.byType(OutlinedButton));
    expect(prevBox.top, closeTo(navBox.top, 4));
  });
}
