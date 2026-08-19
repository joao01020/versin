import 'package:flutter/material.dart';

// ============================================================
// ANIMATED CHAT MESSAGE
// ============================================================
//
// Responsável exclusivamente pela animação de entrada dos itens
// exibidos no histórico do chat.
//
// Pode animar:
//
// - mensagem do usuário;
// - mensagem da IA;
// - resposta local;
// - indicador/card;
// - AiQuotaWarningCard;
// - AiQuotaExhaustedCard;
// - qualquer outro Widget inserido no chat.
//
// Este componente NÃO conhece ChatMessage e não possui regra de
// negócio.
//
// ============================================================

class AnimatedChatMessage extends StatefulWidget {
  // ============================================================
  // CONTEÚDO
  // ============================================================

  final Widget child;

  // ============================================================
  // ORIGEM
  // ============================================================
  //
  // true:
  //     mensagem do usuário entra levemente pela direita.
  //
  // false:
  //     IA, cards e mensagens do sistema entram levemente
  //     pela esquerda.
  //
  // ============================================================

  final bool isUser;

  // ============================================================
  // DURAÇÃO
  // ============================================================
  //
  // Opcional para permitir ajustes futuros sem duplicar este
  // componente.
  //
  // ============================================================

  final Duration duration;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const AnimatedChatMessage({
    super.key,
    required this.child,
    required this.isUser,
    this.duration = const Duration(milliseconds: 320),
  });

  // ============================================================
  // STATE
  // ============================================================

  @override
  State<AnimatedChatMessage> createState() {
    return _AnimatedChatMessageState();
  }
}

// ============================================================
// ANIMATED CHAT MESSAGE STATE
// ============================================================

class _AnimatedChatMessageState extends State<AnimatedChatMessage>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // CONTROLLER
  // ============================================================

  late final AnimationController _controller;

  // ============================================================
  // ANIMAÇÕES
  // ============================================================

  late Animation<double> _opacity;

  late Animation<Offset> _slide;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);

    _configureAnimations();

    _controller.forward();
  }

  // ============================================================
  // CONFIGURAR ANIMAÇÕES
  // ============================================================

  void _configureAnimations() {
    // ==========================================================
    // OPACIDADE
    // ==========================================================

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    // ==========================================================
    // DESLIZAMENTO
    // ==========================================================
    //
    // Usuário:
    //     direita → centro
    //
    // Assistente/cards:
    //     esquerda → centro
    //
    // ==========================================================

    final beginOffset = Offset(widget.isUser ? 0.08 : -0.08, 0.04);

    _slide = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  // ============================================================
  // ATUALIZAÇÃO DO WIDGET
  // ============================================================
  //
  // Normalmente isUser não muda porque cada mensagem possui uma
  // Key estável.
  //
  // Mesmo assim, tratamos essa possibilidade para manter o
  // componente consistente.
  //
  // ============================================================

  @override
  void didUpdateWidget(covariant AnimatedChatMessage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ==========================================================
    // DURAÇÃO
    // ==========================================================

    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }

    // ==========================================================
    // DIREÇÃO
    // ==========================================================

    if (oldWidget.isUser != widget.isUser) {
      _configureAnimations();
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // ==========================================================
    // ACESSIBILIDADE
    // ==========================================================
    //
    // Se o sistema solicitar redução/desativação de animações,
    // exibimos o conteúdo diretamente.
    //
    // Isso também evita animações desnecessárias em ambientes
    // onde elas estejam desabilitadas.
    //
    // ==========================================================

    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (disableAnimations) {
      return widget.child;
    }

    // ==========================================================
    // ANIMAÇÃO
    // ==========================================================

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
