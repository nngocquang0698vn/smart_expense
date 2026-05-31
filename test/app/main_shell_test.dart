import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/app/main_shell.dart";
import "package:smart_expense/app/providers.dart";
import "package:smart_expense/core/utils/date_format.dart";
import "package:smart_expense/core/testing/fake_ledger_repository.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LedgerRepository repo;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = await createFakeLedgerRepository();
    await repo.setUserName("Original");
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.clearAllTestValues();
  });

  Future<void> pumpShell(WidgetTester tester, Size size) async {
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
          home: const MainShell(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets(
    "keeps profile text state when resizing between mobile and desktop",
    (tester) async {
      await pumpShell(tester, const Size(1200, 800));

      await tester.tap(find.byIcon(Icons.person_rounded).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final profileField = find.byType(TextField).first;
      await tester.enterText(profileField, "Draft name");
      expect(find.text("Draft name"), findsOneWidget);

      await tester.binding.setSurfaceSize(const Size(430, 800));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text("Draft name"), findsOneWidget);
    },
  );

  testWidgets("desktop sidebar clock updates at the next minute", (
    tester,
  ) async {
    await pumpShell(tester, const Size(1200, 800));

    final before = DateTime.now();
    expect(find.text(formatShellTime(before)), findsOneWidget);

    final nextMinute = DateTime(
      before.year,
      before.month,
      before.day,
      before.hour,
      before.minute + 1,
    );
    await tester.pump(nextMinute.difference(before));
    await tester.pump();

    expect(find.text(formatShellTime(DateTime.now())), findsOneWidget);
  });
}
