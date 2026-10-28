import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ambar_inventario/main.dart';
import 'package:ambar_inventario/core/data/local_database.dart';
import 'package:ambar_inventario/core/data/demo_loader.dart';
import 'package:ambar_inventario/core/presentation/app_controller.dart';
import 'package:ambar_inventario/features/products/data/sqlite_product_repository.dart';
import 'package:ambar_inventario/features/inventory/data/sqlite_inventory_repository.dart';
import 'package:ambar_inventario/features/settings/data/sqlite_profile_repository.dart';
import 'package:ambar_inventario/features/settings/domain/profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final size in [const Size(320, 568), const Size(390, 844), const Size(768, 1024), const Size(1360, 1000)]) {
    testWidgets('navegación y diseño a ${size.width.toInt()} px', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late Database db;
      final controller = await tester.runAsync(() async {
        sqfliteFfiInit();
        await initializeDateFormatting('es');
        db = await LocalDatabase.open(factory: databaseFactoryFfi, databasePath: inMemoryDatabasePath);
        final vm = AppController(productsRepository: SqliteProductRepository(db), inventoryRepository: SqliteInventoryRepository(db), profileRepository: SqliteProfileRepository(db), loadDemo: DemoLoader(db).load);
        await vm.setup(const Profile(store: 'Tienda de prueba', responsible: 'Ana', currency: 'GTQ'), true);
        await vm.initialize();
        return vm;
      });
      await tester.pumpWidget(AmbarApp(controller: controller!));
      await tester.pumpAndSettle();
      expect(find.text('Todo bajo control.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('nav_1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('product_search')), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('product_search')), 'AB-002');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Miel pura · 500 ml'), 160, scrollable: find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first);
      expect(find.text('Miel pura · 500 ml'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Miel pura · 500 ml'));
      await tester.pumpAndSettle();
      expect(find.text('Detalle del producto'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav_3')));
      await tester.pumpAndSettle();
      expect(find.text('Cada unidad tiene una historia'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await tester.runAsync(db.close);
    });
  }
}
