import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/app/providers.dart";
import "package:smart_expense/features/settings/presentation/profile_screen.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _ProfileLedgerRepository repo;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = _ProfileLedgerRepository(userName: "Original");
  });

  tearDown(() async {
    await repo.dispose();
  });

  Future<void> pumpProfile(WidgetTester tester) async {
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
          home: Scaffold(body: ProfileScreen(onOpenPending: () {})),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets(
    "does not overwrite an in-progress name edit after repo changes",
    (tester) async {
      await pumpProfile(tester);

      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, "Draft name");
      expect(find.text("Draft name"), findsOneWidget);

      await repo.setUserName("Server name");
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text("Draft name"), findsOneWidget);
      expect(find.text("Server name"), findsNothing);
    },
  );
}

class _ProfileLedgerRepository extends LedgerRepository {
  _ProfileLedgerRepository({required String userName}) : _userName = userName;

  final _changes = StreamController<void>.broadcast();
  String _userName;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<Map<String, Object?>> getMeta() async => {"userName": _userName};

  @override
  Future<void> setUserName(String name) async {
    _userName = name;
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
