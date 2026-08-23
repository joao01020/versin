import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/project_recruitment_model.dart';
import '../services/project_recruitment_service.dart';

// ============================================================
// PROJECT RECRUITMENT CONTROLLER
// ============================================================

class ProjectRecruitmentController
    with
        ChangeNotifier {
  final String projectId;

  final ProjectRecruitmentService _service;

  StreamSubscription<
    List<
      ProjectRecruitmentModel
    >
  >?
  _subscription;

  List<
    ProjectRecruitmentModel
  >
  _recruitments = const [];

  List<
    ProjectRecruitmentCandidateModel
  >
  _candidates = const [];

  bool _isLoading = false;

  bool _isSaving = false;

  bool _isLoadingCandidates = false;

  bool _disposed = false;

  String? _errorMessage;

  ProjectRecruitmentController({
    required String projectId,
    ProjectRecruitmentService? service,
  }) : projectId = _requiredProjectId(
         projectId,
       ),
       _service =
           service ??
           ProjectRecruitmentService();

  // ==========================================================
  // GETTERS
  // ==========================================================

  List<
    ProjectRecruitmentModel
  >
  get recruitments => _recruitments;

  List<
    ProjectRecruitmentCandidateModel
  >
  get candidates => _candidates;

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  bool get isLoadingCandidates => _isLoadingCandidates;

  bool get hasError =>
      _errorMessage !=
      null;

  String? get errorMessage => _errorMessage;

  List<
    ProjectRecruitmentModel
  >
  get activeRecruitments => _recruitments
      .where(
        (
          item,
        ) =>
            item.isOpen &&
            !item.isExpired,
      )
      .toList(
        growable: false,
      );

  // ==========================================================
  // INIT
  // ==========================================================

  Future<
    void
  >
  init() async {
    if (_disposed) {
      return;
    }

    _isLoading = true;

    _errorMessage = null;

    _safeNotify();

    await _subscription?.cancel();

    _subscription = _service
        .streamRecruitments(
          projectId: projectId,
        )
        .listen(
          (
            items,
          ) {
            if (_disposed) {
              return;
            }

            _recruitments =
                List<
                  ProjectRecruitmentModel
                >.unmodifiable(
                  items,
                );

            _isLoading = false;

            _errorMessage = null;

            _safeNotify();
          },
          onError:
              (
                error,
              ) {
                if (_disposed) {
                  return;
                }

                _isLoading = false;

                _errorMessage = 'Não foi possível carregar as buscas.';

                _safeNotify();
              },
        );
  }

  // ==========================================================
  // CRIAR
  // ==========================================================

  Future<
    ProjectRecruitmentModel?
  >
  createRecruitment({
    required String role,
    String description = '',
    DateTime? expiresAt,
  }) async {
    if (_disposed ||
        _isSaving) {
      return null;
    }

    _isSaving = true;

    _errorMessage = null;

    _safeNotify();

    try {
      return await _service.createRecruitment(
        projectId: projectId,

        role: role,

        description: description,

        expiresAt: expiresAt,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROJECT RECRUITMENT CONTROLLER] '
        'Erro ao criar busca: '
        '$error',
      );

      debugPrint(
        '[PROJECT RECRUITMENT CONTROLLER] '
        '$stackTrace',
      );

      _errorMessage = 'Não foi possível iniciar a busca.';

      return null;
    } finally {
      if (!_disposed) {
        _isSaving = false;

        _safeNotify();
      }
    }
  }

  // ==========================================================
  // CANDIDATOS
  // ==========================================================

  Future<
    void
  >
  loadCandidates(
    ProjectRecruitmentModel recruitment,
  ) async {
    if (_disposed) {
      return;
    }

    _isLoadingCandidates = true;

    _errorMessage = null;

    _safeNotify();

    try {
      _candidates = await _service.getCandidates(
        recruitment: recruitment,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROJECT RECRUITMENT CONTROLLER] '
        'Erro candidatos: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      _candidates = const [];

      _errorMessage = 'Não foi possível buscar candidatos.';
    } finally {
      if (!_disposed) {
        _isLoadingCandidates = false;

        _safeNotify();
      }
    }
  }

  // ==========================================================
  // CONVIDAR
  // ==========================================================

  Future<
    bool
  >
  inviteCandidate({
    required ProjectRecruitmentModel recruitment,
    required ProjectRecruitmentCandidateModel candidate,
  }) async {
    try {
      await _service.inviteCandidate(
        recruitmentId: recruitment.id,

        userId: candidate.userId,
      );

      await loadCandidates(
        recruitment,
      );

      return true;
    } catch (
      error
    ) {
      _errorMessage = 'Não foi possível enviar o convite.';

      _safeNotify();

      return false;
    }
  }

  // ==========================================================
  // APROVAR
  // ==========================================================

  Future<
    bool
  >
  approveCandidate({
    required ProjectRecruitmentModel recruitment,
    required ProjectRecruitmentCandidateModel candidate,
  }) async {
    try {
      await _service.approveCandidate(
        recruitment: recruitment,

        userId: candidate.userId,
      );

      await loadCandidates(
        recruitment,
      );

      return true;
    } catch (
      error
    ) {
      _errorMessage = 'Não foi possível adicionar o membro.';

      _safeNotify();

      return false;
    }
  }

  // ==========================================================
  // FECHAR
  // ==========================================================

  Future<
    void
  >
  closeRecruitment(
    ProjectRecruitmentModel recruitment,
  ) async {
    try {
      await _service.closeRecruitment(
        recruitmentId: recruitment.id,
      );
    } catch (
      error
    ) {
      _errorMessage = 'Não foi possível encerrar a busca.';

      _safeNotify();
    }
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

    unawaited(
      _subscription?.cancel(),
    );

    _subscription = null;

    super.dispose();
  }
}
