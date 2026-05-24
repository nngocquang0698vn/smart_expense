import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_controller.dart";
import "package:smart_expense/features/onboarding/application/onboarding_flow.dart";
import "package:smart_expense/features/onboarding/presentation/onboarding_layout_metrics.dart";
import "package:smart_expense/features/onboarding/presentation/onboarding_nav_row.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";
import "package:smart_expense/shared/design_system/tokens/app_spacing.dart";
import "package:smart_expense/shared/layouts/onboarding_page_layout.dart";
import "package:smart_expense/shared/components/pwa/pwa_install_hint.dart";
import "package:smart_expense/shared/components/pwa/pwa_install_onboarding_page.dart";

/// Chiều rộng tối đa nội dung onboarding (mobile + PWA web rộng).
const double kOnboardingContentMaxWidth = 480;

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.repo, required this.onDone});

  final LedgerRepository repo;
  final VoidCallback onDone;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _i = 0;
  final _nameCtrl = TextEditingController();
  bool _showNameError = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  int _pageCount(bool showPwaGuide) =>
      OnboardingFlow.pageCount(showPwaGuidePage: showPwaGuide);

  int _namePageIndex(bool showPwaGuide) =>
      OnboardingFlow.namePageIndex(showPwaGuidePage: showPwaGuide);

  void _next(int pageCount) {
    if (_i < pageCount - 1) {
      _goToPage(_i + 1);
    }
  }

  void _prev() {
    if (_i > 0) {
      _goToPage(_i - 1);
    }
  }

  Future<void> _finish() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _showNameError = true);
      return;
    }
    await widget.repo.setUserName(name);
    await widget.repo.setOnboarded(true);
    widget.onDone();
  }

  void _goToPage(int index) {
    if (index == _i) return;
    setState(() => _i = index);
  }

  void _skipToName(int namePageIndex) => _goToPage(namePageIndex);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pwaNotifier = ref.read(pwaInstallControllerProvider.notifier);
    final showHint = OnboardingFlow.showPwaUiOnWeb(
      isWeb: kIsWeb,
      eligible: pwaNotifier.shouldShowOnboardingHint(),
    );
    final showPwaGuide = OnboardingFlow.showPwaUiOnWeb(
      isWeb: kIsWeb,
      eligible: pwaNotifier.shouldShowOnboardingCard(),
    );
    final pageCount = _pageCount(showPwaGuide);
    final namePageIndex = _namePageIndex(showPwaGuide);
    final isLast = _i == namePageIndex;
    final cs = Theme.of(context).colorScheme;
    final nameSectionHeight = onboardingNameSectionHeight(context);

    final pages = <Widget>[
      _IntroPage(
        key: const ValueKey("onboarding_intro"),
        title: l10n.onboardingIntroTitle,
        body: l10n.onboardingIntroBody,
        icon: Icons.account_balance_wallet_outlined,
        footer: showHint ? const PwaInstallHint() : null,
      ),
      _IntroPage(
        key: const ValueKey("onboarding_fast"),
        title: l10n.onboardingFastTitle,
        body: l10n.onboardingFastBody,
        icon: Icons.bolt,
      ),
      if (showPwaGuide)
        const PwaInstallOnboardingPage(key: ValueKey("onboarding_pwa")),
      _IntroPage(
        key: const ValueKey("onboarding_review"),
        title: l10n.onboardingReviewTitle,
        body: l10n.onboardingReviewBody,
        icon: Icons.fact_check,
      ),
      _IntroPage(
        key: const ValueKey("onboarding_insights"),
        title: l10n.onboardingInsightsTitle,
        body: l10n.onboardingInsightsBody,
        icon: Icons.insights,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final reserveNameSlot = OnboardingFlow.shouldReserveNameFieldSlot(
              isLastPage: isLast,
              viewportAllowsReserve: _canReserveNameFieldSlot(
                viewportHeight: viewport.maxHeight,
                footerHeight: onboardingFooterHeight(context),
              ),
              currentPageIndex: _i,
              showPwaGuidePage: showPwaGuide,
            );

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: kOnboardingContentMaxWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      if (!isLast)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 4),
                          child: Row(
                            children: [
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => _skipToName(namePageIndex),
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: cs.onSurfaceVariant,
                                ),
                                label: Text(l10n.onboardingSkip),
                                style: TextButton.styleFrom(
                                  foregroundColor: cs.onSurfaceVariant,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const SizedBox(height: 44),

                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeOut,
                          child: KeyedSubtree(
                            key: ValueKey<int>(_i),
                            child: pages[_i],
                          ),
                        ),
                      ),

                      if (isLast)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: kOnboardingNameFieldTopGap,
                            bottom: kOnboardingNameFieldToDotsGap,
                          ),
                          child: TextField(
                            controller: _nameCtrl,
                            decoration: InputDecoration(
                              labelText: l10n.onboardingNameLabel,
                              hintText: l10n.onboardingNameHint,
                              errorText: _showNameError
                                  ? l10n.onboardingNameRequired
                                  : null,
                            ),
                            textCapitalization: TextCapitalization.words,
                            onChanged: (_) {
                              if (_showNameError) {
                                setState(() => _showNameError = false);
                              }
                            },
                            onSubmitted: (_) => _finish(),
                          ),
                        )
                      else if (reserveNameSlot)
                        SizedBox(height: nameSectionHeight),

                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: kOnboardingDotsToButtonsGap,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(pageCount, (idx) {
                            final active = idx == _i;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xxs,
                              ),
                              width: active ? 24 : kOnboardingProgressDotSize,
                              height: kOnboardingProgressDotSize,
                              decoration: BoxDecoration(
                                color: active
                                    ? cs.primary
                                    : cs.primary.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: isLast
                            ? OnboardingLastNavRow(
                                onBack: _prev,
                                onStart: _finish,
                                backLabel: l10n.onboardingBack,
                                startLabel: l10n.onboardingStart,
                              )
                            : OnboardingNavRow(
                                showPrevious: _i > 0,
                                onPrevious: _prev,
                                onNext: () => _next(pageCount),
                                previousLabel: l10n.onboardingPrevious,
                                nextLabel: l10n.onboardingNext,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Chỉ giữ slot ô tên khi còn đủ chiều cao cho PageView + nội dung intro gọn.
  static bool _canReserveNameFieldSlot({
    required double viewportHeight,
    required double footerHeight,
  }) {
    const headerHeight = 52;
    const minPageContent = 280;
    final pageViewHeight = viewportHeight - headerHeight - footerHeight;
    return pageViewHeight >= minPageContent;
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({
    super.key,
    required this.title,
    required this.body,
    required this.icon,
    this.footer,
  });

  final String title;
  final String body;
  final IconData icon;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.headlineSmall;
    final iconSize = titleStyle?.fontSize ?? 24;

    return OnboardingPageLayout(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: titleStyle,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: iconSize, color: cs.primary),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (footer != null) ...[footer!],
        ],
      ),
    );
  }
}
