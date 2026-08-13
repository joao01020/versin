import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/app/locator.dart';

import 'package:versin/modules/dashboard/controllers/dashboard_controller.dart';

import 'package:versin/modules/profile/controllers/professional_profile_controller.dart';
import 'package:versin/modules/profile/models/music_role.dart';

import '../models/match_user_entity.dart';

// ============================================================
// MATCH CONTROLLER
// ============================================================
//
// Responsabilidades:
//
// - controlar sessão de descoberta;
// - controlar usuário principal do Discovery;
// - controlar recomendações;
// - limpar resultados;
// - registrar likes;
// - detectar match mútuo;
// - iniciar projeto/networking;
// - controlar timer da conexão;
// - utilizar o perfil profissional real do usuário.
//
// Perfil profissional:
//
// ProfessionalProfileController
//
// fornece:
//
// - primaryRole
// - selectedRoles
// - lookingForRoles
//
// ============================================================

class MatchController
    with
        ChangeNotifier {
  // ============================================================
  // DEPENDÊNCIAS
  // ============================================================

  final DashboardController _dashboardController =
      sl<
        DashboardController
      >();

  final ProfessionalProfileController _professionalProfileController =
      sl<
        ProfessionalProfileController
      >();

  // ============================================================
  // STREAM DE MATCH
  // ============================================================

  final StreamController<
    String
  >
  _matchEventController =
      StreamController<
        String
      >.broadcast();

  // ============================================================
  // TIMERS / SUBSCRIPTIONS
  // ============================================================

  Timer? _countdownTimer;

  Timer? _searchTimeoutTimer;

  StreamSubscription? _matchSubscription;

  // ============================================================
  // ESTADO
  // ============================================================

  bool isLoading = true;

  MatchUserEntity? discoveryUser;

  List<
    MatchUserEntity
  >
  recommendedUsers = [];

  int remainingSeconds = 1200;

  // ============================================================
  // GETTERS
  // ============================================================

  Stream<
    String
  >
  get matchEventStream => _matchEventController.stream;

  Color get accentNeon => _dashboardController.accentNeon;

  Color get primaryPurple => _dashboardController.primaryPurple;

  ProfessionalProfileController get professionalProfileController => _professionalProfileController;

  MusicRole? get currentPrimaryRole => _professionalProfileController.primaryRole;

  Set<
    MusicRole
  >
  get currentRoles => _professionalProfileController.selectedRoles;

  Set<
    MusicRole
  >
  get lookingForRoles => _professionalProfileController.lookingForRoles;

  String get primaryRoleLabel => _professionalProfileController.primaryRoleLabel;

  bool get hasDiscoveryUser =>
      discoveryUser !=
      null;

  bool get hasRecommendations => recommendedUsers.isNotEmpty;

  bool get hasMatchResults =>
      discoveryUser !=
          null ||
      recommendedUsers.isNotEmpty;

  // ============================================================
  // USER ID
  // ============================================================

  String? get currentUserId {
    if (kDebugMode) {
      final debugUserId = dotenv.env['DEBUG_USER_ID']?.trim();

      if (debugUserId !=
              null &&
          debugUserId.isNotEmpty) {
        return debugUserId;
      }
    }

    return Supabase.instance.client.auth.currentUser?.id;
  }

  // ============================================================
  // SAFE NOTIFY
  // ============================================================

  void safeNotify() {
    if (hasListeners) {
      notifyListeners();
    }
  }

  // ============================================================
  // INIT MATCH SESSION
  // ============================================================
  //
  // A sessão usa diretamente:
  //
  // professionalProfileController.primaryRole
  //
  // e:
  //
  // professionalProfileController.lookingForRoles
  //
  // ============================================================

  Future<
    void
  >
  initMatchSession() async {
    // ==========================================================
    // RESET DA SESSÃO
    // ==========================================================

    isLoading = true;

    discoveryUser = null;

    recommendedUsers = [];

    remainingSeconds = 1200;

    _cancelTimers();

    safeNotify();

    // ==========================================================
    // CARREGAR PERFIL PROFISSIONAL
    // ==========================================================

    await _professionalProfileController.load();

    // ==========================================================
    // PERFIL NÃO CONFIGURADO
    // ==========================================================

    if (_professionalProfileController.primaryRole ==
        null) {
      debugPrint(
        '[MATCH] Função principal não configurada.',
      );
    }

    if (_professionalProfileController.lookingForRoles.isEmpty) {
      debugPrint(
        '[MATCH] Nenhum profissional procurado configurado.',
      );
    }

    // ==========================================================
    // REALTIME
    // ==========================================================

    _startRealtimeMatchListener();

    // ==========================================================
    // TIMEOUT DA BUSCA
    // ==========================================================

    _searchTimeoutTimer = Timer(
      const Duration(
        milliseconds: 1500,
      ),
      () {
        if (isLoading &&
            discoveryUser ==
                null &&
            recommendedUsers.isEmpty) {
          isLoading = false;

          safeNotify();
        }
      },
    );

    // ==========================================================
    // LOG
    // ==========================================================

    debugPrint(
      '[MATCH] ========================================',
    );

    debugPrint(
      '[MATCH] Sessão iniciada.',
    );

    debugPrint(
      '[MATCH] User ID: $currentUserId',
    );

    debugPrint(
      '[MATCH] Função principal: '
      '${currentPrimaryRole?.key ?? "não informado"}',
    );

    debugPrint(
      '[MATCH] Funções: '
      '${currentRoles.map((role) => role.key).toList()}',
    );

    debugPrint(
      '[MATCH] Procura: '
      '${lookingForRoles.map((role) => role.key).toList()}',
    );

    debugPrint(
      '[MATCH] ========================================',
    );
  }

  // ============================================================
  // LIMPAR RESULTADOS DO MATCH
  // ============================================================
  //
  // Usado pelo MatchRepository quando:
  //
  // - não existem usuários online;
  // - não existem candidatos compatíveis;
  // - ocorre erro no stream;
  // - a busca precisa ser reiniciada.
  //
  // Isso evita manter um discoveryUser antigo na tela.
  //
  // ============================================================

  void clearMatchResults({
    bool stopLoading = true,
  }) {
    discoveryUser = null;

    recommendedUsers = [];

    _countdownTimer?.cancel();

    _countdownTimer = null;

    remainingSeconds = 1200;

    if (stopLoading) {
      isLoading = false;
    }

    safeNotify();

    debugPrint(
      '[MATCH] Resultados limpos.',
    );
  }

  // ============================================================
  // REALTIME MATCH LISTENER
  // ============================================================

  void _startRealtimeMatchListener() {
    final userId = currentUserId;

    if (userId ==
        null) {
      debugPrint(
        '[MATCH] Não foi possível iniciar realtime: '
        'usuário não identificado.',
      );

      return;
    }

    _matchSubscription?.cancel();

    _matchSubscription = Supabase.instance.client
        .from(
          'favorites',
        )
        .stream(
          primaryKey: [
            'id',
          ],
        )
        .eq(
          'target_user_id',
          userId,
        )
        .listen(
          (
            snapshot,
          ) {
            if (snapshot.isEmpty) {
              return;
            }

            final lastMatch = snapshot.last;

            final senderId = lastMatch['sender_id']?.toString().trim();

            if (senderId ==
                    null ||
                senderId.isEmpty) {
              return;
            }

            checkAndStartNetworking(
              userId,
              senderId,
            );
          },
          onError:
              (
                error,
              ) {
                debugPrint(
                  '[MATCH] Erro realtime: $error',
                );
              },
        );
  }

  // ============================================================
  // MATCH MÚTUO
  // ============================================================

  Future<
    bool
  >
  checkAndStartNetworking(
    String myId,
    String otherId,
  ) async {
    final supabase = Supabase.instance.client;

    if (myId.trim().isEmpty ||
        otherId.trim().isEmpty ||
        myId ==
            otherId) {
      return false;
    }

    try {
      // ========================================================
      // VERIFICAR FAVORITOS MÚTUOS
      // ========================================================

      final matches = await supabase
          .from(
            'favorites',
          )
          .select(
            '*',
          )
          .or(
            'and(sender_id.eq.$myId,target_user_id.eq.$otherId),'
            'and(sender_id.eq.$otherId,target_user_id.eq.$myId)',
          );

      if (matches.length <
          2) {
        return false;
      }

      // ========================================================
      // PROJETO EXISTENTE
      // ========================================================

      final existingProject = await supabase
          .from(
            'projects',
          )
          .select(
            'id',
          )
          .contains(
            'members',
            [
              myId,
              otherId,
            ],
          )
          .maybeSingle();

      if (existingProject !=
          null) {
        final projectId = existingProject['id']?.toString().trim();

        if (projectId !=
                null &&
            projectId.isNotEmpty) {
          _matchEventController.add(
            projectId,
          );

          debugPrint(
            '[MATCH] Projeto existente encontrado: '
            '$projectId',
          );

          return true;
        }
      }

      // ========================================================
      // CRIAR PROJETO
      // ========================================================

      final newProject = await supabase
          .from(
            'projects',
          )
          .insert(
            {
              'title': 'Studio Session',

              'members': [
                myId,
                otherId,
              ],

              'status': 'active',
            },
          )
          .select(
            'id',
          )
          .single();

      final newProjectId = newProject['id']?.toString().trim();

      if (newProjectId ==
              null ||
          newProjectId.isEmpty) {
        return false;
      }

      // ========================================================
      // EMITIR EVENTO
      // ========================================================

      _matchEventController.add(
        newProjectId,
      );

      debugPrint(
        '[MATCH] Novo projeto criado: '
        '$newProjectId',
      );

      return true;
    } catch (
      error
    ) {
      debugPrint(
        '[MATCH] '
        'Erro ao iniciar networking: $error',
      );

      return false;
    }
  }

  // ============================================================
  // REGISTRAR LIKE
  // ============================================================

  Future<
    void
  >
  registerLike(
    String targetId,
  ) async {
    final userId = currentUserId;

    if (userId ==
        null) {
      debugPrint(
        '[MATCH] Like ignorado: '
        'usuário não identificado.',
      );

      return;
    }

    final normalizedTargetId = targetId.trim();

    if (normalizedTargetId.isEmpty ||
        normalizedTargetId ==
            userId) {
      return;
    }

    try {
      await Supabase.instance.client
          .from(
            'favorites',
          )
          .insert(
            {
              'sender_id': userId,

              'target_user_id': normalizedTargetId,
            },
          );

      debugPrint(
        '[MATCH] Like registrado: '
        '$userId -> $normalizedTargetId',
      );
    } on PostgrestException catch (
      error
    ) {
      // ========================================================
      // UNIQUE VIOLATION
      // ========================================================

      if (error.code ==
          '23505') {
        debugPrint(
          '[MATCH] Like já registrado.',
        );

        return;
      }

      debugPrint(
        '[MATCH] '
        'Erro Supabase ao registrar like: '
        '${error.message}',
      );
    } catch (
      error
    ) {
      debugPrint(
        '[MATCH] '
        'Erro ao registrar like: $error',
      );
    }
  }

  // ============================================================
  // DISCOVERY USER
  // ============================================================

  void setDiscoveryUser(
    MatchUserEntity user,
  ) {
    _searchTimeoutTimer?.cancel();

    _searchTimeoutTimer = null;

    discoveryUser = user;

    isLoading = false;

    startConnectionTimer();

    safeNotify();
  }

  // ============================================================
  // RECOMENDAÇÕES
  // ============================================================

  void updateRecommendedUsers(
    List<
      MatchUserEntity
    >
    users,
  ) {
    _searchTimeoutTimer?.cancel();

    _searchTimeoutTimer = null;

    recommendedUsers =
        List<
          MatchUserEntity
        >.unmodifiable(
          users,
        );

    // ==========================================================
    // BUSCA FINALIZADA
    // ==========================================================
    //
    // Mesmo com lista vazia, o Repository terminou o trabalho.
    //
    // ==========================================================

    isLoading = false;

    safeNotify();
  }

  // ============================================================
  // TIMER DE CONEXÃO
  // ============================================================

  void startConnectionTimer() {
    _countdownTimer?.cancel();

    remainingSeconds = 1200;

    _countdownTimer = Timer.periodic(
      const Duration(
        seconds: 1,
      ),
      (
        timer,
      ) {
        if (remainingSeconds >
            0) {
          remainingSeconds--;

          safeNotify();

          return;
        }

        timer.cancel();

        _countdownTimer = null;
      },
    );
  }

  // ============================================================
  // CANCELAR TIMERS
  // ============================================================

  void _cancelTimers() {
    _countdownTimer?.cancel();

    _countdownTimer = null;

    _searchTimeoutTimer?.cancel();

    _searchTimeoutTimer = null;
  }

  // ============================================================
  // CONTRATO PROVISÓRIO
  // ============================================================

  String generateProvisionalContractHash(
    String userA,
    String userB,
  ) {
    final hash =
        userA.hashCode ^
        userB.hashCode;

    return 'VRSN-$hash-'
        '${DateTime.now().millisecondsSinceEpoch}';
  }

  // ============================================================
  // FILTROS
  // ============================================================

  VoidCallback get openFilters => () {
    debugPrint(
      '[MATCH] Abrir filtros.',
    );
  };

  // ============================================================
  // DEMO
  // ============================================================

  void listenDemo() {
    debugPrint(
      '[MATCH] Reproduzir demo.',
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _cancelTimers();

    _matchSubscription?.cancel();

    _matchSubscription = null;

    if (!_matchEventController.isClosed) {
      _matchEventController.close();
    }

    // ==========================================================
    // NÃO DISPOR PROFESSIONAL PROFILE CONTROLLER
    // ==========================================================
    //
    // Ele é LazySingleton compartilhado por:
    //
    // - Dashboard;
    // - Match;
    // - Perfil profissional.
    //
    // ==========================================================

    super.dispose();
  }
}
