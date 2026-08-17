import 'package:flutter/material.dart';

import '../../../controllers/project_recruitment_controller.dart';
import 'recruitment_candidates_view.dart';

// ============================================================
// CREATE RECRUITMENT VIEW
// ============================================================

class CreateRecruitmentView
    extends
        StatefulWidget {
  final String projectId;

  const CreateRecruitmentView({
    super.key,
    required this.projectId,
  });

  @override
  State<
    CreateRecruitmentView
  >
  createState() => _CreateRecruitmentViewState();
}

class _CreateRecruitmentViewState
    extends
        State<
          CreateRecruitmentView
        > {
  static const Color _background = Color(
    0xFF08080B,
  );

  static const Color _surface = Color(
    0xFF111116,
  );

  static const Color _purple = Color(
    0xFF8B5CF6,
  );

  late final ProjectRecruitmentController _controller;

  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedRole;

  final Map<
    String,
    String
  >
  _roles = const {
    'artist': 'Artista',

    'producer': 'Produtor',

    'beatmaker': 'Beatmaker',

    'songwriter': 'Compositor',

    'singer': 'Vocalista',

    'rapper': 'Rapper',

    'engineer': 'Engenheiro',
  };

  @override
  void initState() {
    super.initState();

    _controller = ProjectRecruitmentController(
      projectId: widget.projectId,
    );
  }

  // ==========================================================
  // CRIAR
  // ==========================================================

  Future<
    void
  >
  _create() async {
    final role = _selectedRole;

    if (role ==
        null) {
      _showMessage(
        'Selecione quem você procura.',
      );

      return;
    }

    final recruitment = await _controller.createRecruitment(
      role: role,

      description: _descriptionController.text,
    );

    if (!mounted ||
        recruitment ==
            null) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => RecruitmentCandidatesView(
              projectId: widget.projectId,

              recruitment: recruitment,
            ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: _background,

      appBar: AppBar(
        backgroundColor: Colors.transparent,

        surfaceTintColor: Colors.transparent,

        title: const Text(
          'Procurar membro',
          style: TextStyle(
            fontSize: 16,

            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: ListenableBuilder(
        listenable: _controller,

        builder:
            (
              context,
              _,
            ) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(
                  18,
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    _buildHero(),

                    const SizedBox(
                      height: 26,
                    ),

                    const Text(
                      'QUEM VOCÊ PROCURA?',
                      style: TextStyle(
                        color: Colors.white38,

                        fontSize: 10,

                        fontWeight: FontWeight.w700,

                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Wrap(
                      spacing: 10,

                      runSpacing: 10,

                      children: _roles.entries
                          .map(
                            (
                              entry,
                            ) => _buildRoleChip(
                              entry.key,
                              entry.value,
                            ),
                          )
                          .toList(),
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    const Text(
                      'DETALHES',
                      style: TextStyle(
                        color: Colors.white38,

                        fontSize: 10,

                        fontWeight: FontWeight.w700,

                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    TextField(
                      controller: _descriptionController,

                      maxLines: 4,

                      style: const TextStyle(
                        color: Colors.white,
                      ),

                      decoration: InputDecoration(
                        hintText: 'Ex: procuramos beatmaker para trap/dark...',

                        hintStyle: const TextStyle(
                          color: Colors.white24,
                        ),

                        filled: true,

                        fillColor: _surface,

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            18,
                          ),

                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 32,
                    ),

                    SizedBox(
                      width: double.infinity,

                      height: 52,

                      child: ElevatedButton.icon(
                        onPressed: _controller.isSaving
                            ? null
                            : _create,

                        icon: _controller.isSaving
                            ? const SizedBox(
                                width: 18,

                                height: 18,

                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.radar_rounded,
                              ),

                        label: const Text(
                          'Começar busca',
                        ),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: _purple,

                          foregroundColor: Colors.white,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
      ),
    );
  }

  // ==========================================================
  // HERO
  // ==========================================================

  Widget _buildHero() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        18,
      ),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          22,
        ),

        gradient: const LinearGradient(
          colors: [
            Color(
              0xFF21113E,
            ),

            _surface,
          ],
        ),

        border: Border.all(
          color: _purple.withValues(
            alpha: 0.22,
          ),
        ),
      ),

      child: const Row(
        children: [
          Icon(
            Icons.group_add_rounded,

            color: _purple,

            size: 30,
          ),

          SizedBox(
            width: 15,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'Expanda sua sessão',
                  style: TextStyle(
                    color: Colors.white,

                    fontSize: 16,

                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(
                  height: 5,
                ),

                Text(
                  'O Versin continuará procurando profissionais compatíveis com o projeto.',
                  style: TextStyle(
                    color: Colors.white38,

                    fontSize: 11,
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
  // ROLE
  // ==========================================================

  Widget _buildRoleChip(
    String key,
    String label,
  ) {
    final selected =
        _selectedRole ==
        key;

    return GestureDetector(
      onTap: () {
        setState(
          () {
            _selectedRole = key;
          },
        );
      },

      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 180,
        ),

        padding: const EdgeInsets.symmetric(
          horizontal: 14,

          vertical: 10,
        ),

        decoration: BoxDecoration(
          color: selected
              ? _purple.withValues(
                  alpha: 0.16,
                )
              : _surface,

          borderRadius: BorderRadius.circular(
            14,
          ),

          border: Border.all(
            color: selected
                ? _purple
                : Colors.white10,
          ),
        ),

        child: Text(
          label,

          style: TextStyle(
            color: selected
                ? _purple
                : Colors.white60,

            fontSize: 12,

            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();

    _descriptionController.dispose();

    super.dispose();
  }
}
