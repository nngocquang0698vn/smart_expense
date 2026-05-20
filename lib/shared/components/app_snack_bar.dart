import "package:awesome_snackbar_content/awesome_snackbar_content.dart";
import "package:flutter/material.dart";

enum AppSnackBarType { success, error, warning, info }

extension _AppSnackBarTypeX on AppSnackBarType {
  ContentType get contentType {
    return switch (this) {
      AppSnackBarType.success => ContentType.success,
      AppSnackBarType.error => ContentType.failure,
      AppSnackBarType.warning => ContentType.warning,
      AppSnackBarType.info => ContentType.help,
    };
  }
}

void showAppSnackBar(
  BuildContext context, {
  required String title,
  required String message,
  AppSnackBarType type = AppSnackBarType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final snackBar = SnackBar(
    elevation: 0,
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,
    duration: duration,
    content: AwesomeSnackbarContent(
      title: title,
      message: message,
      contentType: type.contentType,
    ),
  );

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
}
