import 'dart:async';
import 'package:flutter/material.dart';
import 'package:versin/app/locator.dart';
import '../data/repositories/match_repository.dart';
import '../controllers/match_controllers.dart';
import '../models/match_user_entity.dart';
import '../widgets/discovery_card_widget.dart';
import '../widgets/profile_tile_widget.dart';
import '../../networking/views/networking_session_view.dart';

class MatchPage
    extends
        StatefulWidget {
  static const String routeName = '/match';
  const MatchPage({
    super.key,
  });

  @override
  State<
    MatchPage
  >
  createState() => _MatchPageState();
}

class _MatchPageState
    extends
        State<
          MatchPage
        > {
  // Alterado para buscar via locator (sl) se disponível, ou manter a instância
  final MatchController _matchController = MatchController();
  StreamSubscription? _matchSubscription;

  @override
  void initState() {
    super.initState();

    // 1. Escutando o evento de match antes de iniciar a sessão
    _matchSubscription = _matchController.matchEventStream.listen(
      (
        projectId,
      ) {
        debugPrint(
          "🎯 MatchPage: Evento recebido no stream! Projeto: $projectId",
        );
        if (mounted) {
          navigateToNetworkingSession(
            projectId,
          );
        }
      },
      onError:
          (
            e,
          ) => debugPrint(
            "❌ Erro no stream de match: $e",
          ),
    );

    // 2. Inicializa a sessão
    _matchController.initMatchSession(
      UserRole.artist,
    );
    _matchController.addListener(
      _onControllerUpdate,
    );

    // 3. Carrega os dados
    sl<
          MatchRepository
        >()
        .streamCrossRoleMatches(
          _matchController,
          UserRole.artist,
        );
  }

  void navigateToNetworkingSession(
    String projectId,
  ) {
    debugPrint(
      "🚀 Navegando para NetworkingSessionView com ID: $projectId",
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => NetworkingSessionView(
              projectId: projectId,
            ),
      ),
    );
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(
        () {},
      );
    }
  }

  @override
  void dispose() {
    _matchSubscription?.cancel();
    _matchController.removeListener(
      _onControllerUpdate,
    );
    _matchController.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final bool hasNoDiscovery =
        _matchController.discoveryUser ==
        null;
    final bool hasNoRecommendations = _matchController.recommendedUsers.isEmpty;

    return Scaffold(
      backgroundColor: const Color(
        0xFF0D0B1F,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Novas Conexões",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Encontre sua parceria profissional",
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.tune,
                    color: _matchController.accentNeon,
                  ),
                  onPressed: _matchController.openFilters,
                ),
              ],
            ),
            const SizedBox(
              height: 24,
            ),
            if (_matchController.isLoading) ...[
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.02,
                  ),
                  borderRadius: BorderRadius.circular(
                    24,
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.purple,
                  ),
                ),
              ),
              const SizedBox(
                height: 24,
              ),
            ] else if (!hasNoDiscovery) ...[
              DiscoveryCardWidget(
                controller: _matchController,
                user: _matchController.discoveryUser!,
              ),
              const SizedBox(
                height: 24,
              ),
            ] else ...[
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.02,
                  ),
                  borderRadius: BorderRadius.circular(
                    24,
                  ),
                  border: Border.all(
                    color: Colors.white10,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_tethering,
                      color: Colors.white24,
                      size: 32,
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    Text(
                      "Buscando novos talentos...",
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 24,
              ),
            ],
            const Text(
              "Recomendados para você",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            if (_matchController.isLoading)
              const Center(
                child: Text(
                  "Processando vitrines pela IA...",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              )
            else if (!hasNoRecommendations)
              Column(
                children: _matchController.recommendedUsers
                    .map(
                      (
                        user,
                      ) => ProfileTileWidget(
                        user: user,
                        controller: _matchController,
                      ),
                    )
                    .toList(),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 20,
                ),
                child: Center(
                  child: Text(
                    "Nenhuma recomendação disponível.",
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }
}
