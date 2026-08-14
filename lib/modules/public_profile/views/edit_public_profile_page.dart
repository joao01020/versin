import 'package:flutter/material.dart';

import 'package:versin/modules/public_profile/controllers/public_profile_controller.dart';
import 'package:versin/modules/public_profile/widgets/edit_profile_avatar_widget.dart';

// ============================================================
// EDIT PUBLIC PROFILE PAGE
// ============================================================
//
// Tela responsável pela edição do perfil público.
//
// Responsabilidades:
//
// - editar nome artístico;
// - editar username;
// - editar bio;
// - exibir avatar atual;
// - validar formulário;
// - salvar alterações.
//
// NÃO:
//
// - acessa Supabase diretamente;
// - faz upload diretamente;
// - contém repository;
// - possui regras do Match.
//
// O upload do avatar será conectado depois através do onTap
// do EditProfileAvatarWidget.
//
// ============================================================

class EditPublicProfilePage extends StatefulWidget {
  final PublicProfileController controller;

  const EditPublicProfilePage({super.key, required this.controller});

  @override
  State<EditPublicProfilePage> createState() => _EditPublicProfilePageState();
}

// ============================================================
// STATE
// ============================================================

class _EditPublicProfilePageState extends State<EditPublicProfilePage> {
  // ============================================================
  // FORM
  // ============================================================

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ============================================================
  // INPUT CONTROLLERS
  // ============================================================

  late final TextEditingController _displayNameController;

  late final TextEditingController _usernameController;

  late final TextEditingController _bioController;

  // ============================================================
  // AVATAR
  // ============================================================

  String? _avatarUrl;

  // ============================================================
  // GETTER
  // ============================================================

  PublicProfileController get controller => widget.controller;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    final profile = controller.profile;

    _displayNameController = TextEditingController(
      text: profile?.displayName ?? '',
    );

    _usernameController = TextEditingController(text: profile?.username ?? '');

    _bioController = TextEditingController(text: profile?.bio ?? '');

    _avatarUrl = profile?.avatarUrl;

    controller.addListener(_onControllerChanged);
  }

  // ============================================================
  // CONTROLLER CHANGE
  // ============================================================

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ============================================================
  // SALVAR
  // ============================================================

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || controller.isSaving) {
      return;
    }

    final success = await controller.updateProfile(
      displayName: _displayNameController.text,
      username: _usernameController.text,
      bio: _bioController.text,
      avatarUrl: _avatarUrl,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showError(
        controller.errorMessage ?? 'Não foi possível salvar o perfil.',
      );

      return;
    }

    Navigator.of(context).pop(true);
  }

  // ============================================================
  // AVATAR
  // ============================================================
  //
  // Por enquanto apenas informa que o seletor ainda será
  // conectado.
  //
  // Depois este método poderá:
  //
  // - abrir file_picker;
  // - gerar preview;
  // - fazer upload;
  // - atualizar _avatarUrl.
  //
  // ============================================================

  void _handleAvatarTap() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Seleção de avatar será conectada na próxima etapa.'),
        ),
      );
  }

  // ============================================================
  // ERRO
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final profile = controller.profile;

    return Scaffold(
      backgroundColor: const Color(0xFF09090F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090F),
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(
          'Editar perfil',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: controller.isSaving ? null : _save,
            child: controller.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar'),
          ),

          const SizedBox(width: 8),
        ],
      ),
      body: profile == null ? _buildProfileUnavailable() : _buildForm(),
    );
  }

  // ============================================================
  // FORM
  // ============================================================

  Widget _buildForm() {
    final profile = controller.profile;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // AVATAR
            // ==================================================
            Center(
              child: EditProfileAvatarWidget(
                avatarUrl: _avatarUrl,
                displayName: profile?.resolvedDisplayName,
                isLoading: controller.isSaving,
                onTap: _handleAvatarTap,
              ),
            ),

            const SizedBox(height: 32),

            // ==================================================
            // NOME ARTÍSTICO
            // ==================================================
            _buildLabel('Nome artístico'),

            const SizedBox(height: 8),

            TextFormField(
              controller: _displayNameController,
              enabled: !controller.isSaving,
              textInputAction: TextInputAction.next,
              maxLength: 50,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                hint: 'Como você quer aparecer no Versin?',
                icon: Icons.badge_outlined,
              ),
              validator: _validateDisplayName,
            ),

            const SizedBox(height: 20),

            // ==================================================
            // USERNAME
            // ==================================================
            _buildLabel('Username'),

            const SizedBox(height: 8),

            TextFormField(
              controller: _usernameController,
              enabled: !controller.isSaving,
              textInputAction: TextInputAction.next,
              maxLength: 30,
              autocorrect: false,
              enableSuggestions: false,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                hint: 'seuusername',
                icon: Icons.alternate_email_rounded,
                prefix: '@',
              ),
              validator: _validateUsername,
            ),

            const SizedBox(height: 20),

            // ==================================================
            // BIO
            // ==================================================
            _buildLabel('Bio'),

            const SizedBox(height: 8),

            TextFormField(
              controller: _bioController,
              enabled: !controller.isSaving,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              minLines: 4,
              maxLines: 7,
              maxLength: 300,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                hint:
                    'Conte sobre você, seu trabalho, estilo musical e o que procura no Versin.',
                icon: Icons.notes_rounded,
              ),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // SALVAR
            // ==================================================
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: controller.isSaving ? null : _save,
                icon: controller.isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(
                  controller.isSaving ? 'Salvando...' : 'Salvar alterações',
                ),
              ),
            ),

            // ==================================================
            // ERRO
            // ==================================================
            if (controller.hasError) ...[
              const SizedBox(height: 16),

              _buildErrorCard(),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    String? prefix,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
    );

    return InputDecoration(
      hintText: hint,

      hintStyle: const TextStyle(color: Colors.white38),

      prefixText: prefix,

      prefixStyle: const TextStyle(color: Colors.white70),

      prefixIcon: Icon(icon, color: Colors.white54),

      filled: true,

      fillColor: Colors.white.withValues(alpha: 0.05),

      counterStyle: const TextStyle(color: Colors.white38),

      border: border,

      enabledBorder: border,

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF9C6BFF), width: 1.5),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  // ============================================================
  // VALIDAR NOME
  // ============================================================

  String? _validateDisplayName(String? value) {
    final normalized = value?.trim() ?? '';

    if (normalized.isEmpty) {
      return 'Informe seu nome artístico.';
    }

    if (normalized.length < 2) {
      return 'O nome precisa ter pelo menos 2 caracteres.';
    }

    return null;
  }

  // ============================================================
  // VALIDAR USERNAME
  // ============================================================

  String? _validateUsername(String? value) {
    var normalized = value?.trim() ?? '';

    if (normalized.startsWith('@')) {
      normalized = normalized.substring(1);
    }

    if (normalized.isEmpty) {
      return 'Informe um username.';
    }

    if (normalized.length < 3) {
      return 'Use pelo menos 3 caracteres.';
    }

    final validUsername = RegExp(r'^[a-zA-Z0-9._]+$');

    if (!validUsername.hasMatch(normalized)) {
      return 'Use apenas letras, números, ponto e _.';
    }

    return null;
  }

  // ============================================================
  // ERROR CARD
  // ============================================================

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 20,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              controller.errorMessage ?? 'Não foi possível salvar o perfil.',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PERFIL INDISPONÍVEL
  // ============================================================

  Widget _buildProfileUnavailable() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Perfil indisponível para edição.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 15),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);

    _displayNameController.dispose();

    _usernameController.dispose();

    _bioController.dispose();

    super.dispose();
  }
}
