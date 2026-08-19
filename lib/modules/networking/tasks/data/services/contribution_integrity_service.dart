import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

// ============================================================
// CONTRIBUTION INTEGRITY SERVICE
// ============================================================
//
// Responsável SOMENTE por integridade.
//
// Funções:
//
// - SHA-256 de arquivo;
// - SHA-256 de texto;
// - SHA-256 de payload;
// - JSON canônico;
// - hash de evento;
// - encadeamento de eventos;
// - verificação.
//
// NÃO:
//
// - salva no banco;
// - faz upload;
// - decide autoria;
// - decide propriedade intelectual;
// - afirma validade jurídica.
//
// IMPORTANTE:
//
// Uma hash identifica os bytes/dados registrados.
//
// Ela NÃO prova sozinha:
//
// - autoria;
// - titularidade;
// - criação artística.
//
// ============================================================

class ContributionIntegrityService {
  const ContributionIntegrityService();

  // ============================================================
  // HASH BYTES
  // ============================================================

  String hashBytes(
    Uint8List bytes,
  ) {
    return sha256
        .convert(
          bytes,
        )
        .toString();
  }

  // ============================================================
  // HASH LIST
  // ============================================================

  String hashByteList(
    List<
      int
    >
    bytes,
  ) {
    return sha256
        .convert(
          bytes,
        )
        .toString();
  }

  // ============================================================
  // HASH TEXT
  // ============================================================

  String hashText(
    String value,
  ) {
    final bytes = utf8.encode(
      value,
    );

    return sha256
        .convert(
          bytes,
        )
        .toString();
  }

  // ============================================================
  // HASH PAYLOAD
  // ============================================================
  //
  // Primeiro transforma o conteúdo em JSON canônico.
  //
  // Isso evita:
  //
  // {"a":1,"b":2}
  //
  // possuir hash diferente de:
  //
  // {"b":2,"a":1}
  //
  // apenas porque a ordem das chaves mudou.
  //
  // ============================================================

  String hashPayload(
    Map<
      String,
      dynamic
    >
    payload,
  ) {
    final canonical = canonicalJson(
      payload,
    );

    return hashText(
      canonical,
    );
  }

  // ============================================================
  // CANONICAL JSON
  // ============================================================

  String canonicalJson(
    Map<
      String,
      dynamic
    >
    value,
  ) {
    final normalized = _canonicalize(
      value,
    );

    return jsonEncode(
      normalized,
    );
  }

  // ============================================================
  // BUILD EVENT HASH
  // ============================================================
  //
  // EVENT HASH =
  //
  // SHA256(
  //   projectId
  //   actorUserId
  //   eventType
  //   entityType
  //   entityId
  //   payloadHash
  //   previousEventHash
  //   createdAt UTC
  // )
  //
  // ============================================================

  String createEventHash({
    required String projectId,
    required String eventType,
    required String payloadHash,
    required DateTime createdAt,
    String? actorUserId,
    String? entityType,
    String? entityId,
    String? previousEventHash,
  }) {
    final eventPayload =
        <
          String,
          dynamic
        >{
          'project_id': projectId.trim(),

          'actor_user_id': _nullableString(
            actorUserId,
          ),

          'event_type': eventType.trim(),

          'entity_type': _nullableString(
            entityType,
          ),

          'entity_id': _nullableString(
            entityId,
          ),

          'payload_hash': payloadHash.trim(),

          'previous_event_hash': _nullableString(
            previousEventHash,
          ),

          'created_at': createdAt.toUtc().toIso8601String(),
        };

    return hashPayload(
      eventPayload,
    );
  }

  // ============================================================
  // CREATE EVENT INTEGRITY
  // ============================================================

  ContributionEventIntegrity createEventIntegrity({
    required String projectId,
    required String eventType,
    required Map<
      String,
      dynamic
    >
    payload,
    required DateTime createdAt,
    String? actorUserId,
    String? entityType,
    String? entityId,
    String? previousEventHash,
  }) {
    final payloadHash = hashPayload(
      payload,
    );

    final eventHash = createEventHash(
      projectId: projectId,

      actorUserId: actorUserId,

      eventType: eventType,

      entityType: entityType,

      entityId: entityId,

      payloadHash: payloadHash,

      previousEventHash: previousEventHash,

      createdAt: createdAt,
    );

    return ContributionEventIntegrity(
      payloadHash: payloadHash,

      previousEventHash: _nullableString(
        previousEventHash,
      ),

      eventHash: eventHash,
    );
  }

  // ============================================================
  // VERIFY BYTES
  // ============================================================

  bool verifyBytes({
    required Uint8List bytes,
    required String expectedHash,
  }) {
    final normalizedExpected = expectedHash.trim().toLowerCase();

    if (normalizedExpected.isEmpty) {
      return false;
    }

    final actual = hashBytes(
      bytes,
    ).toLowerCase();

    return actual ==
        normalizedExpected;
  }

  // ============================================================
  // VERIFY PAYLOAD
  // ============================================================

  bool verifyPayload({
    required Map<
      String,
      dynamic
    >
    payload,
    required String expectedHash,
  }) {
    final normalizedExpected = expectedHash.trim().toLowerCase();

    if (normalizedExpected.isEmpty) {
      return false;
    }

    return hashPayload(
          payload,
        ).toLowerCase() ==
        normalizedExpected;
  }

  // ============================================================
  // VERIFY EVENT
  // ============================================================

  bool verifyEvent({
    required String projectId,
    required String eventType,
    required Map<
      String,
      dynamic
    >
    payload,
    required DateTime createdAt,
    required String expectedEventHash,
    String? actorUserId,
    String? entityType,
    String? entityId,
    String? previousEventHash,
  }) {
    final payloadHash = hashPayload(
      payload,
    );

    final calculated = createEventHash(
      projectId: projectId,

      actorUserId: actorUserId,

      eventType: eventType,

      entityType: entityType,

      entityId: entityId,

      payloadHash: payloadHash,

      previousEventHash: previousEventHash,

      createdAt: createdAt,
    );

    return calculated.toLowerCase() ==
        expectedEventHash.trim().toLowerCase();
  }

  // ============================================================
  // SHORT HASH
  // ============================================================

  String shortHash(
    String? value, {
    int sideLength = 8,
  }) {
    final normalized =
        value?.trim() ??
        '';

    if (normalized.isEmpty) {
      return '';
    }

    if (sideLength <=
        0) {
      return normalized;
    }

    final requiredLength =
        sideLength *
        2;

    if (normalized.length <=
        requiredLength) {
      return normalized;
    }

    return '${normalized.substring(0, sideLength)}'
        '...'
        '${normalized.substring(normalized.length - sideLength)}';
  }

  // ============================================================
  // CANONICALIZE
  // ============================================================

  dynamic _canonicalize(
    dynamic value,
  ) {
    // ==========================================================
    // MAP
    // ==========================================================

    if (value
        is Map) {
      final keys =
          value.keys
              .map(
                (
                  key,
                ) => key.toString(),
              )
              .toList()
            ..sort();

      final result =
          <
            String,
            dynamic
          >{};

      for (final key in keys) {
        dynamic rawValue;

        if (value.containsKey(
          key,
        )) {
          rawValue = value[key];
        } else {
          for (final entry in value.entries) {
            if (entry.key.toString() ==
                key) {
              rawValue = entry.value;

              break;
            }
          }
        }

        result[key] = _canonicalize(
          rawValue,
        );
      }

      return result;
    }

    // ==========================================================
    // ITERABLE
    // ==========================================================

    if (value
        is Iterable) {
      return value
          .map(
            _canonicalize,
          )
          .toList();
    }

    // ==========================================================
    // DATETIME
    // ==========================================================

    if (value
        is DateTime) {
      return value.toUtc().toIso8601String();
    }

    // ==========================================================
    // ENUM
    // ==========================================================

    if (value
        is Enum) {
      return value.name;
    }

    // ==========================================================
    // BASIC TYPES
    // ==========================================================

    if (value ==
            null ||
        value
            is String ||
        value
            is num ||
        value
            is bool) {
      return value;
    }

    // ==========================================================
    // FALLBACK
    // ==========================================================

    return value.toString();
  }

  // ============================================================
  // NULLABLE STRING
  // ============================================================

  String? _nullableString(
    String? value,
  ) {
    final normalized =
        value?.trim() ??
        '';

    return normalized.isEmpty
        ? null
        : normalized;
  }
}

// ============================================================
// CONTRIBUTION EVENT INTEGRITY
// ============================================================

class ContributionEventIntegrity {
  final String payloadHash;

  final String? previousEventHash;

  final String eventHash;

  const ContributionEventIntegrity({
    required this.payloadHash,
    required this.eventHash,
    this.previousEventHash,
  });

  bool get hasPreviousEvent {
    return previousEventHash?.trim().isNotEmpty ==
        true;
  }

  @override
  String toString() {
    return 'ContributionEventIntegrity('
        'payloadHash: $payloadHash, '
        'previousEventHash: $previousEventHash, '
        'eventHash: $eventHash'
        ')';
  }
}
