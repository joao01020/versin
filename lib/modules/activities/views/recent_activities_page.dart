import 'package:flutter/material.dart';

import 'package:versin/app/locator.dart';

import '../controllers/recent_activity_controller.dart';
import '../models/recent_activity_model.dart';
import '../models/recent_activity_type.dart';

// ============================================================
// RECENT ACTIVITIES PAGE
// ============================================================
//
// Página responsável por exibir o histórico de atividades
// do mês atual.
//
// Dashboard:
// → mostra somente 3 atividades.
//
// Esta página:
// → mostra todas as atividades acumuladas no mês atual.
//
// Também permite:
// → excluir uma atividade individual;
// → atualizar a lista;
// → visualizar estado vazio;
// → visualizar erro;
//
// ============================================================

class RecentActivitiesPage
    extends
        StatefulWidget {
  const RecentActivitiesPage({
    super.key,
  });

  @override
  State<
    RecentActivitiesPage
  >
  createState() => _RecentActivitiesPageState();
}

// ============================================================
// STATE
// ============================================================

class _RecentActivitiesPageState
    extends
        State<
          RecentActivitiesPage
        > {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final RecentActivityController _controller =
      sl<
        RecentActivityController
      >();

  // ============================================================
  // ESTADO
  // ============================================================

  List<
    RecentActivityModel
  >
  _monthlyActivities =
      <
        RecentActivityModel
      >[];

  bool _isLoading = false;

  String? _errorMessage;

  // ============================================================
  // CORES
  // ============================================================

  static const Color _backgroundColor = Color(
    0xFF0D0B1F,
  );

  static const Color _cardColor = Color(
    0xFF17132D,
  );

  static const Color _accentColor = Color(
    0xFFE100FF,
  );

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _controller.addListener(
      _onControllerUpdate,
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) async {
        if (!mounted) {
          return;
        }

        await _loadMonthlyActivities();
      },
    );
  }

  // ============================================================
  // CONTROLLER UPDATE
  // ============================================================

  void _onControllerUpdate() {
    if (!mounted) {
      return;
    }

    _applyMonthlyFilter(
      _controller.activities,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _controller.removeListener(
      _onControllerUpdate,
    );

    super.dispose();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<
    void
  >
  _loadMonthlyActivities() async {
    if (_isLoading) {
      return;
    }

    setState(
      () {
        _isLoading = true;

        _errorMessage = null;
      },
    );

    try {
      final activities = await _controller.getAllActivities();

      if (!mounted) {
        return;
      }

      _applyMonthlyFilter(
        activities,
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      setState(
        () {
          _errorMessage = 'Não foi possível carregar as atividades.';
        },
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _isLoading = false;
          },
        );
      }
    }
  }

  // ============================================================
  // FILTRAR MÊS ATUAL
  // ============================================================

  void _applyMonthlyFilter(
    Iterable<
      RecentActivityModel
    >
    activities,
  ) {
    final now = DateTime.now();

    final filtered = activities.where(
      (
        activity,
      ) {
        final date = activity.createdAt.toLocal();

        return date.year ==
                now.year &&
            date.month ==
                now.month;
      },
    ).toList();

    filtered.sort(
      (
        a,
        b,
      ) {
        return b.createdAt.compareTo(
          a.createdAt,
        );
      },
    );

    if (!mounted) {
      return;
    }

    setState(
      () {
        _monthlyActivities = filtered;
      },
    );
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

        centerTitle: false,

        iconTheme: const IconThemeData(
          color: Colors.white,
        ),

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Atividades',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 2,
            ),

            Text(
              _currentMonthLabel(),
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _isLoading
                ? null
                : _loadMonthlyActivities,
            icon: Icon(
              Icons.refresh_rounded,
              color: _isLoading
                  ? Colors.white12
                  : Colors.white54,
            ),
          ),

          const SizedBox(
            width: 8,
          ),
        ],
      ),

      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    // ==========================================================
    // LOADING
    // ==========================================================

    if (_isLoading &&
        _monthlyActivities.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: _accentColor,
        ),
      );
    }

    // ==========================================================
    // ERRO
    // ==========================================================

    if (_errorMessage !=
            null &&
        _monthlyActivities.isEmpty) {
      return _buildErrorState();
    }

    // ==========================================================
    // VAZIO
    // ==========================================================

    if (_monthlyActivities.isEmpty) {
      return _buildEmptyState();
    }

    // ==========================================================
    // LISTA
    // ==========================================================

    return RefreshIndicator(
      color: _accentColor,

      backgroundColor: _cardColor,

      onRefresh: _loadMonthlyActivities,

      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          20,
          16,
          20,
          30,
        ),

        itemCount: _monthlyActivities.length,

        itemBuilder:
            (
              context,
              index,
            ) {
              final activity = _monthlyActivities[index];

              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 12,
                ),
                child: _buildActivityCard(
                  activity,
                ),
              );
            },
      ),
    );
  }

  // ============================================================
  // CARD DA ATIVIDADE
  // ============================================================

  Widget _buildActivityCard(
    RecentActivityModel activity,
  ) {
    final visual = _visualForType(
      activity.type,
    );

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        16,
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
            alpha: 0.06,
          ),
        ),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ====================================================
          // ÍCONE
          // ====================================================
          Container(
            width: 42,

            height: 42,

            decoration: BoxDecoration(
              color: visual.color.withValues(
                alpha: 0.10,
              ),

              borderRadius: BorderRadius.circular(
                13,
              ),

              border: Border.all(
                color: visual.color.withValues(
                  alpha: 0.18,
                ),
              ),
            ),

            child: Icon(
              visual.icon,

              color: visual.color,

              size: 19,
            ),
          ),

          const SizedBox(
            width: 13,
          ),

          // ====================================================
          // CONTEÚDO
          // ====================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // ==============================================
                // TÍTULO
                // ==============================================
                Text(
                  activity.title,

                  style: const TextStyle(
                    color: Colors.white,

                    fontSize: 13,

                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                // ==============================================
                // DESCRIÇÃO
                // ==============================================
                Text(
                  activity.description,

                  style: const TextStyle(
                    color: Colors.white54,

                    fontSize: 10,

                    height: 1.45,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                // ==============================================
                // DATA
                // ==============================================
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,

                      color: Colors.white24,

                      size: 11,
                    ),

                    const SizedBox(
                      width: 4,
                    ),

                    Text(
                      _formatDateTime(
                        activity.createdAt,
                      ),

                      style: const TextStyle(
                        color: Colors.white24,

                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          // ====================================================
          // MENU
          // ====================================================
          PopupMenuButton<
            String
          >(
            tooltip: 'Opções',

            color: const Color(
              0xFF211C38,
            ),

            icon: const Icon(
              Icons.more_vert_rounded,

              color: Colors.white30,

              size: 18,
            ),

            onSelected:
                (
                  value,
                ) async {
                  if (value ==
                      'delete') {
                    await _confirmDelete(
                      activity,
                    );
                  }
                },

            itemBuilder:
                (
                  context,
                ) {
                  return const [
                    PopupMenuItem<
                      String
                    >(
                      value: 'delete',

                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,

                            color: Colors.redAccent,

                            size: 17,
                          ),

                          SizedBox(
                            width: 9,
                          ),

                          Text(
                            'Excluir atividade',

                            style: TextStyle(
                              color: Colors.white70,

                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONFIRMAR DELETE
  // ============================================================

  Future<
    void
  >
  _confirmDelete(
    RecentActivityModel activity,
  ) async {
    final shouldDelete =
        await showDialog<
          bool
        >(
          context: context,

          builder:
              (
                dialogContext,
              ) {
                return AlertDialog(
                  backgroundColor: const Color(
                    0xFF17132D,
                  ),

                  title: const Text(
                    'Excluir atividade?',

                    style: TextStyle(
                      color: Colors.white,

                      fontSize: 16,

                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  content: Text(
                    activity.title,

                    style: const TextStyle(
                      color: Colors.white54,

                      fontSize: 11,
                    ),
                  ),

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
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(
                          true,
                        );
                      },

                      child: const Text(
                        'EXCLUIR',

                        style: TextStyle(
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                );
              },
        );

    if (shouldDelete !=
        true) {
      return;
    }

    final success = await _controller.deleteActivity(
      activity.id,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      setState(
        () {
          _monthlyActivities.removeWhere(
            (
              item,
            ) {
              return item.id ==
                  activity.id;
            },
          );
        },
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Atividade excluída.',
          ),
        ),
      );

      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content: Text(
          'Não foi possível excluir a atividade.',
        ),
      ),
    );
  }

  // ============================================================
  // ESTADO VAZIO
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 58,

              height: 58,

              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.035,
                ),

                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.history_toggle_off_rounded,

                color: Colors.white24,

                size: 27,
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            const Text(
              'Nenhuma atividade neste mês',

              style: TextStyle(
                color: Colors.white60,

                fontSize: 12,

                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            const Text(
              'Suas principais ações aparecerão aqui conforme você utilizar o Versin.',

              textAlign: TextAlign.center,

              style: TextStyle(
                color: Colors.white24,

                fontSize: 10,

                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERRO
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          30,
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(
              Icons.error_outline_rounded,

              color: Colors.redAccent,

              size: 28,
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              _errorMessage ??
                  'Não foi possível carregar as atividades.',

              textAlign: TextAlign.center,

              style: const TextStyle(
                color: Colors.white38,

                fontSize: 10,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            TextButton.icon(
              onPressed: _loadMonthlyActivities,

              icon: const Icon(
                Icons.refresh_rounded,

                size: 15,
              ),

              label: const Text(
                'TENTAR NOVAMENTE',

                style: TextStyle(
                  fontSize: 9,

                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // VISUAL POR TIPO
  // ============================================================

  _RecentActivityVisual _visualForType(
    RecentActivityType type,
  ) {
    switch (type) {
      case RecentActivityType.welcome:
        return const _RecentActivityVisual(
          icon: Icons.waving_hand_rounded,

          color: Colors.amberAccent,
        );

      case RecentActivityType.profileUpdated:
        return const _RecentActivityVisual(
          icon: Icons.music_note_rounded,

          color: Colors.purpleAccent,
        );

      case RecentActivityType.connection:
        return const _RecentActivityVisual(
          icon: Icons.handshake_outlined,

          color: Colors.cyanAccent,
        );

      case RecentActivityType.favorite:
        return const _RecentActivityVisual(
          icon: Icons.star_rounded,

          color: Colors.yellowAccent,
        );

      case RecentActivityType.fileAdded:
        return const _RecentActivityVisual(
          icon: Icons.folder_rounded,

          color: Colors.lightBlueAccent,
        );
    }
  }

  // ============================================================
  // MÊS ATUAL
  // ============================================================

  String _currentMonthLabel() {
    final now = DateTime.now();

    return '${_monthName(now.month)} ${now.year}';
  }

  // ============================================================
  // NOME DO MÊS
  // ============================================================

  String _monthName(
    int month,
  ) {
    const months =
        <
          String
        >[
          'Janeiro',
          'Fevereiro',
          'Março',
          'Abril',
          'Maio',
          'Junho',
          'Julho',
          'Agosto',
          'Setembro',
          'Outubro',
          'Novembro',
          'Dezembro',
        ];

    if (month <
            1 ||
        month >
            12) {
      return '';
    }

    return months[month -
        1];
  }

  // ============================================================
  // FORMATAR DATA
  // ============================================================

  String _formatDateTime(
    DateTime date,
  ) {
    final localDate = date.toLocal();

    final now = DateTime.now();

    final difference = now.difference(
      localDate,
    );

    if (!difference.isNegative &&
        difference.inSeconds <
            60) {
      return 'Agora';
    }

    if (!difference.isNegative &&
        difference.inMinutes <
            60) {
      return '${difference.inMinutes} min atrás';
    }

    if (!difference.isNegative &&
        difference.inHours <
            24) {
      return '${difference.inHours}h atrás';
    }

    if (!difference.isNegative &&
        difference.inDays ==
            1) {
      return 'Ontem';
    }

    final day = localDate.day.toString().padLeft(
      2,
      '0',
    );

    final month = localDate.month.toString().padLeft(
      2,
      '0',
    );

    final hour = localDate.hour.toString().padLeft(
      2,
      '0',
    );

    final minute = localDate.minute.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month às $hour:$minute';
  }
}

// ============================================================
// VISUAL
// ============================================================

class _RecentActivityVisual {
  final IconData icon;

  final Color color;

  const _RecentActivityVisual({
    required this.icon,
    required this.color,
  });
}
