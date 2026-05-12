import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('versin_storage.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE offline_rhymes (id TEXT PRIMARY KEY, word TEXT, synced INTEGER)
    ''');
    await db.execute('''
      CREATE TABLE projects (id TEXT PRIMARY KEY, lyrics TEXT, bpm INTEGER, vibe TEXT, technique TEXT, synced INTEGER)
    ''');
    await db.execute('''
      CREATE TABLE user_profile (id TEXT PRIMARY KEY, name TEXT, wallet TEXT, synced INTEGER)
    ''');
  }
}

// Linha 30: Estrutura preparada para persistência total (letras e wallet)
// Linha 31: Tabela 'projects' armazena o estado atual do seu estúdio
// Linha 32: Tabela 'user_profile' guarda os dados de acesso e carteira
// Linha 33: Campo 'synced' em todas as tabelas para controle do SyncManager
// Linha 34: Responsabilidade técnica: Garantia de dados offline first
// Linha 35: Próximo passo: Atualizar o SyncManager para estas novas tabelas
// Linha 36: Integração com Supabase facilitada via IDs únicos
// Linha 37: Fim do arquivo DatabaseHelper atualizado.