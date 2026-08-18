import 'package:flutter/material.dart';

import 'package:versin/modules/match/controllers/match_controllers.dart';

import 'discovery_card_widget.dart';

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
// -> o nível superior cria project_invitations;
// -> depois avança para o próximo candidato.
//
// IMPORTANTE:
//
// Se não existir próximo usuário:
//
// - o usuário atual permanece;
// - o card não desaparece.
//
// Também repassa:
//
// - ação assíncrona de ouvir demo.
//
// NÃO:
//
// - consulta Supabase diretamente;
// - acessa Cloudflare R2;
// - calcula compatibilidade;
// - cria projeto manualmente;
// - cria convite diretamente;
// - navega para Networking;
// - reproduz demo.
//
// Essas responsabilidades continuam nos níveis superiores.
//
// ============================================================

class DiscoverySectionWidget extends StatelessWidget {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final MatchController controller;

  // ============================================================
  // ESTADO
  // ============================================================

  final bool isInitializingMatch;

  // ============================================================
  // MODO DE EXPANSÃO
  // ============================================================
  //
  // false:
  // -> fluxo normal de Match.
  //
  // true:
  // -> usuário está procurando alguém para uma equipe existente.
  //
  // ============================================================

  final bool isTeamExpansionMode;

  // ============================================================
  // CONVITE
  // ============================================================
  //
  // Chamado somente no modo de expansão.
  //
  // Recebe o ID do profissional mostrado no card.
  //
  // O MatchPage será responsável por:
  //
  // - conhecer targetProjectId;
  // - criar project_invitations;
  // - mostrar sucesso/erro;
  // - decidir navegação.
  //
  // Retorna bool:
  //
  // true
  // -> convite criado com sucesso;
  // -> avança para o próximo candidato.
  //
  // false
  // -> convite não foi criado;
  // -> mantém o candidato atual.
  //
  // ============================================================

  final Future<bool> Function(String userId)? onInviteUser;

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

  final Future<void> Function(String userId)? onListenDemo;

  // ============================================================
  // CONSTRUTOR
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
  Widget build(BuildContext context) {
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

    if (discoveryUser != null) {
      return DiscoveryCardWidget(
        controller: controller,

        user: discoveryUser,

        // ======================================================
        // REJEITAR / IGNORAR
        // ======================================================
        onDismiss: () {
          controller.dismissCurrentDiscoveryUser();
        },

        // ======================================================
        // AÇÃO POSITIVA
        // ======================================================
        //
        // MATCH NORMAL:
        //
        // -> LIKE.
        //
        // EXPANSÃO:
        //
        // -> CONVITE.
        //
        // IMPORTANTE:
        //
        // no modo de expansão NÃO chamamos:
        //
        // controller.likeCurrentDiscoveryUserAndAdvance()
        //
        // porque isso poderia registrar favorite e disparar o
        // fluxo normal de criação de Studio Session.
        //
        // ======================================================
        onLike: () async {
          // ====================================================
          // EXPANSÃO DE EQUIPE
          // ====================================================

          if (isTeamExpansionMode) {
            final inviteCallback = onInviteUser;

            if (inviteCallback == null) {
              debugPrint(
                '[DISCOVERY SECTION] '
                'Modo de expansão ativo, mas '
                'onInviteUser não foi configurado.',
              );

              return;
            }

            final invited = await inviteCallback(discoveryUser.id);

            if (!invited) {
              return;
            }

            controller.moveToNextDiscoveryUser();

            return;
          }

          // ====================================================
          // MATCH NORMAL
          // ====================================================

          await controller.likeCurrentDiscoveryUserAndAdvance();
        },

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
        onListenDemo: onListenDemo == null
            ? null
            : () async {
                await onListenDemo!(discoveryUser.id);
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
    return controller.isLoading || isInitializingMatch;
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return Container(
      width: double.infinity,

      height: 220,

      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),

        borderRadius: BorderRadius.circular(24),

        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),

      child: const Center(
        child: CircularProgressIndicator(color: Colors.purple),
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

      padding: const EdgeInsets.symmetric(horizontal: 24),

      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),

        borderRadius: BorderRadius.circular(24),

        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          // ====================================================
          // ÍCONE
          // ====================================================
          Icon(
            isTeamExpansionMode
                ? Icons.group_add_rounded
                : Icons.wifi_tethering_rounded,

            color: Colors.white24,

            size: 32,
          ),

          const SizedBox(height: 12),

          // ====================================================
          // TÍTULO
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

          const SizedBox(height: 6),

          // ====================================================
          // SUBTÍTULO
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
