import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/recent_activity_model.dart';
import '../../models/recent_activity_type.dart';

// ============================================================
// RECENT ACTIVITY REMOTE DATASOURCE
// ============================================================
//
// Responsável por:
//
// - buscar atividades recentes;
// - buscar histórico completo;
// - buscar uma atividade por ID;
// - criar atividades;
// - remover atividades;
// - limpar histórico;
// - observar mudanças em tempo real.
//
// Tabela esperada:
//
// public.recent_activities
//
// Estrutura esperada:
//
// id
// user_id
// type
// title
// description
// metadata
// created_at
//
// ============================================================

abstract class RecentActivityRemoteDatasource {
  // ============================================================
  // BUSCAR RECENTES
  // ============================================================

  Future<
    List<
      RecentActivityModel
    >
  >
  getRecentActivities({
    int limit = 5,
  });

  // ============================================================
  // BUSCAR TODAS
  // ============================================================

  Future<
    List<
      RecentActivityModel
    >
  >
  getAllActivities();

  // ============================================================
  // BUSCAR POR ID
  // ============================================================

  Future<
    RecentActivityModel?
  >
  getActivityById(
    String activityId,
  );

  // ============================================================
  // CRIAR
  // ============================================================

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

  // ============================================================
  // REMOVER
  // ============================================================

  Future<
    void
  >
  deleteActivity(
    String activityId,
  );

  // ============================================================
  // LIMPAR
  // ============================================================

  Future<
    void
  >
  clearActivities();

  // ============================================================
  // REALTIME
  // ============================================================

  Stream<
    List<
      RecentActivityModel
    >
  >
  watchRecentActivities({
    int limit = 5,
  });

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<
    void
  >
  dispose();
}

// ============================================================
// IMPLEMENTAÇÃO SUPABASE
// ============================================================

class RecentActivityRemoteDatasourceImpl
    implements
        RecentActivityRemoteDatasource {
  // ============================================================
  // TABELA
  // ============================================================

  static const String _tableName = 'recent_activities';

  // ============================================================
  // SELECT
  // ============================================================

  static const String _selectFields = '''
    id,
    user_id,
    type,
    title,
    description,
    metadata,
    created_at
  ''';

  // ============================================================
  // SUPABASE
  // ============================================================

  final SupabaseClient _supabase;

  // ============================================================
  // REALTIME
  // ============================================================

  StreamSubscription<
    List<
      Map<
        String,
        dynamic
      >
    >
  >?
  _realtimeSubscription;

  final StreamController<
    List<
      RecentActivityModel
    >
  >
  _streamController =
      StreamController<
        List<
          RecentActivityModel
        >
      >.broadcast();

  bool _isListening = false;

  bool _isDisposed = false;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  RecentActivityRemoteDatasourceImpl({
    SupabaseClient? supabase,
  }) : _supabase =
           supabase ??
           Supabase.instance.client;

  // ============================================================
  // USER ID
  // ============================================================

  String? get _currentUserId {
    return _supabase.auth.currentUser?.id;
  }

  // ============================================================
  // VALIDAR USUÁRIO
  // ============================================================

  String _requireUserId() {
    final userId = _currentUserId;

    if (userId ==
            null ||
        userId.trim().isEmpty) {
      throw const AuthException(
        'Usuário não autenticado.',
      );
    }

    return userId.trim();
  }

  // ============================================================
  // BUSCAR RECENTES
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
    final userId = _requireUserId();

    final safeLimit = _normalizeLimit(
      limit,
    );

    try {
      final response = await _supabase
          .from(
            _tableName,
          )
          .select(
            _selectFields,
          )
          .eq(
            'user_id',
            userId,
          )
          .order(
            'created_at',
            ascending: false,
          )
          .limit(
            safeLimit,
          );

      final rows =
          List<
            Map<
              String,
              dynamic
            >
          >.from(
            response,
          );

      final activities = rows
          .map(
            RecentActivityModel.fromMap,
          )
          .toList();

      debugPrint(
        '[RECENT ACTIVITY REMOTE] '
        '${activities.length} atividade(s) carregada(s).',
      );

      return activities;
    } on PostgrestException catch (
      error
    ) {
      debugPrint(
        '[RECENT ACTIVITY REMOTE] '
        'Erro Supabase ao buscar recentes: '
        '${error.message}',
      );

      rethrow;
    } catch (
      error
    ) {
      debugPrint(
        '[RECENT ACTIVITY REMOTE] '
        'Erro ao buscar recentes: '
        '$error',
      );

      rethrow;
    }
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
    final userId = _requireUserId();

    try {
      final response = await _supabase
          .from(
            _tableName,
          )
          .select(
            _selectFields,
          )
          .eq(
            'user_id',
            userId,
          )
          .order(
            'created_at',
            ascending: false,
          );

      final rows =
          List<
            Map<
              String,
              dynamic
            >
          >.from(
            response,
          );

      return rows
          .map(
            RecentActivityModel.fromMap,
          )
          .toList();
    } on PostgrestException catch (
      error
    ) {
      debugPrint(
        '[RECENT ACTIVITY REMOTE] '
        'Erro Supabase ao buscar histórico: '
        '${error.message}',
      );

      rethrow;
    } catch (
      error
    ) {
      debugPrint(
        '[RECENT ACTIVITY REMOTE] '
        'Erro ao buscar histórico: '
        '$error',
      );

      rethrow;
    }
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
    final userId = _requireUserId();

    final normalizedId = activityId.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    try {
      final response = await _supabase
          .from(
            _tableName,
          )
          .select(
            _selectFields,
          )
          .eq(
            'id',
            normalizedId,
          )
          .eq(
            'user_id',
            userId,
          )
          .maybeSingle();

      if (response ==
          null) {
        return null;
      }

      return RecentActivityModel.fromMap(
        response,
      );
    } on PostgrestException catch (
      error
    ) {
      debugPrint(
        '[RECENT ACTIVITY REMOTE] '
        'Erro Supabase ao buscar atividade: '
        '${error.message}',
      );

      rethrow;
    } catch (
      error
    ) {
      debugPrint(
        '[RECENT ACTIVITY REMOTE] '
        'Erro ao buscar atividade: '
        '$error',
      );

      rethrow;
    }
  }

  // ============================================================
  // CRIAR
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
    final userId = _requireUserId();

    final normalizedTitle = title.trim();

    final normalizedDescription = description.trim();

    if (normalizedTitle.isEmpty) {
      throw ArgumentError(
        'O título da atividade não pode ser vazio.',
      );
    }

    if (normalizedDescription.isEmpty) {
      throw ArgumentError(
        'A descrição da atividade não pode ser vazia.',
      );
    }

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

    try {
      final response = await _supabase
          .from(
            _tableName,
          )
          .insert(
            {
              'user_id': userId,

              'type': type.key,

              'title': normalizedTitle,

              'description': normalizedDescription,

              'metadata': normalizedMetadata,
            },
          )
          .select(
            _selectFields,
          )
          .single();

      final activity = RecentActivityModel.fromMap(
        response,
      );

      debugPrint(
        '[RECENT ACTIVITY REMOTE] '
        'Atividade criada: ${activity.id}',
      );

      return activity;
    } on PostgrestException catch (
      error
    ) {
      debugPrint(
        '[RECENT ACTIVITY REMOTE] '
        'Erro Supabase ao criar atividade: '
        '${error.message}',
      );

      rethrow;
    } catch (
      error
    ) {
      debugPrint(
        '[RECENT ACTIVITY REMOTE] '
        'Erro ao criar atividade: '
        '$error',
      );

      rethrow;
    }
  }

  // ============================================================
  // REMOVER
  // ============================================================

  @override
  Future<
    void
  >
  deleteActivity(
    String activityId,
  ) async {
    final userId = _requireUserId();

    final normalizedId = activityId.trim();

    if (normalizedId.isEmpty) {
      return;
    }

    try {
      await _supabase
          .from(
            _tableName,
          )
          .delete()
          .eq(
            'id',
            normalizedId,
          )
          .eq(
            'user_id',
            userId,
          );

      debugPrint(
        '[RECENT ACTIVITY REMOTE] '
        'Atividade removida: $normalizedId',
      );
    } on PostgrestException catch (
      error
    ) {
      debugPrint(
        '[RECENT ACTIVITY REMOTE] '
        'Erro Supabase ao remover atividade: '
        '${error.message}',
      );

      rethrow;
    } catch (
      error
    ) {
      debugPrint(
        '[RECENT ACTIVITY REMOTE] '
        'Erro ao remover atividade: '
        '$error',
      );

      rethrow;
    }
  }

  // ============================================================
  // LIMPAR HISTÓRICO
  // ============================================================

  @override
  Future<
    void
  >
  clearActivities() async {
    final userId = _requireUserId();

    try {
      await _supabase
          .from(
            _tableName,
          )
          .delete()
          .eq(
            'user_id',
            userId,
          );

      debugPrint(
        '[RECENT ACTIVITY REMOTE] '
        'Histórico de atividades removido.',
      );
    } on PostgrestException catch (
      error
    ) {
      debugPrint(
        '[RECENT ACTIVITY REMOTE] '
        'Erro Supabase ao limpar histórico: '
        '${error.message}',
      );

      rethrow;
    } catch (
      error
    ) {
      debugPrint(
        '[RECENT ACTIVITY REMOTE] '
        'Erro ao limpar histórico: '
        '$error',
      );

      rethrow;
    }
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
    final safeLimit = _normalizeLimit(
      limit,
    );

    _startRealtime(
      limit: safeLimit,
    );

    return _streamController.stream;
  }

  // ============================================================
  // INICIAR REALTIME
  // ============================================================

  void _startRealtime({
    required int limit,
  }) {
    if (_isDisposed ||
        _isListening) {
      return;
    }

    final userId = _requireUserId();

    _isListening = true;

    bool firstEmission = true;

    _realtimeSubscription = _supabase
        .from(
          _tableName,
        )
        .stream(
          primaryKey: [
            'id',
          ],
        )
        .eq(
          'user_id',
          userId,
        )
        .listen(
          (
            _,
          ) async {
            if (_isDisposed) {
              return;
            }

            // ======================================================
            // IGNORAR SNAPSHOT INICIAL
            // ======================================================
            //
            // O Controller pode fazer a primeira carga via:
            //
            // getRecentActivities()
            //
            // e depois iniciar o Realtime.
            //
            // ======================================================

            if (firstEmission) {
              firstEmission = false;

              debugPrint(
                '[RECENT ACTIVITY REMOTE] '
                'Snapshot inicial ignorado.',
              );

              return;
            }

            try {
              final activities = await getRecentActivities(
                limit: limit,
              );

              if (_isDisposed ||
                  _streamController.isClosed) {
                return;
              }

              _streamController.add(
                activities,
              );

              debugPrint(
                '[RECENT ACTIVITY REMOTE] '
                'Realtime atualizado.',
              );
            } catch (
              error
            ) {
              if (_isDisposed ||
                  _streamController.isClosed) {
                return;
              }

              _streamController.addError(
                error,
              );
            }
          },
          onError:
              (
                Object error,
              ) {
                if (_isDisposed ||
                    _streamController.isClosed) {
                  return;
                }

                debugPrint(
                  '[RECENT ACTIVITY REMOTE] '
                  'Erro Realtime: $error',
                );

                _streamController.addError(
                  error,
                );
              },
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
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;

    await _realtimeSubscription?.cancel();

    _realtimeSubscription = null;

    _isListening = false;

    if (!_streamController.isClosed) {
      await _streamController.close();
    }
  }
}
