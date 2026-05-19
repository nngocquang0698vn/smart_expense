import "package:smart_expense/features/transactions/data/models/category_model.dart";
import "package:smart_expense/features/transactions/domain/entities/category.dart";

extension CategoryModelMapper on CategoryModel {
  LedgerCategory toEntity() {
    return LedgerCategory(
      id: id,
      name: name,
      iconKey: iconKey,
      colorValue: colorValue,
      isIncome: isIncome,
      enabled: enabled,
    );
  }
}

extension CategoryEntityModelMapper on LedgerCategory {
  CategoryModel toModel() {
    return CategoryModel(
      id: id,
      name: name,
      iconKey: iconKey,
      colorValue: colorValue,
      isIncome: isIncome,
      enabled: enabled,
    );
  }
}
