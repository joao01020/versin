import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/app/locator.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';

// ============================================================
// DASHBOARD
// ============================================================

import '../config/menu/dashboard_menu_config.dart';
import '../controllers/dashboard_controller.dart';
import '../layouts/dashboard_home_layout.dart';
import '../navigation/dashboard_bottom_navigation.dart';
import '../navigation/dashboard_navigation.dart';
import '../navigation/dashboard_side_rail.dart';
import '../widgets/dashboard_header_widget.dart';

import 'package:versin/modules/dashboard/global_call/controllers/dashboard_global_call_controller.dart';
import 'package:versin/modules/dashboard/global_call/widgets/dashboard_global_call_banner.dart';
import 'package:versin/modules/dashboard/global_chat/controllers/dashboard_global_chat_controller.dart';
import 'package:versin/modules/dashboard/global_chat/widgets/dashboard_global_chat_banner.dart';
import 'package:versin/modules/dashboard/invitations/controllers/dashboard_invitation_controller.dart';
import 'package:versin/modules/dashboard/invitations/widgets/dashboard_invitation_banner.dart';

// ============================================================
// ECOSSISTEMA
// ============================================================

import 'package:versin/modules/calendar/views/calendar_page.dart';
import 'package:versin/modules/chat/data/datasources/chat_remote_datasource.dart';
import 'package:versin/modules/chat/data/repositories/chat_repository_impl.dart';
import 'package:versin/modules/chat/ai/services/provider/ai_provider_service.dart';
import 'package:versin/modules/chat/ai/services/private_api/private_ai_client.dart';
import 'package:versin/modules/chat/ai/services/private_api/private_api_service.dart';
import 'package:versin/modules/chat/views/chat_page.dart';
import 'package:versin/modules/hub/views/hub_page.dart';
import 'package:versin/modules/market/market_page.dart';
import 'package:versin/modules/match/views/match_page.dart';
import 'package:versin/modules/settings/views/settings_page.dart';
import 'package:versin/modules/storage/views/storage_page.dart';
import 'package:versin/modules/studio/views/studio_page.dart';
import 'package:versin/modules/vnode/vnode_page.dart';
import 'package:versin/modules/wallet/views/wallet_page.dart';

import 'package:versin/modules/networking/call/views/call_view.dart';
import 'package:versin/modules/networking/views/networking_session_view.dart';
import 'package:versin/modules/networking/chat/views/chat_view.dart';

// ============================================================
// NETWORKING - PROJECT INVITATIONS
// ============================================================

// ============================================================
// DASHBOARD PAGE
// ============================================================
//
// Responsabilidade:
//
// - obter controllers;
// - orquestrar navegação;
// - montar shell principal;
// - manter PageView dos módulos;
// - delegar UI para componentes especializados;
// - manter banners globais de chamada e mensagens.
//
// Não contém:
//
// - configuração dos menus;
// - model de menu;
// - desenho do SideRail;
// - desenho da BottomNavigation;
// - layout da Home;
// - formulário de compromisso.
//
// ============================================================

class DashboardPage
    extends
        StatefulWidget {
  static const String routeName = '/';

  const DashboardPage({
    super.key,
  });

  @override
  State<
    DashboardPage
  >
  createState() => _DashboardPageState();
}

// ============================================================
// STATE
// ============================================================

class _DashboardPageState
    extends
        State<
          DashboardPage
        > {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final DashboardController _controller =
      sl<
        DashboardController
      >();

  final RhymesController _rhymesController =
      sl<
        RhymesController
      >();

  // ============================================================
  // GLOBAL CHAT
  // ============================================================

  late final DashboardGlobalChatController _globalChatController;

  // ============================================================
  // PROJECT INVITATIONS
  // ============================================================

  late final DashboardInvitationController _invitationController;

  // ============================================================
  // GLOBAL CALL
  // ============================================================

  late final DashboardGlobalCallController _globalCallController;

  // ============================================================
  // SUPABASE
  // ============================================================

  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // MENUS VISÍVEIS
  // ============================================================

  get _visibleMenuItems => DashboardMenuConfig.visibleItems;

  // ============================================================
  // ONBOARDING OBRIGATÓRIO DO NOME
  // ============================================================
  //
  // Enquanto o usuário ainda não possuir um nome público válido,
  // a aplicação permanece na Home do Dashboard.
  //
  // O campo de nome é exibido pelo AccountActivitiesCardWidget.
  //
  // ============================================================

  bool get _requiresDisplayName {
    // Enquanto o DashboardController ainda não terminou de
    // consultar o artist_name real do perfil, não exibimos
    // onboarding e não bloqueamos a navegação.
    //
    // Isso evita o campo "Como devemos te chamar?" aparecer
    // rapidamente em contas que já possuem nome salvo.
    if (!_controller.artistNameResolved) {
      return false;
    }

    final value = _controller.artistName.trim();

    return value.isEmpty ||
        value ==
            'Membro';
  }

  // ============================================================
  // ÍNDICE VISÍVEL ATUAL
  // ============================================================

  int get _visibleCurrentIndex {
    return DashboardNavigation.visibleIndexFromOriginalIndex(
      items: DashboardMenuConfig.items,
      originalIndex: _controller.currentIndex,
    );
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    unawaited(
      _initializeDashboard(),
    );

    _globalChatController = DashboardGlobalChatController()..init();

    _globalCallController = DashboardGlobalCallController()..init();

    _invitationController = DashboardInvitationController();

    unawaited(
      _invitationController.init(),
    );
  }

  // ============================================================
  // INITIALIZE DASHBOARD
  // ============================================================

  Future<
    void
  >
  _initializeDashboard() async {
    await _controller.init();

    if (!mounted) {
      return;
    }

    if (_requiresDisplayName &&
        _controller.currentIndex !=
            0) {
      _controller.navigationTap(
        0,
      );
    }

    setState(
      () {},
    );

    // Atualiza a quota real sem bloquear a abertura do Dashboard.
    unawaited(
      _refreshAiQuota(),
    );
  }

  // ============================================================
  // REFRESH AI QUOTA
  // ============================================================

  Future<
    void
  >
  _refreshAiQuota() async {
    final user = _supabase.auth.currentUser;

    if (user ==
        null) {
      debugPrint(
        '[DASHBOARD] '
        'Quota não atualizada: usuário não autenticado.',
      );

      return;
    }

    final userId = user.id.trim();

    if (userId.isEmpty) {
      debugPrint(
        '[DASHBOARD] '
        'Quota não atualizada: userId inválido.',
      );

      return;
    }

    debugPrint(
      '[DASHBOARD] '
      'Atualizando quota real da IA Versin.',
    );

    final privateApiService = PrivateApiService();

    final aiProviderService = AiProviderService(
      privateApiService: privateApiService,
    );

    final privateAiClient = PrivateAiClient();

    final remoteDatasource = ChatRemoteDatasource();

    final chatRepository = ChatRepositoryImpl(
      remoteDatasource: remoteDatasource,

      aiProviderService: aiProviderService,

      privateAiClient: privateAiClient,
    );

    try {
      final quota = await chatRepository.fetchAiQuota();

      if (!mounted) {
        return;
      }

      final currentUserId = _supabase.auth.currentUser?.id.trim();

      if (currentUserId !=
          userId) {
        debugPrint(
          '[DASHBOARD] '
          'Resposta de quota descartada: a conta autenticada mudou.',
        );

        return;
      }

      if (quota.isEmpty) {
        debugPrint(
          '[DASHBOARD] '
          'Backend retornou quota vazia. Mantendo cache atual.',
        );

        return;
      }

      _rhymesController.updateAiQuotaFromMap(
        quota,
        notify: true,
      );

      debugPrint(
        '[DASHBOARD] '
        'Quota real atualizada com sucesso.',
      );

      debugPrint(
        '[DASHBOARD] '
        'Tokens usados: ${_rhymesController.aiUsedTokens}',
      );

      debugPrint(
        '[DASHBOARD] '
        'Tokens restantes: ${_rhymesController.aiRemainingTokens}',
      );

      debugPrint(
        '[DASHBOARD] '
        'Limite: ${_rhymesController.aiLimitTokens}',
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[DASHBOARD] '
        'Não foi possível atualizar a quota real: $error',
      );

      debugPrint(
        '[DASHBOARD] '
        'Mantendo quota/cache atual.',
      );

      debugPrint(
        '$stackTrace',
      );
    }
  }

  // ============================================================
  // NAVEGAÇÃO
  // ============================================================

  void _onNavigationTap(
    int visibleIndex,
  ) {
    if (_requiresDisplayName) {
      _showCompleteNameMessage();

      return;
    }

    final originalIndex = DashboardNavigation.originalIndexFromVisibleIndex(
      items: DashboardMenuConfig.items,
      visibleIndex: visibleIndex,
    );

    if (originalIndex ==
        null) {
      return;
    }

    setState(
      () {
        _controller.navigationTap(
          originalIndex,
        );
      },
    );
  }

  // ============================================================
  // COMPLETE NAME MESSAGE
  // ============================================================

  void _showCompleteNameMessage() {
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
            'Defina seu nome para liberar o restante do aplicativo.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // ABRIR CALENDÁRIO
  // ============================================================
  //
  // O antigo AddAppointmentSheet foi removido deste fluxo.
  //
  // A criação de tarefas e compromissos agora fica centralizada
  // no módulo Calendar.
  //
  // ============================================================

  Future<
    void
  >
  _openCalendarPage() async {
    if (!mounted) {
      return;
    }

    if (_requiresDisplayName) {
      _showCompleteNameMessage();

      return;
    }

    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (
              _,
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
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedBuilder(
      animation: _controller,

      builder:
          (
            context,
            _,
          ) {
            return LayoutBuilder(
              builder:
                  (
                    context,
                    constraints,
                  ) {
                    final isMobile =
                        constraints.maxWidth <
                        800;

                    final locked = _requiresDisplayName;

                    return Scaffold(
                      backgroundColor: Colors.black,

                      // ====================================================
                      // NAVEGAÇÃO MOBILE
                      // ====================================================
                      bottomNavigationBar: isMobile
                          ? IgnorePointer(
                              ignoring: locked,

                              child: AnimatedOpacity(
                                duration: const Duration(
                                  milliseconds: 180,
                                ),
                                opacity: locked
                                    ? 0.28
                                    : 1.0,
                                child: DashboardBottomNavigation(
                                  controller: _controller,
                                  items: _visibleMenuItems,
                                  currentVisibleIndex: _visibleCurrentIndex,
                                  onTap: _onNavigationTap,
                                ),
                              ),
                            )
                          : null,

                      // ====================================================
                      // BODY
                      // ====================================================
                      body: _buildBody(
                        isMobile: isMobile,
                      ),
                    );
                  },
            );
          },
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody({
    required bool isMobile,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(
              0xFF2E1A47,
            ),
            _controller.deepBg,
            Colors.black,
          ],
        ),
      ),
      child: Row(
        children: [
          // ====================================================
          // MENU DESKTOP
          // ====================================================
          if (!isMobile)
            IgnorePointer(
              ignoring: _requiresDisplayName,

              child: AnimatedOpacity(
                duration: const Duration(
                  milliseconds: 180,
                ),
                opacity: _requiresDisplayName
                    ? 0.28
                    : 1.0,
                child: DashboardSideRail(
                  controller: _controller,
                  items: _visibleMenuItems,
                  currentVisibleIndex: _visibleCurrentIndex,
                  onTap: _onNavigationTap,
                ),
              ),
            ),

          // ====================================================
          // CONTEÚDO
          // ====================================================
          Expanded(
            child: Stack(
              children: [
                SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DashboardHeaderWidget(
                        controller: _controller,
                      ),

                      Expanded(
                        child: _buildPageView(),
                      ),
                    ],
                  ),
                ),

                if (!_requiresDisplayName)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DashboardInvitationBanner(
                          controller: _invitationController,
                          canInteract: () {
                            if (_requiresDisplayName) {
                              _showCompleteNameMessage();
                              return false;
                            }

                            return true;
                          },
                          onOpenProject: _openInvitedProject,
                        ),

                        DashboardGlobalCallBanner(
                          controller: _globalCallController,
                          onOpenCall: _openCallPage,
                        ),

                        DashboardGlobalChatBanner(
                          controller: _globalChatController,
                          onOpen: _openGlobalChat,
                        ),
                      ],
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
  // OPEN INVITED PROJECT
  // ============================================================

  Future<
    void
  >
  _openInvitedProject(
    String projectId,
  ) async {
    if (_requiresDisplayName) {
      _showCompleteNameMessage();

      return;
    }

    final normalizedProjectId = projectId.trim();

    if (!mounted ||
        normalizedProjectId.isEmpty) {
      return;
    }

    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (
              _,
            ) {
              return NetworkingSessionView(
                projectId: normalizedProjectId,
              );
            },
      ),
    );
  }

  // ============================================================
  // OPEN GLOBAL CHAT
  // ============================================================

  Future<
    void
  >
  _openGlobalChat(
    String projectId,
  ) async {
    if (_requiresDisplayName) {
      _showCompleteNameMessage();
      return;
    }

    final normalizedProjectId = projectId.trim();

    if (!mounted ||
        normalizedProjectId.isEmpty) {
      return;
    }

    final prepared = _globalChatController.prepareOpen(
      normalizedProjectId,
    );

    if (!prepared) {
      return;
    }

    try {
      await Navigator.of(
        context,
      ).push(
        MaterialPageRoute(
          builder:
              (
                _,
              ) => ChatView(
                projectId: normalizedProjectId,
              ),
        ),
      );
    } finally {
      _globalChatController.finishOpen();
    }
  }

  // ============================================================
  // OPEN CALL
  // ============================================================

  Future<
    void
  >
  _openCallPage(
    String projectId,
  ) async {
    if (_requiresDisplayName) {
      _showCompleteNameMessage();

      return;
    }

    if (!mounted ||
        projectId.trim().isEmpty) {
      return;
    }

    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (
              _,
            ) => CallView(
              projectId: projectId,
            ),
      ),
    );
  }

  // ============================================================
  // PAGE VIEW
  // ============================================================
  //
  // IMPORTANTE:
  //
  // Preserve esta ordem.
  //
  // 0 = Dashboard
  // 1 = Match
  // 2 = Market
  // 3 = Wallet
  // 4 = IA / Chat
  // 5 = Storage
  // 6 = Hub
  // 7 = VNode
  // 8 = Settings
  // 9 = Studio
  //
  // Os itens ocultos continuam no PageView para preservar os
  // índices usados pelo DashboardController.
  //
  // ============================================================

  Widget _buildPageView() {
    return PageView(
      controller: _controller.pageController,

      physics: const NeverScrollableScrollPhysics(),

      onPageChanged:
          (
            index,
          ) {
            if (!mounted) {
              return;
            }

            if (_requiresDisplayName &&
                index !=
                    0) {
              WidgetsBinding.instance.addPostFrameCallback(
                (
                  _,
                ) {
                  if (!mounted) {
                    return;
                  }

                  _controller.navigationTap(
                    0,
                  );
                },
              );

              return;
            }

            setState(
              () {
                _controller.handlePageChange(
                  index,
                );
              },
            );
          },

      children: [
        // ======================================================
        // 0 — DASHBOARD
        // ======================================================
        DashboardHomeLayout(
          controller: _controller,
          rhymesController: _rhymesController,
          onAddAppointment: () {
            _openCalendarPage();
          },
        ),

        // ======================================================
        // 1 — CONECTAR
        // ======================================================
        const MatchPage(),

        // ======================================================
        // 2 — MERCADO
        // ======================================================
        //
        // Continua existindo mesmo quando oculto do menu.
        //
        // ======================================================
        MarketPage(),

        // ======================================================
        // 3 — CARTEIRA
        // ======================================================
        const WalletPage(),

        // ======================================================
        // 4 — IA
        // ======================================================
        const ChatPage(),

        // ======================================================
        // 5 — ARMAZENAR
        // ======================================================
        StoragePage(),

        // ======================================================
        // 6 — HUB
        // ======================================================
        const HubPage(),

        // ======================================================
        // 7 — VNODE
        // ======================================================
        //
        // Continua existindo mesmo quando oculto do menu.
        //
        // ======================================================
        VNodePage(),

        // ======================================================
        // 8 — AJUSTES
        // ======================================================
        SettingsPage(),

        // ======================================================
        // 9 — STUDIO
        // ======================================================
        const StudioPage(),
      ],
    );
  }
  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _globalChatController.dispose();
    _globalCallController.dispose();
    _invitationController.dispose();

    super.dispose();
  }
}
