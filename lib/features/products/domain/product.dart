import '../../../core/domain/failure.dart';

class Product {
  const Product({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.category,
    required this.purchaseCents,
    required this.saleCents,
    required this.minimum,
    this.stock = 0,
    this.active = true,
    this.photo,
  });
  final String id, code, name, description, category;
  final int purchaseCents, saleCents, minimum, stock;
  final bool active;
  final String? photo;
  bool get lowStock => active && stock <= minimum;
  int get valuation => stock * purchaseCents;
  Product copyWith({int? stock, bool? active}) => Product(
    id: id,
    code: code,
    name: name,
    description: description,
    category: category,
    purchaseCents: purchaseCents,
    saleCents: saleCents,
    minimum: minimum,
    stock: stock ?? this.stock,
    active: active ?? this.active,
    photo: photo,
  );
}

class ValidateProduct {
  void call(Product product) {
    if (!RegExp(r'^[A-Z0-9][A-Z0-9._/-]{0,47}$').hasMatch(product.code)) {
      throw const AppFailure(
        'Usa un código de 1 a 48 caracteres: letras, números, punto, guion o barra.',
      );
    }
    if (product.name.trim().isEmpty || product.name.length > 100) {
      throw const AppFailure('Escribe un nombre de hasta 100 caracteres.');
    }
    if (product.category.trim().isEmpty || product.category.length > 50) {
      throw const AppFailure('Escribe una categoría de hasta 50 caracteres.');
    }
    if (product.purchaseCents < 0 ||
        product.saleCents < 0 ||
        product.purchaseCents > 999999999 ||
        product.saleCents > 999999999) {
      throw const AppFailure('Los precios deben estar entre 0 y 9,999,999.99.');
    }
    if (product.minimum < 0 || product.minimum > 1000000000) {
      throw const AppFailure(
        'El stock mínimo debe estar entre 0 y 1,000,000,000.',
      );
    }
  }
}

abstract interface class ProductRepository {
  Future<List<Product>> getProducts();
  Future<void> save(
    Product product, {
    required int initialStock,
    required String responsible,
  });
  Future<void> setActive(String id, bool active);
}
