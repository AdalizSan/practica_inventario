import '../domain/product.dart';

class ProductMapper {
  static Product fromRow(Map<String, Object?> row) => Product(
    id: row['id'] as String,
    code: row['code'] as String,
    name: row['name'] as String,
    description: row['description'] as String,
    category: row['category'] as String,
    purchaseCents: row['purchase_cents'] as int,
    saleCents: row['sale_cents'] as int,
    minimum: row['minimum'] as int,
    stock: row['stock'] as int,
    active: row['active'] == 1,
    photo: row['photo'] as String?,
  );
  static Map<String, Object?> toRow(Product p) => {
    'id': p.id,
    'code': p.code,
    'name': p.name,
    'description': p.description,
    'category': p.category,
    'purchase_cents': p.purchaseCents,
    'sale_cents': p.saleCents,
    'minimum': p.minimum,
    'stock': p.stock,
    'active': p.active ? 1 : 0,
    'photo': p.photo,
  };
}
