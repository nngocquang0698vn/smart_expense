import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/features/categories/presentation/category_visuals.dart";
import "package:smart_expense/core/constants/app_constants.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/features/transactions/domain/entities/category.dart";
import "package:smart_expense/shared/components/app_confirm_bottom_sheet.dart";
import "package:smart_expense/shared/components/app_empty_state.dart";
import "package:smart_expense/shared/components/app_finance_card.dart";
import "package:smart_expense/shared/components/app_icon_button.dart";
import "package:smart_expense/shared/components/app_loading_state.dart";
import "package:smart_expense/shared/components/app_primary_button.dart";
import "package:smart_expense/shared/components/app_scaffold.dart";
import "package:smart_expense/shared/components/app_section_header.dart";
import "package:smart_expense/shared/components/app_snack_bar.dart";
import "package:smart_expense/features/categories/application/categories_controller.dart";
import "package:smart_expense/features/categories/application/category_editor_policy.dart";

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    LedgerCategory? existing,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => _CategoryEditorSheet(ref: ref, existing: existing),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesControllerProvider);

    return categories.when(
      data: (state) {
        final viewModel = state.viewModel;
        return AppScaffold(
          title: context.l10n.category,
          padding: EdgeInsets.zero,
          floatingActionButton: FloatingActionButton(
            tooltip: context.l10n.addCategory,
            onPressed: () => _openEditor(context, ref),
            child: const Icon(Icons.add),
          ),
          body: state.loading
              ? AppLoadingState(message: context.l10n.loading)
              : viewModel.isEmpty
              ? AppEmptyState(
                  message: context.l10n.noCategories,
                  icon: Icons.category_outlined,
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppBreakpoints.tablet,
                    ),
                    child: ListView(
                      padding: const EdgeInsets.only(
                        bottom: AppInsets.listBottom,
                      ),
                      children: [
                        AppSectionHeader(title: context.l10n.expense),
                        for (final category in viewModel.expense)
                          _CategoryTile(
                            category: category,
                            isSystem: viewModel.isSystem(category),
                            onToggle: () => ref
                                .read(categoriesControllerProvider.notifier)
                                .toggleEnabled(category),
                            onTap: () =>
                                _openEditor(context, ref, existing: category),
                          ),
                        const SizedBox(height: AppSpacing.xs),
                        AppSectionHeader(title: context.l10n.income),
                        for (final category in viewModel.income)
                          _CategoryTile(
                            category: category,
                            isSystem: viewModel.isSystem(category),
                            onToggle: () => ref
                                .read(categoriesControllerProvider.notifier)
                                .toggleEnabled(category),
                            onTap: () =>
                                _openEditor(context, ref, existing: category),
                          ),
                      ],
                    ),
                  ),
                ),
        );
      },
      loading: () => AppScaffold(
        title: context.l10n.category,
        padding: EdgeInsets.zero,
        body: AppLoadingState(message: context.l10n.loading),
      ),
      error: (_, _) => AppScaffold(
        title: context.l10n.category,
        padding: EdgeInsets.zero,
        body: AppEmptyState(message: context.l10n.genericError),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.isSystem,
    required this.onToggle,
    required this.onTap,
  });

  final LedgerCategory category;
  final bool isSystem;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = isSystem
        ? context.l10n.categoryDefault
        : category.enabled
        ? null
        : context.l10n.categoryDisabled;

    return Opacity(
      opacity: category.enabled ? 1 : 0.48,
      child: AppFinanceCard(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xxs,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        onTap: isSystem ? null : onTap,
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: category.color.withValues(alpha: 0.14),
              child: Icon(category.icon, color: category.color, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isSystem)
              Switch.adaptive(
                value: category.enabled,
                onChanged: (_) => onToggle(),
                activeThumbColor: scheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryEditorSheet extends StatefulWidget {
  const _CategoryEditorSheet({required this.ref, this.existing});

  final WidgetRef ref;
  final LedgerCategory? existing;

  @override
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
  final _policy = const CategoryEditorPolicy();
  late final TextEditingController _nameController;
  late CategoryDraft _draft;
  bool _saving = false;
  CategoryValidationError? _validationError;

  @override
  void initState() {
    super.initState();
    _draft = _policy.initialDraft(existing: widget.existing);
    _nameController = TextEditingController(text: _draft.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateDraft(CategoryDraft draft) {
    setState(() => _draft = draft);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    late final CategoryValidationResult result;
    try {
      result = await widget.ref
          .read(categoriesControllerProvider.notifier)
          .saveDraft(
            draft: _draft.copyWith(name: _nameController.text),
            existing: widget.existing,
          );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(
        "Chưa thể lưu danh mục. Vui lòng thử lại.",
        type: AppSnackBarType.error,
        title: "Chưa thể lưu",
      );
      return;
    }
    if (!mounted) return;
    setState(() => _saving = false);

    if (!result.isValid) {
      setState(() => _validationError = result.error);
      return;
    }
    _showMessage(
      "Đã lưu danh mục.",
      type: AppSnackBarType.success,
      title: "Đã lưu",
    );
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final category = widget.existing;
    if (category == null) return;

    final decision = await widget.ref
        .read(categoriesControllerProvider.notifier)
        .canDelete(category);
    if (!mounted) return;
    if (!decision.allowed) {
      _showMessage(
        _categoryDeleteMessage(decision.reason),
        type: AppSnackBarType.warning,
        title: "Chưa thể xoá",
      );
      return;
    }

    final confirmed = await AppConfirmBottomSheet.show(
      context,
      title: context.l10n.deleteCategoryTitle,
      message: category.name,
      confirmLabel: context.l10n.delete,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await widget.ref
          .read(categoriesControllerProvider.notifier)
          .delete(category);
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        "Chưa thể xoá danh mục. Vui lòng thử lại.",
        type: AppSnackBarType.error,
        title: "Chưa thể xoá",
      );
      return;
    }
    _showMessage(
      "Đã xoá danh mục.",
      type: AppSnackBarType.success,
      title: "Đã xoá",
    );
    if (mounted) Navigator.of(context).pop();
  }

  void _showMessage(
    String message, {
    AppSnackBarType type = AppSnackBarType.info,
    String title = "Thông báo",
  }) {
    showAppSnackBar(context, title: title, message: message, type: type);
  }

  String? _categoryValidationMessage(CategoryValidationError? error) {
    return switch (error) {
      CategoryValidationError.nameRequired => context.l10n.categoryNameRequired,
      null => null,
    };
  }

  String _categoryDeleteMessage(CategoryDeleteBlockReason? reason) {
    return switch (reason) {
      CategoryDeleteBlockReason.systemCategory =>
        context.l10n.categorySystemDeleteDenied,
      CategoryDeleteBlockReason.inUse => context.l10n.categoryInUseDeleteDenied,
      null => context.l10n.genericError,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEdit = widget.existing != null;
    final iconEntries = CategoryIcons.byName.entries.toList();
    final currentColor = Color(_draft.colorValue);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.76,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isEdit
                          ? context.l10n.editCategory
                          : context.l10n.newCategory,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (isEdit)
                    AppIconButton(
                      icon: Icons.delete_outline,
                      tooltip: context.l10n.delete,
                      onPressed: _delete,
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: currentColor.withValues(alpha: 0.15),
                      child: Icon(
                        CategoryIcons.get(_draft.iconKey),
                        color: currentColor,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: context.l10n.categoryName,
                      prefixIcon: Icon(Icons.edit_outlined),
                      errorText: _categoryValidationMessage(_validationError),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) {
                      if (_validationError != null) {
                        setState(() => _validationError = null);
                      }
                    },
                    onSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text(context.l10n.expense),
                        icon: Icon(Icons.arrow_downward_rounded),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(context.l10n.income),
                        icon: Icon(Icons.arrow_upward_rounded),
                      ),
                    ],
                    selected: {_draft.isIncome},
                    onSelectionChanged: (selection) => _updateDraft(
                      _draft.copyWith(isIncome: selection.first),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _PickerLabel(label: context.l10n.categoryColor),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final colorValue in kCategoryColors)
                        _ColorOption(
                          colorValue: colorValue,
                          selected: _draft.colorValue == colorValue,
                          onTap: () => _updateDraft(
                            _draft.copyWith(colorValue: colorValue),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _PickerLabel(label: context.l10n.categoryIcon),
                  const SizedBox(height: AppSpacing.xs),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 52,
                          mainAxisSpacing: AppSpacing.xs,
                          crossAxisSpacing: AppSpacing.xs,
                        ),
                    itemCount: iconEntries.length,
                    itemBuilder: (context, index) {
                      final entry = iconEntries[index];
                      final selected = _draft.iconKey == entry.key;
                      return _IconOption(
                        icon: entry.value,
                        selected: selected,
                        selectedColor: currentColor,
                        backgroundColor: scheme.surfaceContainerHighest,
                        onTap: () =>
                            _updateDraft(_draft.copyWith(iconKey: entry.key)),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppPrimaryButton(
                    label: isEdit
                        ? context.l10n.save
                        : context.l10n.addCategory,
                    icon: Icons.check,
                    isLoading: _saving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PickerLabel extends StatelessWidget {
  const _PickerLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _ColorOption extends StatelessWidget {
  const _ColorOption({
    required this.colorValue,
    required this.selected,
    required this.onTap,
  });

  final int colorValue;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(colorValue);

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: selected
                ? Border.all(
                    color: Theme.of(context).colorScheme.onSurface,
                    width: 2.5,
                  )
                : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.45),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: selected
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : null,
        ),
      ),
    );
  }
}

class _IconOption extends StatelessWidget {
  const _IconOption({
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        decoration: BoxDecoration(
          color: selected
              ? selectedColor.withValues(alpha: 0.18)
              : backgroundColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: selected ? Border.all(color: selectedColor, width: 2) : null,
        ),
        child: Icon(
          icon,
          size: 22,
          color: selected ? selectedColor : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
