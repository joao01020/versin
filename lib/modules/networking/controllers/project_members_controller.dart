import 'package:flutter/foundation.dart';

import '../data/models/project_member_model.dart';
import '../services/project_members_service.dart';

// ============================================================
// PROJECT MEMBERS CONTROLLER
// ============================================================
//
// Responsável pelo estado dos membros de uma Studio Session.
//
// Fluxo:
//
// MembersView
//    ↓
// ProjectMembersController
//    ↓
// ProjectMembersService
//    ↓
// projects.members
//    ↓
// profiles
//
// Também serve como fonte de identidade para:
//
// - chamadas;
// - áudio;
// - consentimento de vídeo;
// - seleção de participantes;
// - recrutamento;
// - ações privadas.
//
// IMPORTANTE:
//
// ProjectMemberModel.id
//
// e
//
// ProjectMemberModel.userId
//
// representam o UUID do usuário.
//
// ============================================================

class ProjectMembersController
    with
        ChangeNotifier {
  // ==========================================================
  // PROJETO
  // ==========================================================

  final String projectId;

  // ==========================================================
  // SERVICE
  // ==========================================================

  final ProjectMembersService _service;

  // ==========================================================
  // MEMBERS
  // ==========================================================

  List<
    ProjectMemberModel
  >
  _members =
      const <
        ProjectMemberModel
      >[];

  // ==========================================================
  // STATE
  // ==========================================================

  bool _isLoading = true;

  bool _hasLoaded = false;

  bool _disposed = false;

  String? _errorMessage;

  // ==========================================================
  // LOAD CONTROL
  // ==========================================================

  Future<
    void
  >?
  _activeLoad;

  // ==========================================================
  // CONSTRUTOR
  // ==========================================================

  ProjectMembersController({
    required String projectId,
    ProjectMembersService? service,
  }) : projectId = _requiredProjectId(
         projectId,
       ),
       _service =
           service ??
           ProjectMembersService();

  // ==========================================================
  // GETTERS
  // ==========================================================

  List<
    ProjectMemberModel
  >
  get members => _members;

  bool get isLoading => _isLoading;

  bool get hasLoaded => _hasLoaded;

  bool get hasMembers => _members.isNotEmpty;

  bool get isEmpty => _members.isEmpty;

  bool get hasError =>
      _errorMessage !=
      null;

  String? get errorMessage => _errorMessage;

  int get memberCount => _members.length;

  // ==========================================================
  // CURRENT USER
  // ==========================================================

  String? get currentUserId {
    final value = _service.currentUserId?.trim();

    if (value ==
            null ||
        value.isEmpty) {
      return null;
    }

    return value;
  }

  // ==========================================================
  // CURRENT USER MEMBER
  // ==========================================================

  ProjectMemberModel? get currentUserMember {
    final userId = currentUserId;

    if (userId ==
        null) {
      return null;
    }

    return getMemberByUserId(
      userId,
    );
  }

  // ==========================================================
  // LOAD
  // ==========================================================
  //
  // Se já existe um carregamento em andamento, devolvemos
  // exatamente o mesmo Future.
  //
  // Isso evita:
  //
  // load()
  // reload()
  // pull-to-refresh
  //
  // dispararem múltiplas consultas simultâneas.
  //
  // ==========================================================

  Future<
    void
  >
  load() {
    if (_disposed) {
      return Future.value();
    }

    final activeLoad = _activeLoad;

    if (activeLoad !=
        null) {
      return activeLoad;
    }

    final future = _performLoad();

    _activeLoad = future;

    return future.whenComplete(
      () {
        if (identical(
          _activeLoad,
          future,
        )) {
          _activeLoad = null;
        }
      },
    );
  }

  // ==========================================================
  // PERFORM LOAD
  // ==========================================================

  Future<
    void
  >
  _performLoad() async {
    if (_disposed) {
      return;
    }

    // ========================================================
    // LOADING
    // ========================================================

    _isLoading = true;

    _errorMessage = null;

    _safeNotify();

    try {
      // ======================================================
      // SERVICE
      // ======================================================

      final result = await _service.getMembers(
        projectId: projectId,
      );

      if (_disposed) {
        return;
      }

      // ======================================================
      // NORMALIZAR
      // ======================================================

      final normalizedMembers = result
          .where(
            (
              member,
            ) => member.userId.trim().isNotEmpty,
          )
          .toList(
            growable: false,
          );

      // ======================================================
      // REMOVE DUPLICADOS
      // ======================================================

      final uniqueMembers =
          <
            String,
            ProjectMemberModel
          >{};

      for (final member in normalizedMembers) {
        uniqueMembers[member.userId] = member;
      }

      // ======================================================
      // RESULTADO
      // ======================================================

      _members =
          List<
            ProjectMemberModel
          >.unmodifiable(
            uniqueMembers.values,
          );

      _isLoading = false;

      _hasLoaded = true;

      _errorMessage = null;

      _safeNotify();

      debugPrint(
        '[PROJECT MEMBERS CONTROLLER] '
        '${_members.length} membro(s) disponível(is).',
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROJECT MEMBERS CONTROLLER] '
        'Erro ao carregar membros: '
        '$error',
      );

      debugPrint(
        '[PROJECT MEMBERS CONTROLLER] '
        'StackTrace: '
        '$stackTrace',
      );

      if (_disposed) {
        return;
      }

      // ======================================================
      // NÃO APAGAR DADOS JÁ CARREGADOS
      // ======================================================
      //
      // Se for apenas um erro de refresh, manter os membros
      // antigos é melhor do que transformar a tela em vazia.
      //
      // ======================================================

      if (!_hasLoaded) {
        _members =
            const <
              ProjectMemberModel
            >[];
      }

      _isLoading = false;

      _hasLoaded = true;

      _errorMessage = 'Não foi possível carregar os membros.';

      _safeNotify();
    }
  }

  // ==========================================================
  // RELOAD
  // ==========================================================

  Future<
    void
  >
  reload() async {
    if (_disposed) {
      return;
    }

    await load();
  }

  // ==========================================================
  // É O USUÁRIO ATUAL?
  // ==========================================================

  bool isCurrentUser(
    ProjectMemberModel member,
  ) {
    final userId = currentUserId;

    if (userId ==
        null) {
      return false;
    }

    return member.userId ==
        userId;
  }

  // ==========================================================
  // BUSCAR MEMBRO POR ID
  // ==========================================================
  //
  // Compatibilidade com código anterior.
  //
  // ==========================================================

  ProjectMemberModel? getMemberById(
    String memberId,
  ) {
    return getMemberByUserId(
      memberId,
    );
  }

  // ==========================================================
  // BUSCAR MEMBRO POR USER ID
  // ==========================================================

  ProjectMemberModel? getMemberByUserId(
    String userId,
  ) {
    final normalizedId = userId.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    for (final member in _members) {
      if (member.userId ==
          normalizedId) {
        return member;
      }
    }

    return null;
  }

  // ==========================================================
  // POSSUI MEMBRO
  // ==========================================================

  bool containsUser(
    String userId,
  ) {
    return getMemberByUserId(
          userId,
        ) !=
        null;
  }

  // ==========================================================
  // OUTROS MEMBROS
  // ==========================================================
  //
  // Retorna todos, exceto o usuário autenticado.
  //
  // Útil para:
  //
  // - ligação;
  // - áudio;
  // - vídeo;
  // - consentimento;
  // - abrir perfil;
  // - contratos;
  //
  // ==========================================================

  List<
    ProjectMemberModel
  >
  get otherMembers {
    final userId = currentUserId;

    if (userId ==
        null) {
      return List<
        ProjectMemberModel
      >.unmodifiable(
        _members,
      );
    }

    return _members
        .where(
          (
            member,
          ) =>
              member.userId !=
              userId,
        )
        .toList(
          growable: false,
        );
  }

  // ==========================================================
  // ONLINE MEMBERS
  // ==========================================================

  List<
    ProjectMemberModel
  >
  get onlineMembers {
    return _members
        .where(
          (
            member,
          ) => member.isOnline,
        )
        .toList(
          growable: false,
        );
  }

  // ==========================================================
  // OTHER ONLINE MEMBERS
  // ==========================================================

  List<
    ProjectMemberModel
  >
  get otherOnlineMembers {
    return otherMembers
        .where(
          (
            member,
          ) => member.isOnline,
        )
        .toList(
          growable: false,
        );
  }

  // ==========================================================
  // CLEAR ERROR
  // ==========================================================

  void clearError() {
    if (_disposed ||
        _errorMessage ==
            null) {
      return;
    }

    _errorMessage = null;

    _safeNotify();
  }

  // ==========================================================
  // SAFE NOTIFY
  // ==========================================================

  void _safeNotify() {
    if (_disposed ||
        !hasListeners) {
      return;
    }

    notifyListeners();
  }

  // ==========================================================
  // PROJECT ID
  // ==========================================================

  static String _requiredProjectId(
    String value,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError(
        'projectId não pode ser vazio.',
      );
    }

    return normalized;
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    _members =
        const <
          ProjectMemberModel
        >[];

    _activeLoad = null;

    super.dispose();
  }
}
