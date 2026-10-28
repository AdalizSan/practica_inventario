import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ambar_inventario/core/data/local_database.dart';
import 'package:ambar_inventario/core/domain/failure.dart';
import 'package:ambar_inventario/features/products/domain/product.dart';
import 'package:ambar_inventario/features/products/data/sqlite_product_repository.dart';
import 'package:ambar_inventario/features/inventory/domain/movement.dart';
import 'package:ambar_inventario/features/inventory/data/sqlite_inventory_repository.dart';
import 'package:ambar_inventario/features/reports/domain/inventory_report.dart';
import 'package:ambar_inventario/features/scanner/domain/resolve_code.dart';

Product sample({String id = 'p1', String code = 'TEST-001', String name = 'Café', int stock = 0, bool active = true}) => Product(id: id, code: code, name: name, description: 'Producto de prueba', category: 'Despensa', purchaseCents: 1250, saleCents: 1800, minimum: 5, stock: stock, active: active);
MovementRequest request(MovementType type, int quantity, {String reason = 'Prueba', String responsible = 'Ana'}) => MovementRequest(productId: 'p1', type: type, quantity: quantity, reason: reason, responsible: responsible);

void main() {
  sqfliteFfiInit();
  late Database db;
  late SqliteProductRepository products;
  late SqliteInventoryRepository inventory;
  setUp(() async {
    db = await LocalDatabase.open(factory: databaseFactoryFfi, databasePath: inMemoryDatabasePath);
    products = SqliteProductRepository(db);
    inventory = SqliteInventoryRepository(db);
  });
  tearDown(() async => db.close());

  test('aceptación: 20 - 16 = 4, rechaza 5, ajuste a 3 y CSV', () async {
    await products.save(sample(), initialStock: 0, responsible: 'Ana');
    await inventory.record(request(MovementType.entry, 20));
    final scanned = ResolveCode()('TEST-001', await products.getProducts());
    expect(scanned.stock, 20);
    await inventory.record(request(MovementType.exit, 16));
    final low = (await products.getProducts()).single;
    expect(low.stock, 4);
    expect(low.lowStock, true);
    await expectLater(inventory.record(request(MovementType.exit, 5)), throwsA(isA<AppFailure>()));
    expect((await products.getProducts()).single.stock, 4);
    expect((await inventory.getMovements()).length, 2);
    await inventory.record(request(MovementType.adjustment, 3, reason: 'Conteo físico: diferencia de una unidad'));
    final report = InventoryReport(await products.getProducts(), await inventory.getMovements());
    expect(report.units, 3);
    expect(report.value, 3750);
    expect(report.movements.first.before, 4);
    expect(report.movements.first.after, 3);
    expect(report.csv('GTQ'), contains('"3","5","12.50","18.00","37.50","GTQ"'));
  });

  test('existencias iniciales generan movimiento y rechazan duplicados', () async {
    await products.save(sample(), initialStock: 20, responsible: 'Ana');
    expect((await inventory.getMovements()).single.reason, 'Existencias iniciales');
    await expectLater(products.save(sample(id: 'p2'), initialStock: 3, responsible: 'Ana'), throwsA(isA<AppFailure>()));
    expect((await products.getProducts()).length, 1);
    expect((await inventory.getMovements()).length, 1);
  });

  test('editar datos nunca cambia existencias ni historial', () async {
    await products.save(sample(), initialStock: 7, responsible: 'Ana');
    await products.save(sample(name: 'Nuevo nombre', stock: 999), initialStock: 999, responsible: 'Ana');
    expect((await products.getProducts()).single.stock, 7);
    expect((await inventory.getMovements()).single.productName, 'Café');
  });

  test('desactivación bloquea movimientos y conserva la referencia', () async {
    await products.save(sample(), initialStock: 3, responsible: 'Ana');
    await products.setActive('p1', false);
    await expectLater(inventory.record(request(MovementType.entry, 1)), throwsA(isA<AppFailure>()));
    await expectLater(db.delete('products', where: 'id = ?', whereArgs: ['p1']), throwsA(isA<DatabaseException>()));
    expect((await products.getProducts()).single.stock, 3);
    await products.setActive('p1', true);
    await inventory.record(request(MovementType.entry, 2));
    expect((await products.getProducts()).single.stock, 5);
  });

  test('movimientos confirmados no se editan ni eliminan', () async {
    await products.save(sample(), initialStock: 1, responsible: 'Ana');
    await expectLater(db.update('movements', {'reason': 'Alterado'}), throwsA(isA<DatabaseException>()));
    await expectLater(db.delete('movements'), throwsA(isA<DatabaseException>()));
    expect((await inventory.getMovements()).length, 1);
  });

  test('fallo de almacenamiento revierte movimiento y existencias', () async {
    await products.save(sample(), initialStock: 2, responsible: 'Ana');
    await db.execute("CREATE TRIGGER fail_stock BEFORE UPDATE OF stock ON products BEGIN SELECT RAISE(ABORT, 'fallo simulado'); END");
    await expectLater(inventory.record(request(MovementType.entry, 5)), throwsA(isA<DatabaseException>()));
    expect((await products.getProducts()).single.stock, 2);
    expect((await inventory.getMovements()).length, 1);
  });

  test('dos salidas simultáneas no producen stock negativo', () async {
    await products.save(sample(), initialStock: 5, responsible: 'Ana');
    final results = await Future.wait(List.generate(2, (_) async {
      try { await inventory.record(request(MovementType.exit, 4)); return true; } on AppFailure { return false; }
    }));
    expect(results.where((r) => r).length, 1);
    expect((await products.getProducts()).single.stock, 1);
    expect((await inventory.getMovements()).length, 2);
  });

  test('cantidades, justificación, responsable y límite', () {
    final calculate = CalculateStock();
    for (final type in [MovementType.entry, MovementType.exit]) {
      expect(() => calculate(sample(stock: 20), request(type, 0)), throwsA(isA<AppFailure>()));
      expect(() => calculate(sample(stock: 20), request(type, -1)), throwsA(isA<AppFailure>()));
    }
    expect(calculate(sample(stock: 20), request(MovementType.adjustment, 0)), 0);
    expect(() => calculate(sample(), request(MovementType.adjustment, 3, reason: ' ')), throwsA(isA<AppFailure>()));
    expect(() => calculate(sample(), request(MovementType.entry, 3, responsible: ' ')), throwsA(isA<AppFailure>()));
    expect(() => calculate(sample(stock: 1000000000), request(MovementType.entry, 1)), throwsA(isA<AppFailure>()));
  });

  test('código inexistente y códigos normalizados', () {
    expect(ResolveCode()(' test-001 ', [sample()]).id, 'p1');
    expect(() => ResolveCode()('DESCONOCIDO', [sample()]), throwsA(isA<AppFailure>()));
    expect(() => ValidateProduct()(sample(code: 'ñ inválido')), throwsA(isA<AppFailure>()));
  });

  test('CSV escapa comillas, comas y fórmulas', () {
    final report = InventoryReport([sample(name: '=SUM(1,2) "texto"', stock: 2)], []);
    expect(report.csv('GTQ'), contains('"\'=SUM(1,2) ""texto"""'));
    expect(report.csv('GTQ').startsWith('\uFEFF'), true);
  });

  test('filtros por producto, tipo y rango inclusivo', () async {
    await products.save(sample(), initialStock: 8, responsible: 'Ana');
    await inventory.record(request(MovementType.exit, 2));
    final report = InventoryReport(await products.getProducts(), await inventory.getMovements());
    final now = DateTime.now();
    expect(report.filter(productId: 'p1', type: MovementType.exit, from: DateTime(now.year, now.month, now.day), to: now).length, 1);
    expect(report.filter(productId: 'missing'), isEmpty);
    expect(report.filter(to: now.subtract(const Duration(days: 1))), isEmpty);
  });

  test('persistencia al cerrar y abrir archivo SQLite', () async {
    final dir = await Directory.systemTemp.createTemp('ambar-test-');
    final file = '${dir.path}/test.db';
    final first = await LocalDatabase.open(factory: databaseFactoryFfi, databasePath: file);
    await SqliteProductRepository(first).save(sample(), initialStock: 9, responsible: 'Ana');
    await first.close();
    final reopened = await LocalDatabase.open(factory: databaseFactoryFfi, databasePath: file);
    expect((await SqliteProductRepository(reopened).getProducts()).single.stock, 9);
    expect((await SqliteInventoryRepository(reopened).getMovements()).single.after, 9);
    await reopened.close();
    await dir.delete(recursive: true);
  });
}
