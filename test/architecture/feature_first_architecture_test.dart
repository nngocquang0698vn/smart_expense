import "dart:io";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("feature-first architecture does not keep legacy scaffolding", () {
    expect(Directory("lib/data").existsSync(), isFalse);
    expect(File("lib/app/repo_scope.dart").existsSync(), isFalse);
    expect(File("lib/app/smart_expense_root.dart").existsSync(), isFalse);
    expect(Directory("lib/core/widgets").existsSync(), isFalse);
    expect(Directory("lib/core/theme").existsSync(), isFalse);
    expect(Directory("lib/core/tokens").existsSync(), isFalse);
    expect(Directory("lib/core/pwa").existsSync(), isFalse);
    expect(File("lib/app/localization/app_strings.dart").existsSync(), isFalse);

    final gitkeepFiles = Directory("lib/features")
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.uri.pathSegments.last == ".gitkeep")
        .map((file) => file.path)
        .toList();

    expect(gitkeepFiles, isEmpty);
  });

  test("features tree only contains implemented features", () {
    final featureNames = Directory("lib/features")
        .listSync()
        .whereType<Directory>()
        .map((directory) => directory.uri.pathSegments.reversed.skip(1).first)
        .toSet();

    expect(
      featureNames,
      equals({
        "categories",
        "dashboard",
        "onboarding",
        "reports",
        "settings",
        "transactions",
      }),
    );
  });

  test("test tree mirrors current architecture names", () {
    expect(Directory("test/core/widgets").existsSync(), isFalse);
    expect(Directory("test/core/pwa").existsSync(), isFalse);
    expect(Directory("test/data").existsSync(), isFalse);
    expect(Directory("test/features/pending").existsSync(), isFalse);
    expect(Directory("test/features/home").existsSync(), isFalse);
    expect(Directory("test/widgets").existsSync(), isFalse);
    expect(Directory("test/fakes").existsSync(), isFalse);
  });

  test("app supports Vietnamese localization only", () {
    expect(Directory("lib/app/localization/l10n").existsSync(), isFalse);
    expect(File("lib/app/localization/l10n/app_en.arb").existsSync(), isFalse);
    expect(
      AppLocalizations.supportedLocales.map((locale) => locale.languageCode),
      equals(["vi"]),
    );
  });

  test("date filter data objects do not own localized labels", () {
    expect(
      File("lib/features/transactions/data/date_filter.dart").existsSync(),
      isFalse,
    );
    final source = File(
      "lib/features/transactions/domain/entities/date_filter.dart",
    ).readAsStringSync();

    expect(source, isNot(contains("String label(")));
    expect(source, isNot(contains("labelVi")));
  });

  test("transactions domain does not depend on Flutter or data models", () {
    final offenders = <String>[];
    final forbidden = RegExp(
      r'package:flutter|features/transactions/data|CategoryModel|TransactionModel|extends ChangeNotifier|DateTimeRange',
    );

    for (final file in Directory(
      "lib/features/transactions/domain",
    ).listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith(".dart")) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (forbidden.hasMatch(lines[i])) {
          offenders.add("${file.path}:${i + 1}: ${lines[i].trim()}");
        }
      }
    }

    expect(offenders, isEmpty);
  });

  test("dart files use package imports for project files", () {
    final offenders = <String>[];
    final importOrExport = RegExp(r'^\s*(import|export)\s+"([^"]+\.dart)"');

    for (final root in [Directory("lib"), Directory("test")]) {
      for (final file in root.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith(".dart")) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final match = importOrExport.firstMatch(lines[i]);
          if (match == null) continue;
          final uri = match.group(2)!;
          final isSdkOrPackage =
              uri.startsWith("dart:") ||
              uri.startsWith("package:") ||
              uri.startsWith("flutter:");
          if (!isSdkOrPackage) {
            offenders.add("${file.path}:${i + 1}: $uri");
          }
        }
      }
    }

    expect(offenders, isEmpty);
  });
}
