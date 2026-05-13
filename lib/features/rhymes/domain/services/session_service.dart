import 'package:versin/features/rhymes/data/repositories/project_repository.dart';

class SessionService {
  final ProjectRepository _repository = ProjectRepository();

  // Verifica se o usuário deve ver o modal de "Continuar Projeto"
  Future<Map<String, dynamic>?> hasPendingSession() async {
    try {
      final activeProject = await _repository.getActiveProject();
      
      if (activeProject != null) {
        return activeProject;
      }
    } catch (e) {
      print("Erro ao verificar sessão pendente: $e");
    }
    return null;
  }

  // Inicia um fluxo totalmente limpo para novas perguntas
  Future<void> startFreshSession() async {
    await _repository.archiveActiveProjects();
  }

  // Prepara os dados básicos para a nova rima (Sem referências externas)
  Map<String, dynamic> prepareNewProjectData({
    required String genre,
    required String mood,
    String? name,
    String template = 'PADRÃO', // Alterado de ASTRYVO para PADRÃO
  }) {
    return {
      'name': name ?? 'SEM TÍTULO', // Define nome padrão se for nulo
      'genre': genre,
      'mood': mood,
      'template': template,
      'content': '', 
    };
  }
}