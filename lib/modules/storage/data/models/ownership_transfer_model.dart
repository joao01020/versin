// ============================================================
// OWNERSHIP TRANSFER STATUS
// ============================================================
//
// pending:
//   transferência criada, aguardando resposta.
//
// accepted:
//   novo proprietário aceitou.
//
// rejected:
//   destinatário recusou.
//
// cancelled:
//   remetente cancelou antes da aceitação.
//
// ============================================================

enum OwnershipTransferStatus {
  pending,
  accepted,
  rejected,
  cancelled,
}

// ============================================================
// OWNERSHIP TRANSFER MODEL
// ============================================================
//
// Representa uma transferência de propriedade dentro
// do armazenamento do Versin.
//
// IMPORTANTE:
//
// Este model NÃO altera diretamente StoredWorkModel.
//
// O fluxo futuro será:
//
// OwnershipTransferModel
//        ↓
// transferência aceita
//        ↓
// serviço/controller
//        ↓
// StoredWorkModel.ownerUserId atualizado
//
// O originalAuthorUserId da obra permanece inalterado.
//
// ============================================================

class OwnershipTransferModel {
  // ==========================================================
  // IDENTIFICAÇÃO
  // ==========================================================

  final String id;

  // ==========================================================
  // OBRA
  // ==========================================================

  final String workId;

  // ==========================================================
  // USUÁRIOS
  // ==========================================================
  //
  // fromUserId:
  //   proprietário que está transferindo.
  //
  // toUserId:
  //   usuário que receberá a propriedade.
  //
  // ==========================================================

  final String fromUserId;

  final String toUserId;

  // ==========================================================
  // STATUS
  // ==========================================================

  final OwnershipTransferStatus status;

  // ==========================================================
  // HASH DA OBRA NO MOMENTO DA TRANSFERÊNCIA
  // ==========================================================
  //
  // Guardar o hash aqui é importante porque permite saber
  // exatamente qual versão da obra foi transferida.
  //
  // ==========================================================

  final String workHash;

  // ==========================================================
  // VERSÃO
  // ==========================================================

  final int workVersion;

  // ==========================================================
  // DATAS
  // ==========================================================

  final DateTime createdAt;

  final DateTime? acceptedAt;

  final DateTime? rejectedAt;

  final DateTime? cancelledAt;

  // ==========================================================
  // OBSERVAÇÃO
  // ==========================================================

  final String? note;

  // ==========================================================
  // CONSTRUTOR
  // ==========================================================

  const OwnershipTransferModel({
    required this.id,
    required this.workId,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    required this.workHash,
    required this.workVersion,
    required this.createdAt,
    this.acceptedAt,
    this.rejectedAt,
    this.cancelledAt,
    this.note,
  });

  // ==========================================================
  // HELPERS DE STATUS
  // ==========================================================

  bool get isPending =>
      status ==
      OwnershipTransferStatus.pending;

  bool get isAccepted =>
      status ==
      OwnershipTransferStatus.accepted;

  bool get isRejected =>
      status ==
      OwnershipTransferStatus.rejected;

  bool get isCancelled =>
      status ==
      OwnershipTransferStatus.cancelled;

  // ==========================================================
  // STATUS FINAL
  // ==========================================================

  bool get isFinished =>
      isAccepted ||
      isRejected ||
      isCancelled;

  // ==========================================================
  // NOME DO STATUS
  // ==========================================================

  String get statusName {
    switch (status) {
      case OwnershipTransferStatus.pending:
        return 'Pendente';

      case OwnershipTransferStatus.accepted:
        return 'Aceita';

      case OwnershipTransferStatus.rejected:
        return 'Recusada';

      case OwnershipTransferStatus.cancelled:
        return 'Cancelada';
    }
  }

  // ==========================================================
  // CONVERTER STATUS PARA STRING
  // ==========================================================

  static String statusToString(
    OwnershipTransferStatus status,
  ) {
    switch (status) {
      case OwnershipTransferStatus.pending:
        return 'pending';

      case OwnershipTransferStatus.accepted:
        return 'accepted';

      case OwnershipTransferStatus.rejected:
        return 'rejected';

      case OwnershipTransferStatus.cancelled:
        return 'cancelled';
    }
  }

  // ==========================================================
  // CONVERTER STRING PARA STATUS
  // ==========================================================

  static OwnershipTransferStatus statusFromString(
    String value,
  ) {
    switch (value.trim().toLowerCase()) {
      case 'pending':
        return OwnershipTransferStatus.pending;

      case 'accepted':
        return OwnershipTransferStatus.accepted;

      case 'rejected':
        return OwnershipTransferStatus.rejected;

      case 'cancelled':
        return OwnershipTransferStatus.cancelled;

      default:
        throw ArgumentError(
          'Status de transferência inválido: $value',
        );
    }
  }

  // ==========================================================
  // TO MAP
  // ==========================================================

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'id': id,

      'work_id': workId,

      'from_user_id': fromUserId,

      'to_user_id': toUserId,

      'status': statusToString(
        status,
      ),

      'work_hash': workHash,

      'work_version': workVersion,

      'created_at': createdAt.toIso8601String(),

      'accepted_at': acceptedAt?.toIso8601String(),

      'rejected_at': rejectedAt?.toIso8601String(),

      'cancelled_at': cancelledAt?.toIso8601String(),

      'note': note,
    };
  }

  // ==========================================================
  // FROM MAP
  // ==========================================================

  factory OwnershipTransferModel.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return OwnershipTransferModel(
      id:
          map['id']?.toString() ??
          '',

      workId:
          map['work_id']?.toString() ??
          '',

      fromUserId:
          map['from_user_id']?.toString() ??
          '',

      toUserId:
          map['to_user_id']?.toString() ??
          '',

      status: statusFromString(
        map['status']?.toString() ??
            'pending',
      ),

      workHash:
          map['work_hash']?.toString() ??
          '',

      workVersion: _parseInt(
        map['work_version'],
        fallback: 1,
      ),

      createdAt: _parseDateTime(
        map['created_at'],
      ),

      acceptedAt: _parseNullableDateTime(
        map['accepted_at'],
      ),

      rejectedAt: _parseNullableDateTime(
        map['rejected_at'],
      ),

      cancelledAt: _parseNullableDateTime(
        map['cancelled_at'],
      ),

      note: map['note']?.toString(),
    );
  }

  // ==========================================================
  // COPY WITH
  // ==========================================================

  OwnershipTransferModel copyWith({
    String? id,
    String? workId,
    String? fromUserId,
    String? toUserId,
    OwnershipTransferStatus? status,
    String? workHash,
    int? workVersion,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? rejectedAt,
    DateTime? cancelledAt,
    String? note,
  }) {
    return OwnershipTransferModel(
      id:
          id ??
          this.id,

      workId:
          workId ??
          this.workId,

      fromUserId:
          fromUserId ??
          this.fromUserId,

      toUserId:
          toUserId ??
          this.toUserId,

      status:
          status ??
          this.status,

      workHash:
          workHash ??
          this.workHash,

      workVersion:
          workVersion ??
          this.workVersion,

      createdAt:
          createdAt ??
          this.createdAt,

      acceptedAt:
          acceptedAt ??
          this.acceptedAt,

      rejectedAt:
          rejectedAt ??
          this.rejectedAt,

      cancelledAt:
          cancelledAt ??
          this.cancelledAt,

      note:
          note ??
          this.note,
    );
  }

  // ==========================================================
  // ACEITAR
  // ==========================================================

  OwnershipTransferModel accept({
    DateTime? acceptedAt,
  }) {
    if (!isPending) {
      throw StateError(
        'Somente transferências pendentes podem ser aceitas.',
      );
    }

    return copyWith(
      status: OwnershipTransferStatus.accepted,

      acceptedAt:
          acceptedAt ??
          DateTime.now().toUtc(),
    );
  }

  // ==========================================================
  // RECUSAR
  // ==========================================================

  OwnershipTransferModel reject({
    DateTime? rejectedAt,
  }) {
    if (!isPending) {
      throw StateError(
        'Somente transferências pendentes podem ser recusadas.',
      );
    }

    return copyWith(
      status: OwnershipTransferStatus.rejected,

      rejectedAt:
          rejectedAt ??
          DateTime.now().toUtc(),
    );
  }

  // ==========================================================
  // CANCELAR
  // ==========================================================

  OwnershipTransferModel cancel({
    DateTime? cancelledAt,
  }) {
    if (!isPending) {
      throw StateError(
        'Somente transferências pendentes podem ser canceladas.',
      );
    }

    return copyWith(
      status: OwnershipTransferStatus.cancelled,

      cancelledAt:
          cancelledAt ??
          DateTime.now().toUtc(),
    );
  }

  // ==========================================================
  // PARSE INT
  // ==========================================================

  static int _parseInt(
    dynamic value, {
    required int fallback,
  }) {
    if (value
        is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ??
              '',
        ) ??
        fallback;
  }

  // ==========================================================
  // PARSE DATETIME
  // ==========================================================

  static DateTime _parseDateTime(
    dynamic value,
  ) {
    if (value
        is DateTime) {
      return value;
    }

    final parsed = DateTime.tryParse(
      value?.toString() ??
          '',
    );

    return parsed ??
        DateTime.fromMillisecondsSinceEpoch(
          0,
          isUtc: true,
        );
  }

  // ==========================================================
  // PARSE DATETIME OPCIONAL
  // ==========================================================

  static DateTime? _parseNullableDateTime(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    if (value
        is DateTime) {
      return value;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  // ==========================================================
  // DEBUG
  // ==========================================================

  @override
  String toString() {
    return 'OwnershipTransferModel('
        'id: $id, '
        'workId: $workId, '
        'from: $fromUserId, '
        'to: $toUserId, '
        'status: ${statusToString(status)}, '
        'version: $workVersion'
        ')';
  }
}
