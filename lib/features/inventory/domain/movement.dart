import '../../../core/domain/failure.dart';
import '../../products/domain/product.dart';

enum MovementType {
  entry('Entrada'),
  exit('Salida'),
  adjustment('Ajuste');

  const MovementType(this.label);
  final String label;
}

class StockMovement {
  const StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.type,
    required this.quantity,
    required this.before,
    required this.after,
    required this.reason,
    required this.responsible,
    required this.date,
  });
  final String id, productId, productName, productCode, reason, responsible;
  final MovementType type;
  final int quantity, before, after;
  final DateTime date;
  int get delta => after - before;
}

class MovementRequest {
  const MovementRequest({
    required this.productId,
    required this.type,
    required this.quantity,
    required this.reason,
    required this.responsible,
  });
  final String productId, reason, responsible;
  final MovementType type;
  final int quantity;
}

class CalculateStock {
  int call(Product product, MovementRequest request) {
    if (!product.active) {
      throw const AppFailure(
        'Reactiva el producto antes de registrar un movimiento.',
      );
    }
    if (request.productId != product.id) {
      throw const AppFailure('El movimiento no corresponde al producto.');
    }
    if (request.responsible.trim().isEmpty) {
      throw const AppFailure('Configura el nombre del responsable.');
    }
    if (request.reason.trim().isEmpty) {
      throw const AppFailure(
        'Escribe el motivo o la justificación del movimiento.',
      );
    }
    if (request.reason.length > 500) {
      throw const AppFailure('El motivo no puede superar 500 caracteres.');
    }
    if (request.quantity < 0 ||
        request.quantity > 1000000000 ||
        (request.type != MovementType.adjustment && request.quantity == 0)) {
      throw const AppFailure(
        'La cantidad debe ser positiva. Un conteo físico sí puede ser cero.',
      );
    }
    final next = switch (request.type) {
      MovementType.entry => product.stock + request.quantity,
      MovementType.exit => product.stock - request.quantity,
      MovementType.adjustment => request.quantity,
    };
    if (next < 0) {
      throw AppFailure(
        'Stock insuficiente. Solo hay ${product.stock} unidades disponibles.',
      );
    }
    if (next > 1000000000) {
      throw const AppFailure(
        'La operación supera el máximo de existencias permitido.',
      );
    }
    return next;
  }
}

abstract interface class InventoryRepository {
  Future<void> record(MovementRequest request);
  Future<List<StockMovement>> getMovements();
}
