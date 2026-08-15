import 'package:flutter/material.dart';

// ============================================================
// VERSIN TIMELINE
// ============================================================
//
// Timeline visual das palavras/rimas salvas.
//
// Características:
//
// - limite de 12 palavras ativas;
// - todas as palavras ficam visíveis;
// - quebra automática em várias linhas;
// - campo de nova rima integrado;
// - remoção individual;
// - contador;
// - animações suaves.
//
// ============================================================

class VersinTimeline
    extends
        StatefulWidget {
  final int currentStep;

  final Color activeColor;

  final List<
    String
  >
  savedRhymes;

  final ValueChanged<
    String
  >
  onAddRhyme;

  final ValueChanged<
    String
  >
  onRemoveRhyme;

  final ValueChanged<
    String
  >?
  onTextChanged;

  const VersinTimeline({
    super.key,
    required this.currentStep,
    required this.activeColor,
    required this.savedRhymes,
    required this.onAddRhyme,
    required this.onRemoveRhyme,
    this.onTextChanged,
  });

  @override
  State<
    VersinTimeline
  >
  createState() => _VersinTimelineState();
}

// ============================================================
// STATE
// ============================================================

class _VersinTimelineState
    extends
        State<
          VersinTimeline
        > {
  final TextEditingController _inputController = TextEditingController();

  final FocusNode _inputFocusNode = FocusNode();

  bool _isSubmitting = false;

  static const int _maxActiveRhymes = 12;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _inputController.dispose();

    _inputFocusNode.dispose();

    super.dispose();
  }

  // ============================================================
  // NORMALIZAÇÃO
  // ============================================================

  String _normalize(
    String value,
  ) {
    return value.trim().toLowerCase();
  }

  // ============================================================
  // LISTA LIMPA
  // ============================================================

  List<
    String
  >
  get _rhymes {
    final unique =
        <
          String
        >{};

    final result =
        <
          String
        >[];

    for (final raw in widget.savedRhymes) {
      final word = raw.trim();

      if (word.isEmpty) {
        continue;
      }

      final normalized = _normalize(
        word,
      );

      if (unique.add(
        normalized,
      )) {
        result.add(
          word,
        );
      }
    }

    return result;
  }

  bool get _isFull =>
      _rhymes.length >=
      _maxActiveRhymes;

  // ============================================================
  // ADICIONAR
  // ============================================================

  Future<
    void
  >
  _submitRhyme() async {
    if (_isSubmitting ||
        _isFull) {
      return;
    }

    final text = _inputController.text.trim();

    if (text.isEmpty) {
      return;
    }

    final alreadyExists = _rhymes.any(
      (
        rhyme,
      ) =>
          _normalize(
            rhyme,
          ) ==
          _normalize(
            text,
          ),
    );

    if (alreadyExists) {
      _inputController.clear();

      _requestInputFocus();

      return;
    }

    setState(
      () {
        _isSubmitting = true;
      },
    );

    try {
      widget.onAddRhyme(
        text,
      );

      _inputController.clear();

      widget.onTextChanged?.call(
        '',
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _isSubmitting = false;
          },
        );

        _requestInputFocus();
      }
    }
  }

  // ============================================================
  // REMOVER
  // ============================================================

  void _removeRhyme(
    String rhyme,
  ) {
    widget.onRemoveRhyme(
      rhyme,
    );
  }

  // ============================================================
  // FOCO
  // ============================================================

  void _requestInputFocus() {
    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (!mounted) {
          return;
        }

        _inputFocusNode.requestFocus();
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final rhymes = _rhymes;

    return AnimatedSize(
      duration: const Duration(
        milliseconds: 220,
      ),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          14,
          12,
          14,
          14,
        ),
        decoration: BoxDecoration(
          color: const Color(
            0xFF121212,
          ),
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(
                alpha: 0.05,
              ),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              rhymes.length,
            ),

            const SizedBox(
              height: 10,
            ),

            _buildProgress(
              rhymes.length,
            ),

            const SizedBox(
              height: 12,
            ),

            _buildWordsArea(
              rhymes,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
    int count,
  ) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: widget.activeColor.withValues(
              alpha: 0.10,
            ),
            borderRadius: BorderRadius.circular(
              10,
            ),
            border: Border.all(
              color: widget.activeColor.withValues(
                alpha: 0.14,
              ),
            ),
          ),
          child: Icon(
            Icons.route_rounded,
            color: widget.activeColor,
            size: 18,
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Linha criativa',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),

              SizedBox(
                height: 2,
              ),

              Text(
                'Palavras da sua composição',
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.035,
            ),
            borderRadius: BorderRadius.circular(
              20,
            ),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.05,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 12,
                color: widget.activeColor.withValues(
                  alpha: 0.85,
                ),
              ),

              const SizedBox(
                width: 5,
              ),

              Text(
                '$count',
                style: TextStyle(
                  color: widget.activeColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PROGRESSO
  // ============================================================

  Widget _buildProgress(
    int count,
  ) {
    final progress =
        count ==
            0
        ? 0.0
        : (count /
                  _maxActiveRhymes)
              .clamp(
                0.0,
                1.0,
              );

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              20,
            ),
            child: SizedBox(
              height: 3,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(
                  alpha: 0.05,
                ),
                valueColor:
                    AlwaysStoppedAnimation<
                      Color
                    >(
                      widget.activeColor.withValues(
                        alpha: 0.75,
                      ),
                    ),
              ),
            ),
          ),
        ),

        const SizedBox(
          width: 9,
        ),

        Text(
          count ==
                  0
              ? '0/$_maxActiveRhymes'
              : '$count/$_maxActiveRhymes',
          style: const TextStyle(
            color: Colors.white24,
            fontSize: 8,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ÁREA DAS PALAVRAS
  // ============================================================

  Widget _buildWordsArea(
    List<
      String
    >
    rhymes,
  ) {
    return LayoutBuilder(
      builder:
          (
            context,
            constraints,
          ) {
            return Wrap(
              spacing: 7,
              runSpacing: 7,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (
                  int index = 0;
                  index <
                      rhymes.length;
                  index++
                )
                  _buildRhymeChip(
                    rhyme: rhymes[index],
                    index: index,
                  ),

                if (!_isFull)
                  _buildInputChip(
                    constraints.maxWidth,
                  )
                else
                  _buildLimitReachedChip(),
              ],
            );
          },
    );
  }

  // ============================================================
  // CHIP DA RIMA
  // ============================================================

  Widget _buildRhymeChip({
    required String rhyme,
    required int index,
  }) {
    return TweenAnimationBuilder<
      double
    >(
      key: ValueKey(
        rhyme,
      ),
      tween: Tween(
        begin: 0,
        end: 1,
      ),
      duration: Duration(
        milliseconds:
            180 +
            (index.clamp(
                  0,
                  8,
                ) *
                30),
      ),
      curve: Curves.easeOutCubic,
      builder:
          (
            context,
            value,
            child,
          ) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(
                  0,
                  5 *
                      (1 -
                          value),
                ),
                child: child,
              ),
            );
          },
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 36,
          maxWidth: 220,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(
            alpha: 0.035,
          ),
          borderRadius: BorderRadius.circular(
            12,
          ),
          border: Border.all(
            color: Colors.white.withValues(
              alpha: 0.065,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4,
              height: 20,
              margin: const EdgeInsets.only(
                left: 8,
              ),
              decoration: BoxDecoration(
                color: widget.activeColor.withValues(
                  alpha: 0.70,
                ),
                borderRadius: BorderRadius.circular(
                  10,
                ),
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            Flexible(
              child: Text(
                rhyme,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(
              width: 4,
            ),

            Tooltip(
              message: 'Remover',
              child: InkWell(
                onTap: () => _removeRhyme(
                  rhyme,
                ),
                borderRadius: BorderRadius.circular(
                  20,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(
                    7,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withValues(
                      alpha: 0.24,
                    ),
                    size: 14,
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
  // LIMITE ATINGIDO
  // ============================================================

  Widget _buildLimitReachedChip() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 36,
        maxWidth: 280,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: widget.activeColor.withValues(
          alpha: 0.055,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: widget.activeColor.withValues(
            alpha: 0.14,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 14,
            color: widget.activeColor.withValues(
              alpha: 0.75,
            ),
          ),

          const SizedBox(
            width: 7,
          ),

          const Flexible(
            child: Text(
              '12 palavras ativas. Use ou remova uma para liberar espaço.',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 9,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHIP DE ENTRADA
  // ============================================================

  Widget _buildInputChip(
    double availableWidth,
  ) {
    final inputWidth =
        availableWidth <
            300
        ? availableWidth
        : 170.0;

    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 180,
      ),
      curve: Curves.easeOutCubic,
      width: inputWidth,
      height: 36,
      padding: const EdgeInsets.only(
        left: 11,
        right: 4,
      ),
      decoration: BoxDecoration(
        color: widget.activeColor.withValues(
          alpha: 0.07,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: widget.activeColor.withValues(
            alpha: _inputFocusNode.hasFocus
                ? 0.35
                : 0.16,
          ),
        ),
        boxShadow: _inputFocusNode.hasFocus
            ? [
                BoxShadow(
                  color: widget.activeColor.withValues(
                    alpha: 0.08,
                  ),
                  blurRadius: 12,
                ),
              ]
            : const [],
      ),
      child: Row(
        children: [
          Icon(
            Icons.add_rounded,
            size: 15,
            color: widget.activeColor.withValues(
              alpha: 0.75,
            ),
          ),

          const SizedBox(
            width: 5,
          ),

          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _inputFocusNode,
              textInputAction: TextInputAction.done,
              onChanged:
                  (
                    value,
                  ) {
                    widget.onTextChanged?.call(
                      value,
                    );

                    setState(
                      () {},
                    );
                  },
              onSubmitted:
                  (
                    _,
                  ) {
                    _submitRhyme();
                  },
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: 'Nova palavra...',
                hintStyle: TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          AnimatedSwitcher(
            duration: const Duration(
              milliseconds: 150,
            ),
            child: _inputController.text.trim().isEmpty
                ? const SizedBox(
                    key: ValueKey(
                      'empty-action',
                    ),
                    width: 4,
                  )
                : Tooltip(
                    key: const ValueKey(
                      'send-action',
                    ),
                    message: 'Adicionar',
                    child: InkWell(
                      onTap: _isSubmitting
                          ? null
                          : _submitRhyme,
                      borderRadius: BorderRadius.circular(
                        20,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(
                          6,
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                width: 13,
                                height: 13,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.6,
                                  color: widget.activeColor,
                                ),
                              )
                            : Icon(
                                Icons.arrow_upward_rounded,
                                size: 15,
                                color: widget.activeColor,
                              ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
