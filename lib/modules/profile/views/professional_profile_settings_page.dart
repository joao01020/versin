import 'package:flutter/material.dart';

import 'package:versin/app/locator.dart';
import 'package:versin/modules/profile/controllers/professional_profile_controller.dart';
import 'package:versin/modules/profile/models/music_role.dart';

// ============================================================
// PROFESSIONAL PROFILE SETTINGS PAGE
// ============================================================
//
// Responsabilidades da View:
//
// - mostrar funções exercidas;
// - permitir múltiplas funções;
// - selecionar função principal;
// - selecionar profissionais procurados;
// - mostrar loading;
// - mostrar erro/sucesso.
//
// Estado:
//
// ProfessionalProfileController
//
// Persistência:
//
// View
//   ↓
// ProfessionalProfileController
//   ↓
// ProfessionalProfileRepository
//   ↓
// ProfessionalProfileRepositoryImpl
//   ↓
// ProfessionalProfileRemoteDatasource
//   ↓
// Supabase
//
// ============================================================

class ProfessionalProfileSettingsPage
    extends
        StatefulWidget {
  const ProfessionalProfileSettingsPage({
    super.key,
  });

  @override
  State<
    ProfessionalProfileSettingsPage
  >
  createState() => _ProfessionalProfileSettingsPageState();
}

class _ProfessionalProfileSettingsPageState
    extends
        State<
          ProfessionalProfileSettingsPage
        > {
  // ============================================================
  // CONTROLLER
  // ============================================================

  late final ProfessionalProfileController _controller;

  // ============================================================
  // CORES
  // ============================================================

  static const Color _backgroundColor = Color(
    0xFF0D0B1F,
  );

  static const Color _surfaceColor = Color(
    0xFF17132D,
  );

  static const Color _primaryPurple = Color(
    0xFF6A1B9A,
  );

  static const Color _accentNeon = Color(
    0xFFE040FB,
  );

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    // Usa a mesma instância usada pelo Dashboard.

    _controller =
        sl<
          ProfessionalProfileController
        >();

    _controller.load();
  }

  // ============================================================
  // DISPOSE
  // ============================================================
  //
  // Não fazemos:
  //
  // _controller.dispose();
  //
  // porque o controller é singleton do GetIt.
  //
  // ============================================================

  @override
  void dispose() {
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Voltar',
          onPressed: () {
            Navigator.of(
              context,
            ).pop();
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
          ),
        ),
        title: const Text(
          'Perfil Profissional',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder:
            (
              context,
              _,
            ) {
              // ====================================================
              // LOADING INICIAL
              // ====================================================

              if (_controller.isLoading &&
                  !_controller.hasLoaded) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: _accentNeon,
                  ),
                );
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  40,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 720,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ==================================================
                        // INTRODUÇÃO
                        // ==================================================
                        _buildIntroCard(),

                        const SizedBox(
                          height: 18,
                        ),

                        // ==================================================
                        // O QUE O USUÁRIO FAZ
                        // ==================================================
                        _buildRolesCard(),

                        // ==================================================
                        // FUNÇÃO PRINCIPAL
                        // ==================================================
                        if (_controller.hasSelectedRoles) ...[
                          const SizedBox(
                            height: 18,
                          ),

                          _buildPrimaryRoleCard(),
                        ],

                        const SizedBox(
                          height: 18,
                        ),

                        // ==================================================
                        // QUEM O USUÁRIO PROCURA
                        // ==================================================
                        _buildLookingForCard(),

                        // ==================================================
                        // ERRO
                        // ==================================================
                        if (_controller.errorMessage !=
                            null) ...[
                          const SizedBox(
                            height: 14,
                          ),

                          _buildMessage(
                            message: _controller.errorMessage!,
                            error: true,
                          ),
                        ],

                        // ==================================================
                        // SUCESSO
                        // ==================================================
                        if (_controller.successMessage !=
                            null) ...[
                          const SizedBox(
                            height: 14,
                          ),

                          _buildMessage(
                            message: _controller.successMessage!,
                            error: false,
                          ),
                        ],

                        const SizedBox(
                          height: 20,
                        ),

                        // ==================================================
                        // SALVAR
                        // ==================================================
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),
              );
            },
      ),
    );
  }

  // ============================================================
  // INTRO
  // ============================================================

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _accentNeon.withValues(
                alpha: 0.08,
              ),
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
            child: const Icon(
              Icons.badge_outlined,
              color: _accentNeon,
              size: 22,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seu perfil profissional',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(
                  height: 5,
                ),

                Text(
                  'Informe suas funções profissionais e quais '
                  'profissionais você deseja encontrar. '
                  'Essas informações serão usadas pelo Conectar '
                  'para encontrar pessoas compatíveis.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // O QUE VOCÊ FAZ
  // ============================================================

  Widget _buildRolesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.work_outline_rounded,
                color: _accentNeon,
                size: 18,
              ),

              SizedBox(
                width: 8,
              ),

              Text(
                'O que você faz na música?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 5,
          ),

          const Text(
            'Você pode selecionar todas as áreas em que atua.',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: MusicRole.values.map(
              (
                role,
              ) {
                return _buildRoleChip(
                  role,
                );
              },
            ).toList(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHIP — FUNÇÃO DO USUÁRIO
  // ============================================================

  Widget _buildRoleChip(
    MusicRole role,
  ) {
    final selected = _controller.isRoleSelected(
      role,
    );

    return InkWell(
      onTap:
          _controller.isSaving ||
              _controller.isLoading
          ? null
          : () {
              _controller.toggleRole(
                role,
              );
            },
      borderRadius: BorderRadius.circular(
        14,
      ),
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 160,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: selected
              ? _primaryPurple.withValues(
                  alpha: 0.28,
                )
              : Colors.white.withValues(
                  alpha: 0.03,
                ),
          borderRadius: BorderRadius.circular(
            14,
          ),
          border: Border.all(
            color: selected
                ? _accentNeon.withValues(
                    alpha: 0.55,
                  )
                : Colors.white.withValues(
                    alpha: 0.07,
                  ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              color: selected
                  ? _accentNeon
                  : Colors.white24,
              size: 17,
            ),

            const SizedBox(
              width: 7,
            ),

            Text(
              role.label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : Colors.white70,
                fontSize: 12,
                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FUNÇÃO PRINCIPAL
  // ============================================================

  Widget _buildPrimaryRoleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.star_outline_rounded,
                color: _accentNeon,
                size: 18,
              ),

              SizedBox(
                width: 8,
              ),

              Text(
                'Função principal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 5,
          ),

          const Text(
            'Essa função será exibida abaixo do seu nome no Dashboard.',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          ..._controller.selectedRoles.map(
            _buildPrimaryRoleOption,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OPÇÃO PRINCIPAL
  // ============================================================

  Widget _buildPrimaryRoleOption(
    MusicRole role,
  ) {
    final selected = _controller.isPrimaryRole(
      role,
    );

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: InkWell(
        onTap:
            _controller.isSaving ||
                _controller.isLoading
            ? null
            : () {
                _controller.setPrimaryRole(
                  role,
                );
              },
        borderRadius: BorderRadius.circular(
          12,
        ),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 160,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: selected
                ? _primaryPurple.withValues(
                    alpha: 0.20,
                  )
                : Colors.black.withValues(
                    alpha: 0.12,
                  ),
            borderRadius: BorderRadius.circular(
              12,
            ),
            border: Border.all(
              color: selected
                  ? _accentNeon.withValues(
                      alpha: 0.40,
                    )
                  : Colors.white.withValues(
                      alpha: 0.04,
                    ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected
                    ? _accentNeon
                    : Colors.white24,
                size: 19,
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Text(
                  role.label,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : Colors.white70,
                    fontSize: 12,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),

              if (selected)
                const Text(
                  'PRINCIPAL',
                  style: TextStyle(
                    color: _accentNeon,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.7,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // QUEM VOCÊ PROCURA
  // ============================================================

  Widget _buildLookingForCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.person_search_outlined,
                color: _accentNeon,
                size: 19,
              ),

              SizedBox(
                width: 8,
              ),

              Expanded(
                child: Text(
                  'Quem você procura para se conectar?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 5,
          ),

          const Text(
            'Escolha todos os tipos de profissionais com quem '
            'você tem interesse em trabalhar.',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              height: 1.4,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: MusicRole.values.map(
              (
                role,
              ) {
                return _buildLookingForChip(
                  role,
                );
              },
            ).toList(),
          ),

          if (_controller.hasLookingForRoles) ...[
            const SizedBox(
              height: 16,
            ),

            _buildLookingForSummary(),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // CHIP — QUEM PROCURA
  // ============================================================

  Widget _buildLookingForChip(
    MusicRole role,
  ) {
    final selected = _controller.isLookingForRoleSelected(
      role,
    );

    return InkWell(
      onTap:
          _controller.isSaving ||
              _controller.isLoading
          ? null
          : () {
              _controller.toggleLookingForRole(
                role,
              );
            },
      borderRadius: BorderRadius.circular(
        14,
      ),
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 160,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: selected
              ? _primaryPurple.withValues(
                  alpha: 0.28,
                )
              : Colors.white.withValues(
                  alpha: 0.03,
                ),
          borderRadius: BorderRadius.circular(
            14,
          ),
          border: Border.all(
            color: selected
                ? _accentNeon.withValues(
                    alpha: 0.55,
                  )
                : Colors.white.withValues(
                    alpha: 0.07,
                  ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? Icons.person_search_rounded
                  : Icons.person_outline_rounded,
              color: selected
                  ? _accentNeon
                  : Colors.white24,
              size: 17,
            ),

            const SizedBox(
              width: 7,
            ),

            Text(
              role.label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : Colors.white70,
                fontSize: 12,
                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RESUMO — QUEM PROCURA
  // ============================================================

  Widget _buildLookingForSummary() {
    final labels = _controller.lookingForRoleLabels;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        12,
      ),
      decoration: BoxDecoration(
        color: _accentNeon.withValues(
          alpha: 0.05,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: _accentNeon.withValues(
            alpha: 0.12,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.hub_outlined,
            color: _accentNeon,
            size: 17,
          ),

          const SizedBox(
            width: 9,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Você procura',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  labels.join(
                    ' • ',
                  ),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SALVAR
  // ============================================================

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed:
            _controller.isSaving ||
                _controller.isLoading
            ? null
            : () async {
                await _controller.save();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryPurple,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primaryPurple.withValues(
            alpha: 0.25,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              14,
            ),
          ),
          side: BorderSide(
            color: _accentNeon.withValues(
              alpha: 0.35,
            ),
          ),
        ),
        icon: _controller.isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.save_outlined,
                size: 19,
              ),
        label: Text(
          _controller.isSaving
              ? 'SALVANDO...'
              : 'SALVAR CONFIGURAÇÕES',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.7,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  Widget _buildMessage({
    required String message,
    required bool error,
  }) {
    final color = error
        ? Colors.redAccent
        : Colors.greenAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        12,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.07,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: color.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            error
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: color,
            size: 17,
          ),

          const SizedBox(
            width: 9,
          ),

          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _surfaceColor.withValues(
        alpha: 0.72,
      ),
      borderRadius: BorderRadius.circular(
        20,
      ),
      border: Border.all(
        color: Colors.white.withValues(
          alpha: 0.07,
        ),
      ),
    );
  }
}
