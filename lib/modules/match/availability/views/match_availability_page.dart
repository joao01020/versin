import 'package:flutter/material.dart';

import '../controllers/match_availability_controller.dart';
import '../services/match_availability_service.dart';
import '../widgets/match_availability_duration_sheet.dart';

// ============================================================
// MATCH AVAILABILITY PAGE
// ============================================================
//
// Página dedicada à feature:
//
// "Disponíveis agora"
//
// Responsável somente por:
//
// - apresentar o estado;
// - observar o controller;
// - solicitar ativação;
// - solicitar encerramento;
// - abrir seletor de duração.
//
// NÃO:
//
// - acessa Supabase;
// - controla Timer;
// - calcula expiração;
// - persiste disponibilidade.
//
// ============================================================

class MatchAvailabilityPage
    extends
        StatefulWidget {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final MatchAvailabilityController controller;

  // ============================================================
  // ACCENT COLOR
  // ============================================================

  final Color accentColor;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const MatchAvailabilityPage({
    super.key,
    required this.controller,
    this.accentColor = const Color(
      0xFF8B5CF6,
    ),
  });

  // ============================================================
  // CREATE STATE
  // ============================================================

  @override
  State<
    MatchAvailabilityPage
  >
  createState() {
    return _MatchAvailabilityPageState();
  }
}

// ============================================================
// STATE
// ============================================================

class _MatchAvailabilityPageState
    extends
        State<
          MatchAvailabilityPage
        > {
  // ============================================================
  // GETTERS
  // ============================================================

  MatchAvailabilityController get _controller {
    return widget.controller;
  }

  Color get _accentColor {
    return widget.accentColor;
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _controller.addListener(
      _handleControllerChanged,
    );

    if (!_controller.isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback(
        (
          _,
        ) {
          if (!mounted) {
            return;
          }

          _initialize();
        },
      );
    }
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<
    void
  >
  _initialize() async {
    try {
      await _controller.initialize();
    } catch (
      _
    ) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Não foi possível carregar sua disponibilidade.',
        isError: true,
      );
    }
  }

  // ============================================================
  // CONTROLLER CHANGED
  // ============================================================

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ============================================================
  // ACTIVATE
  // ============================================================

  Future<
    void
  >
  _activateAvailability() async {
    if (_controller.isLoading) {
      return;
    }

    final minutes = await MatchAvailabilityDurationSheet.show(
      context: context,
      accentColor: _accentColor,
    );

    if (!mounted ||
        minutes ==
            null) {
      return;
    }

    final success = await _controller.activate(
      minutes: minutes,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(
        'Não foi possível ativar sua disponibilidade.',
        isError: true,
      );

      return;
    }

    _showMessage(
      'Disponível agora por '
      '${_controller.durationLabel(minutes)}.',
    );
  }

  // ============================================================
  // CLEAR
  // ============================================================

  Future<
    void
  >
  _clearAvailability() async {
    if (_controller.isLoading) {
      return;
    }

    final success = await _controller.clear();

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(
        'Não foi possível encerrar sua disponibilidade.',
        isError: true,
      );

      return;
    }

    _showMessage(
      'Disponibilidade encerrada.',
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
        context,
      )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,

          backgroundColor: isError
              ? Colors.red.shade900
              : const Color(
                  0xFF4C1D95,
                ),

          content: Text(
            message,
          ),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final state = _controller.state;

    return Scaffold(
      backgroundColor: const Color(
        0xFF0D0B1F,
      ),

      appBar: AppBar(
        backgroundColor: const Color(
          0xFF0D0B1F,
        ),

        surfaceTintColor: Colors.transparent,

        foregroundColor: Colors.white,

        elevation: 0,

        title: const Text(
          'Disponíveis agora',

          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _controller.refresh,

          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),

            padding: const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              30,
            ),

            children: [
              // ==================================================
              // HEADER
              // ==================================================
              _buildHeader(),

              const SizedBox(
                height: 24,
              ),

              // ==================================================
              // STATUS
              // ==================================================
              _buildStatusCard(
                state.isActive,
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // INFO
              // ==================================================
              _buildInfoCard(),

              const SizedBox(
                height: 24,
              ),

              // ==================================================
              // ACTION
              // ==================================================
              if (state.isActive) _buildClearButton() else _buildActivateButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,

              alignment: Alignment.center,

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                color: _accentColor.withValues(
                  alpha: 0.10,
                ),
              ),

              child: Icon(
                Icons.bolt_rounded,
                color: _accentColor,
                size: 26,
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    'Disponíveis agora',

                    style: TextStyle(
                      color: Colors.white,

                      fontSize: 20,

                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  SizedBox(
                    height: 4,
                  ),

                  Text(
                    'Apareça para profissionais '
                    'que estão procurando suas habilidades.',

                    style: TextStyle(
                      color: Colors.white54,

                      fontSize: 11,

                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // STATUS CARD
  // ============================================================

  Widget _buildStatusCard(
    bool active,
  ) {
    final state = _controller.state;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        18,
      ),

      decoration: BoxDecoration(
        color: _accentColor.withValues(
          alpha: active
              ? 0.10
              : 0.04,
        ),

        borderRadius: BorderRadius.circular(
          18,
        ),

        border: Border.all(
          color: _accentColor.withValues(
            alpha: active
                ? 0.30
                : 0.12,
          ),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,

                decoration: BoxDecoration(
                  shape: BoxShape.circle,

                  color: active
                      ? _accentColor
                      : Colors.white24,
                ),
              ),

              const SizedBox(
                width: 9,
              ),

              Text(
                active
                    ? 'ATIVO'
                    : 'INATIVO',

                style: TextStyle(
                  color: active
                      ? _accentColor
                      : Colors.white38,

                  fontSize: 10,

                  fontWeight: FontWeight.w900,

                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          Text(
            active
                ? 'Você está disponível agora'
                : 'Sua disponibilidade está desativada',

            style: const TextStyle(
              color: Colors.white,

              fontSize: 15,

              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            active
                ? state.remainingLabel
                : 'Ative por 30 minutos, 1 hora ou 2 horas.',

            style: const TextStyle(
              color: Colors.white54,

              fontSize: 11,

              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO CARD
  // ============================================================

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(
        16,
      ),

      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.025,
        ),

        borderRadius: BorderRadius.circular(
          16,
        ),

        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.06,
          ),
        ),
      ),

      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(
            Icons.info_outline_rounded,

            color: Colors.white38,

            size: 18,
          ),

          SizedBox(
            width: 11,
          ),

          Expanded(
            child: Text(
              'Enquanto estiver ativo, seu perfil poderá '
              'receber prioridade nas conexões rápidas. '
              'A disponibilidade termina automaticamente '
              'quando o período escolhido acabar.',

              style: TextStyle(
                color: Colors.white54,

                fontSize: 10.5,

                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIVATE BUTTON
  // ============================================================

  Widget _buildActivateButton() {
    return SizedBox(
      width: double.infinity,

      height: 50,

      child: FilledButton.icon(
        onPressed: _controller.isLoading
            ? null
            : _activateAvailability,

        style: FilledButton.styleFrom(
          backgroundColor: _accentColor,

          foregroundColor: Colors.black,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              14,
            ),
          ),
        ),

        icon: _controller.isLoading
            ? const SizedBox(
                width: 17,
                height: 17,

                child: CircularProgressIndicator(
                  strokeWidth: 2,

                  color: Colors.black,
                ),
              )
            : const Icon(
                Icons.bolt_rounded,
                size: 19,
              ),

        label: const Text(
          'ATIVAR DISPONIBILIDADE',

          style: TextStyle(
            fontSize: 11,

            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CLEAR BUTTON
  // ============================================================

  Widget _buildClearButton() {
    return SizedBox(
      width: double.infinity,

      height: 50,

      child: OutlinedButton.icon(
        onPressed: _controller.isLoading
            ? null
            : _clearAvailability,

        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,

          side: BorderSide(
            color: Colors.white.withValues(
              alpha: 0.12,
            ),
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              14,
            ),
          ),
        ),

        icon: _controller.isLoading
            ? const SizedBox(
                width: 17,
                height: 17,

                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons.stop_circle_outlined,
                size: 18,
              ),

        label: const Text(
          'ENCERRAR DISPONIBILIDADE',

          style: TextStyle(
            fontSize: 10,

            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _controller.removeListener(
      _handleControllerChanged,
    );

    // IMPORTANTE:
    //
    // Não fazemos:
    //
    // _controller.dispose();
    //
    // aqui porque a página não necessariamente é dona
    // do controller. Ele pode ter sido criado pela MatchPage
    // ou pelo service locator.

    super.dispose();
  }
}
