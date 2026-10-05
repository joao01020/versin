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
                      maxWidth: 820,
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

                        const SizedBox(
                          height: 14,
                        ),

                        // ==================================================
                        // QUEM O USUÁRIO PROCURA
                        // ==================================================
                        _buildLookingForCard(),

                        // ==================================================
                        // FUNÇÃO PRINCIPAL
                        // ==================================================
                        if (_controller.hasSelectedRoles) ...[
                          const SizedBox(
                            height: 14,
                          ),

                          _buildPrimaryRoleCard(),
                        ],

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
    final roleCount = _controller.selectedRoles.length;
    final lookingCount = _controller.lookingForRoles.length;
    final primaryRole = _controller.primaryRole;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _primaryPurple.withValues(
              alpha: 0.25,
            ),
            _surfaceColor.withValues(
              alpha: 0.90,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color: _accentNeon.withValues(
            alpha: 0.12,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _accentNeon.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                  border: Border.all(
                    color: _accentNeon.withValues(
                      alpha: 0.16,
                    ),
                  ),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: _accentNeon,
                  size: 22,
                ),
              ),
              const SizedBox(
                width: 13,
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seu perfil profissional',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    Text(
                      'Organize sua identidade profissional e diga ao '
                      'Conectar quais perfis fazem sentido para você.',
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
          const SizedBox(
            height: 16,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMiniStatus(
                icon: Icons.work_outline_rounded,
                label:
                    roleCount ==
                        1
                    ? '1 área selecionada'
                    : '$roleCount áreas selecionadas',
                active:
                    roleCount >
                    0,
              ),
              _buildMiniStatus(
                icon: Icons.person_search_outlined,
                label:
                    lookingCount ==
                        1
                    ? '1 perfil procurado'
                    : '$lookingCount perfis procurados',
                active:
                    lookingCount >
                    0,
              ),
              _buildMiniStatus(
                icon: Icons.star_rounded,
                label:
                    primaryRole?.label ??
                    'Função principal pendente',
                active:
                    primaryRole !=
                    null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatus({
    required IconData icon,
    required String label,
    required bool active,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: active
            ? _accentNeon.withValues(
                alpha: 0.07,
              )
            : Colors.white.withValues(
                alpha: 0.025,
              ),
        borderRadius: BorderRadius.circular(
          999,
        ),
        border: Border.all(
          color: active
              ? _accentNeon.withValues(
                  alpha: 0.15,
                )
              : Colors.white.withValues(
                  alpha: 0.05,
                ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: active
                ? _accentNeon
                : Colors.white24,
            size: 13,
          ),
          const SizedBox(
            width: 6,
          ),
          Text(
            label,
            style: TextStyle(
              color: active
                  ? Colors.white70
                  : Colors.white38,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
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
    return _buildSectionCard(
      icon: Icons.work_outline_rounded,
      title: 'O que você faz na música?',
      subtitle: 'Selecione todas as áreas em que você atua.',
      badge: '${_controller.selectedRoles.length}',
      child: Wrap(
        spacing: 9,
        runSpacing: 9,
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
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
          12,
        ),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: selected
                ? _accentNeon.withValues(
                    alpha: 0.075,
                  )
                : Colors.white.withValues(
                    alpha: 0.025,
                  ),
            borderRadius: BorderRadius.circular(
              12,
            ),
            border: Border.all(
              color: selected
                  ? _accentNeon.withValues(
                      alpha: 0.38,
                    )
                  : Colors.white.withValues(
                      alpha: 0.055,
                    ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(
                  milliseconds: 150,
                ),
                child: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  key:
                      ValueKey<
                        bool
                      >(
                        selected,
                      ),
                  color: selected
                      ? _accentNeon
                      : Colors.white24,
                  size: 16,
                ),
              ),
              const SizedBox(
                width: 7,
              ),
              Text(
                role.label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.white60,
                  fontSize: 11.5,
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FUNÇÃO PRINCIPAL
  // ============================================================

  Widget _buildPrimaryRoleCard() {
    return _buildSectionCard(
      icon: Icons.star_outline_rounded,
      title: 'Função principal',
      subtitle: 'Escolha uma das suas áreas para aparecer abaixo do seu nome no Dashboard.',
      badge: _controller.primaryRole?.label,
      child: Column(
        children: _controller.selectedRoles
            .map(
              _buildPrimaryRoleOption,
            )
            .toList(),
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
      child: Material(
        color: Colors.transparent,
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
            13,
          ),
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 180,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? _primaryPurple.withValues(
                      alpha: 0.20,
                    )
                  : Colors.black.withValues(
                      alpha: 0.10,
                    ),
              borderRadius: BorderRadius.circular(
                13,
              ),
              border: Border.all(
                color: selected
                    ? _accentNeon.withValues(
                        alpha: 0.32,
                      )
                    : Colors.white.withValues(
                        alpha: 0.04,
                      ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 31,
                  height: 31,
                  decoration: BoxDecoration(
                    color: selected
                        ? _accentNeon.withValues(
                            alpha: 0.09,
                          )
                        : Colors.white.withValues(
                            alpha: 0.025,
                          ),
                    borderRadius: BorderRadius.circular(
                      9,
                    ),
                  ),
                  child: Icon(
                    selected
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: selected
                        ? _accentNeon
                        : Colors.white24,
                    size: 16,
                  ),
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
                          : Colors.white60,
                      fontSize: 11.5,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _accentNeon.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(
                        999,
                      ),
                    ),
                    child: const Text(
                      'PRINCIPAL',
                      style: TextStyle(
                        color: _accentNeon,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withValues(
                      alpha: 0.14,
                    ),
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // QUEM VOCÊ PROCURA
  // ============================================================

  Widget _buildLookingForCard() {
    return _buildSectionCard(
      icon: Icons.person_search_outlined,
      title: 'Quem você procura para se conectar?',
      subtitle: 'Escolha os tipos de profissionais com quem você quer trabalhar.',
      badge: '${_controller.lookingForRoles.length}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 9,
            runSpacing: 9,
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
              height: 14,
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
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
          12,
        ),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: selected
                ? _primaryPurple.withValues(
                    alpha: 0.22,
                  )
                : Colors.white.withValues(
                    alpha: 0.025,
                  ),
            borderRadius: BorderRadius.circular(
              12,
            ),
            border: Border.all(
              color: selected
                  ? _accentNeon.withValues(
                      alpha: 0.36,
                    )
                  : Colors.white.withValues(
                      alpha: 0.055,
                    ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected
                    ? Icons.group_add_rounded
                    : Icons.person_add_alt_outlined,
                color: selected
                    ? _accentNeon
                    : Colors.white24,
                size: 16,
              ),
              const SizedBox(
                width: 7,
              ),
              Text(
                role.label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.white60,
                  fontSize: 11.5,
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(
          alpha: 0.12,
        ),
        borderRadius: BorderRadius.circular(
          11,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.04,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.hub_outlined,
            color: _accentNeon,
            size: 15,
          ),
          const SizedBox(
            width: 8,
          ),
          Expanded(
            child: Text(
              labels.join(
                '  •  ',
              ),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 9.5,
                height: 1.4,
              ),
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
  // SECTION CARD
  // ============================================================

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
    String? badge,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _accentNeon.withValues(
                    alpha: 0.07,
                  ),
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                  border: Border.all(
                    color: _accentNeon.withValues(
                      alpha: 0.10,
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  color: _accentNeon,
                  size: 17,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge !=
                      null &&
                  badge.trim().isNotEmpty) ...[
                const SizedBox(
                  width: 10,
                ),
                Container(
                  constraints: const BoxConstraints(
                    minWidth: 30,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _accentNeon.withValues(
                      alpha: 0.07,
                    ),
                    borderRadius: BorderRadius.circular(
                      999,
                    ),
                    border: Border.all(
                      color: _accentNeon.withValues(
                        alpha: 0.13,
                      ),
                    ),
                  ),
                  child: Text(
                    badge,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _accentNeon,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          child,
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
        alpha: 0.66,
      ),
      borderRadius: BorderRadius.circular(
        18,
      ),
      border: Border.all(
        color: Colors.white.withValues(
          alpha: 0.055,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: 0.10,
          ),
          blurRadius: 18,
          offset: const Offset(
            0,
            7,
          ),
        ),
      ],
    );
  }
}
