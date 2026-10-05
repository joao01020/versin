// ============================================================
// SYSTEM NOTIFICATION TYPE
// ============================================================

enum SystemNotificationType {
  info(
    key: 'info',
    label: 'Informação',
  ),

  success(
    key: 'success',
    label: 'Sucesso',
  ),

  warning(
    key: 'warning',
    label: 'Aviso',
  ),

  error(
    key: 'error',
    label: 'Erro',
  ),

  update(
    key: 'update',
    label: 'Atualização',
  ),

  maintenance(
    key: 'maintenance',
    label: 'Manutenção',
  ),

  news(
    key: 'news',
    label: 'Novidade',
  );

  final String key;

  final String label;

  const SystemNotificationType({
    required this.key,
    required this.label,
  });

  static SystemNotificationType fromKey(
    String? key,
  ) {
    if (key ==
            null ||
        key.trim().isEmpty) {
      return SystemNotificationType.info;
    }

    final normalizedKey = key.trim().toLowerCase();

    for (final type in values) {
      if (type.key ==
          normalizedKey) {
        return type;
      }
    }

    return SystemNotificationType.info;
  }
}

// ============================================================
// SYSTEM NOTIFICATION STATUS
// ============================================================
//
// Estados utilizados principalmente por notificações de
// atualização.
//
// Banco:
//
// pending
// downloading
// installing
// completed
// failed
//
// ============================================================

enum SystemNotificationStatus {
  pending(
    key: 'pending',
    label: 'Aguardando',
  ),

  downloading(
    key: 'downloading',
    label: 'Baixando',
  ),

  installing(
    key: 'installing',
    label: 'Instalando',
  ),

  completed(
    key: 'completed',
    label: 'Concluído',
  ),

  failed(
    key: 'failed',
    label: 'Falhou',
  );

  final String key;

  final String label;

  const SystemNotificationStatus({
    required this.key,
    required this.label,
  });

  static SystemNotificationStatus fromKey(
    String? key,
  ) {
    if (key ==
            null ||
        key.trim().isEmpty) {
      return SystemNotificationStatus.pending;
    }

    final normalizedKey = key.trim().toLowerCase();

    for (final status in values) {
      if (status.key ==
          normalizedKey) {
        return status;
      }
    }

    return SystemNotificationStatus.pending;
  }
}

// ============================================================
// SYSTEM NOTIFICATION MODEL
// ============================================================

class SystemNotificationModel {
  // ============================================================
  // IDENTIFICAÇÃO
  // ============================================================

  final String id;

  // ============================================================
  // CONTEÚDO
  // ============================================================

  final String title;

  final String message;

  // ============================================================
  // TIPO
  // ============================================================

  final SystemNotificationType type;

  // ============================================================
  // DESTINATÁRIO
  // ============================================================

  final String? targetUserId;

  // ============================================================
  // ESTADO DE LEITURA
  // ============================================================

  final bool isRead;

  final bool isActive;

  // ============================================================
  // PROGRESSO
  // ============================================================
  //
  // progress:
  // 0 até 100.
  //
  // status:
  // pending
  // downloading
  // installing
  // completed
  // failed
  //
  // progressMessage:
  // mensagem exibida enquanto o processo evolui.
  //
  // ============================================================

  final int progress;

  final SystemNotificationStatus status;

  final String? progressMessage;

  // ============================================================
  // DATAS
  // ============================================================

  final DateTime createdAt;

  final DateTime? expiresAt;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const SystemNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.targetUserId,
    this.isRead = false,
    this.isActive = true,
    this.progress = 0,
    this.status = SystemNotificationStatus.pending,
    this.progressMessage,
    this.expiresAt,
  });

  // ============================================================
  // NÃO LIDA
  // ============================================================

  bool get isUnread {
    return !isRead;
  }

  // ============================================================
  // GLOBAL
  // ============================================================

  bool get isGlobal {
    return targetUserId ==
            null ||
        targetUserId!.trim().isEmpty;
  }

  // ============================================================
  // POSSUI DESTINATÁRIO
  // ============================================================

  bool get hasTargetUser {
    return targetUserId !=
            null &&
        targetUserId!.trim().isNotEmpty;
  }

  // ============================================================
  // VISÍVEL PARA USUÁRIO
  // ============================================================

  bool isVisibleForUser(
    String? userId,
  ) {
    if (isGlobal) {
      return true;
    }

    if (userId ==
            null ||
        userId.trim().isEmpty) {
      return false;
    }

    return targetUserId ==
        userId.trim();
  }

  // ============================================================
  // EXPIRADA
  // ============================================================

  bool get isExpired {
    final expiration = expiresAt;

    if (expiration ==
        null) {
      return false;
    }

    return DateTime.now().isAfter(
      expiration,
    );
  }

  // ============================================================
  // PODE SER EXIBIDA
  // ============================================================

  bool get canDisplay {
    return isActive &&
        !isExpired;
  }

  // ============================================================
  // LABEL DO TIPO
  // ============================================================

  String get typeLabel {
    return type.label;
  }

  // ============================================================
  // LABEL DO STATUS
  // ============================================================

  String get statusLabel {
    return status.label;
  }

  // ============================================================
  // É ATUALIZAÇÃO
  // ============================================================

  bool get isUpdate {
    return type ==
        SystemNotificationType.update;
  }

  // ============================================================
  // POSSUI PROGRESSO
  // ============================================================

  bool get hasProgress {
    return isUpdate ||
        progress >
            0 ||
        progressMessage !=
            null;
  }

  // ============================================================
  // PROGRESSO NORMALIZADO
  // ============================================================
  //
  // Utilizado diretamente em:
  //
  // LinearProgressIndicator
  //
  // 0   → 0.0
  // 50  → 0.5
  // 100 → 1.0
  //
  // ============================================================

  double get progressValue {
    return normalizedProgress /
        100;
  }

  // ============================================================
  // PROGRESSO NORMALIZADO 0..100
  // ============================================================

  int get normalizedProgress {
    if (progress <
        0) {
      return 0;
    }

    if (progress >
        100) {
      return 100;
    }

    return progress;
  }

  // ============================================================
  // PENDENTE
  // ============================================================

  bool get isPending {
    return status ==
        SystemNotificationStatus.pending;
  }

  // ============================================================
  // BAIXANDO
  // ============================================================

  bool get isDownloading {
    return status ==
        SystemNotificationStatus.downloading;
  }

  // ============================================================
  // INSTALANDO
  // ============================================================

  bool get isInstalling {
    return status ==
        SystemNotificationStatus.installing;
  }

  // ============================================================
  // CONCLUÍDO
  // ============================================================

  bool get isCompleted {
    return status ==
        SystemNotificationStatus.completed;
  }

  // ============================================================
  // FALHOU
  // ============================================================

  bool get isFailed {
    return status ==
        SystemNotificationStatus.failed;
  }

  // ============================================================
  // PROCESSANDO
  // ============================================================

  bool get isProcessing {
    return isDownloading ||
        isInstalling;
  }

  // ============================================================
  // MARCAR COMO LIDA
  // ============================================================

  SystemNotificationModel markAsRead() {
    if (isRead) {
      return this;
    }

    return copyWith(
      isRead: true,
    );
  }

  // ============================================================
  // MARCAR COMO NÃO LIDA
  // ============================================================

  SystemNotificationModel markAsUnread() {
    if (!isRead) {
      return this;
    }

    return copyWith(
      isRead: false,
    );
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory SystemNotificationModel.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return SystemNotificationModel(
      id: _parseString(
        map['id'],
      ),

      title: _parseString(
        map['title'],
      ),

      message: _parseString(
        map['message'],
      ),

      type: SystemNotificationType.fromKey(
        map['type']?.toString(),
      ),

      targetUserId: _parseNullableString(
        map['target_user_id'],
      ),

      isRead: _parseBool(
        map['is_read'],
        fallback: false,
      ),

      isActive: _parseBool(
        map['is_active'],
        fallback: true,
      ),

      // ========================================================
      // PROGRESSO
      // ========================================================
      progress: _parseProgress(
        map['progress'],
      ),

      status: SystemNotificationStatus.fromKey(
        map['status']?.toString(),
      ),

      progressMessage: _parseNullableString(
        map['progress_message'],
      ),

      // ========================================================
      // DATAS
      // ========================================================
      createdAt: _parseDateTime(
        map['created_at'],
      ),

      expiresAt: _parseNullableDateTime(
        map['expires_at'],
      ),
    );
  }

  // ============================================================
  // FROM JSON
  // ============================================================

  factory SystemNotificationModel.fromJson(
    Map<
      String,
      dynamic
    >
    json,
  ) {
    return SystemNotificationModel.fromMap(
      json,
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
    return <
      String,
      dynamic
    >{
      'id': id,

      'title': title,

      'message': message,

      'type': type.key,

      'target_user_id': targetUserId,

      'is_read': isRead,

      'is_active': isActive,

      'progress': normalizedProgress,

      'status': status.key,

      'progress_message': progressMessage,

      'created_at': createdAt.toUtc().toIso8601String(),

      'expires_at': expiresAt?.toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // MAP PARA SUPABASE
  // ============================================================
  //
  // Não envia:
  //
  // id
  // created_at
  // is_read
  //
  // ============================================================

  Map<
    String,
    dynamic
  >
  toRemoteMap() {
    return <
      String,
      dynamic
    >{
      'title': title,

      'message': message,

      'type': type.key,

      'target_user_id': targetUserId,

      'is_active': isActive,

      'progress': normalizedProgress,

      'status': status.key,

      'progress_message': progressMessage,

      'expires_at': expiresAt?.toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<
    String,
    dynamic
  >
  toJson() {
    return toMap();
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  SystemNotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    SystemNotificationType? type,
    String? targetUserId,
    bool clearTargetUserId = false,
    bool? isRead,
    bool? isActive,
    int? progress,
    SystemNotificationStatus? status,
    String? progressMessage,
    bool clearProgressMessage = false,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
  }) {
    return SystemNotificationModel(
      id:
          id ??
          this.id,

      title:
          title ??
          this.title,

      message:
          message ??
          this.message,

      type:
          type ??
          this.type,

      targetUserId: clearTargetUserId
          ? null
          : targetUserId ??
                this.targetUserId,

      isRead:
          isRead ??
          this.isRead,

      isActive:
          isActive ??
          this.isActive,

      progress:
          progress ??
          this.progress,

      status:
          status ??
          this.status,

      progressMessage: clearProgressMessage
          ? null
          : progressMessage ??
                this.progressMessage,

      createdAt:
          createdAt ??
          this.createdAt,

      expiresAt: clearExpiresAt
          ? null
          : expiresAt ??
                this.expiresAt,
    );
  }

  // ============================================================
  // DEBUG
  // ============================================================

  @override
  String toString() {
    return 'SystemNotificationModel('
        'id: $id, '
        'title: $title, '
        'type: ${type.key}, '
        'targetUserId: $targetUserId, '
        'isGlobal: $isGlobal, '
        'isRead: $isRead, '
        'isActive: $isActive, '
        'progress: $normalizedProgress, '
        'status: ${status.key}, '
        'progressMessage: $progressMessage, '
        'createdAt: $createdAt, '
        'expiresAt: $expiresAt'
        ')';
  }

  // ============================================================
  // EQUALITY
  // ============================================================

  @override
  bool operator ==(
    Object other,
  ) {
    if (identical(
      this,
      other,
    )) {
      return true;
    }

    return other
            is SystemNotificationModel &&
        other.id ==
            id;
  }

  // ============================================================
  // HASH CODE
  // ============================================================

  @override
  int get hashCode {
    return id.hashCode;
  }

  // ============================================================
  // PARSE STRING
  // ============================================================

  static String _parseString(
    dynamic value,
  ) {
    if (value ==
        null) {
      return '';
    }

    return value.toString().trim();
  }

  // ============================================================
  // PARSE NULLABLE STRING
  // ============================================================

  static String? _parseNullableString(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    final parsed = value.toString().trim();

    if (parsed.isEmpty) {
      return null;
    }

    return parsed;
  }

  // ============================================================
  // PARSE BOOL
  // ============================================================

  static bool _parseBool(
    dynamic value, {
    required bool fallback,
  }) {
    if (value ==
        null) {
      return fallback;
    }

    if (value
        is bool) {
      return value;
    }

    if (value
        is num) {
      return value !=
          0;
    }

    final normalized = value.toString().trim().toLowerCase();

    if (normalized ==
            'true' ||
        normalized ==
            '1') {
      return true;
    }

    if (normalized ==
            'false' ||
        normalized ==
            '0') {
      return false;
    }

    return fallback;
  }

  // ============================================================
  // PARSE PROGRESS
  // ============================================================

  static int _parseProgress(
    dynamic value,
  ) {
    if (value ==
        null) {
      return 0;
    }

    int? parsed;

    if (value
        is int) {
      parsed = value;
    } else if (value
        is num) {
      parsed = value.toInt();
    } else {
      parsed = int.tryParse(
        value.toString(),
      );
    }

    final result =
        parsed ??
        0;

    if (result <
        0) {
      return 0;
    }

    if (result >
        100) {
      return 100;
    }

    return result;
  }

  // ============================================================
  // PARSE DATETIME
  // ============================================================

  static DateTime _parseDateTime(
    dynamic value,
  ) {
    if (value
        is DateTime) {
      return value;
    }

    if (value !=
        null) {
      final parsed = DateTime.tryParse(
        value.toString(),
      );

      if (parsed !=
          null) {
        return parsed;
      }
    }

    return DateTime.fromMillisecondsSinceEpoch(
      0,
      isUtc: true,
    );
  }

  // ============================================================
  // PARSE NULLABLE DATETIME
  // ============================================================

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

    final raw = value.toString().trim();

    if (raw.isEmpty) {
      return null;
    }

    return DateTime.tryParse(
      raw,
    );
  }
}
