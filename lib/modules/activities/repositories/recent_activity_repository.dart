import '../models/recent_activity_model.dart';
import '../models/recent_activity_type.dart';

// ============================================================
// RECENT ACTIVITY REPOSITORY
// ============================================================
//
// Contrato da camada de dados do módulo de atividades.
//
// O Controller depende deste contrato.
//
// Esta camada NÃO conhece:
//
// - Supabase;
// - SQLite;
// - API;
// - implementação concreta.
//
// Fluxo:
//
// Dashboard
//    ↓
// RecentActivityController
//    ↓
// RecentActivityRepository
//    ↓
// RecentActivityRepositoryImpl
//    ↓
// RecentActivityRemoteDatasource
//    ↓
// Supabase
//
// ============================================================

abstract class RecentActivityRepository {
  // ==========================================================
  // BUSCAR ATIVIDADES RECENTES
  // ==========================================================
  //
  // Retorna as atividades do usuário atual ordenadas da mais
  // recente para a mais antiga.
  //
  // O limite padrão será útil para o Dashboard.
  //
  // ==========================================================

  Future<
    List<
      RecentActivityModel
    >
  >
  getRecentActivities({
    int limit = 5,
  });

  // ==========================================================
  // BUSCAR TODAS AS ATIVIDADES
  // ==========================================================
  //
  // Útil futuramente para uma página de histórico completo.
  //
  // ==========================================================

  Future<
    List<
      RecentActivityModel
    >
  >
  getAllActivities();

  // ==========================================================
  // BUSCAR ATIVIDADE POR ID
  // ==========================================================

  Future<
    RecentActivityModel?
  >
  getActivityById(
    String activityId,
  );

  // ==========================================================
  // REGISTRAR ATIVIDADE
  // ==========================================================
  //
  // Usado pelos demais módulos para registrar acontecimentos.
  //
  // Exemplos:
  //
  // welcome
  // profileUpdated
  // connection
  // favorite
  // fileAdded
  //
  // ==========================================================

  Future<
    RecentActivityModel
  >
  createActivity({
    required RecentActivityType type,
    required String title,
    required String description,
    Map<
      String,
      dynamic
    >?
    metadata,
  });

  // ==========================================================
  // REMOVER ATIVIDADE
  // ==========================================================

  Future<
    void
  >
  deleteActivity(
    String activityId,
  );

  // ==========================================================
  // LIMPAR HISTÓRICO
  // ==========================================================
  //
  // Pode ser útil futuramente para configurações da conta.
  //
  // ==========================================================

  Future<
    void
  >
  clearActivities();

  // ==========================================================
  // REALTIME
  // ==========================================================
  //
  // Mantém o Dashboard atualizado quando uma nova atividade
  // for criada.
  //
  // ==========================================================

  Stream<
    List<
      RecentActivityModel
    >
  >
  watchRecentActivities({
    int limit = 5,
  });

  // ==========================================================
  // DISPOSE
  // ==========================================================

  Future<
    void
  >
  dispose();
}
