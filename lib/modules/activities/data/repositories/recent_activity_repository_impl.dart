import '../../models/recent_activity_model.dart';
import '../../models/recent_activity_type.dart';
import '../../repositories/recent_activity_repository.dart';
import '../datasources/recent_activity_remote_datasource.dart';

// ============================================================
// RECENT ACTIVITY REPOSITORY IMPLEMENTATION
// ============================================================
//
// Implementação concreta do:
//
// RecentActivityRepository
//
// Responsabilidades:
//
// - validar dados básicos;
// - normalizar informações;
// - encaminhar operações ao Datasource;
// - manter o Controller independente do Supabase.
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

class RecentActivityRepositoryImpl
    implements
        RecentActivityRepository {
  // ============================================================
  // DATASOURCE
  // ============================================================

  final RecentActivityRemoteDatasource _remoteDatasource;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  RecentActivityRepositoryImpl({
    RecentActivityRemoteDatasource? remoteDatasource,
  }) : _remoteDatasource =
           remoteDatasource ??
           RecentActivityRemoteDatasourceImpl();

  // ============================================================
  // BUSCAR ATIVIDADES RECENTES
  // ============================================================

  @override
  Future<
    List<
      RecentActivityModel
    >
  >
  getRecentActivities({
    int limit = 5,
  }) async {
    final normalizedLimit = _normalizeLimit(
      limit,
    );

    return await _remoteDatasource.getRecentActivities(
      limit: normalizedLimit,
    );
  }

  // ============================================================
  // BUSCAR TODAS
  // ============================================================

  @override
  Future<
    List<
      RecentActivityModel
    >
  >
  getAllActivities() async {
    return await _remoteDatasource.getAllActivities();
  }

  // ============================================================
  // BUSCAR POR ID
  // ============================================================

  @override
  Future<
    RecentActivityModel?
  >
  getActivityById(
    String activityId,
  ) async {
    final normalizedId = activityId.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    return await _remoteDatasource.getActivityById(
      normalizedId,
    );
  }

  // ============================================================
  // CRIAR ATIVIDADE
  // ============================================================

  @override
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
  }) async {
    final normalizedTitle = title.trim();

    final normalizedDescription = description.trim();

    // ==========================================================
    // VALIDAR TÍTULO
    // ==========================================================

    if (normalizedTitle.isEmpty) {
      throw ArgumentError(
        'O título da atividade não pode ser vazio.',
      );
    }

    // ==========================================================
    // VALIDAR DESCRIÇÃO
    // ==========================================================

    if (normalizedDescription.isEmpty) {
      throw ArgumentError(
        'A descrição da atividade não pode ser vazia.',
      );
    }

    // ==========================================================
    // NORMALIZAR METADATA
    // ==========================================================

    final normalizedMetadata =
        metadata ==
            null
        ? <
            String,
            dynamic
          >{}
        : Map<
            String,
            dynamic
          >.from(
            metadata,
          );

    // ==========================================================
    // CRIAR
    // ==========================================================

    return await _remoteDatasource.createActivity(
      type: type,
      title: normalizedTitle,
      description: normalizedDescription,
      metadata: normalizedMetadata,
    );
  }

  // ============================================================
  // REMOVER ATIVIDADE
  // ============================================================

  @override
  Future<
    void
  >
  deleteActivity(
    String activityId,
  ) async {
    final normalizedId = activityId.trim();

    if (normalizedId.isEmpty) {
      return;
    }

    await _remoteDatasource.deleteActivity(
      normalizedId,
    );
  }

  // ============================================================
  // LIMPAR HISTÓRICO
  // ============================================================

  @override
  Future<
    void
  >
  clearActivities() async {
    await _remoteDatasource.clearActivities();
  }

  // ============================================================
  // REALTIME
  // ============================================================

  @override
  Stream<
    List<
      RecentActivityModel
    >
  >
  watchRecentActivities({
    int limit = 5,
  }) {
    final normalizedLimit = _normalizeLimit(
      limit,
    );

    return _remoteDatasource.watchRecentActivities(
      limit: normalizedLimit,
    );
  }

  // ============================================================
  // NORMALIZAR LIMITE
  // ============================================================

  int _normalizeLimit(
    int limit,
  ) {
    if (limit <=
        0) {
      return 5;
    }

    if (limit >
        100) {
      return 100;
    }

    return limit;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  Future<
    void
  >
  dispose() async {
    await _remoteDatasource.dispose();
  }
}
