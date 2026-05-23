import "package:flutter/material.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

/// Segmented Chi tiêu / Thu nhập — nửa chọn nền xanh lá, chữ trắng (Stitch).
class TransactionTypeToggle extends StatelessWidget {
  const TransactionTypeToggle({
    super.key,
    required this.isIncome,
    required this.onChanged,
    this.onSideChanged,
  });

  final bool isIncome;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onSideChanged;

  static const double _height = 48;
  static const double _padding = 4;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final track = AppTransactionEntryTokens.toggleTrack(brightness);
    final selectedFill = AppTransactionEntryTokens.toggleSelectedFill(
      brightness,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final innerWidth = constraints.maxWidth - _padding * 2;
        final segmentWidth = innerWidth / 2;

        return SizedBox(
          height: _height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: track,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Padding(
              padding: const EdgeInsets.all(_padding),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: AppDurations.normal,
                    curve: Curves.easeOutCubic,
                    left: isIncome ? segmentWidth : 0,
                    top: 0,
                    bottom: 0,
                    width: segmentWidth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: selectedFill,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _SegmentLabel(
                        label: context.l10n.expense,
                        selected: !isIncome,
                        onTap: () => _select(context, false),
                      ),
                      _SegmentLabel(
                        label: context.l10n.income,
                        selected: isIncome,
                        onTap: () => _select(context, true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _select(BuildContext context, bool income) {
    if (income == isIncome) return;
    onChanged(income);
    onSideChanged?.call();
  }
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final selectedColor = AppTransactionEntryTokens.toggleSelectedLabel(
      brightness,
    );
    final unselectedColor = AppTransactionEntryTokens.toggleUnselectedLabel(
      brightness,
    );

    return Expanded(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: AppDurations.fast,
              curve: Curves.easeOut,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.1,
                color: selected ? selectedColor : unselectedColor,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
