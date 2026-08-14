// ============================================================
// PROFILE TRACK MODEL
// ============================================================
//
// Representa uma música ou demo publicada no perfil público.
//
// Responsabilidades:
//
// - armazenar metadados da faixa;
// - armazenar público permitido;
// - converter Map -> Model;
// - converter Model -> Map;
// - formatar duração;
// - formatar tamanho do arquivo;
// - fornecer helpers;
// - permitir cópias imutáveis.
//
// NÃO:
//
// - acessa Supabase;
// - faz upload;
// - reproduz áudio;
// - controla UI;
// - aplica segurança de banco.
//
// ============================================================

class ProfileTrackModel {
  // ============================================================
  // IDENTIDADE
  // ============================================================

  final String id;

  final String userId;

  // ============================================================
  // MÚSICA
  // ============================================================

  final String title;

  final String storagePath;

  final String? audioUrl;

  // ============================================================
  // AUDIÊNCIA
  // ============================================================
  //
  // Exemplo:
  //
  // [
  //   'artist',
  //   'beatmaker',
  // ]
  //
  // ============================================================

  final List<String> audienceRoles;

  // ============================================================
  // METADADOS
  // ============================================================

  final int? durationSeconds;

  final String? mimeType;

  final int? fileSizeBytes;

  // ============================================================
  // ORGANIZAÇÃO
  // ============================================================

  final int position;

  // ============================================================
  // STATUS
  // ============================================================

  final bool isActive;

  // ============================================================
  // DATAS
  // ============================================================

  final DateTime? createdAt;

  final DateTime? updatedAt;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const ProfileTrackModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.storagePath,
    this.audioUrl,
    this.audienceRoles = const <String>[],
    this.durationSeconds,
    this.mimeType,
    this.fileSizeBytes,
    this.position = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  // ============================================================
  // EMPTY
  // ============================================================

  factory ProfileTrackModel.empty({required String userId}) {
    return ProfileTrackModel(
      id: '',
      userId: userId.trim(),
      title: '',
      storagePath: '',
      audienceRoles: const <String>[],
    );
  }

  // ============================================================
  // GETTERS
  // ============================================================

  bool get hasId => id.trim().isNotEmpty;

  bool get hasTitle => title.trim().isNotEmpty;

  bool get hasStoragePath => storagePath.trim().isNotEmpty;

  bool get hasAudioUrl => audioUrl?.trim().isNotEmpty == true;

  bool get hasDuration => durationSeconds != null && durationSeconds! > 0;

  bool get hasFileSize => fileSizeBytes != null && fileSizeBytes! > 0;

  bool get hasAudience => audienceRoles.isNotEmpty;

  // ============================================================
  // AUDIENCE
  // ============================================================

  bool allowsRole(String role) {
    final normalizedRole = _normalizeRole(role);

    if (normalizedRole.isEmpty) {
      return false;
    }

    return audienceRoles.contains(normalizedRole);
  }

  bool allowsAnyRole(Iterable<String> roles) {
    for (final role in roles) {
      if (allowsRole(role)) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // DURAÇÃO FORMATADA
  // ============================================================

  String get formattedDuration {
    final totalSeconds = durationSeconds;

    if (totalSeconds == null || totalSeconds <= 0) {
      return '--:--';
    }

    final minutes = totalSeconds ~/ 60;

    final seconds = totalSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // TAMANHO FORMATADO
  // ============================================================

  String get formattedFileSize {
    final bytes = fileSizeBytes;

    if (bytes == null || bytes <= 0) {
      return '';
    }

    const kilobyte = 1024;

    const megabyte = kilobyte * 1024;

    const gigabyte = megabyte * 1024;

    if (bytes >= gigabyte) {
      return '${(bytes / gigabyte).toStringAsFixed(2)} GB';
    }

    if (bytes >= megabyte) {
      return '${(bytes / megabyte).toStringAsFixed(2)} MB';
    }

    if (bytes >= kilobyte) {
      return '${(bytes / kilobyte).toStringAsFixed(1)} KB';
    }

    return '$bytes B';
  }

  // ============================================================
  // FORMATO
  // ============================================================

  String get formatLabel {
    final normalizedMimeType = mimeType?.trim();

    if (normalizedMimeType == null || normalizedMimeType.isEmpty) {
      return '';
    }

    if (!normalizedMimeType.contains('/')) {
      return normalizedMimeType.toUpperCase();
    }

    return normalizedMimeType.split('/').last.toUpperCase();
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory ProfileTrackModel.fromMap(Map<String, dynamic> map) {
    return ProfileTrackModel(
      id: _readString(map['id']),

      userId: _readString(map['user_id']),

      title: _readString(map['title']),

      storagePath: _readString(map['storage_path']),

      audioUrl: _readNullableString(map['audio_url']),

      audienceRoles: _readStringList(map['audience_roles']),

      durationSeconds: _readNullableInt(map['duration_seconds']),

      mimeType: _readNullableString(map['mime_type']),

      fileSizeBytes: _readNullableInt(map['file_size_bytes']),

      position: _readInt(map['position']),

      isActive: _readBool(map['is_active'], fallback: true),

      createdAt: _readDateTime(map['created_at']),

      updatedAt: _readDateTime(map['updated_at']),
    );
  }

  // ============================================================
  // TO MAP
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id.trim(),

      'user_id': userId.trim(),

      'title': title.trim(),

      'storage_path': storagePath.trim(),

      'audio_url': _normalizeNullableString(audioUrl),

      'audience_roles': _normalizeRoles(audienceRoles),

      'duration_seconds': durationSeconds,

      'mime_type': _normalizeNullableString(mimeType),

      'file_size_bytes': fileSizeBytes,

      'position': position,

      'is_active': isActive,

      if (createdAt != null) 'created_at': createdAt!.toUtc().toIso8601String(),

      if (updatedAt != null) 'updated_at': updatedAt!.toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // INSERT MAP
  // ============================================================

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId.trim(),

      'title': title.trim(),

      'storage_path': storagePath.trim(),

      'audio_url': _normalizeNullableString(audioUrl),

      'audience_roles': _normalizeRoles(audienceRoles),

      'duration_seconds': durationSeconds,

      'mime_type': _normalizeNullableString(mimeType),

      'file_size_bytes': fileSizeBytes,

      'position': position,

      'is_active': isActive,
    };
  }

  // ============================================================
  // UPDATE MAP
  // ============================================================

  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title.trim(),

      'audio_url': _normalizeNullableString(audioUrl),

      'audience_roles': _normalizeRoles(audienceRoles),

      'duration_seconds': durationSeconds,

      'mime_type': _normalizeNullableString(mimeType),

      'file_size_bytes': fileSizeBytes,

      'position': position,

      'is_active': isActive,

      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  ProfileTrackModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? storagePath,
    String? audioUrl,
    bool clearAudioUrl = false,
    List<String>? audienceRoles,
    int? durationSeconds,
    bool clearDuration = false,
    String? mimeType,
    bool clearMimeType = false,
    int? fileSizeBytes,
    bool clearFileSize = false,
    int? position,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileTrackModel(
      id: id ?? this.id,

      userId: userId ?? this.userId,

      title: title ?? this.title,

      storagePath: storagePath ?? this.storagePath,

      audioUrl: clearAudioUrl ? null : audioUrl ?? this.audioUrl,

      audienceRoles: audienceRoles == null
          ? this.audienceRoles
          : _normalizeRoles(audienceRoles),

      durationSeconds: clearDuration
          ? null
          : durationSeconds ?? this.durationSeconds,

      mimeType: clearMimeType ? null : mimeType ?? this.mimeType,

      fileSizeBytes: clearFileSize ? null : fileSizeBytes ?? this.fileSizeBytes,

      position: position ?? this.position,

      isActive: isActive ?? this.isActive,

      createdAt: createdAt ?? this.createdAt,

      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ============================================================
  // READ STRING
  // ============================================================

  static String _readString(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  // ============================================================
  // READ NULLABLE STRING
  // ============================================================

  static String? _readNullableString(dynamic value) {
    final normalized = _readString(value);

    return normalized.isEmpty ? null : normalized;
  }

  // ============================================================
  // NORMALIZE NULLABLE STRING
  // ============================================================

  static String? _normalizeNullableString(String? value) {
    final normalized = value?.trim();

    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  // ============================================================
  // READ STRING LIST
  // ============================================================

  static List<String> _readStringList(dynamic value) {
    if (value == null) {
      return const <String>[];
    }

    if (value is List) {
      return _normalizeRoles(
        value.map((item) {
          return item.toString();
        }),
      );
    }

    if (value is Iterable) {
      return _normalizeRoles(
        value.map((item) {
          return item.toString();
        }),
      );
    }

    return const <String>[];
  }

  // ============================================================
  // NORMALIZE ROLE
  // ============================================================

  static String _normalizeRole(String value) {
    return value.trim().toLowerCase().replaceAll(' ', '_');
  }

  // ============================================================
  // NORMALIZE ROLES
  // ============================================================

  static List<String> _normalizeRoles(Iterable<String> roles) {
    final normalized = roles
        .map(_normalizeRole)
        .where((role) {
          return role.isNotEmpty;
        })
        .toSet()
        .toList();

    normalized.sort();

    return List<String>.unmodifiable(normalized);
  }

  // ============================================================
  // READ INT
  // ============================================================

  static int _readInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(_readString(value)) ?? fallback;
  }

  // ============================================================
  // READ NULLABLE INT
  // ============================================================

  static int? _readNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    final normalized = _readString(value);

    if (normalized.isEmpty) {
      return null;
    }

    return int.tryParse(normalized);
  }

  // ============================================================
  // READ BOOL
  // ============================================================

  static bool _readBool(dynamic value, {bool fallback = false}) {
    if (value == null) {
      return fallback;
    }

    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final normalized = _readString(value).toLowerCase();

    if (normalized == 'true' || normalized == '1') {
      return true;
    }

    if (normalized == 'false' || normalized == '0') {
      return false;
    }

    return fallback;
  }

  // ============================================================
  // READ DATETIME
  // ============================================================

  static DateTime? _readDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    final normalized = _readString(value);

    if (normalized.isEmpty) {
      return null;
    }

    return DateTime.tryParse(normalized);
  }

  // ============================================================
  // DEBUG
  // ============================================================

  @override
  String toString() {
    return 'ProfileTrackModel('
        'id: $id, '
        'userId: $userId, '
        'title: $title, '
        'audienceRoles: $audienceRoles, '
        'position: $position, '
        'isActive: $isActive'
        ')';
  }
}
