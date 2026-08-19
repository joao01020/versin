import 'package:flutter/material.dart';

import '../models/royalty_agreement_model.dart';

// ============================================================
// ROYALTY INTEGRITY WIDGET
// ============================================================
//
// Mostra o registro final do acordo.
//
// NÃO calcula hash.
//
// O hash já chega calculado/armazenado.
//
// ============================================================

class RoyaltyIntegrityWidget
    extends
        StatelessWidget {
  final RoyaltyAgreementModel? agreement;

  final int approvalCount;

  final int memberCount;

  final bool integrityValid;

  final VoidCallback? onCreateNewVersion;

  const RoyaltyIntegrityWidget({
    super.key,
    required this.agreement,
    required this.approvalCount,
    required this.memberCount,
    this.integrityValid = false,
    this.onCreateNewVersion,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final currentAgreement = agreement;

    if (currentAgreement ==
            null ||
        !currentAgreement.isConfirmed) {
      return _buildPending();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.green.withValues(
          alpha: 0.04,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: Colors.green.withValues(
            alpha: 0.15,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: Colors.greenAccent,
                size: 19,
              ),

              const SizedBox(
                width: 8,
              ),

              const Expanded(
                child: Text(
                  'Registro de integridade',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Icon(
                integrityValid
                    ? Icons.verified_rounded
                    : Icons.warning_amber_rounded,
                color: integrityValid
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
                size: 16,
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          _buildValue(
            label: 'VERSÃO',
            value: '${currentAgreement.version}',
          ),

          const SizedBox(
            height: 10,
          ),

          _buildValue(
            label: 'CONFIRMAÇÕES',
            value: '$approvalCount/$memberCount',
          ),

          const SizedBox(
            height: 10,
          ),

          _buildValue(
            label: 'HASH SHA-256',
            value:
                currentAgreement.integrityHash ??
                '-',
            monospace: true,
          ),

          if (currentAgreement.confirmedAt !=
              null) ...[
            const SizedBox(
              height: 10,
            ),

            _buildValue(
              label: 'CONFIRMADO EM',
              value: _formatDateTime(
                currentAgreement.confirmedAt!,
              ),
            ),
          ],

          if (onCreateNewVersion !=
              null) ...[
            const SizedBox(
              height: 14,
            ),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCreateNewVersion,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white60,
                  side: BorderSide(
                    color: Colors.white.withValues(
                      alpha: 0.08,
                    ),
                  ),
                ),
                icon: const Icon(
                  Icons.history_rounded,
                  size: 16,
                ),
                label: const Text(
                  'PROPOR NOVA DIVISÃO',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // PENDING
  // ============================================================

  Widget _buildPending() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.02,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.lock_open_outlined,
            color: Colors.white30,
            size: 18,
          ),

          SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              'O registro de integridade será criado quando todos confirmarem o acordo.',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VALUE
  // ============================================================

  Widget _buildValue({
    required String label,
    required String value,
    bool monospace = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white24,
            fontSize: 7,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),

        const SizedBox(
          height: 4,
        ),

        SelectableText(
          value,
          style: TextStyle(
            color: Colors.white60,
            fontSize: 10,
            fontFamily: monospace
                ? 'monospace'
                : null,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDateTime(
    DateTime value,
  ) {
    final local = value.toLocal();

    final day = local.day.toString().padLeft(
      2,
      '0',
    );

    final month = local.month.toString().padLeft(
      2,
      '0',
    );

    final hour = local.hour.toString().padLeft(
      2,
      '0',
    );

    final minute = local.minute.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month/${local.year} • $hour:$minute';
  }
}
