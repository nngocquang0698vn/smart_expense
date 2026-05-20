import "package:flutter/material.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

/// Safari system blue — chỉ dùng cho affordance Chia sẻ / Thêm trong hướng dẫn iOS.
const Color kPwaSafariActionBlue = Color(0xFF007AFF);

/// Nội dung hướng dẫn cài PWA (dùng chung onboarding + bottom sheet).
class PwaInstallGuideContent extends StatelessWidget {
  const PwaInstallGuideContent({
    super.key,
    this.onPrimaryPressed,
    this.primaryButtonLabel,
    this.compact = false,
  });

  final VoidCallback? onPrimaryPressed;
  final String? primaryButtonLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final hPad = compact ? 16.0 : 16.0;
    final vPad = compact ? 8.0 : 0.0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, 16),
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
          _IosStepCard(
            step: 1,
            text: l10n.pwaIosGuideStep1,
            helper: l10n.pwaIosShareLabel,
            preview: const _SafariShareBarPreview(),
          ),
          _IosStepCard(
            step: 2,
            text: l10n.pwaIosGuideStep2,
            helper: l10n.pwaIosAddToHomeLabel,
            preview: _SafariAddToHomeRowPreview(
              label: l10n.pwaIosAddToHomeLabel,
            ),
          ),
          _IosStepCard(
            step: 3,
            text: l10n.pwaIosGuideStep3,
            preview: const _SafariAddActionPreview(),
          ),
          if (onPrimaryPressed != null && primaryButtonLabel != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.center,
              child: FilledButton(
                onPressed: onPrimaryPressed,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  minimumSize: const Size(0, 44),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(primaryButtonLabel!),
              ),
            ),
          ],
        ],
          ),
        ),
      ),
    );
  }
}

class _SafariShareBarPreview extends StatelessWidget {
  const _SafariShareBarPreview();

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
      child: const Icon(
        Icons.ios_share_rounded,
        size: 32,
        color: kPwaSafariActionBlue,
      ),
    );
  }
}

class _SafariAddToHomeRowPreview extends StatelessWidget {
  const _SafariAddToHomeRowPreview({required this.label});

  final String label;

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
            const Icon(
              Icons.add_box_outlined,
              size: 24,
              color: kPwaSafariActionBlue,
            ),
          ],
        ),
      ),
    );
  }
}

class _SafariAddActionPreview extends StatelessWidget {
  const _SafariAddActionPreview();

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "Thêm",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: kPwaSafariActionBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            " / Add",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: kPwaSafariActionBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _IosStepCard extends StatelessWidget {
  const _IosStepCard({
    required this.step,
    required this.text,
    this.helper,
    this.preview,
  });

  final int step;
  final String text;
  final String? helper;
  final Widget? preview;

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
              "$step",
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
                _StepText(step: step, text: text),
                if (helper != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    helper!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (preview != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Center(child: preview),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepText extends StatelessWidget {
  const _StepText({required this.step, required this.text});

  final int step;
  final String text;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyLarge;
    final accent = base?.copyWith(
      color: kPwaSafariActionBlue,
      fontWeight: FontWeight.w600,
    );

    switch (step) {
      case 1:
        return Text.rich(
          TextSpan(
            style: base,
            children: [
              const TextSpan(text: "Nhấn nút "),
              TextSpan(text: "chia sẻ", style: accent),
              const TextSpan(text: " ở thanh dưới Safari."),
            ],
          ),
        );
      case 3:
        return Text.rich(
          TextSpan(
            style: base,
            children: [
              const TextSpan(text: "Nhấn nút "),
              TextSpan(text: "Thêm", style: accent),
              const TextSpan(text: " (hoặc "),
              TextSpan(text: "Add", style: accent),
              const TextSpan(text: ") để hoàn tất."),
            ],
          ),
        );
      default:
        return Text(text, style: base);
    }
  }
}
