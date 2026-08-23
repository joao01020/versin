import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

// ============================================================
// PICKED PROFILE TRACK
// ============================================================
//
// Resultado independente do FilePicker.
//
// Isso evita que UI/controller precisem conhecer PlatformFile.
//
// ============================================================

class PickedProfileTrack {
  final String fileName;

  final Uint8List bytes;

  final int fileSizeBytes;

  final String? extension;

  final String? mimeType;

  const PickedProfileTrack({
    required this.fileName,
    required this.bytes,
    required this.fileSizeBytes,
    this.extension,
    this.mimeType,
  });
}

// ============================================================
// PROFILE TRACK PICKER SERVICE
// ============================================================
//
// Responsável somente por:
//
// - abrir seletor;
// - aceitar um único áudio;
// - validar extensão;
// - carregar bytes;
// - descobrir MIME básico.
//
// NÃO:
//
// - envia para Supabase;
// - cria ProfileTrackModel;
// - altera controller.
//
// ============================================================

class ProfileTrackPickerService {
  // ============================================================
  // EXTENSÕES
  // ============================================================

  static const List<String> supportedExtensions = <String>[
    'mp3',
    'wav',
    'm4a',
    'aac',
    'ogg',
  ];

  // ============================================================
  // TAMANHO MÁXIMO
  // ============================================================
  //
  // Primeira versão:
  //
  // máximo 25 MB por demo.
  //
  // ============================================================

  static const int maxFileSizeBytes = 25 * 1024 * 1024;

  // ============================================================
  // PICK
  // ============================================================

  Future<PickedProfileTrack?> pickTrack() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Selecionar demo',
      type: FileType.custom,
      allowedExtensions: supportedExtensions,
      allowMultiple: false,
      withData: true,
      lockParentWindow: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;

    final bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) {
      throw StateError('Não foi possível ler o arquivo selecionado.');
    }

    if (file.size > maxFileSizeBytes) {
      throw StateError('A demo pode ter no máximo 25 MB.');
    }

    final extension = file.extension?.trim().toLowerCase();

    if (extension == null || !supportedExtensions.contains(extension)) {
      throw StateError('Formato de áudio não suportado.');
    }

    return PickedProfileTrack(
      fileName: file.name,
      bytes: bytes,
      fileSizeBytes: file.size,
      extension: extension,
      mimeType: _resolveMimeType(extension),
    );
  }

  // ============================================================
  // MIME
  // ============================================================

  String? _resolveMimeType(String extension) {
    switch (extension) {
      case 'mp3':
        return 'audio/mpeg';

      case 'wav':
        return 'audio/wav';

      case 'm4a':
        return 'audio/mp4';

      case 'aac':
        return 'audio/aac';

      case 'ogg':
        return 'audio/ogg';

      default:
        return null;
    }
  }
}
