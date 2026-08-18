import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/communication_permission_controller.dart';
import '../controllers/project_call_controller.dart';
import '../controllers/webrtc_call_controller.dart';

import '../data/models/call_participant_model.dart';
import '../data/models/project_call_model.dart';

import '../../views/sub_features/members_view.dart';

import 'active_call_view.dart';
import 'incoming_call_view.dart';

// ============================================================
// CALL VIEW
// ============================================================
//
// Porta de entrada da funcionalidade de chamadas.
//
// Responsabilidades:
//
// - inicializar ProjectCallController;
// - inicializar CommunicationPermissionController;
// - observar chamadas do projeto;
// - observar permissões de vídeo;
// - observar convites de vídeo;
// - identificar chamada recebida;
// - mostrar chamada recebida;
// - mostrar chamada ativa;
// - permitir iniciar áudio;
// - permitir iniciar vídeo quando houver consentimento;
// - direcionar para MembersView quando vídeo estiver bloqueado.
//
// MODELO DE CONSENTIMENTO:
//
// A permissão de vídeo NÃO é global.
//
// Ela existe entre pares:
//
// usuário A <-> usuário B
//
// Exemplo:
//
// João <-> Artista
// vídeo liberado
//
// João <-> Beatmaker
// somente áudio
//
// Portanto uma chamada de grupo pode conter:
//
// Participante A
// -> vídeo + áudio
//
// Participante B
// -> somente áudio
//
// Participante C
// -> vídeo + áudio
//
// WEBRTC:
//
// Esta versão mantém a integração já existente com:
//
// - WebRtcCallController;
// - WebRtcCallService;
// - CallSignalingService;
// - microfone;
// - câmera;
// - SDP;
// - ICE.
//
// Também mantém os timers de:
//
// - chamada tocando / aguardando atendimento;
// - chamada recebida.
//
// O tempo da chamada já atendida é mostrado pelo
// ActiveCallView.
//
// ============================================================

class CallView extends StatefulWidget {
  final String projectId;

  final String? participantName;

  const CallView({super.key, required this.projectId, this.participantName});

  @override
  State<CallView> createState() => _CallViewState();
}

// ============================================================
// STATE
// ============================================================

class _CallViewState extends State<CallView> {
  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color _background = Color(0xFF08080B);

  static const Color _surface = Color(0xFF111116);

  static const Color _purple = Color(0xFF8B5CF6);

  static const Color _green = Color(0xFF34D399);

  static const Color _orange = Color(0xFFF59E0B);

  // ==========================================================
  // CONTROLLERS
  // ==========================================================

  late final ProjectCallController _callController;

  late final CommunicationPermissionController _permissionController;

  late final WebRtcCallController _webRtcController;

  bool _isSyncingWebRtc = false;
  String? _webRtcCallId;
  String? _offerSentForCallId;

  // ==========================================================
  // SUPABASE
  // ==========================================================

  final SupabaseClient _supabase = Supabase.instance.client;

  // ==========================================================
  // REMOTE MEMBER
  // ==========================================================

  String? _remoteParticipantName;

  String? _remoteParticipantUserId;

  bool _isResolvingRemoteParticipant = false;

  // ==========================================================
  // PARTICIPANTS
  // ==========================================================
  //
  // Nesta etapa a lista recebe o outro membro da chamada
  // usando os dados da própria chamada + profiles.
  //
  // Depois será alimentada diretamente por:
  //
  // WebRtcCallService
  // +
  // Presence / signaling.
  //
  // ==========================================================

  List<CallParticipantModel> _participants = const <CallParticipantModel>[];

  // ==========================================================
  // LOCAL MEDIA STATE
  // ==========================================================
  //
  // Estes estados ainda representam somente a UI.
  //
  // O controle real será transferido posteriormente para:
  //
  // WebRtcCallService.
  //
  // ==========================================================

  bool get _microphoneEnabled => _webRtcController.microphoneEnabled;

  bool get _cameraEnabled => _webRtcController.cameraEnabled;

  bool get _speakerEnabled => _webRtcController.speakerEnabled;

  // ==========================================================
  // CURRENT USER
  // ==========================================================

  String? get _currentUserId {
    try {
      final value = _permissionController.currentUserId.trim();

      if (value.isEmpty) {
        return null;
      }

      return value;
    } catch (_) {
      return null;
    }
  }

  // ==========================================================
  // VIDEO PERMISSION
  // ==========================================================
  //
  // Como a chamada pode ser de grupo, NÃO existe mais:
  //
  // bool videoAllowed global
  //
  // armazenado manualmente.
  //
  // Consideramos que o usuário pode ativar vídeo quando possui
  // ao menos uma relação bilateral liberada.
  //
  // A distribuição real do vídeo continuará sendo individual:
  //
  // João -> Artista
  // permitido
  //
  // João -> Beatmaker
  // bloqueado
  //
  // ==========================================================

  bool get _videoAllowed {
    for (final permission in _permissionController.permissions) {
      if (permission.videoAllowed) {
        return true;
      }
    }

    return false;
  }

  // ==========================================================
  // VIDEO RELATION COUNT
  // ==========================================================

  int get _videoAllowedRelations {
    return _permissionController.permissions
        .where((permission) => permission.videoAllowed)
        .length;
  }

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _callController = ProjectCallController(projectId: widget.projectId);

    _permissionController = CommunicationPermissionController(
      projectId: widget.projectId,
    );

    _webRtcController = WebRtcCallController();

    final initialParticipantName = widget.participantName?.trim();

    if (initialParticipantName != null && initialParticipantName.isNotEmpty) {
      _remoteParticipantName = initialParticipantName;
    }

    _initialize();
  }

  // ==========================================================
  // INITIALIZE
  // ==========================================================

  Future<void> _initialize() async {
    await Future.wait([_callController.init(), _permissionController.init()]);

    if (!mounted) {
      return;
    }

    setState(() {});

    await _syncRemoteParticipant(_callController.activeCall);

    final activeCall = _callController.activeCall;

    if (activeCall != null && activeCall.isActive) {
      await _syncWebRtcForCall(activeCall);
    }

    final remoteUserId = _remoteParticipantUserId;

    if (mounted &&
        activeCall != null &&
        remoteUserId != null &&
        remoteUserId.isNotEmpty &&
        _participants.isEmpty) {
      setState(() {
        _participants = _buildRemoteParticipants(
          userId: remoteUserId,

          displayName: _participantDisplayName,

          call: activeCall,
        );
      });
    }
  }

  // ==========================================================
  // REFRESH
  // ==========================================================

  Future<void> _refresh() async {
    await Future.wait([
      _callController.refresh(),

      _permissionController.refresh(),
    ]);

    await _syncRemoteParticipant(_callController.activeCall);

    final call = _callController.activeCall;

    if (call != null && call.isActive) {
      await _syncWebRtcForCall(call);
    } else {
      await _stopWebRtcIfNeeded();
    }
  }

  // ==========================================================
  // START AUDIO
  // ==========================================================

  Future<void> _startAudio() async {
    final call = await _callController.startAudioCall();

    if (!mounted || call == null) {
      return;
    }

    await _syncRemoteParticipant(call);

    // A mídia real será aberta quando a chamada ficar ativa.
  }

  // ==========================================================
  // START VIDEO
  // ==========================================================

  Future<void> _startVideo() async {
    if (!_videoAllowed) {
      _showVideoPermissionRequired();

      return;
    }

    final call = await _callController.startVideoCall();

    if (!mounted || call == null) {
      return;
    }

    await _syncRemoteParticipant(call);

    // A câmera real será aberta quando a chamada ficar ativa.
  }

  // ==========================================================
  // WEBRTC SYNC
  // ==========================================================

  Future<void> _syncWebRtcForCall(ProjectCallModel call) async {
    if (!mounted || _isSyncingWebRtc || !call.isActive) {
      return;
    }

    final currentUserId = _currentUserId;
    final remoteUserId = _resolveRemoteParticipantUserId(call);
    final callId = call.id.trim();

    if (currentUserId == null ||
        currentUserId.isEmpty ||
        remoteUserId.isEmpty ||
        callId.isEmpty) {
      return;
    }

    if (_webRtcController.initialized && _webRtcCallId == callId) {
      await _startOfferIfNeeded(call);
      return;
    }

    _isSyncingWebRtc = true;

    try {
      if (_webRtcCallId != null && _webRtcCallId != callId) {
        await _webRtcController.hangup();
        _webRtcCallId = null;
        _offerSentForCallId = null;
      }

      final initialized = await _webRtcController.initialize(
        callId: callId,
        currentUserId: currentUserId,
        remoteUserId: remoteUserId,
        enableVideo: call.startedAsVideo && _videoAllowed,
      );

      if (!mounted || !initialized) {
        final error = _webRtcController.errorMessage;

        if (mounted && error != null && error.isNotEmpty) {
          _showMessage(error);
        }

        return;
      }

      _webRtcCallId = callId;

      debugPrint('[CALL VIEW] WebRTC preparado: $callId');

      await _startOfferIfNeeded(call);
    } catch (error, stackTrace) {
      debugPrint('[CALL VIEW] Erro preparando WebRTC: $error');
      debugPrint('$stackTrace');

      if (mounted) {
        _showMessage('Não foi possível conectar o áudio da chamada.');
      }
    } finally {
      _isSyncingWebRtc = false;
    }
  }

  Future<void> _startOfferIfNeeded(ProjectCallModel call) async {
    final currentUserId = _currentUserId;
    final callId = call.id.trim();

    if (currentUserId == null ||
        currentUserId.isEmpty ||
        callId.isEmpty ||
        !call.isActive) {
      return;
    }

    if (call.createdBy.trim() != currentUserId) {
      return;
    }

    if (_offerSentForCallId == callId) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!mounted) {
      return;
    }

    final success = await _webRtcController.startAsCaller();

    if (!success) {
      final error = _webRtcController.errorMessage;

      if (mounted && error != null && error.isNotEmpty) {
        _showMessage(error);
      }

      return;
    }

    _offerSentForCallId = callId;

    debugPrint('[CALL VIEW] Offer WebRTC enviada: $callId');
  }

  Future<void> _stopWebRtcIfNeeded() async {
    if (_webRtcCallId == null) {
      return;
    }

    final previousCallId = _webRtcCallId;

    _webRtcCallId = null;
    _offerSentForCallId = null;

    try {
      await _webRtcController.hangup();

      debugPrint('[CALL VIEW] WebRTC encerrado: $previousCallId');
    } catch (error) {
      debugPrint('[CALL VIEW] Erro encerrando WebRTC: $error');
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _callController,
        _permissionController,
        _webRtcController,
      ]),

      builder: (context, _) {
        // ====================================================
        // LOADING
        // ====================================================

        if (_callController.isLoading || _permissionController.isLoading) {
          return const Scaffold(
            backgroundColor: _background,

            body: Center(child: CircularProgressIndicator()),
          );
        }

        final call = _callController.activeCall;

        if (call != null && call.isActive) {
          Future.microtask(() => _syncWebRtcForCall(call));
        } else if (_webRtcCallId != null) {
          Future.microtask(_stopWebRtcIfNeeded);
        }

        if (call != null) {
          final participantUserId = _resolveRemoteParticipantUserId(call);

          final shouldResolveParticipant =
              participantUserId != _remoteParticipantUserId ||
              _remoteParticipantName == null ||
              _remoteParticipantName!.trim().isEmpty;

          if (shouldResolveParticipant) {
            Future.microtask(() {
              _syncRemoteParticipant(call);
            });
          } else {
            final currentParticipants = _participants;

            final participantNeedsStateUpdate =
                currentParticipants.isEmpty ||
                currentParticipants.first.connected != call.isActive ||
                currentParticipants.first.cameraEnabled !=
                    (call.startedAsVideo && call.isActive);

            if (participantNeedsStateUpdate) {
              Future.microtask(() {
                if (!mounted) {
                  return;
                }

                setState(() {
                  _participants = _buildRemoteParticipants(
                    userId: participantUserId,

                    displayName: _participantDisplayName,

                    call: call,
                  );
                });
              });
            }
          }
        }

        // ====================================================
        // ACTIVE CALL
        // ====================================================

        if (call != null && call.isActive) {
          return ActiveCallView(
            projectId: widget.projectId,

            controller: _callController,

            call: call,

            participants: _participants,

            microphoneEnabled: _microphoneEnabled,

            cameraEnabled: _cameraEnabled,

            videoAllowed: _videoAllowed,

            speakerEnabled: _speakerEnabled,

            onToggleMicrophone: _toggleMicrophone,

            onToggleCamera: _toggleCamera,

            onRequestVideo: _requestVideo,

            onSwitchCamera: _switchCamera,

            onToggleSpeaker: _toggleSpeaker,
          );
        }

        // ====================================================
        // RINGING
        // ====================================================

        if (call != null && call.isRinging) {
          final isIncoming = _isIncomingCall(call);

          // ==================================================
          // RECEBENDO
          // ==================================================
          //
          // Quem NÃO criou a chamada entra aqui.
          //
          // IncomingCallView é responsável por mostrar:
          //
          // Ligação de <nome>
          //
          // ==================================================

          if (isIncoming) {
            return Stack(
              children: [
                IncomingCallView(
                  controller: _callController,

                  call: call,

                  callerName: _participantDisplayName,

                  onAccepted: _handleCallAccepted,

                  onRejected: _handleCallRejected,
                ),

                Positioned(
                  top: 18,
                  left: 0,
                  right: 0,

                  child: IgnorePointer(
                    child: Center(
                      child: _buildCallTimerPill(
                        icon: call.startedAsVideo
                            ? Icons.video_call_rounded
                            : Icons.ring_volume_rounded,

                        label: call.startedAsVideo
                            ? 'Chamada de vídeo recebida'
                            : 'Chamada recebida',

                        duration: _callController.currentRingingDuration,

                        color: _green,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // ==================================================
          // LIGANDO
          // ==================================================
          //
          // Somente quem criou a chamada chega aqui.
          //
          // A tela mostra:
          //
          // Chamando <nome>...
          //
          // ==================================================

          return _buildOutgoingCall(call);
        }

        // ====================================================
        // IDLE
        // ====================================================

        return _buildIdle();
      },
    );
  }

  // ==========================================================
  // PARTICIPANT DISPLAY NAME
  // ==========================================================

  String get _participantDisplayName {
    final value = _remoteParticipantName?.trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return 'Membro da sessão';
  }

  // ==========================================================
  // RESOLVE REMOTE PARTICIPANT ID
  // ==========================================================

  String _resolveRemoteParticipantUserId(ProjectCallModel call) {
    final currentUserId = _currentUserId;

    if (currentUserId == null) {
      return '';
    }

    final createdBy = call.createdBy.trim();

    final targetUserId = call.targetUserId?.trim();

    if (createdBy == currentUserId) {
      return targetUserId ?? '';
    }

    return createdBy;
  }

  // ==========================================================
  // SYNC REMOTE PARTICIPANT
  // ==========================================================

  Future<void> _syncRemoteParticipant(ProjectCallModel? call) async {
    if (!mounted || call == null || _isResolvingRemoteParticipant) {
      return;
    }

    final userId = _resolveRemoteParticipantUserId(call);

    if (userId.isEmpty) {
      return;
    }

    if (_remoteParticipantUserId == userId &&
        _remoteParticipantName != null &&
        _remoteParticipantName!.trim().isNotEmpty) {
      return;
    }

    _remoteParticipantUserId = userId;

    _isResolvingRemoteParticipant = true;

    try {
      final profile = await _supabase
          .from('profiles')
          .select('id, artist_name, name, username')
          .eq('id', userId)
          .maybeSingle();

      if (!mounted) {
        return;
      }

      final resolvedName = _resolveProfileName(profile);

      setState(() {
        _remoteParticipantName = resolvedName;

        _participants = _buildRemoteParticipants(
          userId: userId,

          displayName: resolvedName,

          call: call,
        );
      });
    } catch (error, stackTrace) {
      debugPrint(
        '[CALL VIEW] '
        'Erro ao carregar nome do participante: '
        '$error',
      );

      debugPrint('$stackTrace');
    } finally {
      _isResolvingRemoteParticipant = false;
    }
  }

  // ==========================================================
  // BUILD REMOTE PARTICIPANTS
  // ==========================================================
  //
  // Enquanto o WebRTC / Presence ainda não alimenta a lista
  // real de participantes, criamos o participante remoto a
  // partir da própria chamada.
  //
  // Isso permite que ActiveCallView mostre:
  //
  // - nome;
  // - estado de áudio;
  // - estado de vídeo inicial;
  //
  // sem continuar exibindo a tela vazia.
  //
  // Quando WebRtcCallService passar a fornecer Presence real,
  // esta lista poderá ser substituída diretamente pelos peers.
  //
  // ==========================================================

  List<CallParticipantModel> _buildRemoteParticipants({
    required String userId,
    required String displayName,
    required ProjectCallModel call,
  }) {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return const <CallParticipantModel>[];
    }

    final normalizedName = displayName.trim();

    return <CallParticipantModel>[
      CallParticipantModel(
        userId: normalizedUserId,

        name: normalizedName.isEmpty ? 'Membro da sessão' : normalizedName,

        connected: call.isActive,

        microphoneEnabled: true,

        audioConnected: call.isActive,

        cameraEnabled: call.startedAsVideo && call.isActive,

        videoConnected: false,

        isSpeaking: false,

        isLocalUser: false,
      ),
    ];
  }

  // ==========================================================
  // RESOLVE PROFILE NAME
  // ==========================================================

  String _resolveProfileName(Map<String, dynamic>? profile) {
    if (profile == null) {
      return 'Membro da sessão';
    }

    final artistName = profile['artist_name']?.toString().trim();

    if (artistName != null && artistName.isNotEmpty) {
      return artistName;
    }

    final name = profile['name']?.toString().trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    final username = profile['username']?.toString().trim().replaceFirst(
      RegExp(r'^@+'),
      '',
    );

    if (username != null && username.isNotEmpty) {
      return '@$username';
    }

    return 'Membro da sessão';
  }

  // ==========================================================
  // INCOMING CALL
  // ==========================================================

  bool _isIncomingCall(ProjectCallModel call) {
    final currentUserId = _currentUserId;

    if (currentUserId == null || currentUserId.isEmpty) {
      return false;
    }

    final createdBy = call.createdBy.trim();

    final targetUserId = call.targetUserId?.trim();

    // ======================================================
    // QUEM CRIOU A CHAMADA
    // ======================================================
    //
    // Se a chamada foi criada pelo usuário autenticado,
    // então este lado SEMPRE é o lado que está ligando.
    //
    // Portanto:
    //
    // createdBy == currentUserId
    //
    // -> "Chamando <nome>..."
    //
    // ======================================================

    if (createdBy == currentUserId) {
      return false;
    }

    // ======================================================
    // CHAMADA DIRETA
    // ======================================================
    //
    // Se existe target_user_id, somente o destinatário deve
    // enxergar a chamada como recebida.
    //
    // ======================================================

    if (targetUserId != null && targetUserId.isNotEmpty) {
      return targetUserId == currentUserId;
    }

    // ======================================================
    // CHAMADA DA SESSÃO / GRUPO
    // ======================================================
    //
    // Quando não existe target específico, qualquer membro
    // diferente do criador deve enxergar como chamada
    // recebida.
    //
    // O criador já foi filtrado acima.
    //
    // Portanto:
    //
    // criador
    // -> Chamando...
    //
    // demais membros
    // -> Ligação de <nome>...
    //
    // ======================================================

    return true;
  }

  // ==========================================================
  // ACCEPTED
  // ==========================================================

  void _handleCallAccepted() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ==========================================================
  // REJECTED
  // ==========================================================

  void _handleCallRejected() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ==========================================================
  // IDLE
  // ==========================================================

  Widget _buildIdle() {
    return Scaffold(
      backgroundColor: _background,

      appBar: AppBar(
        backgroundColor: Colors.transparent,

        surfaceTintColor: Colors.transparent,

        elevation: 0,

        title: const Text(
          'Ligar',

          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _refresh,

        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.all(18),

          children: [
            // ================================================
            // HERO
            // ================================================
            _buildHero(),

            const SizedBox(height: 26),

            // ================================================
            // SECTION
            // ================================================
            const Text(
              'COMUNICAÇÃO',

              style: TextStyle(
                color: Colors.white38,

                fontSize: 10,

                fontWeight: FontWeight.w700,

                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 12),

            // ================================================
            // AUDIO
            // ================================================
            _buildCallAction(
              icon: Icons.call_rounded,

              title: 'Áudio',

              description: 'Converse por voz com os membros da sessão.',

              enabled: true,

              onTap: _callController.isProcessing ? null : _startAudio,
            ),

            const SizedBox(height: 10),

            // ================================================
            // VIDEO
            // ================================================
            _buildCallAction(
              icon: _videoAllowed ? Icons.videocam_rounded : Icons.lock_rounded,

              title: 'Vídeo',

              description: _videoDescription,

              enabled: _videoAllowed,

              onTap: _callController.isProcessing
                  ? null
                  : _videoAllowed
                  ? _startVideo
                  : _showVideoPermissionRequired,
            ),

            // ================================================
            // VIDEO LOCK INFO
            // ================================================
            if (!_videoAllowed) ...[
              const SizedBox(height: 14),

              _buildVideoUnlockInfo(),
            ],

            // ================================================
            // VIDEO RELATIONS INFO
            // ================================================
            if (_videoAllowed) ...[
              const SizedBox(height: 14),

              _buildVideoRelationsInfo(),
            ],

            // ================================================
            // PERMISSION ERROR
            // ================================================
            if (_permissionController.hasError) ...[
              const SizedBox(height: 18),

              _buildPermissionError(),
            ],

            // ================================================
            // CALL ERROR
            // ================================================
            if (_callController.hasError) ...[
              const SizedBox(height: 18),

              _buildCallError(),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // VIDEO DESCRIPTION
  // ==========================================================

  String get _videoDescription {
    if (!_videoAllowed) {
      return 'Requer consentimento com pelo menos um membro.';
    }

    if (_videoAllowedRelations == 1) {
      return 'Vídeo liberado com 1 membro da sessão.';
    }

    return 'Vídeo liberado com '
        '$_videoAllowedRelations membros da sessão.';
  }

  // ==========================================================
  // HERO
  // ==========================================================

  Widget _buildHero() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),

        gradient: const LinearGradient(
          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

          colors: [Color(0xFF21113E), _surface],
        ),

        border: Border.all(color: _purple.withValues(alpha: 0.20)),
      ),

      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(Icons.spatial_audio_off_rounded, color: _purple, size: 30),

          SizedBox(height: 14),

          Text(
            'Converse no seu ritmo',

            style: TextStyle(
              color: Colors.white,

              fontSize: 18,

              fontWeight: FontWeight.w700,
            ),
          ),

          SizedBox(height: 6),

          Text(
            'Comece por áudio. O vídeo só é compartilhado '
            'entre participantes que deram consentimento.',

            style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.45),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // CALL ACTION
  // ==========================================================

  Widget _buildCallAction({
    required IconData icon,
    required String title,
    required String description,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(18),

        child: Ink(
          padding: const EdgeInsets.all(15),

          decoration: BoxDecoration(
            color: _surface,

            borderRadius: BorderRadius.circular(18),

            border: Border.all(
              color: enabled
                  ? _purple.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.05),
            ),
          ),

          child: Row(
            children: [
              // ==============================================
              // ICON
              // ==============================================
              Container(
                width: 44,

                height: 44,

                decoration: BoxDecoration(
                  color: enabled
                      ? _purple.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.04),

                  borderRadius: BorderRadius.circular(14),
                ),

                child: Icon(
                  icon,

                  color: enabled ? _purple : Colors.white30,

                  size: 21,
                ),
              ),

              const SizedBox(width: 12),

              // ==============================================
              // TEXT
              // ==============================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,

                      style: TextStyle(
                        color: enabled ? Colors.white : Colors.white38,

                        fontSize: 13,

                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      description,

                      style: const TextStyle(
                        color: Colors.white30,

                        fontSize: 9,

                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              // ==============================================
              // TRAILING
              // ==============================================
              Icon(
                enabled
                    ? Icons.chevron_right_rounded
                    : Icons.lock_outline_rounded,

                color: enabled ? Colors.white24 : Colors.white12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // VIDEO LOCK INFO
  // ==========================================================

  Widget _buildVideoUnlockInfo() {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: _purple.withValues(alpha: 0.06),

        borderRadius: BorderRadius.circular(16),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Icon(Icons.verified_user_outlined, color: _purple, size: 18),

              SizedBox(width: 10),

              Expanded(
                child: Text(
                  'Vídeo é uma camada adicional de confiança. '
                  'Cada membro precisa aceitar individualmente '
                  'antes de receber ou compartilhar vídeo com você.',

                  style: TextStyle(
                    color: Colors.white38,

                    fontSize: 10,

                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,

            child: OutlinedButton.icon(
              onPressed: _openMembers,

              icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),

              label: const Text('Escolher membros para vídeo'),

              style: OutlinedButton.styleFrom(
                foregroundColor: _purple,

                side: BorderSide(color: _purple.withValues(alpha: 0.32)),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),

                textStyle: const TextStyle(
                  fontSize: 10,

                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // VIDEO RELATIONS INFO
  // ==========================================================

  Widget _buildVideoRelationsInfo() {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: _green.withValues(alpha: 0.055),

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: _green.withValues(alpha: 0.12)),
      ),

      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: _green, size: 18),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              _videoAllowedRelations == 1
                  ? 'Você possui consentimento de vídeo com 1 membro.'
                  : 'Você possui consentimento de vídeo com '
                        '$_videoAllowedRelations membros.',

              style: const TextStyle(
                color: Colors.white54,

                fontSize: 10,

                height: 1.4,
              ),
            ),
          ),

          IconButton(
            tooltip: 'Gerenciar',

            onPressed: _openMembers,

            icon: const Icon(
              Icons.manage_accounts_outlined,

              color: _green,

              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // OPEN MEMBERS
  // ==========================================================

  Future<void> _openMembers() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MembersView(projectId: widget.projectId),
      ),
    );

    if (!mounted) {
      return;
    }

    await _permissionController.refresh();
  }

  // ==========================================================
  // VIDEO PERMISSION REQUIRED
  // ==========================================================

  void _showVideoPermissionRequired() {
    showModalBottomSheet<void>(
      context: context,

      backgroundColor: _surface,

      showDragHandle: true,

      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Container(
                  width: 44,

                  height: 44,

                  decoration: BoxDecoration(
                    color: _purple.withValues(alpha: 0.12),

                    borderRadius: BorderRadius.circular(14),
                  ),

                  child: const Icon(Icons.lock_outline_rounded, color: _purple),
                ),

                const SizedBox(height: 14),

                const Text(
                  'Vídeo bloqueado',

                  style: TextStyle(
                    color: Colors.white,

                    fontSize: 16,

                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 7),

                const Text(
                  'Antes de usar vídeo, escolha um ou mais '
                  'membros e envie um convite de consentimento. '
                  'Cada pessoa decide individualmente.',

                  style: TextStyle(
                    color: Colors.white54,

                    fontSize: 11,

                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,

                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);

                      _openMembers();
                    },

                    icon: const Icon(Icons.person_search_rounded, size: 17),

                    label: const Text('Selecionar membros'),

                    style: FilledButton.styleFrom(
                      backgroundColor: _purple,

                      foregroundColor: Colors.white,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // CALL TIMER PILL
  // ==========================================================

  Widget _buildCallTimerPill({
    required IconData icon,
    required String label,
    required Duration duration,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),

      decoration: BoxDecoration(
        color: _surface.withValues(alpha: 0.96),

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: color.withValues(alpha: 0.22)),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),

            blurRadius: 12,

            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(icon, color: color, size: 14),

          const SizedBox(width: 7),

          Text(
            '$label · ${_formatDuration(duration)}',

            style: const TextStyle(
              color: Colors.white70,

              fontSize: 10,

              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // FORMAT DURATION
  // ==========================================================

  String _formatDuration(Duration value) {
    final totalSeconds = value.inSeconds < 0 ? 0 : value.inSeconds;

    final hours = totalSeconds ~/ 3600;

    final minutes = (totalSeconds % 3600) ~/ 60;

    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // ==========================================================
  // OUTGOING CALL
  // ==========================================================

  Widget _buildOutgoingCall(ProjectCallModel call) {
    return Scaffold(
      backgroundColor: _background,

      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                // ============================================
                // ICON
                // ============================================
                Container(
                  width: 90,

                  height: 90,

                  decoration: BoxDecoration(
                    color: _purple.withValues(alpha: 0.10),

                    shape: BoxShape.circle,
                  ),

                  child: Icon(
                    call.startedAsVideo
                        ? Icons.videocam_rounded
                        : Icons.call_rounded,

                    color: _purple,

                    size: 34,
                  ),
                ),

                const SizedBox(height: 24),

                // ============================================
                // STATUS
                // ============================================
                Text(
                  'Chamando $_participantDisplayName...',

                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    color: Colors.white,

                    fontSize: 20,

                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  call.startedAsVideo
                      ? 'Aguardando atendimento por vídeo · '
                            '${_formatDuration(_callController.currentRingingDuration)}'
                      : 'Aguardando atendimento · '
                            '${_formatDuration(_callController.currentRingingDuration)}',

                  textAlign: TextAlign.center,

                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),

                if (call.startedAsVideo) ...[
                  const SizedBox(height: 7),

                  const Text(
                    'O vídeo será compartilhado somente '
                    'com participantes autorizados.',

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      color: Colors.white30,

                      fontSize: 9,

                      height: 1.4,
                    ),
                  ),
                ],

                const SizedBox(height: 38),

                // ============================================
                // CANCEL
                // ============================================
                GestureDetector(
                  onTap: _callController.isProcessing
                      ? null
                      : _cancelOutgoingCall,

                  child: Container(
                    width: 62,

                    height: 62,

                    decoration: const BoxDecoration(
                      color: Colors.redAccent,

                      shape: BoxShape.circle,
                    ),

                    child: const Icon(
                      Icons.call_end_rounded,

                      color: Colors.white,

                      size: 27,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Cancelar',

                  style: TextStyle(color: Colors.white38, fontSize: 9),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // CANCEL OUTGOING CALL
  // ==========================================================

  Future<void> _cancelOutgoingCall() async {
    await _stopWebRtcIfNeeded();
    await _callController.endCall();
  }

  // ==========================================================
  // MICROPHONE
  // ==========================================================

  void _toggleMicrophone() {
    Future.microtask(() async {
      final success = await _webRtcController.toggleMicrophone();

      if (!mounted) {
        return;
      }

      if (!success) {
        _showMessage('Não foi possível alterar o microfone.');
      }
    });
  }

  // ==========================================================
  // CAMERA
  // ==========================================================

  void _toggleCamera() {
    if (!_videoAllowed) {
      _requestVideo();
      return;
    }

    Future.microtask(() async {
      final success = await _webRtcController.toggleCamera();

      if (!mounted) {
        return;
      }

      if (!success) {
        _showMessage('Não foi possível alterar a câmera.');
      }
    });
  }

  // ==========================================================
  // REQUEST VIDEO
  // ==========================================================

  void _requestVideo() {
    _openMembers();
  }

  // ==========================================================
  // SWITCH CAMERA
  // ==========================================================

  void _switchCamera() {
    Future.microtask(() async {
      final success = await _webRtcController.switchCamera();

      if (!mounted) {
        return;
      }

      if (!success) {
        _showMessage('Não foi possível trocar a câmera.');
      }
    });
  }

  // ==========================================================
  // SPEAKER
  // ==========================================================

  void _toggleSpeaker() {
    Future.microtask(() async {
      await _webRtcController.toggleSpeaker();
    });
  }

  // ==========================================================
  // CALL ERROR
  // ==========================================================

  Widget _buildCallError() {
    return _buildErrorBox(
      _callController.errorMessage ?? 'Erro ao processar chamada.',
    );
  }

  // ==========================================================
  // PERMISSION ERROR
  // ==========================================================

  Widget _buildPermissionError() {
    return _buildErrorBox(
      _permissionController.errorMessage ??
          'Erro ao carregar permissões de vídeo.',
    );
  }

  // ==========================================================
  // ERROR BOX
  // ==========================================================

  Widget _buildErrorBox(String message) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.07),

        borderRadius: BorderRadius.circular(14),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Icon(
            Icons.error_outline_rounded,

            color: Colors.redAccent,

            size: 17,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              message,

              style: const TextStyle(
                color: Colors.redAccent,

                fontSize: 10,

                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _callController.dispose();

    _permissionController.dispose();

    _webRtcController.dispose();

    super.dispose();
  }
}
