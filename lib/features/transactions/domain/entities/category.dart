class LedgerCategory {
  const LedgerCategory({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required this.isIncome,
    this.enabled = true,
  });

  final String id;
  final String name;
  final String iconKey;
  final int colorValue;
  final bool isIncome;
  final bool enabled;

  LedgerCategory copyWith({
    String? name,
    String? iconKey,
    int? colorValue,
    bool? isIncome,
    bool? enabled,
  }) {
    return LedgerCategory(
      id: id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      isIncome: isIncome ?? this.isIncome,
      enabled: enabled ?? this.enabled,
    );
  }
}

const List<int> kCategoryColors = [
  0xFF26A69A,
  0xFF42A5F5,
  0xFF66BB6A,
  0xFFEF5350,
  0xFFFF7043,
  0xFFFFCA28,
  0xFFAB47BC,
  0xFF8D6E63,
  0xFF78909C,
  0xFF26C6DA,
  0xFFEC407A,
  0xFF7E57C2,
  0xFF29B6F6,
  0xFF9CCC65,
  0xFFFFA726,
];
