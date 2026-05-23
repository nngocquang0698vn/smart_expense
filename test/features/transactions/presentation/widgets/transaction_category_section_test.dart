import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/features/transactions/domain/entities/category.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_category_chips.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_category_section.dart";

void main() {
  final categories = <LedgerCategory>[
    const LedgerCategory(
      id: "food",
      name: "Ăn uống",
      iconKey: "restaurant",
      colorValue: 0xFFFF7043,
      isIncome: false,
    ),
    const LedgerCategory(
      id: "salary",
      name: "Lương",
      iconKey: "payments",
      colorValue: 0xFF66BB6A,
      isIncome: true,
    ),
    const LedgerCategory(
      id: "old",
      name: "Danh mục cũ",
      iconKey: "archive",
      colorValue: 0xFF78909C,
      isIncome: false,
      enabled: false,
    ),
  ];

  Widget wrap(Widget child) {
    return MaterialApp(
      locale: const Locale("vi", "VN"),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }

  testWidgets("shows category label and chips", (tester) async {
    await tester.pumpWidget(
      wrap(
        TransactionCategorySection(
          categories: categories,
          isIncome: false,
          selectedId: "food",
          onSelected: (_) {},
        ),
      ),
    );

    expect(find.text("Hạng mục"), findsOneWidget);
    expect(find.byType(TransactionCategoryChips), findsOneWidget);
    expect(find.text("Ăn uống"), findsOneWidget);
  });

  testWidgets("shows validation error when provided", (tester) async {
    await tester.pumpWidget(
      wrap(
        TransactionCategorySection(
          categories: categories,
          isIncome: false,
          selectedId: null,
          onSelected: (_) {},
          errorText: "Vui lòng chọn hạng mục",
        ),
      ),
    );

    expect(find.text("Vui lòng chọn hạng mục"), findsOneWidget);
  });

  testWidgets("includes legacy selected category when editing old transaction", (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        TransactionCategorySection(
          categories: [categories.first],
          includeSelectedFrom: categories,
          isIncome: false,
          selectedId: "old",
          onSelected: (_) {},
        ),
      ),
    );

    expect(find.text("Danh mục cũ"), findsOneWidget);
  });
}
