import "dart:async";

import "package:flutter/material.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

enum AppNotificationType { success, error, warning, info }

OverlayEntry? _currentNotification;

void showSuccess(
  BuildContext context,
  String message, {
  String? title,
  Duration duration = AppNotificationTokens.durationNormal,
}) {
  showAppNotification(
    context,
    title: title ?? context.l10n.notificationSuccessTitle,
    message: message,
    type: AppNotificationType.success,
    duration: duration,
  );
}

void showError(
  BuildContext context,
  String message, {
  String? title,
  Duration duration = AppNotificationTokens.durationLong,
}) {
  showAppNotification(
    context,
    title: title ?? context.l10n.notificationErrorTitle,
    message: message,
    type: AppNotificationType.error,
    duration: duration,
  );
}

void showWarning(
  BuildContext context,
  String message, {
  String? title,
  Duration duration = AppNotificationTokens.durationLong,
}) {
  showAppNotification(
    context,
    title: title ?? context.l10n.notificationWarningTitle,
    message: message,
    type: AppNotificationType.warning,
    duration: duration,
  );
}

void showInfo(
  BuildContext context,
  String message, {
  String? title,
  Duration duration = AppNotificationTokens.durationNormal,
}) {
  showAppNotification(
    context,
    title: title ?? context.l10n.notificationInfoTitle,
    message: message,
    type: AppNotificationType.info,
    duration: duration,
  );
}

void showAppNotification(
  BuildContext context, {
  required String title,
  required String message,
  AppNotificationType type = AppNotificationType.info,
  Duration duration = AppNotificationTokens.durationNormal,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  hideAppNotification();
  final entry = OverlayEntry(
    builder: (context) => _AppNotificationOverlay(
      title: title,
      message: message,
      type: type,
      duration: duration,
      onClose: hideAppNotification,
    ),
  );

  _currentNotification = entry;
  overlay.insert(entry);
}

void hideAppNotification() {
  _currentNotification?.remove();
  _currentNotification = null;
}

class _AppNotificationOverlay extends StatefulWidget {
  const _AppNotificationOverlay({
    required this.title,
    required this.message,
    required this.type,
    required this.duration,
    required this.onClose,
  });

  final String title;
  final String message;
  final AppNotificationType type;
  final Duration duration;
  final VoidCallback onClose;

  @override
  State<_AppNotificationOverlay> createState() =>
      _AppNotificationOverlayState();
}

class _AppNotificationOverlayState extends State<_AppNotificationOverlay> {
  Timer? _timer;
  var _visible = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, widget.onClose);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: AppNotificationTokens.topMargin),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final horizontal = AppNotificationTokens.horizontalMargin(
                width,
                AppBreakpoints.tablet,
              );
              final radius = AppNotificationTokens.radius(
                width,
                AppBreakpoints.tablet,
              );
              final padding = AppNotificationTokens.padding(
                width,
                AppBreakpoints.tablet,
              );
              final closeButtonSize = AppNotificationTokens.closeButtonSizeFor(
                width,
              );

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontal),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppNotificationTokens.maxWidth,
                    ),
                    child: AnimatedSlide(
                      duration: AppDurations.fast,
                      curve: Curves.easeOutCubic,
                      offset: _visible ? Offset.zero : const Offset(0, -0.2),
                      child: AnimatedOpacity(
                        duration: AppDurations.fast,
                        curve: Curves.easeOutCubic,
                        opacity: _visible ? 1 : 0,
                        child: Material(
                          color: Colors.transparent,
                          child: _AppNotificationCard(
                            title: widget.title,
                            message: widget.message,
                            type: widget.type,
                            radius: radius,
                            padding: padding,
                            closeButtonSize: closeButtonSize,
                            onClose: widget.onClose,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AppNotificationCard extends StatelessWidget {
  const _AppNotificationCard({
    required this.title,
    required this.message,
    required this.type,
    required this.radius,
    required this.padding,
    required this.closeButtonSize,
    required this.onClose,
  });

  final String title;
  final String message;
  final AppNotificationType type;
  final double radius;
  final EdgeInsets padding;
  final double closeButtonSize;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = _NotificationTone.from(context, type);

    return DecoratedBox(
      key: const ValueKey("app-notification-card"),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: tone.border),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(
              alpha: AppNotificationTokens.shadowAlpha,
            ),
            blurRadius: AppNotificationTokens.shadowBlur,
            offset: AppNotificationTokens.shadowOffset,
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: AppNotificationTokens.iconBoxSize,
              height: AppNotificationTokens.iconBoxSize,
              decoration: BoxDecoration(
                color: tone.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                tone.icon,
                color: tone.foreground,
                size: AppNotificationTokens.iconSize,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: AppNotificationTokens.titleMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: AppTypography.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    message,
                    maxLines: AppNotificationTokens.messageMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            SizedBox.square(
              dimension: closeButtonSize,
              child: IconButton(
                tooltip: context.l10n.close,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                onPressed: onClose,
                icon: Icon(Icons.close_rounded, color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTone {
  const _NotificationTone({
    required this.icon,
    required this.foreground,
    required this.background,
    required this.border,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
  final Color border;

  static _NotificationTone from(
    BuildContext context,
    AppNotificationType type,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (type) {
      AppNotificationType.success => AppColors.success,
      AppNotificationType.error => scheme.error,
      AppNotificationType.warning => AppColors.warning,
      AppNotificationType.info => AppColors.info,
    };
    final icon = switch (type) {
      AppNotificationType.success => Icons.check_circle_rounded,
      AppNotificationType.error => Icons.error_rounded,
      AppNotificationType.warning => Icons.warning_rounded,
      AppNotificationType.info => Icons.info_rounded,
    };

    return _NotificationTone(
      icon: icon,
      foreground: color,
      background: color.withValues(
        alpha: AppNotificationTokens.toneBackgroundAlpha,
      ),
      border: color.withValues(alpha: AppNotificationTokens.toneBorderAlpha),
    );
  }
}
