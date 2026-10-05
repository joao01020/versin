enum StoredWorkType {
  lyrics,
  beat,
}

class StoredWorkModel {
  final String id;

  final String originalAuthorUserId;
  final String ownerUserId;

  final StoredWorkType type;
  final String title;

  final String contentHash;
  final String hashAlgorithm;

  final int version;
  final String? previousHash;

  final bool integrityVerified;

  final String? lyricsContent;

  // Para beats, aponta para a cópia armazenada pelo Versin.
  // Exemplo:
  // ~/.local/share/versin/storage/beats/beat_123.wav
  final String? filePath;
  final String? fileName;
  final String? mimeType;
  final int? fileSizeBytes;
  final int? bpm;

  final DateTime createdAt;
  final DateTime updatedAt;

  const StoredWorkModel({
    required this.id,
    required this.originalAuthorUserId,
    required this.ownerUserId,
    required this.type,
    required this.title,
    required this.contentHash,
    required this.hashAlgorithm,
    required this.version,
    required this.integrityVerified,
    required this.createdAt,
    required this.updatedAt,
    this.previousHash,
    this.lyricsContent,
    this.filePath,
    this.fileName,
    this.mimeType,
    this.fileSizeBytes,
    this.bpm,
  });

  bool get isLyrics =>
      type ==
      StoredWorkType.lyrics;

  bool get isBeat =>
      type ==
      StoredWorkType.beat;

  bool get hasPreviousVersion =>
      previousHash !=
          null &&
      previousHash!.isNotEmpty;

  bool get hasFile =>
      filePath !=
          null &&
      filePath!.isNotEmpty;

  bool get hasLyricsContent =>
      lyricsContent !=
          null &&
      lyricsContent!.isNotEmpty;

  String get typeName {
    switch (type) {
      case StoredWorkType.lyrics:
        return 'Letra';

      case StoredWorkType.beat:
        return 'Beat';
    }
  }

  static String typeToString(
    StoredWorkType type,
  ) {
    switch (type) {
      case StoredWorkType.lyrics:
        return 'lyrics';

      case StoredWorkType.beat:
        return 'beat';
    }
  }

  static StoredWorkType typeFromString(
    String value,
  ) {
    switch (value.trim().toLowerCase()) {
      case 'lyrics':
        return StoredWorkType.lyrics;

      case 'beat':
        return StoredWorkType.beat;

      default:
        throw ArgumentError(
          'Tipo de obra inválido: $value',
        );
    }
  }

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'id': id,
      'original_author_user_id': originalAuthorUserId,
      'owner_user_id': ownerUserId,
      'type': typeToString(
        type,
      ),
      'title': title,
      'content_hash': contentHash,
      'hash_algorithm': hashAlgorithm,
      'version': version,
      'previous_hash': previousHash,
      'integrity_verified': integrityVerified,
      'lyrics_content': lyricsContent,
      'file_path': filePath,
      'file_name': fileName,
      'mime_type': mimeType,
      'file_size_bytes': fileSizeBytes,
      'bpm': bpm,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory StoredWorkModel.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return StoredWorkModel(
      id:
          map['id']?.toString() ??
          '',
      originalAuthorUserId:
          map['original_author_user_id']?.toString() ??
          '',
      ownerUserId:
          map['owner_user_id']?.toString() ??
          '',
      type: typeFromString(
        map['type']?.toString() ??
            '',
      ),
      title:
          map['title']?.toString() ??
          '',
      contentHash:
          map['content_hash']?.toString() ??
          '',
      hashAlgorithm:
          map['hash_algorithm']?.toString() ??
          'SHA-256',
      version: _parseInt(
        map['version'],
        fallback: 1,
      ),
      previousHash: map['previous_hash']?.toString(),
      integrityVerified: _parseBool(
        map['integrity_verified'],
      ),
      lyricsContent: map['lyrics_content']?.toString(),
      filePath: map['file_path']?.toString(),
      fileName: map['file_name']?.toString(),
      mimeType: map['mime_type']?.toString(),
      fileSizeBytes: _parseNullableInt(
        map['file_size_bytes'],
      ),
      bpm: _parseNullableInt(
        map['bpm'],
      ),
      createdAt: _parseDateTime(
        map['created_at'],
      ),
      updatedAt: _parseDateTime(
        map['updated_at'],
      ),
    );
  }

  StoredWorkModel copyWith({
    String? id,
    String? originalAuthorUserId,
    String? ownerUserId,
    StoredWorkType? type,
    String? title,
    String? contentHash,
    String? hashAlgorithm,
    int? version,
    String? previousHash,
    bool? integrityVerified,
    String? lyricsContent,
    String? filePath,
    String? fileName,
    String? mimeType,
    int? fileSizeBytes,
    int? bpm,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StoredWorkModel(
      id:
          id ??
          this.id,
      originalAuthorUserId:
          originalAuthorUserId ??
          this.originalAuthorUserId,
      ownerUserId:
          ownerUserId ??
          this.ownerUserId,
      type:
          type ??
          this.type,
      title:
          title ??
          this.title,
      contentHash:
          contentHash ??
          this.contentHash,
      hashAlgorithm:
          hashAlgorithm ??
          this.hashAlgorithm,
      version:
          version ??
          this.version,
      previousHash:
          previousHash ??
          this.previousHash,
      integrityVerified:
          integrityVerified ??
          this.integrityVerified,
      lyricsContent:
          lyricsContent ??
          this.lyricsContent,
      filePath:
          filePath ??
          this.filePath,
      fileName:
          fileName ??
          this.fileName,
      mimeType:
          mimeType ??
          this.mimeType,
      fileSizeBytes:
          fileSizeBytes ??
          this.fileSizeBytes,
      bpm:
          bpm ??
          this.bpm,
      createdAt:
          createdAt ??
          this.createdAt,
      updatedAt:
          updatedAt ??
          this.updatedAt,
    );
  }

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

  static int? _parseNullableInt(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    if (value
        is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  static bool _parseBool(
    dynamic value,
  ) {
    if (value
        is bool) {
      return value;
    }

    if (value
        is int) {
      return value ==
          1;
    }

    final normalized = value?.toString().trim().toLowerCase();

    return normalized ==
            'true' ||
        normalized ==
            '1';
  }

  static DateTime _parseDateTime(
    dynamic value,
  ) {
    if (value
        is DateTime) {
      return value;
    }

    return DateTime.tryParse(
          value?.toString() ??
              '',
        ) ??
        DateTime.fromMillisecondsSinceEpoch(
          0,
          isUtc: true,
        );
  }

  @override
  String toString() {
    return 'StoredWorkModel('
        'id: $id, '
        'type: ${typeToString(type)}, '
        'title: $title, '
        'version: $version, '
        'hash: $contentHash, '
        'verified: $integrityVerified'
        ')';
  }
}
