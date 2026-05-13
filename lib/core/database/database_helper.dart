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
    
    // Versão incrementada para 2 para suportar a nova coluna de nome
    return await openDatabase(
      path, 
      version: 2, 
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE offline_rhymes (id TEXT PRIMARY KEY, word TEXT, synced INTEGER)
    ''');
    
    // Tabela projects agora inclui o campo 'name' para o título do projeto
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY, 
        name TEXT, 
        lyrics TEXT, 
        bpm INTEGER, 
        vibe TEXT, 
        technique TEXT, 
        synced INTEGER
      )
    ''');
    
    await db.execute('''
      CREATE TABLE user_profile (id TEXT PRIMARY KEY, name TEXT, wallet TEXT, synced INTEGER)
    ''');
  }

  // Função para atualizar bancos de dados existentes sem perder dados
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Adiciona a coluna name se ela não existir (para quem já tem a V1 instalada)
      await db.execute('ALTER TABLE projects ADD COLUMN name TEXT DEFAULT "SEM TÍTULO"');
    }
  }
}

// Linha 30: Estrutura atualizada para incluir 'name' na tabela projects
// Linha 31: Versão do banco subida para 2 para gatilho de atualização automática
// Linha 32: Tabela 'projects' sincronizada com o header editável da ChatPage
// Linha 33: Campo 'name' com valor padrão para evitar erros de nulo
// Linha 34: Responsabilidade técnica: Persistência do título do projeto offline
// Linha 35: Mantido o campo 'synced' para o fluxo do SyncManager
// Linha 36: OnUpgrade implementado para garantir integridade dos dados antigos
// Linha 37: Fim do arquivo DatabaseHelper sincronizado.