import 'package:sqflite/sqflite.dart';
import '../../../core/domain/failure.dart';
import '../domain/profile.dart';

class SqliteProfileRepository implements ProfileRepository {
  SqliteProfileRepository(this.db);
  final Database db;
  @override
  Future<Profile?> getProfile() async {
    final rows = await db.query('settings');
    if (rows.isEmpty) return null;
    return Profile(
      store: rows.first['store'] as String,
      responsible: rows.first['responsible'] as String,
      currency: rows.first['currency'] as String,
    );
  }

  @override
  Future<void> saveProfile(Profile profile) async {
    if (profile.store.trim().isEmpty || profile.responsible.trim().isEmpty) {
      throw const AppFailure(
        'Escribe el nombre de la tienda y del responsable.',
      );
    }
    if (!['GTQ', 'USD', 'MXN', 'EUR'].contains(profile.currency)) {
      throw const AppFailure('Selecciona una moneda disponible.');
    }
    await db.insert('settings', {
      'id': 1,
      'store': profile.store.trim(),
      'responsible': profile.responsible.trim(),
      'currency': profile.currency,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
