import 'package:flutter/material.dart';

import 'package:versin/app/locator.dart';

import '../../controllers/storage_controller.dart';
import '../../data/models/stored_work_model.dart';
import '../../services/storage_hash_service.dart';

class RegisterLyricsPage
    extends
        StatefulWidget {
  final String initialTitle;
  final String initialLyrics;

  const RegisterLyricsPage({
    super.key,
    this.initialTitle = '',
    this.initialLyrics = '',
  });

  @override
  State<
    RegisterLyricsPage
  >
  createState() => _RegisterLyricsPageState();
}

class _RegisterLyricsPageState
    extends
        State<
          RegisterLyricsPage
        > {
  late final TextEditingController _titleController;
  late final TextEditingController _lyricsController;

  final StorageController _storageController =
      sl<
        StorageController
      >();
  final StorageHashService _hashService =
      sl<
        StorageHashService
      >();

  bool _isRegistering = false;

  static const Color _backgroundColor = Color(
    0xFF0D0B1F,
  );
  static const Color _surfaceColor = Color(
    0xFF17132D,
  );
  static const Color _accentColor = Color(
    0xFFE100FF,
  );

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.initialTitle,
    );

    _lyricsController = TextEditingController(
      text: widget.initialLyrics,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

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
          'Registrar letra',
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
                  _buildHeader(),
                  const SizedBox(
                    height: 24,
                  ),
                  _buildLabel(
                    'TÍTULO DA OBRA',
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  _buildTitleField(),
                  const SizedBox(
                    height: 24,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLabel(
                        'LETRA',
                      ),
                      ValueListenableBuilder<
                        TextEditingValue
                      >(
                        valueListenable: _lyricsController,
                        builder:
                            (
                              context,
                              value,
                              _,
                            ) {
                              return Text(
                                '${value.text.length} caracteres',
                                style: const TextStyle(
                                  color: Colors.white30,
                                  fontSize: 10,
                                ),
                              );
                            },
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  _buildLyricsField(),
                  const SizedBox(
                    height: 16,
                  ),
                  _buildHashInformation(),
                  const SizedBox(
                    height: 28,
                  ),
                  _buildRegisterButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final importedFromStudio = widget.initialLyrics.trim().isNotEmpty;

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
              Icons.description_outlined,
              color: _accentColor,
              size: 24,
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
                  importedFromStudio
                      ? 'Letra pronta para registrar'
                      : 'Nova letra',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  importedFromStudio
                      ? 'O título e a letra do Estúdio já foram preenchidos. Revise antes de registrar.'
                      : 'Cole sua letra e registre uma impressão digital SHA-256 da obra.',
                  style: const TextStyle(
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
        hint: 'Ex: Madrugada',
        icon: Icons.title_rounded,
      ),
    );
  }

  Widget _buildLyricsField() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 360,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.035,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.07,
          ),
        ),
      ),
      child: TextField(
        controller: _lyricsController,
        enabled: !_isRegistering,
        minLines: 16,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textAlignVertical: TextAlignVertical.top,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          height: 1.65,
        ),
        decoration: const InputDecoration(
          hintText: 'Cole ou escreva sua letra aqui...',
          hintStyle: TextStyle(
            color: Colors.white24,
            fontSize: 13,
            height: 1.6,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(
            20,
          ),
        ),
      ),
    );
  }

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
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          14,
        ),
        borderSide: BorderSide(
          color: Colors.white.withValues(
            alpha: 0.04,
          ),
        ),
      ),
    );
  }

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
                  'Hash SHA-256',
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
                  'Ao registrar, o Versin gera uma impressão digital do conteúdo da letra. Se o conteúdo for alterado, o hash também será diferente.',
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

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isRegistering
            ? null
            : _registerLyrics,
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
              ? 'REGISTRANDO...'
              : 'REGISTRAR LETRA',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Future<
    void
  >
  _registerLyrics() async {
    final title = _titleController.text.trim();
    final lyrics = _lyricsController.text.trim();

    if (title.isEmpty) {
      _showMessage(
        'Digite o título da obra.',
        isError: true,
      );
      return;
    }

    if (lyrics.isEmpty) {
      _showMessage(
        'Cole ou escreva a letra antes de registrar.',
        isError: true,
      );
      return;
    }

    final userId = _storageController.currentUserId;

    if (userId ==
            null ||
        userId.isEmpty) {
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
      final normalizedLyrics = _hashService.normalizeLyrics(
        lyrics,
      );

      final contentHash = _hashService.generateTextHash(
        normalizedLyrics,
      );

      final alreadyExists = await _storageController.hashExists(
        contentHash,
      );

      if (!mounted) {
        return;
      }

      if (alreadyExists) {
        _showMessage(
          'Esta letra já possui um registro com o mesmo conteúdo.',
          isError: true,
        );
        return;
      }

      final now = DateTime.now().toUtc();
      final workId = 'lyrics_${now.microsecondsSinceEpoch}';

      final work = StoredWorkModel(
        id: workId,
        ownerUserId: userId,
        originalAuthorUserId: userId,
        type: StoredWorkType.lyrics,
        title: title,
        contentHash: contentHash,
        hashAlgorithm: StorageHashService.algorithm,
        lyricsContent: normalizedLyrics,
        version: 1,
        integrityVerified: true,
        createdAt: now,
        updatedAt: now,
      );

      final saved = await _storageController.saveWork(
        work,
      );

      if (!mounted) {
        return;
      }

      if (!saved) {
        _showMessage(
          _storageController.errorMessage ??
              'Não foi possível registrar a letra.',
          isError: true,
        );
        return;
      }

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
        'Erro ao registrar a letra: $error',
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
