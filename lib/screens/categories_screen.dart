import "package:flutter/material.dart";

import "../core/constants.dart";
import "../core/strings.dart";
import "../data/ledger_repository.dart";
import "../data/models/category_model.dart";
import "../features/categories/application/categories_controller.dart";
import "../features/categories/application/category_editor_policy.dart";
import "../shared/widgets/app_card.dart";
import "../shared/widgets/app_confirm_bottom_sheet.dart";
import "../shared/widgets/app_empty_state.dart";
import "../shared/widgets/app_icon_button.dart";
import "../shared/widgets/app_loading_state.dart";
import "../shared/widgets/app_primary_button.dart";
import "../shared/widgets/app_scaffold.dart";
import "../shared/widgets/app_section_header.dart";

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key, required this.repo});

  final LedgerRepository repo;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final CategoriesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CategoriesController(repo: widget.repo)..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openEditor({CategoryModel? existing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) =>
          _CategoryEditorSheet(controller: _controller, existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final viewModel = _controller.viewModel;

        return AppScaffold(
          title: AppStrings.category,
          padding: EdgeInsets.zero,
          floatingActionButton: FloatingActionButton(
            tooltip: AppStrings.addCategory,
            onPressed: () => _openEditor(),
            child: const Icon(Icons.add),
          ),
          body: _controller.loading
              ? const AppLoadingState(message: AppStrings.loading)
              : viewModel.isEmpty
              ? const AppEmptyState(
                  message: AppStrings.noCategories,
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
                        AppSectionHeader(title: AppStrings.expense),
                        for (final category in viewModel.expense)
                          _CategoryTile(
                            category: category,
                            isSystem: viewModel.isSystem(category),
                            onToggle: () => _controller.toggleEnabled(category),
                            onTap: () => _openEditor(existing: category),
                          ),
                        const SizedBox(height: AppSpacing.xs),
                        AppSectionHeader(title: AppStrings.income),
                        for (final category in viewModel.income)
                          _CategoryTile(
                            category: category,
                            isSystem: viewModel.isSystem(category),
                            onToggle: () => _controller.toggleEnabled(category),
                            onTap: () => _openEditor(existing: category),
                          ),
                      ],
                    ),
                  ),
                ),
        );
      },
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

  final CategoryModel category;
  final bool isSystem;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = isSystem
        ? AppStrings.categoryDefault
        : category.enabled
        ? null
        : AppStrings.categoryDisabled;

    return Opacity(
      opacity: category.enabled ? 1 : 0.48,
      child: AppCard(
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
  const _CategoryEditorSheet({required this.controller, this.existing});

  final CategoriesController controller;
  final CategoryModel? existing;

  @override
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
  final _policy = const CategoryEditorPolicy();
  late final TextEditingController _nameController;
  late CategoryDraft _draft;
  bool _saving = false;

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
    final result = await widget.controller.saveDraft(
      draft: _draft.copyWith(name: _nameController.text),
      existing: widget.existing,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (!result.isValid) {
      _showMessage(result.message ?? AppStrings.genericError);
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final category = widget.existing;
    if (category == null) return;

    final decision = await widget.controller.canDelete(category);
    if (!mounted) return;
    if (!decision.allowed) {
      _showMessage(decision.message ?? AppStrings.genericError);
      return;
    }

    final confirmed = await AppConfirmBottomSheet.show(
      context,
      title: AppStrings.deleteCategoryTitle,
      message: category.name,
      confirmLabel: AppStrings.delete,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    await widget.controller.delete(category);
    if (mounted) Navigator.of(context).pop();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
                      isEdit ? AppStrings.editCategory : AppStrings.newCategory,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (isEdit)
                    AppIconButton(
                      icon: Icons.delete_outline,
                      tooltip: AppStrings.delete,
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
                    decoration: const InputDecoration(
                      labelText: AppStrings.categoryName,
                      prefixIcon: Icon(Icons.edit_outlined),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text(AppStrings.expense),
                        icon: Icon(Icons.arrow_downward_rounded),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(AppStrings.income),
                        icon: Icon(Icons.arrow_upward_rounded),
                      ),
                    ],
                    selected: {_draft.isIncome},
                    onSelectionChanged: (selection) => _updateDraft(
                      _draft.copyWith(isIncome: selection.first),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _PickerLabel(label: AppStrings.categoryColor),
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
                  _PickerLabel(label: AppStrings.categoryIcon),
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
                    label: isEdit ? AppStrings.save : AppStrings.addCategory,
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
