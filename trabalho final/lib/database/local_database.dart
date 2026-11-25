import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Abre (e cria, na primeira vez) o banco SQLite do aparelho.
class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  static const String nomeArquivo = 'cineboxd.db';
  static const String tabelaRegistros = 'registros';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _abrir();
    return _db!;
  }

  Future<Database> _abrir() async {
    final caminho = join(await getDatabasesPath(), nomeArquivo);
    return openDatabase(
      caminho,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tabelaRegistros (
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            remoteId TEXT,
            titulo TEXT NOT NULL,
            descricao TEXT,
            nota INTEGER NOT NULL DEFAULT 0,
            tmdbId INTEGER,
            posterPath TEXT,
            dataEvento INTEGER NOT NULL,
            criadoEm INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL,
            latitude REAL,
            longitude REAL,
            fotoBase64 TEXT,
            synced INTEGER NOT NULL DEFAULT 0,
            deletedAt INTEGER
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_registros_user ON $tabelaRegistros(userId)',
        );
      },
    );
  }
}
