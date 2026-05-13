import "package:flutter/material.dart";

import "../data/ledger_repository.dart";
import "../data/models/category_model.dart";

bool _isSystem(CategoryModel c) =>
    c.id == LedgerRepository.kOtherExpenseId ||
    c.id == LedgerRepository.kOtherIncomeId;

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key, required this.repo});

  final LedgerRepository repo;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<CategoryModel> _cats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.repo.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    widget.repo.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final cats = await widget.repo.categories();
    if (!mounted) return;
    setState(() {
      _cats = cats;
      _loading = false;
    });
  }

  Future<void> _toggleEnabled(CategoryModel c) async {
    await widget.repo.upsertCategory(c.copyWith(enabled: !c.enabled));
  }

  Future<void> _openEditor({CategoryModel? existing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _CategoryEditorSheet(
        repo: widget.repo,
        existing: existing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expense = _cats.where((c) => !c.isIncome).toList();
    final income = _cats.where((c) => c.isIncome).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Hạng mục")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: ListView(
                  children: [
                    _SectionHeader(label: "Chi tiêu"),
                    ...expense.map(
                      (c) => _CategoryTile(
                        cat: c,
                        onToggle: () => _toggleEnabled(c),
                        onTap: () => _openEditor(existing: c),
                      ),
                    ),
                    const Divider(height: 1),
                    _SectionHeader(label: "Thu nhập"),
                    ...income.map(
                      (c) => _CategoryTile(
                        cat: c,
                        onToggle: () => _toggleEnabled(c),
                        onTap: () => _openEditor(existing: c),
                      ),
                    ),
                    const SizedBox(height: 96),
                  ],
                ),
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.cat,
    required this.onToggle,
    required this.onTap,
  });

  final CategoryModel cat;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final system = _isSystem(cat);
    return Opacity(
      opacity: cat.enabled ? 1.0 : 0.45,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cat.color.withValues(alpha: 0.15),
          child: Icon(cat.icon, color: cat.color, size: 22),
        ),
        title: Text(cat.name),
        subtitle: system
            ? const Text("Hạng mục mặc định")
            : cat.enabled
                ? null
                : const Text("Đã tắt"),
        trailing: system
            ? null
            : Switch.adaptive(
                value: cat.enabled,
                onChanged: (_) => onToggle(),
                activeColor: cs.primary,
              ),
        onTap: system ? null : onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add / Edit sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryEditorSheet extends StatefulWidget {
  const _CategoryEditorSheet({required this.repo, this.existing});

  final LedgerRepository repo;
  final CategoryModel? existing;

  @override
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
  late final TextEditingController _nameCtrl;
  late String _iconKey;
  late int _colorValue;
  late bool _isIncome;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? "");
    _iconKey = e?.iconKey ?? "category";
    _colorValue = e?.colorValue ?? kCategoryColors.first;
    _isIncome = e?.isIncome ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    if (widget.existing != null) {
      await widget.repo.upsertCategory(
        widget.existing!.copyWith(
          name: name,
          iconKey: _iconKey,
          colorValue: _colorValue,
          isIncome: _isIncome,
        ),
      );
    } else {
      await widget.repo.createCategory(
        name: name,
        isIncome: _isIncome,
        iconKey: _iconKey,
        colorValue: _colorValue,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final inUse = await widget.repo.categoryInUse(widget.existing!.id);
    if (!mounted) return;
    if (inUse) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Không xoá được: còn giao dịch dùng hạng mục này"),
        ),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xoá hạng mục?"),
        content: Text(widget.existing!.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Huỷ"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xoá"),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await widget.repo.deleteCategory(widget.existing!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.existing != null;
    final iconEntries = CategoryIcons.byName.entries.toList();
    final currentColor = Color(_colorValue);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) => Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                Text(
                  isEdit ? "Chỉnh sửa hạng mục" : "Hạng mục mới",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                if (isEdit && !_isSystem(widget.existing!))
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: cs.error,
                    tooltip: "Xoá",
                    onPressed: _delete,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── Scrollable body ─────────────────────────────────────────────
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              children: [
                // Preview
                Center(
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: currentColor.withValues(alpha: 0.15),
                    child: Icon(
                      CategoryIcons.get(_iconKey),
                      color: currentColor,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Name
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Tên hạng mục",
                    prefixIcon: Icon(Icons.edit_outlined),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),

                // Chi / Thu toggle
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                        value: false,
                        label: Text("Chi tiêu"),
                        icon: Icon(Icons.arrow_downward_rounded)),
                    ButtonSegment(
                        value: true,
                        label: Text("Thu nhập"),
                        icon: Icon(Icons.arrow_upward_rounded)),
                  ],
                  selected: {_isIncome},
                  onSelectionChanged: (s) =>
                      setState(() => _isIncome = s.first),
                ),
                const SizedBox(height: 20),

                // Color picker
                Text("Màu sắc",
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kCategoryColors
                      .map(
                        (cv) => GestureDetector(
                          onTap: () => setState(() => _colorValue = cv),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Color(cv),
                              shape: BoxShape.circle,
                              border: _colorValue == cv
                                  ? Border.all(
                                      color: cs.onSurface, width: 2.5)
                                  : null,
                              boxShadow: _colorValue == cv
                                  ? [
                                      BoxShadow(
                                        color:
                                            Color(cv).withValues(alpha: 0.5),
                                        blurRadius: 6,
                                      )
                                    ]
                                  : null,
                            ),
                            child: _colorValue == cv
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 18)
                                : null,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),

                // Icon picker
                Text("Biểu tượng",
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 52,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: iconEntries.length,
                  itemBuilder: (context, i) {
                    final entry = iconEntries[i];
                    final selected = _iconKey == entry.key;
                    return GestureDetector(
                      onTap: () => setState(() => _iconKey = entry.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: selected
                              ? currentColor.withValues(alpha: 0.18)
                              : cs.surfaceVariant
                                  .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: selected
                              ? Border.all(color: currentColor, width: 2)
                              : null,
                        ),
                        child: Icon(
                          entry.value,
                          size: 22,
                          color: selected ? currentColor : cs.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Save button
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: Text(isEdit ? "Lưu thay đổi" : "Thêm hạng mục"),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
