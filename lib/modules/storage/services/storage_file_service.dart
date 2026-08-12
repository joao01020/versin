import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

// ============================================================
// STORAGE FILE SERVICE
// ============================================================
//
// Responsabilidades:
//
// - selecionar arquivos de beat;
// - validar extensão;
// - validar existência;
// - obter nome;
// - obter extensão;
// - obter MIME type;
// - obter tamanho;
// - ler bytes quando necessário.
//
// NÃO é responsabilidade deste service:
//
// - gerar hash;
// - salvar no banco;
// - criar StoredWorkModel;
// - controlar UI;
// - transferir autoria.
//
// ============================================================

class StorageFileService {
  // ==========================================================
  // EXTENSÕES PERMITIDAS
  // ==========================================================

  static const List<
    String
  >
  allowedAudioExtensions = [
    'wav',
    'mp3',
    'flac',
    'aiff',
    'aif',
    'm4a',
    'ogg',
  ];

  // ==========================================================
  // TAMANHO MÁXIMO
  // ==========================================================
  //
  // 500 MB inicialmente.
  //
  // Isso pode ser alterado depois conforme o Storage real.
  //
  // ==========================================================

  static const int maxFileSizeBytes =
      500 *
      1024 *
      1024;

  // ==========================================================
  // SELECIONAR BEAT
  // ==========================================================

  Future<
    StorageFileInfo?
  >
  pickBeatFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,

      allowedExtensions: allowedAudioExtensions,

      allowMultiple: false,

      withData: false,

      withReadStream: false,
    );

    if (result ==
            null ||
        result.files.isEmpty) {
      return null;
    }

    final pickedFile = result.files.first;

    final path = pickedFile.path;

    if (path ==
            null ||
        path.trim().isEmpty) {
      throw StateError(
        'Não foi possível acessar o caminho do arquivo selecionado.',
      );
    }

    return inspectFile(
      path,
    );
  }

  // ==========================================================
  // ANALISAR ARQUIVO
  // ==========================================================

  Future<
    StorageFileInfo
  >
  inspectFile(
    String filePath,
  ) async {
    final normalizedPath = filePath.trim();

    if (normalizedPath.isEmpty) {
      throw ArgumentError(
        'O caminho do arquivo não pode ser vazio.',
      );
    }

    final file = File(
      normalizedPath,
    );

    final exists = await file.exists();

    if (!exists) {
      throw FileSystemException(
        'Arquivo não encontrado.',
        normalizedPath,
      );
    }

    final sizeBytes = await file.length();

    if (sizeBytes <=
        0) {
      throw StateError(
        'O arquivo selecionado está vazio.',
      );
    }

    if (sizeBytes >
        maxFileSizeBytes) {
      throw StateError(
        'O arquivo excede o limite permitido de ${formatFileSize(maxFileSizeBytes)}.',
      );
    }

    final fileName = _extractFileName(
      normalizedPath,
    );

    final extension = _extractExtension(
      fileName,
    );

    if (!isAllowedAudioExtension(
      extension,
    )) {
      throw StateError(
        'Formato de arquivo não permitido: .$extension',
      );
    }

    final mimeType = getMimeTypeFromExtension(
      extension,
    );

    return StorageFileInfo(
      path: normalizedPath,

      fileName: fileName,

      extension: extension,

      mimeType: mimeType,

      sizeBytes: sizeBytes,
    );
  }

  // ==========================================================
  // VALIDAR ARQUIVO DE ÁUDIO
  // ==========================================================

  Future<
    bool
  >
  isValidBeatFile(
    String filePath,
  ) async {
    try {
      await inspectFile(
        filePath,
      );

      return true;
    } catch (
      _
    ) {
      return false;
    }
  }

  // ==========================================================
  // LER BYTES
  // ==========================================================
  //
  // Use apenas quando realmente precisar dos bytes completos.
  //
  // Para hash de arquivos grandes, o StorageHashService usa
  // stream e é mais eficiente.
  //
  // ==========================================================

  Future<
    Uint8List
  >
  readBytes(
    String filePath,
  ) async {
    final info = await inspectFile(
      filePath,
    );

    final file = File(
      info.path,
    );

    return file.readAsBytes();
  }

  // ==========================================================
  // EXISTE
  // ==========================================================

  Future<
    bool
  >
  exists(
    String filePath,
  ) async {
    final normalizedPath = filePath.trim();

    if (normalizedPath.isEmpty) {
      return false;
    }

    return File(
      normalizedPath,
    ).exists();
  }

  // ==========================================================
  // TAMANHO
  // ==========================================================

  Future<
    int?
  >
  getFileSize(
    String filePath,
  ) async {
    final normalizedPath = filePath.trim();

    if (normalizedPath.isEmpty) {
      return null;
    }

    final file = File(
      normalizedPath,
    );

    if (!await file.exists()) {
      return null;
    }

    return file.length();
  }

  // ==========================================================
  // NOME DO ARQUIVO
  // ==========================================================

  String getFileName(
    String filePath,
  ) {
    return _extractFileName(
      filePath,
    );
  }

  // ==========================================================
  // EXTENSÃO
  // ==========================================================

  String getExtension(
    String filePath,
  ) {
    final fileName = _extractFileName(
      filePath,
    );

    return _extractExtension(
      fileName,
    );
  }

  // ==========================================================
  // VALIDAR EXTENSÃO
  // ==========================================================

  bool isAllowedAudioExtension(
    String extension,
  ) {
    final normalized = extension.trim().toLowerCase().replaceFirst(
      '.',
      '',
    );

    return allowedAudioExtensions.contains(
      normalized,
    );
  }

  // ==========================================================
  // MIME TYPE
  // ==========================================================

  String getMimeTypeFromExtension(
    String extension,
  ) {
    switch (extension.trim().toLowerCase().replaceFirst(
      '.',
      '',
    )) {
      case 'wav':
        return 'audio/wav';

      case 'mp3':
        return 'audio/mpeg';

      case 'flac':
        return 'audio/flac';

      case 'aiff':
      case 'aif':
        return 'audio/aiff';

      case 'm4a':
        return 'audio/mp4';

      case 'ogg':
        return 'audio/ogg';

      default:
        return 'application/octet-stream';
    }
  }

  // ==========================================================
  // SALVAR BEAT LOCALMENTE
  // ==========================================================

  Future<
    StorageFileInfo
  >
  saveBeatLocally({
    required String sourcePath,
    required String workId,
  }) async {
    final sourceInfo = await inspectFile(
      sourcePath,
    );

    final normalizedWorkId = workId.trim();

    if (normalizedWorkId.isEmpty) {
      throw ArgumentError(
        'workId não pode ser vazio.',
      );
    }

    final directory = await getLocalBeatsDirectory();

    final destinationPath = '${directory.path}/$normalizedWorkId.${sourceInfo.extension}';

    final destinationFile = File(
      destinationPath,
    );

    if (await destinationFile.exists()) {
      await destinationFile.delete();
    }

    await File(
      sourceInfo.path,
    ).copy(
      destinationPath,
    );

    return inspectFile(
      destinationPath,
    );
  }

  // ==========================================================
  // DIRETÓRIO LOCAL DOS BEATS
  // ==========================================================

  Future<
    Directory
  >
  getLocalBeatsDirectory() async {
    final home = Platform.environment['HOME'];

    if (home ==
            null ||
        home.trim().isEmpty) {
      throw StateError(
        'Não foi possível identificar o diretório HOME.',
      );
    }

    final directory = Directory(
      '$home/.local/share/versin/storage/beats',
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    return directory;
  }

  // ==========================================================
  // VERIFICAR ARQUIVO LOCAL
  // ==========================================================

  Future<
    bool
  >
  localFileExists(
    String filePath,
  ) async {
    return exists(
      filePath,
    );
  }

  // ==========================================================
  // APAGAR ARQUIVO LOCAL
  // ==========================================================

  Future<
    bool
  >
  deleteLocalFile(
    String filePath,
  ) async {
    final normalizedPath = filePath.trim();

    if (normalizedPath.isEmpty) {
      return false;
    }

    final file = File(
      normalizedPath,
    );

    if (!await file.exists()) {
      return false;
    }

    await file.delete();

    return true;
  }

  // ==========================================================
  // FORMATAR TAMANHO
  // ==========================================================

  String formatFileSize(
    int bytes,
  ) {
    if (bytes <
        1024) {
      return '$bytes B';
    }

    final kilobytes =
        bytes /
        1024;

    if (kilobytes <
        1024) {
      return '${kilobytes.toStringAsFixed(1)} KB';
    }

    final megabytes =
        kilobytes /
        1024;

    if (megabytes <
        1024) {
      return '${megabytes.toStringAsFixed(1)} MB';
    }

    final gigabytes =
        megabytes /
        1024;

    return '${gigabytes.toStringAsFixed(2)} GB';
  }

  // ==========================================================
  // EXTRAIR NOME
  // ==========================================================

  String _extractFileName(
    String filePath,
  ) {
    final normalized = filePath.replaceAll(
      '\\',
      '/',
    );

    final parts = normalized.split(
      '/',
    );

    if (parts.isEmpty) {
      return normalized;
    }

    return parts.last;
  }

  // ==========================================================
  // EXTRAIR EXTENSÃO
  // ==========================================================

  String _extractExtension(
    String fileName,
  ) {
    final index = fileName.lastIndexOf(
      '.',
    );

    if (index ==
            -1 ||
        index ==
            fileName.length -
                1) {
      return '';
    }

    return fileName
        .substring(
          index +
              1,
        )
        .trim()
        .toLowerCase();
  }
}

// ============================================================
// STORAGE FILE INFO
// ============================================================
//
// Representa os metadados básicos de um arquivo selecionado.
//
// Não representa uma obra registrada.
//
// O StoredWorkModel continua sendo o modelo persistido.
//
// ============================================================

class StorageFileInfo {
  final String path;

  final String fileName;

  final String extension;

  final String mimeType;

  final int sizeBytes;

  const StorageFileInfo({
    required this.path,
    required this.fileName,
    required this.extension,
    required this.mimeType,
    required this.sizeBytes,
  });

  // ==========================================================
  // HELPERS
  // ==========================================================

  bool get isAudio => mimeType.startsWith(
    'audio/',
  );

  // ==========================================================
  // TO MAP
  // ==========================================================

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'path': path,

      'file_name': fileName,

      'extension': extension,

      'mime_type': mimeType,

      'size_bytes': sizeBytes,
    };
  }

  // ==========================================================
  // DEBUG
  // ==========================================================

  @override
  String toString() {
    return 'StorageFileInfo('
        'fileName: $fileName, '
        'extension: $extension, '
        'mimeType: $mimeType, '
        'sizeBytes: $sizeBytes'
        ')';
  }
}
