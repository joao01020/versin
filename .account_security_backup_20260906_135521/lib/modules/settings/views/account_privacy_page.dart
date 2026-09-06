import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountPrivacyPage
    extends
        StatefulWidget {
  const AccountPrivacyPage({
    super.key,
  });

  @override
  State<
    AccountPrivacyPage
  >
  createState() => _AccountPrivacyPageState();
}

class _AccountPrivacyPageState
    extends
        State<
          AccountPrivacyPage
        > {
  static const Color _background = Color(
    0xFF0D0B1F,
  );
  static const Color _surface = Color(
    0xFF17132D,
  );
  static const Color _purple = Color(
    0xFF6A1B9A,
  );
  static const Color _accent = Color(
    0xFFE040FB,
  );

  final SupabaseClient _supabase = Supabase.instance.client;

  bool _changingPassword = false;
  bool _deletingData = false;
  bool _deletingAccount = false;

  bool get _busy =>
      _changingPassword ||
      _deletingData ||
      _deletingAccount;

  @override
  Widget build(
    BuildContext context,
  ) {
    final email =
        _supabase.auth.currentUser?.email ??
        'Conta autenticada';

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        title: const Text(
          'Conta & Privacidade',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            14,
            20,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAccountHeader(
                email,
              ),
              const SizedBox(
                height: 24,
              ),
              _sectionTitle(
                'Segurança da conta',
              ),
              _card(
                child: _actionTile(
                  icon: Icons.password_rounded,
                  iconColor: _accent,
                  title: 'Alterar senha',
                  subtitle: 'Confirme sua senha atual e defina uma nova senha.',
                  loading: _changingPassword,
                  onTap: _busy
                      ? null
                      : _openChangePasswordModal,
                ),
              ),
              const SizedBox(
                height: 24,
              ),
              _sectionTitle(
                'Seus dados',
              ),
              _card(
                child: _actionTile(
                  icon: Icons.delete_sweep_outlined,
                  iconColor: Colors.orangeAccent,
                  title: 'Excluir meus dados',
                  subtitle: 'Apaga seus dados pessoais e conteúdos da aplicação, mas mantém sua conta.',
                  loading: _deletingData,
                  onTap: _busy
                      ? null
                      : _confirmDeleteData,
                ),
              ),
              const SizedBox(
                height: 24,
              ),
              _sectionTitle(
                'Zona de risco',
                color: Colors.redAccent,
              ),
              _card(
                borderColor: Colors.redAccent.withValues(
                  alpha: 0.20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'A exclusão da conta é permanente.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    const Text(
                      'Sua conta será removida e você perderá o acesso aos dados associados a ela. Essa ação não pode ser desfeita.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    _actionTile(
                      icon: Icons.person_remove_alt_1_outlined,
                      iconColor: Colors.redAccent,
                      title: 'Excluir conta permanentemente',
                      subtitle: 'Remove a conta de autenticação e encerra a sessão.',
                      loading: _deletingAccount,
                      danger: true,
                      onTap: _busy
                          ? null
                          : _confirmDeleteAccount,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountHeader(
    String email,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.08,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _accent.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(
                14,
              ),
              border: Border.all(
                color: _accent.withValues(
                  alpha: 0.20,
                ),
              ),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: _accent,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Controle da sua conta',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    String title, {
    Color color = _accent,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 8,
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: color.withValues(
            alpha: 0.90,
          ),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _card({
    required Widget child,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.04,
        ),
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color:
              borderColor ??
              Colors.white.withValues(
                alpha: 0.08,
              ),
        ),
      ),
      child: child,
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool loading,
    required VoidCallback? onTap,
    bool danger = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled:
          onTap !=
          null,
      leading: loading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: iconColor,
              ),
            )
          : Icon(
              icon,
              color: iconColor,
              size: 23,
            ),
      title: Text(
        title,
        style: TextStyle(
          color: danger
              ? Colors.redAccent
              : Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(
          top: 4,
        ),
        child: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(
              alpha: 0.46,
            ),
            fontSize: 11,
            height: 1.35,
          ),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.white24,
      ),
      onTap: onTap,
    );
  }

  Future<
    void
  >
  _openChangePasswordModal() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    var obscureCurrentPassword = true;
    var obscureNewPassword = true;
    var obscureConfirmPassword = true;
    var submitting = false;
    String? validationMessage;

    try {
      await showDialog<
        void
      >(
        context: context,
        barrierDismissible: false,
        builder:
            (
              dialogContext,
            ) {
              return StatefulBuilder(
                builder:
                    (
                      context,
                      setDialogState,
                    ) {
                      Future<
                        void
                      >
                      submit() async {
                        if (submitting) {
                          return;
                        }

                        final currentPassword = currentPasswordController.text;
                        final newPassword = newPasswordController.text;
                        final confirmation = confirmPasswordController.text;

                        String? errorMessage;

                        if (currentPassword.isEmpty) {
                          errorMessage = 'Digite sua senha atual.';
                        } else if (newPassword.length <
                            8) {
                          errorMessage = 'A nova senha precisa ter pelo menos 8 caracteres.';
                        } else if (newPassword !=
                            confirmation) {
                          errorMessage = 'A confirmação da nova senha não coincide.';
                        } else if (currentPassword ==
                            newPassword) {
                          errorMessage = 'A nova senha deve ser diferente da senha atual.';
                        }

                        if (errorMessage !=
                            null) {
                          setDialogState(
                            () {
                              validationMessage = errorMessage;
                            },
                          );
                          return;
                        }

                        setDialogState(
                          () {
                            submitting = true;
                            validationMessage = null;
                          },
                        );

                        if (mounted) {
                          setState(
                            () {
                              _changingPassword = true;
                            },
                          );
                        }

                        try {
                          final user = _supabase.auth.currentUser;

                          final email = user?.email?.trim();

                          if (email ==
                                  null ||
                              email.isEmpty) {
                            throw const AuthException(
                              'Não foi possível identificar o e-mail da conta.',
                            );
                          }

                          // ==========================================================
                          // 1. VALIDAR SENHA ATUAL
                          // ==========================================================

                          await _supabase.auth.signInWithPassword(
                            email: email,
                            password: currentPassword,
                          );

                          // ==========================================================
                          // 2. ALTERAR PARA A NOVA SENHA
                          // ==========================================================

                          await _supabase.auth.updateUser(
                            UserAttributes(
                              password: newPassword,
                            ),
                          );

                          if (!dialogContext.mounted) {
                            return;
                          }

                          Navigator.of(
                            dialogContext,
                          ).pop();

                          if (!mounted) {
                            return;
                          }

                          _showMessage(
                            'Senha alterada com sucesso.',
                          );
                        } on AuthException catch (
                          error
                        ) {
                          if (!dialogContext.mounted) {
                            return;
                          }

                          setDialogState(
                            () {
                              submitting = false;
                              validationMessage = _passwordErrorMessage(
                                error,
                              );
                            },
                          );
                        } catch (
                          error
                        ) {
                          if (!dialogContext.mounted) {
                            return;
                          }

                          setDialogState(
                            () {
                              submitting = false;
                              validationMessage = 'Não foi possível alterar a senha: $error';
                            },
                          );
                        } finally {
                          if (mounted) {
                            setState(
                              () {
                                _changingPassword = false;
                              },
                            );
                          }
                        }
                      }

                      return AlertDialog(
                        backgroundColor: _surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            20,
                          ),
                        ),
                        icon: const Icon(
                          Icons.password_rounded,
                          color: _accent,
                          size: 34,
                        ),
                        title: const Text(
                          'Alterar senha',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: SizedBox(
                          width: 430,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Para proteger sua conta, confirme sua senha atual antes de definir uma nova.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                _modalPasswordField(
                                  controller: currentPasswordController,
                                  label: 'Senha atual',
                                  obscureText: obscureCurrentPassword,
                                  enabled: !submitting,
                                  onToggleVisibility: () {
                                    setDialogState(
                                      () {
                                        obscureCurrentPassword = !obscureCurrentPassword;
                                      },
                                    );
                                  },
                                  onSubmitted:
                                      (
                                        _,
                                      ) {
                                        submit();
                                      },
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                _modalPasswordField(
                                  controller: newPasswordController,
                                  label: 'Nova senha',
                                  hintText: 'Mínimo de 8 caracteres',
                                  obscureText: obscureNewPassword,
                                  enabled: !submitting,
                                  onToggleVisibility: () {
                                    setDialogState(
                                      () {
                                        obscureNewPassword = !obscureNewPassword;
                                      },
                                    );
                                  },
                                  onSubmitted:
                                      (
                                        _,
                                      ) {
                                        submit();
                                      },
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                _modalPasswordField(
                                  controller: confirmPasswordController,
                                  label: 'Confirmar nova senha',
                                  obscureText: obscureConfirmPassword,
                                  enabled: !submitting,
                                  onToggleVisibility: () {
                                    setDialogState(
                                      () {
                                        obscureConfirmPassword = !obscureConfirmPassword;
                                      },
                                    );
                                  },
                                  onSubmitted:
                                      (
                                        _,
                                      ) {
                                        submit();
                                      },
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(
                                    milliseconds: 180,
                                  ),
                                  child:
                                      validationMessage ==
                                          null
                                      ? const SizedBox(
                                          key: ValueKey(
                                            'password-no-error',
                                          ),
                                          height: 8,
                                        )
                                      : Padding(
                                          key: const ValueKey(
                                            'password-error',
                                          ),
                                          padding: const EdgeInsets.only(
                                            top: 12,
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Icon(
                                                Icons.error_outline_rounded,
                                                color: Colors.redAccent,
                                                size: 16,
                                              ),
                                              const SizedBox(
                                                width: 7,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  validationMessage!,
                                                  style: const TextStyle(
                                                    color: Colors.redAccent,
                                                    fontSize: 11,
                                                    height: 1.35,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        actionsAlignment: MainAxisAlignment.center,
                        actions: [
                          TextButton(
                            onPressed: submitting
                                ? null
                                : () {
                                    Navigator.of(
                                      dialogContext,
                                    ).pop();
                                  },
                            child: const Text(
                              'CANCELAR',
                              style: TextStyle(
                                color: Colors.white54,
                              ),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: submitting
                                ? null
                                : submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: _purple,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: _purple.withValues(
                                alpha: 0.30,
                              ),
                              disabledForegroundColor: Colors.white54,
                            ),
                            icon: submitting
                                ? const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.lock_reset_rounded,
                                    size: 18,
                                  ),
                            label: Text(
                              submitting
                                  ? 'ALTERANDO...'
                                  : 'ALTERAR SENHA',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
              );
            },
      );
    } finally {
      currentPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    }
  }

  Widget _modalPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required bool enabled,
    required VoidCallback onToggleVisibility,
    required ValueChanged<
      String
    >
    onSubmitted,
    String? hintText,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      enableSuggestions: false,
      autocorrect: false,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
      ),
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
        ),
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Colors.white24,
          fontSize: 11,
        ),
        filled: true,
        fillColor: Colors.black.withValues(
          alpha: 0.20,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            12,
          ),
          borderSide: BorderSide(
            color: Colors.white.withValues(
              alpha: 0.07,
            ),
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            12,
          ),
          borderSide: BorderSide(
            color: Colors.white.withValues(
              alpha: 0.04,
            ),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            12,
          ),
          borderSide: BorderSide(
            color: _accent.withValues(
              alpha: 0.55,
            ),
          ),
        ),
        suffixIcon: IconButton(
          onPressed: enabled
              ? onToggleVisibility
              : null,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.white38,
            size: 19,
          ),
        ),
      ),
    );
  }

  String _passwordErrorMessage(
    AuthException error,
  ) {
    final message = error.message.toLowerCase();

    if (message.contains(
          'current password',
        ) ||
        message.contains(
          'password is incorrect',
        ) ||
        message.contains(
          'invalid login credentials',
        )) {
      return 'A senha atual está incorreta.';
    }

    if (message.contains(
          'same password',
        ) ||
        message.contains(
          'different from the old password',
        )) {
      return 'A nova senha deve ser diferente da senha atual.';
    }

    if (message.contains(
          'weak password',
        ) ||
        message.contains(
          'password should be at least',
        )) {
      return 'A nova senha não atende aos requisitos de segurança.';
    }

    return error.message;
  }

  Future<
    void
  >
  _confirmDeleteData() async {
    final confirmed = await _typedDangerConfirmation(
      icon: Icons.delete_sweep_outlined,
      title: 'Excluir seus dados?',
      message: 'Os conteúdos e dados pessoais vinculados à aplicação serão apagados. Sua conta continuará existindo.',
      confirmationPhrase: 'EXCLUIR DADOS',
      buttonText: 'EXCLUIR DADOS',
    );

    if (confirmed !=
            true ||
        !mounted) {
      return;
    }

    await _deleteData();
  }

  Future<
    void
  >
  _deleteData() async {
    setState(
      () {
        _deletingData = true;
      },
    );

    try {
      await _supabase.rpc(
        'delete_my_app_data',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Seus dados foram excluídos.',
      );
    } on PostgrestException catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
        error: true,
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Não foi possível excluir seus dados: $error',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _deletingData = false;
          },
        );
      }
    }
  }

  Future<
    void
  >
  _confirmDeleteAccount() async {
    final confirmed = await _typedDangerConfirmation(
      icon: Icons.person_remove_alt_1_outlined,
      title: 'Excluir conta permanentemente?',
      message: 'Sua conta, seus dados e o acesso ao Versin serão removidos permanentemente. Esta ação não pode ser desfeita.',
      confirmationPhrase: 'EXCLUIR CONTA',
      buttonText: 'EXCLUIR CONTA',
    );

    if (confirmed !=
            true ||
        !mounted) {
      return;
    }

    await _deleteAccount();
  }

  Future<
    void
  >
  _deleteAccount() async {
    setState(
      () {
        _deletingAccount = true;
      },
    );

    try {
      await _supabase.rpc(
        'delete_my_account',
      );

      try {
        await _supabase.auth.signOut();
      } catch (
        _
      ) {
        // A sessão pode já ter sido invalidada ao remover auth.users.
      }

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).popUntil(
        (
          route,
        ) => route.isFirst,
      );
    } on PostgrestException catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
        error: true,
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Não foi possível excluir a conta: $error',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _deletingAccount = false;
          },
        );
      }
    }
  }

  Future<
    bool?
  >
  _typedDangerConfirmation({
    required IconData icon,
    required String title,
    required String message,
    required String confirmationPhrase,
    required String buttonText,
  }) async {
    final controller = TextEditingController();

    try {
      return await showDialog<
        bool
      >(
        context: context,
        barrierDismissible: false,
        builder:
            (
              dialogContext,
            ) {
              return StatefulBuilder(
                builder:
                    (
                      context,
                      setDialogState,
                    ) {
                      final typedText = controller.text.trim();
                      final canConfirm =
                          typedText ==
                          confirmationPhrase;

                      return AlertDialog(
                        backgroundColor: _surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            20,
                          ),
                        ),
                        icon: Icon(
                          icon,
                          color: Colors.redAccent,
                          size: 34,
                        ),
                        title: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: SizedBox(
                          width: 430,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Text(
                                'Para confirmar, digite exatamente:',
                                style: TextStyle(
                                  color: Colors.white.withValues(
                                    alpha: 0.55,
                                  ),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(
                                height: 7,
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    10,
                                  ),
                                  border: Border.all(
                                    color: Colors.redAccent.withValues(
                                      alpha: 0.18,
                                    ),
                                  ),
                                ),
                                child: SelectableText(
                                  confirmationPhrase,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              TextField(
                                controller: controller,
                                autofocus: true,
                                textCapitalization: TextCapitalization.characters,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                onChanged:
                                    (
                                      _,
                                    ) {
                                      setDialogState(
                                        () {},
                                      );
                                    },
                                onSubmitted:
                                    (
                                      _,
                                    ) {
                                      if (!canConfirm) {
                                        return;
                                      }

                                      Navigator.of(
                                        dialogContext,
                                      ).pop(
                                        true,
                                      );
                                    },
                                decoration: InputDecoration(
                                  hintText: confirmationPhrase,
                                  hintStyle: const TextStyle(
                                    color: Colors.white24,
                                    fontSize: 12,
                                  ),
                                  filled: true,
                                  fillColor: Colors.black.withValues(
                                    alpha: 0.20,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 13,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      12,
                                    ),
                                    borderSide: BorderSide(
                                      color: canConfirm
                                          ? Colors.redAccent.withValues(
                                              alpha: 0.55,
                                            )
                                          : Colors.white.withValues(
                                              alpha: 0.07,
                                            ),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      12,
                                    ),
                                    borderSide: BorderSide(
                                      color: canConfirm
                                          ? Colors.redAccent
                                          : Colors.white.withValues(
                                              alpha: 0.18,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(
                                  milliseconds: 160,
                                ),
                                child: canConfirm
                                    ? const Row(
                                        key: ValueKey(
                                          'confirmed',
                                        ),
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline_rounded,
                                            size: 14,
                                            color: Colors.redAccent,
                                          ),
                                          SizedBox(
                                            width: 6,
                                          ),
                                          Text(
                                            'Confirmação válida.',
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox(
                                        key: ValueKey(
                                          'empty',
                                        ),
                                        height: 14,
                                      ),
                              ),
                            ],
                          ),
                        ),
                        actionsAlignment: MainAxisAlignment.center,
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(
                                dialogContext,
                              ).pop(
                                false,
                              );
                            },
                            child: const Text(
                              'CANCELAR',
                              style: TextStyle(
                                color: Colors.white54,
                              ),
                            ),
                          ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              disabledBackgroundColor: Colors.redAccent.withValues(
                                alpha: 0.18,
                              ),
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white.withValues(
                                alpha: 0.30,
                              ),
                            ),
                            onPressed: canConfirm
                                ? () {
                                    Navigator.of(
                                      dialogContext,
                                    ).pop(
                                      true,
                                    );
                                  }
                                : null,
                            icon: const Icon(
                              Icons.delete_forever_rounded,
                              size: 17,
                            ),
                            label: Text(
                              buttonText,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
              );
            },
      );
    } finally {
      controller.dispose();
    }
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
        context,
      )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error
              ? const Color(
                  0xFF3B161C,
                )
              : const Color(
                  0xFF1D2E24,
                ),
          content: Text(
            message,
          ),
        ),
      );
  }
}
