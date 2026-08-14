import 'package:flutter/material.dart';

import '../models/track_audience_model.dart';
import '../services/profile_track_picker_service.dart';

// ============================================================
// ADD PROFILE TRACK RESULT
// ============================================================
//
// Resultado do modal.
//
// A página recebe esse objeto e chama:
//
// PublicProfileController.addTrack(...)
//
// ============================================================

class AddProfileTrackResult {
  final String title;

  final PickedProfileTrack file;

  final TrackAudienceModel audience;

  const AddProfileTrackResult({
    required this.title,
    required this.file,
    required this.audience,
  });
}

// ============================================================
// ADD PROFILE TRACK SHEET
// ============================================================
//
// Modal responsável por:
//
// - título;
// - selecionar áudio;
// - selecionar quem pode ouvir;
// - validar;
// - devolver resultado.
//
// NÃO:
//
// - faz upload;
// - acessa Supabase;
// - cria linha no banco.
//
// ============================================================

class AddProfileTrackSheet extends StatefulWidget {
  final Color accentColor;

  const AddProfileTrackSheet({
    super.key,
    this.accentColor = const Color(0xFFE100FF),
  });

  // ============================================================
  // SHOW
  // ============================================================

  static Future<AddProfileTrackResult?> show({
    required BuildContext context,
    Color accentColor = const Color(0xFFE100FF),
  }) {
    return showModalBottomSheet<AddProfileTrackResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AddProfileTrackSheet(accentColor: accentColor);
      },
    );
  }

  @override
  State<AddProfileTrackSheet> createState() => _AddProfileTrackSheetState();
}

// ============================================================
// STATE
// ============================================================

class _AddProfileTrackSheetState extends State<AddProfileTrackSheet> {
  // ============================================================
  // SERVICES
  // ============================================================

  final ProfileTrackPickerService _pickerService = ProfileTrackPickerService();

  // ============================================================
  // FORM
  // ============================================================

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();

  // ============================================================
  // FILE
  // ============================================================

  PickedProfileTrack? _selectedFile;

  bool _isPicking = false;

  // ============================================================
  // AUDIENCE
  // ============================================================

  TrackAudienceModel _audience = const TrackAudienceModel.empty();

  // ============================================================
  // ROLES
  // ============================================================
  //
  // Ajuste os IDs se os seus MusicRole reais forem diferentes.
  //
  // ============================================================

  static const List<_AudienceOption> _audienceOptions = <_AudienceOption>[
    _AudienceOption(
      id: 'artist',
      label: 'Artistas',
      icon: Icons.mic_external_on_outlined,
    ),
    _AudienceOption(
      id: 'beatmaker',
      label: 'Beatmakers',
      icon: Icons.graphic_eq_rounded,
    ),
    _AudienceOption(
      id: 'producer',
      label: 'Produtores',
      icon: Icons.tune_rounded,
    ),
    _AudienceOption(
      id: 'composer',
      label: 'Compositores',
      icon: Icons.edit_note_rounded,
    ),
  ];

  // ============================================================
  // SELECT FILE
  // ============================================================

  Future<void> _selectFile() async {
    if (_isPicking) {
      return;
    }

    setState(() {
      _isPicking = true;
    });

    try {
      final file = await _pickerService.pickTrack();

      if (!mounted || file == null) {
        return;
      }

      setState(() {
        _selectedFile = file;

        if (_titleController.text.trim().isEmpty) {
          _titleController.text = _titleFromFileName(file.fileName);
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isPicking = false;
      });
    }
  }

  // ============================================================
  // TOGGLE ROLE
  // ============================================================

  void _toggleRole(String role) {
    setState(() {
      _audience = _audience.toggle(role);
    });
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  void _submit() {
    FocusScope.of(context).unfocus();

    final valid = _formKey.currentState?.validate() ?? false;

    if (!valid) {
      return;
    }

    final file = _selectedFile;

    if (file == null) {
      _showError('Selecione uma música.');

      return;
    }

    if (_audience.isEmpty) {
      _showError('Escolha pelo menos um grupo que poderá ouvir a demo.');

      return;
    }

    Navigator.of(context).pop(
      AddProfileTrackResult(
        title: _titleController.text.trim(),
        file: file,
        audience: _audience,
      ),
    );
  }

  // ============================================================
  // ERROR
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      margin: const EdgeInsets.only(top: 40),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF151126),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==============================================
                // HANDLE
                // ==============================================
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // ==============================================
                // HEADER
                // ==============================================
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Adicionar demo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          const Text(
                            'Publique uma prévia no seu perfil público.',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                // ==============================================
                // TITLE
                // ==============================================
                _buildLabel('Título'),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _titleController,
                  maxLength: 80,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    hint: 'Nome da demo',
                    icon: Icons.music_note_rounded,
                  ),
                  validator: (value) {
                    final normalized = value?.trim() ?? '';

                    if (normalized.isEmpty) {
                      return 'Informe o título.';
                    }

                    if (normalized.length < 2) {
                      return 'Use pelo menos 2 caracteres.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ==============================================
                // FILE
                // ==============================================
                _buildLabel('Arquivo'),

                const SizedBox(height: 8),

                _buildFileSelector(),

                const SizedBox(height: 26),

                // ==============================================
                // AUDIENCE
                // ==============================================
                _buildLabel('Quem pode ouvir?'),

                const SizedBox(height: 4),

                const Text(
                  'Selecione os grupos profissionais que terão acesso à demo.',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 12),

                _buildAudience(),

                const SizedBox(height: 28),

                // ==============================================
                // INFO
                // ==============================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white54,
                        size: 17,
                      ),

                      SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          'A reprodução será tratada como uma demo de até 60 segundos.',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ==============================================
                // PUBLISH
                // ==============================================
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text(
                      'PUBLICAR DEMO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.5,
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
  // FILE SELECTOR
  // ============================================================

  Widget _buildFileSelector() {
    final file = _selectedFile;

    if (file == null) {
      return InkWell(
        onTap: _isPicking ? null : _selectFile,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              if (_isPicking)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.accentColor,
                  ),
                )
              else
                Icon(
                  Icons.audio_file_outlined,
                  color: widget.accentColor,
                  size: 24,
                ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  _isPicking ? 'Abrindo arquivos...' : 'Selecionar MP3 / WAV',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const Icon(Icons.chevron_right_rounded, color: Colors.white30),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.accentColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.audio_file_rounded, color: widget.accentColor, size: 25),

          const SizedBox(width: 12),

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
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _formatFileSize(file.fileSizeBytes),
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Trocar arquivo',
            onPressed: _selectFile,
            icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white54),
          ),

          IconButton(
            tooltip: 'Remover',
            onPressed: () {
              setState(() {
                _selectedFile = null;
              });
            },
            icon: const Icon(Icons.close_rounded, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AUDIENCE
  // ============================================================

  Widget _buildAudience() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _audienceOptions.map((option) {
        final selected = _audience.contains(option.id);

        return FilterChip(
          selected: selected,
          onSelected: (_) {
            _toggleRole(option.id);
          },
          avatar: Icon(
            option.icon,
            size: 15,
            color: selected ? Colors.black : Colors.white54,
          ),
          label: Text(option.label),
          selectedColor: widget.accentColor,
          backgroundColor: Colors.white.withValues(alpha: 0.035),
          side: BorderSide(
            color: selected
                ? widget.accentColor
                : Colors.white.withValues(alpha: 0.08),
          ),
          labelStyle: TextStyle(
            color: selected ? Colors.black : Colors.white60,
            fontSize: 10,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _buildLabel(String value) {
    return Text(
      value,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ============================================================
  // INPUT
  // ============================================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30),
      prefixIcon: Icon(icon, color: Colors.white38),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.035),
      counterStyle: const TextStyle(color: Colors.white30),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: widget.accentColor),
      ),
    );
  }

  // ============================================================
  // FILE TITLE
  // ============================================================

  String _titleFromFileName(String fileName) {
    final normalized = fileName.trim();

    final index = normalized.lastIndexOf('.');

    if (index <= 0) {
      return normalized;
    }

    return normalized.substring(0, index);
  }

  // ============================================================
  // FILE SIZE
  // ============================================================

  String _formatFileSize(int bytes) {
    const kb = 1024;

    const mb = kb * 1024;

    if (bytes >= mb) {
      return '${(bytes / mb).toStringAsFixed(2)} MB';
    }

    if (bytes >= kb) {
      return '${(bytes / kb).toStringAsFixed(1)} KB';
    }

    return '$bytes B';
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _titleController.dispose();

    super.dispose();
  }
}

// ============================================================
// AUDIENCE OPTION
// ============================================================

class _AudienceOption {
  final String id;

  final String label;

  final IconData icon;

  const _AudienceOption({
    required this.id,
    required this.label,
    required this.icon,
  });
}
