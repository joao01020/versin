import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/app/routes/app_routes.dart';

class ArtistNamePage extends StatefulWidget {
  const ArtistNamePage({super.key});

  @override
  State<ArtistNamePage> createState() => _ArtistNamePageState();
}

class _ArtistNamePageState extends State<ArtistNamePage> {
  final TextEditingController _artistNameController = TextEditingController();

  bool _isSaving = false;

  String? _errorMessage;

  static const Color deepBg = Color(0xFF0D0B1F);

  static const Color primaryPurple = Color(0xFF6A1B9A);

  static const Color accentNeon = Color(0xFFE040FB);

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _artistNameController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: Container(
        width: double.infinity,

        height: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,

            end: Alignment.bottomRight,

            colors: [Color(0xFF1A0B2E), deepBg, Colors.black],
          ),
        ),

        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),

              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    _buildIcon(),

                    const SizedBox(height: 22),

                    const Text(
                      'Seu nome artístico',

                      textAlign: TextAlign.center,

                      style: TextStyle(
                        color: Colors.white,

                        fontSize: 26,

                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Escolha como você será identificado dentro do Versin.',

                      textAlign: TextAlign.center,

                      style: TextStyle(
                        color: Colors.white38,

                        fontSize: 12,

                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 30),

                    _buildCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ÍCONE
  // ============================================================

  Widget _buildIcon() {
    return Container(
      width: 64,

      height: 64,

      decoration: BoxDecoration(
        color: accentNeon.withValues(alpha: 0.08),

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: accentNeon.withValues(alpha: 0.20)),
      ),

      child: const Icon(
        Icons.mic_external_on_outlined,

        color: accentNeon,

        size: 30,
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _buildCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),

      child: Column(
        children: [
          // ======================================================
          // NOME ARTÍSTICO
          // ======================================================
          TextField(
            controller: _artistNameController,

            autofocus: true,

            textCapitalization: TextCapitalization.words,

            textInputAction: TextInputAction.done,

            maxLength: 40,

            onSubmitted: (_) {
              _saveArtistName();
            },

            onChanged: (_) {
              if (_errorMessage != null) {
                setState(() {
                  _errorMessage = null;
                });
              }
            },

            style: const TextStyle(color: Colors.white, fontSize: 15),

            decoration: InputDecoration(
              labelText: 'NOME ARTÍSTICO',

              hintText: 'Ex: João V',

              counterStyle: const TextStyle(color: Colors.white24, fontSize: 9),

              labelStyle: const TextStyle(
                color: Colors.white38,

                fontSize: 10,

                letterSpacing: 1,
              ),

              hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),

              prefixIcon: Icon(
                Icons.person_outline_rounded,

                color: accentNeon.withValues(alpha: 0.75),
              ),

              filled: true,

              fillColor: Colors.black.withValues(alpha: 0.20),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),

                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),

                borderSide: BorderSide(
                  color: accentNeon.withValues(alpha: 0.65),
                ),
              ),

              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),

                borderSide: BorderSide(
                  color: Colors.redAccent.withValues(alpha: 0.60),
                ),
              ),

              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),

                borderSide: const BorderSide(color: Colors.redAccent),
              ),
            ),
          ),

          // ======================================================
          // ERRO
          // ======================================================
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),

            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(10),

              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.08),

                borderRadius: BorderRadius.circular(10),

                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.18),
                ),
              ),

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Icon(
                    Icons.error_outline_rounded,

                    color: Colors.redAccent,

                    size: 16,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      _errorMessage!,

                      style: const TextStyle(
                        color: Colors.redAccent,

                        fontSize: 10,

                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // ======================================================
          // AVISO
          // ======================================================
          Container(
            width: double.infinity,

            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: accentNeon.withValues(alpha: 0.04),

              borderRadius: BorderRadius.circular(12),

              border: Border.all(color: accentNeon.withValues(alpha: 0.10)),
            ),

            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Icon(
                  Icons.info_outline_rounded,

                  color: accentNeon.withValues(alpha: 0.70),

                  size: 16,
                ),

                const SizedBox(width: 8),

                const Expanded(
                  child: Text(
                    'Esse nome será exibido como sua identidade artística dentro do Versin.',

                    style: TextStyle(
                      color: Colors.white38,

                      fontSize: 10,

                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ======================================================
          // CONTINUAR
          // ======================================================
          SizedBox(
            width: double.infinity,

            height: 52,

            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveArtistName,

              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple.withValues(alpha: 0.35),

                foregroundColor: Colors.white,

                disabledBackgroundColor: primaryPurple.withValues(alpha: 0.10),

                elevation: 0,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),

                side: BorderSide(color: accentNeon.withValues(alpha: 0.55)),
              ),

              child: _isSaving
                  ? const SizedBox(
                      width: 20,

                      height: 20,

                      child: CircularProgressIndicator(
                        strokeWidth: 2,

                        color: accentNeon,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        Icon(
                          Icons.arrow_forward_rounded,

                          color: accentNeon,

                          size: 18,
                        ),

                        SizedBox(width: 10),

                        Text(
                          'CONTINUAR',

                          style: TextStyle(
                            fontWeight: FontWeight.bold,

                            fontSize: 12,

                            letterSpacing: 1,
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

  // ============================================================
  // SALVAR NOME ARTÍSTICO
  // ============================================================

  Future<void> _saveArtistName() async {
    if (_isSaving) {
      return;
    }

    FocusScope.of(context).unfocus();

    final artistName = _artistNameController.text.trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    // ==========================================================
    // VALIDAR
    // ==========================================================

    if (artistName.isEmpty) {
      _setError('Digite seu nome artístico.');

      return;
    }

    if (artistName.length < 2) {
      _setError('O nome artístico deve ter pelo menos 2 caracteres.');

      return;
    }

    if (artistName.length > 40) {
      _setError('O nome artístico deve ter no máximo 40 caracteres.');

      return;
    }

    // ==========================================================
    // USUÁRIO
    // ==========================================================

    final supabase = Supabase.instance.client;

    final user = supabase.auth.currentUser;

    if (user == null) {
      _setError('Usuário não autenticado.');

      return;
    }

    setState(() {
      _isSaving = true;

      _errorMessage = null;
    });

    try {
      // ========================================================
      // SALVAR NO PROFILE
      // ========================================================

      await supabase.from('profiles').upsert({
        'id': user.id,

        'artist_name': artistName,

        'artist_name_updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'id');

      if (!mounted) {
        return;
      }

      // ========================================================
      // DASHBOARD
      // ========================================================

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'Não foi possível salvar o nome artístico: '
            '${error.message}';

        _isSaving = false;
      });

      debugPrint(
        '[VERSIN PROFILE] PostgrestException: '
        '${error.message}',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Não foi possível salvar o nome artístico.';

        _isSaving = false;
      });

      debugPrint('[VERSIN PROFILE] Erro ao salvar artist_name: $error');
    }
  }

  // ============================================================
  // ERRO
  // ============================================================

  void _setError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _errorMessage = message;
    });
  }
}
