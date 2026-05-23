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

  static bool showPwaUiOnWeb({required bool isWeb, required bool eligible}) {
    return isWeb && eligible;
  }
}
