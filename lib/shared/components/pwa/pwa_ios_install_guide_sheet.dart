import "package:flutter/material.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

/// Hướng dẫn cài PWA trên iOS Safari — dùng theme app (Material icons cho web).
class PwaIosInstallGuideSheet extends StatelessWidget {
  const PwaIosInstallGuideSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => const PwaIosInstallGuideSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final steps = [
      _IosStep(
        number: 1,
        text: l10n.pwaIosGuideStep1,
        helper: l10n.pwaIosShareLabel,
        preview: _SafariShareBarPreview(color: cs.primary),
      ),
      _IosStep(
        number: 2,
        text: l10n.pwaIosGuideStep2,
        helper: l10n.pwaIosAddToHomeLabel,
        preview: _SafariAddToHomeRowPreview(
          label: l10n.pwaIosAddToHomeLabel,
          iconColor: cs.onSurfaceVariant,
        ),
      ),
      _IosStep(
        number: 3,
        text: l10n.pwaIosGuideStep3,
        helper: null,
        preview: _SafariAddActionPreview(color: cs.primary),
      ),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.pwaIosGuideTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.pwaIosGuideBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...steps.map((step) => _IosStepCard(step: step)),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.center,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  minimumSize: const Size(0, 44),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(l10n.pwaIosGuideDone),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thanh toolbar Safari + Share (Material — hiển thị đúng trên PWA web).
class _SafariShareBarPreview extends StatelessWidget {
  const _SafariShareBarPreview({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Icon(
        Icons.ios_share_rounded,
        size: 32,
        color: color,
      ),
    );
  }
}

class _SafariAddToHomeRowPreview extends StatelessWidget {
  const _SafariAddToHomeRowPreview({
    required this.label,
    required this.iconColor,
  });

  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Icon(Icons.add_box_outlined, size: 24, color: iconColor),
          ],
        ),
      ),
    );
  }
}

class _SafariAddActionPreview extends StatelessWidget {
  const _SafariAddActionPreview({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          "Thêm",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _IosStep {
  const _IosStep({
    required this.number,
    required this.text,
    this.helper,
    this.preview,
  });

  final int number;
  final String text;
  final String? helper;
  final Widget? preview;
}

class _IosStepCard extends StatelessWidget {
  const _IosStepCard({required this.step});

  final _IosStep step;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: cs.primary,
            child: Text(
              "${step.number}",
              style: TextStyle(
                color: cs.onPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.text, style: Theme.of(context).textTheme.bodyLarge),
                if (step.helper != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    step.helper!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (step.preview != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Center(child: step.preview),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
