// ============================================================
// STORED WORK TYPE
// ============================================================
//
// Define os tipos de obras que podem ser armazenadas.
//
// lyrics:
//   Letra / composição textual.
//
// beat:
//   Arquivo de áudio / beat.
//
// ============================================================

enum StoredWorkType {
  lyrics,
  beat,
}

// ============================================================
// STORED WORK MODEL
// ============================================================
//
// Representa uma obra registrada no armazenamento do Versin.
//
// Este model não possui responsabilidade de:
//
// - gerar hash;
// - salvar arquivos;
// - acessar banco de dados;
// - transferir propriedade;
// - verificar integridade.
//
// Essas responsabilidades pertencem aos services,
// repositories e controllers.
//
// ============================================================

class StoredWorkModel {
  // ==========================================================
  // IDENTIFICAÇÃO
  // ==========================================================

  final String id;

  // ==========================================================
  // USUÁRIO / AUTORIA
  // ==========================================================
  //
  // originalAuthorUserId:
  //   usuário que registrou originalmente a obra.
  //
  // ownerUserId:
  //   proprietário atual da obra dentro do sistema.
  //
  // No primeiro registro:
  //
  // originalAuthorUserId == ownerUserId
  //
  // Caso exista uma transferência futura:
  //
  // originalAuthorUserId permanece igual.
  // ownerUserId pode mudar.
  //
  // ==========================================================

  final String originalAuthorUserId;

  final String ownerUserId;

  // ==========================================================
  // TIPO
  // ==========================================================

  final StoredWorkType type;

  // ==========================================================
  // INFORMAÇÕES DA OBRA
  // ==========================================================

  final String title;

  // ==========================================================
  // HASH
  // ==========================================================
  //
  // Exemplo:
  //
  // hashAlgorithm = SHA-256
  //
  // contentHash =
  // 68f84d34b7c3...
  //
  // ==========================================================

  final String contentHash;

  final String hashAlgorithm;

  // ==========================================================
  // VERSÃO
  // ==========================================================
  //
  // Uma obra registrada nunca deve ser sobrescrita.
  //
  // Caso o artista altere a obra e registre novamente:
  //
  // versão 1
  // versão 2
  // versão 3
  //
  // previousHash permite relacionar a versão atual
  // com a versão anterior.
  //
  // ==========================================================

  final int version;

  final String? previousHash;

  // ==========================================================
  // INTEGRIDADE
  // ==========================================================

  final bool integrityVerified;

  // ==========================================================
  // LETRA
  // ==========================================================
  //
  // Usado somente quando:
  //
  // type == StoredWorkType.lyrics
  //
  // Futuramente esse conteúdo poderá ser armazenado
  // criptografado no backend.
  //
  // ==========================================================

  final String? lyricsContent;

  // ==========================================================
  // BEAT
  // ==========================================================
  //
  // Usado somente quando:
  //
  // type == StoredWorkType.beat
  //
  // O banco não precisa armazenar o arquivo inteiro.
  //
  // filePath aponta para o arquivo armazenado no Storage.
  //
  // ==========================================================

  final String? filePath;

  final String? fileName;

  final String? mimeType;

  final int? fileSizeBytes;

  // ==========================================================
  // METADADOS DO BEAT
  // ==========================================================

  final int? bpm;

  // ==========================================================
  // DATAS
  // ==========================================================

  final DateTime createdAt;

  final DateTime updatedAt;

  // ==========================================================
  // CONSTRUTOR
  // ==========================================================

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

  // ==========================================================
  // HELPERS DE TIPO
  // ==========================================================

  bool get isLyrics =>
      type ==
      StoredWorkType.lyrics;

  bool get isBeat =>
      type ==
      StoredWorkType.beat;

  // ==========================================================
  // POSSUI VERSÃO ANTERIOR
  // ==========================================================

  bool get hasPreviousVersion =>
      previousHash !=
          null &&
      previousHash!.isNotEmpty;

  // ==========================================================
  // POSSUI ARQUIVO
  // ==========================================================

  bool get hasFile =>
      filePath !=
          null &&
      filePath!.isNotEmpty;

  // ==========================================================
  // POSSUI CONTEÚDO DE LETRA
  // ==========================================================

  bool get hasLyricsContent =>
      lyricsContent !=
          null &&
      lyricsContent!.isNotEmpty;

  // ==========================================================
  // NOME DO TIPO
  // ==========================================================

  String get typeName {
    switch (type) {
      case StoredWorkType.lyrics:
        return 'Letra';

      case StoredWorkType.beat:
        return 'Beat';
    }
  }

  // ==========================================================
  // CONVERTER TYPE PARA STRING
  // ==========================================================
  //
  // Valor que será armazenado no banco:
  //
  // lyrics
  // beat
  //
  // ==========================================================

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

  // ==========================================================
  // CONVERTER STRING PARA TYPE
  // ==========================================================

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

  // ==========================================================
  // TO MAP
  // ==========================================================
  //
  // Formato preparado para persistência.
  //
  // Mantemos os nomes das colunas em snake_case,
  // enquanto o Dart continua usando camelCase.
  //
  // ==========================================================

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

  // ==========================================================
  // FROM MAP
  // ==========================================================

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

  // ==========================================================
  // COPY WITH
  // ==========================================================

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
  // PARSE NULLABLE INT
  // ==========================================================

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

  // ==========================================================
  // PARSE BOOL
  // ==========================================================

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
  // DEBUG
  // ==========================================================

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
