import 'package:flutter/material.dart';

// ============================================================
// CONTRIBUTION APPROVAL WIDGET
// ============================================================
//
// Exibe o estado de aprovação coletiva de uma contribuição.
//
// Este widget NÃO:
//
// - acessa Supabase;
// - altera contribuição;
// - decide quem pode aprovar.
//
// Apenas recebe:
//
// - quantidade de membros;
// - quantidade de aprovações;
// - estado do usuário atual;
// - callback.
//
// ============================================================

class ContributionApprovalWidget
    extends
        StatelessWidget {
  final int approvedCount;

  final int requiredCount;

  final bool currentUserApproved;

  final bool canApprove;

  final bool isLoading;

  final VoidCallback? onApprove;

  const ContributionApprovalWidget({
    super.key,
    required this.approvedCount,
    required this.requiredCount,
    this.currentUserApproved = false,
    this.canApprove = true,
    this.isLoading = false,
    this.onApprove,
  });

  // ============================================================
  // HELPERS
  // ============================================================

  bool get _isFullyApproved {
    return requiredCount >
            0 &&
        approvedCount >=
            requiredCount;
  }

  double get _progress {
    if (requiredCount <=
        0) {
      return 0;
    }

    return (approvedCount /
            requiredCount)
        .clamp(
          0.0,
          1.0,
        )
        .toDouble();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFF171717,
        ),
        borderRadius: BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: _isFullyApproved
              ? Colors.greenAccent.withValues(
                  alpha: 0.25,
                )
              : Colors.white.withValues(
                  alpha: 0.07,
                ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // HEADER
          // ====================================================
          Row(
            children: [
              Icon(
                _isFullyApproved
                    ? Icons.verified_outlined
                    : Icons.how_to_vote_outlined,
                size: 18,
                color: _isFullyApproved
                    ? Colors.greenAccent
                    : const Color(
                        0xFFE100FF,
                      ),
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child: Text(
                  _isFullyApproved
                      ? 'Contribuição aprovada'
                      : 'Validação da equipe',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              Text(
                '$approvedCount/$requiredCount',
                style: TextStyle(
                  color: _isFullyApproved
                      ? Colors.greenAccent
                      : Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          // ====================================================
          // PROGRESS
          // ====================================================
          ClipRRect(
            borderRadius: BorderRadius.circular(
              20,
            ),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(
                alpha: 0.08,
              ),
              valueColor:
                  AlwaysStoppedAnimation<
                    Color
                  >(
                    _isFullyApproved
                        ? Colors.greenAccent
                        : const Color(
                            0xFFE100FF,
                          ),
                  ),
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          // ====================================================
          // DESCRIPTION
          // ====================================================
          Text(
            _buildDescription(),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              height: 1.4,
            ),
          ),

          // ====================================================
          // ACTION
          // ====================================================
          if (!_isFullyApproved) ...[
            const SizedBox(
              height: 12,
            ),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: _buildActionButton(),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // DESCRIPTION
  // ============================================================

  String _buildDescription() {
    if (_isFullyApproved) {
      return 'Todos os participantes confirmaram esta contribuição.';
    }

    if (currentUserApproved) {
      return 'Você confirmou. Aguardando os demais participantes.';
    }

    if (requiredCount <=
        0) {
      return 'Aguardando participantes para iniciar a validação.';
    }

    return 'Confirme que esta responsabilidade representa o combinado pela equipe.';
  }

  // ============================================================
  // BUTTON
  // ============================================================

  Widget _buildActionButton() {
    if (isLoading) {
      return const OutlinedButton(
        onPressed: null,
        child: SizedBox(
          width: 17,
          height: 17,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (currentUserApproved) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(
          Icons.check,
          size: 16,
        ),
        label: const Text(
          'Você confirmou',
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: canApprove
          ? onApprove
          : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(
          0xFFE100FF,
        ),
        side: BorderSide(
          color:
              const Color(
                0xFFE100FF,
              ).withValues(
                alpha: 0.45,
              ),
        ),
      ),
      icon: const Icon(
        Icons.check_circle_outline,
        size: 17,
      ),
      label: const Text(
        'Confirmar contribuição',
        style: TextStyle(
          fontSize: 12,
        ),
      ),
    );
  }
}
