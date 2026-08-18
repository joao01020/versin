import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/app/locator.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';

// ============================================================
// DASHBOARD
// ============================================================

import '../config/dashboard_menu_config.dart';
import '../controllers/dashboard_controller.dart';
import '../layouts/dashboard_home_layout.dart';
import '../navigation/dashboard_bottom_navigation.dart';
import '../navigation/dashboard_navigation.dart';
import '../navigation/dashboard_side_rail.dart';
import '../widgets/dashboard_header_widget.dart';

// ============================================================
// ECOSSISTEMA
// ============================================================

import 'package:versin/modules/calendar/views/calendar_page.dart';
import 'package:versin/modules/chat/views/chat_page.dart';
import 'package:versin/modules/hub/views/hub_page.dart';
import 'package:versin/modules/market/market_page.dart';
import 'package:versin/modules/match/views/match_page.dart';
import 'package:versin/modules/settings/views/settings_page.dart';
import 'package:versin/modules/storage/views/storage_page.dart';
import 'package:versin/modules/studio/views/studio_page.dart';
import 'package:versin/modules/vnode/vnode_page.dart';
import 'package:versin/modules/wallet/views/wallet_page.dart';

import 'package:versin/modules/networking/call/data/repositories/project_call_repository_impl.dart';
import 'package:versin/modules/networking/call/views/call_view.dart';
import 'package:versin/modules/networking/call/views/widgets/global_call_banner.dart';
import 'package:versin/modules/networking/controllers/global_chat_controller.dart';
import 'package:versin/modules/networking/widgets/global_chat_banner.dart';
import 'package:versin/modules/networking/views/sub_features/chat_view.dart';

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

class DashboardPage extends StatefulWidget {
  static const String routeName = '/';

  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

// ============================================================
// STATE
// ============================================================

class _DashboardPageState extends State<DashboardPage> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final DashboardController _controller = sl<DashboardController>();

  final RhymesController _rhymesController = sl<RhymesController>();

  // ============================================================
  // GLOBAL CHAT
  // ============================================================

  late final GlobalChatController _globalChatController;

  // ============================================================
  // GLOBAL CALL
  // ============================================================

  final SupabaseClient _supabase = Supabase.instance.client;

  final ProjectCallRepositoryImpl _callRepository = ProjectCallRepositoryImpl();

  bool _isGlobalCallActionProcessing = false;

  String? _globalCallAction;

  Timer? _globalCallClockTimer;

  DateTime _globalCallClockNow = DateTime.now();

  // ============================================================
  // CACHE DE NOMES DA CHAMADA
  // ============================================================

  final Map<String, String> _callParticipantNameCache = <String, String>{};

  // ============================================================
  // CACHE DE NOMES DO CHAT
  // ============================================================

  final Map<String, String> _chatSenderNameCache = <String, String>{};

  // ============================================================
  // MENUS VISÍVEIS
  // ============================================================

  get _visibleMenuItems => DashboardMenuConfig.visibleItems;

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

    _controller.init();

    _globalChatController = GlobalChatController()..init();

    _globalCallClockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _globalCallClockNow = DateTime.now();
      });
    });
  }

  // ============================================================
  // NAVEGAÇÃO
  // ============================================================

  void _onNavigationTap(int visibleIndex) {
    final originalIndex = DashboardNavigation.originalIndexFromVisibleIndex(
      items: DashboardMenuConfig.items,
      visibleIndex: visibleIndex,
    );

    if (originalIndex == null) {
      return;
    }

    setState(() {
      _controller.navigationTap(originalIndex);
    });
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

  Future<void> _openCalendarPage() async {
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          return const CalendarPage();
        },
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return Scaffold(
          backgroundColor: Colors.black,

          // ====================================================
          // NAVEGAÇÃO MOBILE
          // ====================================================
          bottomNavigationBar: isMobile
              ? DashboardBottomNavigation(
                  controller: _controller,
                  items: _visibleMenuItems,
                  currentVisibleIndex: _visibleCurrentIndex,
                  onTap: _onNavigationTap,
                )
              : null,

          // ====================================================
          // BODY
          // ====================================================
          body: _buildBody(isMobile: isMobile),
        );
      },
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody({required bool isMobile}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF2E1A47), _controller.deepBg, Colors.black],
        ),
      ),
      child: Row(
        children: [
          // ====================================================
          // MENU DESKTOP
          // ====================================================
          if (!isMobile)
            DashboardSideRail(
              controller: _controller,
              items: _visibleMenuItems,
              currentVisibleIndex: _visibleCurrentIndex,
              onTap: _onNavigationTap,
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
                      DashboardHeaderWidget(controller: _controller),

                      Expanded(child: _buildPageView()),
                    ],
                  ),
                ),

                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildGlobalCallBanner(),
                      _buildGlobalChatBanner(),
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
  // GLOBAL CHAT BANNER
  // ============================================================

  Widget _buildGlobalChatBanner() {
    return ListenableBuilder(
      listenable: _globalChatController,

      builder: (context, _) {
        if (!_globalChatController.hasNotification) {
          return const SizedBox.shrink();
        }

        final projectId = _globalChatController.latestProjectId;

        if (projectId == null || projectId.isEmpty) {
          return const SizedBox.shrink();
        }

        final latestMessage = _globalChatController.latestMessage;

        if (latestMessage == null) {
          return const SizedBox.shrink();
        }

        final senderId = latestMessage.senderId.trim();

        return FutureBuilder<String>(
          future: _resolveChatSenderName(senderId),

          builder: (context, snapshot) {
            final senderName =
                snapshot.data ??
                _chatSenderNameCache[senderId] ??
                _globalChatController.senderName;

            return GlobalChatBanner(
              type: _globalChatController.latestIsAudio
                  ? GlobalChatBannerType.audio
                  : GlobalChatBannerType.message,

              senderName: senderName,

              preview: _globalChatController.preview,

              unreadCount: _globalChatController.unreadCount,

              onOpen: () {
                _openGlobalChat(projectId);
              },

              onDismiss: _globalChatController.dismissBanner,
            );
          },
        );
      },
    );
  }

  // ============================================================
  // RESOLVER NOME DO REMETENTE DO CHAT
  // ============================================================

  Future<String> _resolveChatSenderName(String userId) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return _globalChatController.senderName;
    }

    final cached = _chatSenderNameCache[normalizedUserId];

    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    try {
      final profile = await _supabase
          .from('profiles')
          .select('id, artist_name, name, username')
          .eq('id', normalizedUserId)
          .maybeSingle();

      if (profile == null) {
        return _globalChatController.senderName;
      }

      final artistName = profile['artist_name']?.toString().trim();

      if (artistName != null && artistName.isNotEmpty) {
        _chatSenderNameCache[normalizedUserId] = artistName;

        return artistName;
      }

      final name = profile['name']?.toString().trim();

      if (name != null && name.isNotEmpty) {
        _chatSenderNameCache[normalizedUserId] = name;

        return name;
      }

      final username = profile['username']?.toString().trim().replaceFirst(
        RegExp(r'^@+'),
        '',
      );

      if (username != null && username.isNotEmpty) {
        final usernameLabel = '@$username';

        _chatSenderNameCache[normalizedUserId] = usernameLabel;

        return usernameLabel;
      }
    } catch (error, stackTrace) {
      debugPrint(
        '[DASHBOARD] '
        'Erro ao buscar nome do remetente do chat: '
        '$error',
      );

      debugPrint('$stackTrace');
    }

    final controllerName = _globalChatController.senderName.trim();

    if (controllerName.isNotEmpty && controllerName != 'Membro') {
      return controllerName;
    }

    return 'Membro';
  }

  // ============================================================
  // OPEN GLOBAL CHAT
  // ============================================================

  Future<void> _openGlobalChat(String projectId) async {
    final normalizedProjectId = projectId.trim();

    if (!mounted || normalizedProjectId.isEmpty) {
      return;
    }

    // Marca somente esta Studio Session como lida.
    //
    // Mensagens não lidas de outras Studio Sessions continuam
    // preservadas no controller global.
    _globalChatController.markProjectAsRead(normalizedProjectId);

    _globalChatController.setChatVisible(true, projectId: normalizedProjectId);

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatView(projectId: normalizedProjectId),
        ),
      );
    } finally {
      _globalChatController.setChatVisible(false);
    }
  }

  // ============================================================
  // GLOBAL CALL BANNER
  // ============================================================

  Widget _buildGlobalCallBanner() {
    final currentUserId = _supabase.auth.currentUser?.id.trim();

    if (currentUserId == null || currentUserId.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('project_calls')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false),

      builder: (context, snapshot) {
        final rows = snapshot.data ?? const <Map<String, dynamic>>[];

        Map<String, dynamic>? activeRow;

        for (final row in rows) {
          final status = row['status']?.toString().trim();

          if (status != 'ringing' && status != 'active') {
            continue;
          }

          final createdBy = row['created_by']?.toString().trim();

          final targetUserId = row['target_user_id']?.toString().trim();

          final directlyInvolved =
              createdBy == currentUserId || targetUserId == currentUserId;

          final groupCall = targetUserId == null || targetUserId.isEmpty;

          if (!directlyInvolved && !groupCall) {
            continue;
          }

          activeRow = row;

          break;
        }

        if (activeRow == null) {
          return const SizedBox.shrink();
        }

        return _buildGlobalCallBannerFromRow(activeRow, currentUserId);
      },
    );
  }

  // ============================================================
  // GLOBAL CALL FROM ROW
  // ============================================================

  Widget _buildGlobalCallBannerFromRow(
    Map<String, dynamic> row,
    String currentUserId,
  ) {
    final callId = row['id']?.toString().trim() ?? '';

    final projectId = row['project_id']?.toString().trim() ?? '';

    final createdBy = row['created_by']?.toString().trim() ?? '';

    final targetUserId = row['target_user_id']?.toString().trim();

    final status = row['status']?.toString().trim() ?? '';

    final mediaTypeValue =
        row['media_type']?.toString().trim().toLowerCase() ?? 'audio';

    final bannerMediaType = mediaTypeValue == 'video'
        ? GlobalCallMediaType.video
        : GlobalCallMediaType.audio;

    final incoming =
        status == 'ringing' &&
        createdBy != currentUserId &&
        (targetUserId == currentUserId ||
            targetUserId == null ||
            targetUserId.isEmpty);

    final outgoing = status == 'ringing' && createdBy == currentUserId;

    final active = status == 'active';

    GlobalCallBannerState state = GlobalCallBannerState.hidden;

    if (_isGlobalCallActionProcessing && _globalCallAction == 'end') {
      state = GlobalCallBannerState.ending;
    } else if (incoming) {
      state = GlobalCallBannerState.incoming;
    } else if (outgoing) {
      state = GlobalCallBannerState.calling;
    } else if (active) {
      state = GlobalCallBannerState.active;
    }

    final createdAt = DateTime.tryParse(row['created_at']?.toString() ?? '');

    final startedAt = DateTime.tryParse(row['started_at']?.toString() ?? '');

    final ringingDuration = createdAt == null || !(incoming || outgoing)
        ? null
        : _safeDurationDifference(
            _globalCallClockNow.toUtc(),
            createdAt.toUtc(),
          );

    final duration = startedAt == null || !active
        ? null
        : _safeDurationDifference(
            _globalCallClockNow.toUtc(),
            startedAt.toUtc(),
          );

    final participantUserId = _resolveCallParticipantUserId(
      createdBy: createdBy,
      targetUserId: targetUserId,
      currentUserId: currentUserId,
    );

    return FutureBuilder<String>(
      future: _resolveCallParticipantName(participantUserId),

      builder: (context, snapshot) {
        final participantName =
            snapshot.data ??
            _callParticipantNameCache[participantUserId] ??
            'Membro da sessão';

        return GlobalCallBanner(
          state: state,

          mediaType: bannerMediaType,

          participantName: participantName,

          ringingDuration: ringingDuration,

          duration: duration,

          onOpen: projectId.isEmpty
              ? null
              : () {
                  _openCallPage(projectId);
                },

          onAccept: incoming && callId.isNotEmpty
              ? () {
                  _acceptGlobalCall(callId, projectId);
                }
              : null,

          onReject: incoming && callId.isNotEmpty
              ? () {
                  _rejectGlobalCall(callId);
                }
              : null,

          onEnd: (outgoing || active) && callId.isNotEmpty
              ? () {
                  _endGlobalCall(callId);
                }
              : null,
        );
      },
    );
  }

  // ============================================================
  // SAFE DURATION DIFFERENCE
  // ============================================================

  Duration _safeDurationDifference(DateTime now, DateTime startedAt) {
    final value = now.difference(startedAt);

    if (value.isNegative) {
      return Duration.zero;
    }

    return value;
  }

  // ============================================================
  // RESOLVER ID DO OUTRO PARTICIPANTE
  // ============================================================

  String _resolveCallParticipantUserId({
    required String createdBy,
    required String? targetUserId,
    required String currentUserId,
  }) {
    final normalizedCreatedBy = createdBy.trim();

    final normalizedTargetUserId = targetUserId?.trim();

    // ========================================================
    // EU CRIEI A CHAMADA
    // ========================================================

    if (normalizedCreatedBy == currentUserId) {
      if (normalizedTargetUserId != null && normalizedTargetUserId.isNotEmpty) {
        return normalizedTargetUserId;
      }

      return '';
    }

    // ========================================================
    // OUTRO USUÁRIO CRIOU A CHAMADA
    // ========================================================

    return normalizedCreatedBy;
  }

  // ============================================================
  // RESOLVER NOME DO OUTRO PARTICIPANTE
  // ============================================================
  //
  // Ordem de prioridade:
  //
  // 1. artist_name
  // 2. name
  // 3. @username
  // 4. Membro da sessão
  //
  // ============================================================

  Future<String> _resolveCallParticipantName(String userId) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return 'Membro da sessão';
    }

    final cached = _callParticipantNameCache[normalizedUserId];

    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    try {
      final profile = await _supabase
          .from('profiles')
          .select('id, artist_name, name, username')
          .eq('id', normalizedUserId)
          .maybeSingle();

      if (profile == null) {
        return 'Membro da sessão';
      }

      final artistName = profile['artist_name']?.toString().trim();

      if (artistName != null && artistName.isNotEmpty) {
        _callParticipantNameCache[normalizedUserId] = artistName;

        return artistName;
      }

      final name = profile['name']?.toString().trim();

      if (name != null && name.isNotEmpty) {
        _callParticipantNameCache[normalizedUserId] = name;

        return name;
      }

      final username = profile['username']?.toString().trim().replaceFirst(
        RegExp(r'^@+'),
        '',
      );

      if (username != null && username.isNotEmpty) {
        final usernameLabel = '@$username';

        _callParticipantNameCache[normalizedUserId] = usernameLabel;

        return usernameLabel;
      }
    } catch (error, stackTrace) {
      debugPrint(
        '[DASHBOARD] '
        'Erro ao buscar nome do participante da chamada: '
        '$error',
      );

      debugPrint('$stackTrace');
    }

    return 'Membro da sessão';
  }

  // ============================================================
  // OPEN CALL
  // ============================================================

  Future<void> _openCallPage(String projectId) async {
    if (!mounted || projectId.trim().isEmpty) {
      return;
    }

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => CallView(projectId: projectId)));
  }

  // ============================================================
  // ACCEPT CALL
  // ============================================================

  Future<void> _acceptGlobalCall(String callId, String projectId) async {
    if (_isGlobalCallActionProcessing) {
      return;
    }

    _setGlobalCallProcessing(true, 'accept');

    try {
      await _callRepository.acceptCall(callId: callId);

      if (mounted && projectId.trim().isNotEmpty) {
        await _openCallPage(projectId);
      }
    } catch (error, stackTrace) {
      debugPrint('[DASHBOARD] Erro ao aceitar chamada global: $error');

      debugPrint('$stackTrace');
    } finally {
      _setGlobalCallProcessing(false, null);
    }
  }

  // ============================================================
  // REJECT CALL
  // ============================================================

  Future<void> _rejectGlobalCall(String callId) async {
    if (_isGlobalCallActionProcessing) {
      return;
    }

    _setGlobalCallProcessing(true, 'reject');

    try {
      await _callRepository.rejectCall(callId: callId);
    } catch (error, stackTrace) {
      debugPrint('[DASHBOARD] Erro ao recusar chamada global: $error');

      debugPrint('$stackTrace');
    } finally {
      _setGlobalCallProcessing(false, null);
    }
  }

  // ============================================================
  // END CALL
  // ============================================================

  Future<void> _endGlobalCall(String callId) async {
    if (_isGlobalCallActionProcessing) {
      return;
    }

    _setGlobalCallProcessing(true, 'end');

    try {
      await _callRepository.endCall(callId: callId);
    } catch (error, stackTrace) {
      debugPrint('[DASHBOARD] Erro ao encerrar chamada global: $error');

      debugPrint('$stackTrace');
    } finally {
      _setGlobalCallProcessing(false, null);
    }
  }

  // ============================================================
  // PROCESSING
  // ============================================================

  void _setGlobalCallProcessing(bool value, String? action) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isGlobalCallActionProcessing = value;

      _globalCallAction = action;
    });
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

      onPageChanged: (index) {
        if (!mounted) {
          return;
        }

        setState(() {
          _controller.handlePageChange(index);
        });
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
    _globalCallClockTimer?.cancel();

    _globalCallClockTimer = null;

    _globalChatController.dispose();

    super.dispose();
  }
}
