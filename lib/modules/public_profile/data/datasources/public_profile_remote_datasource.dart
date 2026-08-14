import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// PUBLIC PROFILE REMOTE DATASOURCE
// ============================================================
//
// Responsável SOMENTE pela comunicação com Supabase.
//
// Trabalha com:
//
// Map<String, dynamic>
//
// Conversão:
//
// Map -> Model
//
// pertence ao Repository.
//
// Responsabilidades:
//
// - buscar perfil;
// - atualizar perfil;
// - buscar demos;
// - buscar primeira demo;
// - criar demo;
// - atualizar demo;
// - excluir demo;
// - acompanhar demos em realtime.
//
// ============================================================

abstract class PublicProfileRemoteDatasource {
  // ==========================================================
  // PERFIL
  // ==========================================================

  Future<Map<String, dynamic>?> getProfile({required String userId});

  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required Map<String, dynamic> data,
  });

  // ==========================================================
  // TRACKS
  // ==========================================================

  Future<List<Map<String, dynamic>>> getTracks({
    required String userId,
    bool onlyActive = true,
  });

  // ==========================================================
  // PRIMEIRA DEMO
  // ==========================================================

  Future<Map<String, dynamic>?> getFirstTrack({
    required String userId,
    bool onlyActive = true,
  });

  // ==========================================================
  // CRIAR TRACK
  // ==========================================================

  Future<Map<String, dynamic>> createTrack({
    required Map<String, dynamic> data,
  });

  // ==========================================================
  // ATUALIZAR TRACK
  // ==========================================================

  Future<Map<String, dynamic>> updateTrack({
    required String trackId,
    required Map<String, dynamic> data,
  });

  // ==========================================================
  // EXCLUIR TRACK
  // ==========================================================

  Future<void> deleteTrack({required String trackId});

  // ==========================================================
  // REALTIME
  // ==========================================================

  Stream<List<Map<String, dynamic>>> watchTracks({required String userId});
}

// ============================================================
// IMPLEMENTAÇÃO SUPABASE
// ============================================================

class PublicProfileRemoteDatasourceImpl
    implements PublicProfileRemoteDatasource {
  // ============================================================
  // SUPABASE
  // ============================================================

  final SupabaseClient _supabase;

  // ============================================================
  // TABELAS
  // ============================================================

  static const String _profilesTable = 'profiles';

  static const String _tracksTable = 'profile_tracks';

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  PublicProfileRemoteDatasourceImpl({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  // ============================================================
  // BUSCAR PERFIL
  // ============================================================

  @override
  Future<Map<String, dynamic>?> getProfile({required String userId}) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return null;
    }

    try {
      final response = await _supabase
          .from(_profilesTable)
          .select('''
                id,
                username,
                artist_name,
                name,
                avatar_url,
                bio,
                is_online,
                created_at,
                updated_at
                ''')
          .eq('id', normalizedUserId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Map<String, dynamic>.from(response);
    } on PostgrestException catch (error) {
      debugPrint(
        '[PUBLIC PROFILE REMOTE] '
        'Erro ao carregar perfil: '
        '${error.message}',
      );

      rethrow;
    }
  }

  // ============================================================
  // ATUALIZAR PERFIL
  // ============================================================

  @override
  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      throw ArgumentError('userId não pode ser vazio.');
    }

    try {
      final response = await _supabase
          .from(_profilesTable)
          .update(data)
          .eq('id', normalizedUserId)
          .select('''
                id,
                username,
                artist_name,
                name,
                avatar_url,
                bio,
                is_online,
                created_at,
                updated_at
                ''')
          .single();

      return Map<String, dynamic>.from(response);
    } on PostgrestException catch (error) {
      debugPrint(
        '[PUBLIC PROFILE REMOTE] '
        'Erro ao atualizar perfil: '
        '${error.message}',
      );

      rethrow;
    }
  }

  // ============================================================
  // BUSCAR TRACKS
  // ============================================================

  @override
  Future<List<Map<String, dynamic>>> getTracks({
    required String userId,
    bool onlyActive = true,
  }) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    try {
      // ========================================================
      // SOMENTE ATIVAS
      // ========================================================

      if (onlyActive) {
        final response = await _supabase
            .from(_tracksTable)
            .select()
            .eq('user_id', normalizedUserId)
            .eq('is_active', true)
            .order('position', ascending: true)
            .order('created_at', ascending: false);

        return _convertRows(response);
      }

      // ========================================================
      // TODAS
      // ========================================================

      final response = await _supabase
          .from(_tracksTable)
          .select()
          .eq('user_id', normalizedUserId)
          .order('position', ascending: true)
          .order('created_at', ascending: false);

      return _convertRows(response);
    } on PostgrestException catch (error) {
      debugPrint(
        '[PUBLIC PROFILE REMOTE] '
        'Erro ao carregar músicas: '
        '${error.message}',
      );

      rethrow;
    }
  }

  // ============================================================
  // PRIMEIRA DEMO
  // ============================================================
  //
  // Usado principalmente em:
  //
  // Match
  //   ↓
  // OUVIR DEMO
  //
  // Busca somente uma faixa para evitar carregar a lista inteira.
  //
  // ============================================================

  @override
  Future<Map<String, dynamic>?> getFirstTrack({
    required String userId,
    bool onlyActive = true,
  }) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return null;
    }

    try {
      // ========================================================
      // SOMENTE ATIVA
      // ========================================================

      if (onlyActive) {
        final response = await _supabase
            .from(_tracksTable)
            .select()
            .eq('user_id', normalizedUserId)
            .eq('is_active', true)
            .order('position', ascending: true)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (response == null) {
          debugPrint(
            '[PUBLIC PROFILE REMOTE] '
            'Nenhuma demo ativa encontrada para: '
            '$normalizedUserId',
          );

          return null;
        }

        return Map<String, dynamic>.from(response);
      }

      // ========================================================
      // PRIMEIRA INDEPENDENTE DO STATUS
      // ========================================================

      final response = await _supabase
          .from(_tracksTable)
          .select()
          .eq('user_id', normalizedUserId)
          .order('position', ascending: true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Map<String, dynamic>.from(response);
    } on PostgrestException catch (error) {
      debugPrint(
        '[PUBLIC PROFILE REMOTE] '
        'Erro ao carregar primeira demo: '
        '${error.message}',
      );

      rethrow;
    }
  }

  // ============================================================
  // CRIAR TRACK
  // ============================================================

  @override
  Future<Map<String, dynamic>> createTrack({
    required Map<String, dynamic> data,
  }) async {
    if (data.isEmpty) {
      throw ArgumentError('Os dados da música não podem estar vazios.');
    }

    try {
      // ========================================================
      // GARANTIR QUE ID VAZIO NÃO SEJA ENVIADO
      // ========================================================

      final normalizedData = Map<String, dynamic>.from(data);

      if (normalizedData['id']?.toString().trim().isEmpty == true) {
        normalizedData.remove('id');
      }

      final response = await _supabase
          .from(_tracksTable)
          .insert(normalizedData)
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } on PostgrestException catch (error) {
      debugPrint(
        '[PUBLIC PROFILE REMOTE] '
        'Erro ao criar música: '
        '${error.message}',
      );

      rethrow;
    }
  }

  // ============================================================
  // ATUALIZAR TRACK
  // ============================================================

  @override
  Future<Map<String, dynamic>> updateTrack({
    required String trackId,
    required Map<String, dynamic> data,
  }) async {
    final normalizedTrackId = trackId.trim();

    if (normalizedTrackId.isEmpty) {
      throw ArgumentError('trackId não pode ser vazio.');
    }

    if (data.isEmpty) {
      throw ArgumentError('Os dados da música não podem estar vazios.');
    }

    try {
      final response = await _supabase
          .from(_tracksTable)
          .update(data)
          .eq('id', normalizedTrackId)
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } on PostgrestException catch (error) {
      debugPrint(
        '[PUBLIC PROFILE REMOTE] '
        'Erro ao atualizar música: '
        '${error.message}',
      );

      rethrow;
    }
  }

  // ============================================================
  // EXCLUIR TRACK
  // ============================================================

  @override
  Future<void> deleteTrack({required String trackId}) async {
    final normalizedTrackId = trackId.trim();

    if (normalizedTrackId.isEmpty) {
      return;
    }

    try {
      await _supabase.from(_tracksTable).delete().eq('id', normalizedTrackId);
    } on PostgrestException catch (error) {
      debugPrint(
        '[PUBLIC PROFILE REMOTE] '
        'Erro ao excluir música: '
        '${error.message}',
      );

      rethrow;
    }
  }

  // ============================================================
  // STREAM DE TRACKS
  // ============================================================

  @override
  Stream<List<Map<String, dynamic>>> watchTracks({required String userId}) {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return Stream<List<Map<String, dynamic>>>.value(
        const <Map<String, dynamic>>[],
      );
    }

    return _supabase
        .from(_tracksTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', normalizedUserId)
        .map((rows) {
          final filtered = rows
              .where((row) {
                return row['is_active'] != false;
              })
              .map((row) {
                return Map<String, dynamic>.from(row);
              })
              .toList();

          filtered.sort((a, b) {
            // ==============================================
            // POSITION
            // ==============================================

            final positionA = _readPosition(a['position']);

            final positionB = _readPosition(b['position']);

            final positionResult = positionA.compareTo(positionB);

            if (positionResult != 0) {
              return positionResult;
            }

            // ==============================================
            // CREATED AT
            // ==============================================

            final createdA = _readDateTime(a['created_at']);

            final createdB = _readDateTime(b['created_at']);

            return createdB.compareTo(createdA);
          });

          return List<Map<String, dynamic>>.unmodifiable(filtered);
        });
  }

  // ============================================================
  // CONVERTER ROWS
  // ============================================================

  List<Map<String, dynamic>> _convertRows(dynamic response) {
    if (response is! List) {
      return const <Map<String, dynamic>>[];
    }

    return response
        .map((row) {
          return Map<String, dynamic>.from(row as Map);
        })
        .toList(growable: false);
  }

  // ============================================================
  // POSITION
  // ============================================================

  int _readPosition(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString().trim() ?? '') ?? 0;
  }

  // ============================================================
  // DATETIME
  // ============================================================

  DateTime _readDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    if (value != null) {
      final parsed = DateTime.tryParse(value.toString());

      if (parsed != null) {
        return parsed;
      }
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
