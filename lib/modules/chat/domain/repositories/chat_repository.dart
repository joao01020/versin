import 'package:versin/modules/chat/models/chat_message.dart';

abstract class ChatRepository {
  Future<List<Map<String, dynamic>>> fetchAiResponse(String message);
  Future<void> saveProject(Map<String, dynamic> projectData);
}

// IMPLEMENTAÇÃO CONCRETA (Adicione isto abaixo da interface)
class ChatRepositoryImpl implements ChatRepository {
  @override
  Future<List<Map<String, dynamic>>> fetchAiResponse(String message) async {
    // Aqui você conectará sua API no futuro
    return []; 
  }

  @override
  Future<void> saveProject(Map<String, dynamic> projectData) async {
    // Lógica para salvar projeto
  }
}