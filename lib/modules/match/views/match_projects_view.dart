import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/modules/networking/views/networking_session_view.dart';
import 'package:versin/modules/profile/services/profile_name_cache_service.dart';

// ============================================================
// MATCH PROJECTS VIEW
// ============================================================
//
// Lista somente Studio Sessions:
//
// - criadas pelo Match;
// - ativas;
// - das quais o usuário autenticado participa.
//
// Banco:
//
// public.projects
//
// Filtros:
//
// origin = 'match'
// status = 'active'
// members contém auth.uid()
//
// Ao tocar em um projeto:
//
// MatchProjectsView
//        ↓
// NetworkingSessionView(projectId)
//
// ============================================================

class MatchProjectsView extends StatefulWidget {
  const MatchProjectsView({super.key});

  @override
  State<MatchProjectsView> createState() => _MatchProjectsViewState();
}

// ============================================================
// STATE
// ============================================================

class _MatchProjectsViewState extends State<MatchProjectsView> {
  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color _background = Color(0xFF08080B);
  static const Color _surface = Color(0xFF111116);
  static const Color _surfaceLight = Color(0xFF17171E);
  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _purpleLight = Color(0xFFA78BFA);
  static const Color _green = Color(0xFF34D399);

  // ==========================================================
  // SUPABASE
  // ==========================================================

  final SupabaseClient _supabase = Supabase.instance.client;

  // ==========================================================
  // STATE
  // ==========================================================

  bool _isLoading = true;

  String? _errorMessage;

  String? _renamingProjectId;

  List<_MatchProjectItem> _projects = const <_MatchProjectItem>[];

  // ==========================================================
  // PROFILE NAME CACHE
  // ==========================================================

  late final ProfileNameCacheService _profileNameCacheService;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _profileNameCacheService = ProfileNameCacheService();

    _initialize();
  }

  // ==========================================================
  // INITIALIZE
  // ==========================================================

  Future<void> _initialize() async {
    await _profileNameCacheService.init();

    if (!mounted) {
      return;
    }

    await _loadProjects();
  }

  // ==========================================================
  // CURRENT USER
  // ==========================================================

  String? get _currentUserId {
    final userId = _supabase.auth.currentUser?.id.trim();

    if (userId == null || userId.isEmpty) {
      return null;
    }

    return userId;
  }

  // ==========================================================
  // LOAD PROJECTS
  // ==========================================================

  Future<void> _loadProjects() async {
    if (!mounted) {
      return;
    }

    final userId = _currentUserId;

    if (userId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Usuário não autenticado.';
        _projects = const <_MatchProjectItem>[];
      });

      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ========================================================
      // PROJECTS
      // ========================================================

      final response = await _supabase
          .from('projects')
          .select(
            'id, title, members, founders, status, origin, created_at, updated_at',
          )
          .eq('origin', 'match')
          .eq('status', 'active')
          .contains('members', <String>[userId])
          .order('updated_at', ascending: false);

      final rows = List<Map<String, dynamic>>.from(response);

      // ========================================================
      // TODOS OS MEMBER IDS
      // ========================================================
      //
      // Antes cada projeto fazia uma consulta para cada membro.
      //
      // Agora:
      //
      // projects
      //    ↓
      // reúne todos os IDs
      //    ↓
      // ProfileNameCacheService.getNames(...)
      //    ↓
      // cache RAM / SharedPreferences / 1 consulta em lote
      //
      // ========================================================

      final allMemberIds = <String>{};

      for (final row in rows) {
        allMemberIds.addAll(_readStringList(row['members']));
      }

      final namesByUserId = await _profileNameCacheService.getNames(
        allMemberIds,
      );

      final items = <_MatchProjectItem>[];

      for (final row in rows) {
        final projectId = row['id']?.toString().trim() ?? '';

        if (projectId.isEmpty) {
          continue;
        }

        final members = _readStringList(row['members']);

        final founders = _readStringList(row['founders']);

        final memberNames = members
            .map((memberId) => namesByUserId[memberId] ?? 'Membro')
            .toList(growable: false);

        items.add(
          _MatchProjectItem(
            id: projectId,
            title: _readProjectTitle(row['title']),
            members: members,
            founders: founders,
            memberNames: memberNames,
            createdAt: _readDateTime(row['created_at']),
            updatedAt: _readDateTime(row['updated_at']),
          ),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _projects = List<_MatchProjectItem>.unmodifiable(items);

        _isLoading = false;
      });
    } on PostgrestException catch (error, stackTrace) {
      debugPrint(
        '[MATCH PROJECTS] '
        'Erro Supabase: ${error.message}',
      );

      debugPrint(
        '[MATCH PROJECTS] '
        'Código: ${error.code}',
      );

      debugPrint('$stackTrace');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    } catch (error, stackTrace) {
      debugPrint(
        '[MATCH PROJECTS] '
        'Erro ao carregar projetos: $error',
      );

      debugPrint('$stackTrace');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Não foi possível carregar os projetos de Match.';
      });
    }
  }

  // ==========================================================
  // SHOW RENAME PROJECT DIALOG
  // ==========================================================
  //
  // Somente founders visualizam e utilizam esta ação.
  //
  // A validação definitiva de permissão deve continuar no
  // Supabase através de RLS.
  //
  // ==========================================================

  Future<void> _showRenameProjectDialog(_MatchProjectItem project) async {
    final currentUserId = _currentUserId;

    if (currentUserId == null || !project.founders.contains(currentUserId)) {
      _showMessage('Somente fundadores podem renomear este projeto.');

      return;
    }

    if (_renamingProjectId == project.id) {
      return;
    }

    String draftTitle = project.title == 'Studio Session' ? '' : project.title;

    String? validationMessage;

    final newTitle = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void submit() {
              final normalizedTitle = draftTitle.trim();

              final validation = _validateProjectTitle(normalizedTitle);

              if (validation != null) {
                setDialogState(() {
                  validationMessage = validation;
                });

                return;
              }

              Navigator.of(dialogContext).pop(normalizedTitle);
            }

            return AlertDialog(
              backgroundColor: _surfaceLight,
              surfaceTintColor: Colors.transparent,
              title: const Text(
                'Renomear projeto',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SizedBox(
                width: 380,
                child: TextFormField(
                  initialValue: draftTitle,
                  autofocus: true,
                  maxLength: 40,
                  textInputAction: TextInputAction.done,
                  onChanged: (value) {
                    draftTitle = value;

                    if (validationMessage != null) {
                      setDialogState(() {
                        validationMessage = null;
                      });
                    }
                  },
                  onFieldSubmitted: (_) {
                    submit();
                  },
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Nome do projeto',
                    hintText: 'Ex.: Projeto - "Meu Laboratório"',
                    errorText: validationMessage,
                    labelStyle: const TextStyle(color: Colors.white54),
                    hintStyle: const TextStyle(color: Colors.white30),
                    counterStyle: const TextStyle(
                      color: Colors.white30,
                      fontSize: 9,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _purpleLight),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: submit,
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || newTitle == null) {
      return;
    }

    final normalizedCurrentTitle = project.title.trim();

    if (newTitle == normalizedCurrentTitle) {
      return;
    }

    await _renameProject(project: project, newTitle: newTitle);
  }

  // ==========================================================
  // RENAME PROJECT
  // ==========================================================

  Future<void> _renameProject({
    required _MatchProjectItem project,
    required String newTitle,
  }) async {
    final currentUserId = _currentUserId;

    if (currentUserId == null || !project.founders.contains(currentUserId)) {
      _showMessage('Somente fundadores podem renomear este projeto.');

      return;
    }

    final normalizedTitle = newTitle.trim();

    final validation = _validateProjectTitle(normalizedTitle);

    if (validation != null) {
      _showMessage(validation);

      return;
    }

    if (_renamingProjectId != null) {
      return;
    }

    setState(() {
      _renamingProjectId = project.id;
    });

    try {
      await _supabase
          .from('projects')
          .update({'title': normalizedTitle})
          .eq('id', project.id);

      if (!mounted) {
        return;
      }

      // ======================================================
      // UPDATE LOCAL STATE
      // ======================================================
      //
      // Atualiza a lista imediatamente sem exigir que o usuário
      // saia e entre novamente na tela.
      //
      // ======================================================

      setState(() {
        _projects = List<_MatchProjectItem>.unmodifiable(
          _projects.map((item) {
            if (item.id != project.id) {
              return item;
            }

            return item.copyWith(
              title: normalizedTitle,
              updatedAt: DateTime.now(),
            );
          }),
        );

        _renamingProjectId = null;
      });

      _showMessage('Nome do projeto atualizado.');

      // ======================================================
      // REFRESH REMOTO
      // ======================================================
      //
      // Recarrega para manter a lista sincronizada com o banco.
      //
      // ======================================================

      await _loadProjects();
    } on PostgrestException catch (error, stackTrace) {
      debugPrint(
        '[MATCH PROJECTS] '
        'Erro ao renomear projeto: ${error.message}',
      );

      debugPrint(
        '[MATCH PROJECTS] '
        'Código: ${error.code}',
      );

      debugPrint('$stackTrace');

      if (!mounted) {
        return;
      }

      setState(() {
        _renamingProjectId = null;
      });

      _showMessage('Não foi possível renomear o projeto.');
    } catch (error, stackTrace) {
      debugPrint(
        '[MATCH PROJECTS] '
        'Erro inesperado ao renomear projeto: $error',
      );

      debugPrint('$stackTrace');

      if (!mounted) {
        return;
      }

      setState(() {
        _renamingProjectId = null;
      });

      _showMessage('Não foi possível renomear o projeto.');
    }
  }

  // ==========================================================
  // VALIDATE PROJECT TITLE
  // ==========================================================

  String? _validateProjectTitle(String title) {
    final normalizedTitle = title.trim();

    if (normalizedTitle.isEmpty) {
      return 'Informe um nome para o projeto.';
    }

    if (normalizedTitle.length < 3) {
      return 'Use pelo menos 3 caracteres.';
    }

    if (normalizedTitle.length > 40) {
      return 'Use no máximo 40 caracteres.';
    }

    return null;
  }

  // ==========================================================
  // SHOW MESSAGE
  // ==========================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ==========================================================
  // OPEN PROJECT
  // ==========================================================

  Future<void> _openProject(_MatchProjectItem project) async {
    if (!mounted) {
      return;
    }

    final projectId = project.id.trim();

    if (projectId.isEmpty) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return NetworkingSessionView(projectId: projectId);
        },
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadProjects();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,

      appBar: AppBar(
        backgroundColor: Colors.transparent,

        surfaceTintColor: Colors.transparent,

        elevation: 0,

        titleSpacing: 4,

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              'Projetos de Match',

              style: TextStyle(
                color: Colors.white,

                fontSize: 16,

                fontWeight: FontWeight.w700,
              ),
            ),

            Text(
              'Studio Sessions ativas',

              style: TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Atualizar',

            onPressed: _isLoading ? null : _loadProjects,

            icon: const Icon(Icons.refresh_rounded, size: 19),
          ),
        ],
      ),

      body: SafeArea(top: false, child: _buildBody()),
    );
  }

  // ==========================================================
  // BODY
  // ==========================================================

  Widget _buildBody() {
    if (_isLoading && _projects.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _purple));
    }

    if (_errorMessage != null && _projects.isEmpty) {
      return _buildError();
    }

    return RefreshIndicator(
      onRefresh: _loadProjects,

      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),

        children: [
          _buildHeader(),

          const SizedBox(height: 22),

          _buildSectionHeader(),

          const SizedBox(height: 10),

          if (_projects.isEmpty)
            _buildEmpty()
          else
            ..._projects.map(_buildProjectCard),
        ],
      ),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeader() {
    final count = _projects.length;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),

        gradient: const LinearGradient(
          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

          colors: [Color(0xFF21113E), _surface],
        ),

        border: Border.all(color: _purple.withValues(alpha: 0.22)),
      ),

      child: Row(
        children: [
          Container(
            width: 50,

            height: 50,

            alignment: Alignment.center,

            decoration: BoxDecoration(
              color: _purple.withValues(alpha: 0.12),

              borderRadius: BorderRadius.circular(16),

              border: Border.all(color: _purple.withValues(alpha: 0.22)),
            ),

            child: const Icon(
              Icons.workspaces_outline,

              color: _purpleLight,

              size: 24,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  '$count ${count == 1 ? "projeto ativo" : "projetos ativos"}',

                  style: const TextStyle(
                    color: Colors.white,

                    fontSize: 16,

                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Studio Sessions criadas a partir dos seus Matches.',

                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SECTION HEADER
  // ==========================================================

  Widget _buildSectionHeader() {
    return const Row(
      children: [
        Expanded(
          child: Text(
            'PROJETOS ATIVOS',

            style: TextStyle(
              color: Colors.white38,

              fontSize: 10,

              fontWeight: FontWeight.w700,

              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // PROJECT CARD
  // ==========================================================

  Widget _buildProjectCard(_MatchProjectItem project) {
    final currentUserId = _currentUserId;

    final isFounder =
        currentUserId != null && project.founders.contains(currentUserId);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),

      decoration: BoxDecoration(
        color: _surface,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: isFounder
              ? _purple.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: () {
            _openProject(project);
          },

          borderRadius: BorderRadius.circular(18),

          child: Padding(
            padding: const EdgeInsets.all(14),

            child: Row(
              children: [
                Container(
                  width: 46,

                  height: 46,

                  alignment: Alignment.center,

                  decoration: BoxDecoration(
                    color: _purple.withValues(alpha: 0.10),

                    borderRadius: BorderRadius.circular(14),
                  ),

                  child: const Icon(
                    Icons.music_note_rounded,

                    color: _purpleLight,

                    size: 21,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              project.title,

                              maxLines: 1,

                              overflow: TextOverflow.ellipsis,

                              style: const TextStyle(
                                color: Colors.white,

                                fontSize: 13,

                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          if (isFounder) ...[
                            const SizedBox(width: 6),

                            _buildRenameButton(project),

                            const SizedBox(width: 4),

                            _buildFounderBadge(),
                          ],
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        project.memberNamesLabel,

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          color: Colors.white38,

                          fontSize: 10,
                        ),
                      ),

                      const SizedBox(height: 9),

                      Wrap(
                        spacing: 7,

                        runSpacing: 6,

                        children: [
                          _buildInfoChip(
                            icon: Icons.groups_2_outlined,

                            text:
                                '${project.memberCount} '
                                '${project.memberCount == 1 ? "membro" : "membros"}',

                            color: _purpleLight,
                          ),

                          _buildInfoChip(
                            icon: Icons.circle,

                            text: 'Ativo',

                            color: _green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                const Icon(
                  Icons.chevron_right_rounded,

                  color: Colors.white24,

                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // RENAME BUTTON
  // ==========================================================

  Widget _buildRenameButton(_MatchProjectItem project) {
    final isRenaming = _renamingProjectId == project.id;

    return Tooltip(
      message: 'Renomear projeto',
      child: InkWell(
        onTap: isRenaming
            ? null
            : () {
                _showRenameProjectDialog(project);
              },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _purple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: isRenaming
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: _purpleLight,
                  ),
                )
              : const Icon(Icons.edit_outlined, color: _purpleLight, size: 14),
        ),
      ),
    );
  }

  // ==========================================================
  // FOUNDER BADGE
  // ==========================================================

  Widget _buildFounderBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),

      decoration: BoxDecoration(
        color: _purple.withValues(alpha: 0.12),

        borderRadius: BorderRadius.circular(20),
      ),

      child: const Text(
        'FUNDADOR',

        style: TextStyle(
          color: _purpleLight,

          fontSize: 7,

          fontWeight: FontWeight.w800,

          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ==========================================================
  // INFO CHIP
  // ==========================================================

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(icon, color: color, size: icon == Icons.circle ? 6 : 11),

          const SizedBox(width: 5),

          Text(
            text,

            style: TextStyle(
              color: color,

              fontSize: 8,

              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // EMPTY
  // ==========================================================

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(28),

      decoration: BoxDecoration(
        color: _surface,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),

      child: const Column(
        children: [
          Icon(Icons.workspaces_outline, color: Colors.white24, size: 36),

          SizedBox(height: 12),

          Text(
            'Nenhum projeto de Match ativo',

            textAlign: TextAlign.center,

            style: TextStyle(
              color: Colors.white54,

              fontSize: 12,

              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 5),

          Text(
            'Quando um Match criar uma Studio Session, '
            'ela aparecerá aqui.',

            textAlign: TextAlign.center,

            style: TextStyle(color: Colors.white30, fontSize: 10, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 62,

              height: 62,

              alignment: Alignment.center,

              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.08),

                borderRadius: BorderRadius.circular(20),
              ),

              child: const Icon(
                Icons.error_outline_rounded,

                color: Colors.redAccent,

                size: 28,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              _errorMessage ?? 'Não foi possível carregar os projetos.',

              textAlign: TextAlign.center,

              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),

            const SizedBox(height: 14),

            TextButton.icon(
              onPressed: _loadProjects,

              icon: const Icon(Icons.refresh_rounded),

              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  List<String> _readStringList(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }

    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  String _readProjectTitle(dynamic value) {
    final title = value?.toString().trim();

    if (title == null || title.isEmpty) {
      return 'Studio Session';
    }

    return title;
  }

  DateTime? _readDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    final normalized = value.toString().trim();

    if (normalized.isEmpty) {
      return null;
    }

    return DateTime.tryParse(normalized);
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    super.dispose();
  }
}

// ============================================================
// MATCH PROJECT ITEM
// ============================================================

class _MatchProjectItem {
  final String id;
  final String title;

  final List<String> members;
  final List<String> founders;
  final List<String> memberNames;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const _MatchProjectItem({
    required this.id,
    required this.title,
    required this.members,
    required this.founders,
    required this.memberNames,
    this.createdAt,
    this.updatedAt,
  });

  _MatchProjectItem copyWith({
    String? id,
    String? title,
    List<String>? members,
    List<String>? founders,
    List<String>? memberNames,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return _MatchProjectItem(
      id: id ?? this.id,
      title: title ?? this.title,
      members: members ?? this.members,
      founders: founders ?? this.founders,
      memberNames: memberNames ?? this.memberNames,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get memberCount => members.length;

  String get memberNamesLabel {
    if (memberNames.isEmpty) {
      return 'Participantes da Studio Session';
    }

    if (memberNames.length <= 3) {
      return memberNames.join(' • ');
    }

    final visible = memberNames.take(3).join(' • ');

    final remaining = memberNames.length - 3;

    return '$visible +$remaining';
  }
}
