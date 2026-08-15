import 'package:flutter/material.dart';

import 'package:versin/modules/match/controllers/match_controllers.dart';
import 'package:versin/modules/profile/controllers/professional_profile_controller.dart';

// ============================================================
// CONNECTION PROFILE CARD WIDGET
// ============================================================
//
// Card responsável por mostrar:
//
// - função profissional principal;
// - profissionais procurados;
// - estado de carregamento;
// - expansão / recolhimento;
// - acesso à edição do perfil profissional.
//
// Este widget NÃO:
//
// - navega diretamente;
// - reinicia o Match;
// - acessa repository;
// - acessa Supabase.
//
// A MatchPage fornece:
//
// - controllers;
// - callback para editar perfil.
//
// ============================================================

class ConnectionProfileCardWidget
    extends
        StatefulWidget {
  final MatchController matchController;

  final ProfessionalProfileController profileController;

  final bool isInitializingMatch;

  final Future<
    void
  >
  Function()
  onEditProfile;

  const ConnectionProfileCardWidget({
    super.key,
    required this.matchController,
    required this.profileController,
    required this.isInitializingMatch,
    required this.onEditProfile,
  });

  @override
  State<
    ConnectionProfileCardWidget
  >
  createState() => _ConnectionProfileCardWidgetState();
}

// ============================================================
// STATE
// ============================================================

class _ConnectionProfileCardWidgetState
    extends
        State<
          ConnectionProfileCardWidget
        > {
  // ============================================================
  // EXPANSÃO
  // ============================================================

  bool _isExpanded = true;

  // ============================================================
  // GETTERS
  // ============================================================

  MatchController get matchController => widget.matchController;

  ProfessionalProfileController get profileController => widget.profileController;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final lookingFor = profileController.lookingForRoleLabels;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color:
            const Color(
              0xFF17132D,
            ).withValues(
              alpha: 0.90,
            ),
        borderRadius: BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.07,
          ),
        ),
      ),
      child: Column(
        children: [
          // ====================================================
          // HEADER
          // ====================================================
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(
              22,
            ),
            child: Padding(
              padding: const EdgeInsets.all(
                16,
              ),
              child: Row(
                children: [
                  // ============================================
                  // ÍCONE
                  // ============================================
                  Tooltip(
                    message: 'Editar perfil profissional',
                    child: InkWell(
                      onTap: widget.onEditProfile,
                      borderRadius: BorderRadius.circular(
                        50,
                      ),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: matchController.accentNeon.withValues(
                            alpha: 0.10,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: matchController.accentNeon.withValues(
                              alpha: 0.30,
                            ),
                          ),
                        ),
                        child: Icon(
                          Icons.person_search_rounded,
                          color: matchController.accentNeon,
                          size: 22,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 13,
                  ),

                  // ============================================
                  // TEXTO
                  // ============================================
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Você quer se conectar com',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(
                          height: 3,
                        ),

                        Text(
                          profileController.isLoading ||
                                  widget.isInitializingMatch
                              ? 'Carregando perfil...'
                              : lookingFor.isEmpty
                              ? 'Não informado'
                              : lookingFor.length ==
                                    1
                              ? '1 tipo de profissional'
                              : '${lookingFor.length} tipos de profissionais',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ============================================
                  // EDITAR
                  // ============================================
                  IconButton(
                    tooltip: 'Editar perfil profissional',
                    onPressed: widget.onEditProfile,
                    icon: Icon(
                      Icons.edit_outlined,
                      color: matchController.accentNeon,
                      size: 18,
                    ),
                  ),

                  // ============================================
                  // EXPANDIR
                  // ============================================
                  AnimatedRotation(
                    turns: _isExpanded
                        ? 0
                        : 0.5,
                    duration: const Duration(
                      milliseconds: 180,
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: Colors.white54,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ====================================================
          // CONTEÚDO EXPANDIDO
          // ====================================================
          AnimatedCrossFade(
            duration: const Duration(
              milliseconds: 180,
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _buildExpandedContent(),
            secondChild: const SizedBox(
              width: double.infinity,
              height: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTEÚDO EXPANDIDO
  // ============================================================

  Widget _buildExpandedContent() {
    if (profileController.isLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          18,
        ),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.purpleAccent,
            ),
          ),
        ),
      );
    }

    final lookingForRoles = profileController.lookingForRoles.toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            height: 1,
            color: Colors.white.withValues(
              alpha: 0.06,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          // ====================================================
          // FUNÇÃO PRINCIPAL
          // ====================================================
          Row(
            children: [
              const Text(
                'Sua função principal:',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),

              const SizedBox(
                width: 6,
              ),

              Flexible(
                child: Text(
                  profileController.primaryRoleLabel,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: matchController.accentNeon,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          // ====================================================
          // TÍTULO
          // ====================================================
          const Text(
            'PROFISSIONAIS PROCURADOS',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          // ====================================================
          // ROLES
          // ====================================================
          if (lookingForRoles.isEmpty)
            _buildEmptyLookingFor()
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: lookingForRoles.map(
                (
                  role,
                ) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: matchController.accentNeon.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(
                        20,
                      ),
                      border: Border.all(
                        color: matchController.accentNeon.withValues(
                          alpha: 0.20,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_search_outlined,
                          color: matchController.accentNeon,
                          size: 13,
                        ),

                        const SizedBox(
                          width: 5,
                        ),

                        Text(
                          role.label,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ).toList(),
            ),

          const SizedBox(
            height: 16,
          ),

          // ====================================================
          // EDITAR
          // ====================================================
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onEditProfile,
              style: OutlinedButton.styleFrom(
                foregroundColor: matchController.accentNeon,
                side: BorderSide(
                  color: matchController.accentNeon.withValues(
                    alpha: 0.25,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              icon: const Icon(
                Icons.tune_rounded,
                size: 16,
              ),
              label: const Text(
                'EDITAR PERFIL PROFISSIONAL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NÃO INFORMADO
  // ============================================================

  Widget _buildEmptyLookingFor() {
    return InkWell(
      onTap: widget.onEditProfile,
      borderRadius: BorderRadius.circular(
        12,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(
          14,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(
            alpha: 0.025,
          ),
          borderRadius: BorderRadius.circular(
            12,
          ),
          border: Border.all(
            color: Colors.white.withValues(
              alpha: 0.06,
            ),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Colors.white24,
              size: 17,
            ),

            const SizedBox(
              width: 9,
            ),

            const Expanded(
              child: Text(
                'Não informado. Toque para escolher '
                'com quem você deseja se conectar.',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ),

            Icon(
              Icons.chevron_right_rounded,
              color: matchController.accentNeon,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EXPANDIR / RECOLHER
  // ============================================================

  void _toggleExpanded() {
    setState(
      () {
        _isExpanded = !_isExpanded;
      },
    );
  }
}
