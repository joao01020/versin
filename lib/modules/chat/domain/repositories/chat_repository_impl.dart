import '../../models/chat_message.dart';

/// 1. A Interface (O contrato)
abstract class ChatRepository {
  Future<List<Map<String, dynamic>>> fetchAiResponse(String message);
  Future<void> saveProject(Map<String, dynamic> projectData);
}

/// 2. A Implementação (A classe concreta)
class ChatRepositoryImpl implements ChatRepository {
  @override
  Future<List<Map<String, dynamic>>> fetchAiResponse(String message) async {
    // Lógica da API será implementada aqui
    return []; 
  }
  
  @override
  Future<void> saveProject(Map<String, dynamic> projectData) async {
    // Lógica para persistência
  }
}