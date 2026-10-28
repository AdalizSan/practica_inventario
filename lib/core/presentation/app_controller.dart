import 'package:flutter/foundation.dart';
import '../domain/failure.dart';
import '../../features/products/domain/product.dart';
import '../../features/inventory/domain/movement.dart';
import '../../features/reports/domain/inventory_report.dart';
import '../../features/settings/domain/profile.dart';
import '../../features/scanner/domain/resolve_code.dart';

class AppController extends ChangeNotifier {
  AppController({
    required this.productsRepository,
    required this.inventoryRepository,
    required this.profileRepository,
    required this.loadDemo,
  });
  final ProductRepository productsRepository;
  final InventoryRepository inventoryRepository;
  final ProfileRepository profileRepository;
  final Future<void> Function(String responsible) loadDemo;
  List<Product> _products = [];
  List<StockMovement> _movements = [];
  Profile? profile;
  bool loading = true;
  bool busy = false;
  String? error;
  List<Product> get products => List.unmodifiable(_products);
  List<StockMovement> get movements => List.unmodifiable(_movements);
  InventoryReport get report => InventoryReport(products, movements);
  List<String> get categories =>
      (products.map((p) => p.category).toSet().toList()..sort());
  Product product(String id) => products.firstWhere((p) => p.id == id);
  Product resolve(String code) => ResolveCode()(code, products);

  Future<void> initialize() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _refresh();
    } catch (e) {
      error = friendly(e);
    }
    loading = false;
    notifyListeners();
  }

  Future<void> _refresh() async {
    final products = await productsRepository.getProducts();
    final movements = await inventoryRepository.getMovements();
    final settings = await profileRepository.getProfile();
    _products = products;
    _movements = movements;
    profile = settings;
  }

  Future<void> _mutate(Future<void> Function() action) async {
    if (busy) {
      throw const AppFailure('Espera a que termine la operación actual.');
    }
    busy = true;
    notifyListeners();
    try {
      await action();
      await _refresh();
    } catch (e) {
      throw AppFailure(friendly(e));
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> setup(Profile value, bool demo) => _mutate(() async {
    if (demo) await loadDemo(value.responsible);
    await profileRepository.saveProfile(value);
  });
  Future<void> saveProfile(Profile value) =>
      _mutate(() => profileRepository.saveProfile(value));
  Future<void> saveProduct(Product product, int initialStock) => _mutate(
    () => productsRepository.save(
      product,
      initialStock: initialStock,
      responsible: profile!.responsible,
    ),
  );
  Future<void> setActive(String id, bool active) =>
      _mutate(() => productsRepository.setActive(id, active));
  Future<void> record(MovementRequest request) =>
      _mutate(() => inventoryRepository.record(request));
  static String friendly(Object error) => error is AppFailure
      ? error.message
      : 'No se pudo completar la operación. Comprueba el espacio disponible e inténtalo de nuevo.';
}
