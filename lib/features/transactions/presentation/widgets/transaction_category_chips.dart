import "package:flutter/material.dart";

import "../../../../data/models/category_model.dart";
import "../../../../core/theme/app_finance_colors.dart";

class TransactionCategoryChips extends StatelessWidget {
  const TransactionCategoryChips({
    super.key,
    required this.categories,
    required this.isIncome,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CategoryModel> categories;
  final bool isIncome;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final finance = context.financeColors;
    final filtered = categories.where((c) => c.isIncome == isIncome);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filtered.map((cat) {
        final active = cat.id == selectedId;
        return GestureDetector(
          onTap: () => onSelected(cat.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: active ? cs.primary : finance.fieldFill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active ? cs.primary : finance.fieldBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  cat.icon,
                  size: 16,
                  color: active ? cs.onPrimary : cat.color,
                ),
                const SizedBox(width: 5),
                Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? cs.onPrimary : cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
