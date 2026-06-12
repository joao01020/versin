import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Class responsible for handling external file operations for the library
class RhymeLibraryManager {
  /// Opens the file picker and parses .txt or .md files into a list of strings
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
          'txt',
          'md',
        ],
      );

      if (result !=
              null &&
          result.files.single.path !=
              null) {
        final file = File(
          result.files.single.path!,
        );
        final String content = await file.readAsString();

        // Splits content by common delimiters (newline, comma, semicolon)
        return content
            .split(
              RegExp(
                r'[,\n;]',
              ),
            )
            .map(
              (
                item,
              ) => item.trim(),
            )
            .where(
              (
                item,
              ) => item.isNotEmpty,
            )
            .toList();
      }
    } catch (
      e
    ) {
      // In a real production app, consider logging this error
      return [];
    }
    return [];
  }

  /// Exports the current vocabulary list to a backup file in the device's downloads folder
  static Future<
    String?
  >
  exportToBackup(
    List<
      dynamic
    >
    vocabulary,
  ) async {
    try {
      final Directory? downloadsDir = await getDownloadsDirectory();
      if (downloadsDir ==
          null)
        return null;

      final String path = "${downloadsDir.path}/versin_backup_${DateTime.now().millisecondsSinceEpoch}.txt";
      final File file = File(
        path,
      );

      StringBuffer buffer = StringBuffer();
      buffer.writeln(
        "--- BACKUP VERSIN: VOCABULÁRIO ---\n",
      );
      for (var entry in vocabulary) {
        buffer.writeln(
          entry.word,
        );
      }

      await file.writeAsString(
        buffer.toString(),
      );
      return path;
    } catch (
      e
    ) {
      return null;
    }
  }
}
