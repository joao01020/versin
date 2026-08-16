import '../models/stored_work_model.dart';

// ============================================================
// STORAGE REPOSITORY
// ============================================================
//
// Contrato responsável por persistir e consultar obras.
//
// O controller não precisa saber se os dados vêm de:
//
// - memória;
// - SQLite;
// - Supabase;
// - API;
// - outro backend.
//
// Isso permite trocar a implementação sem alterar
// a lógica da interface.
//
// ============================================================

abstract class StorageRepository {
  // ==========================================================
  // LISTAR TODAS AS OBRAS DO USUÁRIO
  // ==========================================================

  Future<
    List<
      StoredWorkModel
    >
  >
  getWorks({
    required String userId,
  });

  // ==========================================================
  // BUSCAR OBRA POR ID
  // ==========================================================

  Future<
    StoredWorkModel?
  >
  getWorkById({
    required String workId,
  });

  // ==========================================================
  // BUSCAR OBRA POR HASH
  // ==========================================================

  Future<
    StoredWorkModel?
  >
  getWorkByHash({
    required String contentHash,
  });

  // ==========================================================
  // LISTAR LETRAS
  // ==========================================================

  Future<
    List<
      StoredWorkModel
    >
  >
  getLyrics({
    required String userId,
  });

  // ==========================================================
  // LISTAR BEATS
  // ==========================================================

  Future<
    List<
      StoredWorkModel
    >
  >
  getBeats({
    required String userId,
  });

  // ==========================================================
  // SALVAR OBRA
  // ==========================================================

  Future<
    StoredWorkModel
  >
  saveWork(
    StoredWorkModel work,
  );

  // ==========================================================
  // ATUALIZAR OBRA
  // ==========================================================

  Future<
    StoredWorkModel
  >
  updateWork(
    StoredWorkModel work,
  );

  // ==========================================================
  // REMOVER OBRA
  // ==========================================================

  Future<
    void
  >
  deleteWork({
    required String workId,
  });

  // ==========================================================
  // TRANSFERIR AUTORIA / PROPRIEDADE
  // ==========================================================
  //
  // originalAuthorUserId permanece inalterado.
  //
  // Somente ownerUserId deve ser atualizado.
  //
  // Em implementações remotas, este método poderá chamar uma
  // RPC segura no backend, por exemplo:
  //
  // transfer_work(
  //   p_work_id,
  //   p_to_user_id,
  //   p_note
  // )
  //
  // ==========================================================

  Future<
    StoredWorkModel
  >
  transferWork({
    required String workId,
    required String toUserId,
    String? note,
  });

  // ==========================================================
  // VERIFICAR EXISTÊNCIA DO HASH
  // ==========================================================

  Future<
    bool
  >
  hashExists({
    required String contentHash,
  });

  // ==========================================================
  // CONTAGEM TOTAL
  // ==========================================================

  Future<
    int
  >
  countWorks({
    required String userId,
  });

  // ==========================================================
  // CONTAGEM DE LETRAS
  // ==========================================================

  Future<
    int
  >
  countLyrics({
    required String userId,
  });

  // ==========================================================
  // CONTAGEM DE BEATS
  // ==========================================================

  Future<
    int
  >
  countBeats({
    required String userId,
  });

  // ==========================================================
  // CONTAGEM DE OBRAS ÍNTEGRAS
  // ==========================================================

  Future<
    int
  >
  countVerifiedWorks({
    required String userId,
  });
}

// ============================================================
// IN-MEMORY STORAGE REPOSITORY
// ============================================================
//
// Implementação inicial.
//
// Começa completamente vazia.
//
// Depois podemos substituir por:
//
// SupabaseStorageRepository
// SqliteStorageRepository
// ApiStorageRepository
//
// sem alterar StorageController.
//
// ============================================================

class InMemoryStorageRepository
    implements
        StorageRepository {
  // ==========================================================
  // BANCO EM MEMÓRIA
  // ==========================================================

  final List<
    StoredWorkModel
  >
  _works = [];

  // ==========================================================
  // LISTAR TODAS
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
    final normalizedUserId = _normalizeRequiredString(
      userId,
      fieldName: 'userId',
    );

    final result = _works
        .where(
          (
            work,
          ) =>
              work.ownerUserId ==
              normalizedUserId,
        )
        .toList();

    result.sort(
      (
        a,
        b,
      ) => b.createdAt.compareTo(
        a.createdAt,
      ),
    );

    return List.unmodifiable(
      result,
    );
  }

  // ==========================================================
  // BUSCAR POR ID
  // ==========================================================

  @override
  Future<
    StoredWorkModel?
  >
  getWorkById({
    required String workId,
  }) async {
    final normalizedWorkId = _normalizeRequiredString(
      workId,
      fieldName: 'workId',
    );

    for (final work in _works) {
      if (work.id ==
          normalizedWorkId) {
        return work;
      }
    }

    return null;
  }

  // ==========================================================
  // BUSCAR POR HASH
  // ==========================================================

  @override
  Future<
    StoredWorkModel?
  >
  getWorkByHash({
    required String contentHash,
  }) async {
    final normalizedHash = _normalizeHash(
      contentHash,
    );

    for (final work in _works) {
      if (work.contentHash.toLowerCase() ==
          normalizedHash) {
        return work;
      }
    }

    return null;
  }

  // ==========================================================
  // LISTAR LETRAS
  // ==========================================================

  @override
  Future<
    List<
      StoredWorkModel
    >
  >
  getLyrics({
    required String userId,
  }) async {
    final works = await getWorks(
      userId: userId,
    );

    return List.unmodifiable(
      works.where(
        (
          work,
        ) =>
            work.type ==
            StoredWorkType.lyrics,
      ),
    );
  }

  // ==========================================================
  // LISTAR BEATS
  // ==========================================================

  @override
  Future<
    List<
      StoredWorkModel
    >
  >
  getBeats({
    required String userId,
  }) async {
    final works = await getWorks(
      userId: userId,
    );

    return List.unmodifiable(
      works.where(
        (
          work,
        ) =>
            work.type ==
            StoredWorkType.beat,
      ),
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
    _validateWork(
      work,
    );

    final idAlreadyExists = _works.any(
      (
        storedWork,
      ) =>
          storedWork.id ==
          work.id,
    );

    if (idAlreadyExists) {
      throw StateError(
        'Já existe uma obra com o ID ${work.id}.',
      );
    }

    final hashAlreadyExists = await hashExists(
      contentHash: work.contentHash,
    );

    if (hashAlreadyExists) {
      throw StateError(
        'Já existe uma obra registrada com esse hash.',
      );
    }

    _works.add(
      work,
    );

    return work;
  }

  // ==========================================================
  // ATUALIZAR OBRA
  // ==========================================================
  //
  // Será útil principalmente para:
  //
  // - atualizar proprietário;
  // - marcar integridade;
  // - ajustar metadados.
  //
  // Uma nova versão da obra NÃO deve sobrescrever
  // uma versão antiga.
  //
  // ==========================================================

  @override
  Future<
    StoredWorkModel
  >
  updateWork(
    StoredWorkModel work,
  ) async {
    _validateWork(
      work,
    );

    final index = _works.indexWhere(
      (
        storedWork,
      ) =>
          storedWork.id ==
          work.id,
    );

    if (index ==
        -1) {
      throw StateError(
        'Obra não encontrada: ${work.id}',
      );
    }

    final conflictingHash = _works.any(
      (
        storedWork,
      ) =>
          storedWork.id !=
              work.id &&
          storedWork.contentHash.toLowerCase() ==
              work.contentHash.toLowerCase(),
    );

    if (conflictingHash) {
      throw StateError(
        'Já existe outra obra registrada com esse hash.',
      );
    }

    _works[index] = work;

    return work;
  }

  // ==========================================================
  // REMOVER OBRA
  // ==========================================================
  //
  // Remove uma obra pelo ID.
  //
  // Se o ID não existir, lança StateError.
  //
  // Isso permite que o StorageController saiba se a remoção
  // realmente aconteceu e mostre feedback correto na interface.
  //
  // ==========================================================

  @override
  Future<
    void
  >
  deleteWork({
    required String workId,
  }) async {
    final normalizedWorkId = _normalizeRequiredString(
      workId,
      fieldName: 'workId',
    );

    // ========================================================
    // LOCALIZAR OBRA
    // ========================================================

    final index = _works.indexWhere(
      (
        work,
      ) =>
          work.id ==
          normalizedWorkId,
    );

    // ========================================================
    // NÃO ENCONTRADA
    // ========================================================

    if (index ==
        -1) {
      throw StateError(
        'Obra não encontrada: $normalizedWorkId',
      );
    }

    // ========================================================
    // REMOVER
    // ========================================================

    _works.removeAt(
      index,
    );
  }

  // ==========================================================
  // TRANSFERIR AUTORIA / PROPRIEDADE
  // ==========================================================
  //
  // Implementação em memória.
  //
  // Observação:
  // - note não é persistida nesta implementação simples;
  // - originalAuthorUserId é preservado;
  // - ownerUserId recebe o novo usuário;
  // - updatedAt é atualizado.
  //
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
    final normalizedWorkId = _normalizeRequiredString(
      workId,
      fieldName: 'workId',
    );

    final normalizedToUserId = _normalizeRequiredString(
      toUserId,
      fieldName: 'toUserId',
    );

    final index = _works.indexWhere(
      (
        work,
      ) =>
          work.id ==
          normalizedWorkId,
    );

    if (index ==
        -1) {
      throw StateError(
        'Obra não encontrada: $normalizedWorkId',
      );
    }

    final currentWork = _works[index];

    if (currentWork.ownerUserId ==
        normalizedToUserId) {
      throw StateError(
        'Esse usuário já é o proprietário atual da obra.',
      );
    }

    final updatedWork = currentWork.copyWith(
      ownerUserId: normalizedToUserId,
      updatedAt: DateTime.now().toUtc(),
    );

    _validateWork(
      updatedWork,
    );

    _works[index] = updatedWork;

    return updatedWork;
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
    final normalizedHash = _normalizeHash(
      contentHash,
    );

    return _works.any(
      (
        work,
      ) =>
          work.contentHash.toLowerCase() ==
          normalizedHash,
    );
  }

  // ==========================================================
  // CONTAR TODAS
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
  // CONTAR ÍNTEGROS
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
  // LIMPAR BANCO EM MEMÓRIA
  // ==========================================================
  //
  // Útil durante desenvolvimento e testes.
  //
  // ==========================================================

  Future<
    void
  >
  clear() async {
    _works.clear();
  }

  // ==========================================================
  // VALIDAR OBRA
  // ==========================================================

  void _validateWork(
    StoredWorkModel work,
  ) {
    _normalizeRequiredString(
      work.id,
      fieldName: 'id',
    );

    _normalizeRequiredString(
      work.originalAuthorUserId,
      fieldName: 'originalAuthorUserId',
    );

    _normalizeRequiredString(
      work.ownerUserId,
      fieldName: 'ownerUserId',
    );

    _normalizeRequiredString(
      work.title,
      fieldName: 'title',
    );

    _normalizeHash(
      work.contentHash,
    );

    _normalizeRequiredString(
      work.hashAlgorithm,
      fieldName: 'hashAlgorithm',
    );

    if (work.version <=
        0) {
      throw ArgumentError(
        'A versão da obra deve ser maior que zero.',
      );
    }

    // ========================================================
    // LETRA
    // ========================================================

    if (work.type ==
        StoredWorkType.lyrics) {
      final content = work.lyricsContent?.trim();

      if (content ==
              null ||
          content.isEmpty) {
        throw ArgumentError(
          'Uma letra precisa possuir conteúdo.',
        );
      }
    }

    // ========================================================
    // BEAT
    // ========================================================

    if (work.type ==
        StoredWorkType.beat) {
      final path = work.filePath?.trim();

      if (path ==
              null ||
          path.isEmpty) {
        throw ArgumentError(
          'Um beat precisa possuir um arquivo.',
        );
      }
    }
  }

  // ==========================================================
  // NORMALIZAR STRING OBRIGATÓRIA
  // ==========================================================

  String _normalizeRequiredString(
    String value, {
    required String fieldName,
  }) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError(
        '$fieldName não pode ser vazio.',
      );
    }

    return normalized;
  }

  // ==========================================================
  // NORMALIZAR HASH
  // ==========================================================

  String _normalizeHash(
    String value,
  ) {
    final normalized = value.trim().toLowerCase();

    if (normalized.isEmpty) {
      throw ArgumentError(
        'contentHash não pode ser vazio.',
      );
    }

    return normalized;
  }
}
