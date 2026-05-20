import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_controller.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";
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
  final _page = PageController();
  int _i = 0;
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _page.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  int _pageCount(bool showPwaGuide) => showPwaGuide ? 5 : 4;

  int _namePageIndex(bool showPwaGuide) => showPwaGuide ? 4 : 3;

  void _next(int pageCount) {
    if (_i < pageCount - 1) {
      _page.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _prev() {
    if (_i > 0) {
      _page.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _finish() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.onboardingNameRequired)),
      );
      return;
    }
    await widget.repo.setUserName(name);
    await widget.repo.setOnboarded(true);
    widget.onDone();
  }

  void _skipToName(int namePageIndex) {
    _page.animateToPage(
      namePageIndex,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pwaNotifier = ref.read(pwaInstallControllerProvider.notifier);
    final showHint = kIsWeb && pwaNotifier.shouldShowOnboardingHint();
    final showPwaGuide = kIsWeb && pwaNotifier.shouldShowOnboardingCard();
    final pageCount = _pageCount(showPwaGuide);
    final namePageIndex = _namePageIndex(showPwaGuide);
    final isLast = _i == namePageIndex;
    final cs = Theme.of(context).colorScheme;

    final pages = <Widget>[
      _IntroPage(
        title: l10n.onboardingIntroTitle,
        body: l10n.onboardingIntroBody,
        icon: Icons.account_balance_wallet_outlined,
        footer: showHint ? const PwaInstallHint() : null,
      ),
      _IntroPage(
        title: l10n.onboardingFastTitle,
        body: l10n.onboardingFastBody,
        icon: Icons.bolt,
      ),
      if (showPwaGuide) const PwaInstallOnboardingPage(),
      _IntroPage(
        title: l10n.onboardingReviewTitle,
        body: l10n.onboardingReviewBody,
        icon: Icons.fact_check,
      ),
      _IntroPage(
        title: l10n.onboardingInsightsTitle,
        body: l10n.onboardingInsightsBody,
        icon: Icons.insights,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kOnboardingContentMaxWidth),
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
                    child: PageView(
                      controller: _page,
                      onPageChanged: (v) => setState(() => _i = v),
                      children: pages,
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(pageCount, (idx) {
                        final active = idx == _i;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 24 : 8,
                          height: 8,
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
                    padding: const EdgeInsets.only(bottom: 16),
                    child: isLast
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _nameCtrl,
                                decoration: InputDecoration(
                                  labelText: l10n.onboardingNameLabel,
                                  hintText: l10n.onboardingNameHint,
                                ),
                                textCapitalization: TextCapitalization.words,
                                onSubmitted: (_) => _finish(),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _prev,
                                    style: _onboardingOutlinedStyle(context),
                                    icon: const Icon(
                                      Icons.arrow_back_rounded,
                                      size: 18,
                                    ),
                                    label: Text(l10n.onboardingBack),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: _finish,
                                      style: _onboardingFilledStyle(context),
                                      child: Text(l10n.onboardingStart),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : _OnboardingNavRow(
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
        ),
      ),
    );
  }
}

ButtonStyle _onboardingOutlinedStyle(BuildContext context) {
  return OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    minimumSize: const Size(0, 40),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

ButtonStyle _onboardingFilledStyle(BuildContext context) {
  return FilledButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    minimumSize: const Size(0, 40),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

class _OnboardingNavRow extends StatelessWidget {
  const _OnboardingNavRow({
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
    final outlined = _onboardingOutlinedStyle(context);
    final filled = _onboardingFilledStyle(context);

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
      children: [
        OutlinedButton.icon(
          onPressed: onPrevious,
          style: outlined,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: Text(previousLabel),
        ),
        const SizedBox(width: 12),
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

class _IntroPage extends StatelessWidget {
  const _IntroPage({
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
    return OnboardingPageLayout(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
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
