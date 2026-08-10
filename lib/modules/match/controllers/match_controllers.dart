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

  final StreamController<
    String
  >
  _matchEventController =
      StreamController<
        String
      >.broadcast();

  Timer? _countdownTimer;
  Timer? _searchTimeoutTimer;
  StreamSubscription? _matchSubscription;

  bool isLoading = true;
  MatchUserEntity? discoveryUser;
  List<
    MatchUserEntity
  >
  recommendedUsers = [];
  int remainingSeconds = 1200;

  Stream<
    String
  >
  get matchEventStream => _matchEventController.stream;

  Color get accentNeon => _dashboardController.accentNeon;

  Color get primaryPurple => _dashboardController.primaryPurple;

  String? get currentUserId => kDebugMode
      ? dotenv.env['DEBUG_USER_ID']
      : Supabase.instance.client.auth.currentUser?.id;

  void safeNotify() {
    if (hasListeners) {
      notifyListeners();
    }
  }

  void initMatchSession(
    UserRole currentUserRole,
  ) {
    isLoading = true;
    discoveryUser = null;
    recommendedUsers = [];

    _cancelTimers();
    _startRealtimeMatchListener();
    safeNotify();

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
  }

  void _startRealtimeMatchListener() {
    final userId = currentUserId;

    if (userId ==
        null) {
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

            checkAndStartNetworking(
              userId,
              lastMatch['sender_id'],
            );
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

    _matchEventController.add(
      newProject['id'],
    );

    return true;
  }

  Future<
    void
  >
  registerLike(
    String targetId,
  ) async {
    final userId = currentUserId;

    if (userId ==
        null) {
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
    } catch (
      e
    ) {
      debugPrint(
        '⚠️ Erro ao registrar like: $e',
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
    safeNotify();
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

    safeNotify();
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
          safeNotify();
          return;
        }

        timer.cancel();
      },
    );
  }

  void _cancelTimers() {
    _countdownTimer?.cancel();
    _searchTimeoutTimer?.cancel();
  }

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

  VoidCallback get openFilters => () {};

  void listenDemo() {}

  @override
  void dispose() {
    _cancelTimers();
    _matchSubscription?.cancel();
    _matchEventController.close();

    super.dispose();
  }
}
