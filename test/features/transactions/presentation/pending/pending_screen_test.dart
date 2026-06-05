import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/app/providers.dart";
import "package:smart_expense/core/testing/fake_ledger_repository.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";
import "package:smart_expense/features/transactions/presentation/pending/pending_screen.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LedgerRepository repo;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = await createFakeLedgerRepository();

    final categories = await repo.categories();
    final expense = categories.firstWhere((category) => !category.isIncome);
    await repo.addQuick(
      title: "Pending lunch",
      amountVnd: 120000,
      isIncome: false,
      categoryId: expense.id,
      at: DateTime.now(),
      pending: true,
      note: "Receipt needs review",
    );
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.clearAllTestValues();
  });

  Future<void> pumpPendingScreen(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          ledgerRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          locale: const Locale("vi", "VN"),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: PendingScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets("mobile shows pending list before opening transaction detail", (
    tester,
  ) async {
    await pumpPendingScreen(tester, const Size(430, 800));

    expect(find.text("Pending lunch"), findsOneWidget);
    expect(find.text("Sửa giao dịch"), findsNothing);

    await tester.tap(find.text("Pending lunch"));
    await tester.pumpAndSettle();

    expect(find.text("Sửa giao dịch"), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text("Pending lunch"), findsOneWidget);
    expect(find.text("Sửa giao dịch"), findsNothing);
  });
}
