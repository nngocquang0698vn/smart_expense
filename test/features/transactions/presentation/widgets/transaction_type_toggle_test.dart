import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_type_toggle.dart";
import "package:smart_expense/shared/design_system/theme/app_theme.dart";
import "package:smart_expense/shared/design_system/tokens/app_transaction_entry_tokens.dart";

void main() {
  Widget buildSubject({
    required bool isIncome,
    required ValueChanged<bool> onChanged,
  }) {
    return MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale("vi", "VN"),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: TransactionTypeToggle(
            isIncome: isIncome,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  testWidgets("selects income when income segment tapped", (tester) async {
    var isIncome = false;

    await tester.pumpWidget(
      buildSubject(isIncome: isIncome, onChanged: (v) => isIncome = v),
    );

    await tester.tap(find.text(AppLocalizations.vi.income));
    await tester.pumpAndSettle();

    expect(isIncome, isTrue);
  });

  testWidgets("selected segment uses green fill on light track", (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(isIncome: true, onChanged: (_) {}));

    final colors = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(TransactionTypeToggle),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((b) => (b.decoration as BoxDecoration?)?.color)
        .whereType<Color>()
        .toList();

    expect(colors, contains(AppTransactionEntryTokens.toggleTrackLight));
    expect(colors, contains(AppTransactionEntryTokens.toggleSelectedFillLight));
  });

  testWidgets("selected label is white and unselected is dark", (tester) async {
    await tester.pumpWidget(buildSubject(isIncome: true, onChanged: (_) {}));
    await tester.pumpAndSettle();

    TextStyle resolvedStyle(Element element) {
      return DefaultTextStyle.of(element).style;
    }

    final incomeStyle = resolvedStyle(
      tester.element(find.text(AppLocalizations.vi.income)),
    );
    final expenseStyle = resolvedStyle(
      tester.element(find.text(AppLocalizations.vi.expense)),
    );

    expect(
      incomeStyle.color,
      AppTransactionEntryTokens.toggleSelectedLabelLight,
    );
    expect(
      expenseStyle.color,
      AppTransactionEntryTokens.toggleUnselectedLabelLight,
    );
    expect(incomeStyle.fontWeight, FontWeight.w700);
    expect(expenseStyle.fontWeight, FontWeight.w500);
  });
}
