import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

/// iOS Safari blue used for toolbar/share affordances (SF Symbol style).
const Color _kIosSystemBlue = Color(0xFF007AFF);

/// iOS Safari install guide — Stitch «Hướng dẫn cài đặt iOS», Cupertino chrome.
class PwaIosInstallGuideSheet extends StatelessWidget {
  const PwaIosInstallGuideSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showCupertinoModalPopup<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (sheetContext) {
        final bottom = MediaQuery.paddingOf(sheetContext).bottom;
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.92,
              ),
              padding: EdgeInsets.only(bottom: bottom),
              decoration: const BoxDecoration(
                color: CupertinoColors.systemBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: const PwaIosInstallGuideSheet(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = [
      _IosStep(
        number: 1,
        text: l10n.pwaIosGuideStep1,
        helper: l10n.pwaIosShareLabel,
        preview: const _SafariShareBarPreview(),
      ),
      _IosStep(
        number: 2,
        text: l10n.pwaIosGuideStep2,
        helper: l10n.pwaIosAddToHomeLabel,
        preview: _SafariAddToHomeRowPreview(label: l10n.pwaIosAddToHomeLabel),
      ),
      _IosStep(
        number: 3,
        text: l10n.pwaIosGuideStep3,
        helper: null,
        preview: const _SafariAddButtonPreview(),
      ),
    ];

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey3.resolveFrom(context),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            Text(
              l10n.pwaIosGuideTitle,
              textAlign: TextAlign.center,
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle
                  .copyWith(
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.pwaIosGuideBody,
              textAlign: TextAlign.center,
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...steps.map((step) => _IosStepCard(step: step)),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                borderRadius: BorderRadius.circular(12),
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.pwaIosGuideDone),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mimics Safari bottom toolbar with Share (square.and.arrow.up).
class _SafariShareBarPreview extends StatelessWidget {
  const _SafariShareBarPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: const Center(
        child: Icon(
          CupertinoIcons.square_arrow_up,
          size: 30,
          color: _kIosSystemBlue,
        ),
      ),
    );
  }
}

/// Mimics a row inside the Safari share sheet menu.
class _SafariAddToHomeRowPreview extends StatelessWidget {
  const _SafariAddToHomeRowPreview({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Icon(
              Icons.add_box_outlined,
              size: 24,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mimics the blue «Add» action on the iOS share-sheet header.
class _SafariAddButtonPreview extends StatelessWidget {
  const _SafariAddButtonPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "Add",
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              color: _kIosSystemBlue,
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
        ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _kIosSystemBlue,
              shape: BoxShape.circle,
            ),
            child: Text(
              "${step.number}",
              style: const TextStyle(
                color: CupertinoColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.text,
                  style: CupertinoTheme.of(context).textTheme.textStyle
                      .copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (step.helper != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    step.helper!,
                    style: CupertinoTheme.of(context).textTheme.textStyle
                        .copyWith(
                          fontSize: 12,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
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
