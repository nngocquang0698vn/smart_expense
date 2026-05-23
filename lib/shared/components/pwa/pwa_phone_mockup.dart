import "package:flutter/material.dart";

import "package:smart_expense/shared/design_system/design_system.dart";

/// Phone mockup from Stitch «Onboarding - Thẻ cài đặt app» (CSS-only in export).
class PwaPhoneMockup extends StatelessWidget {
  const PwaPhoneMockup({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 180,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(-0.18)
              ..rotateX(0.08),
            child: Container(
              width: 120,
              height: 168,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: cs.outlineVariant, width: 5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: ColoredBox(
                  color: cs.surfaceContainerLow,
                  child: Column(
                    children: [
                      const SizedBox(height: 28),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: cs.onPrimary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 72,
                        height: 6,
                        decoration: BoxDecoration(
                          color: cs.outlineVariant,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 48,
                        height: 6,
                        decoration: BoxDecoration(
                          color: cs.outlineVariant.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        height: 28,
                        decoration: BoxDecoration(
                          color: cs.surface,
                          border: Border(
                            top: BorderSide(
                              color: cs.outlineVariant.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            4,
                            (i) => Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: i == 2
                                    ? cs.primary
                                    : cs.primary.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 4,
            bottom: 8,
            child: Transform.rotate(
              angle: 0.05,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.surface, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_to_home_screen_rounded,
                      size: 16,
                      color: cs.onPrimaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Install",
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PwaInstallBenefitRow extends StatelessWidget {
  const PwaInstallBenefitRow({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: cs.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
      ],
    );
  }
}
