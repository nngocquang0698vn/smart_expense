import "package:flutter/material.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/features/transactions/domain/entities/category.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_category_chips.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

/// Hạng mục dạng chip — dùng chung nhập nhanh và sửa giao dịch.
class TransactionCategorySection extends StatelessWidget {
  const TransactionCategorySection({
    super.key,
    required this.categories,
    required this.isIncome,
    required this.selectedId,
    required this.onSelected,
    this.errorText,
    this.includeSelectedFrom,
  });

  /// Danh mục hiển thị dạng chip (thường là enabled theo chi tiêu/thu nhập).
  final List<LedgerCategory> categories;

  /// Khi sửa giao dịch cũ: thêm danh mục đã chọn nếu không còn trong [categories].
  final List<LedgerCategory>? includeSelectedFrom;

  final bool isIncome;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final String? errorText;

  List<LedgerCategory> get _chipCategories {
    final chips = List<LedgerCategory>.from(categories);
    if (selectedId == null ||
        selectedId!.isEmpty ||
        chips.any((c) => c.id == selectedId)) {
      return chips;
    }
    final pool = includeSelectedFrom ?? categories;
    for (final category in pool) {
      if (category.id == selectedId) {
        chips.add(category);
        break;
      }
    }
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.category,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        TransactionCategoryChips(
          categories: _chipCategories,
          isIncome: isIncome,
          selectedId: selectedId,
          onSelected: onSelected,
        ),
        if (errorText != null && errorText!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
