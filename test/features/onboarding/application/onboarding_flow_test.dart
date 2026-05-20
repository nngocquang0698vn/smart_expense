import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/features/onboarding/application/onboarding_flow.dart";

void main() {
  group("OnboardingFlow.pageCount", () {
    test("returns 4 without PWA guide page", () {
      expect(
        OnboardingFlow.pageCount(showPwaGuidePage: false),
        OnboardingFlow.pageCountWithoutPwa,
      );
    });

    test("returns 5 with PWA guide as third page on web", () {
      expect(
        OnboardingFlow.pageCount(showPwaGuidePage: true),
        OnboardingFlow.pageCountWithPwa,
      );
    });
  });

  group("OnboardingFlow.namePageIndex", () {
    test("last page is index 3 without PWA", () {
      expect(OnboardingFlow.namePageIndex(showPwaGuidePage: false), 3);
    });

    test("last page is index 4 with PWA guide", () {
      expect(OnboardingFlow.namePageIndex(showPwaGuidePage: true), 4);
    });
  });

  group("OnboardingFlow.showPwaUiOnWeb", () {
    test("hides PWA UI when not web", () {
      expect(
        OnboardingFlow.showPwaUiOnWeb(isWeb: false, eligible: true),
        isFalse,
      );
    });

    test("hides PWA UI on web when not eligible", () {
      expect(
        OnboardingFlow.showPwaUiOnWeb(isWeb: true, eligible: false),
        isFalse,
      );
    });

    test("shows PWA UI only on eligible web", () {
      expect(
        OnboardingFlow.showPwaUiOnWeb(isWeb: true, eligible: true),
        isTrue,
      );
    });
  });
}
