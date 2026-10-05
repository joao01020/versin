// ============================================================
// WITHDRAW REQUEST
// ============================================================
//
// Representa uma solicitação de saque.
//
// Este model NÃO executa operações financeiras.
//
// Ele apenas transporta os dados necessários entre:
//
// WithdrawController
//        ↓
// WithdrawService
//        ↓
// Backend
//
// Futuramente poderá receber:
//
// - chave PIX;
// - tipo da chave;
// - conta bancária;
// - status;
// - taxa;
// - valor líquido;
// - identificador da transação.
//
// ============================================================

class WithdrawRequest {
  // ============================================================
  // USUÁRIO
  // ============================================================

  final String userId;

  // ============================================================
  // VALOR
  // ============================================================

  final double amount;

  // ============================================================
  // DATA
  // ============================================================

  final DateTime requestedAt;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const WithdrawRequest({
    required this.userId,
    required this.amount,
    required this.requestedAt,
  });

  // ============================================================
  // VALIDAÇÕES SIMPLES
  // ============================================================

  bool get hasValidUser {
    return userId.trim().isNotEmpty;
  }

  bool get hasValidAmount {
    return amount >
        0;
  }

  bool get isValid {
    return hasValidUser &&
        hasValidAmount;
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  WithdrawRequest copyWith({
    String? userId,
    double? amount,
    DateTime? requestedAt,
  }) {
    return WithdrawRequest(
      userId:
          userId ??
          this.userId,

      amount:
          amount ??
          this.amount,

      requestedAt:
          requestedAt ??
          this.requestedAt,
    );
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory WithdrawRequest.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return WithdrawRequest(
      userId:
          map['user_id']?.toString().trim() ??
          '',

      amount: _parseDouble(
        map['amount'],
      ),

      requestedAt:
          _parseDateTime(
            map['requested_at'],
          ) ??
          DateTime.now(),
    );
  }

  // ============================================================
  // TO MAP
  // ============================================================

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'user_id': userId,

      'amount': amount,

      'requested_at': requestedAt.toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // TO INSERT MAP
  // ============================================================
  //
  // Mantemos separado de toMap() porque futuramente o model
  // poderá possuir campos que não devem ser enviados durante
  // um INSERT.
  //
  // ============================================================

  Map<
    String,
    dynamic
  >
  toInsertMap() {
    return {
      'user_id': userId,

      'amount': amount,

      'requested_at': requestedAt.toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // PARSE DOUBLE
  // ============================================================

  static double _parseDouble(
    dynamic value,
  ) {
    if (value
        is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ??
              '',
        ) ??
        0;
  }

  // ============================================================
  // PARSE DATETIME
  // ============================================================

  static DateTime? _parseDateTime(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(
      text,
    );
  }

  // ============================================================
  // TO STRING
  // ============================================================

  @override
  String toString() {
    return 'WithdrawRequest('
        'userId: $userId, '
        'amount: $amount, '
        'requestedAt: $requestedAt'
        ')';
  }
}
