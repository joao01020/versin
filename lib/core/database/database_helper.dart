import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  // ============================================================
  // DATABASE
  // ============================================================

  Future<
    Database
  >
  get database async {
    if (_database !=
        null) {
      return _database!;
    }

    _database = await _initDB(
      'versin_storage.db',
    );

    return _database!;
  }

  // ============================================================
  // INIT
  // ============================================================

  Future<
    Database
  >
  _initDB(
    String filePath,
  ) async {
    final dbPath = await getDatabasesPath();

    final path = join(
      dbPath,
      filePath,
    );

    debugPrint(
      '[DATABASE] Abrindo: $path',
    );

    return openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: _onOpen,
    );
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<
    void
  >
  _createDB(
    Database db,
    int version,
  ) async {
    // ==========================================================
    // RIMAS
    // ==========================================================

    await db.execute(
      '''
      CREATE TABLE offline_rhymes (
        id TEXT PRIMARY KEY,
        word TEXT,
        synced INTEGER
      )
      ''',
    );

    // ==========================================================
    // PROJETOS
    // ==========================================================

    await db.execute(
      '''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT,
        lyrics TEXT,
        bpm INTEGER,
        vibe TEXT,
        technique TEXT,
        synced INTEGER
      )
      ''',
    );

    // ==========================================================
    // PERFIL
    // ==========================================================

    await db.execute(
      '''
      CREATE TABLE user_profile (
        id TEXT PRIMARY KEY,
        name TEXT,
        artist_name TEXT,
        wallet TEXT,
        synced INTEGER
      )
      ''',
    );

    debugPrint(
      '[DATABASE] Banco criado na versão $version.',
    );
  }

  // ============================================================
  // UPGRADE
  // ============================================================

  Future<
    void
  >
  _upgradeDB(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    debugPrint(
      '[DATABASE] Migration $oldVersion -> $newVersion',
    );

    // ==========================================================
    // PROJECTS.NAME
    // ==========================================================

    await _addColumnIfMissing(
      db,
      table: 'projects',
      column: 'name',
      definition: 'TEXT DEFAULT "SEM TÍTULO"',
    );

    // ==========================================================
    // USER_PROFILE.ARTIST_NAME
    // ==========================================================

    await _addColumnIfMissing(
      db,
      table: 'user_profile',
      column: 'artist_name',
      definition: 'TEXT',
    );
  }

  // ============================================================
  // ON OPEN
  // ============================================================
  //
  // Proteção adicional.
  //
  // Mesmo que algum banco antigo tenha uma versão inconsistente,
  // verificamos as colunas novamente quando o banco abre.
  //
  // ============================================================

  Future<
    void
  >
  _onOpen(
    Database db,
  ) async {
    await _addColumnIfMissing(
      db,
      table: 'user_profile',
      column: 'artist_name',
      definition: 'TEXT',
    );

    debugPrint(
      '[DATABASE] Estrutura verificada.',
    );
  }

  // ============================================================
  // ADICIONAR COLUNA SE NÃO EXISTIR
  // ============================================================

  Future<
    void
  >
  _addColumnIfMissing(
    Database db, {
    required String table,
    required String column,
    required String definition,
  }) async {
    final tableExists = await _tableExists(
      db,
      table,
    );

    if (!tableExists) {
      debugPrint(
        '[DATABASE] Tabela $table não existe.',
      );

      return;
    }

    final columns = await db.rawQuery(
      'PRAGMA table_info($table)',
    );

    final exists = columns.any(
      (
        item,
      ) =>
          item['name'] ==
          column,
    );

    if (exists) {
      debugPrint(
        '[DATABASE] $table.$column já existe.',
      );

      return;
    }

    await db.execute(
      'ALTER TABLE $table '
      'ADD COLUMN $column $definition',
    );

    debugPrint(
      '[DATABASE] Coluna criada: $table.$column',
    );
  }

  // ============================================================
  // VERIFICAR TABELA
  // ============================================================

  Future<
    bool
  >
  _tableExists(
    Database db,
    String table,
  ) async {
    final result = await db.rawQuery(
      '''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
      AND name = ?
      LIMIT 1
      ''',
      [
        table,
      ],
    );

    return result.isNotEmpty;
  }

  // ============================================================
  // FECHAR
  // ============================================================

  Future<
    void
  >
  close() async {
    final db = _database;

    if (db ==
        null) {
      return;
    }

    await db.close();

    _database = null;

    debugPrint(
      '[DATABASE] Banco fechado.',
    );
  }
}
