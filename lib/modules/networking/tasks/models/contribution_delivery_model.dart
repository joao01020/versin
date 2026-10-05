// ============================================================
// CONTRIBUTION DELIVERY STATUS
// ============================================================
//
// submitted
//     ↓
// validating
//     ↓
// validated
//
// Uma entrega também poderá ser rejeitada e gerar nova versão.
//
// ============================================================

enum ContributionDeliveryStatus {
  submitted,
  validating,
  validated,
  rejected,
}

// ============================================================
// CONTRIBUTION DELIVERY MODEL
// ============================================================
//
// Representa um arquivo entregue como resultado de uma
// contribuição.
//
// Exemplo:
//
// beat_master.wav
// Versão 1
// SHA-256 af82c1...8b921e
//
// O arquivo físico fica no Supabase Storage.
//
// O banco guarda:
//
// - quem enviou;
// - contribuição;
// - nome;
// - caminho;
// - tamanho;
// - MIME;
// - versão;
// - SHA-256;
// - status;
// - timestamps.
//
// ============================================================

class ContributionDeliveryModel {
  // ============================================================
  // IDENTIDADE
  // ============================================================

  final String id;

  // ============================================================
  // CONTRIBUTION
  // ============================================================

  final String contributionId;

  // ============================================================
  // UPLOADER
  // ============================================================

  final String uploadedBy;

  // ============================================================
  // FILE
  // ============================================================

  final String fileName;

  final String storagePath;

  final String? mimeType;

  final int? fileSize;

  // ============================================================
  // INTEGRITY
  // ============================================================
  //
  // SHA-256 do conteúdo real do arquivo.
  //
  // Não deve ser usado como "prova automática de autoria".
  //
  // Ele identifica de forma verificável os bytes que foram
  // registrados naquela entrega.
  //
  // ============================================================

  final String? sha256;

  // ============================================================
  // VERSION
  // ============================================================

  final int version;

  // ============================================================
  // STATUS
  // ============================================================

  final ContributionDeliveryStatus status;

  // ============================================================
  // TIMESTAMPS
  // ============================================================

  final DateTime createdAt;

  final DateTime? validatedAt;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const ContributionDeliveryModel({
    required this.id,
    required this.contributionId,
    required this.uploadedBy,
    required this.fileName,
    required this.storagePath,
    required this.version,
    required this.status,
    required this.createdAt,
    this.mimeType,
    this.fileSize,
    this.sha256,
    this.validatedAt,
  });

  // ============================================================
  // STATUS HELPERS
  // ============================================================

  bool get isSubmitted {
    return status ==
        ContributionDeliveryStatus.submitted;
  }

  bool get isValidating {
    return status ==
        ContributionDeliveryStatus.validating;
  }

  bool get isValidated {
    return status ==
        ContributionDeliveryStatus.validated;
  }

  bool get isRejected {
    return status ==
        ContributionDeliveryStatus.rejected;
  }

  // ============================================================
  // FILE HELPERS
  // ============================================================

  bool get hasFile {
    return fileName.trim().isNotEmpty &&
        storagePath.trim().isNotEmpty;
  }

  bool get hasMimeType {
    return mimeType?.trim().isNotEmpty ==
        true;
  }

  bool get hasHash {
    return sha256?.trim().isNotEmpty ==
        true;
  }

  bool get hasFileSize {
    return fileSize !=
            null &&
        fileSize! >
            0;
  }

  bool get hasBeenValidated {
    return validatedAt !=
            null &&
        isValidated;
  }

  // ============================================================
  // FILE EXTENSION
  // ============================================================

  String get fileExtension {
    final normalized = fileName.trim();

    final index = normalized.lastIndexOf(
      '.',
    );

    if (index <
            0 ||
        index ==
            normalized.length -
                1) {
      return '';
    }

    return normalized
        .substring(
          index +
              1,
        )
        .toLowerCase();
  }

  // ============================================================
  // FILE TYPE HELPERS
  // ============================================================

  bool get isAudio {
    final mime = mimeType?.trim().toLowerCase();

    if (mime?.startsWith(
          'audio/',
        ) ==
        true) {
      return true;
    }

    const extensions =
        <
          String
        >{
          'wav',
          'mp3',
          'flac',
          'aac',
          'm4a',
          'ogg',
          'aiff',
          'aif',
        };

    return extensions.contains(
      fileExtension,
    );
  }

  bool get isImage {
    final mime = mimeType?.trim().toLowerCase();

    if (mime?.startsWith(
          'image/',
        ) ==
        true) {
      return true;
    }

    const extensions =
        <
          String
        >{
          'png',
          'jpg',
          'jpeg',
          'webp',
          'gif',
        };

    return extensions.contains(
      fileExtension,
    );
  }

  bool get isDocument {
    final mime = mimeType?.trim().toLowerCase();

    if (mime ==
            'application/pdf' ||
        mime ==
            'text/plain') {
      return true;
    }

    const extensions =
        <
          String
        >{
          'pdf',
          'txt',
          'doc',
          'docx',
        };

    return extensions.contains(
      fileExtension,
    );
  }

  // ============================================================
  // HUMAN FILE SIZE
  // ============================================================

  String get formattedFileSize {
    final bytes = fileSize;

    if (bytes ==
            null ||
        bytes <=
            0) {
      return '';
    }

    if (bytes <
        1024) {
      return '$bytes B';
    }

    final kb =
        bytes /
        1024;

    if (kb <
        1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }

    final mb =
        kb /
        1024;

    if (mb <
        1024) {
      return '${mb.toStringAsFixed(1)} MB';
    }

    final gb =
        mb /
        1024;

    return '${gb.toStringAsFixed(2)} GB';
  }

  // ============================================================
  // SHORT HASH
  // ============================================================

  String get shortHash {
    final normalized =
        sha256?.trim() ??
        '';

    if (normalized.isEmpty) {
      return '';
    }

    if (normalized.length <=
        16) {
      return normalized;
    }

    return '${normalized.substring(0, 8)}'
        '...'
        '${normalized.substring(normalized.length - 8)}';
  }

  // ============================================================
  // STATUS DATABASE VALUE
  // ============================================================

  String get statusDatabaseValue {
    switch (status) {
      case ContributionDeliveryStatus.submitted:
        return 'submitted';

      case ContributionDeliveryStatus.validating:
        return 'validating';

      case ContributionDeliveryStatus.validated:
        return 'validated';

      case ContributionDeliveryStatus.rejected:
        return 'rejected';
    }
  }

  // ============================================================
  // STATUS FROM DATABASE
  // ============================================================

  static ContributionDeliveryStatus statusFromDatabase(
    String? value,
  ) {
    switch (value?.trim().toLowerCase()) {
      case 'validating':
        return ContributionDeliveryStatus.validating;

      case 'validated':
        return ContributionDeliveryStatus.validated;

      case 'rejected':
        return ContributionDeliveryStatus.rejected;

      case 'submitted':
      default:
        return ContributionDeliveryStatus.submitted;
    }
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  ContributionDeliveryModel copyWith({
    String? id,
    String? contributionId,
    String? uploadedBy,
    String? fileName,
    String? storagePath,
    String? mimeType,
    int? fileSize,
    String? sha256,
    int? version,
    ContributionDeliveryStatus? status,
    DateTime? createdAt,
    DateTime? validatedAt,
    bool clearMimeType = false,
    bool clearFileSize = false,
    bool clearSha256 = false,
    bool clearValidatedAt = false,
  }) {
    return ContributionDeliveryModel(
      id:
          id ??
          this.id,
      contributionId:
          contributionId ??
          this.contributionId,
      uploadedBy:
          uploadedBy ??
          this.uploadedBy,
      fileName:
          fileName ??
          this.fileName,
      storagePath:
          storagePath ??
          this.storagePath,
      mimeType: clearMimeType
          ? null
          : mimeType ??
                this.mimeType,
      fileSize: clearFileSize
          ? null
          : fileSize ??
                this.fileSize,
      sha256: clearSha256
          ? null
          : sha256 ??
                this.sha256,
      version:
          version ??
          this.version,
      status:
          status ??
          this.status,
      createdAt:
          createdAt ??
          this.createdAt,
      validatedAt: clearValidatedAt
          ? null
          : validatedAt ??
                this.validatedAt,
    );
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
            is ContributionDeliveryModel &&
        other.id ==
            id &&
        other.version ==
            version;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      version,
    );
  }

  // ============================================================
  // TO STRING
  // ============================================================

  @override
  String toString() {
    return 'ContributionDeliveryModel('
        'id: $id, '
        'contributionId: $contributionId, '
        'fileName: $fileName, '
        'version: $version, '
        'status: $statusDatabaseValue'
        ')';
  }
}
