import 'package:flutter/material.dart';

import '../models/contribution_delivery_model.dart';

// ============================================================
// CONTRIBUTION DELIVERY WIDGET
// ============================================================
//
// Área de entrega de uma contribuição.
//
// Mostra:
//
// - arquivo;
// - versão;
// - tamanho;
// - SHA-256;
// - status;
// - upload;
// - download/abrir.
//
// Não acessa Storage diretamente.
//
// ============================================================

class ContributionDeliveryWidget
    extends
        StatelessWidget {
  final ContributionDeliveryModel? delivery;

  final bool canUpload;

  final bool isUploading;

  final double? uploadProgress;

  final VoidCallback? onUpload;

  final VoidCallback? onOpen;

  const ContributionDeliveryWidget({
    super.key,
    this.delivery,
    this.canUpload = false,
    this.isUploading = false,
    this.uploadProgress,
    this.onUpload,
    this.onOpen,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFF171717,
        ),
        borderRadius: BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.07,
          ),
        ),
      ),
      child:
          delivery ==
              null
          ? _buildEmpty()
          : _buildDelivery(),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.attach_file,
              color: Colors.white54,
              size: 18,
            ),
            SizedBox(
              width: 7,
            ),
            Text(
              'Entrega',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 10,
        ),

        const Text(
          'Nenhum arquivo foi enviado ainda.',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),

        if (canUpload) ...[
          const SizedBox(
            height: 12,
          ),
          _buildUploadButton(),
        ],
      ],
    );
  }

  // ============================================================
  // DELIVERY
  // ============================================================

  Widget _buildDelivery() {
    final currentDelivery = delivery!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================================
        // HEADER
        // ======================================================
        Row(
          children: [
            _buildFileIcon(
              currentDelivery,
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentDelivery.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    _buildFileMetadata(
                      currentDelivery,
                    ),
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            _buildStatus(
              currentDelivery,
            ),
          ],
        ),

        // ======================================================
        // HASH
        // ======================================================
        if (currentDelivery.hasHash) ...[
          const SizedBox(
            height: 12,
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(
                alpha: 0.22,
              ),
              borderRadius: BorderRadius.circular(
                8,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.fingerprint,
                  color: Colors.white38,
                  size: 15,
                ),

                const SizedBox(
                  width: 7,
                ),

                const Text(
                  'SHA-256',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: Text(
                    currentDelivery.shortHash,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // ======================================================
        // ACTIONS
        // ======================================================
        if (onOpen !=
                null ||
            canUpload) ...[
          const SizedBox(
            height: 12,
          ),
          Row(
            children: [
              if (onOpen !=
                  null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(
                      Icons.open_in_new,
                      size: 15,
                    ),
                    label: const Text(
                      'Abrir arquivo',
                      style: TextStyle(
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),

              if (onOpen !=
                      null &&
                  canUpload)
                const SizedBox(
                  width: 8,
                ),

              if (canUpload)
                Expanded(
                  child: _buildUploadButton(),
                ),
            ],
          ),
        ],
      ],
    );
  }

  // ============================================================
  // UPLOAD BUTTON
  // ============================================================

  Widget _buildUploadButton() {
    if (isUploading) {
      return Column(
        children: [
          LinearProgressIndicator(
            value: uploadProgress,
            minHeight: 3,
          ),
          const SizedBox(
            height: 7,
          ),
          const Text(
            'Enviando arquivo...',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
        ],
      );
    }

    return OutlinedButton.icon(
      onPressed: onUpload,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(
          0xFFE100FF,
        ),
        side: BorderSide(
          color:
              const Color(
                0xFFE100FF,
              ).withValues(
                alpha: 0.4,
              ),
        ),
      ),
      icon: const Icon(
        Icons.upload_file_outlined,
        size: 16,
      ),
      label: Text(
        delivery ==
                null
            ? 'Enviar arquivo'
            : 'Nova versão',
        style: const TextStyle(
          fontSize: 11,
        ),
      ),
    );
  }

  // ============================================================
  // FILE ICON
  // ============================================================

  Widget _buildFileIcon(
    ContributionDeliveryModel delivery,
  ) {
    IconData icon;

    if (delivery.isAudio) {
      icon = Icons.audio_file_outlined;
    } else if (delivery.isImage) {
      icon = Icons.image_outlined;
    } else if (delivery.isDocument) {
      icon = Icons.description_outlined;
    } else {
      icon = Icons.insert_drive_file_outlined;
    }

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color:
            const Color(
              0xFFE100FF,
            ).withValues(
              alpha: 0.08,
            ),
        borderRadius: BorderRadius.circular(
          9,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: const Color(
          0xFFE100FF,
        ),
        size: 20,
      ),
    );
  }

  // ============================================================
  // METADATA
  // ============================================================

  String _buildFileMetadata(
    ContributionDeliveryModel delivery,
  ) {
    final values =
        <
          String
        >[
          'v${delivery.version}',
        ];

    if (delivery.formattedFileSize.isNotEmpty) {
      values.add(
        delivery.formattedFileSize,
      );
    }

    if (delivery.fileExtension.isNotEmpty) {
      values.add(
        delivery.fileExtension.toUpperCase(),
      );
    }

    return values.join(
      ' • ',
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _buildStatus(
    ContributionDeliveryModel delivery,
  ) {
    late final String label;
    late final IconData icon;
    late final Color color;

    switch (delivery.status) {
      case ContributionDeliveryStatus.submitted:
        label = 'Enviado';
        icon = Icons.schedule;
        color = Colors.amberAccent;

      case ContributionDeliveryStatus.validating:
        label = 'Validando';
        icon = Icons.sync;
        color = Colors.lightBlueAccent;

      case ContributionDeliveryStatus.validated:
        label = 'Validado';
        icon = Icons.verified_outlined;
        color = Colors.greenAccent;

      case ContributionDeliveryStatus.rejected:
        label = 'Revisar';
        icon = Icons.error_outline;
        color = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: color,
          ),
          const SizedBox(
            width: 4,
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
