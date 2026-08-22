import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
// CHAT AI GUIDE MODAL
// ============================================================
//
// Guia de uso da IA.
//
// Permite:
//
// - ensinar o usuário a formular pedidos;
// - navegar por categorias;
// - copiar qualquer exemplo;
// - usar um exemplo diretamente no campo do Chat;
// - NÃO enviar automaticamente.
//
// ============================================================

class ChatAiGuideModal {
  // ============================================================
  // CORES
  // ============================================================

  static const Color _background = Color(
    0xFF0D0B1F,
  );

  static const Color _surface = Color(
    0xFF17132D,
  );

  static const Color _surfaceSecondary = Color(
    0xFF1B1635,
  );

  static const Color _accent = Color(
    0xFFE040FB,
  );

  // ============================================================
  // SHOW
  // ============================================================

  static Future<
    void
  >
  show({
    required BuildContext context,
    required ValueChanged<
      String
    >
    onUseExample,
  }) async {
    final selectedExample =
        await showModalBottomSheet<
          String
        >(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black.withValues(
            alpha: 0.72,
          ),
          builder:
              (
                context,
              ) {
                return const _ChatAiGuideContent();
              },
        );

    if (selectedExample ==
            null ||
        selectedExample.trim().isEmpty) {
      return;
    }

    onUseExample(
      selectedExample.trim(),
    );
  }
}

// ============================================================
// GUIDE CONTENT
// ============================================================

class _ChatAiGuideContent
    extends
        StatefulWidget {
  const _ChatAiGuideContent();

  @override
  State<
    _ChatAiGuideContent
  >
  createState() {
    return _ChatAiGuideContentState();
  }
}

// ============================================================
// GUIDE CONTENT STATE
// ============================================================

class _ChatAiGuideContentState
    extends
        State<
          _ChatAiGuideContent
        > {
  // ============================================================
  // STATE
  // ============================================================

  _AiGuideCategory? _selectedCategory;

  String? _copiedExample;

  // ============================================================
  // COPY
  // ============================================================

  Future<
    void
  >
  _copyExample(
    String text,
  ) async {
    await Clipboard.setData(
      ClipboardData(
        text: text,
      ),
    );

    if (!mounted) {
      return;
    }

    setState(
      () {
        _copiedExample = text;
      },
    );

    // Mostra o check por um pequeno período.
    await Future<
      void
    >.delayed(
      const Duration(
        milliseconds: 1300,
      ),
    );

    if (!mounted) {
      return;
    }

    if (_copiedExample ==
        text) {
      setState(
        () {
          _copiedExample = null;
        },
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
    final mediaQuery = MediaQuery.of(
      context,
    );

    final maxHeight =
        mediaQuery.size.height *
        0.84;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: maxHeight,
        ),
        decoration: const BoxDecoration(
          color: ChatAiGuideModal._background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(
              24,
            ),
            topRight: Radius.circular(
              24,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 10,
            ),

            // ==================================================
            // HANDLE
            // ==================================================
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.14,
                ),
                borderRadius: BorderRadius.circular(
                  20,
                ),
              ),
            ),

            // ==================================================
            // HEADER
            // ==================================================
            _buildHeader(
              context,
            ),

            Divider(
              height: 1,
              color: Colors.white.withValues(
                alpha: 0.06,
              ),
            ),

            // ==================================================
            // CONTENT
            // ==================================================
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(
                  milliseconds: 180,
                ),
                child:
                    _selectedCategory ==
                        null
                    ? _buildCategories()
                    : _buildCategoryDetails(
                        _selectedCategory!,
                      ),
              ),
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
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        14,
        10,
        14,
      ),
      child: Row(
        children: [
          // ====================================================
          // BACK / ICON
          // ====================================================
          if (_selectedCategory !=
              null)
            IconButton(
              tooltip: 'Voltar',
              onPressed: () {
                setState(
                  () {
                    _selectedCategory = null;
                  },
                );
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white70,
                size: 20,
              ),
            )
          else
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ChatAiGuideModal._accent.withValues(
                  alpha: 0.10,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: ChatAiGuideModal._accent,
                size: 18,
              ),
            ),

          const SizedBox(
            width: 11,
          ),

          // ====================================================
          // TITLE
          // ====================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCategory ==
                          null
                      ? 'Como usar a IA'
                      : _selectedCategory!.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  _selectedCategory ==
                          null
                      ? 'Use a IA como uma ferramenta de composição.'
                      : _selectedCategory!.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          // ====================================================
          // CLOSE
          // ====================================================
          IconButton(
            tooltip: 'Fechar',
            onPressed: () {
              Navigator.of(
                context,
              ).pop();
            },
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white38,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  Widget _buildCategories() {
    return SingleChildScrollView(
      key: const ValueKey(
        'ai-guide-categories',
      ),
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIntroduction(),

          const SizedBox(
            height: 20,
          ),

          const Text(
            'O QUE VOCÊ QUER FAZER?',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          ..._categories.map(
            (
              category,
            ) {
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 8,
                ),
                child: _buildCategoryCard(
                  category,
                ),
              );
            },
          ),

          const SizedBox(
            height: 16,
          ),

          _buildContextTip(),
        ],
      ),
    );
  }

  // ============================================================
  // INTRODUCTION
  // ============================================================

  Widget _buildIntroduction() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        15,
      ),
      decoration: BoxDecoration(
        color: ChatAiGuideModal._accent.withValues(
          alpha: 0.055,
        ),
        borderRadius: BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: ChatAiGuideModal._accent.withValues(
            alpha: 0.14,
          ),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: ChatAiGuideModal._accent,
            size: 18,
          ),
          SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              'Em vez de conversar sem um objetivo, diga o que '
              'você está criando, o que precisa e, quando possível, '
              'envie o trecho que está trabalhando.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CATEGORY CARD
  // ============================================================

  Widget _buildCategoryCard(
    _AiGuideCategory category,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(
            () {
              _selectedCategory = category;
            },
          );
        },
        borderRadius: BorderRadius.circular(
          14,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: ChatAiGuideModal._surface,
            borderRadius: BorderRadius.circular(
              14,
            ),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.055,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ChatAiGuideModal._accent.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius: BorderRadius.circular(
                    11,
                  ),
                ),
                child: Icon(
                  category.icon,
                  color: ChatAiGuideModal._accent,
                  size: 18,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
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
                      category.description,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 9.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white24,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY DETAILS
  // ============================================================

  Widget _buildCategoryDetails(
    _AiGuideCategory category,
  ) {
    return SingleChildScrollView(
      key: ValueKey(
        'ai-guide-${category.id}',
      ),
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.tip,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              height: 1.45,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          if (category.id ==
              'library') ...[
            _buildLibraryInstructions(),

            const SizedBox(
              height: 16,
            ),
          ],

          ...category.examples.map(
            (
              example,
            ) {
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 10,
                ),
                child: _buildExampleCard(
                  example,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMO USAR A BIBLIOTECA
  // ============================================================

  Widget _buildLibraryInstructions() {
    const example = 'Me dê 10 rimas para coração.';

    final copied =
        _copiedExample ==
        example;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================================
        // DICA DE PESQUISA
        // ======================================================
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(
            14,
          ),
          decoration: BoxDecoration(
            color: ChatAiGuideModal._accent.withValues(
              alpha: 0.055,
            ),
            borderRadius: BorderRadius.circular(
              14,
            ),
            border: Border.all(
              color: ChatAiGuideModal._accent.withValues(
                alpha: 0.14,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: ChatAiGuideModal._accent,
                    size: 17,
                  ),

                  SizedBox(
                    width: 8,
                  ),

                  Text(
                    'COMO PESQUISAR RIMAS',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 10,
              ),

              const Text(
                'Ao pedir rimas, informe também a quantidade '
                'de opções que você quer receber.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10.5,
                  height: 1.45,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: 0.18,
                  ),
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: 0.05,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Text(
                        example,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10.5,
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Tooltip(
                      message: copied
                          ? 'Copiado'
                          : 'Copiar',
                      child: InkWell(
                        onTap: () {
                          _copyExample(
                            example,
                          );
                        },
                        borderRadius: BorderRadius.circular(
                          8,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(
                            6,
                          ),
                          child: Icon(
                            copied
                                ? Icons.check_rounded
                                : Icons.copy_rounded,
                            size: 14,
                            color: copied
                                ? ChatAiGuideModal._accent
                                : Colors.white38,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        // ======================================================
        // COMO SALVAR
        // ======================================================
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(
            14,
          ),
          decoration: BoxDecoration(
            color: ChatAiGuideModal._surfaceSecondary,
            borderRadius: BorderRadius.circular(
              14,
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.library_add_rounded,
                    color: ChatAiGuideModal._accent,
                    size: 17,
                  ),

                  SizedBox(
                    width: 8,
                  ),

                  Text(
                    'COMO SALVAR UMA RIMA',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),

              SizedBox(
                height: 12,
              ),

              _LibraryStep(
                number: '1',
                text: 'Selecione a palavra que você quer salvar na resposta da IA.',
              ),

              SizedBox(
                height: 9,
              ),

              _LibraryStep(
                number: '2',
                text: 'Clique com o botão direito do mouse sobre a seleção.',
              ),

              SizedBox(
                height: 9,
              ),

              _LibraryStep(
                number: '3',
                text: 'No menu que aparecer, clique em "+ Adicionar à lista".',
              ),

              SizedBox(
                height: 9,
              ),

              _LibraryStep(
                number: '4',
                text: 'A palavra será adicionada à sua biblioteca para você usar depois.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EXAMPLE CARD
  // ============================================================

  Widget _buildExampleCard(
    _AiGuideExample example,
  ) {
    final copied =
        _copiedExample ==
        example.text;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: ChatAiGuideModal._surface,
        borderRadius: BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // LABEL + COPY
          // ====================================================
          Row(
            children: [
              Expanded(
                child: Text(
                  example.label.toUpperCase(),
                  style: TextStyle(
                    color: ChatAiGuideModal._accent.withValues(
                      alpha: 0.80,
                    ),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                  ),
                ),
              ),

              // =================================================
              // COPY BUTTON
              // =================================================
              Tooltip(
                message: copied
                    ? 'Copiado'
                    : 'Copiar',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _copyExample(
                        example.text,
                      );
                    },
                    borderRadius: BorderRadius.circular(
                      9,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(
                        milliseconds: 160,
                      ),
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: copied
                            ? ChatAiGuideModal._accent.withValues(
                                alpha: 0.12,
                              )
                            : Colors.white.withValues(
                                alpha: 0.055,
                              ),
                        borderRadius: BorderRadius.circular(
                          9,
                        ),
                        border: Border.all(
                          color: copied
                              ? ChatAiGuideModal._accent.withValues(
                                  alpha: 0.25,
                                )
                              : Colors.white.withValues(
                                  alpha: 0.06,
                                ),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(
                          milliseconds: 140,
                        ),
                        child: Icon(
                          copied
                              ? Icons.check_rounded
                              : Icons.copy_rounded,
                          key: ValueKey(
                            copied,
                          ),
                          size: 15,
                          color: copied
                              ? ChatAiGuideModal._accent
                              : Colors.white60,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          // ====================================================
          // TEXT + COPY BESIDE TEXT
          // ====================================================
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SelectableText(
                  example.text,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          // ====================================================
          // ACTIONS
          // ====================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // =================================================
              // COPY TEXT ACTION
              // =================================================
              TextButton.icon(
                onPressed: () {
                  _copyExample(
                    example.text,
                  );
                },
                icon: Icon(
                  copied
                      ? Icons.check_rounded
                      : Icons.copy_rounded,
                  size: 14,
                ),
                label: Text(
                  copied
                      ? 'COPIADO'
                      : 'COPIAR',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: copied
                      ? ChatAiGuideModal._accent
                      : Colors.white54,
                  textStyle: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),

              const SizedBox(
                width: 4,
              ),

              // =================================================
              // USE
              // =================================================
              TextButton.icon(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pop(
                    example.text,
                  );
                },
                icon: const Icon(
                  Icons.north_west_rounded,
                  size: 14,
                ),
                label: const Text(
                  'USAR',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: ChatAiGuideModal._accent,
                  textStyle: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
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
  // CONTEXT TIP
  // ============================================================

  Widget _buildContextTip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: ChatAiGuideModal._surfaceSecondary,
        borderRadius: BorderRadius.circular(
          14,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: Colors.greenAccent,
                size: 16,
              ),
              SizedBox(
                width: 7,
              ),
              Text(
                'Quanto mais contexto, melhor.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          _GuideLevel(
            label: 'BÁSICO',
            text: 'Rimas para coração',
            copied:
                _copiedExample ==
                'Rimas para coração',
            onCopy: () {
              _copyExample(
                'Rimas para coração',
              );
            },
          ),

          const SizedBox(
            height: 8,
          ),

          _GuideLevel(
            label: 'MELHOR',
            text: 'Rimas para coração com clima melancólico',
            copied:
                _copiedExample ==
                'Rimas para coração com clima melancólico',
            onCopy: () {
              _copyExample(
                'Rimas para coração com clima melancólico',
              );
            },
          ),

          const SizedBox(
            height: 8,
          ),

          _GuideLevel(
            label: 'MAIS PRECISO',
            text:
                'Estou escrevendo sobre um término. '
                'Preciso de rimas para coração, mas quero '
                'evitar paixão e solidão.',
            copied:
                _copiedExample ==
                'Estou escrevendo sobre um término. '
                    'Preciso de rimas para coração, mas quero '
                    'evitar paixão e solidão.',
            onCopy: () {
              _copyExample(
                'Estou escrevendo sobre um término. '
                'Preciso de rimas para coração, mas quero '
                'evitar paixão e solidão.',
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LIBRARY STEP
// ============================================================

class _LibraryStep
    extends
        StatelessWidget {
  final String number;

  final String text;

  const _LibraryStep({
    required this.number,
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ChatAiGuideModal._accent.withValues(
              alpha: 0.10,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: ChatAiGuideModal._accent.withValues(
                alpha: 0.18,
              ),
            ),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: ChatAiGuideModal._accent,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        const SizedBox(
          width: 9,
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 3,
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// GUIDE LEVEL
// ============================================================

class _GuideLevel
    extends
        StatelessWidget {
  final String label;

  final String text;

  final bool copied;

  final VoidCallback onCopy;

  const _GuideLevel({
    required this.label,
    required this.text,
    required this.copied,
    required this.onCopy,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white30,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        Expanded(
          child: Text(
            '"$text"',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 9.5,
              height: 1.35,
            ),
          ),
        ),

        const SizedBox(
          width: 8,
        ),

        // ======================================================
        // COPY ICON
        // ======================================================
        Tooltip(
          message: copied
              ? 'Copiado'
              : 'Copiar',
          child: InkWell(
            onTap: onCopy,
            borderRadius: BorderRadius.circular(
              8,
            ),
            child: Padding(
              padding: const EdgeInsets.all(
                6,
              ),
              child: Icon(
                copied
                    ? Icons.check_rounded
                    : Icons.copy_rounded,
                size: 14,
                color: copied
                    ? ChatAiGuideModal._accent
                    : Colors.white38,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CATEGORY MODEL
// ============================================================

class _AiGuideCategory {
  final String id;

  final String title;

  final String description;

  final String tip;

  final IconData icon;

  final List<
    _AiGuideExample
  >
  examples;

  const _AiGuideCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.tip,
    required this.icon,
    required this.examples,
  });
}

// ============================================================
// EXAMPLE MODEL
// ============================================================

class _AiGuideExample {
  final String label;

  final String text;

  const _AiGuideExample({
    required this.label,
    required this.text,
  });
}

// ============================================================
// CATEGORIES
// ============================================================

const List<
  _AiGuideCategory
>
_categories = [
  // ============================================================
  // BIBLIOTECA
  // ============================================================
  _AiGuideCategory(
    id: 'library',
    title: 'Usar a biblioteca',
    description: 'Aprenda a pesquisar rimas e salvar palavras na sua lista.',
    tip:
        'Ao pesquisar rimas, informe quantas opções você quer. '
        'Depois, selecione uma palavra da resposta e use o menu do '
        'botão direito para adicioná-la à sua lista.',
    icon: Icons.library_books_outlined,
    examples: [
      _AiGuideExample(
        label: 'Quantidade definida',
        text: 'Me dê 10 rimas para coração.',
      ),
      _AiGuideExample(
        label: 'Com contexto',
        text: 'Me dê 8 rimas para coração com clima melancólico.',
      ),
      _AiGuideExample(
        label: 'Mais específico',
        text: 'Me dê 12 rimas para coração, evitando paixão e solidão.',
      ),
    ],
  ),

  // ============================================================
  // LETRA
  // ============================================================
  _AiGuideCategory(
    id: 'lyrics',
    title: 'Trabalhar uma letra',
    description: 'Continue ou desenvolva algo que você já começou.',
    tip:
        'Cole o trecho que está escrevendo e explique o que '
        'você quer preservar ou mudar.',
    icon: Icons.edit_note_rounded,
    examples: [
      _AiGuideExample(
        label: 'Continuar',
        text:
            'Continue este verso mantendo o mesmo clima:\n'
            '"Eu ando sozinho pela cidade..."',
      ),
      _AiGuideExample(
        label: 'Desenvolver',
        text:
            'Estou escrevendo uma letra sobre distância. '
            'Ajude a desenvolver este trecho sem mudar a ideia principal:\n'
            '"Eu vejo sua janela de longe..."',
      ),
      _AiGuideExample(
        label: 'Com restrição',
        text:
            'Continue este trecho em 4 linhas. '
            'Quero um tom íntimo e sem frases clichês:\n'
            '"A casa ainda guarda seu cheiro..."',
      ),
    ],
  ),

  // ============================================================
  // IDEIAS
  // ============================================================
  _AiGuideCategory(
    id: 'ideas',
    title: 'Criar ideias',
    description: 'Explore temas, cenas, histórias e direções para uma música.',
    tip:
        'Diga o tema e o tipo de sensação que você quer provocar. '
        'Você também pode pedir ideias menos óbvias.',
    icon: Icons.lightbulb_outline_rounded,
    examples: [
      _AiGuideExample(
        label: 'Básico',
        text: 'Me dê ideias para uma música sobre saudade.',
      ),
      _AiGuideExample(
        label: 'Com direção',
        text:
            'Me dê 5 ideias de músicas sobre saudade, '
            'mas sem falar diretamente de relacionamento.',
      ),
      _AiGuideExample(
        label: 'Visual',
        text:
            'Quero escrever uma música noturna e melancólica. '
            'Me dê cenas, objetos e situações que eu poderia usar '
            'para contar essa história.',
      ),
    ],
  ),

  // ============================================================
  // MELHORAR
  // ============================================================
  _AiGuideCategory(
    id: 'improve',
    title: 'Melhorar um trecho',
    description: 'Encontre novas formas de dizer a mesma coisa.',
    tip:
        'Mostre a frase original e explique o que não está '
        'funcionando para você.',
    icon: Icons.auto_fix_high_rounded,
    examples: [
      _AiGuideExample(
        label: 'Alternativas',
        text:
            'Me dê alternativas para esta frase:\n'
            '"Não consigo te esquecer."',
      ),
      _AiGuideExample(
        label: 'Preservar sentido',
        text:
            'Reescreva esta frase de 5 formas diferentes '
            'sem mudar o significado:\n'
            '"Eu ainda espero você voltar."',
      ),
      _AiGuideExample(
        label: 'Evitar clichê',
        text:
            'Quero transmitir a mesma ideia deste verso, '
            'mas de uma forma menos clichê:\n'
            '"Meu coração está partido."',
      ),
    ],
  ),

  // ============================================================
  // MÉTRICA
  // ============================================================
  _AiGuideCategory(
    id: 'metric',
    title: 'Analisar métrica',
    description: 'Trabalhe ritmo, tamanho e fluidez dos versos.',
    tip:
        'Envie o trecho completo. Se você já tiver uma melodia '
        'ou quantidade aproximada de sílabas, informe também.',
    icon: Icons.straighten_rounded,
    examples: [
      _AiGuideExample(
        label: 'Analisar',
        text:
            'Analise a métrica deste trecho e indique onde '
            'o ritmo pode ficar mais fluido:\n'
            '"Cole seu trecho aqui."',
      ),
      _AiGuideExample(
        label: 'Ajustar',
        text:
            'Ajuste a métrica destes versos sem mudar '
            'a ideia principal:\n'
            '"Cole seus versos aqui."',
      ),
      _AiGuideExample(
        label: 'Comparar',
        text:
            'Compare o tamanho e o ritmo destes versos '
            'e sugira como deixá-los mais consistentes:\n'
            '"Cole seus versos aqui."',
      ),
    ],
  ),

  // ============================================================
  // REFRÃO
  // ============================================================
  _AiGuideCategory(
    id: 'chorus',
    title: 'Criar refrão',
    description: 'Explore ideias fortes e memoráveis para o refrão.',
    tip:
        'Explique o tema da música e o sentimento que o refrão '
        'precisa concentrar. Se já existir um verso, envie-o.',
    icon: Icons.music_note_rounded,
    examples: [
      _AiGuideExample(
        label: 'Básico',
        text: 'Me dê ideias de refrão para uma música sobre despedida.',
      ),
      _AiGuideExample(
        label: 'Com clima',
        text:
            'Quero um refrão curto sobre despedida. '
            'A música é melancólica, mas não quero que pareça derrotada.',
      ),
      _AiGuideExample(
        label: 'Com contexto',
        text:
            'Este é o verso da minha música:\n'
            '"Cole seu verso aqui."\n\n'
            'Me dê 3 caminhos de refrão que mantenham '
            'a mesma história e tenham uma frase central memorável.',
      ),
    ],
  ),
];
