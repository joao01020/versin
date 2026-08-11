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

              Text(
                '${words.length} palavra${words.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Colors.white30,
                  fontSize: 10,
                ),
              ),

              const Spacer(),

              TextButton.icon(
                onPressed: onAddWord,
                icon: Icon(
                  Icons.add_rounded,
                  size: 17,
                  color: activeColor,
                ),
                label: Text(
                  'ADICIONAR',
                  style: TextStyle(
                    color: activeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
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
        ],
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
            Icon(
              Icons.timeline_rounded,
              color: activeColor.withValues(
                alpha: 0.35,
              ),
              size: 26,
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Nenhuma palavra no radar ainda',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            const Text(
              'Adicione palavras que você quer explorar nesta música.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white24,
                fontSize: 10,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            TextButton(
              onPressed: onAddWord,
              child: Text(
                'ADICIONAR PRIMEIRA PALAVRA',
                style: TextStyle(
                  color: activeColor,
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
    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 220,
      ),
      constraints: const BoxConstraints(
        minWidth: 84,
        maxWidth: 150,
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
          // =================================================
          // STATUS
          // =================================================
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
                : Icon(
                    Icons.radio_button_unchecked_rounded,
                    key: const ValueKey(
                      'unused',
                    ),
                    size: 14,
                    color: Colors.white24,
                  ),
          ),

          const SizedBox(
            width: 7,
          ),

          // =================================================
          // PALAVRA
          // =================================================
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

          // =================================================
          // REMOVER
          // =================================================
          InkWell(
            borderRadius: BorderRadius.circular(
              20,
            ),
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(
                2,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 13,
                color: Colors.white24,
              ),
            ),
          ),
        ],
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
    return Container(
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
