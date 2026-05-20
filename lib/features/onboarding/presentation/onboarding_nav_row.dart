import "package:flutter/material.dart";

import "package:smart_expense/shared/design_system/tokens/app_spacing.dart";

ButtonStyle onboardingOutlinedButtonStyle(BuildContext context) {
  return OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    minimumSize: const Size(0, 40),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

ButtonStyle onboardingFilledButtonStyle(BuildContext context) {
  return FilledButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    minimumSize: const Size(0, 40),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

/// Hàng nút Trước / Tiếp theo — cùng một dòng, chiều cao gọn.
class OnboardingNavRow extends StatelessWidget {
  const OnboardingNavRow({
    super.key,
    required this.showPrevious,
    required this.onPrevious,
    required this.onNext,
    required this.previousLabel,
    required this.nextLabel,
  });

  final bool showPrevious;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final String previousLabel;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    final outlined = onboardingOutlinedButtonStyle(context);
    final filled = onboardingFilledButtonStyle(context);

    if (!showPrevious) {
      return Align(
        alignment: Alignment.center,
        child: FilledButton.icon(
          onPressed: onNext,
          style: filled,
          label: Text(nextLabel),
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          iconAlignment: IconAlignment.end,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: onPrevious,
          style: outlined,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: Text(previousLabel),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: FilledButton.icon(
            onPressed: onNext,
            style: filled,
            label: Text(nextLabel),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            iconAlignment: IconAlignment.end,
          ),
        ),
      ],
    );
  }
}

/// Hàng nút Quay lại / Bắt đầu ở màn nhập tên — cùng layout với [OnboardingNavRow].
class OnboardingLastNavRow extends StatelessWidget {
  const OnboardingLastNavRow({
    super.key,
    required this.onBack,
    required this.onStart,
    required this.backLabel,
    required this.startLabel,
  });

  final VoidCallback onBack;
  final VoidCallback onStart;
  final String backLabel;
  final String startLabel;

  @override
  Widget build(BuildContext context) {
    final outlined = onboardingOutlinedButtonStyle(context);
    final filled = onboardingFilledButtonStyle(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: onBack,
          style: outlined,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: Text(backLabel),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: FilledButton(
            onPressed: onStart,
            style: filled,
            child: Text(startLabel),
          ),
        ),
      ],
    );
  }
}
