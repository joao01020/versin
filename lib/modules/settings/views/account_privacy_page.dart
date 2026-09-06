import 'package:flutter/material.dart';

import 'package:versin/app/locator.dart';
import 'package:versin/app/routes/app_routes.dart';
import 'package:versin/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:versin/modules/profile/services/presence/user_presence_service.dart';
import 'package:versin/modules/settings/account/controllers/account_security_controller.dart';
import 'package:versin/modules/settings/account/domain/repositories/account_security_repository.dart';

class AccountPrivacyPage extends StatefulWidget {
  const AccountPrivacyPage({super.key});

  @override
  State<AccountPrivacyPage> createState() => _AccountPrivacyPageState();
}

class _AccountPrivacyPageState extends State<AccountPrivacyPage> {
  static const Color _background = Color(0xFF0D0B1F);
  static const Color _surface = Color(0xFF17132D);
  static const Color _purple = Color(0xFF6A1B9A);
  static const Color _accent = Color(0xFFE040FB);

  late final AccountSecurityController _controller;

  @override
  void initState() {
    super.initState();

    _controller = sl<AccountSecurityController>();
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        title: const Text(
          'Conta & Privacidade',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAccountHeader(),
              const SizedBox(height: 24),
              _sectionTitle('Segurança da conta'),
              _card(
                child: _actionTile(
                  icon: Icons.password_rounded,
                  iconColor: _accent,
                  title: 'Alterar senha',
                  subtitle: 'Confirme sua senha atual e defina uma nova senha.',
                  loading: _controller.changingPassword,
                  onTap: _controller.busy ? null : _openChangePasswordModal,
                ),
              ),
              const SizedBox(height: 24),
              _sectionTitle('Seus dados'),
              _card(
                child: _actionTile(
                  icon: Icons.delete_sweep_outlined,
                  iconColor: Colors.orangeAccent,
                  title: 'Excluir meus dados',
                  subtitle:
                      'Remove seus dados pessoais do Versin, mantendo apenas a conta de acesso.',
                  loading: _controller.deletingData,
                  onTap: _controller.busy ? null : _confirmDeleteData,
                ),
              ),
              const SizedBox(height: 24),
              _sectionTitle('Zona de risco', color: Colors.redAccent),
              _card(
                borderColor: Colors.redAccent.withValues(alpha: 0.20),
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
                    const SizedBox(height: 6),
                    const Text(
                      'A conta de autenticação é removida e a sessão é encerrada. '
                      'Registros compartilhados ou históricos podem ser preservados de forma anonimizada.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _actionTile(
                      icon: Icons.person_remove_alt_1_outlined,
                      iconColor: Colors.redAccent,
                      title: 'Excluir conta permanentemente',
                      subtitle:
                          'Remove sua identidade de acesso e os dados pessoais elimináveis.',
                      loading: _controller.deletingAccount,
                      danger: true,
                      onTap: _controller.busy ? null : _confirmDeleteAccount,
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

  Widget _buildAccountHeader() {
    final email = _controller.email ?? 'Conta autenticada';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accent.withValues(alpha: 0.20)),
            ),
            child: const Icon(Icons.shield_outlined, color: _accent),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 3),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, {Color color = _accent}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: color.withValues(alpha: 0.90),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _card({required Widget child, Color? borderColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.08),
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
      enabled: onTap != null,
      leading: loading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: iconColor,
              ),
            )
          : Icon(icon, color: iconColor, size: 23),
      title: Text(
        title,
        style: TextStyle(
          color: danger ? Colors.redAccent : Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.46),
            fontSize: 11,
            height: 1.35,
          ),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
      onTap: onTap,
    );
  }

  Future<void> _openChangePasswordModal() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    var obscureCurrentPassword = true;
    var obscureNewPassword = true;
    var obscureConfirmPassword = true;
    var submitting = false;
    String? validationMessage;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> submit() async {
                if (submitting) {
                  return;
                }

                final currentPassword = currentPasswordController.text;
                final newPassword = newPasswordController.text;
                final confirmation = confirmPasswordController.text;

                String? error;

                if (currentPassword.isEmpty) {
                  error = 'Digite sua senha atual.';
                } else if (newPassword.length < 8) {
                  error = 'A nova senha precisa ter pelo menos 8 caracteres.';
                } else if (newPassword != confirmation) {
                  error = 'A confirmação da nova senha não coincide.';
                } else if (currentPassword == newPassword) {
                  error = 'A nova senha deve ser diferente da senha atual.';
                }

                if (error != null) {
                  setDialogState(() {
                    validationMessage = error;
                  });
                  return;
                }

                setDialogState(() {
                  submitting = true;
                  validationMessage = null;
                });

                try {
                  await _controller.changePassword(
                    currentPassword: currentPassword,
                    newPassword: newPassword,
                  );

                  if (!dialogContext.mounted) {
                    return;
                  }

                  Navigator.of(dialogContext).pop();

                  if (!mounted) {
                    return;
                  }

                  _showMessage('Senha alterada com sucesso.');
                } on AccountSecurityException catch (error) {
                  if (!dialogContext.mounted) {
                    return;
                  }

                  setDialogState(() {
                    submitting = false;
                    validationMessage = error.message;
                  });
                } catch (error) {
                  if (!dialogContext.mounted) {
                    return;
                  }

                  setDialogState(() {
                    submitting = false;
                    validationMessage = 'Não foi possível alterar a senha.';
                  });
                }
              }

              return AlertDialog(
                backgroundColor: _surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
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
                      children: [
                        const Text(
                          'Confirme sua senha atual antes de definir uma nova.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _modalPasswordField(
                          controller: currentPasswordController,
                          label: 'Senha atual',
                          obscureText: obscureCurrentPassword,
                          enabled: !submitting,
                          onToggleVisibility: () {
                            setDialogState(() {
                              obscureCurrentPassword = !obscureCurrentPassword;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _modalPasswordField(
                          controller: newPasswordController,
                          label: 'Nova senha',
                          hintText: 'Mínimo de 8 caracteres',
                          obscureText: obscureNewPassword,
                          enabled: !submitting,
                          onToggleVisibility: () {
                            setDialogState(() {
                              obscureNewPassword = !obscureNewPassword;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _modalPasswordField(
                          controller: confirmPasswordController,
                          label: 'Confirmar nova senha',
                          obscureText: obscureConfirmPassword,
                          enabled: !submitting,
                          onToggleVisibility: () {
                            setDialogState(() {
                              obscureConfirmPassword = !obscureConfirmPassword;
                            });
                          },
                        ),
                        if (validationMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.redAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 7),
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
                            Navigator.of(dialogContext).pop();
                          },
                    child: const Text(
                      'CANCELAR',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: submitting ? null : submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: _purple,
                      foregroundColor: Colors.white,
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
                        : const Icon(Icons.lock_reset_rounded, size: 18),
                    label: Text(
                      submitting ? 'ALTERANDO...' : 'ALTERAR SENHA',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
    String? hintText,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      enableSuggestions: false,
      autocorrect: false,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.20),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accent.withValues(alpha: 0.55)),
        ),
        suffixIcon: IconButton(
          onPressed: enabled ? onToggleVisibility : null,
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

  Future<void> _confirmDeleteData() async {
    final confirmed = await _typedDangerConfirmation(
      icon: Icons.delete_sweep_outlined,
      title: 'Excluir seus dados?',
      message:
          'Seus dados pessoais elimináveis serão apagados. '
          'Registros compartilhados ou históricos podem ser preservados de forma anonimizada. '
          'Sua conta de acesso continuará existindo.',
      confirmationPhrase: 'EXCLUIR DADOS',
      buttonText: 'EXCLUIR DADOS',
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await _controller.deleteAppData();

      if (!mounted) {
        return;
      }

      _showMessage('Seus dados pessoais foram removidos.');
    } on AccountSecurityException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message, error: true);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await _typedDangerConfirmation(
      icon: Icons.person_remove_alt_1_outlined,
      title: 'Excluir conta permanentemente?',
      message:
          'A conta será removida e a sessão será encerrada. '
          'Esta ação não pode ser desfeita.',
      confirmationPhrase: 'EXCLUIR CONTA',
      buttonText: 'EXCLUIR CONTA',
    );

    if (confirmed != true || !mounted) {
      return;
    }

    UserPresenceService? presenceService;

    if (sl.isRegistered<UserPresenceService>()) {
      presenceService = sl<UserPresenceService>();
      presenceService.stop();
    }

    try {
      await _controller.deleteAccount();

      if (sl.isRegistered<DashboardController>()) {
        sl<DashboardController>().resetNavigation();
      }

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } on AccountSecurityException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message, error: true);
    }
  }

  Future<bool?> _typedDangerConfirmation({
    required IconData icon,
    required String title,
    required String message,
    required String confirmationPhrase,
    required String buttonText,
  }) async {
    final controller = TextEditingController();

    try {
      return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final canConfirm = controller.text.trim() == confirmationPhrase;

              return AlertDialog(
                backgroundColor: _surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                icon: Icon(icon, color: Colors.redAccent, size: 34),
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
                      const SizedBox(height: 20),
                      const Text(
                        'Para confirmar, digite exatamente:',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.18),
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
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        onChanged: (_) {
                          setDialogState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: confirmationPhrase,
                          hintStyle: const TextStyle(
                            color: Colors.white24,
                            fontSize: 12,
                          ),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.20),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: canConfirm
                                  ? Colors.redAccent.withValues(alpha: 0.55)
                                  : Colors.white.withValues(alpha: 0.07),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: canConfirm
                                  ? Colors.redAccent
                                  : Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(false);
                    },
                    child: const Text(
                      'CANCELAR',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: canConfirm
                        ? () {
                            Navigator.of(dialogContext).pop(true);
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.delete_forever_rounded, size: 17),
                    label: Text(
                      buttonText,
                      style: const TextStyle(fontWeight: FontWeight.bold),
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

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error
              ? const Color(0xFF3B161C)
              : const Color(0xFF1D2E24),
          content: Text(message),
        ),
      );
  }
}
