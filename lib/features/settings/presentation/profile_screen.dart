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
import "package:smart_expense/features/settings/application/demo_review_data_service.dart";
import "package:smart_expense/features/settings/application/notifications/review_notification_platform.dart";
import "package:smart_expense/features/settings/application/review_reminder_scheduler.dart";
import "package:smart_expense/features/settings/application/user_preferences_controller.dart";
import "package:smart_expense/features/settings/domain/review_reminder_settings.dart";
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
  final _nameFocus = FocusNode();
  late final LedgerRepository _repo;
  late final StreamSubscription<void> _repoSubscription;
  String _loadedName = "";
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
    _nameFocus.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _onRepo() => _load();

  Future<void> _load() async {
    final m = await _repo.getMeta();
    if (!mounted) return;
    final loadedName = (m["userName"] as String?) ?? "";
    setState(() {
      final hasLocalEdit = _nameCtrl.text != _loadedName;
      if (!_nameFocus.hasFocus && !hasLocalEdit) {
        _nameCtrl.text = loadedName;
      }
      _loadedName = loadedName;
      _loading = false;
    });
  }

  Future<void> _saveName() async {
    final nextName = _nameCtrl.text.trim();
    await _repo.setUserName(nextName);
    _loadedName = nextName;
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

  Future<void> _setReviewReminderEnabled(bool enabled) async {
    final scheduler = ref.read(reviewReminderSchedulerProvider.notifier);
    final prefs = ref.read(userPreferencesControllerProvider);
    final current = prefs.reviewReminder;
    if (!enabled) {
      await scheduler.disableReminder();
      if (mounted) {
        showInfo(context, context.l10n.text("reviewReminderDisabled"));
      }
      return;
    }

    final status = await scheduler.requestPermission();
    if (!mounted) return;
    if (status != ReviewNotificationPermissionStatus.granted) {
      final message = status == ReviewNotificationPermissionStatus.denied
          ? context.l10n.text("reviewReminderPermissionBlocked")
          : context.l10n.text("reviewReminderPermissionRequired");
      showWarning(context, message);
      return;
    }
    await _saveReviewReminderSettings(current.copyWith(enabled: true));
  }

  Future<void> _saveReviewReminderSettings(
    ReviewReminderSettings settings,
  ) async {
    final errors = settings.validate();
    if (errors.isNotEmpty) {
      showWarning(context, errors.first);
      return;
    }
    final warnings = settings.warnings();
    if (warnings.isNotEmpty && mounted) {
      showInfo(context, warnings.first);
    }
    await ref
        .read(reviewReminderSchedulerProvider.notifier)
        .updateSettings(settings);
  }

  Future<void> _pickReviewTime({
    required ReviewReminderTime initial,
    required ValueChanged<ReviewReminderTime> onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    );
    if (picked == null || !mounted) return;
    onPicked(ReviewReminderTime(hour: picked.hour, minute: picked.minute));
  }

  Future<void> _createPendingReviewDemo() async {
    try {
      await DemoReviewDataService(_repo).seedPendingReviewTransactions();
      if (mounted) {
        showSuccess(context, context.l10n.text("demoReviewSeedSuccess"));
      }
    } catch (_) {
      if (mounted) showError(context, context.l10n.genericError);
    }
  }

  Future<void> _scheduleDemoNotification() async {
    final scheduler = ref.read(reviewReminderSchedulerProvider.notifier);
    final permission = await scheduler.requestPermission();
    if (!mounted) return;
    if (permission != ReviewNotificationPermissionStatus.granted) {
      showWarning(
        context,
        context.l10n.text("reviewReminderPermissionRequired"),
      );
      return;
    }
    final scheduled = await scheduler.scheduleDemoNotification(
      const Duration(seconds: 20),
    );
    if (!mounted) return;
    if (!scheduled) {
      showWarning(context, context.l10n.text("demoNotificationNoPending"));
      return;
    }
    showSuccess(context, context.l10n.text("demoNotificationScheduled"));
  }

  Future<void> _clearAllTransactionData() async {
    final confirmed = await AppConfirmBottomSheet.show(
      context,
      title: context.l10n.text("clearAllDataTitle"),
      message: context.l10n.text("clearAllDataMessage"),
      confirmLabel: context.l10n.text("clearAllDataConfirm"),
      isDestructive: true,
    );
    if (!confirmed) return;
    try {
      await _repo.clearAllTransactions();
      if (mounted) {
        showSuccess(context, context.l10n.text("clearAllDataSuccess"));
      }
    } catch (_) {
      if (mounted) showError(context, context.l10n.genericError);
    }
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

  Widget _buildReviewReminderSection(BuildContext context) {
    final prefs = ref.watch(userPreferencesControllerProvider);
    final settings = prefs.reviewReminder;
    final mode = settings.mode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.text("reviewReminderSectionTitle"),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.notifications_active_outlined),
            title: Text(context.l10n.text("reviewReminderEnabledTitle")),
            subtitle: Text(context.l10n.text("reviewReminderEnabledSubtitle")),
            value: settings.enabled,
            onChanged: _setReviewReminderEnabled,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.text("reviewReminderModeLabel"),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<ReviewReminderMode>(
            segments: [
              ButtonSegment(
                value: ReviewReminderMode.endOfDay,
                icon: const Icon(Icons.nights_stay_outlined),
                label: Text(context.l10n.text("reviewReminderModeEndOfDay")),
              ),
              ButtonSegment(
                value: ReviewReminderMode.interval,
                icon: const Icon(Icons.schedule_outlined),
                label: Text(context.l10n.text("reviewReminderModeInterval")),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (selection) {
              _saveReviewReminderSettings(
                settings.copyWith(mode: selection.first),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            mode == ReviewReminderMode.endOfDay
                ? context.l10n.text("reviewReminderEndOfDayDescription")
                : context.l10n.text("reviewReminderIntervalDescription"),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          if (mode == ReviewReminderMode.endOfDay)
            _TimeSettingTile(
              icon: Icons.access_time_rounded,
              title: context.l10n.text("reviewReminderEndOfDayTime"),
              value: settings.endOfDayReminderTime.label,
              onTap: () => _pickReviewTime(
                initial: settings.endOfDayReminderTime,
                onPicked: (time) => _saveReviewReminderSettings(
                  settings.copyWith(endOfDayReminderTime: time),
                ),
              ),
            )
          else ...[
            _TimeSettingTile(
              icon: Icons.play_arrow_rounded,
              title: context.l10n.text("reviewReminderStartTime"),
              value: settings.intervalReminderStartTime.label,
              onTap: () => _pickReviewTime(
                initial: settings.intervalReminderStartTime,
                onPicked: (time) => _saveReviewReminderSettings(
                  settings.copyWith(intervalReminderStartTime: time),
                ),
              ),
            ),
            _TimeSettingTile(
              icon: Icons.stop_rounded,
              title: context.l10n.text("reviewReminderEndTime"),
              value: settings.intervalReminderEndTime.label,
              onTap: () => _pickReviewTime(
                initial: settings.intervalReminderEndTime,
                onPicked: (time) => _saveReviewReminderSettings(
                  settings.copyWith(intervalReminderEndTime: time),
                ),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.repeat_rounded),
              title: Text(context.l10n.text("reviewReminderIntervalHours")),
              trailing: DropdownButton<int>(
                value: settings.intervalReminderHours,
                items: [
                  for (
                    var hour = ReviewReminderDefaults.minIntervalHours;
                    hour <= ReviewReminderDefaults.maxIntervalHours;
                    hour++
                  )
                    DropdownMenuItem(
                      value: hour,
                      child: Text("$hour ${context.l10n.text("hourUnit")}"),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  _saveReviewReminderSettings(
                    settings.copyWith(intervalReminderHours: value),
                  );
                },
              ),
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
                      focusNode: _nameFocus,
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
        _buildQuickConfirmTile(context),
        ListTile(
          leading: const Icon(Icons.add_circle_outline),
          title: Text(context.l10n.quickTransactionTitle),
          onTap: () => handleAddFab(context, _repo),
        ),
        if (_showPwaInstallEntry()) _buildPwaInstallTile(context),
        _buildDemoSection(context),
      ],
    );
  }

  Widget _buildDemoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              context.l10n.text("reviewDemoSectionTitle"),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add_check_rounded),
            title: Text(context.l10n.text("demoCreatePendingReview")),
            onTap: _createPendingReviewDemo,
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: Text(context.l10n.text("demoSendNotification20s")),
            onTap: _scheduleDemoNotification,
          ),
          ListTile(
            leading: const Icon(Icons.refresh_rounded),
            title: Text(context.l10n.text("clearAllDataAction")),
            onTap: _clearAllTransactionData,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
            child: Text(
              context.l10n.text("sampleDataSectionTitle"),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dataset_outlined),
            title: Text(context.l10n.demoSectionTitle),
            subtitle: Text(context.l10n.demoPersonSummary),
            onTap: _populateJohny,
          ),
        ],
      ),
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

  Widget _buildQuickConfirmTile(BuildContext context) {
    final prefs = ref.watch(userPreferencesControllerProvider);
    final notifier = ref.read(userPreferencesControllerProvider.notifier);

    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      secondary: const Icon(Icons.bolt_outlined),
      title: Text(context.l10n.quickConfirmPendingTitle),
      subtitle: Text(context.l10n.quickConfirmPendingSubtitle),
      value: prefs.quickConfirmPending,
      onChanged: (v) => notifier.update(prefs.copyWith(quickConfirmPending: v)),
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
                _buildReviewReminderSection(context),
                const Divider(height: 24, indent: 16, endIndent: 16),
                _buildLeftPanel(context),
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

class _TimeSettingTile extends StatelessWidget {
  const _TimeSettingTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
      onTap: onTap,
    );
  }
}
