import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/app/locator.dart';
import 'package:versin/core/utils/network_image_url_helper.dart';
import 'package:versin/app/routes/app_routes.dart';

import 'package:versin/modules/activities/controllers/recent_activity_controller.dart';
import 'package:versin/modules/activities/views/recent_activities_page.dart';
import 'package:versin/modules/activities/widgets/recent_activities_card_widget.dart';
import 'package:versin/modules/calendar/views/calendar_page.dart';
import 'package:versin/modules/dashboard/services/dashboard_ui_preferences_service.dart';
import 'package:versin/modules/notifications/widgets/notification_button_widget.dart';
import 'package:versin/modules/profile/controllers/professional_profile_controller.dart';
import 'package:versin/modules/match/views/projects/match_projects_view.dart';

import 'package:versin/modules/networking/invitations/controllers/project_invitation_controller.dart';
import 'package:versin/modules/networking/invitations/models/project_invitation_model.dart';
import 'package:versin/modules/networking/views/networking_session_view.dart';

import '../../controllers/dashboard_controller.dart';

// ============================================================
// ACCOUNT ACTIVITIES CARD WIDGET
// ============================================================
//
// Card principal do perfil exibido no Dashboard.
//
// Responsabilidades:
//
// - exibir avatar;
// - exibir nome artístico;
// - exibir função profissional principal;
// - acessar contratos;
// - acessar calendário;
// - acessar notificações;
// - exibir as 3 atividades mais recentes;
// - permitir acessar o histórico mensal;
// - permitir expandir/recolher o card.
//
// ============================================================

class AccountActivitiesCardWidget
    extends
        StatefulWidget {
  // ============================================================
  // DEPENDÊNCIAS
  // ============================================================

  final DashboardController controller;

  final VoidCallback onStateChanged;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const AccountActivitiesCardWidget({
    super.key,
    required this.controller,
    required this.onStateChanged,
  });

  @override
  State<
    AccountActivitiesCardWidget
  >
  createState() => _AccountActivitiesCardWidgetState();
}

// ============================================================
// STATE
// ============================================================

class _AccountActivitiesCardWidgetState
    extends
        State<
          AccountActivitiesCardWidget
        > {
  // ============================================================
  // PROFILE CONTROLLER
  // ============================================================

  late final ProfessionalProfileController _profileController;

  // ============================================================
  // ACTIVITY CONTROLLER
  // ============================================================

  late final RecentActivityController _activityController;

  late final ProjectInvitationController _projectInvitationController;

  // ============================================================
  // UI PREFERENCES
  // ============================================================

  late final DashboardUiPreferencesService _uiPreferencesService;

  // ============================================================
  // REQUIRED NAME ONBOARDING
  // ============================================================

  final TextEditingController _displayNameController = TextEditingController();

  final FocusNode _displayNameFocusNode = FocusNode();

  bool _isSavingDisplayName = false;

  bool _isSigningOut = false;

  String? _displayNameError;

  bool get _requiresDisplayName {
    // Enquanto o DashboardController ainda não terminou de
    // resolver o artist_name real do perfil, não mostramos o
    // onboarding. Isso evita o "flash" do campo de nome em
    // contas que já possuem o nome salvo no Supabase.
    if (!widget.controller.artistNameResolved) {
      return false;
    }

    final value = widget.controller.artistName.trim();

    return value.isEmpty ||
        value ==
            'Membro';
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _profileController =
        sl<
          ProfessionalProfileController
        >();

    _activityController =
        sl<
          RecentActivityController
        >();

    _projectInvitationController =
        sl<
          ProjectInvitationController
        >();

    _projectInvitationController.init();

    _uiPreferencesService = DashboardUiPreferencesService();

    _profileController.load();

    _loadProfileCardPreference();

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (!mounted ||
            !_requiresDisplayName) {
          return;
        }

        _displayNameFocusNode.requestFocus();
      },
    );
  }

  // ============================================================
  // LOAD PROFILE CARD PREFERENCE
  // ============================================================
  //
  // Restaura o último estado visual salvo do card.
  //
  // Se o valor salvo for diferente do estado atual mantido pelo
  // DashboardController, alternamos uma única vez.
  //
  // ============================================================

  Future<
    void
  >
  _loadProfileCardPreference() async {
    final isExpanded = await _uiPreferencesService.loadProfileCardExpanded();

    if (!mounted) {
      return;
    }

    // Durante o onboarding obrigatório o card precisa permanecer
    // expandido para que o campo de nome continue visível.
    if (_requiresDisplayName) {
      if (!widget.controller.isProfileCardExpanded) {
        widget.controller.toggleProfileCard();

        widget.onStateChanged();
      }

      return;
    }

    if (widget.controller.isProfileCardExpanded ==
        isExpanded) {
      return;
    }

    widget.controller.toggleProfileCard();

    widget.onStateChanged();
  }

  // ============================================================
  // TOGGLE PROFILE CARD
  // ============================================================

  Future<
    void
  >
  _toggleProfileCard() async {
    if (_requiresDisplayName) {
      return;
    }

    widget.controller.toggleProfileCard();

    widget.onStateChanged();

    final saved = await _uiPreferencesService.saveProfileCardExpanded(
      widget.controller.isProfileCardExpanded,
    );

    if (!saved) {
      debugPrint(
        '[DASHBOARD UI] '
        'Não foi possível salvar o estado do card de perfil.',
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedBuilder(
      animation: Listenable.merge(
        [
          widget.controller,
          _profileController,
          _activityController,
          _projectInvitationController,
        ],
      ),
      builder:
          (
            context,
            _,
          ) {
            final requiresDisplayName = _requiresDisplayName;

            return Container(
              padding: const EdgeInsets.all(
                20,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(
                      0xFF1F1A3A,
                    ),
                    Color(
                      0xFF0D0B1F,
                    ),
                  ],
                ),
                borderRadius: BorderRadius.circular(
                  24,
                ),
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: 0.05,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ==================================================
                  // EXPANDIR / RECOLHER
                  // ==================================================
                  if (!requiresDisplayName)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: _toggleProfileCard,
                          child: Icon(
                            widget.controller.isProfileCardExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.white54,
                            size: 22,
                          ),
                        ),
                      ],
                    )
                  else
                    const SizedBox(
                      height: 22,
                    ),

                  // ==================================================
                  // AVATAR
                  // ==================================================
                  Builder(
                    builder:
                        (
                          context,
                        ) {
                          final validProfileImageUrl = NetworkImageUrlHelper.validUrlOrNull(
                            widget.controller.profileImagePath,
                          );

                          return GestureDetector(
                            onTap: requiresDisplayName
                                ? null
                                : widget.controller.pickProfileImage,
                            child: CircleAvatar(
                              radius: 36,
                              backgroundColor: const Color(
                                0xFFFFCC80,
                              ),
                              backgroundImage:
                                  validProfileImageUrl !=
                                      null
                                  ? NetworkImage(
                                      validProfileImageUrl,
                                    )
                                  : null,
                              child:
                                  validProfileImageUrl ==
                                      null
                                  ? const Icon(
                                      Icons.person,
                                      color: Color(
                                        0xFF2E1A47,
                                      ),
                                      size: 40,
                                    )
                                  : null,
                            ),
                          );
                        },
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  // ==================================================
                  // NOME / ONBOARDING OBRIGATÓRIO
                  // ==================================================
                  if (requiresDisplayName)
                    _buildRequiredNameOnboarding(
                      context,
                    )
                  else ...[
                    Text(
                      widget.controller.artistName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    // ==================================================
                    // FUNÇÃO PROFISSIONAL PRINCIPAL
                    // ==================================================
                    if (_profileController.isLoading)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.white38,
                        ),
                      )
                    else
                      Text(
                        _profileController.primaryRoleLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                    const SizedBox(
                      height: 20,
                    ),

                    // ==================================================
                    // AÇÕES
                    // ==================================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCircularActionIcon(
                          context,
                          Icons.description_outlined,
                          route: AppRoutes.contracts,
                        ),

                        const SizedBox(
                          width: 16,
                        ),

                        _buildCircularActionIcon(
                          context,
                          Icons.calendar_today_outlined,
                          onTap: () {
                            _openCalendarPage(
                              context,
                            );
                          },
                        ),

                        const SizedBox(
                          width: 16,
                        ),

                        _buildProjectInvitationButton(
                          context,
                        ),

                        const SizedBox(
                          width: 16,
                        ),

                        _buildCircularActionIcon(
                          context,
                          Icons.workspaces_outline,
                          onTap: () {
                            _openActiveProjectsPage(
                              context,
                            );
                          },
                        ),

                        const SizedBox(
                          width: 16,
                        ),

                        const NotificationButtonWidget(
                          size: 44,
                        ),

                        const SizedBox(
                          width: 16,
                        ),

                        _buildCircularActionIcon(
                          context,
                          Icons.logout_rounded,
                          tooltip: 'Sair da conta',
                          iconColor: const Color(
                            0xFFFF6B7A,
                          ),
                          borderColor: const Color(
                            0xFFFF6B7A,
                          ),
                          backgroundColor: const Color(
                            0xFFFF6B7A,
                          ),
                          onTap: _isSigningOut
                              ? null
                              : () {
                                  _confirmSignOut(
                                    context,
                                  );
                                },
                        ),
                      ],
                    ),

                    // ==================================================
                    // ATIVIDADES RECENTES
                    // ==================================================
                    if (widget.controller.isProfileCardExpanded) ...[
                      const SizedBox(
                        height: 28,
                      ),

                      RecentActivitiesCardWidget(
                        controller: _activityController,
                        accentColor: widget.controller.accentNeon,
                      ),

                      if (_activityController.hasActivities) ...[
                        const SizedBox(
                          height: 12,
                        ),

                        _buildViewMoreButton(
                          context,
                        ),
                      ],
                    ],
                  ],
                ],
              ),
            );
          },
    );
  }

  // ============================================================
  // REQUIRED NAME ONBOARDING
  // ============================================================

  Widget _buildRequiredNameOnboarding(
    BuildContext context,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 360,
      ),
      child: Column(
        children: [
          const Text(
            'Como devemos te chamar?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          const Text(
            'Defina o nome que será exibido no Versin. '
            'Você poderá alterar essa informação depois.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              height: 1.4,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          TextField(
            controller: _displayNameController,
            focusNode: _displayNameFocusNode,
            enabled: !_isSavingDisplayName,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.words,
            maxLength: 60,
            onChanged:
                (
                  _,
                ) {
                  if (_displayNameError ==
                      null) {
                    return;
                  }

                  setState(
                    () {
                      _displayNameError = null;
                    },
                  );
                },
            onSubmitted:
                (
                  _,
                ) {
                  _saveRequiredDisplayName();
                },
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Digite seu nome',
              hintStyle: const TextStyle(
                color: Colors.white30,
                fontSize: 12,
              ),
              errorText: _displayNameError,
              prefixIcon: const Icon(
                Icons.badge_outlined,
                size: 18,
              ),
              filled: true,
              fillColor: Colors.white.withValues(
                alpha: 0.045,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  14,
                ),
                borderSide: BorderSide(
                  color: Colors.white.withValues(
                    alpha: 0.08,
                  ),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  14,
                ),
                borderSide: BorderSide(
                  color: Colors.white.withValues(
                    alpha: 0.08,
                  ),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  14,
                ),
                borderSide: BorderSide(
                  color: widget.controller.accentNeon.withValues(
                    alpha: 0.75,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: _isSavingDisplayName
                  ? null
                  : _saveRequiredDisplayName,
              style: FilledButton.styleFrom(
                backgroundColor: widget.controller.accentNeon,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                ),
              ),
              child: _isSavingDisplayName
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'CONTINUAR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 12,
                color: Colors.white24,
              ),
              SizedBox(
                width: 5,
              ),
              Flexible(
                child: Text(
                  'Complete seu nome para liberar o restante do aplicativo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SAVE REQUIRED DISPLAY NAME
  // ============================================================

  Future<
    void
  >
  _saveRequiredDisplayName() async {
    if (_isSavingDisplayName) {
      return;
    }

    final displayName = _displayNameController.text.trim();

    if (displayName.length <
        2) {
      setState(
        () {
          _displayNameError = 'Digite pelo menos 2 caracteres.';
        },
      );

      return;
    }

    if (displayName.length >
        60) {
      setState(
        () {
          _displayNameError = 'O nome pode ter no máximo 60 caracteres.';
        },
      );

      return;
    }

    setState(
      () {
        _isSavingDisplayName = true;
        _displayNameError = null;
      },
    );

    try {
      // ======================================================
      // RESOLVER SESSÃO AUTENTICADA
      // ======================================================
      //
      // No Web, especialmente logo após OAuth (GitHub), a URL
      // pode abrir o Dashboard enquanto o Supabase ainda está
      // terminando de restaurar a sessão.
      //
      // Por isso não dependemos apenas de currentUser em uma
      // única leitura instantânea.
      //
      // ======================================================

      final userId = await _resolveAuthenticatedUserId();

      if (userId ==
              null ||
          userId.isEmpty) {
        if (!mounted) {
          return;
        }

        setState(
          () {
            _displayNameError =
                'Sua sessão ainda não está pronta. '
                'Aguarde um instante e tente novamente.';
          },
        );

        return;
      }

      // ======================================================
      // UPSERT DO PERFIL
      // ======================================================
      //
      // Contas OAuth antigas podem existir em auth.users sem
      // possuir ainda uma linha em public.profiles.
      //
      // update() falharia silenciosamente nesse cenário.
      // upsert() atende tanto:
      //
      // - perfil existente;
      // - perfil ainda não criado.
      //
      // ======================================================

      final response = await Supabase.instance.client
          .from(
            'profiles',
          )
          .upsert(
            {
              'id': userId,
              'artist_name': displayName,
              'artist_name_updated_at': DateTime.now().toUtc().toIso8601String(),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
            onConflict: 'id',
          )
          .select(
            'artist_name',
          )
          .maybeSingle();

      final savedName =
          response?['artist_name']?.toString().trim() ??
          '';

      if (savedName.isEmpty) {
        throw StateError(
          'O banco não confirmou o nome salvo.',
        );
      }

      if (!mounted) {
        return;
      }

      // ======================================================
      // ESTADO LOCAL DO DASHBOARD
      // ======================================================

      widget.controller.updateArtistName(
        savedName,
      );

      widget.onStateChanged();

      FocusScope.of(
        context,
      ).unfocus();

      ScaffoldMessenger.of(
          context,
        )
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Nome salvo com sucesso.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );

      debugPrint(
        '[DASHBOARD PROFILE] '
        'Nome obrigatório salvo para $userId.',
      );
    } on PostgrestException catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[DASHBOARD PROFILE] '
        'Erro Supabase ao salvar nome obrigatório: '
        '${error.message}',
      );

      debugPrint(
        '[DASHBOARD PROFILE] '
        'Código: ${error.code}',
      );

      debugPrint(
        '$stackTrace',
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _displayNameError = 'Não foi possível salvar seu nome agora.';
        },
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[DASHBOARD PROFILE] '
        'Erro ao salvar nome obrigatório: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _displayNameError = 'Não foi possível salvar seu nome.';
        },
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _isSavingDisplayName = false;
          },
        );
      }
    }
  }

  // ============================================================
  // RESOLVER USUÁRIO AUTENTICADO
  // ============================================================
  //
  // Faz uma leitura imediata e, se necessário, aguarda por um
  // curto período um evento de autenticação do Supabase.
  //
  // Isso deixa o onboarding mais resiliente após OAuth Web.
  //
  // ============================================================

  Future<
    String?
  >
  _resolveAuthenticatedUserId() async {
    final auth = Supabase.instance.client.auth;

    String? readCurrentUserId() {
      final userId = auth.currentUser?.id.trim();

      if (userId ==
              null ||
          userId.isEmpty) {
        return null;
      }

      return userId;
    }

    final immediateUserId = readCurrentUserId();

    if (immediateUserId !=
        null) {
      debugPrint(
        '[DASHBOARD PROFILE] '
        'Sessão disponível imediatamente: '
        '$immediateUserId',
      );

      return immediateUserId;
    }

    final sessionUserId = auth.currentSession?.user.id.trim();

    if (sessionUserId !=
            null &&
        sessionUserId.isNotEmpty) {
      debugPrint(
        '[DASHBOARD PROFILE] '
        'Usuário resolvido pela sessão atual: '
        '$sessionUserId',
      );

      return sessionUserId;
    }

    debugPrint(
      '[DASHBOARD PROFILE] '
      'Aguardando restauração da sessão OAuth.',
    );

    try {
      final authState = await auth.onAuthStateChange
          .firstWhere(
            (
              state,
            ) {
              final userId = state.session?.user.id.trim();

              return userId !=
                      null &&
                  userId.isNotEmpty;
            },
          )
          .timeout(
            const Duration(
              seconds: 4,
            ),
          );

      final userId = authState.session?.user.id.trim();

      if (userId ==
              null ||
          userId.isEmpty) {
        return null;
      }

      debugPrint(
        '[DASHBOARD PROFILE] '
        'Sessão OAuth restaurada: $userId',
      );

      return userId;
    } on TimeoutException {
      debugPrint(
        '[DASHBOARD PROFILE] '
        'Tempo limite aguardando sessão OAuth.',
      );

      return null;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[DASHBOARD PROFILE] '
        'Erro ao resolver sessão autenticada: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      return null;
    }
  }

  // ============================================================
  // VER MAIS
  // ============================================================

  Widget _buildViewMoreButton(
    BuildContext context,
  ) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(
            12,
          ),
          onTap: () {
            _openActivitiesPage(
              context,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'VER MAIS',
                  style: TextStyle(
                    color: widget.controller.accentNeon,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),

                const SizedBox(
                  width: 5,
                ),

                Icon(
                  Icons.arrow_forward_rounded,
                  color: widget.controller.accentNeon,
                  size: 13,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTÃO DE CONVITES DE PROJETO
  // ============================================================

  Widget _buildProjectInvitationButton(
    BuildContext context,
  ) {
    final count = _projectInvitationController.pendingCount;

    return Tooltip(
      message:
          count >
              0
          ? 'Convites de projetos • $count'
          : 'Convites de projetos',

      child: GestureDetector(
        onTap: () {
          _openProjectInvitations(
            context,
          );
        },

        child: Stack(
          clipBehavior: Clip.none,

          children: [
            Container(
              width: 44,
              height: 44,

              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.05,
                ),

                shape: BoxShape.circle,

                border: Border.all(
                  color:
                      count >
                          0
                      ? const Color(
                          0xFF8B5CF6,
                        ).withValues(
                          alpha: 0.45,
                        )
                      : Colors.white.withValues(
                          alpha: 0.08,
                        ),
                ),
              ),

              child: Icon(
                Icons.group_add_outlined,
                color:
                    count >
                        0
                    ? const Color(
                        0xFFA78BFA,
                      )
                    : Colors.white70,
                size: 20,
              ),
            ),

            if (count >
                0)
              Positioned(
                top: -4,
                right: -4,

                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),

                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                  ),

                  alignment: Alignment.center,

                  decoration: const BoxDecoration(
                    color: Color(
                      0xFF8B5CF6,
                    ),
                    shape: BoxShape.circle,
                  ),

                  child: Text(
                    count >
                            99
                        ? '99+'
                        : '$count',

                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ABRIR CONVITES
  // ============================================================

  Future<
    void
  >
  _openProjectInvitations(
    BuildContext context,
  ) async {
    if (!_projectInvitationController.initialized) {
      await _projectInvitationController.init();
    }

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<
      void
    >(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      builder:
          (
            sheetContext,
          ) {
            return FractionallySizedBox(
              heightFactor: 0.72,

              child: Container(
                decoration: const BoxDecoration(
                  color: Color(
                    0xFF0D0B14,
                  ),

                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(
                      24,
                    ),
                  ),
                ),

                child: SafeArea(
                  top: false,

                  child: Column(
                    children: [
                      const SizedBox(
                        height: 10,
                      ),

                      Container(
                        width: 42,
                        height: 4,

                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          18,
                          20,
                          14,
                        ),

                        child: Row(
                          children: [
                            Icon(
                              Icons.group_add_outlined,
                              color: Color(
                                0xFFA78BFA,
                              ),
                              size: 20,
                            ),

                            SizedBox(
                              width: 10,
                            ),

                            Text(
                              'Convites de projetos',

                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: ListenableBuilder(
                          listenable: _projectInvitationController,

                          builder:
                              (
                                context,
                                _,
                              ) {
                                if (_projectInvitationController.isLoading &&
                                    !_projectInvitationController.hasPendingInvitations) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final invitations = _projectInvitationController.pendingInvitations;

                                if (invitations.isEmpty) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(
                                        24,
                                      ),

                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,

                                        children: [
                                          Icon(
                                            Icons.mark_email_read_outlined,
                                            color: Colors.white24,
                                            size: 36,
                                          ),

                                          SizedBox(
                                            height: 12,
                                          ),

                                          Text(
                                            'Nenhum convite pendente',

                                            style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),

                                          SizedBox(
                                            height: 5,
                                          ),

                                          Text(
                                            'Novos convites para Studio Sessions aparecerão aqui.',

                                            textAlign: TextAlign.center,

                                            style: TextStyle(
                                              color: Colors.white30,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                return ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    24,
                                  ),

                                  itemCount: invitations.length,

                                  separatorBuilder:
                                      (
                                        _,
                                        __,
                                      ) {
                                        return const SizedBox(
                                          height: 10,
                                        );
                                      },

                                  itemBuilder:
                                      (
                                        context,
                                        index,
                                      ) {
                                        return _buildProjectInvitationCard(
                                          sheetContext,
                                          invitations[index],
                                        );
                                      },
                                );
                              },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
    );
  }

  // ============================================================
  // CARD DO CONVITE
  // ============================================================

  Widget _buildProjectInvitationCard(
    BuildContext sheetContext,
    ProjectInvitationModel invitation,
  ) {
    final busy = _projectInvitationController.isBusy;

    return Container(
      padding: const EdgeInsets.all(
        14,
      ),

      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.035,
        ),

        borderRadius: BorderRadius.circular(
          18,
        ),

        border: Border.all(
          color:
              const Color(
                0xFF8B5CF6,
              ).withValues(
                alpha: 0.18,
              ),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,

                alignment: Alignment.center,

                decoration: BoxDecoration(
                  color:
                      const Color(
                        0xFF8B5CF6,
                      ).withValues(
                        alpha: 0.12,
                      ),

                  borderRadius: BorderRadius.circular(
                    13,
                  ),
                ),

                child: const Icon(
                  Icons.groups_2_outlined,
                  color: Color(
                    0xFFA78BFA,
                  ),
                  size: 20,
                ),
              ),

              const SizedBox(
                width: 11,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      invitation.projectTitle,

                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      '${invitation.inviterName} convidou você para participar.',

                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 13,
          ),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy
                      ? null
                      : () async {
                          final rejected = await _projectInvitationController.rejectInvitation(
                            invitation,
                          );

                          if (!mounted ||
                              !rejected) {
                            return;
                          }

                          _showInvitationMessage(
                            'Convite recusado.',
                          );
                        },

                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,

                    side: BorderSide(
                      color: Colors.redAccent.withValues(
                        alpha: 0.30,
                      ),
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),

                  child: const Text(
                    'Recusar',

                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child: FilledButton(
                  onPressed: busy
                      ? null
                      : () async {
                          final projectId = await _projectInvitationController.acceptInvitation(
                            invitation,
                          );

                          if (!mounted ||
                              projectId ==
                                  null ||
                              projectId.trim().isEmpty) {
                            return;
                          }

                          if (sheetContext.mounted) {
                            Navigator.of(
                              sheetContext,
                            ).pop();
                          }

                          _showInvitationMessage(
                            'Você entrou em ${invitation.projectTitle}.',
                          );

                          await Navigator.of(
                            this.context,
                          ).push(
                            MaterialPageRoute<
                              void
                            >(
                              builder:
                                  (
                                    _,
                                  ) {
                                    return NetworkingSessionView(
                                      projectId: projectId.trim(),
                                    );
                                  },
                            ),
                          );
                        },

                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF8B5CF6,
                    ),
                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),

                  child: busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,

                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Aceitar',

                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MENSAGEM DE CONVITE
  // ============================================================

  void _showInvitationMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
        context,
      )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),

          backgroundColor: const Color(
            0xFF15151D,
          ),

          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // ABRIR PROJETOS ATIVOS
  // ============================================================

  Future<
    void
  >
  _openActiveProjectsPage(
    BuildContext context,
  ) async {
    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute<
        void
      >(
        builder:
            (
              _,
            ) {
              return const MatchProjectsView();
            },
      ),
    );
  }

  // ============================================================
  // ABRIR CALENDÁRIO
  // ============================================================

  Future<
    void
  >
  _openCalendarPage(
    BuildContext context,
  ) async {
    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute<
        void
      >(
        builder:
            (
              context,
            ) {
              return const CalendarPage();
            },
      ),
    );

    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ============================================================
  // ABRIR HISTÓRICO DE ATIVIDADES
  // ============================================================

  Future<
    void
  >
  _openActivitiesPage(
    BuildContext context,
  ) async {
    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute<
        void
      >(
        builder:
            (
              context,
            ) {
              return const RecentActivitiesPage();
            },
      ),
    );
  }

  // ============================================================
  // SAIR DA CONTA
  // ============================================================

  Future<
    void
  >
  _confirmSignOut(
    BuildContext context,
  ) async {
    if (_isSigningOut) {
      return;
    }

    final shouldSignOut =
        await showDialog<
          bool
        >(
          context: context,
          barrierDismissible: true,
          builder:
              (
                dialogContext,
              ) {
                return AlertDialog(
                  backgroundColor: const Color(
                    0xFF12101D,
                  ),
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      22,
                    ),
                    side: BorderSide(
                      color:
                          const Color(
                            0xFFFF6B7A,
                          ).withValues(
                            alpha: 0.18,
                          ),
                    ),
                  ),
                  titlePadding: const EdgeInsets.fromLTRB(
                    22,
                    22,
                    22,
                    0,
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(
                    22,
                    14,
                    22,
                    0,
                  ),
                  actionsPadding: const EdgeInsets.fromLTRB(
                    16,
                    18,
                    16,
                    16,
                  ),
                  title: const Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: Color(
                          0xFFFF6B7A,
                        ),
                        size: 21,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Sair da conta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    'Deseja encerrar sua sessão no Versin?',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(
                          false,
                        );
                      },
                      child: const Text(
                        'CANCELAR',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(
                          true,
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFFF6B7A,
                        ),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 16,
                      ),
                      label: const Text(
                        'SAIR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                );
              },
        );

    if (shouldSignOut !=
            true ||
        !mounted) {
      return;
    }

    await _signOut();
  }

  Future<
    void
  >
  _signOut() async {
    if (_isSigningOut) {
      return;
    }

    setState(
      () {
        _isSigningOut = true;
      },
    );

    try {
      await Supabase.instance.client.auth.signOut();

      if (!mounted) {
        return;
      }

      debugPrint(
        '[DASHBOARD PROFILE] '
        'Logout realizado com sucesso.',
      );

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (
          route,
        ) => false,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[DASHBOARD PROFILE] '
        'Erro ao sair da conta: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
          context,
        )
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível sair da conta. Tente novamente.',
            ),
            backgroundColor: Color(
              0xFF15151D,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(
          () {
            _isSigningOut = false;
          },
        );
      }
    }
  }

  // ============================================================
  // BOTÃO CIRCULAR
  // ============================================================

  Widget _buildCircularActionIcon(
    BuildContext context,
    IconData icon, {
    String? route,
    VoidCallback? onTap,
    String? tooltip,
    Color? iconColor,
    Color? borderColor,
    Color? backgroundColor,
  }) {
    final button = GestureDetector(
      onTap:
          onTap ==
                  null &&
              route ==
                  null
          ? null
          : () {
              // ======================================================
              // CALLBACK PERSONALIZADO
              // ======================================================

              if (onTap !=
                  null) {
                onTap();

                return;
              }

              // ======================================================
              // ROTA
              // ======================================================

              if (route !=
                  null) {
                Navigator.of(
                  context,
                ).pushNamed(
                  route,
                );
              }
            },
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 180,
        ),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color:
              backgroundColor?.withValues(
                alpha: 0.07,
              ) ??
              Colors.white.withValues(
                alpha: 0.05,
              ),
          shape: BoxShape.circle,
          border: Border.all(
            color:
                borderColor?.withValues(
                  alpha: 0.22,
                ) ??
                Colors.white.withValues(
                  alpha: 0.08,
                ),
          ),
        ),
        child:
            _isSigningOut &&
                icon ==
                    Icons.logout_rounded
            ? const Padding(
                padding: EdgeInsets.all(
                  14,
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: Color(
                    0xFFFF6B7A,
                  ),
                ),
              )
            : Icon(
                icon,
                color:
                    iconColor ??
                    Colors.white70,
                size: 20,
              ),
      ),
    );

    if (tooltip ==
            null ||
        tooltip.trim().isEmpty) {
      return button;
    }

    return Tooltip(
      message: tooltip,
      child: button,
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();

    _displayNameFocusNode.dispose();

    // O ProjectInvitationController é global (GetIt LazySingleton).
    // Não deve ser disposed por este widget, senão o Realtime
    // deixaria de funcionar ao sair/recriar o Dashboard.

    super.dispose();
  }
}
