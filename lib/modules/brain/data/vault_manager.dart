import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:versin/core/models/rhyme_model.dart';

class VaultManager {
  /// Importa rimas a partir de arquivos .md ou .txt no formato Obsidian
  static Future<
    List<
      String
    >
  >
  importFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'md',
          'txt',
        ],
      );

      if (result !=
              null &&
          result.files.single.path !=
              null) {
        final file = File(
          result.files.single.path!,
        );
        final content = await file.readAsString();

        // Remove caracteres especiais de markdown e separa por quebra de linha
        return content
            .split(
              RegExp(
                r'[\n\r]',
              ),
            )
            .map(
              (
                line,
              ) => line
                  .replaceAll(
                    RegExp(
                      r'[#*-]',
                    ),
                    '',
                  )
                  .trim(),
            )
            .where(
              (
                line,
              ) => line.isNotEmpty,
            )
            .toList();
      }
    } catch (
      e
    ) {
      return [];
    }
    return [];
  }

  /// Exporta o vocabulário atual para um arquivo .md (Vault Backup)
  static Future<
    String?
  >
  exportToBackup(
    List<
      Rhyme
    >
    vocabulary,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String path = '${directory.path}/versin_vault_backup.md';
      final File file = File(
        path,
      );

      // Cria um conteúdo formatado como arquivo de notas
      final String content =
          '# VERSIN VAULT BACKUP\n\n' +
          vocabulary
              .map(
                (
                  r,
                ) => '- ${r.word}',
              )
              .join(
                '\n',
              );

      await file.writeAsString(
        content,
      );
      return path;
    } catch (
      e
    ) {
      return null;
    }
  }

  /// Método utilitário para ler uma nota específica do Vault
  static Future<
    String
  >
  readNote(
    String fileName,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/$fileName.md',
      );
      return await file.readAsString();
    } catch (
      e
    ) {
      return "Nota não encontrada.";
    }
  }
}
