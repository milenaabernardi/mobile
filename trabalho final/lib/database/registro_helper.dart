import 'package:sqflite/sqflite.dart';
import '../models/registro_model.dart';
import 'local_database.dart';

/// CRUD do SQLite. Só este arquivo conhece o SQL da tabela de registros.
///
/// O banco local funciona como uma "fila": guarda o que ainda não foi enviado
/// para a nuvem (criações, edições e exclusões pendentes).
class RegistroHelper {
  static const String _tabela = LocalDatabase.tabelaRegistros;

  Future<Database> get _db => LocalDatabase.instance.database;

  // ---------- CREATE ----------
  Future<void> inserir(Registro r) async {
    final db = await _db;
    await db.insert(
      _tabela,
      r.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ---------- READ ----------
  Future<Registro?> buscarPorId(String id) async {
    final db = await _db;
    final rows = await db.query(_tabela, where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Registro.fromMap(rows.first);
  }

  /// Registros do usuário que o app deve mostrar (exclui os apagados).
  Future<List<Registro>> listarAtivos(String userId) async {
    final db = await _db;
    final rows = await db.query(
      _tabela,
      where: 'userId = ? AND deletedAt IS NULL',
      whereArgs: [userId],
      orderBy: 'dataEvento DESC',
    );
    return rows.map(Registro.fromMap).toList();
  }

  /// Criados ou editados que ainda não foram enviados.
  Future<List<Registro>> listarPendentes(String userId) async {
    final db = await _db;
    final rows = await db.query(
      _tabela,
      where: 'userId = ? AND synced = 0 AND deletedAt IS NULL',
      whereArgs: [userId],
      orderBy: 'updatedAt ASC',
    );
    return rows.map(Registro.fromMap).toList();
  }

  /// Exclusões feitas offline que ainda precisam ser replicadas na nuvem.
  Future<List<Registro>> listarExclusoesPendentes(String userId) async {
    final db = await _db;
    final rows = await db.query(
      _tabela,
      where: 'userId = ? AND deletedAt IS NOT NULL',
      whereArgs: [userId],
    );
    return rows.map(Registro.fromMap).toList();
  }

  /// Ids de tudo o que existe no banco local (inclui exclusões pendentes).
  Future<Set<String>> listarIds(String userId) async {
    final db = await _db;
    final rows = await db.query(
      _tabela,
      columns: ['id'],
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return rows.map((r) => r['id'] as String).toSet();
  }

  Future<int> contarPendentes(String userId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM $_tabela '
      'WHERE userId = ? AND (synced = 0 OR deletedAt IS NOT NULL)',
      [userId],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  // ---------- UPDATE ----------
  Future<int> atualizar(Registro r) async {
    final db = await _db;
    return db.update(_tabela, r.toMap(), where: 'id = ?', whereArgs: [r.id]);
  }

  Future<void> marcarSincronizado(String id) async {
    final db = await _db;
    await db.update(_tabela, {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // ---------- DELETE ----------
  Future<int> excluir(String id) async {
    final db = await _db;
    return db.delete(_tabela, where: 'id = ?', whereArgs: [id]);
  }
}
