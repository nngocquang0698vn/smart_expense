/// Luồng trang onboarding — logic thuần, dễ unit test.
abstract final class OnboardingFlow {
  static const int pageCountWithoutPwa = 4;
  static const int pageCountWithPwa = 5;

  static int pageCount({required bool showPwaGuidePage}) {
    return showPwaGuidePage ? pageCountWithPwa : pageCountWithoutPwa;
  }

  static int namePageIndex({required bool showPwaGuidePage}) {
    return showPwaGuidePage ? 4 : 3;
  }

  /// Index of the PWA install guide page when shown (always page 3 of 5).
  static int? pwaGuidePageIndex({required bool showPwaGuidePage}) {
    return showPwaGuidePage ? 2 : null;
  }

  /// Reserve name-field slot on earlier pages to avoid layout jump on last page.
  /// Skip on tall pages (PWA guide) so content can use full height.
  static bool shouldReserveNameFieldSlot({
    required bool isLastPage,
    required bool viewportAllowsReserve,
    required int currentPageIndex,
    required bool showPwaGuidePage,
  }) {
    if (isLastPage || !viewportAllowsReserve) return false;
    final pwaIndex = pwaGuidePageIndex(showPwaGuidePage: showPwaGuidePage);
    if (pwaIndex != null && currentPageIndex == pwaIndex) return false;
    return true;
  }

  static bool showPwaUiOnWeb({required bool isWeb, required bool eligible}) {
    return isWeb && eligible;
  }
}
