import 'package:flutter/foundation.dart';

import '../data/models/stored_work_model.dart';
import '../data/repositories/storage_repository.dart';

// ============================================================
// STORAGE CONTROLLER
// ============================================================
//
// Responsabilidades:
//
// - inicializar armazenamento;
// - garantir usuário atual;
// - carregar obras;
// - manter estado da página;
// - separar letras e beats;
// - fornecer contadores;
// - salvar obra;
// - atualizar obra;
// - remover obra;
// - sincronizar registros;
// - coordenar transferência de propriedade;
// - tratar loading e erros.
//
// NÃO é responsabilidade deste controller:
//
// - gerar hash;
// - ler arquivos;
// - criptografar conteúdo;
// - acessar diretamente Supabase/SQLite;
// - validar regras de segurança do backend.
//
// ============================================================

class StorageController
    extends
        ChangeNotifier {
  // ==========================================================
  // REPOSITORY
  // ==========================================================

  final StorageRepository repository;

  // ==========================================================
  // CONSTRUTOR
  // ==========================================================

  StorageController({
    required this.repository,
  });

  // ==========================================================
  // ESTADO
  // ==========================================================

  final List<
    StoredWorkModel
  >
  _works = [];

  bool _isLoading = false;

  bool _isSaving = false;

  bool _isDeleting = false;

  bool _isTransferring = false;

  bool _isInitialized = false;

  String? _errorMessage;

  String? _currentUserId;

  // ==========================================================
  // GETTERS
  // ==========================================================

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  bool get isDeleting => _isDeleting;

  bool get isTransferring => _isTransferring;

  bool get isInitialized => _isInitialized;

  bool get hasError =>
      _errorMessage !=
          null &&
      _errorMessage!.isNotEmpty;

  String? get errorMessage => _errorMessage;

  String? get currentUserId => _currentUserId;

  // ==========================================================
  // TODAS AS OBRAS
  // ==========================================================

  List<
    StoredWorkModel
  >
  get works => List.unmodifiable(
    _works,
  );

  // ==========================================================
  // LETRAS
  // ==========================================================

  List<
    StoredWorkModel
  >
  get lyrics => List.unmodifiable(
    _works.where(
      (
        work,
      ) =>
          work.type ==
          StoredWorkType.lyrics,
    ),
  );

  // ==========================================================
  // BEATS
  // ==========================================================

  List<
    StoredWorkModel
  >
  get beats => List.unmodifiable(
    _works.where(
      (
        work,
      ) =>
          work.type ==
          StoredWorkType.beat,
    ),
  );

  // ==========================================================
  // OBRAS ÍNTEGRAS
  // ==========================================================

  List<
    StoredWorkModel
  >
  get verifiedWorks => List.unmodifiable(
    _works.where(
      (
        work,
      ) => work.integrityVerified,
    ),
  );

  // ==========================================================
  // CONTADORES
  // ==========================================================

  int get totalCount => _works.length;

  int get lyricsCount => lyrics.length;

  int get beatsCount => beats.length;

  int get verifiedCount => verifiedWorks.length;

  // ==========================================================
  // ESTADO VAZIO
  // ==========================================================

  bool get isEmpty => _works.isEmpty;

  bool get hasLyrics => lyrics.isNotEmpty;

  bool get hasBeats => beats.isNotEmpty;

  // ==========================================================
  // INICIALIZAR
  // ==========================================================
  //
  // Pode ser chamado pela página de Storage.
  //
  // Se o mesmo usuário já estiver inicializado,
  // apenas sincronizamos os dados.
  //
  // ==========================================================

  Future<
    void
  >
  init({
    required String userId,
  }) async {
    final normalizedUserId = _normalizeUserId(
      userId,
    );

    // ========================================================
    // MESMO USUÁRIO
    // ========================================================

    if (_isInitialized &&
        _currentUserId ==
            normalizedUserId) {
      await refresh();

      return;
    }

    // ========================================================
    // NOVA SESSÃO
    // ========================================================

    _currentUserId = normalizedUserId;

    _isInitialized = true;

    await loadWorks();
  }

  // ==========================================================
  // GARANTIR INICIALIZAÇÃO
  // ==========================================================
  //
  // Esse método é importante para telas como:
  //
  // Studio
  //      ↓
  // RegisterLyricsPage
  //
  // porque o artista pode registrar uma letra antes mesmo
  // de abrir a página Armazenamento.
  //
  // Exemplo:
  //
  // await storageController.ensureInitialized(
  //   userId: 'user_123',
  // );
  //
  // ==========================================================

  Future<
    void
  >
  ensureInitialized({
    required String userId,
  }) async {
    final normalizedUserId = _normalizeUserId(
      userId,
    );

    // ========================================================
    // AINDA NÃO INICIALIZADO
    // ========================================================

    if (!_isInitialized ||
        _currentUserId ==
            null ||
        _currentUserId!.isEmpty) {
      await init(
        userId: normalizedUserId,
      );

      return;
    }

    // ========================================================
    // USUÁRIO DIFERENTE
    // ========================================================

    if (_currentUserId !=
        normalizedUserId) {
      await init(
        userId: normalizedUserId,
      );
    }
  }

  // ==========================================================
  // DEFINIR USUÁRIO SEM CARREGAR
  // ==========================================================
  //
  // Útil futuramente quando o AuthService informar o usuário
  // atual antes do Storage ser aberto.
  //
  // ==========================================================

  void setCurrentUser({
    required String userId,
  }) {
    final normalizedUserId = _normalizeUserId(
      userId,
    );

    if (_currentUserId ==
            normalizedUserId &&
        _isInitialized) {
      return;
    }

    _currentUserId = normalizedUserId;

    _isInitialized = true;

    notifyListeners();
  }

  // ==========================================================
  // CARREGAR OBRAS
  // ==========================================================

  Future<
    void
  >
  loadWorks() async {
    final userId = _requireCurrentUserId();

    _setLoading(
      true,
    );

    _clearError(
      notify: false,
    );

    try {
      final result = await repository.getWorks(
        userId: userId,
      );

      _works
        ..clear()
        ..addAll(
          result,
        );

      _sortWorks();
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        'Não foi possível carregar as obras.',
        error: error,
        stackTrace: stackTrace,
        notify: false,
      );
    } finally {
      _setLoading(
        false,
      );
    }
  }

  // ==========================================================
  // RECARREGAR
  // ==========================================================

  Future<
    void
  >
  refresh() async {
    if (!_isInitialized) {
      return;
    }

    if (_currentUserId ==
            null ||
        _currentUserId!.isEmpty) {
      return;
    }

    await loadWorks();
  }

  // ==========================================================
  // BUSCAR OBRA POR ID
  // ==========================================================

  Future<
    StoredWorkModel?
  >
  getWorkById(
    String workId,
  ) async {
    final normalizedWorkId = workId.trim();

    if (normalizedWorkId.isEmpty) {
      return null;
    }

    // ========================================================
    // PRIMEIRO PROCURA LOCALMENTE
    // ========================================================

    for (final work in _works) {
      if (work.id ==
          normalizedWorkId) {
        return work;
      }
    }

    // ========================================================
    // DEPOIS CONSULTA O REPOSITORY
    // ========================================================

    try {
      return await repository.getWorkById(
        workId: normalizedWorkId,
      );
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        'Não foi possível buscar a obra.',
        error: error,
        stackTrace: stackTrace,
      );

      return null;
    }
  }

  // ==========================================================
  // BUSCAR OBRA POR HASH
  // ==========================================================

  Future<
    StoredWorkModel?
  >
  getWorkByHash(
    String contentHash,
  ) async {
    final normalizedHash = contentHash.trim().toLowerCase();

    if (normalizedHash.isEmpty) {
      return null;
    }

    try {
      return await repository.getWorkByHash(
        contentHash: normalizedHash,
      );
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        'Não foi possível buscar a obra pelo hash.',
        error: error,
        stackTrace: stackTrace,
      );

      return null;
    }
  }

  // ==========================================================
  // HASH JÁ EXISTE
  // ==========================================================

  Future<
    bool
  >
  hashExists(
    String contentHash,
  ) async {
    final normalizedHash = contentHash.trim().toLowerCase();

    if (normalizedHash.isEmpty) {
      return false;
    }

    try {
      return await repository.hashExists(
        contentHash: normalizedHash,
      );
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        'Não foi possível verificar o hash.',
        error: error,
        stackTrace: stackTrace,
      );

      return false;
    }
  }

  // ==========================================================
  // SALVAR OBRA
  // ==========================================================

  Future<
    bool
  >
  saveWork(
    StoredWorkModel work,
  ) async {
    if (_isSaving) {
      return false;
    }

    // ========================================================
    // GARANTIR USUÁRIO
    // ========================================================

    if (!_isInitialized ||
        _currentUserId ==
            null ||
        _currentUserId!.isEmpty) {
      _setError(
        'StorageController ainda não foi inicializado com userId.',
      );

      return false;
    }

    _setSaving(
      true,
    );

    _clearError(
      notify: false,
    );

    try {
      // ======================================================
      // SALVAR NO REPOSITORY
      // ======================================================

      final savedWork = await repository.saveWork(
        work,
      );

      // ======================================================
      // EVITAR DUPLICIDADE LOCAL
      // ======================================================

      final existingIndex = _works.indexWhere(
        (
          item,
        ) =>
            item.id ==
            savedWork.id,
      );

      if (existingIndex ==
          -1) {
        _works.add(
          savedWork,
        );
      } else {
        _works[existingIndex] = savedWork;
      }

      _sortWorks();

      notifyListeners();

      return true;
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        'Não foi possível registrar a obra.',
        error: error,
        stackTrace: stackTrace,
        notify: false,
      );

      notifyListeners();

      return false;
    } finally {
      _setSaving(
        false,
      );
    }
  }

  // ==========================================================
  // ATUALIZAR OBRA
  // ==========================================================

  Future<
    bool
  >
  updateWork(
    StoredWorkModel work,
  ) async {
    if (_isSaving) {
      return false;
    }

    _setSaving(
      true,
    );

    _clearError(
      notify: false,
    );

    try {
      final updatedWork = await repository.updateWork(
        work,
      );

      final index = _works.indexWhere(
        (
          item,
        ) =>
            item.id ==
            updatedWork.id,
      );

      if (index !=
          -1) {
        _works[index] = updatedWork;
      } else {
        _works.add(
          updatedWork,
        );
      }

      _sortWorks();

      notifyListeners();

      return true;
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        'Não foi possível atualizar a obra.',
        error: error,
        stackTrace: stackTrace,
        notify: false,
      );

      notifyListeners();

      return false;
    } finally {
      _setSaving(
        false,
      );
    }
  }

  // ==========================================================
  // REMOVER OBRA
  // ==========================================================
  //
  // Remove a obra do repository e, em seguida, da lista local.
  //
  // Esse método é usado tanto para:
  //
  // - letras;
  // - beats.
  //
  // A confirmação visual fica na StoragePage.
  //
  // ==========================================================

  Future<
    bool
  >
  deleteWork(
    String workId,
  ) async {
    final normalizedWorkId = workId.trim();

    if (normalizedWorkId.isEmpty) {
      _setError(
        'ID da obra inválido.',
      );

      return false;
    }

    if (_isDeleting) {
      return false;
    }

    if (!_isInitialized ||
        _currentUserId ==
            null ||
        _currentUserId!.isEmpty) {
      _setError(
        'StorageController ainda não foi inicializado com userId.',
      );

      return false;
    }

    // ========================================================
    // VERIFICAR SE A OBRA EXISTE LOCALMENTE
    // ========================================================

    final existingIndex = _works.indexWhere(
      (
        work,
      ) =>
          work.id ==
          normalizedWorkId,
    );

    if (existingIndex ==
        -1) {
      _setError(
        'Obra não encontrada.',
      );

      return false;
    }

    _setDeleting(
      true,
    );

    _clearError(
      notify: false,
    );

    try {
      // ======================================================
      // REMOVER DO REPOSITORY
      // ======================================================

      await repository.deleteWork(
        workId: normalizedWorkId,
      );

      // ======================================================
      // REMOVER DO ESTADO LOCAL
      // ======================================================

      _works.removeWhere(
        (
          work,
        ) =>
            work.id ==
            normalizedWorkId,
      );

      _sortWorks();

      notifyListeners();

      return true;
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        'Não foi possível apagar a obra.',
        error: error,
        stackTrace: stackTrace,
        notify: false,
      );

      notifyListeners();

      return false;
    } finally {
      _setDeleting(
        false,
      );
    }
  }

  // ==========================================================
  // MARCAR INTEGRIDADE
  // ==========================================================

  Future<
    bool
  >
  setIntegrityVerified({
    required String workId,
    required bool verified,
  }) async {
    final work = await getWorkById(
      workId,
    );

    if (work ==
        null) {
      return false;
    }

    final updated = work.copyWith(
      integrityVerified: verified,

      updatedAt: DateTime.now().toUtc(),
    );

    return updateWork(
      updated,
    );
  }

  // ==========================================================
  // TRANSFERIR AUTORIA / PROPRIEDADE
  // ==========================================================
  //
  // O controller coordena a operação, mas a alteração real
  // fica no repository.
  //
  // Em um repository Supabase, este método poderá chamar a RPC:
  //
  // transfer_work(
  //   p_work_id,
  //   p_to_user_id,
  //   p_note
  // )
  //
  // ==========================================================

  Future<
    bool
  >
  transferWork({
    required String workId,
    required String toUserId,
    String? note,
  }) async {
    final normalizedWorkId = workId.trim();

    final normalizedToUserId = toUserId.trim();

    final normalizedNote = note?.trim();

    // ========================================================
    // VALIDAR ID DA OBRA
    // ========================================================

    if (normalizedWorkId.isEmpty) {
      _setError(
        'ID da obra inválido.',
      );

      return false;
    }

    // ========================================================
    // VALIDAR DESTINATÁRIO
    // ========================================================

    if (normalizedToUserId.isEmpty) {
      _setError(
        'Novo proprietário inválido.',
      );

      return false;
    }

    // ========================================================
    // GARANTIR INICIALIZAÇÃO
    // ========================================================

    if (!_isInitialized ||
        _currentUserId ==
            null ||
        _currentUserId!.isEmpty) {
      _setError(
        'StorageController ainda não foi inicializado com userId.',
      );

      return false;
    }

    // ========================================================
    // OPERAÇÃO JÁ EM ANDAMENTO
    // ========================================================

    if (_isTransferring) {
      return false;
    }

    // ========================================================
    // BUSCAR OBRA
    // ========================================================

    final work = await getWorkById(
      normalizedWorkId,
    );

    if (work ==
        null) {
      _setError(
        'Obra não encontrada.',
      );

      return false;
    }

    // ========================================================
    // MESMO PROPRIETÁRIO
    // ========================================================

    if (work.ownerUserId ==
        normalizedToUserId) {
      _setError(
        'Esse usuário já é o proprietário atual da obra.',
      );

      return false;
    }

    // ========================================================
    // EXECUTAR
    // ========================================================

    _setTransferring(
      true,
    );

    _clearError(
      notify: false,
    );

    try {
      final updatedWork = await repository.transferWork(
        workId: normalizedWorkId,
        toUserId: normalizedToUserId,
        note:
            normalizedNote ==
                    null ||
                normalizedNote.isEmpty
            ? null
            : normalizedNote,
      );

      // ======================================================
      // ATUALIZAR ESTADO LOCAL
      // ======================================================

      final index = _works.indexWhere(
        (
          item,
        ) =>
            item.id ==
            updatedWork.id,
      );

      // ======================================================
      // A OBRA DEIXA DE PERTENCER AO USUÁRIO ATUAL
      // ======================================================
      //
      // Como a StoragePage normalmente mostra apenas obras cujo
      // ownerUserId é o usuário atual, removemos a obra da lista
      // depois de uma transferência bem-sucedida.
      //
      // Se no futuro quisermos mostrar "obras transferidas",
      // isso deverá vir de outra consulta/histórico.
      //
      // ======================================================

      if (updatedWork.ownerUserId !=
          _currentUserId) {
        if (index !=
            -1) {
          _works.removeAt(
            index,
          );
        }
      } else {
        if (index !=
            -1) {
          _works[index] = updatedWork;
        } else {
          _works.add(
            updatedWork,
          );
        }
      }

      _sortWorks();

      notifyListeners();

      return true;
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        'Não foi possível transferir a autoria.',
        error: error,
        stackTrace: stackTrace,
        notify: false,
      );

      notifyListeners();

      return false;
    } finally {
      _setTransferring(
        false,
      );
    }
  }

  // ==========================================================
  // ALTERAR PROPRIETÁRIO
  // ==========================================================
  //
  // Mantido por compatibilidade com código antigo.
  //
  // Novos fluxos devem usar transferWork(...).
  //
  // ==========================================================

  Future<
    bool
  >
  updateOwner({
    required String workId,
    required String newOwnerUserId,
  }) {
    return transferWork(
      workId: workId,
      toUserId: newOwnerUserId,
    );
  }

  // ==========================================================
  // LIMPAR ERRO
  // ==========================================================

  void clearError() {
    _clearError();
  }

  // ==========================================================
  // LIMPAR ESTADO
  // ==========================================================
  //
  // Útil ao fazer logout.
  //
  // ==========================================================

  void reset() {
    _works.clear();

    _currentUserId = null;

    _isLoading = false;

    _isSaving = false;

    _isDeleting = false;

    _isTransferring = false;

    _isInitialized = false;

    _errorMessage = null;

    notifyListeners();
  }

  // ==========================================================
  // ORDENAR OBRAS
  // ==========================================================

  void _sortWorks() {
    _works.sort(
      (
        a,
        b,
      ) => b.createdAt.compareTo(
        a.createdAt,
      ),
    );
  }

  // ==========================================================
  // VALIDAR USUÁRIO
  // ==========================================================

  String _normalizeUserId(
    String userId,
  ) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      throw ArgumentError(
        'userId não pode ser vazio.',
      );
    }

    return normalized;
  }

  // ==========================================================
  // EXIGIR USUÁRIO ATUAL
  // ==========================================================

  String _requireCurrentUserId() {
    final userId = _currentUserId;

    if (userId ==
            null ||
        userId.isEmpty) {
      throw StateError(
        'StorageController ainda não foi inicializado com userId.',
      );
    }

    return userId;
  }

  // ==========================================================
  // LOADING
  // ==========================================================

  void _setLoading(
    bool value,
  ) {
    if (_isLoading ==
        value) {
      return;
    }

    _isLoading = value;

    notifyListeners();
  }

  // ==========================================================
  // SAVING
  // ==========================================================

  void _setSaving(
    bool value,
  ) {
    if (_isSaving ==
        value) {
      return;
    }

    _isSaving = value;

    notifyListeners();
  }

  // ==========================================================
  // DELETING
  // ==========================================================

  void _setDeleting(
    bool value,
  ) {
    if (_isDeleting ==
        value) {
      return;
    }

    _isDeleting = value;

    notifyListeners();
  }

  // ==========================================================
  // TRANSFERRING
  // ==========================================================

  void _setTransferring(
    bool value,
  ) {
    if (_isTransferring ==
        value) {
      return;
    }

    _isTransferring = value;

    notifyListeners();
  }

  // ==========================================================
  // ERRO
  // ==========================================================

  void _setError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    bool notify = true,
  }) {
    _errorMessage = message;

    if (error !=
        null) {
      debugPrint(
        '[STORAGE] $message',
      );

      debugPrint(
        '[STORAGE] Erro: $error',
      );
    }

    if (stackTrace !=
        null) {
      debugPrint(
        '[STORAGE] StackTrace: $stackTrace',
      );
    }

    if (notify) {
      notifyListeners();
    }
  }

  // ==========================================================
  // LIMPAR ERRO INTERNO
  // ==========================================================

  void _clearError({
    bool notify = true,
  }) {
    if (_errorMessage ==
        null) {
      return;
    }

    _errorMessage = null;

    if (notify) {
      notifyListeners();
    }
  }
}
