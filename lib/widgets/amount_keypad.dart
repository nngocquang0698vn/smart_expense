import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "../core/constants.dart";
import "../theme/app_finance_colors.dart";

/// Custom numeric pad for VND entry — replaces the system keyboard.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({
    super.key,
    required this.onDigit,
    required this.onTripleZero,
    required this.onBackspace,
    required this.onDone,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onTripleZero;
  final VoidCallback onBackspace;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final finance = context.financeColors;
    final padBg = Theme.of(context).brightness == Brightness.dark
        ? finance.fieldFill
        : const Color(0xFFD8DCE2);

    return ColoredBox(
      color: padBg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.sm,
        ),
        child: SizedBox(
          height: 248,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _NumKey(label: "1", onTap: () => _tap(context, 1)),
                          _NumKey(label: "2", onTap: () => _tap(context, 2)),
                          _NumKey(label: "3", onTap: () => _tap(context, 3)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          _NumKey(label: "4", onTap: () => _tap(context, 4)),
                          _NumKey(label: "5", onTap: () => _tap(context, 5)),
                          _NumKey(label: "6", onTap: () => _tap(context, 6)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          _NumKey(label: "7", onTap: () => _tap(context, 7)),
                          _NumKey(label: "8", onTap: () => _tap(context, 8)),
                          _NumKey(label: "9", onTap: () => _tap(context, 9)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _NumKey(
                              label: "000",
                              onTap: () {
                                HapticFeedback.lightImpact();
                                onTripleZero();
                              },
                            ),
                          ),
                          _NumKey(label: "0", onTap: () => _tap(context, 0)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _BackspaceKey(onTap: onBackspace),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Expanded(
                      flex: 2,
                      child: _DoneKey(onTap: onDone, color: cs.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _tap(BuildContext context, int digit) {
    HapticFeedback.selectionClick();
    onDigit(digit);
  }
}

class _NumKey extends StatelessWidget {
  const _NumKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.financeColors.fieldText,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackspaceKey extends StatelessWidget {
  const _BackspaceKey({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              size: 26,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }
}

class _DoneKey extends StatelessWidget {
  const _DoneKey({required this.onTap, required this.color});

  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Center(
        child: Material(
          color: color,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              onTap();
            },
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 72,
              height: 72,
              child: Center(
                child: Text(
                  "Xong",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
