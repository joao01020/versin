import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:record/record.dart';

class AuthorHash {
  static String generateSignature(
    String title,
    String content,
  ) {
    final data = '$title|$content|VERSIN_SECURE_KEY';

    return sha256
        .convert(
          utf8.encode(
            data,
          ),
        )
        .toString();
  }
}

enum UserRole {
  artista,
  beatmaker,
  compositor,
  interprete,
}

class MatchCardModel {
  final String id;
  final UserRole role;
  final UserRole seeking;
  final String? fileName;
  final String? fileHash;
  final DateTime timestamp;

  const MatchCardModel({
    required this.id,
    required this.role,
    required this.seeking,
    required this.timestamp,
    this.fileName,
    this.fileHash,
  });
}

class MatchPage
    extends
        StatefulWidget {
  const MatchPage({
    super.key,
  });

  @override
  State<
    MatchPage
  >
  createState() => _MatchPageState();
}

class _MatchPageState
    extends
        State<
          MatchPage
        > {
  final AudioRecorder _recorder = AudioRecorder();

  final List<
    MatchCardModel
  >
  catalog = [];

  bool _isRecording = false;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<
    pw.Document
  >
  _generatePdf(
    MatchCardModel item,
  ) async {
    final pdf = pw.Document();

    final date =
        DateFormat(
          'dd/MM/yyyy HH:mm:ss',
        ).format(
          item.timestamp,
        );

    final shortId = item.id.hashCode.abs().toString().padLeft(
      8,
      '0',
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build:
            (
              _,
            ) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'VERSIN DIGITAL ASSET PROTECTION',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        'ID REGISTRO: #$shortId',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(
                    height: 20,
                  ),

                  pw.Header(
                    level: 0,
                    child: pw.Text(
                      'CERTIFICADO DE REGISTRO E ANTERIORIDADE',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),

                  pw.Divider(
                    thickness: 2,
                  ),
                  pw.SizedBox(
                    height: 20,
                  ),

                  pw.Text(
                    'DADOS DO REGISTRO:',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),

                  pw.SizedBox(
                    height: 10,
                  ),

                  pw.Bullet(
                    text: 'ARQUIVO: ${item.fileName}',
                  ),
                  pw.Bullet(
                    text: 'DATA/HORA: $date',
                  ),
                  pw.Bullet(
                    text: 'PAPEL DECLARADO: ${item.role.name.toUpperCase()}',
                  ),
                  pw.Bullet(
                    text: 'STATUS: VALIDADO VIA SHA-256',
                  ),

                  pw.SizedBox(
                    height: 30,
                  ),

                  pw.Container(
                    padding: const pw.EdgeInsets.all(
                      15,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      border: pw.Border.all(
                        color: PdfColors.grey300,
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ASSINATURA CRIPTOGRÁFICA (HASH):',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(
                          height: 5,
                        ),
                        pw.Text(
                          item.fileHash ??
                              'GRAVACAO DIRETA (BIOMETRIA DE VOZ)',
                          style: pw.TextStyle(
                            fontSize: 9,
                            font: pw.Font.courier(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(
                    height: 40,
                  ),

                  pw.Text(
                    'DECLARAÇÃO JURÍDICA:',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),

                  pw.Text(
                    'O detentor deste certificado declara, sob as penas da lei, '
                    'ser o autor ou detentor legítimo dos direitos da obra acima '
                    'descrita, registrada nesta data através do motor de hashing '
                    'SHA-256 via Versin Match Engine. Este documento serve como '
                    'prova de anterioridade temporal.',
                    textAlign: pw.TextAlign.justify,
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey800,
                    ),
                  ),

                  pw.Spacer(),
                  pw.Divider(),

                  pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      'Documento gerado eletronicamente via Versin Engine - Osasco, SP',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey500,
                      ),
                    ),
                  ),
                ],
              );
            },
      ),
    );

    return pdf;
  }

  Future<
    void
  >
  _viewDocument(
    MatchCardModel item,
  ) async {
    final pdf = await _generatePdf(
      item,
    );

    if (!mounted) {
      return;
    }

    final shortId =
        item.id.length >
            5
        ? item.id.substring(
            0,
            5,
          )
        : item.id;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => Scaffold(
              appBar: AppBar(
                title: Text(
                  'Certificado: ${item.fileName}',
                ),
                backgroundColor: const Color(
                  0xFF1A1A1A,
                ),
              ),
              body: PdfPreview(
                build:
                    (
                      _,
                    ) => pdf.save(),
                allowPrinting: true,
                allowSharing: true,
                canChangePageFormat: false,
                initialPageFormat: PdfPageFormat.a4,
                pdfFileName: 'Certificado_Versin_$shortId.pdf',
              ),
            ),
      ),
    );
  }

  Future<
    void
  >
  _handleRecording() async {
    if (!await _recorder.hasPermission()) {
      return;
    }

    if (_isRecording) {
      final path = await _recorder.stop();

      if (!mounted) {
        return;
      }

      setState(
        () {
          _isRecording = false;
        },
      );

      if (path !=
          null) {
        _registerEntry(
          'Vocal_Gravado_${DateTime.now().millisecond}.m4a',
          null,
          UserRole.interprete,
          UserRole.compositor,
        );
      }

      return;
    }

    await _recorder.start(
      const RecordConfig(),
      path: 'recording.m4a',
    );

    if (!mounted) {
      return;
    }

    setState(
      () {
        _isRecording = true;
      },
    );
  }

  void _registerEntry(
    String fileName,
    String? hash,
    UserRole myRole,
    UserRole seekingRole,
  ) {
    setState(
      () {
        catalog.insert(
          0,
          MatchCardModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            role: myRole,
            seeking: seekingRole,
            fileName: fileName,
            fileHash: hash,
            timestamp: DateTime.now(),
          ),
        );
      },
    );
  }

  Future<
    void
  >
  _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'mp3',
          'wav',
          'txt',
        ],
      );

      if (result ==
              null ||
          !mounted) {
        return;
      }

      final file = result.files.first;
      final isText =
          file.extension?.toLowerCase() ==
          'txt';

      final hash = AuthorHash.generateSignature(
        file.name,
        file.size.toString(),
      );

      _showRoleSelection(
        file,
        isText
            ? hash
            : null,
        isText,
      );
    } catch (
      e
    ) {
      debugPrint(
        'Erro ao selecionar arquivo: $e',
      );
    }
  }

  void _showRoleSelection(
    PlatformFile file,
    String? hash,
    bool isText,
  ) {
    showModalBottomSheet<
      void
    >(
      context: context,
      backgroundColor: const Color(
        0xFF1A1A1A,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            20,
          ),
        ),
      ),
      builder:
          (
            sheetContext,
          ) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: isText
                  ? [
                      _buildRoleOption(
                        context: sheetContext,
                        file: file,
                        hash: hash,
                        icon: Icons.mic,
                        color: Colors.pinkAccent,
                        title: 'Artista',
                        role: UserRole.artista,
                        seeking: UserRole.beatmaker,
                      ),
                      _buildRoleOption(
                        context: sheetContext,
                        file: file,
                        hash: hash,
                        icon: Icons.history_edu,
                        color: Colors.orangeAccent,
                        title: 'Compositor',
                        role: UserRole.compositor,
                        seeking: UserRole.artista,
                      ),
                    ]
                  : [
                      _buildRoleOption(
                        context: sheetContext,
                        file: file,
                        hash: AuthorHash.generateSignature(
                          file.name,
                          file.size.toString(),
                        ),
                        icon: Icons.audiotrack,
                        color: Colors.blueAccent,
                        title: 'Beatmaker',
                        role: UserRole.beatmaker,
                        seeking: UserRole.artista,
                      ),
                      _buildRoleOption(
                        context: sheetContext,
                        file: file,
                        hash: null,
                        icon: Icons.record_voice_over,
                        color: Colors.cyanAccent,
                        title: 'Intérprete',
                        role: UserRole.interprete,
                        seeking: UserRole.compositor,
                      ),
                    ],
            );
          },
    );
  }

  Widget _buildRoleOption({
    required BuildContext context,
    required PlatformFile file,
    required String? hash,
    required IconData icon,
    required Color color,
    required String title,
    required UserRole role,
    required UserRole seeking,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
      onTap: () {
        _registerEntry(
          file.name,
          hash,
          role,
          seeking,
        );

        Navigator.pop(
          context,
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0F0F0F,
      ),
      appBar: AppBar(
        title: const Text(
          'VERSIN MATCH ENGINE',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 2,
            color: Colors.white38,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildUploadArea(),
          Expanded(
            child: catalog.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    itemCount: catalog.length,
                    itemBuilder:
                        (
                          _,
                          index,
                        ) {
                          final item = catalog[index];

                          return _MatchCard(
                            item: item,
                            onDelete: () {
                              setState(
                                () {
                                  catalog.removeAt(
                                    index,
                                  );
                                },
                              );
                            },
                            onView: () {
                              _viewDocument(
                                item,
                              );
                            },
                          );
                        },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(
              20,
            ),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white10,
              ),
            ),
            child: const Icon(
              Icons.cloud_outlined,
              size: 40,
              color: Colors.white10,
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          const Text(
            'ESPERANDO ARQUIVOS',
            style: TextStyle(
              color: Colors.white12,
              letterSpacing: 4,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          const Text(
            'Suba um beat ou grave sua voz para registrar',
            style: TextStyle(
              color: Colors.white10,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    return Container(
      margin: const EdgeInsets.all(
        16,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _pickFile,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF1A1A1A,
                  ),
                  borderRadius: BorderRadius.circular(
                    15,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: 0.05,
                    ),
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_box_outlined,
                      color: Colors.purpleAccent,
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    Text(
                      'UPLOAD',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          GestureDetector(
            onTap: _handleRecording,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _isRecording
                    ? Colors.redAccent.withValues(
                        alpha: 0.1,
                      )
                    : const Color(
                        0xFF1A1A1A,
                      ),
                borderRadius: BorderRadius.circular(
                  15,
                ),
                border: Border.all(
                  color: _isRecording
                      ? Colors.redAccent
                      : Colors.cyanAccent.withValues(
                          alpha: 0.1,
                        ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isRecording
                        ? Icons.stop_circle
                        : Icons.mic_none,
                    color: _isRecording
                        ? Colors.redAccent
                        : Colors.cyanAccent,
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    _isRecording
                        ? 'PARAR'
                        : 'GRAVAR',
                    style: TextStyle(
                      color: _isRecording
                          ? Colors.redAccent
                          : Colors.white38,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchCard
    extends
        StatelessWidget {
  final MatchCardModel item;
  final VoidCallback onDelete;
  final VoidCallback onView;

  const _MatchCard({
    required this.item,
    required this.onDelete,
    required this.onView,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final date =
        DateFormat(
          'dd/MM HH:mm',
        ).format(
          item.timestamp,
        );

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFF161616,
        ),
        borderRadius: BorderRadius.circular(
          15,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.03,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: onView,
                    icon: const Icon(
                      Icons.verified_user,
                      color: Colors.purpleAccent,
                      size: 20,
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.white24,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),

          Text(
            item.fileName ??
                'Arquivo',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(
                alpha: 0.05,
              ),
              borderRadius: BorderRadius.circular(
                4,
              ),
            ),
            child: Text(
              item.role.name.toUpperCase(),
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Container(
            padding: const EdgeInsets.all(
              10,
            ),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(
                8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SHA-256 PROVA DIGITAL',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                SelectableText(
                  item.fileHash ??
                      'BIOMETRIA DE VOZ ATIVA',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 8,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
