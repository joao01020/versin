import 'package:flutter/material.dart';

import '../data/models/stored_work_model.dart';

// ============================================================
// STORAGE ITEM CARD
// ============================================================
//
// Representa visualmente uma obra armazenada.
//
// Pode representar:
//
// - letra;
// - beat.
//
// ============================================================

class StorageItemCard
    extends
        StatelessWidget {
  final StoredWorkModel work;

  final Color accentColor;

  final VoidCallback? onTap;

  final VoidCallback? onMorePressed;

  const StorageItemCard({
    super.key,
    required this.work,
    required this.accentColor,
    this.onTap,
    this.onMorePressed,
  });

  // ==========================================================
  // TIPO
  // ==========================================================

  bool get _isLyrics =>
      work.type ==
      StoredWorkType.lyrics;

  // ==========================================================
  // ÍCONE
  // ==========================================================

  IconData get _icon {
    if (_isLyrics) {
      return Icons.description_outlined;
    }

    return Icons.graphic_eq_rounded;
  }

  // ==========================================================
  // NOME DO TIPO
  // ==========================================================

  String get _typeName {
    if (_isLyrics) {
      return 'LETRA';
    }

    return 'BEAT';
  }

  // ==========================================================
  // HASH CURTO
  // ==========================================================

  String get _shortHash {
    final hash = work.contentHash.trim();

    if (hash.isEmpty) {
      return 'Hash indisponível';
    }

    if (hash.length <=
        16) {
      return hash;
    }

    return '${hash.substring(0, 8)}...'
        '${hash.substring(hash.length - 6)}';
  }

  // ==========================================================
  // DATA
  // ==========================================================

  String get _formattedDate {
    final date = work.createdAt.toLocal();

    final day = date.day.toString().padLeft(
      2,
      '0',
    );

    final month = date.month.toString().padLeft(
      2,
      '0',
    );

    final year = date.year.toString();

    return '$day/$month/$year';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          18,
        ),
        child: Container(
          padding: const EdgeInsets.all(
            16,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.045,
            ),
            borderRadius: BorderRadius.circular(
              18,
            ),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.07,
              ),
            ),
          ),
          child: Row(
            children: [
              // =================================================
              // ÍCONE
              // =================================================
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accentColor.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                  border: Border.all(
                    color: accentColor.withValues(
                      alpha: 0.16,
                    ),
                  ),
                ),
                child: Icon(
                  _icon,
                  color: accentColor,
                  size: 25,
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              // =================================================
              // INFORMAÇÕES
              // =================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =============================================
                    // TIPO + INTEGRIDADE
                    // =============================================
                    Row(
                      children: [
                        Text(
                          _typeName,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),

                        if (work.integrityVerified) ...[
                          const SizedBox(
                            width: 8,
                          ),
                          const Icon(
                            Icons.verified_rounded,
                            color: Colors.greenAccent,
                            size: 14,
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    // =============================================
                    // TÍTULO
                    // =============================================
                    Text(
                      work.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    // =============================================
                    // HASH
                    // =============================================
                    Row(
                      children: [
                        Icon(
                          Icons.fingerprint_rounded,
                          color: Colors.white.withValues(
                            alpha: 0.30,
                          ),
                          size: 14,
                        ),

                        const SizedBox(
                          width: 5,
                        ),

                        Flexible(
                          child: Text(
                            _shortHash,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(
                                alpha: 0.35,
                              ),
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              // =================================================
              // DATA + MENU
              // =================================================
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formattedDate,
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.32,
                      ),
                      fontSize: 10,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  IconButton(
                    onPressed: onMorePressed,
                    tooltip: 'Opções',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white.withValues(
                        alpha: 0.40,
                      ),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
