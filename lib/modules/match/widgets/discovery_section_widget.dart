import 'package:flutter/material.dart';

import 'package:versin/modules/match/controllers/match_controllers.dart';

import 'discovery_card_widget.dart';

// ============================================================
// DISCOVERY SECTION WIDGET
// ============================================================
//
// Responsável somente por decidir qual estado do Discovery
// deve ser exibido.
//
// Estados:
//
// - loading;
// - candidato encontrado;
// - nenhum candidato.
//
// Também repassa:
//
// - ação assíncrona de ouvir demo.
//
// NÃO:
//
// - consulta Supabase;
// - acessa Cloudflare R2;
// - calcula compatibilidade;
// - inicia Match;
// - controla recomendações;
// - abre perfil;
// - reproduz demo.
//
// Essas ações pertencem aos níveis superiores.
//
// ============================================================

class DiscoverySectionWidget
    extends
        StatelessWidget {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final MatchController controller;

  // ============================================================
  // ESTADO
  // ============================================================

  final bool isInitializingMatch;

  // ============================================================
  // DEMO
  // ============================================================
  //
  // Recebe o ID do usuário selecionado.
  //
  // Retorna Future<void> porque o fluxo superior pode:
  //
  // - buscar track;
  // - solicitar playbackUrl;
  // - abrir modal;
  // - inicializar player.
  //
  // O MatchPage decide o que fazer com esse ID.
  //
  // ============================================================

  final Future<
    void
  >
  Function(
    String userId,
  )?
  onListenDemo;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const DiscoverySectionWidget({
    super.key,
    required this.controller,
    required this.isInitializingMatch,
    this.onListenDemo,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    // ==========================================================
    // LOADING
    // ==========================================================

    if (_isLoading) {
      return _buildLoading();
    }

    // ==========================================================
    // DISCOVERY USER
    // ==========================================================

    final discoveryUser = controller.discoveryUser;

    if (discoveryUser !=
        null) {
      return DiscoveryCardWidget(
        controller: controller,

        user: discoveryUser,

        // ======================================================
        // OUVIR DEMO
        // ======================================================
        //
        // O Card não recebe userId diretamente no callback.
        //
        // Então fazemos a ponte:
        //
        // Card
        //   ↓
        // callback()
        //   ↓
        // Section
        //   ↓
        // onListenDemo(userId)
        //
        // ======================================================
        onListenDemo:
            onListenDemo ==
                null
            ? null
            : () async {
                await onListenDemo!(
                  discoveryUser.id,
                );
              },
      );
    }

    // ==========================================================
    // EMPTY
    // ==========================================================

    return _buildEmpty();
  }

  // ============================================================
  // IS LOADING
  // ============================================================

  bool get _isLoading {
    return controller.isLoading ||
        isInitializingMatch;
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return Container(
      width: double.infinity,

      height: 220,

      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.02,
        ),

        borderRadius: BorderRadius.circular(
          24,
        ),

        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.04,
          ),
        ),
      ),

      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.purple,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,

      height: 160,

      padding: const EdgeInsets.symmetric(
        horizontal: 24,
      ),

      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.02,
        ),

        borderRadius: BorderRadius.circular(
          24,
        ),

        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.06,
          ),
        ),
      ),

      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          // ====================================================
          // ÍCONE
          // ====================================================
          Icon(
            Icons.wifi_tethering_rounded,
            color: Colors.white24,
            size: 32,
          ),

          SizedBox(
            height: 12,
          ),

          // ====================================================
          // TÍTULO
          // ====================================================
          Text(
            'Nenhum profissional compatível encontrado.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          SizedBox(
            height: 6,
          ),

          // ====================================================
          // SUBTÍTULO
          // ====================================================
          Text(
            'Novos profissionais aparecerão aqui quando forem encontrados.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
