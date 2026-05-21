import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/app/providers.dart";
import "package:smart_expense/core/constants/app_constants.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_controller.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/shared/components/pwa/pwa_install_actions.dart";
import "package:smart_expense/app/theme/theme_controller.dart";
import "package:smart_expense/app/theme/theme_presets.dart";
import "package:smart_expense/app/theme/theme_settings.dart";
import "package:smart_expense/shared/components/page_header_sliver.dart";
import "package:smart_expense/shared/components/app_notification.dart";
import "package:smart_expense/core/config/demo_seed.dart";
import "package:smart_expense/shared/components/app_confirm_bottom_sheet.dart";
import "package:smart_expense/features/categories/presentation/categories_screen.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";
import "package:smart_expense/features/transactions/presentation/add_options_sheet.dart";

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, required this.onOpenPending});

  final VoidCallback onOpenPending;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  late final LedgerRepository _repo;
  late final StreamSubscription<void> _repoSubscription;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(ledgerRepositoryProvider);
    _repoSubscription = _repo.changes.listen((_) => _onRepo());
    _load();
  }

  @override
  void dispose() {
    _repoSubscription.cancel();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _onRepo() => _load();

  Future<void> _load() async {
    final m = await _repo.getMeta();
    if (!mounted) return;
    setState(() {
      _nameCtrl.text = (m["userName"] as String?) ?? "";
      _loading = false;
    });
  }

  Future<void> _saveName() async {
    await _repo.setUserName(_nameCtrl.text.trim());
    if (mounted) {
      showSuccess(context, context.l10n.nameSaved);
    }
  }

  Future<void> _populateJohny() async {
    final confirmed = await AppConfirmBottomSheet.show(
      context,
      title: context.l10n.demoDataTitle,
      message: context.l10n.demoDataMessage,
      confirmLabel: context.l10n.demoDataConfirm,
      isDestructive: true,
    );
    if (!confirmed) return;

    if (!mounted) return;
    // Show loading overlay
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
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
                  Text(context.l10n.demoDataLoading),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    var seeded = false;
    try {
      await populateJohnyData(_repo);
      seeded = true;
    } catch (_) {
      if (mounted) {
        showError(context, context.l10n.genericError);
      }
    } finally {
      if (mounted) Navigator.of(context).pop(); // dismiss loading
    }

    if (!mounted || !seeded) return;
    showSuccess(context, context.l10n.demoDataLoaded);
    // Reload name field
    _load();
  }

  Widget _buildAppearanceSection(BuildContext context) {
    final settings = ref.watch(themeControllerProvider);
    final themeNotifier = ref.read(themeControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.appearanceTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(context.l10n.darkModeTitle),
            subtitle: Text(context.l10n.darkModeSubtitle),
            value: settings.themePreference.isDark,
            onChanged: (v) => themeNotifier.update(
              settings.copyWith(
                themePreference: v
                    ? AppThemePreference.dark
                    : AppThemePreference.light,
              ),
            ),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(context.l10n.accentColorsTitle),
            subtitle: Text(context.l10n.accentColorsSubtitle),
            value: settings.enableAccentColors,
            onChanged: (v) => themeNotifier.update(
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
                  context.l10n.defaultGreenPreset,
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
              context.l10n.seedColorLabel,
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
                    onTap: () => themeNotifier.update(
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
              Text(
                context.l10n.customizationTitle,
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
                      decoration: InputDecoration(
                        labelText: context.l10n.userNameLabel,
                        isDense: true,
                      ),
                      onSubmitted: (_) => _saveName(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.tonal(
                    onPressed: _saveName,
                    child: Text(context.l10n.save),
                  ),
                ],
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.category_outlined),
          title: Text(context.l10n.category),
          subtitle: Text(context.l10n.categorySubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CategoriesScreen()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.fact_check_outlined),
          title: Text(context.l10n.pendingTransactionsTitle),
          subtitle: Text(context.l10n.pendingTransactionsSubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: widget.onOpenPending,
        ),
        ListTile(
          leading: const Icon(Icons.add_circle_outline),
          title: Text(context.l10n.quickTransactionTitle),
          onTap: () => handleAddFab(context, _repo),
        ),
        if (_showPwaInstallEntry()) _buildPwaInstallTile(context),
      ],
    );
  }

  bool _showPwaInstallEntry() {
    if (!kIsWeb) return false;
    return true;
  }

  Widget _buildPwaInstallTile(BuildContext context) {
    final state = ref.watch(pwaInstallControllerProvider);
    final installed = state.isInstalledMode;
    return ListTile(
      leading: Icon(
        installed ? Icons.check_circle_outline : Icons.install_mobile_rounded,
        color: installed ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        installed
            ? context.l10n.pwaInstallMenuInstalled
            : context.l10n.pwaInstallMenuItem,
      ),
      subtitle: Text(
        installed
            ? context.l10n.pwaInstallMenuInstalledSubtitle
            : context.l10n.pwaInstallMenuSubtitle,
      ),
      trailing: installed ? null : const Icon(Icons.chevron_right),
      onTap: installed
          ? null
          : () => PwaInstallActions.requestInstall(context, ref),
    );
  }

  Widget _buildDemoCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.demoSectionTitle,
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
                              context.l10n.demoPersonName,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              context.l10n.demoPersonSummary,
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
                      child: Text(context.l10n.demoModeButton),
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
      return CustomScrollView(
        slivers: [
          PageHeaderSliver(title: context.l10n.profileTitle),
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        PageHeaderSliver(title: context.l10n.profileTitle),
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
