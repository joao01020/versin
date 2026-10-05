import 'package:flutter/material.dart';

import '../models/royalty_agreement_model.dart';

// ============================================================
// ROYALTY AGREEMENT STATUS WIDGET
// ============================================================
//
// Mostra o status geral do acordo.
//
// Não conhece:
//
// - Supabase;
// - Controller;
// - RLS;
// - RPC.
//
// Recebe apenas dados prontos.
//
// ============================================================

class RoyaltyAgreementStatusWidget
    extends
        StatelessWidget {
  final RoyaltyAgreementModel? agreement;

  final double totalPercentage;

  final int approvedCount;

  final int memberCount;

  final bool allApproved;

  const RoyaltyAgreementStatusWidget({
    super.key,
    required this.agreement,
    required this.totalPercentage,
    required this.approvedCount,
    required this.memberCount,
    required this.allApproved,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final configuration = _resolveConfiguration();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: configuration.color.withValues(
          alpha: 0.055,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: configuration.color.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Row(
        children: [
          // ====================================================
          // ICON
          // ====================================================
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: configuration.color.withValues(
                alpha: 0.11,
              ),
              borderRadius: BorderRadius.circular(
                13,
              ),
            ),
            child: Icon(
              configuration.icon,
              color: configuration.color,
              size: 21,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          // ====================================================
          // TEXT
          // ====================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  configuration.title,
                  style: TextStyle(
                    color: configuration.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  configuration.subtitle,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          // ====================================================
          // VERSION
          // ====================================================
          if (agreement !=
              null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.04,
                ),
                borderRadius: BorderRadius.circular(
                  20,
                ),
              ),
              child: Text(
                'v${agreement!.version}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // CONFIGURATION
  // ============================================================

  _RoyaltyAgreementStatusConfiguration _resolveConfiguration() {
    final currentAgreement = agreement;

    if (currentAgreement ==
        null) {
      return const _RoyaltyAgreementStatusConfiguration(
        color: Colors.white54,
        icon: Icons.percent_rounded,
        title: 'Nenhuma divisão proposta',
        subtitle: 'Crie uma proposta para definir os royalties do projeto.',
      );
    }

    if (currentAgreement.isConfirmed) {
      return const _RoyaltyAgreementStatusConfiguration(
        color: Colors.greenAccent,
        icon: Icons.verified_rounded,
        title: 'Acordo confirmado',
        subtitle: 'A divisão foi aprovada pelos participantes e registrada.',
      );
    }

    if (currentAgreement.isSuperseded) {
      return const _RoyaltyAgreementStatusConfiguration(
        color: Colors.white38,
        icon: Icons.history_rounded,
        title: 'Acordo substituído',
        subtitle: 'Existe uma versão mais recente desta proposta.',
      );
    }

    final hasCorrectTotal =
        (totalPercentage -
                100)
            .abs() <
        0.0001;

    if (!hasCorrectTotal) {
      return const _RoyaltyAgreementStatusConfiguration(
        color: Colors.redAccent,
        icon: Icons.warning_amber_rounded,
        title: 'Divisão incompleta',
        subtitle: 'A soma das porcentagens precisa resultar em exatamente 100%.',
      );
    }

    if (!allApproved) {
      return _RoyaltyAgreementStatusConfiguration(
        color: Colors.orangeAccent,
        icon: Icons.hourglass_top_rounded,
        title: 'Aguardando confirmações',
        subtitle: '$approvedCount de $memberCount participantes confirmaram esta versão.',
      );
    }

    return const _RoyaltyAgreementStatusConfiguration(
      color: Color(
        0xFFE100FF,
      ),
      icon: Icons.handshake_outlined,
      title: 'Pronto para confirmar',
      subtitle: 'A divisão está completa e todos os participantes concordaram.',
    );
  }
}

// ============================================================
// CONFIGURATION
// ============================================================

class _RoyaltyAgreementStatusConfiguration {
  final Color color;

  final IconData icon;

  final String title;

  final String subtitle;

  const _RoyaltyAgreementStatusConfiguration({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
