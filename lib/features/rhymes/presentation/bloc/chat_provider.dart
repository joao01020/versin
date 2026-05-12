import 'package:flutter/material.dart';
import 'package:versin/core/database/database_helper.dart';

enum ChatSessionStatus { checking, idle, active }

class ChatProvider extends ChangeNotifier {
  ChatSessionStatus _status = ChatSessionStatus.checking;
  Map<String, dynamic>? _activeProject;

  ChatSessionStatus get status => _status;
  Map<String, dynamic>? get activeProject => _activeProject;

  // Verifica se existe um projeto com status 'active' no SQLite
  Future<void> checkExistingSession() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> results = await db.query(
      'rhymes',
      where: 'status = ?',
      whereArgs: ['active'],
      limit: 1,
    );

    if (results.isNotEmpty) {
      _activeProject = results.first;
      _status = ChatSessionStatus.active;
    } else {
      _status = ChatSessionStatus.idle;
    }
    notifyListeners();
  }

  // Define um novo projeto e limpa o estado anterior
  Future<void> startNewProject() async {
    final db = await DatabaseHelper.instance.database;
    // Marca projetos antigos como finalizados para evitar conflito
    await db.update(
      'rhymes',
      {'status': 'completed'},
      where: 'status = ?',
      whereArgs: ['active'],
    );
    
    _activeProject = null;
    _status = ChatSessionStatus.idle;
    notifyListeners();
  }

  // Continua o projeto encontrado
  void resumeProject() {
    _status = ChatSessionStatus.active;
    notifyListeners();
  }
}