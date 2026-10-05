import 'package:flutter/material.dart';

// ============================================================
// TEAM EXPANSION NOTICE
// ============================================================
//
// Aviso apresentado no topo do Match quando ele foi aberto
// através de uma Studio Session existente.
//
// Exemplo:
//
// EXPANDINDO EQUIPE
//
// Studio Session
// "Minha música"
//
// Encontre profissionais e envie convites.
//
// ============================================================

class TeamExpansionNotice
    extends
        StatelessWidget {
  // ============================================================
  // PROJECT
  // ============================================================

  final String projectTitle;

  // ============================================================
  // COLOR
  // ============================================================

  final Color accentColor;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const TeamExpansionNotice({
    super.key,
    required this.projectTitle,
    required this.accentColor,
  });

  // ============================================================
  // DISPLAY TITLE
  // ============================================================

  String get _displayTitle {
    final normalized = projectTitle.trim();

    if (normalized.isEmpty) {
      return 'Studio Session';
    }

    return normalized;
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

      padding: const EdgeInsets.all(
        14,
      ),

      decoration: BoxDecoration(
        color: accentColor.withValues(
          alpha: 0.055,
        ),

        borderRadius: BorderRadius.circular(
          16,
        ),

        border: Border.all(
          color: accentColor.withValues(
            alpha: 0.18,
          ),
        ),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          // ====================================================
          // ICON
          // ====================================================
          Container(
            width: 40,
            height: 40,

            alignment: Alignment.center,

            decoration: BoxDecoration(
              shape: BoxShape.circle,

              color: accentColor.withValues(
                alpha: 0.11,
              ),
            ),

            child: Icon(
              Icons.group_add_outlined,

              color: accentColor,

              size: 21,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          // ====================================================
          // CONTENT
          // ====================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // ==============================================
                // LABEL
                // ==============================================
                Text(
                  'EXPANDINDO EQUIPE',

                  style: TextStyle(
                    color: accentColor,

                    fontSize: 9,

                    fontWeight: FontWeight.w900,

                    letterSpacing: 1.1,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                // ==============================================
                // PROJECT TITLE
                // ==============================================
                Text(
                  _displayTitle,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: Colors.white,

                    fontSize: 13,

                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                // ==============================================
                // DESCRIPTION
                // ==============================================
                Text(
                  'Encontre profissionais e envie '
                  'convites para esta Studio Session.',

                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.48,
                    ),

                    fontSize: 9.5,

                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          // ====================================================
          // STATUS
          // ====================================================
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),

            decoration: BoxDecoration(
              color: accentColor.withValues(
                alpha: 0.08,
              ),

              borderRadius: BorderRadius.circular(
                20,
              ),
            ),

            child: Row(
              mainAxisSize: MainAxisSize.min,

              children: [
                Container(
                  width: 6,
                  height: 6,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,

                    color: accentColor,
                  ),
                ),

                const SizedBox(
                  width: 5,
                ),

                Text(
                  'ATIVO',

                  style: TextStyle(
                    color: accentColor,

                    fontSize: 8,

                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
