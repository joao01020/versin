import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// PUBLIC PROFILE REMOTE DATASOURCE
// ============================================================
//
// Comunicação REMOTA com o Supabase Postgres.
//
// Responsabilidades:
//
// PERFIL
//
// - buscar perfil;
// - atualizar perfil.
//
// TRACKS
//
// - buscar demos;
// - buscar primeira demo;
// - criar registro da demo;
// - atualizar registro;
// - acompanhar demos em realtime.
//
// IMPORTANTE:
//
// Os ARQUIVOS de áudio NÃO são responsabilidade deste arquivo.
//
// Arquivos:
//
// Flutter
//    ↓
// ProfileTrackService
//    ↓
// Supabase Edge Functions
//    ↓
// Cloudflare R2
//
// Banco:
//
// Flutter
//    ↓
// Repository
//    ↓
// Este Datasource
//    ↓
// Supabase Postgres
//
// ============================================================

abstract class PublicProfileRemoteDatasource {
  // ============================================================
  // PERFIL
  // ============================================================

  Future<
    Map<
      String,
      dynamic
    >?
  >
  getProfile({
    required String userId,
  });

  Future<
    Map<
      String,
      dynamic
    >
  >
  updateProfile({
    required String userId,
    required Map<
      String,
      dynamic
    >
    data,
  });

  // ============================================================
  // TRACKS
  // ============================================================

  Future<
    List<
      Map<
        String,
        dynamic
      >
    >
  >
  getTracks({
    required String userId,
    bool onlyActive = true,
  });

  // ============================================================
  // PRIMEIRA DEMO
  // ============================================================

  Future<
    Map<
      String,
      dynamic
    >?
  >
  getFirstTrack({
    required String userId,
    bool onlyActive = true,
  });

  // ============================================================
  // CRIAR TRACK
  // ============================================================

  Future<
    Map<
      String,
      dynamic
    >
  >
  createTrack({
    required Map<
      String,
      dynamic
    >
    data,
  });

  // ============================================================
  // ATUALIZAR TRACK
  // ============================================================

  Future<
    Map<
      String,
      dynamic
    >
  >
  updateTrack({
    required String trackId,
    required Map<
      String,
      dynamic
    >
    data,
  });

  // ============================================================
  // DELETE LEGADO
  // ============================================================
  //
  // Mantido para compatibilidade com o Repository.
  //
  // O fluxo normal NÃO deve chamar isso para excluir uma demo.
  //
  // A remoção real deve passar por:
  //
  // delete-profile-track
  //
  // que remove:
  //
  // - objeto do R2;
  // - linha do Postgres.
  //
  // ============================================================

  Future<
    void
  >
  deleteTrack({
    required String trackId,
  });

  // ============================================================
  // REALTIME
  // ============================================================

  Stream<
    List<
      Map<
        String,
        dynamic
      >
    >
  >
  watchTracks({
    required String userId,
  });
}

// ============================================================
// IMPLEMENTAÇÃO SUPABASE
// ============================================================

class PublicProfileRemoteDatasourceImpl
    implements
        PublicProfileRemoteDatasource {
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
  // CAMPOS
  // ============================================================

  static const String _profileFields = '''
    id,
    username,
    artist_name,
    name,
    avatar_url,
    bio,
    is_online,
    created_at,
    updated_at
  ''';

  static const String _trackFields = '''
    id,
    user_id,
    title,
    storage_path,
    audio_url,
    duration_seconds,
    mime_type,
    file_size_bytes,
    position,
    is_active,
    created_at,
    updated_at,
    audience_roles
  ''';

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  PublicProfileRemoteDatasourceImpl({
    SupabaseClient? supabase,
  }) : _supabase =
           supabase ??
           Supabase.instance.client;

  // ============================================================
  // BUSCAR PERFIL
  // ============================================================

  @override
  Future<
    Map<
      String,
      dynamic
    >?
  >
  getProfile({
    required String userId,
  }) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return null;
    }

    try {
      final response = await _supabase
          .from(
            _profilesTable,
          )
          .select(
            _profileFields,
          )
          .eq(
            'id',
            normalizedUserId,
          )
          .maybeSingle();

      if (response ==
          null) {
        return null;
      }

      return Map<
        String,
        dynamic
      >.from(
        response,
      );
    } on PostgrestException catch (
      error
    ) {
      _logPostgrestError(
        operation: 'carregar perfil',
        error: error,
      );

      rethrow;
    }
  }

  // ============================================================
  // ATUALIZAR PERFIL
  // ============================================================

  @override
  Future<
    Map<
      String,
      dynamic
    >
  >
  updateProfile({
    required String userId,
    required Map<
      String,
      dynamic
    >
    data,
  }) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      throw ArgumentError(
        'userId não pode ser vazio.',
      );
    }

    if (data.isEmpty) {
      throw ArgumentError(
        'Os dados do perfil não podem estar vazios.',
      );
    }

    try {
      final response = await _supabase
          .from(
            _profilesTable,
          )
          .update(
            data,
          )
          .eq(
            'id',
            normalizedUserId,
          )
          .select(
            _profileFields,
          )
          .single();

      return Map<
        String,
        dynamic
      >.from(
        response,
      );
    } on PostgrestException catch (
      error
    ) {
      _logPostgrestError(
        operation: 'atualizar perfil',
        error: error,
      );

      rethrow;
    }
  }

  // ============================================================
  // BUSCAR TRACKS
  // ============================================================

  @override
  Future<
    List<
      Map<
        String,
        dynamic
      >
    >
  >
  getTracks({
    required String userId,
    bool onlyActive = true,
  }) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return const <
        Map<
          String,
          dynamic
        >
      >[];
    }

    try {
      if (onlyActive) {
        final response = await _supabase
            .from(
              _tracksTable,
            )
            .select(
              _trackFields,
            )
            .eq(
              'user_id',
              normalizedUserId,
            )
            .eq(
              'is_active',
              true,
            )
            .order(
              'position',
              ascending: true,
            )
            .order(
              'created_at',
              ascending: false,
            );

        return _convertRows(
          response,
        );
      }

      final response = await _supabase
          .from(
            _tracksTable,
          )
          .select(
            _trackFields,
          )
          .eq(
            'user_id',
            normalizedUserId,
          )
          .order(
            'position',
            ascending: true,
          )
          .order(
            'created_at',
            ascending: false,
          );

      return _convertRows(
        response,
      );
    } on PostgrestException catch (
      error
    ) {
      _logPostgrestError(
        operation: 'carregar músicas',
        error: error,
      );

      rethrow;
    }
  }

  // ============================================================
  // PRIMEIRA DEMO
  // ============================================================
  //
  // Usado principalmente no Match:
  //
  // OUVIR DEMO
  //
  // Aqui buscamos somente os METADADOS.
  //
  // A URL de áudio será solicitada depois para:
  //
  // create-track-playback-url
  //
  // ============================================================

  @override
  Future<
    Map<
      String,
      dynamic
    >?
  >
  getFirstTrack({
    required String userId,
    bool onlyActive = true,
  }) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return null;
    }

    try {
      if (onlyActive) {
        final response = await _supabase
            .from(
              _tracksTable,
            )
            .select(
              _trackFields,
            )
            .eq(
              'user_id',
              normalizedUserId,
            )
            .eq(
              'is_active',
              true,
            )
            .order(
              'position',
              ascending: true,
            )
            .order(
              'created_at',
              ascending: false,
            )
            .limit(
              1,
            )
            .maybeSingle();

        if (response ==
            null) {
          debugPrint(
            '[PUBLIC PROFILE REMOTE] '
            'Usuário sem demo ativa: '
            '$normalizedUserId',
          );

          return null;
        }

        return Map<
          String,
          dynamic
        >.from(
          response,
        );
      }

      final response = await _supabase
          .from(
            _tracksTable,
          )
          .select(
            _trackFields,
          )
          .eq(
            'user_id',
            normalizedUserId,
          )
          .order(
            'position',
            ascending: true,
          )
          .order(
            'created_at',
            ascending: false,
          )
          .limit(
            1,
          )
          .maybeSingle();

      if (response ==
          null) {
        return null;
      }

      return Map<
        String,
        dynamic
      >.from(
        response,
      );
    } on PostgrestException catch (
      error
    ) {
      _logPostgrestError(
        operation: 'carregar primeira demo',
        error: error,
      );

      rethrow;
    }
  }

  // ============================================================
  // CRIAR TRACK
  // ============================================================
  //
  // O arquivo já deve ter sido enviado para o R2.
  //
  // storage_path contém:
  //
  // profiles/<user-id>/tracks/<uuid>.mp3
  //
  // ============================================================

  @override
  Future<
    Map<
      String,
      dynamic
    >
  >
  createTrack({
    required Map<
      String,
      dynamic
    >
    data,
  }) async {
    if (data.isEmpty) {
      throw ArgumentError(
        'Os dados da música não podem estar vazios.',
      );
    }

    final normalizedData = _normalizeTrackInsertData(
      data,
    );

    _validateTrackInsertData(
      normalizedData,
    );

    try {
      final response = await _supabase
          .from(
            _tracksTable,
          )
          .insert(
            normalizedData,
          )
          .select(
            _trackFields,
          )
          .single();

      debugPrint(
        '[PUBLIC PROFILE REMOTE] '
        'Registro da demo criado.',
      );

      return Map<
        String,
        dynamic
      >.from(
        response,
      );
    } on PostgrestException catch (
      error
    ) {
      _logPostgrestError(
        operation: 'criar música',
        error: error,
      );

      rethrow;
    }
  }

  // ============================================================
  // ATUALIZAR TRACK
  // ============================================================

  @override
  Future<
    Map<
      String,
      dynamic
    >
  >
  updateTrack({
    required String trackId,
    required Map<
      String,
      dynamic
    >
    data,
  }) async {
    final normalizedTrackId = trackId.trim();

    if (normalizedTrackId.isEmpty) {
      throw ArgumentError(
        'trackId não pode ser vazio.',
      );
    }

    if (data.isEmpty) {
      throw ArgumentError(
        'Os dados da música não podem estar vazios.',
      );
    }

    final normalizedData =
        Map<
          String,
          dynamic
        >.from(
          data,
        );

    // ==========================================================
    // CAMPOS IMUTÁVEIS
    // ==========================================================

    normalizedData.remove(
      'id',
    );

    normalizedData.remove(
      'user_id',
    );

    normalizedData.remove(
      'created_at',
    );

    // ==========================================================
    // AUDIO URL
    // ==========================================================
    //
    // Cloudflare R2 usa URL temporária.
    //
    // Não persistimos signed URLs.
    //
    // ==========================================================

    normalizedData.remove(
      'audio_url',
    );

    // ==========================================================
    // UPDATED AT
    // ==========================================================

    normalizedData['updated_at'] = DateTime.now().toUtc().toIso8601String();

    try {
      final response = await _supabase
          .from(
            _tracksTable,
          )
          .update(
            normalizedData,
          )
          .eq(
            'id',
            normalizedTrackId,
          )
          .select(
            _trackFields,
          )
          .single();

      return Map<
        String,
        dynamic
      >.from(
        response,
      );
    } on PostgrestException catch (
      error
    ) {
      _logPostgrestError(
        operation: 'atualizar música',
        error: error,
      );

      rethrow;
    }
  }

  // ============================================================
  // DELETE LEGADO
  // ============================================================
  //
  // NÃO usar no fluxo normal do aplicativo.
  //
  // PublicProfileController deve usar:
  //
  // ProfileTrackService.deleteTrack(trackId: ...)
  //
  // que chama:
  //
  // delete-profile-track
  //
  // ============================================================

  @override
  Future<
    void
  >
  deleteTrack({
    required String trackId,
  }) async {
    final normalizedTrackId = trackId.trim();

    if (normalizedTrackId.isEmpty) {
      return;
    }

    debugPrint(
      '[PUBLIC PROFILE REMOTE] '
      'AVISO: deleteTrack() legado chamado. '
      'Prefira delete-profile-track.',
    );

    try {
      await _supabase
          .from(
            _tracksTable,
          )
          .delete()
          .eq(
            'id',
            normalizedTrackId,
          );
    } on PostgrestException catch (
      error
    ) {
      _logPostgrestError(
        operation: 'excluir registro da música',
        error: error,
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
      Map<
        String,
        dynamic
      >
    >
  >
  watchTracks({
    required String userId,
  }) {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return Stream<
        List<
          Map<
            String,
            dynamic
          >
        >
      >.value(
        const <
          Map<
            String,
            dynamic
          >
        >[],
      );
    }

    return _supabase
        .from(
          _tracksTable,
        )
        .stream(
          primaryKey: [
            'id',
          ],
        )
        .eq(
          'user_id',
          normalizedUserId,
        )
        .map(
          (
            rows,
          ) {
            final filtered = rows
                .where(
                  (
                    row,
                  ) {
                    return row['is_active'] !=
                        false;
                  },
                )
                .map(
                  (
                    row,
                  ) {
                    return Map<
                      String,
                      dynamic
                    >.from(
                      row,
                    );
                  },
                )
                .toList();

            filtered.sort(
              (
                a,
                b,
              ) {
                // ==============================================
                // POSITION
                // ==============================================

                final positionA = _readPosition(
                  a['position'],
                );

                final positionB = _readPosition(
                  b['position'],
                );

                final positionResult = positionA.compareTo(
                  positionB,
                );

                if (positionResult !=
                    0) {
                  return positionResult;
                }

                // ==============================================
                // CREATED AT
                // ==============================================

                final createdA = _readDateTime(
                  a['created_at'],
                );

                final createdB = _readDateTime(
                  b['created_at'],
                );

                return createdB.compareTo(
                  createdA,
                );
              },
            );

            return List<
              Map<
                String,
                dynamic
              >
            >.unmodifiable(
              filtered,
            );
          },
        );
  }

  // ============================================================
  // NORMALIZAR INSERT
  // ============================================================

  Map<
    String,
    dynamic
  >
  _normalizeTrackInsertData(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    final normalized =
        Map<
          String,
          dynamic
        >.from(
          data,
        );

    // ==========================================================
    // ID
    // ==========================================================

    final id = normalized['id']?.toString().trim();

    if (id ==
            null ||
        id.isEmpty) {
      normalized.remove(
        'id',
      );
    }

    // ==========================================================
    // AUDIO URL
    // ==========================================================
    //
    // Não armazenamos URL assinada do R2.
    //
    // ==========================================================

    normalized.remove(
      'audio_url',
    );

    // ==========================================================
    // DATAS
    // ==========================================================

    normalized.remove(
      'created_at',
    );

    normalized.remove(
      'updated_at',
    );

    // ==========================================================
    // STRINGS
    // ==========================================================

    normalized['user_id'] = normalized['user_id']?.toString().trim();

    normalized['title'] = normalized['title']?.toString().trim();

    normalized['storage_path'] = normalized['storage_path']?.toString().trim();

    if (normalized.containsKey(
      'mime_type',
    )) {
      normalized['mime_type'] = _nullableString(
        normalized['mime_type'],
      );
    }

    // ==========================================================
    // AUDIENCE ROLES
    // ==========================================================

    normalized['audience_roles'] = _normalizeAudienceRoles(
      normalized['audience_roles'],
    );

    return normalized;
  }

  // ============================================================
  // VALIDAR INSERT
  // ============================================================

  void _validateTrackInsertData(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    final userId =
        data['user_id']?.toString().trim() ??
        '';

    final title =
        data['title']?.toString().trim() ??
        '';

    final storagePath =
        data['storage_path']?.toString().trim() ??
        '';

    final audienceRoles = data['audience_roles'];

    if (userId.isEmpty) {
      throw ArgumentError(
        'user_id não pode ser vazio.',
      );
    }

    if (title.isEmpty) {
      throw ArgumentError(
        'title não pode ser vazio.',
      );
    }

    if (storagePath.isEmpty) {
      throw ArgumentError(
        'storage_path não pode ser vazio.',
      );
    }

    if (audienceRoles
            is! List ||
        audienceRoles.isEmpty) {
      throw ArgumentError(
        'audience_roles precisa possuir '
        'pelo menos um grupo.',
      );
    }
  }

  // ============================================================
  // AUDIENCE ROLES
  // ============================================================

  List<
    String
  >
  _normalizeAudienceRoles(
    dynamic value,
  ) {
    if (value
        is! Iterable) {
      return const <
        String
      >[];
    }

    final roles = value
        .map(
          (
            role,
          ) {
            return role.toString().trim().toLowerCase().replaceAll(
              ' ',
              '_',
            );
          },
        )
        .where(
          (
            role,
          ) {
            return role.isNotEmpty;
          },
        )
        .toSet()
        .toList();

    roles.sort();

    return List<
      String
    >.unmodifiable(
      roles,
    );
  }

  // ============================================================
  // CONVERTER ROWS
  // ============================================================

  List<
    Map<
      String,
      dynamic
    >
  >
  _convertRows(
    dynamic response,
  ) {
    if (response
        is! List) {
      return const <
        Map<
          String,
          dynamic
        >
      >[];
    }

    return response
        .map(
          (
            row,
          ) {
            return Map<
              String,
              dynamic
            >.from(
              row
                  as Map,
            );
          },
        )
        .toList(
          growable: false,
        );
  }

  // ============================================================
  // NULLABLE STRING
  // ============================================================

  String? _nullableString(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    final normalized = value.toString().trim();

    return normalized.isEmpty
        ? null
        : normalized;
  }

  // ============================================================
  // POSITION
  // ============================================================

  int _readPosition(
    dynamic value,
  ) {
    if (value
        is int) {
      return value;
    }

    if (value
        is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString().trim() ??
              '',
        ) ??
        0;
  }

  // ============================================================
  // DATETIME
  // ============================================================

  DateTime _readDateTime(
    dynamic value,
  ) {
    if (value
        is DateTime) {
      return value;
    }

    if (value !=
        null) {
      final parsed = DateTime.tryParse(
        value.toString(),
      );

      if (parsed !=
          null) {
        return parsed;
      }
    }

    return DateTime.fromMillisecondsSinceEpoch(
      0,
    );
  }

  // ============================================================
  // LOG POSTGREST
  // ============================================================

  void _logPostgrestError({
    required String operation,
    required PostgrestException error,
  }) {
    debugPrint(
      '[PUBLIC PROFILE REMOTE] '
      'Erro ao $operation: '
      '${error.message}',
    );

    if (error.code !=
        null) {
      debugPrint(
        '[PUBLIC PROFILE REMOTE] '
        'Code: '
        '${error.code}',
      );
    }

    if (error.details !=
        null) {
      debugPrint(
        '[PUBLIC PROFILE REMOTE] '
        'Details: '
        '${error.details}',
      );
    }

    if (error.hint !=
        null) {
      debugPrint(
        '[PUBLIC PROFILE REMOTE] '
        'Hint: '
        '${error.hint}',
      );
    }
  }
}
