import "package:flutter/material.dart";

import "../core/theme_settings.dart";
import "../core/strings.dart";
import "../core/theme_notifier.dart";
import "../core/theme_presets.dart";
import "../data/demo_seed.dart";
import "../data/ledger_repository.dart";
import "../widgets/add_options_sheet.dart";
import "categories_screen.dart";

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.repo,
    required this.onOpenPending,
  });

  final LedgerRepository repo;
  final VoidCallback onOpenPending;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.repo.addListener(_onRepo);
    _load();
  }

  @override
  void dispose() {
    widget.repo.removeListener(_onRepo);
    _nameCtrl.dispose();
    super.dispose();
  }

  void _onRepo() => _load();

  Future<void> _load() async {
    final m = await widget.repo.getMeta();
    if (!mounted) return;
    setState(() {
      _nameCtrl.text = (m["userName"] as String?) ?? "";
      _loading = false;
    });
  }

  Future<void> _saveName() async {
    await widget.repo.setUserName(_nameCtrl.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã lưu tên")),
      );
    }
  }

  Future<void> _populateJohny() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nạp dữ liệu Johny Nguyễn?"),
        content: const Text(
          "Thao tác này sẽ XOÁ toàn bộ giao dịch hiện tại và thay bằng "
          "dữ liệu demo của Johny Nguyễn (Software Engineer TP.HCM, "
          "2/2026 – 5/2026). Tên tài khoản cũng sẽ đổi thành "
          "\"Johny Nguyễn\".\n\nBạn có chắc chắn không?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Nạp dữ liệu"),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if (!mounted) return;
    // Show loading overlay
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Đang nạp dữ liệu…"),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      await populateJohnyData(widget.repo);
    } finally {
      if (mounted) Navigator.of(context).pop(); // dismiss loading
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Đã nạp xong dữ liệu Johny Nguyễn!"),
        duration: Duration(seconds: 3),
      ),
    );
    // Reload name field
    _load();
  }

  Widget _buildAppearanceSection(BuildContext context) {
    final notifier = ThemeScope.of(context);
    final settings = notifier.settings;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Giao diện",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          Text(
            "Chế độ hiển thị",
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 8),
          SegmentedButton<AppThemePreference>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<AppThemePreference>(
                value: AppThemePreference.system,
                label: Text("Hệ thống"),
              ),
              ButtonSegment<AppThemePreference>(
                value: AppThemePreference.light,
                label: Text("Sáng"),
              ),
              ButtonSegment<AppThemePreference>(
                value: AppThemePreference.dark,
                label: Text("Tối"),
              ),
            ],
            selected: {settings.themePreference},
            onSelectionChanged: (next) {
              if (next.isEmpty) return;
              notifier.update(
                settings.copyWith(themePreference: next.first),
              );
            },
          ),
          const SizedBox(height: 16),

          // ── Colour label ──────────────────────────────────────────────
          Text(
            "Màu chủ đạo",
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 10),

          // ── Colour swatches ───────────────────────────────────────────
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final preset in kThemePresets)
                _ColorDot(
                  preset: preset,
                  selected: settings.seedColor == preset.color,
                  onTap: () => notifier.update(
                    settings.copyWith(seedColor: preset.color),
                  ),
                ),
            ],
          ),

          // ── Coloured-surfaces toggle ──────────────────────────────────
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text("Nền màu sắc"),
            subtitle: const Text("Tông màu nhẹ theo màu chủ đạo"),
            value: settings.useColoredSurfaces,
            onChanged: (v) =>
                notifier.update(settings.copyWith(useColoredSurfaces: v)),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Tuỳ chỉnh",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              // Name row stretches to full column width so "Lưu" aligns with ">"
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Tên người dùng",
                        isDense: true,
                      ),
                      onSubmitted: (_) => _saveName(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.tonal(
                    onPressed: _saveName,
                    child: const Text("Lưu"),
                  ),
                ],
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.category_outlined),
          title: const Text(AppStrings.category),
          subtitle: const Text("Thêm, sửa, xoá danh mục thu chi"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CategoriesScreen(repo: widget.repo),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.fact_check_outlined),
          title: const Text("Giao dịch chờ đối soát"),
          subtitle: const Text("Mở danh sách đối soát"),
          trailing: const Icon(Icons.chevron_right),
          onTap: widget.onOpenPending,
        ),
        ListTile(
          leading: const Icon(Icons.add_circle_outline),
          title: const Text("Thêm giao dịch nhanh"),
          onTap: () => handleAddFab(context, widget.repo),
        ),
      ],
    );
  }

  Widget _buildDemoCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Dữ liệu demo",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: const Text(
                          "JN",
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Nhân vật Johny Nguyễn",
                              style:
                                  Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              "Software Engineer · TP.HCM · 45tr/tháng",
                              style:
                                  Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: _populateJohny,
                      child: const Text("Chuyển qua chế độ demo"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const CustomScrollView(
        slivers: [
          SliverAppBar.large(title: Text("Cá nhân")),
          SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(title: const Text("Cá nhân")),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAppearanceSection(context),
                const Divider(height: 24, indent: 16, endIndent: 16),
                _buildLeftPanel(context),
                _buildDemoCard(context),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }
}

// ── Private widgets ────────────────────────────────────────────────────────────

/// A tappable coloured circle for the theme colour picker.
class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final ThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: preset.nameVi,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: preset.color,
            shape: BoxShape.circle,
            border: selected
                ? Border.all(color: Colors.white, width: 3)
                : Border.all(color: Colors.transparent, width: 3),
            boxShadow: [
              BoxShadow(
                color: preset.color.withValues(
                  alpha: selected ? 0.55 : 0.20,
                ),
                blurRadius: selected ? 10 : 4,
                spreadRadius: selected ? 1 : 0,
              ),
            ],
          ),
          child: selected
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
              : null,
        ),
      ),
    );
  }
}

