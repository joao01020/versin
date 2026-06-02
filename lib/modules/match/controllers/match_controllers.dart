import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:versin/app/locator.dart';
import 'package:versin/modules/dashboard/controllers/dashboard_controller.dart';
import '../models/match_user_entity.dart';

class MatchController
    with
        ChangeNotifier {
  final DashboardController _dashboardController =
      sl<
        DashboardController
      >();

  // Stream para notificar a View sobre um novo match criado
  final StreamController<
    String
  >
  _matchEventController =
      StreamController<
        String
      >.broadcast();
  Stream<
    String
  >
  get matchEventStream => _matchEventController.stream;

  Color get accentNeon => _dashboardController.accentNeon;
  Color get primaryPurple => _dashboardController.primaryPurple;

  bool isLoading = true;
  MatchUserEntity? discoveryUser;
  List<
    MatchUserEntity
  >
  recommendedUsers = [];

  Timer? _countdownTimer;
  Timer? _searchTimeoutTimer;
  StreamSubscription? _matchSubscription;

  // Lógica de ID de usuário segura para Git
  String? get currentUserId {
    if (kDebugMode) {
      return dotenv.env['DEBUG_USER_ID'];
    }
    return Supabase.instance.client.auth.currentUser?.id;
  }

  void initMatchSession(
    UserRole currentUserRole,
  ) {
    isLoading = true;
    discoveryUser = null;
    recommendedUsers = [];

    _countdownTimer?.cancel();
    _searchTimeoutTimer?.cancel();

    _startRealtimeMatchListener();

    notifyListeners();

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
          notifyListeners();
        }
      },
    );
  }

  void _startRealtimeMatchListener() {
    if (currentUserId ==
        null)
      return;

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
          currentUserId!,
        )
        .listen(
          (
            List<
              Map<
                String,
                dynamic
              >
            >
            snapshot,
          ) {
            if (snapshot.isNotEmpty) {
              final lastMatch = snapshot.last;
              debugPrint(
                "Instant Match received: $lastMatch",
              );

              checkAndStartNetworking(
                currentUserId!,
                lastMatch['sender_id'],
              );

              notifyListeners();
            }
          },
        );
  }

  Future<
    bool
  >
  checkAndStartNetworking(
    String myId,
    String otherId,
  ) async {
    final supabase = Supabase.instance.client;

    debugPrint(
      "🔍 Verificando match mútuo entre $myId e $otherId",
    );

    // Consulta robusta usando OR com AND para buscar ambos os lados
    final response = await supabase
        .from(
          'favorites',
        )
        .select(
          '*',
        )
        .or(
          'and(sender_id.eq.$myId,target_user_id.eq.$otherId),and(sender_id.eq.$otherId,target_user_id.eq.$myId)',
        );

    final List<
      dynamic
    >
    matches =
        response
            as List<
              dynamic
            >;
    debugPrint(
      "🔍 Registros de like encontrados: ${matches.length}",
    );

    // Se temos pelo menos 2 registros, o match é mútuo
    if (matches.length >=
        2) {
      debugPrint(
        "✅ MATCH MÚTUO CONFIRMADO!",
      );

      // Verifica se já existe um projeto para evitar duplicatas
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
        debugPrint(
          "ℹ️ Projeto já existente: ${existingProject['id']}",
        );
        _matchEventController.add(
          existingProject['id'],
        );
        return true;
      }

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
          .select()
          .single();

      debugPrint(
        "🚀 Networking room successfully created: ${newProject['id']}",
      );

      // Emite o ID do projeto recém-criado para a View navegar
      _matchEventController.add(
        newProject['id'],
      );

      return true;
    }

    debugPrint(
      "⏳ Ainda não há match mútuo confirmado.",
    );
    return false;
  }

  Future<
    void
  >
  registerLike(
    String targetId,
  ) async {
    if (currentUserId ==
        null)
      return;

    try {
      await Supabase.instance.client
          .from(
            'favorites',
          )
          .insert(
            {
              'sender_id': currentUserId,
              'target_user_id': targetId,
            },
          );
      debugPrint(
        "👍 Like registrado com sucesso para $targetId",
      );
    } catch (
      e
    ) {
      debugPrint(
        "⚠️ Erro ao registrar like: $e",
      );
    }
  }

  void setDiscoveryUser(
    MatchUserEntity user,
  ) {
    _searchTimeoutTimer?.cancel();
    discoveryUser = user;
    isLoading = false;
    startConnectionTimer();
    notifyListeners();
  }

  void updateRecommendedUsers(
    List<
      MatchUserEntity
    >
    users,
  ) {
    _searchTimeoutTimer?.cancel();
    recommendedUsers = users;
    if (discoveryUser !=
        null) {
      isLoading = false;
    }
    notifyListeners();
  }

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
          notifyListeners();
        } else {
          _countdownTimer?.cancel();
        }
      },
    );
  }

  int remainingSeconds = 1200;

  String generateProvisionalContractHash(
    String userA,
    String userB,
  ) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return "VRSN-${userA.hashCode ^ userB.hashCode}-$timestamp";
  }

  VoidCallback get openFilters => () {};

  void listenDemo() {}

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _searchTimeoutTimer?.cancel();
    _matchSubscription?.cancel();
    _matchEventController.close(); // Fecha o stream corretamente
    super.dispose();
  }
}
