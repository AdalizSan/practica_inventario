import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../core/domain/failure.dart';
import '../../products/data/product_mapper.dart';
import '../../products/domain/product.dart';
import '../domain/movement.dart';

class SqliteInventoryRepository implements InventoryRepository {
  SqliteInventoryRepository(this.db);
  final Database db;
  static Future<void> append(
    DatabaseExecutor tx,
    Product product,
    MovementRequest request,
  ) async {
    final next = CalculateStock()(product, request);
    await tx.insert('movements', {
      'id': const Uuid().v4(),
      'product_id': product.id,
      'product_name': product.name,
      'product_code': product.code,
      'type': request.type.name,
      'quantity': request.quantity,
      'stock_before': product.stock,
      'stock_after': next,
      'reason': request.reason.trim(),
      'responsible': request.responsible.trim(),
      'occurred_at': DateTime.now().toUtc().toIso8601String(),
    });
    await tx.update(
      'products',
      {'stock': next},
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  @override
  Future<void> record(MovementRequest request) => db.transaction((tx) async {
    final rows = await tx.query(
      'products',
      where: 'id = ?',
      whereArgs: [request.productId],
    );
    if (rows.isEmpty) throw const AppFailure('No se encontró el producto.');
    await append(tx, ProductMapper.fromRow(rows.single), request);
  });

  @override
  Future<List<StockMovement>> getMovements() async =>
      (await db.query('movements', orderBy: 'occurred_at DESC, rowid DESC'))
          .map(
            (r) => StockMovement(
              id: r['id'] as String,
              productId: r['product_id'] as String,
              productName: r['product_name'] as String,
              productCode: r['product_code'] as String,
              type: MovementType.values.byName(r['type'] as String),
              quantity: r['quantity'] as int,
              before: r['stock_before'] as int,
              after: r['stock_after'] as int,
              reason: r['reason'] as String,
              responsible: r['responsible'] as String,
              date: DateTime.parse(r['occurred_at'] as String).toLocal(),
            ),
          )
          .toList(growable: false);
}
