import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

import "../../../core/constants.dart";
import "../../../core/pwa/pwa_install_service.dart";
import "../../../core/pwa/pwa_scope.dart";
import "../../../core/strings.dart";
import "../../../core/widgets/pwa_install_guide_sheet.dart";
import "../../../core/theme_notifier.dart";
import "../../../core/theme_presets.dart";
import "../../../core/theme_settings.dart";
import "../../../core/widgets/page_header_sliver.dart";
import "../../dev/demo_seed.dart";
import "../../../core/widgets/app_confirm_bottom_sheet.dart";
import "../../categories/presentation/categories_screen.dart";
import "../../transactions/domain/repositories/ledger_repository.dart";
import "../../transactions/presentation/add_options_sheet.dart";

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đã lưu tên")));
    }
  }

  Future<void> _populateJohny() async {
    final confirmed = await AppConfirmBottomSheet.show(
      context,
      title: AppStrings.demoDataTitle,
      message: AppStrings.demoDataMessage,
      confirmLabel: "Nạp dữ liệu",
      isDestructive: true,
    );
    if (!confirmed) return;

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

    var seeded = false;
    try {
      await populateJohnyData(widget.repo);
      seeded = true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.genericError)));
      }
    } finally {
      if (mounted) Navigator.of(context).pop(); // dismiss loading
    }

    if (!mounted || !seeded) return;
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
          Text("Giao diện", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text("Chế độ tối"),
            subtitle: const Text("Giao diện tối, dễ nhìn ban đêm"),
            value: settings.themePreference.isDark,
            onChanged: (v) => notifier.update(
              settings.copyWith(
                themePreference: v
                    ? AppThemePreference.dark
                    : AppThemePreference.light,
              ),
            ),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text("Màu sắc khác"),
            subtitle: const Text(
              "Chọn thêm màu chủ đạo thay cho ngọc lục bảo mặc định",
            ),
            value: settings.enableAccentColors,
            onChanged: (v) => notifier.update(
              settings.copyWith(
                enableAccentColors: v,
                seedColor: v ? settings.seedColor : AppColors.brandGreen,
                useColoredSurfaces: true,
              ),
            ),
          ),
          if (!settings.enableAccentColors) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.brandGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "Ngọc lục bảo (mặc định)",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
          if (settings.enableAccentColors) ...[
            const SizedBox(height: 16),
            Text(
              "Màu chủ đạo",
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
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
          ],
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
              Text("Tuỳ chỉnh", style: Theme.of(context).textTheme.titleMedium),
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
        if (_showPwaInstallEntry(context)) _buildPwaInstallTile(context),
      ],
    );
  }

  bool _showPwaInstallEntry(BuildContext context) {
    if (!kIsWeb) return false;
    final controller = PwaScope.maybeOf(context);
    if (controller == null) return false;
    return !controller.isStandalone;
  }

  Widget _buildPwaInstallTile(BuildContext context) {
    final controller = PwaScope.of(context);
    return ListTile(
      leading: const Icon(Icons.install_mobile_rounded),
      title: const Text(AppStrings.pwaInstallMenuItem),
      subtitle: const Text(AppStrings.pwaInstallMenuSubtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await PwaInstallGuideSheet.show(
          context,
          platform: controller.platform,
          showNativeInstall: controller.canNativeInstall,
          onNativeInstall: () async {
            final result = await controller.install();
            if (result == PwaInstallPromptResult.accepted) {
              await controller.onInstallAccepted();
            }
          },
        );
      },
    );
  }

  Widget _buildDemoCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Dữ liệu demo", style: Theme.of(context).textTheme.titleMedium),
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
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        child: const Text(
                          "JN",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Nhân vật Johny Nguyễn",
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              "Software Engineer · TP.HCM · 45tr/tháng",
                              style: Theme.of(context).textTheme.bodySmall,
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
          PageHeaderSliver(title: "Cá nhân"),
          SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        const PageHeaderSliver(title: "Cá nhân"),
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
                color: preset.color.withValues(alpha: selected ? 0.55 : 0.20),
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
