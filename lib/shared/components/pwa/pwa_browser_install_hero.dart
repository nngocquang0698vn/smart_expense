import "package:flutter/material.dart";

import "package:smart_expense/shared/design_system/design_system.dart";

/// Hero cài PWA trên trình duyệt desktop — không dùng mockup điện thoại.
class PwaBrowserInstallHero extends StatelessWidget {
  const PwaBrowserInstallHero({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 120,
      child: Center(
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg - 1),
                  ),
                ),
                child: Row(
                  children: [
                    _Dot(color: cs.error.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    _Dot(color: cs.tertiary.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    _Dot(color: cs.primary.withValues(alpha: 0.5)),
                    const Spacer(),
                    Icon(
                      Icons.install_desktop_rounded,
                      size: 14,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: cs.onPrimary,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
