import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../models/royalty_agreement_model.dart';
import '../../models/royalty_share_model.dart';

// ============================================================
// ROYALTY INTEGRITY SERVICE
// ============================================================
//
// Serviço local de verificação da integridade de um acordo.
//
// IMPORTANTE:
//
// O HASH OFICIAL é criado no PostgreSQL pela RPC:
//
// approve_royalty_agreement(...)
//
// quando o último participante confirma.
//
// Este serviço NÃO cria a verdade oficial.
//
// Ele reproduz localmente EXATAMENTE a mesma representação
// utilizada pelo PostgreSQL para permitir:
//
// hash salvo no banco
//        ↓
// recalcular localmente
//        ↓
// comparar
//        ↓
// verificar integridade
//
// ============================================================
//
// FORMATO OFICIAL:
//
// versin.royalty-agreement.v1
// |project=<PROJECT_ID>
// |agreement=<AGREEMENT_ID>
// |version=<VERSION>
// |shares=
// <USER_ID>:<PERCENTAGE>:<ROLE>:<DISPLAY_NAME>
// |
// <USER_ID>:<PERCENTAGE>:<ROLE>:<DISPLAY_NAME>
//
// Os shares são ordenados por:
//
// user_id ASC
//
// A porcentagem é sempre representada com 2 casas:
//
// 30      → 30.00
// 25.5    → 25.50
// 33.33   → 33.33
//
// null em role/name:
//
// ''
//
// ============================================================

class RoyaltyIntegrityService {
  const RoyaltyIntegrityService();

  // ============================================================
  // SCHEMA VERSION
  // ============================================================

  static const String schemaVersion = 'versin.royalty-agreement.v1';

  // ============================================================
  // HASH TEXT
  // ============================================================
  //
  // SHA-256 de UTF-8.
  //
  // Equivalente ao PostgreSQL:
  //
  // encode(
  //   digest(
  //     convert_to(value, 'UTF8'),
  //     'sha256'
  //   ),
  //   'hex'
  // )
  //
  // ============================================================

  String hashText(
    String value,
  ) {
    return sha256
        .convert(
          utf8.encode(
            value,
          ),
        )
        .toString();
  }

  // ============================================================
  // CREATE AGREEMENT HASH
  // ============================================================
  //
  // Reproduz o hash oficial calculado pelo PostgreSQL.
  //
  // ============================================================

  String createAgreementHash({
    required RoyaltyAgreementModel agreement,
    required List<
      RoyaltyShareModel
    >
    shares,
  }) {
    final canonicalSource = createAgreementCanonicalSource(
      agreement: agreement,
      shares: shares,
    );

    return hashText(
      canonicalSource,
    );
  }

  // ============================================================
  // CREATE AGREEMENT CANONICAL SOURCE
  // ============================================================
  //
  // ESTA FUNÇÃO PRECISA PERMANECER SINCRONIZADA COM:
  //
  // approve_royalty_agreement(...)
  //
  // no PostgreSQL.
  //
  // Qualquer alteração neste formato exige alteração equivalente
  // na RPC.
  //
  // ============================================================

  String createAgreementCanonicalSource({
    required RoyaltyAgreementModel agreement,
    required List<
      RoyaltyShareModel
    >
    shares,
  }) {
    final normalizedProjectId = agreement.projectId.trim();

    final normalizedAgreementId = agreement.id.trim();

    // ==========================================================
    // VALIDATION
    // ==========================================================

    if (normalizedProjectId.isEmpty) {
      throw ArgumentError(
        'projectId não pode ficar vazio.',
      );
    }

    if (normalizedAgreementId.isEmpty) {
      throw ArgumentError(
        'agreementId não pode ficar vazio.',
      );
    }

    if (agreement.version <=
        0) {
      throw ArgumentError(
        'A versão do acordo precisa ser maior que zero.',
      );
    }

    if (shares.isEmpty) {
      throw ArgumentError(
        'O acordo precisa possuir participações.',
      );
    }

    // ==========================================================
    // SORT
    // ==========================================================

    final sortedShares =
        List<
            RoyaltyShareModel
          >.from(
            shares,
          )
          ..sort(
            (
              a,
              b,
            ) {
              return a.userId.trim().compareTo(
                b.userId.trim(),
              );
            },
          );

    // ==========================================================
    // SHARES SOURCE
    // ==========================================================

    final shareSources =
        <
          String
        >[];

    final seenUsers =
        <
          String
        >{};

    for (final share in sortedShares) {
      final userId = share.userId.trim();

      if (userId.isEmpty) {
        throw ArgumentError(
          'Existe uma participação sem userId.',
        );
      }

      if (!seenUsers.add(
        userId,
      )) {
        throw ArgumentError(
          'Existe um participante duplicado no acordo.',
        );
      }

      if (share.percentage <
              0 ||
          share.percentage >
              100) {
        throw ArgumentError(
          'Porcentagem inválida para o usuário $userId.',
        );
      }

      shareSources.add(
        _createShareCanonicalSource(
          share,
        ),
      );
    }

    // ==========================================================
    // FINAL SOURCE
    // ==========================================================
    //
    // Igual ao SQL:
    //
    // concat(
    //   'versin.royalty-agreement.v1',
    //   '|project=', project_id,
    //   '|agreement=', agreement_id,
    //   '|version=', version,
    //   '|shares=',
    //   string_agg(..., '|')
    // )
    //
    // ==========================================================

    return '$schemaVersion'
        '|project=$normalizedProjectId'
        '|agreement=$normalizedAgreementId'
        '|version=${agreement.version}'
        '|shares=${shareSources.join('|')}';
  }

  // ============================================================
  // SHARE CANONICAL SOURCE
  // ============================================================

  String _createShareCanonicalSource(
    RoyaltyShareModel share,
  ) {
    final userId = share.userId.trim();

    final percentage = _formatPercentageForHash(
      share.percentage,
    );

    final role = _normalizeSnapshotText(
      share.roleSnapshot,
    );

    final displayName = _normalizeSnapshotText(
      share.displayNameSnapshot,
    );

    return '$userId'
        ':$percentage'
        ':$role'
        ':$displayName';
  }

  // ============================================================
  // VERIFY AGREEMENT
  // ============================================================

  bool verifyAgreement({
    required RoyaltyAgreementModel agreement,
    required List<
      RoyaltyShareModel
    >
    shares,
    required String expectedHash,
  }) {
    final normalizedExpectedHash = expectedHash.trim().toLowerCase();

    if (normalizedExpectedHash.isEmpty) {
      return false;
    }

    try {
      final actualHash = createAgreementHash(
        agreement: agreement,
        shares: shares,
      ).toLowerCase();

      return actualHash ==
          normalizedExpectedHash;
    } catch (
      _
    ) {
      return false;
    }
  }

  // ============================================================
  // VERIFY STORED AGREEMENT
  // ============================================================
  //
  // Compara:
  //
  // agreement.integrityHash
  //
  // com:
  //
  // SHA-256 recalculado localmente.
  //
  // ============================================================

  bool verifyStoredAgreement({
    required RoyaltyAgreementModel agreement,
    required List<
      RoyaltyShareModel
    >
    shares,
  }) {
    final storedHash = agreement.integrityHash?.trim();

    if (storedHash ==
            null ||
        storedHash.isEmpty) {
      return false;
    }

    if (!agreement.isConfirmed) {
      return false;
    }

    return verifyAgreement(
      agreement: agreement,
      shares: shares,
      expectedHash: storedHash,
    );
  }

  // ============================================================
  // SAFE VERIFY STORED AGREEMENT
  // ============================================================
  //
  // Variante que nunca lança erro.
  //
  // Útil diretamente na UI.
  //
  // ============================================================

  bool safeVerifyStoredAgreement({
    required RoyaltyAgreementModel? agreement,
    required List<
      RoyaltyShareModel
    >
    shares,
  }) {
    if (agreement ==
        null) {
      return false;
    }

    try {
      return verifyStoredAgreement(
        agreement: agreement,
        shares: shares,
      );
    } catch (
      _
    ) {
      return false;
    }
  }

  // ============================================================
  // TOTAL PERCENTAGE
  // ============================================================

  double totalPercentage(
    List<
      RoyaltyShareModel
    >
    shares,
  ) {
    return shares.fold<
      double
    >(
      0,
      (
        total,
        share,
      ) {
        return total +
            share.percentage;
      },
    );
  }

  // ============================================================
  // VALID TOTAL
  // ============================================================

  bool hasValidTotal(
    List<
      RoyaltyShareModel
    >
    shares,
  ) {
    if (shares.isEmpty) {
      return false;
    }

    return (totalPercentage(
                  shares,
                ) -
                100)
            .abs() <
        0.0001;
  }

  // ============================================================
  // HAS UNIQUE USERS
  // ============================================================

  bool hasUniqueUsers(
    List<
      RoyaltyShareModel
    >
    shares,
  ) {
    final users =
        <
          String
        >{};

    for (final share in shares) {
      final userId = share.userId.trim();

      if (userId.isEmpty) {
        return false;
      }

      if (!users.add(
        userId,
      )) {
        return false;
      }
    }

    return true;
  }

  // ============================================================
  // IS SNAPSHOT VALID
  // ============================================================

  bool isSnapshotValid({
    required RoyaltyAgreementModel agreement,
    required List<
      RoyaltyShareModel
    >
    shares,
  }) {
    if (agreement.id.trim().isEmpty ||
        agreement.projectId.trim().isEmpty ||
        agreement.version <=
            0 ||
        shares.isEmpty) {
      return false;
    }

    if (!hasValidTotal(
      shares,
    )) {
      return false;
    }

    if (!hasUniqueUsers(
      shares,
    )) {
      return false;
    }

    for (final share in shares) {
      if (share.percentage <
              0 ||
          share.percentage >
              100) {
        return false;
      }
    }

    return true;
  }

  // ============================================================
  // SHORT HASH
  // ============================================================

  String shortHash(
    String? hash, {
    int sideLength = 8,
  }) {
    final normalized =
        hash?.trim() ??
        '';

    if (normalized.isEmpty) {
      return '';
    }

    if (sideLength <=
        0) {
      return normalized;
    }

    final minimumLength =
        sideLength *
        2;

    if (normalized.length <=
        minimumLength) {
      return normalized;
    }

    return '${normalized.substring(0, sideLength)}'
        '...'
        '${normalized.substring(normalized.length - sideLength)}';
  }

  // ============================================================
  // HASH LOOKS VALID
  // ============================================================

  bool isValidSha256(
    String? value,
  ) {
    final normalized =
        value?.trim().toLowerCase() ??
        '';

    if (normalized.length !=
        64) {
      return false;
    }

    return RegExp(
      r'^[0-9a-f]{64}$',
    ).hasMatch(
      normalized,
    );
  }

  // ============================================================
  // FORMAT PERCENTAGE FOR HASH
  // ============================================================
  //
  // PRECISA corresponder ao SQL:
  //
  // trim(
  //   to_char(
  //     rs.percentage,
  //     'FM999999990.00'
  //   )
  // )
  //
  // Exemplos:
  //
  // 30      -> 30.00
  // 5       -> 5.00
  // 25.5    -> 25.50
  // 33.33   -> 33.33
  //
  // ============================================================

  String _formatPercentageForHash(
    double value,
  ) {
    return value.toStringAsFixed(
      2,
    );
  }

  // ============================================================
  // NORMALIZE SNAPSHOT TEXT
  // ============================================================
  //
  // IMPORTANTE:
  //
  // Não fazemos lowercase.
  //
  // Não removemos espaços internos.
  //
  // Não alteramos caracteres Unicode.
  //
  // O snapshot precisa representar exatamente o valor salvo.
  //
  // O SQL usa:
  //
  // coalesce(column, '')
  //
  // portanto null vira ''.
  //
  // ============================================================

  String _normalizeSnapshotText(
    String? value,
  ) {
    if (value ==
        null) {
      return '';
    }

    return value;
  }
}
