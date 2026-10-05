import 'package:flutter/material.dart';

import '../../data/models/call_participant_model.dart';

import 'audio_participant_tile.dart';
import 'video_participant_tile.dart';

// ============================================================
// CALL PARTICIPANT TILE
// ============================================================
//
// Componente responsável por decidir COMO um participante
// deve ser exibido dentro da chamada.
//
// A decisão é feita individualmente.
//
// Isso permite uma chamada híbrida:
//
// Usuário A
// → vídeo + áudio
//
// Usuário B
// → somente áudio
//
// Usuário C
// → vídeo + áudio
//
// Usuário D
// → somente áudio
//
// IMPORTANTE:
//
// O tipo inicial da chamada NÃO determina obrigatoriamente
// como todos os participantes serão exibidos.
//
// Cada participante possui seu próprio estado.
//
// ============================================================

class CallParticipantTile
    extends
        StatelessWidget {
  // ==========================================================
  // PARTICIPANTE
  // ==========================================================

  final CallParticipantModel participant;

  // ==========================================================
  // SUPERFÍCIE DE VÍDEO
  // ==========================================================
  //
  // A UI não conhece diretamente RTCVideoRenderer.
  //
  // A camada responsável pelo WebRTC poderá passar:
  //
  // RTCVideoView(renderer)
  //
  // como um Widget.
  //
  // Isso evita acoplamento entre:
  //
  // widgets/
  //
  // e
  //
  // infraestrutura WebRTC.
  //
  // ==========================================================

  final Widget? videoSurface;

  // ==========================================================
  // CALLBACK
  // ==========================================================

  final VoidCallback? onTap;

  // ==========================================================
  // CONFIGURAÇÃO DE ÁUDIO
  // ==========================================================

  final bool compactAudio;

  // ==========================================================
  // CONFIGURAÇÃO DE VÍDEO
  // ==========================================================

  final double videoAspectRatio;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  const CallParticipantTile({
    super.key,
    required this.participant,
    this.videoSurface,
    this.onTap,
    this.compactAudio = false,
    this.videoAspectRatio =
        16 /
        9,
  });

  // ==========================================================
  // POSSUI VÍDEO ATIVO
  // ==========================================================
  //
  // Para mostrar VideoParticipantTile precisamos de DUAS
  // condições:
  //
  // 1. participante está com vídeo ativo;
  // 2. existe uma superfície de vídeo disponível.
  //
  // Isso evita mostrar uma área preta caso o estado remoto
  // informe vídeo antes do renderer estar pronto.
  //
  // ==========================================================

  bool get _canRenderVideo {
    return participant.hasVideo &&
        videoSurface !=
            null;
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    // ========================================================
    // PARTICIPANTE COM VÍDEO
    // ========================================================

    if (_canRenderVideo) {
      return _buildVideoParticipant();
    }

    // ========================================================
    // PARTICIPANTE SOMENTE ÁUDIO
    // ========================================================

    return _buildAudioParticipant();
  }

  // ==========================================================
  // VIDEO PARTICIPANT
  // ==========================================================

  Widget _buildVideoParticipant() {
    return VideoParticipantTile(
      participant: participant,
      videoSurface: videoSurface!,
      onTap: onTap,
      aspectRatio: videoAspectRatio,
    );
  }

  // ==========================================================
  // AUDIO PARTICIPANT
  // ==========================================================

  Widget _buildAudioParticipant() {
    return AudioParticipantTile(
      participant: participant,
      onTap: onTap,
      compact: compactAudio,
    );
  }
}
