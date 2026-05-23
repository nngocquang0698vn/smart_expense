import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/features/transactions/presentation/add_options_sheet.dart";
import "package:smart_expense/shared/design_system/theme/app_theme.dart";
import "package:smart_expense/shared/design_system/tokens/app_transaction_entry_tokens.dart";

void main() {
  testWidgets("quick add options use light card backgrounds not solid primary", (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale("vi", "VN"),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: QuickAddOptionsSheet(
            onSelected: (_) {},
            onClose: () {},
          ),
        ),
      ),
    );

    final primary = Theme.of(
      tester.element(find.byType(QuickAddOptionsSheet)),
    ).colorScheme.primary;

    final cards = tester.widgetList<Material>(
      find.byWidgetPredicate(
        (w) =>
            w is Material &&
            w.color == AppTransactionEntryTokens.quickAddCardLight,
      ),
    );

    expect(cards.length, 3);
    for (final card in cards) {
      expect(card.color, isNot(primary));
    }
  });
}
