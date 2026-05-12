import 'package:sqflite/sqflite.dart';
import 'package:versin/core/database/database_helper.dart';

class ProjectRepository {
  final String _tableName = 'rhymes';

  // Busca o projeto que está com status 'active'
  Future<Map<String, dynamic>?> getActiveProject() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'status = ?',
      whereArgs: ['active'],
      limit: 1,
      orderBy: 'created_at DESC',
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // Cria uma nova entrada de rima/projeto
  Future<int> createProject(Map<String, dynamic> projectData) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert(
      _tableName,
      {
        ...projectData,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Finaliza um projeto (muda status para completed ou deleta)
  Future<void> archiveActiveProjects() async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      _tableName,
      {'status': 'archived'},
      where: 'status = ?',
      whereArgs: ['active'],
    );
  }

  // Deleta permanentemente o rascunho ativo
  Future<void> deleteActiveProject() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      _tableName,
      where: 'status = ?',
      whereArgs: ['active'],
    );
  }
}