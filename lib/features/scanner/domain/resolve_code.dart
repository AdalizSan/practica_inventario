import '../../../core/domain/failure.dart';
import '../../products/domain/product.dart';

class ResolveCode {
  Product call(String raw, List<Product> products) {
    final code = raw.trim().toUpperCase();
    if (code.isEmpty) throw const AppFailure('El código está vacío.');
    for (final product in products) {
      if (product.code == code) return product;
    }
    throw const AppFailure(
      'Código no registrado. Busca por nombre o registra el producto.',
    );
  }
}
