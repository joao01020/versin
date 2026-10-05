import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/stored_work_model.dart';
import '../../services/storage_hash_service.dart';
import 'storage_repository.dart';

// ============================================================
// SUPABASE STORAGE REPOSITORY
// ============================================================
//
// Responsável pela persistência permanente de:
//
// - letras;
// - metadados de beats;
// - hashes;
// - autoria;
// - propriedade;
// - integridade;
// - histórico através da RPC de transferência.
//
// Arquivos físicos de beat NÃO são enviados por este repository.
//
// Beat:
// arquivo -> Cloudflare R2
// metadados -> stored_works
//
// Letra:
// conteúdo -> stored_works.lyrics_content
//
// ============================================================

class SupabaseStorageRepository
    implements
        StorageRepository {
  // ==========================================================
  // CONFIGURAÇÃO
  // ==========================================================

  static const String _table = 'stored_works';

  static const String _transferRpc = 'transfer_work';

  // ==========================================================
  // DEPENDÊNCIAS
  // ==========================================================

  final SupabaseClient _supabase;

  final StorageHashService _hashService;

  // ==========================================================
  // CONSTRUTOR
  // ==========================================================

  SupabaseStorageRepository({
    SupabaseClient? supabase,
    StorageHashService? hashService,
  }) : _supabase =
           supabase ??
           Supabase.instance.client,
       _hashService =
           hashService ??
           StorageHashService();

  // ==========================================================
  // USUÁRIO ATUAL
  // ==========================================================

  String? get currentUserId {
    final userId = _supabase.auth.currentUser?.id.trim();

    if (userId ==
            null ||
        userId.isEmpty) {
      return null;
    }

    return userId;
  }

  // ==========================================================
  // LISTAR OBRAS
  // ==========================================================

  @override
  Future<
    List<
      StoredWorkModel
    >
  >
  getWorks({
    required String userId,
  }) async {
    final normalizedUserId = _requireRequestedCurrentUserId(
      userId,
      fieldName: 'userId',
    );

    final response = await _supabase
        .from(
          _table,
        )
        .select()
        .eq(
          'owner_user_id',
          normalizedUserId,
        )
        .order(
          'created_at',
          ascending: false,
        );

    return _mapList(
      response,
    );
  }

  // ==========================================================
  // OBRA POR ID
  // ==========================================================

  @override
  Future<
    StoredWorkModel?
  >
  getWorkById({
    required String workId,
  }) async {
    final normalizedWorkId = _required(
      workId,
      'workId',
    );

    final userId = _requireCurrentUserId();

    final response = await _supabase
        .from(
          _table,
        )
        .select()
        .eq(
          'id',
          normalizedWorkId,
        )
        .eq(
          'owner_user_id',
          userId,
        )
        .maybeSingle();

    if (response ==
        null) {
      return null;
    }

    return _mapWork(
      response,
    );
  }

  // ==========================================================
  // OBRA POR HASH
  // ==========================================================

  @override
  Future<
    StoredWorkModel?
  >
  getWorkByHash({
    required String contentHash,
  }) async {
    final hash = _normalizeAndValidateHash(
      contentHash,
    );

    final userId = _requireCurrentUserId();

    final response = await _supabase
        .from(
          _table,
        )
        .select()
        .eq(
          'content_hash',
          hash,
        )
        .eq(
          'owner_user_id',
          userId,
        )
        .maybeSingle();

    if (response ==
        null) {
      return null;
    }

    return _mapWork(
      response,
    );
  }

  // ==========================================================
  // LETRAS
  // ==========================================================

  @override
  Future<
    List<
      StoredWorkModel
    >
  >
  getLyrics({
    required String userId,
  }) {
    return _getByType(
      userId: userId,
      type: StoredWorkType.lyrics,
    );
  }

  // ==========================================================
  // BEATS
  // ==========================================================

  @override
  Future<
    List<
      StoredWorkModel
    >
  >
  getBeats({
    required String userId,
  }) {
    return _getByType(
      userId: userId,
      type: StoredWorkType.beat,
    );
  }

  // ==========================================================
  // FILTRAR POR TIPO
  // ==========================================================

  Future<
    List<
      StoredWorkModel
    >
  >
  _getByType({
    required String userId,
    required StoredWorkType type,
  }) async {
    final normalizedUserId = _requireRequestedCurrentUserId(
      userId,
      fieldName: 'userId',
    );

    final response = await _supabase
        .from(
          _table,
        )
        .select()
        .eq(
          'owner_user_id',
          normalizedUserId,
        )
        .eq(
          'type',
          StoredWorkModel.typeToString(
            type,
          ),
        )
        .order(
          'created_at',
          ascending: false,
        );

    return _mapList(
      response,
    );
  }

  // ==========================================================
  // SALVAR OBRA
  // ==========================================================

  @override
  Future<
    StoredWorkModel
  >
  saveWork(
    StoredWorkModel work,
  ) async {
    // ========================================================
    // AUTENTICAÇÃO / PROPRIEDADE
    // ========================================================

    _validateOwner(
      work,
    );

    final currentUserId = _requireCurrentUserId();

    // ========================================================
    // VALIDAR OBRA
    // ========================================================

    _validateWork(
      work,
    );

    // ========================================================
    // NORMALIZAR HASH
    // ========================================================

    final normalizedWork = work.copyWith(
      ownerUserId: currentUserId,
      contentHash: _normalizeAndValidateHash(
        work.contentHash,
      ),
      hashAlgorithm: StorageHashService.algorithm,
    );

    // ========================================================
    // INSERT
    // ========================================================

    final response = await _supabase
        .from(
          _table,
        )
        .insert(
          normalizedWork.toMap(),
        )
        .select()
        .single();

    return _mapWork(
      response,
    );
  }

  // ==========================================================
  // ATUALIZAR OBRA
  // ==========================================================

  @override
  Future<
    StoredWorkModel
  >
  updateWork(
    StoredWorkModel work,
  ) async {
    // ========================================================
    // AUTENTICAÇÃO / PROPRIEDADE
    // ========================================================

    _validateOwner(
      work,
    );

    final currentUserId = _requireCurrentUserId();

    // ========================================================
    // VALIDAR OBRA
    // ========================================================

    _validateWork(
      work,
    );

    // ========================================================
    // NORMALIZAR HASH
    // ========================================================

    final normalizedWork = work.copyWith(
      ownerUserId: currentUserId,
      contentHash: _normalizeAndValidateHash(
        work.contentHash,
      ),
      hashAlgorithm: StorageHashService.algorithm,
      updatedAt: DateTime.now().toUtc(),
    );

    // ========================================================
    // MAP
    // ========================================================

    final data =
        Map<
            String,
            dynamic
          >.from(
            normalizedWork.toMap(),
          )
          ..remove(
            'id',
          )
          ..remove(
            'created_at',
          )
          ..remove(
            'original_author_user_id',
          );

    // ========================================================
    // UPDATE
    // ========================================================
    //
    // Também filtramos owner_user_id pelo usuário atual.
    //
    // Mesmo com RLS, esta proteção deixa a intenção explícita.
    //
    // ========================================================

    final response = await _supabase
        .from(
          _table,
        )
        .update(
          data,
        )
        .eq(
          'id',
          normalizedWork.id,
        )
        .eq(
          'owner_user_id',
          _requireCurrentUserId(),
        )
        .select()
        .single();

    return _mapWork(
      response,
    );
  }

  // ==========================================================
  // EXCLUIR OBRA
  // ==========================================================

  @override
  Future<
    void
  >
  deleteWork({
    required String workId,
  }) async {
    final normalizedWorkId = _required(
      workId,
      'workId',
    );

    final userId = _requireCurrentUserId();

    await _supabase
        .from(
          _table,
        )
        .delete()
        .eq(
          'id',
          normalizedWorkId,
        )
        .eq(
          'owner_user_id',
          userId,
        );
  }

  // ==========================================================
  // TRANSFERIR PROPRIEDADE
  // ==========================================================

  @override
  Future<
    StoredWorkModel
  >
  transferWork({
    required String workId,
    required String toUserId,
    String? note,
  }) async {
    final normalizedWorkId = _required(
      workId,
      'workId',
    );

    final normalizedToUserId = _required(
      toUserId,
      'toUserId',
    );

    final currentUser = _requireCurrentUserId();

    // ========================================================
    // NÃO TRANSFERIR PARA SI MESMO
    // ========================================================

    if (currentUser ==
        normalizedToUserId) {
      throw StateError(
        'Não é possível transferir uma obra para o próprio proprietário.',
      );
    }

    // ========================================================
    // OBRA ATUAL
    // ========================================================

    final currentWork = await getWorkById(
      workId: normalizedWorkId,
    );

    if (currentWork ==
        null) {
      throw StateError(
        'Obra não encontrada: $normalizedWorkId',
      );
    }

    // ========================================================
    // VALIDAR DONO ATUAL
    // ========================================================

    if (currentWork.ownerUserId !=
        currentUser) {
      throw StateError(
        'A obra não pertence ao usuário autenticado.',
      );
    }

    // ========================================================
    // RPC
    // ========================================================

    await _supabase.rpc(
      _transferRpc,
      params: {
        'p_work_id': normalizedWorkId,
        'p_to_user_id': normalizedToUserId,
        'p_note': _nullable(
          note,
        ),
      },
    );

    // ========================================================
    // RETORNO LOCAL
    // ========================================================
    //
    // Depois da transferência a RLS pode impedir o usuário
    // anterior de consultar a obra novamente.
    //
    // Por isso atualizamos localmente ownerUserId.
    //
    // contentHash permanece exatamente o mesmo.
    //
    // ========================================================

    return currentWork.copyWith(
      ownerUserId: normalizedToUserId,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  // ==========================================================
  // HASH EXISTE
  // ==========================================================

  @override
  Future<
    bool
  >
  hashExists({
    required String contentHash,
  }) async {
    final hash = _normalizeAndValidateHash(
      contentHash,
    );

    final userId = _requireCurrentUserId();

    final response = await _supabase
        .from(
          _table,
        )
        .select(
          'id',
        )
        .eq(
          'content_hash',
          hash,
        )
        .eq(
          'owner_user_id',
          userId,
        )
        .limit(
          1,
        );

    return response.isNotEmpty;
  }

  // ==========================================================
  // CONTAR OBRAS
  // ==========================================================

  @override
  Future<
    int
  >
  countWorks({
    required String userId,
  }) async {
    final works = await getWorks(
      userId: userId,
    );

    return works.length;
  }

  // ==========================================================
  // CONTAR LETRAS
  // ==========================================================

  @override
  Future<
    int
  >
  countLyrics({
    required String userId,
  }) async {
    final works = await getLyrics(
      userId: userId,
    );

    return works.length;
  }

  // ==========================================================
  // CONTAR BEATS
  // ==========================================================

  @override
  Future<
    int
  >
  countBeats({
    required String userId,
  }) async {
    final works = await getBeats(
      userId: userId,
    );

    return works.length;
  }

  // ==========================================================
  // CONTAR VERIFICADAS
  // ==========================================================

  @override
  Future<
    int
  >
  countVerifiedWorks({
    required String userId,
  }) async {
    final works = await getWorks(
      userId: userId,
    );

    return works
        .where(
          (
            work,
          ) => work.integrityVerified,
        )
        .length;
  }

  // ==========================================================
  // VALIDAR OBRA
  // ==========================================================

  void _validateWork(
    StoredWorkModel work,
  ) {
    // ========================================================
    // ID
    // ========================================================

    _required(
      work.id,
      'work.id',
    );

    // ========================================================
    // TÍTULO
    // ========================================================

    _required(
      work.title,
      'work.title',
    );

    // ========================================================
    // AUTOR ORIGINAL
    // ========================================================

    _required(
      work.originalAuthorUserId,
      'work.originalAuthorUserId',
    );

    // ========================================================
    // PROPRIETÁRIO
    // ========================================================

    _required(
      work.ownerUserId,
      'work.ownerUserId',
    );

    // ========================================================
    // HASH
    // ========================================================

    _normalizeAndValidateHash(
      work.contentHash,
    );

    // ========================================================
    // ALGORITMO
    // ========================================================

    if (work.hashAlgorithm.trim().toUpperCase() !=
        StorageHashService.algorithm) {
      throw ArgumentError(
        'A obra precisa utilizar ${StorageHashService.algorithm}.',
      );
    }

    // ========================================================
    // LETRA
    // ========================================================

    if (work.type ==
        StoredWorkType.lyrics) {
      final lyrics = work.lyricsContent?.trim();

      if (lyrics ==
              null ||
          lyrics.isEmpty) {
        throw ArgumentError(
          'Uma obra do tipo lyrics precisa possuir lyricsContent.',
        );
      }
    }

    // ========================================================
    // BEAT
    // ========================================================
    //
    // No momento do upload o filePath pode ser preenchido pelo
    // WorkStorageService depois que o R2 retorna o objectKey.
    //
    // Quando chega ao repository para persistência, ele deve
    // possuir filePath.
    //
    // ========================================================

    if (work.type ==
        StoredWorkType.beat) {
      final filePath = work.filePath?.trim();

      final fileName = work.fileName?.trim();

      if (filePath ==
              null ||
          filePath.isEmpty) {
        throw ArgumentError(
          'Uma obra do tipo beat precisa possuir filePath do R2.',
        );
      }

      if (fileName ==
              null ||
          fileName.isEmpty) {
        throw ArgumentError(
          'Uma obra do tipo beat precisa possuir fileName.',
        );
      }

      if (work.fileSizeBytes ==
              null ||
          work.fileSizeBytes! <=
              0) {
        throw ArgumentError(
          'Uma obra do tipo beat precisa possuir fileSizeBytes válido.',
        );
      }
    }

    // ========================================================
    // BPM
    // ========================================================

    final bpm = work.bpm;

    if (bpm !=
            null &&
        (bpm <=
                0 ||
            bpm >
                400)) {
      throw ArgumentError(
        'BPM inválido. Use um valor entre 1 e 400.',
      );
    }
  }

  // ==========================================================
  // VALIDAR OWNER
  // ==========================================================

  void _validateOwner(
    StoredWorkModel work,
  ) {
    final currentUserId = _requireCurrentUserId();

    if (work.ownerUserId !=
        currentUserId) {
      throw StateError(
        'ownerUserId precisa ser o usuário autenticado.',
      );
    }
  }

  // ==========================================================
  // USUÁRIO ATUAL OBRIGATÓRIO
  // ==========================================================

  String _requireCurrentUserId() {
    final current = _supabase.auth.currentUser?.id.trim();

    if (current ==
            null ||
        current.isEmpty) {
      throw StateError(
        'Usuário não autenticado.',
      );
    }

    return current;
  }

  // ==========================================================
  // VALIDAR USUÁRIO SOLICITADO
  // ==========================================================
  //
  // Métodos públicos que recebem userId só podem consultar a
  // própria conta autenticada.
  //
  // Isso evita:
  //
  // getWorks(userId: UUID_DE_OUTRA_CONTA)
  //
  // mesmo que uma policy RLS seja alterada incorretamente no
  // futuro.
  //
  // ==========================================================

  String _requireRequestedCurrentUserId(
    String userId, {
    required String fieldName,
  }) {
    final requestedUserId = _required(
      userId,
      fieldName,
    );

    final authenticatedUserId = _requireCurrentUserId();

    if (requestedUserId !=
        authenticatedUserId) {
      throw StateError(
        '$fieldName não corresponde ao usuário autenticado.',
      );
    }

    return authenticatedUserId;
  }

  // ==========================================================
  // NORMALIZAR + VALIDAR HASH
  // ==========================================================

  String _normalizeAndValidateHash(
    String value,
  ) {
    return _hashService.requireValidSha256(
      value,
      fieldName: 'contentHash',
    );
  }

  // ==========================================================
  // MAPEAR UMA OBRA
  // ==========================================================

  StoredWorkModel _mapWork(
    Map<
      String,
      dynamic
    >
    response,
  ) {
    final work = StoredWorkModel.fromMap(
      Map<
        String,
        dynamic
      >.from(
        response,
      ),
    );

    // ========================================================
    // VALIDAR HASH VINDO DO BANCO
    // ========================================================

    _normalizeAndValidateHash(
      work.contentHash,
    );

    return work;
  }

  // ==========================================================
  // MAPEAR LISTA
  // ==========================================================

  List<
    StoredWorkModel
  >
  _mapList(
    List<
      dynamic
    >
    response,
  ) {
    return response
        .map(
          (
            item,
          ) => _mapWork(
            Map<
              String,
              dynamic
            >.from(
              item
                  as Map,
            ),
          ),
        )
        .toList(
          growable: false,
        );
  }

  // ==========================================================
  // STRING OBRIGATÓRIA
  // ==========================================================

  String _required(
    String value,
    String field,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError(
        '$field não pode ser vazio.',
      );
    }

    return normalized;
  }

  // ==========================================================
  // STRING OPCIONAL
  // ==========================================================

  String? _nullable(
    String? value,
  ) {
    final normalized = value?.trim();

    if (normalized ==
            null ||
        normalized.isEmpty) {
      return null;
    }

    return normalized;
  }
}
