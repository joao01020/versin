import 'package:flutter/foundation.dart';

import '../data/models/project_member_model.dart';
import '../services/project_members_service.dart';

// ============================================================
// PROJECT MEMBERS CONTROLLER
// ============================================================
//
// Responsável pelo estado da tela MembersView.
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
  // ESTADO
  // ==========================================================

  List<
    ProjectMemberModel
  >
  _members =
      const <
        ProjectMemberModel
      >[];

  bool _isLoading = true;

  bool _disposed = false;

  String? _errorMessage;

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

  bool get hasMembers => _members.isNotEmpty;

  bool get hasError =>
      _errorMessage !=
      null;

  String? get errorMessage => _errorMessage;

  int get memberCount => _members.length;

  String? get currentUserId => _service.currentUserId;

  // ==========================================================
  // LOAD
  // ==========================================================

  Future<
    void
  >
  load() async {
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
      // RESULTADO
      // ======================================================

      _members =
          List<
            ProjectMemberModel
          >.unmodifiable(
            result,
          );

      _isLoading = false;

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

      _members =
          const <
            ProjectMemberModel
          >[];

      _isLoading = false;

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
    await load();
  }

  // ==========================================================
  // É O USUÁRIO ATUAL?
  // ==========================================================

  bool isCurrentUser(
    ProjectMemberModel member,
  ) {
    final id = currentUserId;

    if (id ==
            null ||
        id.isEmpty) {
      return false;
    }

    return member.id ==
        id;
  }

  // ==========================================================
  // BUSCAR MEMBRO POR ID
  // ==========================================================

  ProjectMemberModel? getMemberById(
    String memberId,
  ) {
    final normalizedId = memberId.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    for (final member in _members) {
      if (member.id ==
          normalizedId) {
        return member;
      }
    }

    return null;
  }

  // ==========================================================
  // OUTROS MEMBROS
  // ==========================================================
  //
  // Retorna todos, exceto o usuário autenticado.
  //
  // Útil depois para:
  //
  // - ligação;
  // - abrir perfil;
  // - ações privadas;
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
      return _members;
    }

    return _members
        .where(
          (
            member,
          ) =>
              member.id !=
              userId,
        )
        .toList(
          growable: false,
        );
  }

  // ==========================================================
  // LIMPAR ERRO
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
    if (_disposed) {
      return;
    }

    if (!hasListeners) {
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

    super.dispose();
  }
}
