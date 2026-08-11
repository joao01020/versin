import 'package:flutter/material.dart';

class SongWordTimeline
    extends
        StatelessWidget {
  final List<
    String
  >
  words;

  final Color activeColor;

  final bool Function(
    String word,
  )
  isWordUsed;

  final ValueChanged<
    String
  >
  onRemoveWord;

  final VoidCallback onAddWord;

  const SongWordTimeline({
    super.key,
    required this.words,
    required this.activeColor,
    required this.isWordUsed,
    required this.onRemoveWord,
    required this.onAddWord,
  });

  // ============================================================
  // QUANTIDADE DE PALAVRAS USADAS
  // ============================================================

  int get usedWordsCount {
    return words
        .where(
          isWordUsed,
        )
        .length;
  }

  // ============================================================
  // PROGRESSO
  // ============================================================

  double get progress {
    if (words.isEmpty) {
      return 0.0;
    }

    return usedWordsCount /
        words.length;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFF111111,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =====================================================
          // HEADER
          // =====================================================
          Row(
            children: [
              const Text(
                'TIMELINE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.3,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              // =================================================
              // TOTAL DE PALAVRAS
              // =================================================
              _TimelineInfoBadge(
                icon: Icons.radio_button_checked_rounded,
                text: '${words.length}',
              ),

              if (words.isNotEmpty) ...[
                const SizedBox(
                  width: 6,
                ),

                // ===============================================
                // USADAS
                // ===============================================
                _TimelineInfoBadge(
                  icon: Icons.check_circle_outline_rounded,
                  text: '$usedWordsCount usadas',
                  color: activeColor,
                ),
              ],

              const Spacer(),

              // =================================================
              // BIBLIOTECA GLOBAL
              // =================================================
              TextButton.icon(
                onPressed: onAddWord,
                style: TextButton.styleFrom(
                  foregroundColor: activeColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
                icon: Icon(
                  Icons.library_books_outlined,
                  size: 17,
                  color: activeColor,
                ),
                label: Text(
                  'BIBLIOTECA',
                  style: TextStyle(
                    color: activeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          // =====================================================
          // PROGRESSO
          // =====================================================
          if (words.isNotEmpty) ...[
            const SizedBox(
              height: 8,
            ),

            ClipRRect(
              borderRadius: BorderRadius.circular(
                20,
              ),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 2,
                backgroundColor: Colors.white.withValues(
                  alpha: 0.05,
                ),
                valueColor:
                    AlwaysStoppedAnimation<
                      Color
                    >(
                      activeColor.withValues(
                        alpha: 0.65,
                      ),
                    ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),
          ] else
            const SizedBox(
              height: 8,
            ),

          // =====================================================
          // CONTEÚDO
          // =====================================================
          if (words.isEmpty)
            _EmptyTimeline(
              activeColor: activeColor,
              onAddWord: onAddWord,
            )
          else
            _TimelineContent(
              words: words,
              activeColor: activeColor,
              isWordUsed: isWordUsed,
              onRemoveWord: onRemoveWord,
            ),
        ],
      ),
    );
  }
}

// ============================================================
// CONTEÚDO DA TIMELINE
// ============================================================

class _TimelineContent
    extends
        StatelessWidget {
  final List<
    String
  >
  words;

  final Color activeColor;

  final bool Function(
    String word,
  )
  isWordUsed;

  final ValueChanged<
    String
  >
  onRemoveWord;

  const _TimelineContent({
    required this.words,
    required this.activeColor,
    required this.isWordUsed,
    required this.onRemoveWord,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.only(
            bottom: 4,
          ),
          child: Row(
            children: [
              for (
                int index = 0;
                index <
                    words.length;
                index++
              ) ...[
                _TimelineWordChip(
                  word: words[index],
                  used: isWordUsed(
                    words[index],
                  ),
                  activeColor: activeColor,
                  onRemove: () {
                    onRemoveWord(
                      words[index],
                    );
                  },
                ),

                if (index <
                    words.length -
                        1)
                  _TimelineConnector(
                    activeColor: activeColor,
                    active:
                        isWordUsed(
                          words[index],
                        ) &&
                        isWordUsed(
                          words[index +
                              1],
                        ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TIMELINE VAZIA
// ============================================================

class _EmptyTimeline
    extends
        StatelessWidget {
  final Color activeColor;

  final VoidCallback onAddWord;

  const _EmptyTimeline({
    required this.activeColor,
    required this.onAddWord,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 18,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: activeColor.withValues(
                  alpha: 0.06,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.timeline_rounded,
                color: activeColor.withValues(
                  alpha: 0.45,
                ),
                size: 24,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            const Text(
              'Nenhuma palavra no radar',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            const Text(
              'Escolha palavras da sua biblioteca ou crie novas para esta música.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white24,
                fontSize: 10,
                height: 1.4,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            OutlinedButton.icon(
              onPressed: onAddWord,
              style: OutlinedButton.styleFrom(
                foregroundColor: activeColor,
                side: BorderSide(
                  color: activeColor.withValues(
                    alpha: 0.25,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
              ),
              icon: Icon(
                Icons.library_books_outlined,
                size: 16,
                color: activeColor,
              ),
              label: const Text(
                'ABRIR BIBLIOTECA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CHIP DA PALAVRA
// ============================================================

class _TimelineWordChip
    extends
        StatelessWidget {
  final String word;

  final bool used;

  final Color activeColor;

  final VoidCallback onRemove;

  const _TimelineWordChip({
    required this.word,
    required this.used,
    required this.activeColor,
    required this.onRemove,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Tooltip(
      message: used
          ? '"$word" já aparece na letra'
          : '"$word" ainda não aparece na letra',
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 220,
        ),
        constraints: const BoxConstraints(
          minWidth: 92,
          maxWidth: 175,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: used
              ? activeColor.withValues(
                  alpha: 0.14,
                )
              : const Color(
                  0xFF1A1A1A,
                ),
          borderRadius: BorderRadius.circular(
            12,
          ),
          border: Border.all(
            color: used
                ? activeColor.withValues(
                    alpha: 0.55,
                  )
                : Colors.white.withValues(
                    alpha: 0.08,
                  ),
          ),
          boxShadow: used
              ? [
                  BoxShadow(
                    color: activeColor.withValues(
                      alpha: 0.10,
                    ),
                    blurRadius: 8,
                  ),
                ]
              : const [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ===============================================
            // STATUS
            // ===============================================
            AnimatedSwitcher(
              duration: const Duration(
                milliseconds: 180,
              ),
              child: used
                  ? Icon(
                      Icons.check_circle_rounded,
                      key: const ValueKey(
                        'used',
                      ),
                      size: 14,
                      color: activeColor,
                    )
                  : const Icon(
                      Icons.radio_button_unchecked_rounded,
                      key: ValueKey(
                        'unused',
                      ),
                      size: 14,
                      color: Colors.white24,
                    ),
            ),

            const SizedBox(
              width: 7,
            ),

            // ===============================================
            // PALAVRA
            // ===============================================
            Flexible(
              child: Text(
                word,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: used
                      ? Colors.white
                      : Colors.white70,
                  fontSize: 12,
                  fontWeight: used
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),

            const SizedBox(
              width: 6,
            ),

            // ===============================================
            // REMOVER
            // ===============================================
            Tooltip(
              message: 'Remover da música',
              child: InkWell(
                borderRadius: BorderRadius.circular(
                  20,
                ),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(
                    2,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: Colors.white24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CONECTOR ENTRE PALAVRAS
// ============================================================

class _TimelineConnector
    extends
        StatelessWidget {
  final Color activeColor;

  final bool active;

  const _TimelineConnector({
    required this.activeColor,
    required this.active,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 220,
      ),
      width: 28,
      height: 2,
      margin: const EdgeInsets.symmetric(
        horizontal: 6,
      ),
      decoration: BoxDecoration(
        color: active
            ? activeColor.withValues(
                alpha: 0.55,
              )
            : Colors.white.withValues(
                alpha: 0.08,
              ),
        borderRadius: BorderRadius.circular(
          2,
        ),
      ),
    );
  }
}

// ============================================================
// INFORMAÇÃO DO HEADER
// ============================================================

class _TimelineInfoBadge
    extends
        StatelessWidget {
  final IconData icon;

  final String text;

  final Color? color;

  const _TimelineInfoBadge({
    required this.icon,
    required this.text,
    this.color,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final resolvedColor =
        color ??
        Colors.white38;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: resolvedColor.withValues(
          alpha: 0.06,
        ),
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: resolvedColor.withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: resolvedColor,
          ),

          const SizedBox(
            width: 4,
          ),

          Text(
            text,
            style: TextStyle(
              color: resolvedColor,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
