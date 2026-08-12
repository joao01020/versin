import 'package:flutter/material.dart';

import 'package:versin/app/locator.dart';

import '../controllers/storage_controller.dart';
import '../data/models/stored_work_model.dart';
import '../widgets/storage_empty_state.dart';
import '../widgets/storage_item_card.dart';
import '../widgets/storage_summary_card.dart';
import 'beats/register_beats_page.dart';
import 'lyrics/register_lyrics_page.dart';
import 'storage_details_page.dart';

class StoragePage
    extends
        StatefulWidget {
  const StoragePage({
    super.key,
  });

  @override
  State<
    StoragePage
  >
  createState() => _StoragePageState();
}

class _StoragePageState
    extends
        State<
          StoragePage
        >
    with
        SingleTickerProviderStateMixin {
  final StorageController controller =
      sl<
        StorageController
      >();

  late final TabController _tabController;

  static const String _temporaryUserId = 'user_123';
  static const Color _accentColor = Color(
    0xFFE100FF,
  );
  static const Color _backgroundColor = Color(
    0xFF0D0B1F,
  );
  static const Color _surfaceColor = Color(
    0xFF17132D,
  );

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) async {
        if (!mounted) return;
        await _initializeStorage();
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<
    void
  >
  _initializeStorage() async {
    final userId = controller.currentUserId;

    if (userId ==
            null ||
        userId.trim().isEmpty) {
      await controller.init(
        userId: _temporaryUserId,
      );
      return;
    }

    await controller.refresh();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _surfaceColor,
              _backgroundColor,
              Colors.black,
            ],
          ),
        ),
        child: ListenableBuilder(
          listenable: controller,
          builder:
              (
                context,
                _,
              ) {
                if (controller.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: _accentColor,
                    ),
                  );
                }

                return Column(
                  children: [
                    _buildHeader(),
                    _buildSummary(),
                    const SizedBox(
                      height: 18,
                    ),
                    _buildTabs(),
                    const SizedBox(
                      height: 8,
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildWorksList(
                            StoredWorkType.beat,
                          ),
                          _buildWorksList(
                            StoredWorkType.lyrics,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(
        20,
      ),
      child: Row(
        children: [
          _iconBox(
            Icons.inventory_2_outlined,
          ),
          const SizedBox(
            width: 12,
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Armazenamento',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 2,
                ),
                Text(
                  'Obras, hashes e integridade',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showRegisterWorkDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  12,
                ),
              ),
            ),
            icon: const Icon(
              Icons.add_rounded,
              size: 18,
            ),
            label: const Text(
              'REGISTRAR',
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

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: Row(
        children: [
          _summaryCard(
            'Letras',
            controller.lyricsCount,
            Icons.description_outlined,
          ),
          const SizedBox(
            width: 10,
          ),
          _summaryCard(
            'Beats',
            controller.beatsCount,
            Icons.graphic_eq_rounded,
          ),
          const SizedBox(
            width: 10,
          ),
          _summaryCard(
            'Íntegras',
            controller.verifiedCount,
            Icons.verified_outlined,
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
    String title,
    int value,
    IconData icon,
  ) {
    return Expanded(
      child: StorageSummaryCard(
        title: title,
        value: value.toString(),
        icon: icon,
        accentColor: _accentColor,
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(
          4,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(
            alpha: 0.035,
          ),
          borderRadius: BorderRadius.circular(
            14,
          ),
          border: Border.all(
            color: Colors.white.withValues(
              alpha: 0.05,
            ),
          ),
        ),
        child: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: _accentColor,
          unselectedLabelColor: Colors.white38,
          indicator: BoxDecoration(
            color: _accentColor.withValues(
              alpha: 0.12,
            ),
            borderRadius: BorderRadius.circular(
              10,
            ),
          ),
          tabs: const [
            Tab(
              text: 'BEATS',
            ),
            Tab(
              text: 'LETRAS',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorksList(
    StoredWorkType type,
  ) {
    final works =
        type ==
            StoredWorkType.beat
        ? controller.beats
        : controller.lyrics;

    if (works.isEmpty) {
      return _buildEmptyState(
        type,
      );
    }

    return RefreshIndicator(
      color: _accentColor,
      onRefresh: controller.refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          24,
        ),
        itemCount: works.length,
        separatorBuilder:
            (
              _,
              __,
            ) => const SizedBox(
              height: 12,
            ),
        itemBuilder:
            (
              _,
              index,
            ) {
              final work = works[index];

              return StorageItemCard(
                work: work,
                accentColor: _accentColor,
                onTap: () => _openDetails(
                  work,
                ),
                onMorePressed: () => _showWorkActions(
                  work,
                ),
              );
            },
      ),
    );
  }

  Widget _buildEmptyState(
    StoredWorkType type,
  ) {
    final isBeat =
        type ==
        StoredWorkType.beat;

    return StorageEmptyState(
      title: isBeat
          ? 'Nenhum beat registrado'
          : 'Nenhuma letra registrada',
      message: isBeat
          ? 'Adicione um arquivo de áudio para gerar seu hash de integridade.'
          : 'Cole ou escreva uma letra para criar seu registro de integridade.',
      icon: isBeat
          ? Icons.graphic_eq_rounded
          : Icons.description_outlined,
      buttonLabel: isBeat
          ? 'REGISTRAR BEAT'
          : 'REGISTRAR LETRA',
      accentColor: _accentColor,
      onPressed: isBeat
          ? _openRegisterBeat
          : _openRegisterLyrics,
    );
  }

  Future<
    void
  >
  _openRegisterLyrics() async {
    final registered =
        await Navigator.of(
          context,
        ).push<
          bool
        >(
          MaterialPageRoute(
            builder:
                (
                  _,
                ) => const RegisterLyricsPage(),
          ),
        );

    if (!mounted ||
        registered !=
            true)
      return;

    await controller.refresh();

    if (mounted) {
      _tabController.animateTo(
        1,
      );
    }
  }

  Future<
    void
  >
  _openRegisterBeat() async {
    final registered =
        await Navigator.of(
          context,
        ).push<
          bool
        >(
          MaterialPageRoute(
            builder:
                (
                  _,
                ) => const RegisterBeatsPage(),
          ),
        );

    if (!mounted ||
        registered !=
            true)
      return;

    await controller.refresh();

    if (mounted) {
      _tabController.animateTo(
        0,
      );
    }
  }

  void _openDetails(
    StoredWorkModel work,
  ) {
    Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (
              _,
            ) => StorageDetailsPage(
              work: work,
              accentColor: _accentColor,
            ),
      ),
    );
  }

  void _showWorkActions(
    StoredWorkModel work,
  ) {
    final isBeat =
        work.type ==
        StoredWorkType.beat;

    showModalBottomSheet(
      context: context,
      backgroundColor: _surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            24,
          ),
        ),
      ),
      builder:
          (
            sheetContext,
          ) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(
                  20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _actionTile(
                      Icons.visibility_outlined,
                      'Ver detalhes',
                      () {
                        Navigator.pop(
                          sheetContext,
                        );
                        _openDetails(
                          work,
                        );
                      },
                    ),
                    _actionTile(
                      Icons.verified_outlined,
                      'Verificar hash',
                      () {
                        Navigator.pop(
                          sheetContext,
                        );
                        _showMessage(
                          'A verificação de integridade será conectada na próxima etapa.',
                        );
                      },
                    ),
                    _actionTile(
                      Icons.swap_horiz_rounded,
                      'Transferir autoria',
                      () {
                        Navigator.pop(
                          sheetContext,
                        );
                        _showMessage(
                          'A transferência de autoria será conectada na próxima etapa.',
                        );
                      },
                    ),
                    const Divider(
                      color: Colors.white10,
                    ),
                    _actionTile(
                      Icons.delete_outline_rounded,
                      isBeat
                          ? 'Apagar beat'
                          : 'Apagar letra',
                      () {
                        Navigator.pop(
                          sheetContext,
                        );
                        _confirmDelete(
                          work,
                        );
                      },
                      color: Colors.redAccent,
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }

  Widget _actionTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color color = _accentColor,
  }) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          12,
        ),
      ),
      leading: Icon(
        icon,
        color: color,
      ),
      title: Text(
        title,
        style: TextStyle(
          color:
              color ==
                  Colors.redAccent
              ? Colors.redAccent
              : Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<
    void
  >
  _confirmDelete(
    StoredWorkModel work,
  ) async {
    final isBeat =
        work.type ==
        StoredWorkType.beat;
    final type = isBeat
        ? 'beat'
        : 'letra';

    final confirmed =
        await showDialog<
          bool
        >(
          context: context,
          builder:
              (
                dialogContext,
              ) {
                return AlertDialog(
                  backgroundColor: _surfaceColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      20,
                    ),
                  ),
                  title: Text(
                    'Apagar $type?',
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  content: Text(
                    '"${work.title}" será removido do armazenamento. '
                    'Esta ação não pode ser desfeita.',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(
                        dialogContext,
                        false,
                      ),
                      child: const Text(
                        'CANCELAR',
                        style: TextStyle(
                          color: Colors.white54,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(
                        dialogContext,
                        true,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(
                        Icons.delete_forever_outlined,
                        size: 17,
                      ),
                      label: const Text(
                        'APAGAR',
                      ),
                    ),
                  ],
                );
              },
        );

    if (!mounted ||
        confirmed !=
            true)
      return;

    final deleted = await controller.deleteWork(
      work.id,
    );

    if (!mounted) return;

    _showMessage(
      deleted
          ? '${isBeat ? 'Beat' : 'Letra'} apagado com sucesso.'
          : controller.errorMessage ??
                'Não foi possível apagar a obra.',
      error: !deleted,
    );
  }

  void _showRegisterWorkDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            24,
          ),
        ),
      ),
      builder:
          (
            sheetContext,
          ) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(
                  24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Registrar obra',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    const Text(
                      'Escolha o tipo de conteúdo.',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    _registerOption(
                      Icons.description_outlined,
                      'Letra',
                      'Cole sua letra e gere SHA-256',
                      () {
                        Navigator.pop(
                          sheetContext,
                        );
                        _openRegisterLyrics();
                      },
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    _registerOption(
                      Icons.graphic_eq_rounded,
                      'Beat',
                      'Selecione seu áudio e gere SHA-256',
                      () {
                        Navigator.pop(
                          sheetContext,
                        );
                        _openRegisterBeat();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }

  Widget _registerOption(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        14,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(
          14,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(
            alpha: 0.035,
          ),
          borderRadius: BorderRadius.circular(
            14,
          ),
          border: Border.all(
            color: Colors.white.withValues(
              alpha: 0.05,
            ),
          ),
        ),
        child: Row(
          children: [
            _iconBox(
              icon,
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white24,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(
    IconData icon,
  ) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _accentColor.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(
          10,
        ),
        border: Border.all(
          color: _accentColor.withValues(
            alpha: 0.15,
          ),
        ),
      ),
      child: Icon(
        icon,
        color: _accentColor,
        size: 20,
      ),
    );
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(
        context,
      )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),
          backgroundColor: error
              ? const Color(
                  0xFF8B1E3F,
                )
              : _surfaceColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
