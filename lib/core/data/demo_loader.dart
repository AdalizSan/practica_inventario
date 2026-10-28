import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../features/products/domain/product.dart';
import '../../features/products/data/product_mapper.dart';
import '../../features/inventory/data/sqlite_inventory_repository.dart';
import '../../features/inventory/domain/movement.dart';

class DemoLoader {
  DemoLoader(this.db);
  final Database db;
  Future<void> load(String responsible) async {
    final data =
        jsonDecode(await rootBundle.loadString('assets/data/demo.json'))
            as List;
    await db.transaction((tx) async {
      if (Sqflite.firstIntValue(
            await tx.rawQuery('SELECT COUNT(*) FROM products'),
          ) !=
          0) {
        return;
      }
      for (final item in data) {
        final p = Product(
          id: const Uuid().v4(),
          code: item['code'],
          name: item['name'],
          description: item['description'],
          category: item['category'],
          purchaseCents: item['purchase'],
          saleCents: item['sale'],
          minimum: item['minimum'],
        );
        ValidateProduct()(p);
        await tx.insert('categories', {
          'name': p.category,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        await tx.insert('products', ProductMapper.toRow(p));
        if (item['stock'] > 0) {
          await SqliteInventoryRepository.append(
            tx,
            p,
            MovementRequest(
              productId: p.id,
              type: MovementType.entry,
              quantity: item['stock'],
              reason: 'Existencias iniciales · demostración',
              responsible: responsible,
            ),
          );
        }
      }
    });
  }
}
