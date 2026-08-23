import 'package:flutter/material.dart';

import 'package:versin/modules/match/controllers/match_controllers.dart';
import 'package:versin/modules/match/widgets/discovery_card_widget.dart';

// ============================================================
// DISCOVERY SECTION WIDGET
// ============================================================
//
// Responsável por decidir qual estado do Discovery deve ser
// exibido.
//
// Estados:
//
// - loading;
// - candidato encontrado;
// - nenhum candidato.
//
// Também faz a ponte entre:
//
// DiscoveryCardWidget
//
// e
//
// MatchController.
//
// MODOS:
//
// MATCH NORMAL:
//
// X
// -> ignora usuário atual;
// -> tenta avançar para o próximo.
//
// Coração
// -> registra like;
// -> verifica match;
// -> tenta avançar para o próximo.
//
// EXPANSÃO DE EQUIPE:
//
// X
// -> ignora usuário atual;
// -> tenta avançar para o próximo.
//
// Ação positiva
// -> NÃO registra like;
// -> NÃO cria projeto;
// -> chama onInviteUser(userId);
// -> depois avança para o próximo candidato.
//
// IMPORTANTE:
//
// Se não existir próximo usuário:
//
// - o usuário atual permanece;
// - o card não desaparece.
//
// NÃO:
//
// - consulta Supabase diretamente;
// - acessa Cloudflare R2;
// - calcula compatibilidade;
// - cria projeto;
// - cria convite;
// - reproduz demo.
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
  // STATE
  // ============================================================

  final bool isInitializingMatch;

  // ============================================================
  // TEAM EXPANSION
  // ============================================================

  final bool isTeamExpansionMode;

  // ============================================================
  // INVITATION
  // ============================================================

  final Future<
    bool
  >
  Function(
    String userId,
  )?
  onInviteUser;

  // ============================================================
  // DEMO
  // ============================================================

  final Future<
    void
  >
  Function(
    String userId,
  )?
  onListenDemo;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const DiscoverySectionWidget({
    super.key,
    required this.controller,
    required this.isInitializingMatch,
    this.isTeamExpansionMode = false,
    this.onInviteUser,
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
    // USER
    // ==========================================================

    final discoveryUser = controller.discoveryUser;

    if (discoveryUser !=
        null) {
      return DiscoveryCardWidget(
        controller: controller,

        user: discoveryUser,

        // ======================================================
        // DISMISS
        // ======================================================
        onDismiss: () {
          controller.dismissCurrentDiscoveryUser();
        },

        // ======================================================
        // POSITIVE ACTION
        // ======================================================
        onLike: () async {
          // ====================================================
          // TEAM EXPANSION
          // ====================================================

          if (isTeamExpansionMode) {
            final inviteCallback = onInviteUser;

            if (inviteCallback ==
                null) {
              debugPrint(
                '[DISCOVERY SECTION] '
                'Modo de expansão ativo, mas '
                'onInviteUser não foi configurado.',
              );

              return;
            }

            final invited = await inviteCallback(
              discoveryUser.id,
            );

            if (!invited) {
              return;
            }

            controller.moveToNextDiscoveryUser();

            return;
          }

          // ====================================================
          // NORMAL MATCH
          // ====================================================

          await controller.likeCurrentDiscoveryUserAndAdvance();
        },

        // ======================================================
        // DEMO
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
  // LOADING
  // ============================================================

  bool get _isLoading {
    return controller.isLoading ||
        isInitializingMatch;
  }

  // ============================================================
  // LOADING WIDGET
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

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          // ====================================================
          // ICON
          // ====================================================
          Icon(
            isTeamExpansionMode
                ? Icons.group_add_rounded
                : Icons.wifi_tethering_rounded,

            color: Colors.white24,

            size: 32,
          ),

          const SizedBox(
            height: 12,
          ),

          // ====================================================
          // TITLE
          // ====================================================
          Text(
            isTeamExpansionMode
                ? 'Nenhum profissional disponível para convidar.'
                : 'Nenhum profissional compatível encontrado.',

            textAlign: TextAlign.center,

            style: const TextStyle(
              color: Colors.white38,

              fontSize: 13,

              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          // ====================================================
          // SUBTITLE
          // ====================================================
          Text(
            isTeamExpansionMode
                ? 'Novos profissionais aparecerão aqui '
                      'quando estiverem disponíveis para a equipe.'
                : 'Novos profissionais aparecerão aqui '
                      'quando forem encontrados.',

            textAlign: TextAlign.center,

            style: const TextStyle(
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
