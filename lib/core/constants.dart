import "package:flutter/material.dart";

/// Border radii aligned with the design-system rule (06-ui-ux-design-system):
///   small=12 · input=16 · card=20 · sheet/dialog=24 · container=28 · pill=999
abstract final class AppRadius {
  /// Small UI elements — tags inside chips, compact rows.
  static const double small = 12;

  /// Text inputs and standard buttons.
  static const double input = 16;

  /// Cards and list items with card-style surfaces.
  static const double card = 20;

  /// Bottom-sheet top corners and dialogs.
  static const double sheet = 24;

  /// Large containers — segmented-toggle wrappers, hero areas.
  static const double container = 28;

  /// Pill-shaped items — navigation bar, filter chips.
  static const double pill = 999;
}

/// Layout breakpoints shared across all screens and shells.
abstract final class AppBreakpoints {
  /// Width at which the app switches from mobile to desktop shell.
  static const double desktop = 1000;
}

/// Canonical edge insets used throughout the app.
abstract final class AppInsets {
  /// Standard horizontal padding for screen-level content.
  static const double screenH = 16;

  /// Standard vertical padding added below scrollable content so it clears
  /// the floating bottom nav bar.
  static const double listBottom = 96;

  /// Vertical + horizontal padding inside a transaction card.
  static const EdgeInsets cardPadding =
      EdgeInsets.symmetric(horizontal: 12, vertical: 10);

  /// External card margin for transaction rows.
  static const EdgeInsets cardMargin =
      EdgeInsets.symmetric(horizontal: 16, vertical: 4);

  /// Section-header padding (title rows above lists).
  static const EdgeInsets sectionHeader =
      EdgeInsets.fromLTRB(16, 12, 16, 4);

  /// Day-header padding inside history/pending groups.
  static const EdgeInsets dayHeader =
      EdgeInsets.fromLTRB(16, 12, 16, 4);
}

/// Pagination constants for the history list.
abstract final class AppPageSizes {
  /// Number of items fetched per page in the history list.
  static const int historyPage = 20;

  /// Scroll distance from the bottom at which the next page is triggered.
  static const double scrollLoadThreshold = 200;
}

/// Brand and semantic colours used across the app.
///
/// Always prefer `Theme.of(context).colorScheme` for standard M3 colours.
/// These constants cover values that fall outside the generated scheme.
abstract final class AppColors {
  /// Primary brand green used in the desktop sidebar and nav items.
  static const Color brand = Color(0xFF00544D);

  /// Semantic colour for income (Cashew light; dark uses [AppFinanceColors]).
  static const Color income = Color(0xFF59A849);

  /// Semantic colour for expense (Cashew light; dark uses [AppFinanceColors]).
  static const Color expense = Color(0xFFCA5A5A);

  /// Background fill for the green history-count badge.
  static const Color historyBadge = Color(0xFF2E7D32);

  // ── Recurring accent micro-surfaces ──────────────────────────────────────

  /// Light teal accent used for option cards, audio attachment cards, and
  /// segmented-toggle container backgrounds. In a future theme builder this
  /// will be computed as a very-light tint of the seed colour.
  static const Color surfaceAccent = Color(0xFFE8F6FF);

  /// Dark teal used for text and icons placed on [surfaceAccent].
  static const Color onSurfaceAccent = Color(0xFF004D4D);

  // ── Desktop shell colours ─────────────────────────────────────────────────

  static const Color desktopScaffold = Color(0xFFEAF7FF);
  static const Color desktopContent = Color(0xFFF5FBFF);
  static const Color sidebarGradientTop = Color(0xFFDDF4FF);
  static const Color sidebarGradientBottom = Color(0xFFCDEFFF);
}
