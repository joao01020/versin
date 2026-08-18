import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/project_invitation_model.dart';
import '../services/project_invitation_service.dart';

// ============================================================
// PROJECT INVITATION CONTROLLER
// ============================================================
//
// Controller global dos convites de Studio Session.
//
// Responsabilidades:
//
// - iniciar observação dos convites;
// - manter lista de convites pendentes;
// - expor o convite atual;
// - controlar loading;
// - controlar erro;
// - aceitar convite;
// - recusar convite;
// - remover convite respondido da fila;
// - expor projectId retornado após aceite.
//
// NÃO:
//
// - desenha Widget;
// - usa BuildContext;
// - navega;
// - acessa Supabase diretamente.
//
// ============================================================

class ProjectInvitationController
    with
        ChangeNotifier {
  // ============================================================
  // SERVICE
  // ============================================================

  final ProjectInvitationService _service;

  // ============================================================
  // SUBSCRIPTION
  // ============================================================

  StreamSubscription<
    List<
      ProjectInvitationModel
    >
  >?
  _subscription;

  Timer? _realtimeRetryTimer;

  static const Duration _realtimeRetryDelay = Duration(
    seconds: 3,
  );

  // ============================================================
  // STATE
  // ============================================================

  List<
    ProjectInvitationModel
  >
  _pendingInvitations =
      const <
        ProjectInvitationModel
      >[];

  bool _initialized = false;

  bool _disposed = false;

  bool _isLoading = false;

  bool _isAccepting = false;

  bool _isRejecting = false;

  String? _errorMessage;

  String? _acceptedProjectId;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  ProjectInvitationController({
    ProjectInvitationService? service,
  }) : _service =
           service ??
           ProjectInvitationService();

  // ============================================================
  // GETTERS
  // ============================================================

  bool get initialized => _initialized;

  bool get isLoading => _isLoading;

  bool get isAccepting => _isAccepting;

  bool get isRejecting => _isRejecting;

  bool get isBusy =>
      _isLoading ||
      _isAccepting ||
      _isRejecting;

  bool get hasError =>
      _errorMessage !=
      null;

  String? get errorMessage => _errorMessage;

  String? get acceptedProjectId => _acceptedProjectId;

  List<
    ProjectInvitationModel
  >
  get pendingInvitations => _pendingInvitations;

  int get pendingCount => _pendingInvitations.length;

  bool get hasPendingInvitations => _pendingInvitations.isNotEmpty;

  ProjectInvitationModel? get currentInvitation {
    if (_pendingInvitations.isEmpty) {
      return null;
    }

    return _pendingInvitations.first;
  }

  // ============================================================
  // INIT
  // ============================================================

  Future<
    void
  >
  init() async {
    if (_disposed ||
        _initialized) {
      return;
    }

    _initialized = true;

    _setLoading(
      true,
      notify: false,
    );

    _errorMessage = null;

    _safeNotify();

    try {
      // ========================================================
      // SNAPSHOT INICIAL
      // ========================================================

      final initial = await _service.loadPendingInvitations();

      if (_disposed) {
        return;
      }

      _replacePendingInvitations(
        initial,
        source: 'snapshot inicial',
      );

      // ========================================================
      // REALTIME
      // ========================================================

      await _startRealtime();
    } catch (
      error,
      stackTrace
    ) {
      if (!_disposed) {
        _errorMessage = 'Não foi possível carregar os convites.';

        debugPrint(
          '[PROJECT INVITATION CONTROLLER] '
          'Erro ao inicializar: '
          '$error',
        );

        debugPrint(
          '$stackTrace',
        );

        _scheduleRealtimeRetry();
      }
    } finally {
      if (!_disposed) {
        _setLoading(
          false,
          notify: false,
        );

        _safeNotify();
      }
    }
  }

  // ============================================================
  // REALTIME
  // ============================================================

  Future<
    void
  >
  _startRealtime() async {
    _realtimeRetryTimer?.cancel();

    _realtimeRetryTimer = null;

    await _subscription?.cancel();

    _subscription = null;

    if (_disposed) {
      return;
    }

    debugPrint(
      '[PROJECT INVITATION CONTROLLER] '
      'Iniciando realtime.',
    );

    _subscription = _service.watchPendingInvitations().listen(
      (
        invitations,
      ) {
        if (_disposed) {
          return;
        }

        _replacePendingInvitations(
          invitations,
          source: 'realtime',
        );

        _errorMessage = null;

        _safeNotify();
      },
      onError:
          (
            Object error,
            StackTrace stackTrace,
          ) {
            if (_disposed) {
              return;
            }

            _errorMessage = 'Não foi possível atualizar os convites.';

            debugPrint(
              '[PROJECT INVITATION CONTROLLER] '
              'Erro no realtime: '
              '$error',
            );

            debugPrint(
              '$stackTrace',
            );

            _safeNotify();

            _scheduleRealtimeRetry();
          },
      onDone: () {
        if (_disposed) {
          return;
        }

        debugPrint(
          '[PROJECT INVITATION CONTROLLER] '
          'Realtime encerrado.',
        );

        _scheduleRealtimeRetry();
      },
    );
  }

  // ============================================================
  // REALTIME RETRY
  // ============================================================

  void _scheduleRealtimeRetry() {
    if (_disposed) {
      return;
    }

    if (_realtimeRetryTimer?.isActive ==
        true) {
      return;
    }

    _realtimeRetryTimer = Timer(
      _realtimeRetryDelay,
      () {
        _realtimeRetryTimer = null;

        if (_disposed) {
          return;
        }

        debugPrint(
          '[PROJECT INVITATION CONTROLLER] '
          'Reconectando realtime.',
        );

        unawaited(
          _startRealtime(),
        );
      },
    );
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<
    void
  >
  refresh() async {
    if (_disposed ||
        _isLoading) {
      return;
    }

    _setLoading(
      true,
    );

    _errorMessage = null;

    try {
      final invitations = await _service.loadPendingInvitations();

      if (_disposed) {
        return;
      }

      _replacePendingInvitations(
        invitations,
        source: 'refresh manual',
      );
    } catch (
      error,
      stackTrace
    ) {
      if (!_disposed) {
        _errorMessage = 'Não foi possível atualizar os convites.';

        debugPrint(
          '[PROJECT INVITATION CONTROLLER] '
          'Erro ao atualizar: '
          '$error',
        );

        debugPrint(
          '$stackTrace',
        );
      }
    } finally {
      if (!_disposed) {
        _setLoading(
          false,
          notify: false,
        );

        _safeNotify();
      }
    }
  }

  // ============================================================
  // ACCEPT CURRENT
  // ============================================================

  Future<
    String?
  >
  acceptCurrentInvitation() async {
    final invitation = currentInvitation;

    if (invitation ==
        null) {
      return null;
    }

    return acceptInvitation(
      invitation,
    );
  }

  // ============================================================
  // ACCEPT
  // ============================================================

  Future<
    String?
  >
  acceptInvitation(
    ProjectInvitationModel invitation,
  ) async {
    if (_disposed ||
        _isAccepting ||
        _isRejecting) {
      return null;
    }

    final invitationId = invitation.id.trim();

    if (invitationId.isEmpty) {
      return null;
    }

    _isAccepting = true;

    _errorMessage = null;

    _acceptedProjectId = null;

    _safeNotify();

    try {
      final projectId = await _service.acceptInvitation(
        invitationId,
      );

      if (_disposed) {
        return null;
      }

      _removeInvitationLocally(
        invitationId,
      );

      _acceptedProjectId =
          projectId ??
          invitation.projectId;

      debugPrint(
        '[PROJECT INVITATION CONTROLLER] '
        'Convite aceito. '
        'Projeto: '
        '${_acceptedProjectId ?? "desconhecido"}',
      );

      _safeNotify();

      return _acceptedProjectId;
    } catch (
      error,
      stackTrace
    ) {
      if (_disposed) {
        return null;
      }

      _errorMessage = 'Não foi possível aceitar o convite.';

      debugPrint(
        '[PROJECT INVITATION CONTROLLER] '
        'Erro ao aceitar convite: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      _safeNotify();

      return null;
    } finally {
      if (!_disposed) {
        _isAccepting = false;

        _safeNotify();
      }
    }
  }

  // ============================================================
  // REJECT CURRENT
  // ============================================================

  Future<
    bool
  >
  rejectCurrentInvitation() async {
    final invitation = currentInvitation;

    if (invitation ==
        null) {
      return false;
    }

    return rejectInvitation(
      invitation,
    );
  }

  // ============================================================
  // REJECT
  // ============================================================

  Future<
    bool
  >
  rejectInvitation(
    ProjectInvitationModel invitation,
  ) async {
    if (_disposed ||
        _isAccepting ||
        _isRejecting) {
      return false;
    }

    final invitationId = invitation.id.trim();

    if (invitationId.isEmpty) {
      return false;
    }

    _isRejecting = true;

    _errorMessage = null;

    _safeNotify();

    try {
      await _service.rejectInvitation(
        invitationId,
      );

      if (_disposed) {
        return false;
      }

      _removeInvitationLocally(
        invitationId,
      );

      debugPrint(
        '[PROJECT INVITATION CONTROLLER] '
        'Convite recusado: '
        '$invitationId',
      );

      _safeNotify();

      return true;
    } catch (
      error,
      stackTrace
    ) {
      if (_disposed) {
        return false;
      }

      _errorMessage = 'Não foi possível recusar o convite.';

      debugPrint(
        '[PROJECT INVITATION CONTROLLER] '
        'Erro ao recusar convite: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      _safeNotify();

      return false;
    } finally {
      if (!_disposed) {
        _isRejecting = false;

        _safeNotify();
      }
    }
  }

  // ============================================================
  // REPLACE PENDING INVITATIONS
  // ============================================================
  //
  // Mantém uma única fonte de estado para:
  //
  // - badge;
  // - banner;
  // - lista de convites.
  //
  // ============================================================

  void _replacePendingInvitations(
    List<
      ProjectInvitationModel
    >
    invitations, {
    required String source,
  }) {
    if (_disposed) {
      return;
    }

    _pendingInvitations =
        List<
          ProjectInvitationModel
        >.unmodifiable(
          invitations,
        );

    debugPrint(
      '[PROJECT INVITATION CONTROLLER] '
      '$source atualizado. '
      'Pendentes: ${_pendingInvitations.length}',
    );
  }

  // ============================================================
  // REMOVE LOCAL
  // ============================================================

  void _removeInvitationLocally(
    String invitationId,
  ) {
    final normalizedId = invitationId.trim();

    if (normalizedId.isEmpty) {
      return;
    }

    _pendingInvitations =
        List<
          ProjectInvitationModel
        >.unmodifiable(
          _pendingInvitations
              .where(
                (
                  invitation,
                ) {
                  return invitation.id.trim() !=
                      normalizedId;
                },
              )
              .toList(
                growable: false,
              ),
        );
  }

  // ============================================================
  // CLEAR ACCEPTED PROJECT
  // ============================================================

  void clearAcceptedProject() {
    if (_acceptedProjectId ==
        null) {
      return;
    }

    _acceptedProjectId = null;

    _safeNotify();
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

    _safeNotify();
  }

  // ============================================================
  // LOADING
  // ============================================================

  void _setLoading(
    bool value, {
    bool notify = true,
  }) {
    if (_disposed) {
      return;
    }

    if (_isLoading ==
        value) {
      return;
    }

    _isLoading = value;

    if (notify) {
      _safeNotify();
    }
  }

  // ============================================================
  // SAFE NOTIFY
  // ============================================================

  void _safeNotify() {
    if (_disposed) {
      return;
    }

    if (!hasListeners) {
      return;
    }

    notifyListeners();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    _realtimeRetryTimer?.cancel();

    _realtimeRetryTimer = null;

    unawaited(
      _subscription?.cancel(),
    );

    _subscription = null;

    _pendingInvitations =
        const <
          ProjectInvitationModel
        >[];

    _service.clearCache();

    super.dispose();
  }
}
