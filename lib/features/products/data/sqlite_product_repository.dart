import 'package:sqflite/sqflite.dart';
import '../../../core/domain/failure.dart';
import '../../inventory/data/sqlite_inventory_repository.dart';
import '../../inventory/domain/movement.dart';
import '../domain/product.dart';
import 'product_mapper.dart';

class SqliteProductRepository implements ProductRepository {
  SqliteProductRepository(this.db);
  final Database db;
  @override
  Future<List<Product>> getProducts() async => (await db.query(
    'products',
    orderBy: 'active DESC, name COLLATE NOCASE',
  )).map(ProductMapper.fromRow).toList(growable: false);
  @override
  Future<void> save(
    Product product, {
    required int initialStock,
    required String responsible,
  }) async {
    ValidateProduct()(product);
    if (initialStock < 0) {
      throw const AppFailure(
        'Las existencias iniciales no pueden ser negativas.',
      );
    }
    await db.transaction((tx) async {
      final duplicates = await tx.query(
        'products',
        columns: ['id'],
        where: 'code = ? AND id != ?',
        whereArgs: [product.code, product.id],
      );
      if (duplicates.isNotEmpty) {
        throw const AppFailure(
          'Este código ya pertenece a otro producto, incluso si está inactivo.',
        );
      }
      final existing = await tx.query(
        'products',
        where: 'id = ?',
        whereArgs: [product.id],
      );
      await tx.insert('categories', {
        'name': product.category,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      final row = ProductMapper.toRow(product);
      if (existing.isEmpty) {
        row['stock'] = 0;
        row['active'] = 1;
        await tx.insert('products', row);
        if (initialStock > 0) {
          await SqliteInventoryRepository.append(
            tx,
            product.copyWith(stock: 0, active: true),
            MovementRequest(
              productId: product.id,
              type: MovementType.entry,
              quantity: initialStock,
              reason: 'Existencias iniciales',
              responsible: responsible,
            ),
          );
        }
      } else {
        row.remove('stock');
        row.remove('active');
        row.remove('id');
        await tx.update(
          'products',
          row,
          where: 'id = ?',
          whereArgs: [product.id],
        );
      }
    });
  }

  @override
  Future<void> setActive(String id, bool active) async {
    final changed = await db.update(
      'products',
      {'active': active ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    if (changed == 0) {
      throw const AppFailure('El producto ya no está disponible.');
    }
  }
}
