import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/repositories/recent_activity_repository_impl.dart';
import '../models/recent_activity_model.dart';
import '../models/recent_activity_type.dart';
import '../repositories/recent_activity_repository.dart';

// ============================================================
// RECENT ACTIVITY CONTROLLER
// ============================================================
//
// Responsável por:
//
// - carregar atividades recentes;
// - limitar o Dashboard a 3 atividades;
// - buscar histórico completo;
// - controlar loading;
// - controlar erros;
// - observar novas atividades via Realtime;
// - registrar atividades;
// - remover atividades;
// - limpar o histórico.
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

class RecentActivityController
    extends
        ChangeNotifier {
  // ============================================================
  // CONFIGURAÇÃO
  // ============================================================

  static const int dashboardLimit = 3;

  // ============================================================
  // REPOSITORY
  // ============================================================

  final RecentActivityRepository _repository;

  // ============================================================
  // REALTIME
  // ============================================================

  StreamSubscription<
    List<
      RecentActivityModel
    >
  >?
  _activitiesSubscription;

  // ============================================================
  // ESTADO
  // ============================================================

  List<
    RecentActivityModel
  >
  _activities =
      <
        RecentActivityModel
      >[];

  bool _isLoading = false;

  bool _isInitialized = false;

  bool _isListening = false;

  bool _isDisposed = false;

  String? _errorMessage;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  RecentActivityController({
    RecentActivityRepository? repository,
  }) : _repository =
           repository ??
           RecentActivityRepositoryImpl();

  // ============================================================
  // GETTERS
  // ============================================================

  List<
    RecentActivityModel
  >
  get activities {
    return List<
      RecentActivityModel
    >.unmodifiable(
      _activities,
    );
  }

  bool get isLoading {
    return _isLoading;
  }

  bool get isInitialized {
    return _isInitialized;
  }

  bool get isListening {
    return _isListening;
  }

  bool get hasActivities {
    return _activities.isNotEmpty;
  }

  bool get hasError {
    return _errorMessage !=
        null;
  }

  String? get errorMessage {
    return _errorMessage;
  }

  int get totalCount {
    return _activities.length;
  }

  RecentActivityModel? get latestActivity {
    if (_activities.isEmpty) {
      return null;
    }

    return _activities.first;
  }

  // ============================================================
  // INICIALIZAR
  // ============================================================

  Future<
    void
  >
  init() async {
    if (_isDisposed) {
      return;
    }

    if (_isInitialized) {
      return;
    }

    _isInitialized = true;

    await load();

    if (_isDisposed) {
      return;
    }

    startListening();
  }

  // ============================================================
  // CARREGAR DASHBOARD
  // ============================================================

  Future<
    void
  >
  load() async {
    if (_isDisposed) {
      return;
    }

    if (_isLoading) {
      return;
    }

    _isLoading = true;

    _errorMessage = null;

    _safeNotify();

    try {
      final result = await _repository.getRecentActivities(
        limit: dashboardLimit,
      );

      if (_isDisposed) {
        return;
      }

      _setActivities(
        result,
      );

      debugPrint(
        '[RECENT ACTIVITY CONTROLLER] '
        '${_activities.length} atividade(s) carregada(s).',
      );
    } catch (
      error
    ) {
      if (_isDisposed) {
        return;
      }

      _errorMessage = 'Não foi possível carregar as atividades recentes.';

      debugPrint(
        '[RECENT ACTIVITY CONTROLLER] '
        'Erro ao carregar: $error',
      );
    } finally {
      if (!_isDisposed) {
        _isLoading = false;

        _safeNotify();
      }
    }
  }

  // ============================================================
  // REFRESH DASHBOARD
  // ============================================================

  Future<
    void
  >
  refresh() async {
    if (_isDisposed) {
      return;
    }

    try {
      final result = await _repository.getRecentActivities(
        limit: dashboardLimit,
      );

      if (_isDisposed) {
        return;
      }

      _errorMessage = null;

      _setActivities(
        result,
      );
    } catch (
      error
    ) {
      if (_isDisposed) {
        return;
      }

      _errorMessage = 'Não foi possível atualizar as atividades.';

      debugPrint(
        '[RECENT ACTIVITY CONTROLLER] '
        'Erro no refresh: $error',
      );

      _safeNotify();
    }
  }

  // ============================================================
  // BUSCAR HISTÓRICO COMPLETO
  // ============================================================
  //
  // Utilizado pela:
  //
  // RecentActivitiesPage
  //
  // O Dashboard continua usando apenas 3 atividades.
  //
  // ============================================================

  Future<
    List<
      RecentActivityModel
    >
  >
  getAllActivities() async {
    if (_isDisposed) {
      return <
        RecentActivityModel
      >[];
    }

    try {
      final result = await _repository.getAllActivities();

      result.sort(
        (
          a,
          b,
        ) {
          return b.createdAt.compareTo(
            a.createdAt,
          );
        },
      );

      debugPrint(
        '[RECENT ACTIVITY CONTROLLER] '
        '${result.length} atividade(s) no histórico completo.',
      );

      return result;
    } catch (
      error
    ) {
      debugPrint(
        '[RECENT ACTIVITY CONTROLLER] '
        'Erro ao buscar histórico completo: $error',
      );

      rethrow;
    }
  }

  // ============================================================
  // REALTIME
  // ============================================================

  void startListening() {
    if (_isDisposed) {
      return;
    }

    if (_isListening) {
      return;
    }

    _isListening = true;

    _activitiesSubscription?.cancel();

    _activitiesSubscription = _repository
        .watchRecentActivities(
          limit: dashboardLimit,
        )
        .listen(
          (
            List<
              RecentActivityModel
            >
            activities,
          ) {
            if (_isDisposed) {
              return;
            }

            _errorMessage = null;

            _setActivities(
              activities,
            );

            debugPrint(
              '[RECENT ACTIVITY CONTROLLER] '
              'Realtime atualizado.',
            );
          },
          onError:
              (
                Object error,
              ) {
                if (_isDisposed) {
                  return;
                }

                _errorMessage = 'Não foi possível receber novas atividades.';

                debugPrint(
                  '[RECENT ACTIVITY CONTROLLER] '
                  'Erro realtime: $error',
                );

                _safeNotify();
              },
        );
  }

  // ============================================================
  // PARAR REALTIME
  // ============================================================

  Future<
    void
  >
  stopListening() async {
    await _activitiesSubscription?.cancel();

    _activitiesSubscription = null;

    _isListening = false;

    _safeNotify();
  }

  // ============================================================
  // REGISTRAR ATIVIDADE
  // ============================================================

  Future<
    RecentActivityModel?
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
    try {
      final activity = await _repository.createActivity(
        type: type,
        title: title,
        description: description,
        metadata: metadata,
      );

      if (_isDisposed) {
        return activity;
      }

      _upsertLocalActivity(
        activity,
      );

      _sortActivities();

      _trimToDashboardLimit();

      _safeNotify();

      debugPrint(
        '[RECENT ACTIVITY CONTROLLER] '
        'Atividade criada: ${activity.id}',
      );

      return activity;
    } catch (
      error
    ) {
      if (!_isDisposed) {
        _errorMessage = 'Não foi possível registrar a atividade.';

        _safeNotify();
      }

      debugPrint(
        '[RECENT ACTIVITY CONTROLLER] '
        'Erro ao criar atividade: $error',
      );

      return null;
    }
  }

  // ============================================================
  // REMOVER
  // ============================================================

  Future<
    bool
  >
  deleteActivity(
    String activityId,
  ) async {
    final normalizedId = activityId.trim();

    if (normalizedId.isEmpty) {
      return false;
    }

    try {
      await _repository.deleteActivity(
        normalizedId,
      );

      if (_isDisposed) {
        return true;
      }

      _activities.removeWhere(
        (
          activity,
        ) {
          return activity.id ==
              normalizedId;
        },
      );

      _safeNotify();

      return true;
    } catch (
      error
    ) {
      if (!_isDisposed) {
        _errorMessage = 'Não foi possível remover a atividade.';

        _safeNotify();
      }

      debugPrint(
        '[RECENT ACTIVITY CONTROLLER] '
        'Erro ao remover atividade: $error',
      );

      return false;
    }
  }

  // ============================================================
  // LIMPAR HISTÓRICO
  // ============================================================

  Future<
    bool
  >
  clearActivities() async {
    try {
      await _repository.clearActivities();

      if (_isDisposed) {
        return true;
      }

      _activities.clear();

      _safeNotify();

      return true;
    } catch (
      error
    ) {
      if (!_isDisposed) {
        _errorMessage = 'Não foi possível limpar as atividades.';

        _safeNotify();
      }

      debugPrint(
        '[RECENT ACTIVITY CONTROLLER] '
        'Erro ao limpar histórico: $error',
      );

      return false;
    }
  }

  // ============================================================
  // BUSCAR POR ID LOCAL
  // ============================================================

  RecentActivityModel? findById(
    String activityId,
  ) {
    final normalizedId = activityId.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    for (final activity in _activities) {
      if (activity.id ==
          normalizedId) {
        return activity;
      }
    }

    return null;
  }

  // ============================================================
  // LIMPAR ERRO
  // ============================================================

  void clearError() {
    if (_errorMessage ==
        null) {
      return;
    }

    _errorMessage = null;

    _safeNotify();
  }

  // ============================================================
  // DEFINIR ATIVIDADES DO DASHBOARD
  // ============================================================

  void _setActivities(
    Iterable<
      RecentActivityModel
    >
    activities,
  ) {
    final byId =
        <
          String,
          RecentActivityModel
        >{};

    for (final activity in activities) {
      final id = activity.id.trim();

      if (id.isEmpty) {
        continue;
      }

      byId[id] = activity;
    }

    _activities = byId.values.toList();

    _sortActivities();

    _trimToDashboardLimit();

    _safeNotify();
  }

  // ============================================================
  // UPSERT LOCAL
  // ============================================================

  void _upsertLocalActivity(
    RecentActivityModel activity,
  ) {
    final id = activity.id.trim();

    if (id.isEmpty) {
      return;
    }

    final index = _activities.indexWhere(
      (
        item,
      ) {
        return item.id ==
            id;
      },
    );

    if (index <
        0) {
      _activities.add(
        activity,
      );

      return;
    }

    _activities[index] = activity;
  }

  // ============================================================
  // ORDENAR
  // ============================================================

  void _sortActivities() {
    _activities.sort(
      (
        a,
        b,
      ) {
        return b.createdAt.compareTo(
          a.createdAt,
        );
      },
    );
  }

  // ============================================================
  // LIMITAR DASHBOARD
  // ============================================================

  void _trimToDashboardLimit() {
    if (_activities.length <=
        dashboardLimit) {
      return;
    }

    _activities = _activities
        .take(
          dashboardLimit,
        )
        .toList();
  }

  // ============================================================
  // SAFE NOTIFY
  // ============================================================

  void _safeNotify() {
    if (_isDisposed) {
      return;
    }

    notifyListeners();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;

    _activitiesSubscription?.cancel();

    _activitiesSubscription = null;

    _isListening = false;

    unawaited(
      _repository.dispose(),
    );

    super.dispose();
  }
}
