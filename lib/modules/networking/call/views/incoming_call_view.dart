import 'package:flutter/material.dart';

import '../controllers/project_call_controller.dart';
import '../data/models/project_call_model.dart';

// ============================================================
// INCOMING CALL VIEW
// ============================================================
//
// Tela de chamada recebida.
//
// Responsabilidades:
//
// - mostrar chamada recebida;
// - mostrar tipo da chamada;
// - aceitar;
// - recusar.
//
// Não inicializa câmera/microfone diretamente.
//
// Depois de aceitar:
//
// ProjectCallController
//        ↓
// ActiveCallView
//        ↓
// WebRtcCallService
//
// ============================================================

class IncomingCallView
    extends
        StatefulWidget {
  final ProjectCallController controller;

  final ProjectCallModel call;

  final String callerName;

  final String? callerUsername;

  final String? callerAvatarUrl;

  final VoidCallback? onAccepted;

  final VoidCallback? onRejected;

  const IncomingCallView({
    super.key,
    required this.controller,
    required this.call,
    required this.callerName,
    this.callerUsername,
    this.callerAvatarUrl,
    this.onAccepted,
    this.onRejected,
  });

  @override
  State<
    IncomingCallView
  >
  createState() => _IncomingCallViewState();
}

// ============================================================
// STATE
// ============================================================

class _IncomingCallViewState
    extends
        State<
          IncomingCallView
        > {
  static const Color _background = Color(
    0xFF08080B,
  );

  static const Color _purple = Color(
    0xFF8B5CF6,
  );

  static const Color _green = Color(
    0xFF34D399,
  );

  static const Color _red = Color(
    0xFFEF4444,
  );

  // ==========================================================
  // ACCEPT
  // ==========================================================

  Future<
    void
  >
  _accept() async {
    final success = await widget.controller.acceptCall(
      call: widget.call,
    );

    if (!mounted ||
        !success) {
      return;
    }

    widget.onAccepted?.call();
  }

  // ==========================================================
  // REJECT
  // ==========================================================

  Future<
    void
  >
  _reject() async {
    final success = await widget.controller.rejectCall(
      call: widget.call,
    );

    if (!mounted ||
        !success) {
      return;
    }

    widget.onRejected?.call();

    Navigator.of(
      context,
    ).maybePop();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: _background,

      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.controller,

          builder:
              (
                context,
                _,
              ) {
                return Padding(
                  padding: const EdgeInsets.all(
                    28,
                  ),

                  child: Column(
                    children: [
                      const Spacer(),

                      // ==========================================
                      // TYPE
                      // ==========================================
                      _buildCallType(),

                      const SizedBox(
                        height: 30,
                      ),

                      // ==========================================
                      // AVATAR
                      // ==========================================
                      _buildAvatar(),

                      const SizedBox(
                        height: 20,
                      ),

                      // ==========================================
                      // NAME
                      // ==========================================
                      Text(
                        widget.callerName,

                        textAlign: TextAlign.center,

                        style: const TextStyle(
                          color: Colors.white,

                          fontSize: 24,

                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      if (_usernameLabel.isNotEmpty) ...[
                        const SizedBox(
                          height: 6,
                        ),

                        Text(
                          _usernameLabel,

                          style: const TextStyle(
                            color: Colors.white38,

                            fontSize: 12,
                          ),
                        ),
                      ],

                      const SizedBox(
                        height: 12,
                      ),

                      Text(
                        widget.call.startedAsVideo
                            ? 'quer iniciar uma chamada de vídeo'
                            : 'está ligando para você',

                        textAlign: TextAlign.center,

                        style: const TextStyle(
                          color: Colors.white54,

                          fontSize: 12,
                        ),
                      ),

                      const Spacer(),

                      // ==========================================
                      // ACTIONS
                      // ==========================================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                        children: [
                          _buildAction(
                            icon: Icons.call_end_rounded,

                            label: 'Recusar',

                            color: _red,

                            onTap: widget.controller.isProcessing
                                ? null
                                : _reject,
                          ),

                          _buildAction(
                            icon: widget.call.startedAsVideo
                                ? Icons.videocam_rounded
                                : Icons.call_rounded,

                            label: 'Aceitar',

                            color: _green,

                            onTap: widget.controller.isProcessing
                                ? null
                                : _accept,
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 24,
                      ),
                    ],
                  ),
                );
              },
        ),
      ),
    );
  }

  // ==========================================================
  // TYPE
  // ==========================================================

  Widget _buildCallType() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,

        vertical: 7,
      ),

      decoration: BoxDecoration(
        color: _purple.withValues(
          alpha: 0.10,
        ),

        borderRadius: BorderRadius.circular(
          30,
        ),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(
            widget.call.startedAsVideo
                ? Icons.videocam_rounded
                : Icons.call_rounded,

            color: _purple,

            size: 14,
          ),

          const SizedBox(
            width: 6,
          ),

          Text(
            widget.call.startedAsVideo
                ? 'CHAMADA DE VÍDEO'
                : 'CHAMADA DE ÁUDIO',

            style: const TextStyle(
              color: _purple,

              fontSize: 9,

              fontWeight: FontWeight.w800,

              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // AVATAR
  // ==========================================================

  Widget _buildAvatar() {
    final url = widget.callerAvatarUrl?.trim();

    return Container(
      width: 112,

      height: 112,

      decoration: BoxDecoration(
        shape: BoxShape.circle,

        border: Border.all(
          color: _purple.withValues(
            alpha: 0.35,
          ),

          width: 2,
        ),

        boxShadow: [
          BoxShadow(
            color: _purple.withValues(
              alpha: 0.14,
            ),

            blurRadius: 28,
          ),
        ],
      ),

      child: ClipOval(
        child:
            url !=
                    null &&
                url.isNotEmpty
            ? Image.network(
                url,

                fit: BoxFit.cover,

                errorBuilder:
                    (
                      context,
                      error,
                      stackTrace,
                    ) => _buildInitial(),
              )
            : _buildInitial(),
      ),
    );
  }

  Widget _buildInitial() {
    final name = widget.callerName.trim();

    final initial = name.isEmpty
        ? '?'
        : name
              .substring(
                0,
                1,
              )
              .toUpperCase();

    return Container(
      color: _purple.withValues(
        alpha: 0.12,
      ),

      alignment: Alignment.center,

      child: Text(
        initial,

        style: const TextStyle(
          color: _purple,

          fontSize: 38,

          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ==========================================================
  // ACTION
  // ==========================================================

  Widget _buildAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Opacity(
      opacity:
          onTap ==
              null
          ? 0.45
          : 1,

      child: GestureDetector(
        onTap: onTap,

        child: Column(
          children: [
            Container(
              width: 62,

              height: 62,

              decoration: BoxDecoration(
                color: color,

                shape: BoxShape.circle,

                boxShadow: [
                  BoxShadow(
                    color: color.withValues(
                      alpha: 0.22,
                    ),

                    blurRadius: 18,
                  ),
                ],
              ),

              child: Icon(
                icon,

                color: Colors.white,

                size: 27,
              ),
            ),

            const SizedBox(
              height: 9,
            ),

            Text(
              label,

              style: const TextStyle(
                color: Colors.white60,

                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // USERNAME
  // ==========================================================

  String get _usernameLabel {
    final value = widget.callerUsername?.trim();

    if (value ==
            null ||
        value.isEmpty) {
      return '';
    }

    return '@${value.replaceFirst(RegExp(r'^@+'), '')}';
  }
}
