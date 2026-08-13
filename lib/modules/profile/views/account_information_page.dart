import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/app/locator.dart';
import 'package:versin/modules/dashboard/controllers/dashboard_controller.dart';

class AccountInformationPage
    extends
        StatefulWidget {
  const AccountInformationPage({
    super.key,
  });

  @override
  State<
    AccountInformationPage
  >
  createState() => _AccountInformationPageState();
}

class _AccountInformationPageState
    extends
        State<
          AccountInformationPage
        > {
  final SupabaseClient _supabase = Supabase.instance.client;

  final DashboardController _dashboardController =
      sl<
        DashboardController
      >();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _artistNameController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  Uint8List? _selectedAvatarBytes;
  String? _selectedAvatarExtension;
  String? _avatarUrl;
  String? _errorMessage;
  String? _successMessage;

  static const Color _backgroundColor = Color(
    0xFF0D0B1F,
  );

  static const Color _surfaceColor = Color(
    0xFF17132D,
  );

  static const Color _primaryPurple = Color(
    0xFF6A1B9A,
  );

  static const Color _accentNeon = Color(
    0xFFE040FB,
  );

  @override
  void initState() {
    super.initState();

    _loadAccount();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _artistNameController.dispose();

    super.dispose();
  }

  // ============================================================
  // CARREGAR CONTA
  // ============================================================

  Future<
    void
  >
  _loadAccount() async {
    final user = _supabase.auth.currentUser;

    if (user ==
        null) {
      if (!mounted) {
        return;
      }

      setState(
        () {
          _isLoading = false;
          _errorMessage = 'Nenhum usuário autenticado.';
        },
      );

      return;
    }

    try {
      final profile = await _supabase
          .from(
            'profiles',
          )
          .select(
            'artist_name, avatar_url',
          )
          .eq(
            'id',
            user.id,
          )
          .maybeSingle();

      if (!mounted) {
        return;
      }

      _emailController.text =
          user.email ??
          '';

      _artistNameController.text =
          profile?['artist_name']?.toString().trim() ??
          '';

      setState(
        () {
          _avatarUrl = profile?['avatar_url']?.toString().trim();

          _isLoading = false;
        },
      );
    } on PostgrestException catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      setState(
        () {
          _isLoading = false;
          _errorMessage =
              'Não foi possível carregar o perfil: '
              '${error.message}';
        },
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      setState(
        () {
          _isLoading = false;
          _errorMessage = 'Não foi possível carregar as informações da conta.';
        },
      );

      debugPrint(
        '[ACCOUNT] Erro ao carregar perfil: $error',
      );
    }
  }

  // ============================================================
  // ESCOLHER AVATAR
  // ============================================================

  Future<
    void
  >
  _pickAvatar() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result ==
              null ||
          result.files.isEmpty) {
        return;
      }

      final file = result.files.single;

      final bytes = file.bytes;

      if (bytes ==
              null ||
          bytes.isEmpty) {
        _showError(
          'Não foi possível ler a imagem selecionada.',
        );

        return;
      }

      final extension = _normalizeExtension(
        file.extension,
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _selectedAvatarBytes = bytes;

          _selectedAvatarExtension = extension;

          _errorMessage = null;

          _successMessage = null;
        },
      );
    } catch (
      error
    ) {
      _showError(
        'Não foi possível selecionar a imagem.',
      );

      debugPrint(
        '[ACCOUNT] Erro ao selecionar avatar: $error',
      );
    }
  }

  // ============================================================
  // SALVAR
  // ============================================================

  Future<
    void
  >
  _save() async {
    if (_isSaving) {
      return;
    }

    FocusScope.of(
      context,
    ).unfocus();

    final user = _supabase.auth.currentUser;

    if (user ==
        null) {
      _showError(
        'Sua sessão não está disponível.',
      );

      return;
    }

    final email = _emailController.text.trim().toLowerCase();

    final artistName = _artistNameController.text.trim().replaceAll(
      RegExp(
        r'\s+',
      ),
      ' ',
    );

    if (!_isValidEmail(
      email,
    )) {
      _showError(
        'Informe um e-mail válido.',
      );

      return;
    }

    if (artistName.length <
        2) {
      _showError(
        'O nome artístico deve ter pelo menos 2 caracteres.',
      );

      return;
    }

    if (artistName.length >
        40) {
      _showError(
        'O nome artístico deve ter no máximo 40 caracteres.',
      );

      return;
    }

    setState(
      () {
        _isSaving = true;

        _errorMessage = null;

        _successMessage = null;
      },
    );

    try {
      // ========================================================
      // EMAIL
      // ========================================================

      final currentEmail = user.email?.trim().toLowerCase();

      final emailChanged =
          currentEmail !=
          email;

      if (emailChanged) {
        await _supabase.auth.updateUser(
          UserAttributes(
            email: email,
          ),
        );
      }

      // ========================================================
      // AVATAR
      // ========================================================

      var nextAvatarUrl = _avatarUrl;

      final selectedBytes = _selectedAvatarBytes;

      if (selectedBytes !=
          null) {
        nextAvatarUrl = await _uploadAvatar(
          userId: user.id,
          bytes: selectedBytes,
          extension:
              _selectedAvatarExtension ??
              'png',
        );
      }

      // ========================================================
      // PERFIL
      // ========================================================

      await _supabase
          .from(
            'profiles',
          )
          .update(
            {
              'artist_name': artistName,

              'artist_name_updated_at': DateTime.now().toUtc().toIso8601String(),

              'avatar_url': nextAvatarUrl,
            },
          )
          .eq(
            'id',
            user.id,
          );

      // ========================================================
      // DASHBOARD
      // ========================================================

      _dashboardController.updateArtistName(
        artistName,
      );

      if (nextAvatarUrl !=
              null &&
          nextAvatarUrl.isNotEmpty) {
        _dashboardController.profileImagePath = nextAvatarUrl;
      }

      _dashboardController.notifyListeners();

      if (!mounted) {
        return;
      }

      setState(
        () {
          _avatarUrl = nextAvatarUrl;

          _selectedAvatarBytes = null;

          _selectedAvatarExtension = null;

          _isSaving = false;

          _successMessage = emailChanged
              ? 'Perfil salvo. Confirme a alteração de e-mail pelo link enviado pelo Supabase.'
              : 'Informações da conta atualizadas.';
        },
      );
    } on AuthException catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      setState(
        () {
          _isSaving = false;

          _errorMessage = _translateAuthError(
            error,
          );
        },
      );
    } on StorageException catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      setState(
        () {
          _isSaving = false;

          _errorMessage =
              'Não foi possível salvar o avatar: '
              '${error.message}';
        },
      );
    } on PostgrestException catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      setState(
        () {
          _isSaving = false;

          _errorMessage =
              'Não foi possível salvar o perfil: '
              '${error.message}';
        },
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      setState(
        () {
          _isSaving = false;

          _errorMessage = 'Não foi possível atualizar a conta.';
        },
      );

      debugPrint(
        '[ACCOUNT] Erro ao salvar: $error',
      );
    }
  }

  // ============================================================
  // UPLOAD DO AVATAR
  // ============================================================

  Future<
    String
  >
  _uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final path = '$userId/avatar.$extension';

    await _supabase.storage
        .from(
          'avatars',
        )
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _contentTypeForExtension(
              extension,
            ),
          ),
        );

    final publicUrl = _supabase.storage
        .from(
          'avatars',
        )
        .getPublicUrl(
          path,
        );

    return '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.of(
              context,
            ).pop();
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
          ),
        ),
        title: const Text(
          'Informações da Conta',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: _accentNeon,
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                40,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 620,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatarCard(),

                      const SizedBox(
                        height: 18,
                      ),

                      _buildFormCard(),

                      if (_errorMessage !=
                          null) ...[
                        const SizedBox(
                          height: 14,
                        ),

                        _buildMessage(
                          message: _errorMessage!,
                          error: true,
                        ),
                      ],

                      if (_successMessage !=
                          null) ...[
                        const SizedBox(
                          height: 14,
                        ),

                        _buildMessage(
                          message: _successMessage!,
                          error: false,
                        ),
                      ],

                      const SizedBox(
                        height: 20,
                      ),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving
                              ? null
                              : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryPurple,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: _primaryPurple.withValues(
                              alpha: 0.25,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                14,
                              ),
                            ),
                            side: BorderSide(
                              color: _accentNeon.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.save_outlined,
                                  size: 19,
                                ),
                          label: Text(
                            _isSaving
                                ? 'SALVANDO...'
                                : 'SALVAR ALTERAÇÕES',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAvatarCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        22,
      ),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildAvatar(),

          const SizedBox(
            height: 14,
          ),

          const Text(
            'Avatar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          const Text(
            'Escolha uma imagem para o seu perfil.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          OutlinedButton.icon(
            onPressed: _pickAvatar,
            style: OutlinedButton.styleFrom(
              foregroundColor: _accentNeon,
              side: BorderSide(
                color: _accentNeon.withValues(
                  alpha: 0.35,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  12,
                ),
              ),
            ),
            icon: const Icon(
              Icons.image_outlined,
              size: 18,
            ),
            label: const Text(
              'ESCOLHER IMAGEM',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final selectedBytes = _selectedAvatarBytes;

    if (selectedBytes !=
        null) {
      return CircleAvatar(
        radius: 52,
        backgroundColor: _primaryPurple.withValues(
          alpha: 0.25,
        ),
        backgroundImage: MemoryImage(
          selectedBytes,
        ),
      );
    }

    if (_avatarUrl !=
            null &&
        _avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 52,
        backgroundColor: _primaryPurple.withValues(
          alpha: 0.25,
        ),
        backgroundImage: NetworkImage(
          _avatarUrl!,
        ),
      );
    }

    return CircleAvatar(
      radius: 52,
      backgroundColor: _primaryPurple.withValues(
        alpha: 0.25,
      ),
      child: const Icon(
        Icons.person_rounded,
        color: _accentNeon,
        size: 46,
      ),
    );
  }

  // ============================================================
  // FORM
  // ============================================================

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        20,
      ),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dados do perfil',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          _buildField(
            controller: _emailController,
            label: 'E-MAIL',
            hint: 'seu@email.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(
            height: 14,
          ),

          _buildField(
            controller: _artistNameController,
            label: 'NOME ARTÍSTICO',
            hint: 'Seu nome no Versin',
            icon: Icons.person_outline_rounded,
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            'O nome artístico será atualizado também no Dashboard.',
            style: TextStyle(
              color: Colors.white.withValues(
                alpha: 0.30,
              ),
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          color: Colors.white38,
          fontSize: 10,
          letterSpacing: 0.8,
        ),
        hintStyle: const TextStyle(
          color: Colors.white24,
          fontSize: 12,
        ),
        prefixIcon: Icon(
          icon,
          color: _accentNeon.withValues(
            alpha: 0.75,
          ),
          size: 20,
        ),
        filled: true,
        fillColor: Colors.black.withValues(
          alpha: 0.18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            12,
          ),
          borderSide: BorderSide(
            color: Colors.white.withValues(
              alpha: 0.06,
            ),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            12,
          ),
          borderSide: BorderSide(
            color: _accentNeon.withValues(
              alpha: 0.45,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  Widget _buildMessage({
    required String message,
    required bool error,
  }) {
    final color = error
        ? Colors.redAccent
        : Colors.greenAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        12,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.07,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: color.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            error
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: color,
            size: 17,
          ),

          const SizedBox(
            width: 9,
          ),

          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _surfaceColor.withValues(
        alpha: 0.72,
      ),
      borderRadius: BorderRadius.circular(
        20,
      ),
      border: Border.all(
        color: Colors.white.withValues(
          alpha: 0.07,
        ),
      ),
    );
  }

  void _showError(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    setState(
      () {
        _errorMessage = message;

        _successMessage = null;
      },
    );
  }

  bool _isValidEmail(
    String email,
  ) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(
      email,
    );
  }

  String _normalizeExtension(
    String? extension,
  ) {
    final normalized = extension?.trim().toLowerCase();

    switch (normalized) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        return normalized!;

      default:
        return 'png';
    }
  }

  String _contentTypeForExtension(
    String extension,
  ) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';

      case 'webp':
        return 'image/webp';

      default:
        return 'image/png';
    }
  }

  String _translateAuthError(
    AuthException error,
  ) {
    final message = error.message.toLowerCase();

    if (message.contains(
      'email rate limit exceeded',
    )) {
      return 'Muitos e-mails foram enviados em pouco tempo. Aguarde e tente novamente.';
    }

    if (message.contains(
      'already registered',
    )) {
      return 'Este e-mail já está sendo usado por outra conta.';
    }

    if (message.contains(
      'email',
    )) {
      return 'Não foi possível alterar o e-mail: ${error.message}';
    }

    return error.message;
  }
}
