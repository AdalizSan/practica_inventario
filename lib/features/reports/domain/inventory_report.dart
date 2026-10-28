import '../../products/domain/product.dart';
import '../../inventory/domain/movement.dart';

class InventoryReport {
  const InventoryReport(this.products, this.movements);
  final List<Product> products;
  final List<StockMovement> movements;
  List<Product> get active =>
      products.where((p) => p.active).toList(growable: false);
  List<Product> get alerts =>
      active.where((p) => p.lowStock).toList(growable: false);
  int get units => active.fold(0, (sum, p) => sum + p.stock);
  int get value => active.fold(0, (sum, p) => sum + p.valuation);
  int get dormantValue =>
      products.where((p) => !p.active).fold(0, (sum, p) => sum + p.valuation);

  List<StockMovement> filter({
    String? productId,
    MovementType? type,
    DateTime? from,
    DateTime? to,
  }) => movements
      .where(
        (m) =>
            (productId == null || m.productId == productId) &&
            (type == null || m.type == type) &&
            (from == null || !m.date.isBefore(from)) &&
            (to == null ||
                m.date.isBefore(DateTime(to.year, to.month, to.day + 1))),
      )
      .toList(growable: false);

  String csv(String currency) {
    String cell(Object value) {
      var text = value.toString();
      if (RegExp(r'^[=+@\-\t\r]').hasMatch(text)) text = "'$text";
      return '"${text.replaceAll('"', '""')}"';
    }

    final rows = <List<Object>>[
      [
        'Código',
        'Nombre',
        'Categoría',
        'Estado',
        'Existencias',
        'Stock mínimo',
        'Compra',
        'Venta',
        'Valor estimado',
        'Moneda',
      ],
      ...products.map(
        (p) => [
          p.code,
          p.name,
          p.category,
          p.active ? 'Activo' : 'Inactivo',
          p.stock,
          p.minimum,
          (p.purchaseCents / 100).toStringAsFixed(2),
          (p.saleCents / 100).toStringAsFixed(2),
          (p.valuation / 100).toStringAsFixed(2),
          currency,
        ],
      ),
    ];
    return '\uFEFF${rows.map((r) => r.map(cell).join(',')).join('\r\n')}\r\n';
  }
}
