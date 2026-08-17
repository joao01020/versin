import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

import 'package:versin/app/locator.dart';

import '../../controllers/storage_controller.dart';
import '../../data/models/stored_work_model.dart';
import '../../services/storage_file_service.dart';
import '../../services/storage_hash_service.dart';
import '../../services/work_storage_service.dart';

// ============================================================
// REGISTER BEATS PAGE
// ============================================================
//
// Responsabilidades:
//
// - selecionar beat clicando;
// - receber beat por drag & drop;
// - validar arquivo;
// - exibir metadados;
// - receber título;
// - receber BPM opcional;
// - gerar SHA-256;
// - impedir registro duplicado;
// - criar StoredWorkModel;
// - enviar o beat permanentemente para Cloudflare R2;
// - salvar os metadados em stored_works.
//
// ============================================================

class RegisterBeatsPage
    extends
        StatefulWidget {
  const RegisterBeatsPage({
    super.key,
  });

  @override
  State<
    RegisterBeatsPage
  >
  createState() => _RegisterBeatsPageState();
}

// ============================================================
// STATE
// ============================================================

class _RegisterBeatsPageState
    extends
        State<
          RegisterBeatsPage
        > {
  // ==========================================================
  // TEXT CONTROLLERS
  // ==========================================================

  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _bpmController = TextEditingController();

  // ==========================================================
  // SERVICES
  // ==========================================================

  final StorageController _storageController =
      sl<
        StorageController
      >();

  final StorageHashService _hashService =
      sl<
        StorageHashService
      >();

  final StorageFileService _fileService =
      sl<
        StorageFileService
      >();

  final WorkStorageService _workStorageService =
      sl<
        WorkStorageService
      >();

  // ==========================================================
  // ARQUIVO
  // ==========================================================

  StorageFileInfo? _selectedFile;

  // ==========================================================
  // ESTADO
  // ==========================================================

  bool _isDragging = false;

  bool _isSelectingFile = false;

  bool _isRegistering = false;

  // ==========================================================
  // CORES
  // ==========================================================

  static const Color _backgroundColor = Color(
    0xFF0D0B1F,
  );

  static const Color _surfaceColor = Color(
    0xFF17132D,
  );

  static const Color _accentColor = Color(
    0xFFE100FF,
  );

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _titleController.dispose();
    _bpmController.dispose();

    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: _backgroundColor,

      appBar: AppBar(
        backgroundColor: _backgroundColor,

        elevation: 0,

        foregroundColor: Colors.white,

        title: const Text(
          'Registrar beat',

          style: TextStyle(
            fontSize: 16,

            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: Container(
        width: double.infinity,

        height: double.infinity,

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

          padding: const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            40,
          ),

          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 900,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // ============================================
                  // HEADER
                  // ============================================
                  _buildHeader(),

                  const SizedBox(
                    height: 24,
                  ),

                  // ============================================
                  // ARQUIVO
                  // ============================================
                  _buildLabel(
                    'ARQUIVO DO BEAT',
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  _buildDropZone(),

                  // ============================================
                  // ARQUIVO SELECIONADO
                  // ============================================
                  if (_selectedFile !=
                      null) ...[
                    const SizedBox(
                      height: 16,
                    ),

                    _buildSelectedFileCard(),
                  ],

                  const SizedBox(
                    height: 24,
                  ),

                  // ============================================
                  // TÍTULO
                  // ============================================
                  _buildLabel(
                    'TÍTULO DO BEAT',
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  _buildTitleField(),

                  const SizedBox(
                    height: 22,
                  ),

                  // ============================================
                  // BPM
                  // ============================================
                  _buildLabel(
                    'BPM',
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  _buildBpmField(),

                  const SizedBox(
                    height: 18,
                  ),

                  // ============================================
                  // HASH
                  // ============================================
                  _buildHashInformation(),

                  const SizedBox(
                    height: 28,
                  ),

                  // ============================================
                  // REGISTRAR
                  // ============================================
                  _buildRegisterButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        18,
      ),

      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.035,
        ),

        borderRadius: BorderRadius.circular(
          18,
        ),

        border: Border.all(
          color: _accentColor.withValues(
            alpha: 0.12,
          ),
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 52,

            height: 52,

            decoration: BoxDecoration(
              color: _accentColor.withValues(
                alpha: 0.08,
              ),

              borderRadius: BorderRadius.circular(
                14,
              ),
            ),

            child: const Icon(
              Icons.graphic_eq_rounded,

              color: _accentColor,

              size: 25,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'Novo beat',

                  style: TextStyle(
                    color: Colors.white,

                    fontSize: 18,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(
                  height: 4,
                ),

                Text(
                  'Arraste seu áudio ou selecione um arquivo para gerar sua impressão digital SHA-256.',

                  style: TextStyle(
                    color: Colors.white38,

                    fontSize: 11,

                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DROP ZONE
  // ==========================================================

  Widget _buildDropZone() {
    return DropTarget(
      // ========================================================
      // ARQUIVO ENTROU
      // ========================================================
      onDragEntered:
          (
            details,
          ) {
            if (!mounted) {
              return;
            }

            setState(
              () {
                _isDragging = true;
              },
            );
          },

      // ========================================================
      // ARQUIVO SAIU
      // ========================================================
      onDragExited:
          (
            details,
          ) {
            if (!mounted) {
              return;
            }

            setState(
              () {
                _isDragging = false;
              },
            );
          },

      // ========================================================
      // ARQUIVO SOLTO
      // ========================================================
      onDragDone:
          (
            details,
          ) async {
            if (mounted) {
              setState(
                () {
                  _isDragging = false;
                },
              );
            }

            if (details.files.isEmpty) {
              return;
            }

            // Aceitamos apenas um beat por registro.
            final droppedFile = details.files.first;

            await _selectFileFromPath(
              droppedFile.path,
            );
          },

      child: InkWell(
        onTap:
            _isSelectingFile ||
                _isRegistering
            ? null
            : _pickBeatFile,

        borderRadius: BorderRadius.circular(
          20,
        ),

        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),

          width: double.infinity,

          constraints: const BoxConstraints(
            minHeight: 230,
          ),

          padding: const EdgeInsets.all(
            30,
          ),

          decoration: BoxDecoration(
            color: _isDragging
                ? _accentColor.withValues(
                    alpha: 0.10,
                  )
                : Colors.white.withValues(
                    alpha: 0.025,
                  ),

            borderRadius: BorderRadius.circular(
              20,
            ),

            border: Border.all(
              color: _isDragging
                  ? _accentColor
                  : Colors.white.withValues(
                      alpha: 0.09,
                    ),

              width: _isDragging
                  ? 2
                  : 1,
            ),
          ),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              // ================================================
              // ÍCONE
              // ================================================
              AnimatedContainer(
                duration: const Duration(
                  milliseconds: 180,
                ),

                width: 68,

                height: 68,

                decoration: BoxDecoration(
                  color: _accentColor.withValues(
                    alpha: _isDragging
                        ? 0.16
                        : 0.07,
                  ),

                  shape: BoxShape.circle,
                ),

                child: Icon(
                  _isDragging
                      ? Icons.file_download_done_rounded
                      : Icons.cloud_upload_outlined,

                  color: _accentColor,

                  size: 30,
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              // ================================================
              // TEXTO
              // ================================================
              Text(
                _isDragging
                    ? 'Solte o beat aqui'
                    : 'Arraste seu beat aqui',

                style: const TextStyle(
                  color: Colors.white,

                  fontSize: 16,

                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              Text(
                _isSelectingFile
                    ? 'Abrindo arquivos...'
                    : 'ou clique para selecionar',

                style: const TextStyle(
                  color: Colors.white38,

                  fontSize: 11,
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              // ================================================
              // FORMATOS
              // ================================================
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,

                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.035,
                  ),

                  borderRadius: BorderRadius.circular(
                    20,
                  ),
                ),

                child: const Text(
                  'WAV • MP3 • FLAC • AIFF • M4A • OGG',

                  style: TextStyle(
                    color: Colors.white30,

                    fontSize: 9,

                    fontWeight: FontWeight.w500,

                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // PICK BEAT
  // ==========================================================

  Future<
    void
  >
  _pickBeatFile() async {
    if (_isSelectingFile) {
      return;
    }

    setState(
      () {
        _isSelectingFile = true;
      },
    );

    try {
      final result = await _fileService.pickBeatFile();

      if (result ==
              null ||
          !mounted) {
        return;
      }

      _applySelectedFile(
        result,
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Não foi possível selecionar o beat: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _isSelectingFile = false;
          },
        );
      }
    }
  }

  // ==========================================================
  // ARQUIVO ARRASTADO
  // ==========================================================

  Future<
    void
  >
  _selectFileFromPath(
    String filePath,
  ) async {
    try {
      final file = await _fileService.inspectFile(
        filePath,
      );

      if (!mounted) {
        return;
      }

      _applySelectedFile(
        file,
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Arquivo inválido: $error',
        isError: true,
      );
    }
  }

  // ==========================================================
  // APLICAR ARQUIVO
  // ==========================================================

  void _applySelectedFile(
    StorageFileInfo file,
  ) {
    setState(
      () {
        _selectedFile = file;

        // Preenche título automaticamente somente se estiver vazio.
        if (_titleController.text.trim().isEmpty) {
          _titleController.text = _removeFileExtension(
            file.fileName,
          );
        }
      },
    );
  }

  // ==========================================================
  // SELECTED FILE
  // ==========================================================

  Widget _buildSelectedFileCard() {
    final file = _selectedFile!;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        14,
      ),

      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(
          alpha: 0.04,
        ),

        borderRadius: BorderRadius.circular(
          16,
        ),

        border: Border.all(
          color: Colors.greenAccent.withValues(
            alpha: 0.14,
          ),
        ),
      ),

      child: Row(
        children: [
          // ====================================================
          // ÍCONE
          // ====================================================
          Container(
            width: 44,

            height: 44,

            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(
                alpha: 0.08,
              ),

              borderRadius: BorderRadius.circular(
                12,
              ),
            ),

            child: const Icon(
              Icons.audio_file_rounded,

              color: Colors.greenAccent,

              size: 22,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          // ====================================================
          // INFO
          // ====================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  file.fileName,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: Colors.white,

                    fontSize: 13,

                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  '${file.extension.toUpperCase()}'
                  ' • '
                  '${_fileService.formatFileSize(file.sizeBytes)}',

                  style: const TextStyle(
                    color: Colors.white38,

                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // ====================================================
          // VALIDADO
          // ====================================================
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,

              vertical: 5,
            ),

            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(
                alpha: 0.07,
              ),

              borderRadius: BorderRadius.circular(
                20,
              ),
            ),

            child: const Row(
              mainAxisSize: MainAxisSize.min,

              children: [
                Icon(
                  Icons.check_circle_outline_rounded,

                  color: Colors.greenAccent,

                  size: 13,
                ),

                SizedBox(
                  width: 4,
                ),

                Text(
                  'Válido',

                  style: TextStyle(
                    color: Colors.greenAccent,

                    fontSize: 9,

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 6,
          ),

          // ====================================================
          // REMOVER
          // ====================================================
          IconButton(
            onPressed: _isRegistering
                ? null
                : _removeSelectedFile,

            tooltip: 'Remover arquivo',

            icon: const Icon(
              Icons.close_rounded,

              color: Colors.white38,

              size: 19,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // REMOVER ARQUIVO
  // ==========================================================

  void _removeSelectedFile() {
    setState(
      () {
        _selectedFile = null;
      },
    );
  }

  // ==========================================================
  // LABEL
  // ==========================================================

  Widget _buildLabel(
    String text,
  ) {
    return Text(
      text,

      style: const TextStyle(
        color: Colors.white54,

        fontSize: 10,

        fontWeight: FontWeight.bold,

        letterSpacing: 1.1,
      ),
    );
  }

  // ==========================================================
  // TITLE
  // ==========================================================

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,

      enabled: !_isRegistering,

      maxLength: 120,

      style: const TextStyle(
        color: Colors.white,

        fontSize: 14,
      ),

      decoration: _inputDecoration(
        hint: 'Ex: Dark Streets',

        icon: Icons.title_rounded,
      ),
    );
  }

  // ==========================================================
  // BPM
  // ==========================================================

  Widget _buildBpmField() {
    return SizedBox(
      width: 220,

      child: TextField(
        controller: _bpmController,

        enabled: !_isRegistering,

        keyboardType: TextInputType.number,

        style: const TextStyle(
          color: Colors.white,

          fontSize: 14,
        ),

        decoration: _inputDecoration(
          hint: 'Ex: 140',

          icon: Icons.speed_rounded,
        ),
      ),
    );
  }

  // ==========================================================
  // INPUT DECORATION
  // ==========================================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,

      hintStyle: const TextStyle(
        color: Colors.white24,
      ),

      counterStyle: const TextStyle(
        color: Colors.white24,

        fontSize: 9,
      ),

      prefixIcon: Icon(
        icon,

        color: Colors.white30,

        size: 19,
      ),

      filled: true,

      fillColor: Colors.white.withValues(
        alpha: 0.035,
      ),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,

        vertical: 16,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          14,
        ),

        borderSide: BorderSide(
          color: Colors.white.withValues(
            alpha: 0.07,
          ),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          14,
        ),

        borderSide: BorderSide(
          color: _accentColor.withValues(
            alpha: 0.65,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // HASH INFORMATION
  // ==========================================================

  Widget _buildHashInformation() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        14,
      ),

      decoration: BoxDecoration(
        color: _accentColor.withValues(
          alpha: 0.035,
        ),

        borderRadius: BorderRadius.circular(
          14,
        ),

        border: Border.all(
          color: _accentColor.withValues(
            alpha: 0.10,
          ),
        ),
      ),

      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(
            Icons.fingerprint_rounded,

            color: _accentColor,

            size: 19,
          ),

          SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'Hash SHA-256 do arquivo',

                  style: TextStyle(
                    color: Colors.white70,

                    fontSize: 11,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(
                  height: 4,
                ),

                Text(
                  'O hash será calculado diretamente dos bytes do beat. '
                  'Se qualquer byte do arquivo for alterado, o SHA-256 também será diferente.',

                  style: TextStyle(
                    color: Colors.white38,

                    fontSize: 10,

                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // REGISTER BUTTON
  // ==========================================================

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,

      height: 52,

      child: ElevatedButton.icon(
        onPressed: _isRegistering
            ? null
            : _registerBeat,

        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,

          foregroundColor: Colors.black,

          disabledBackgroundColor: _accentColor.withValues(
            alpha: 0.25,
          ),

          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              14,
            ),
          ),
        ),

        icon: _isRegistering
            ? const SizedBox(
                width: 18,

                height: 18,

                child: CircularProgressIndicator(
                  strokeWidth: 2,

                  color: Colors.black,
                ),
              )
            : const Icon(
                Icons.verified_user_outlined,

                size: 19,
              ),

        label: Text(
          _isRegistering
              ? 'SALVANDO...'
              : 'REGISTRAR BEAT',

          style: const TextStyle(
            fontWeight: FontWeight.bold,

            fontSize: 12,

            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // REGISTRAR BEAT
  // ==========================================================

  Future<
    void
  >
  _registerBeat() async {
    final file = _selectedFile;

    final title = _titleController.text.trim();

    final bpmText = _bpmController.text.trim();

    // ========================================================
    // ARQUIVO
    // ========================================================

    if (file ==
        null) {
      _showMessage(
        'Selecione ou arraste um beat antes de registrar.',
        isError: true,
      );

      return;
    }

    // ========================================================
    // TÍTULO
    // ========================================================

    if (title.isEmpty) {
      _showMessage(
        'Digite o título do beat.',
        isError: true,
      );

      return;
    }

    // ========================================================
    // BPM
    // ========================================================

    final bpm = bpmText.isEmpty
        ? null
        : int.tryParse(
            bpmText,
          );

    if (bpmText.isNotEmpty &&
        (bpm ==
                null ||
            bpm <=
                0 ||
            bpm >
                400)) {
      _showMessage(
        'Digite um BPM válido entre 1 e 400.',
        isError: true,
      );

      return;
    }

    // ========================================================
    // USUÁRIO
    // ========================================================

    final userId = _storageController.currentUserId;

    if (userId ==
            null ||
        userId.trim().isEmpty) {
      _showMessage(
        'Usuário do armazenamento não inicializado.',
        isError: true,
      );

      return;
    }

    setState(
      () {
        _isRegistering = true;
      },
    );

    try {
      // ======================================================
      // VALIDAR ARQUIVO
      // ======================================================

      final exists = await _fileService.exists(
        file.path,
      );

      if (!exists) {
        throw StateError(
          'O arquivo selecionado não existe mais.',
        );
      }

      // ======================================================
      // HASH SHA-256
      // ======================================================

      final contentHash = await _hashService.hashFile(
        file.path,
      );

      final alreadyExists = await _storageController.hashExists(
        contentHash,
      );

      if (!mounted) {
        return;
      }

      if (alreadyExists) {
        _showMessage(
          'Este beat já possui um registro com o mesmo hash.',
          isError: true,
        );

        return;
      }

      // ======================================================
      // ID
      // ======================================================

      final now = DateTime.now().toUtc();

      final workId = 'beat_${now.microsecondsSinceEpoch}';

      // ======================================================
      // BYTES
      // ======================================================
      //
      // Não fazemos mais uma cópia local permanente.
      //
      // Os bytes serão enviados pelo BeatStorageService para
      // uma URL assinada e armazenados no Cloudflare R2.
      //
      // ======================================================

      final bytes = await File(
        file.path,
      ).readAsBytes();

      if (bytes.isEmpty) {
        throw StateError(
          'O beat selecionado está vazio.',
        );
      }

      // ======================================================
      // MODELO
      // ======================================================

      final work = StoredWorkModel(
        id: workId,
        originalAuthorUserId: userId,
        ownerUserId: userId,
        type: StoredWorkType.beat,
        title: title,
        contentHash: contentHash,
        hashAlgorithm: StorageHashService.algorithm,
        version: 1,
        integrityVerified: true,
        fileName: file.fileName,
        mimeType: file.mimeType,
        fileSizeBytes: file.sizeBytes,
        bpm: bpm,
        createdAt: now,
        updatedAt: now,
      );

      // ======================================================
      // SALVAR PERMANENTEMENTE
      // ======================================================
      //
      // 1. envia o arquivo ao Cloudflare R2;
      // 2. recebe objectKey;
      // 3. coloca objectKey em filePath;
      // 4. salva a obra em public.stored_works.
      //
      // ======================================================

      final savedWork = await _workStorageService.saveBeat(
        work: work,
        bytes: bytes,
      );

      if (!mounted) {
        return;
      }

      // ======================================================
      // SINCRONIZAR LISTA LOCAL
      // ======================================================

      await _storageController.refresh();

      if (!mounted) {
        return;
      }

      debugPrint(
        '[STORAGE] Beat permanente salvo: '
        '${savedWork.id} | '
        '${savedWork.filePath}',
      );

      _showMessage(
        'Beat registrado permanentemente com sucesso.',
      );

      Navigator.of(
        context,
      ).pop(
        true,
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Erro ao registrar o beat: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _isRegistering = false;
          },
        );
      }
    }
  }

  // ==========================================================
  // REMOVER EXTENSÃO
  // ==========================================================

  String _removeFileExtension(
    String fileName,
  ) {
    final index = fileName.lastIndexOf(
      '.',
    );

    if (index <=
        0) {
      return fileName;
    }

    return fileName.substring(
      0,
      index,
    );
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),

        backgroundColor: isError
            ? const Color(
                0xFF8B1E3F,
              )
            : _surfaceColor,

        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
