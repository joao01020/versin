import 'package:versin/features/rhymes/data/repositories/project_repository.dart';

class SessionService {
  final ProjectRepository _repository = ProjectRepository();

  // Verifica se o usuário deve ver o modal de "Continuar Projeto"
  Future<Map<String, dynamic>?> hasPendingSession() async {
    try {
      final activeProject = await _repository.getActiveProject();
      
      if (activeProject != null) {
        // Você pode adicionar uma lógica aqui para expirar sessões muito antigas
        // Ex: Se o projeto tem mais de 48h, retorna null
        return activeProject;
      }
    } catch (e) {
      print("Erro ao verificar sessão pendente: $e");
    }
    return null;
  }

  // Inicia um fluxo totalmente limpo para novas perguntas
  Future<void> startFreshSession() async {
    // Arquivamos o anterior para manter histórico no Supabase depois
    await _repository.archiveActiveProjects();
  }

  // Prepara os dados do template (ASTRYVO) para a nova rima
  Map<String, dynamic> prepareNewProjectData({
    required String genre,
    required String mood,
    String template = 'ASTRYVO V1',
  }) {
    return {
      'genre': genre,
      'mood': mood,
      'template': template,
      'content': '', // Inicia vazio para o chat
    };
  }
}