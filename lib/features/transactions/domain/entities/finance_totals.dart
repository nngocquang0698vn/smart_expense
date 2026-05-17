class FinanceTotals {
  const FinanceTotals({required this.income, required this.expense});

  final int income;
  final int expense;

  int get balance => income - expense;

  Map<String, int> toLegacyMap() => {"income": income, "expense": expense};
}
