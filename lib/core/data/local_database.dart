import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class LocalDatabase {
  static Future<Database> open({
    DatabaseFactory? factory,
    String? databasePath,
  }) async {
    final selected = factory ?? _factory();
    final location =
        databasePath ??
        (kIsWeb
            ? 'ambar.db'
            : path.join(await selected.getDatabasesPath(), 'ambar.db'));
    return selected.openDatabase(
      location,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE categories (name TEXT PRIMARY KEY COLLATE NOCASE)',
          );
          await db.execute(
            'CREATE TABLE products (id TEXT PRIMARY KEY, code TEXT NOT NULL UNIQUE COLLATE NOCASE, name TEXT NOT NULL, description TEXT NOT NULL, category TEXT NOT NULL REFERENCES categories(name), purchase_cents INTEGER NOT NULL CHECK(purchase_cents >= 0), sale_cents INTEGER NOT NULL CHECK(sale_cents >= 0), minimum INTEGER NOT NULL CHECK(minimum >= 0), stock INTEGER NOT NULL DEFAULT 0 CHECK(stock >= 0), active INTEGER NOT NULL DEFAULT 1 CHECK(active IN (0,1)), photo TEXT)',
          );
          await db.execute(
            "CREATE TABLE movements (id TEXT PRIMARY KEY, product_id TEXT NOT NULL REFERENCES products(id) ON DELETE RESTRICT, product_name TEXT NOT NULL, product_code TEXT NOT NULL, type TEXT NOT NULL CHECK(type IN ('entry','exit','adjustment')), quantity INTEGER NOT NULL CHECK(quantity >= 0), stock_before INTEGER NOT NULL CHECK(stock_before >= 0), stock_after INTEGER NOT NULL CHECK(stock_after >= 0), reason TEXT NOT NULL, responsible TEXT NOT NULL, occurred_at TEXT NOT NULL)",
          );
          await db.execute(
            'CREATE INDEX movements_product_date ON movements(product_id, occurred_at)',
          );
          await db.execute(
            "CREATE TRIGGER immutable_movements_update BEFORE UPDATE ON movements BEGIN SELECT RAISE(ABORT, 'Los movimientos son inmutables'); END",
          );
          await db.execute(
            "CREATE TRIGGER immutable_movements_delete BEFORE DELETE ON movements BEGIN SELECT RAISE(ABORT, 'Los movimientos son inmutables'); END",
          );
          await db.execute(
            'CREATE TABLE settings (id INTEGER PRIMARY KEY CHECK(id = 1), store TEXT NOT NULL, responsible TEXT NOT NULL, currency TEXT NOT NULL)',
          );
        },
      ),
    );
  }

  static DatabaseFactory _factory() {
    if (kIsWeb) return databaseFactoryFfiWeb;
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      ffi.sqfliteFfiInit();
      return ffi.databaseFactoryFfi;
    }
    return databaseFactory;
  }
}
