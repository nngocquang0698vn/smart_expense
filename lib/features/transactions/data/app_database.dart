import "package:flutter/foundation.dart";
import "package:path/path.dart" as p;
import "package:path_provider/path_provider.dart";
import "package:sembast/sembast_io.dart";
import "package:sembast_web/sembast_web.dart";

class AppDatabase {
  AppDatabase._();

  static Database? _instance;

  static Future<Database> open() async {
    if (_instance != null) return _instance!;
    if (kIsWeb) {
      _instance = await databaseFactoryWeb.openDatabase("smart_expense.db");
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = p.join(dir.path, "smart_expense.db");
      _instance = await databaseFactoryIo.openDatabase(filePath);
    }
    return _instance!;
  }
}
