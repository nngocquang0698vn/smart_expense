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

  Future<void> tapAiVoiceTile(WidgetTester tester) async {
    final tileText = find.text("AI nhận diện giọng nói");
    for (var i = 0; i < 3; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();
    }
    await tester.tap(tileText);
    await tester.pumpAndSettle();
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

  testWidgets("AI voice toggle requires config dialog and cancel keeps off", (
    tester,
  ) async {
    await pumpProfile(tester);

    expect(find.text("Tính năng thử nghiệm"), findsOneWidget);
    await tapAiVoiceTile(tester);

    expect(find.text("Cấu hình AI nhận diện giọng nói"), findsOneWidget);
    await tester.tap(find.text("Huỷ"));
    await tester.pumpAndSettle();

    expect(prefs.getString("userPreferences"), isNull);
  });

  testWidgets("AI voice config save persists endpoint and token", (
    tester,
  ) async {
    await pumpProfile(tester);

    await tapAiVoiceTile(tester);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      "https://smart-expense-m8nm.onrender.com/voice-transaction-demo/",
    );
    await tester.enterText(find.byType(TextFormField).at(1), "demo-token");
    await tester.tap(find.text("Lưu và bật"));
    await tester.pumpAndSettle();

    final raw = prefs.getString("userPreferences");
    expect(raw, isNotNull);
    expect(raw, contains('"aiVoiceRecognitionEnabled":true'));
    expect(
      raw,
      contains(
        '"aiVoiceApiEndpoint":"https://smart-expense-m8nm.onrender.com"',
      ),
    );
    expect(raw, contains('"aiVoiceDemoToken":"demo-token"'));
  });
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
