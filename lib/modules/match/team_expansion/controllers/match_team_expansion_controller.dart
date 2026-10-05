import 'package:flutter/foundation.dart';

import '../services/match_team_invitation_service.dart';

// ============================================================
// MATCH TEAM EXPANSION CONTROLLER
// ============================================================
//
// Responsável pelo estado da expansão de equipe dentro do Match.
//
// O controller:
//
// - conhece a Studio Session alvo;
// - controla loading;
// - envia convite;
// - expõe erro;
// - evita múltiplos convites simultâneos;
// - informa resultado para a UI.
//
// NÃO:
//
// - acessa Supabase diretamente;
// - conhece BuildContext;
// - mostra SnackBar;
// - navega.
//
// ============================================================

class MatchTeamExpansionController
    extends
        ChangeNotifier {
  // ============================================================
  // SERVICE
  // ============================================================

  final MatchTeamInvitationService invitationService;

  // ============================================================
  // PROJECT
  // ============================================================

  String _projectId = '';

  String _projectTitle = '';

  // ============================================================
  // STATE
  // ============================================================

  final Set<
    String
  >
  _sendingUserIds =
      <
        String
      >{};

  final Set<
    String
  >
  _pendingUserIds =
      <
        String
      >{};

  String? _errorMessage;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  MatchTeamExpansionController({
    required this.invitationService,
    String? projectId,
    String? projectTitle,
  }) {
    configureProject(
      projectId: projectId,
      projectTitle: projectTitle,
      notify: false,
    );
  }

  // ============================================================
  // GETTERS
  // ============================================================

  String get projectId {
    return _projectId;
  }

  String get projectTitle {
    return _projectTitle;
  }

  String get displayProjectTitle {
    final title = _projectTitle.trim();

    if (title.isEmpty) {
      return 'Studio Session';
    }

    return title;
  }

  bool get isActive {
    return _projectId.isNotEmpty;
  }

  bool get isBusy {
    return _sendingUserIds.isNotEmpty;
  }

  String? get errorMessage {
    return _errorMessage;
  }

  Set<
    String
  >
  get sendingUserIds {
    return Set<
      String
    >.unmodifiable(
      _sendingUserIds,
    );
  }

  Set<
    String
  >
  get pendingUserIds {
    return Set<
      String
    >.unmodifiable(
      _pendingUserIds,
    );
  }

  // ============================================================
  // CONFIGURE PROJECT
  // ============================================================

  void configureProject({
    String? projectId,
    String? projectTitle,
    bool notify = true,
  }) {
    _projectId =
        projectId?.trim() ??
        '';

    _projectTitle =
        projectTitle?.trim() ??
        '';

    _errorMessage = null;

    if (notify) {
      notifyListeners();
    }
  }

  // ============================================================
  // CLEAR PROJECT
  // ============================================================

  void clearProject() {
    _projectId = '';

    _projectTitle = '';

    _sendingUserIds.clear();

    _pendingUserIds.clear();

    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // IS SENDING
  // ============================================================

  bool isSending(
    String userId,
  ) {
    return _sendingUserIds.contains(
      userId.trim(),
    );
  }

  // ============================================================
  // HAS PENDING
  // ============================================================

  bool hasPending(
    String userId,
  ) {
    return _pendingUserIds.contains(
      userId.trim(),
    );
  }

  // ============================================================
  // CHECK PENDING
  // ============================================================

  Future<
    bool
  >
  checkPending({
    required String userId,
  }) async {
    final normalizedUserId = userId.trim();

    if (!isActive ||
        normalizedUserId.isEmpty) {
      return false;
    }

    try {
      final pending = await invitationService.hasPendingInvitation(
        projectId: _projectId,
        invitedUserId: normalizedUserId,
      );

      if (pending) {
        _pendingUserIds.add(
          normalizedUserId,
        );
      } else {
        _pendingUserIds.remove(
          normalizedUserId,
        );
      }

      notifyListeners();

      return pending;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[MATCH TEAM EXPANSION CONTROLLER] '
        'Erro ao verificar convite: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      return false;
    }
  }

  // ============================================================
  // INVITE
  // ============================================================

  Future<
    MatchTeamInvitationResult
  >
  invite({
    required String userId,
  }) async {
    final normalizedUserId = userId.trim();

    // ==========================================================
    // PROJECT
    // ==========================================================

    if (!isActive) {
      throw StateError(
        'Nenhuma Studio Session foi definida '
        'para expansão de equipe.',
      );
    }

    // ==========================================================
    // USER
    // ==========================================================

    if (normalizedUserId.isEmpty) {
      throw ArgumentError(
        'userId não pode ficar vazio.',
      );
    }

    // ==========================================================
    // ALREADY SENDING
    // ==========================================================

    if (_sendingUserIds.contains(
      normalizedUserId,
    )) {
      throw StateError(
        'Este convite já está sendo enviado.',
      );
    }

    // ==========================================================
    // LOADING
    // ==========================================================

    _sendingUserIds.add(
      normalizedUserId,
    );

    _errorMessage = null;

    notifyListeners();

    try {
      final result = await invitationService.invite(
        projectId: _projectId,
        invitedUserId: normalizedUserId,
      );

      // ========================================================
      // PENDING
      // ========================================================

      if (result.status ==
              MatchTeamInvitationStatus.invited ||
          result.status ==
              MatchTeamInvitationStatus.alreadyPending) {
        _pendingUserIds.add(
          normalizedUserId,
        );
      }

      debugPrint(
        '[MATCH TEAM EXPANSION CONTROLLER] '
        'Resultado do convite: '
        '${result.status}',
      );

      return result;
    } catch (
      error,
      stackTrace
    ) {
      _errorMessage = _resolveErrorMessage(
        error,
      );

      debugPrint(
        '[MATCH TEAM EXPANSION CONTROLLER] '
        'Erro ao convidar usuário: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      rethrow;
    } finally {
      _sendingUserIds.remove(
        normalizedUserId,
      );

      notifyListeners();
    }
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    if (_errorMessage ==
        null) {
      return;
    }

    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  String _resolveErrorMessage(
    Object error,
  ) {
    if (error
        is StateError) {
      final message = error.message.toString().trim();

      if (message.isNotEmpty) {
        return message;
      }
    }

    if (error
        is ArgumentError) {
      final message = error.message?.toString().trim();

      if (message !=
              null &&
          message.isNotEmpty) {
        return message;
      }
    }

    return 'Não foi possível enviar o convite.';
  }
}
