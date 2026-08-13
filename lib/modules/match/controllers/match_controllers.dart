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
// - controlar recomendações;
// - registrar likes;
// - detectar match mútuo;
// - iniciar projeto/networking;
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
  // NOTIFY
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
  // Agora NÃO recebe mais:
  //
  // UserRole.artist
  //
  // A sessão usa:
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
    isLoading = true;

    discoveryUser = null;

    recommendedUsers = [];

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
    // TIMEOUT DE BUSCA
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

            final senderId = lastMatch['sender_id']?.toString();

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
        final projectId = existingProject['id']?.toString();

        if (projectId !=
                null &&
            projectId.isNotEmpty) {
          _matchEventController.add(
            projectId,
          );

          return true;
        }
      }

      // ========================================================
      // CRIAR NOVO PROJETO
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

      final newProjectId = newProject['id']?.toString();

      if (newProjectId ==
              null ||
          newProjectId.isEmpty) {
        return false;
      }

      _matchEventController.add(
        newProjectId,
      );

      return true;
    } catch (
      error
    ) {
      debugPrint(
        '[MATCH] Erro ao iniciar networking: $error',
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
        '[MATCH] Like ignorado: usuário não identificado.',
      );

      return;
    }

    if (targetId.trim().isEmpty ||
        targetId ==
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

              'target_user_id': targetId,
            },
          );

      debugPrint(
        '[MATCH] Like registrado: '
        '$userId -> $targetId',
      );
    } on PostgrestException catch (
      error
    ) {
      // ========================================================
      // UNIQUE VIOLATION
      // ========================================================
      //
      // Caso o usuário clique novamente em alguém já curtido,
      // evitamos quebrar a tela.
      //
      // ========================================================

      if (error.code ==
          '23505') {
        debugPrint(
          '[MATCH] Like já registrado.',
        );

        return;
      }

      debugPrint(
        '[MATCH] Erro Supabase ao registrar like: '
        '${error.message}',
      );
    } catch (
      error
    ) {
      debugPrint(
        '[MATCH] Erro ao registrar like: $error',
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

    recommendedUsers = users;

    // Se existem recomendações, a busca terminou
    // mesmo que discoveryUser ainda seja null.

    if (recommendedUsers.isNotEmpty ||
        discoveryUser !=
            null) {
      isLoading = false;
    }

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

  void listenDemo() {}

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _cancelTimers();

    _matchSubscription?.cancel();

    _matchSubscription = null;

    _matchEventController.close();

    // NÃO damos dispose no:
    //
    // _professionalProfileController
    //
    // porque ele é LazySingleton do GetIt.

    super.dispose();
  }
}
