import 'package:flutter/material.dart';

import 'package:versin/modules/onboarding/controllers/match_onboarding_controller.dart';

// ============================================================
// MATCH USERNAME ONBOARDING CARD
// ============================================================
//
// UI responsável exclusivamente pela etapa obrigatória de
// username.
//
// NÃO:
//
// - acessa Supabase;
// - implementa debounce;
// - verifica disponibilidade diretamente;
// - salva username diretamente no backend;
// - conhece MatchPage.
//
// ============================================================

class MatchUsernameOnboardingCard
    extends
        StatelessWidget {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final MatchOnboardingController controller;

  // ============================================================
  // STYLE
  // ============================================================

  final Color accentColor;

  // ============================================================
  // CALLBACK
  // ============================================================

  final VoidCallback? onUsernameSaved;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const MatchUsernameOnboardingCard({
    super.key,
    required this.controller,
    required this.accentColor,
    this.onUsernameSaved,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedBuilder(
      animation: controller,

      builder:
          (
            context,
            child,
          ) {
            final message = controller.usernameValidationMessage;

            final available = controller.usernameAvailable;

            final checking = controller.isCheckingUsername;

            final saving = controller.isSavingUsername;

            final canSubmit = controller.canSubmitUsername;

            return Container(
              width: double.infinity,

              padding: const EdgeInsets.all(
                16,
              ),

              decoration: BoxDecoration(
                color:
                    const Color(
                      0xFF17132D,
                    ).withValues(
                      alpha: 0.82,
                    ),

                borderRadius: BorderRadius.circular(
                  18,
                ),

                border: Border.all(
                  color: accentColor.withValues(
                    alpha: 0.20,
                  ),
                ),

                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(
                      alpha: 0.04,
                    ),

                    blurRadius: 20,

                    spreadRadius: 1,
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // ================================================
                  // HEADER
                  // ================================================
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Container(
                        width: 42,

                        height: 42,

                        alignment: Alignment.center,

                        decoration: BoxDecoration(
                          color: accentColor.withValues(
                            alpha: 0.10,
                          ),

                          borderRadius: BorderRadius.circular(
                            13,
                          ),
                        ),

                        child: Icon(
                          Icons.alternate_email_rounded,

                          color: accentColor,

                          size: 21,
                        ),
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              'Complete seu perfil',

                              style: TextStyle(
                                color: Colors.white,

                                fontSize: 14,

                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            SizedBox(
                              height: 4,
                            ),

                            Text(
                              'Escolha um username único para continuar no Match.',

                              style: TextStyle(
                                color: Colors.white38,

                                fontSize: 10.5,

                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // ================================================
                  // USERNAME FIELD
                  // ================================================
                  TextField(
                    controller: controller.usernameController,

                    focusNode: controller.usernameFocusNode,

                    enabled: !saving,

                    autocorrect: false,

                    enableSuggestions: false,

                    textInputAction: TextInputAction.done,

                    onChanged: controller.onUsernameChanged,

                    onSubmitted:
                        (
                          _,
                        ) {
                          if (!controller.canSubmitUsername) {
                            return;
                          }

                          _save();
                        },

                    style: const TextStyle(
                      color: Colors.white,

                      fontSize: 12,
                    ),

                    decoration: InputDecoration(
                      hintText: 'seu_username',

                      prefixText: '@',

                      prefixStyle: TextStyle(
                        color: accentColor,

                        fontSize: 12,

                        fontWeight: FontWeight.bold,
                      ),

                      hintStyle: const TextStyle(
                        color: Colors.white24,

                        fontSize: 11,
                      ),

                      filled: true,

                      fillColor: Colors.black.withValues(
                        alpha: 0.14,
                      ),

                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,

                        vertical: 13,
                      ),

                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          13,
                        ),

                        borderSide: BorderSide(
                          color: _fieldBorderColor(
                            available: available,

                            checking: checking,
                          ),
                        ),
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          13,
                        ),

                        borderSide: BorderSide(
                          color: _focusedBorderColor(
                            available: available,

                            checking: checking,
                          ),

                          width: 1.2,
                        ),
                      ),

                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          13,
                        ),

                        borderSide: BorderSide(
                          color: Colors.white.withValues(
                            alpha: 0.05,
                          ),
                        ),
                      ),

                      suffixIcon: _buildFieldStatus(
                        available: available,

                        checking: checking,

                        saving: saving,
                      ),
                    ),
                  ),

                  // ================================================
                  // VALIDATION MESSAGE
                  // ================================================
                  if (message !=
                          null &&
                      message.trim().isNotEmpty) ...[
                    const SizedBox(
                      height: 8,
                    ),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Icon(
                          available ==
                                  true
                              ? Icons.check_circle_outline_rounded
                              : Icons.info_outline_rounded,

                          color:
                              available ==
                                  true
                              ? Colors.greenAccent
                              : available ==
                                    false
                              ? Colors.redAccent
                              : Colors.white38,

                          size: 14,
                        ),

                        const SizedBox(
                          width: 6,
                        ),

                        Expanded(
                          child: Text(
                            message,

                            style: TextStyle(
                              color:
                                  available ==
                                      true
                                  ? Colors.greenAccent
                                  : available ==
                                        false
                                  ? Colors.redAccent
                                  : Colors.white38,

                              fontSize: 9.5,

                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(
                    height: 14,
                  ),

                  // ================================================
                  // BUTTON
                  // ================================================
                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton(
                      onPressed:
                          canSubmit &&
                              !saving
                          ? _save
                          : null,

                      style: ElevatedButton.styleFrom(
                        elevation: 0,

                        backgroundColor: accentColor,

                        disabledBackgroundColor: Colors.white.withValues(
                          alpha: 0.06,
                        ),

                        foregroundColor: Colors.black,

                        disabledForegroundColor: Colors.white24,

                        padding: const EdgeInsets.symmetric(
                          vertical: 13,
                        ),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            13,
                          ),
                        ),
                      ),

                      child: saving
                          ? const SizedBox(
                              width: 18,

                              height: 18,

                              child: CircularProgressIndicator(
                                strokeWidth: 2,

                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'CONTINUAR',

                              style: TextStyle(
                                fontSize: 10,

                                fontWeight: FontWeight.w900,

                                letterSpacing: 0.8,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<
    void
  >
  _save() async {
    final saved = await controller.saveUsername();

    if (!saved) {
      return;
    }

    onUsernameSaved?.call();
  }

  // ============================================================
  // FIELD STATUS
  // ============================================================

  Widget? _buildFieldStatus({
    required bool? available,
    required bool checking,
    required bool saving,
  }) {
    if (saving ||
        checking) {
      return const Padding(
        padding: EdgeInsets.all(
          13,
        ),

        child: SizedBox(
          width: 16,

          height: 16,

          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (available ==
        true) {
      return const Icon(
        Icons.check_circle_rounded,

        color: Colors.greenAccent,

        size: 19,
      );
    }

    if (available ==
        false) {
      return const Icon(
        Icons.cancel_rounded,

        color: Colors.redAccent,

        size: 19,
      );
    }

    return null;
  }

  // ============================================================
  // FIELD BORDER COLOR
  // ============================================================

  Color _fieldBorderColor({
    required bool? available,
    required bool checking,
  }) {
    if (checking) {
      return accentColor.withValues(
        alpha: 0.25,
      );
    }

    if (available ==
        true) {
      return Colors.greenAccent.withValues(
        alpha: 0.35,
      );
    }

    if (available ==
        false) {
      return Colors.redAccent.withValues(
        alpha: 0.35,
      );
    }

    return Colors.white.withValues(
      alpha: 0.08,
    );
  }

  // ============================================================
  // FOCUSED BORDER COLOR
  // ============================================================

  Color _focusedBorderColor({
    required bool? available,
    required bool checking,
  }) {
    if (available ==
        true) {
      return Colors.greenAccent;
    }

    if (available ==
        false) {
      return Colors.redAccent;
    }

    return accentColor;
  }
}
