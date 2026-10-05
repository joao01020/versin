import 'package:flutter/material.dart';

import '../data/models/stored_work_model.dart';

class StorageDetailsPage
    extends
        StatelessWidget {
  final StoredWorkModel work;

  final Color accentColor;

  const StorageDetailsPage({
    super.key,
    required this.work,
    required this.accentColor,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0D0B1F,
      ),
      appBar: AppBar(
        backgroundColor: const Color(
          0xFF0D0B1F,
        ),
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Detalhes da obra',
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(
                0xFF17132D,
              ),
              Color(
                0xFF0D0B1F,
              ),
              Colors.black,
            ],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(
            20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(
                height: 20,
              ),

              _buildSection(
                title: 'Registro',
                children: [
                  _buildInfoRow(
                    label: 'Tipo',
                    value: work.typeName,
                  ),
                  _buildInfoRow(
                    label: 'Versão',
                    value: work.version.toString(),
                  ),
                  _buildInfoRow(
                    label: 'Algoritmo',
                    value: work.hashAlgorithm,
                  ),
                  _buildInfoRow(
                    label: 'Integridade',
                    value: work.integrityVerified
                        ? 'Verificada'
                        : 'Não verificada',
                    valueColor: work.integrityVerified
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                  ),
                ],
              ),

              const SizedBox(
                height: 16,
              ),

              _buildSection(
                title: 'Hash da obra',
                children: [
                  SelectableText(
                    work.contentHash,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 16,
              ),

              _buildSection(
                title: 'Autoria',
                children: [
                  _buildInfoRow(
                    label: 'Autor original',
                    value: work.originalAuthorUserId,
                  ),
                  _buildInfoRow(
                    label: 'Proprietário atual',
                    value: work.ownerUserId,
                  ),
                ],
              ),

              const SizedBox(
                height: 16,
              ),

              if (work.isLyrics) _buildLyricsSection(),

              if (work.isBeat) _buildBeatSection(),

              const SizedBox(
                height: 16,
              ),

              _buildSection(
                title: 'Datas',
                children: [
                  _buildInfoRow(
                    label: 'Registrada em',
                    value: _formatDateTime(
                      work.createdAt,
                    ),
                  ),
                  _buildInfoRow(
                    label: 'Atualizada em',
                    value: _formatDateTime(
                      work.updatedAt,
                    ),
                  ),
                ],
              ),

              if (work.hasPreviousVersion) ...[
                const SizedBox(
                  height: 16,
                ),
                _buildSection(
                  title: 'Versão anterior',
                  children: [
                    SelectableText(
                      work.previousHash!,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(
                height: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.045,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: accentColor.withValues(
            alpha: 0.14,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: accentColor.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(
                16,
              ),
            ),
            child: Icon(
              work.isBeat
                  ? Icons.graphic_eq_rounded
                  : Icons.description_outlined,
              color: accentColor,
              size: 26,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  work.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  '${work.typeName} • Versão ${work.version}',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          if (work.integrityVerified)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(
                  alpha: 0.08,
                ),
                borderRadius: BorderRadius.circular(
                  20,
                ),
                border: Border.all(
                  color: Colors.greenAccent.withValues(
                    alpha: 0.20,
                  ),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: Colors.greenAccent,
                    size: 14,
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Text(
                    'Íntegro',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // LETRA
  // ============================================================

  Widget _buildLyricsSection() {
    return _buildSection(
      title: 'Letra',
      children: [
        if (work.hasLyricsContent)
          SelectableText(
            work.lyricsContent!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.6,
            ),
          )
        else
          const Text(
            'Conteúdo indisponível.',
            style: TextStyle(
              color: Colors.white38,
            ),
          ),
      ],
    );
  }

  // ============================================================
  // BEAT
  // ============================================================

  Widget _buildBeatSection() {
    return _buildSection(
      title: 'Arquivo',
      children: [
        _buildInfoRow(
          label: 'Arquivo',
          value:
              work.fileName ??
              'Não informado',
        ),

        _buildInfoRow(
          label: 'Formato',
          value:
              work.mimeType ??
              'Não informado',
        ),

        if (work.fileSizeBytes !=
            null)
          _buildInfoRow(
            label: 'Tamanho',
            value: _formatFileSize(
              work.fileSizeBytes!,
            ),
          ),

        if (work.bpm !=
            null)
          _buildInfoRow(
            label: 'BPM',
            value: work.bpm.toString(),
          ),

        if (work.filePath !=
            null)
          _buildInfoRow(
            label: 'Caminho',
            value: work.filePath!,
          ),
      ],
    );
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _buildSection({
    required String title,
    required List<
      Widget
    >
    children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.035,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: accentColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _buildInfoRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
          ),

          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                color:
                    valueColor ??
                    Colors.white70,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDateTime(
    DateTime value,
  ) {
    final date = value.toLocal();

    final day = date.day.toString().padLeft(
      2,
      '0',
    );

    final month = date.month.toString().padLeft(
      2,
      '0',
    );

    final hour = date.hour.toString().padLeft(
      2,
      '0',
    );

    final minute = date.minute.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month/${date.year} '
        '$hour:$minute';
  }

  // ============================================================
  // FILE SIZE
  // ============================================================

  String _formatFileSize(
    int bytes,
  ) {
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
}
