import 'package:flutter/material.dart';

import '../controllers/storage_controller.dart';
import '../data/models/stored_work_model.dart';

// ============================================================
// TRANSFER AUTHORSHIP PAGE
// ============================================================
//
// O autor original é preservado.
//
// A página não altera ownerUserId diretamente.
// Ela delega a transferência para:
//
// StorageController.transferWork(...)
//     ↓
// StorageRepository.transferWork(...)
//     ↓
// backend / memória
//
// ============================================================

class TransferAuthorshipPage
    extends
        StatefulWidget {
  final StoredWorkModel work;
  final StorageController controller;
  final Color accentColor;

  const TransferAuthorshipPage({
    super.key,
    required this.work,
    required this.controller,
    this.accentColor = const Color(
      0xFFE100FF,
    ),
  });

  @override
  State<
    TransferAuthorshipPage
  >
  createState() => _TransferAuthorshipPageState();
}

class _TransferAuthorshipPageState
    extends
        State<
          TransferAuthorshipPage
        > {
  final TextEditingController _recipientController = TextEditingController();

  final TextEditingController _noteController = TextEditingController();

  final FocusNode _recipientFocus = FocusNode();

  bool _accepted = false;

  String? _errorMessage;

  static const Color _backgroundColor = Color(
    0xFF0D0B1F,
  );
  static const Color _surfaceColor = Color(
    0xFF17132D,
  );

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (mounted) {
          _recipientFocus.requestFocus();
        }
      },
    );
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _noteController.dispose();
    _recipientFocus.dispose();
    super.dispose();
  }

  bool get _isBeat =>
      widget.work.type ==
      StoredWorkType.beat;

  String get _recipient => _recipientController.text.trim();

  bool get _isTransferring => widget.controller.isTransferring;

  bool get _canTransfer =>
      !_isTransferring &&
      _accepted &&
      _recipient.isNotEmpty &&
      _recipient !=
          widget.work.ownerUserId;

  @override
  Widget build(
    BuildContext context,
  ) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder:
          (
            context,
            _,
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
                child: SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                            28,
                            8,
                            28,
                            32,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 760,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildWorkCard(),
                                  const SizedBox(
                                    height: 18,
                                  ),
                                  _buildOwnershipCard(),
                                  const SizedBox(
                                    height: 18,
                                  ),
                                  _buildRecipientCard(),
                                  const SizedBox(
                                    height: 18,
                                  ),
                                  _buildSecurityCard(),
                                  if (_errorMessage !=
                                      null) ...[
                                    const SizedBox(
                                      height: 14,
                                    ),
                                    _buildError(),
                                  ],
                                  const SizedBox(
                                    height: 22,
                                  ),
                                  _buildTransferButton(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white10,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Voltar',
            onPressed: _isTransferring
                ? null
                : () => Navigator.of(
                    context,
                  ).pop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white70,
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          _iconBox(
            Icons.swap_horiz_rounded,
          ),
          const SizedBox(
            width: 12,
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transferir autoria',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(
                  height: 2,
                ),
                Text(
                  'Transfira a propriedade preservando o registro original.',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkCard() {
    return _section(
      title: 'OBRA',
      icon: _isBeat
          ? Icons.graphic_eq_rounded
          : Icons.description_outlined,
      child: Row(
        children: [
          _iconBox(
            _isBeat
                ? Icons.graphic_eq_rounded
                : Icons.description_outlined,
            size: 50,
          ),
          const SizedBox(
            width: 14,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.work.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 6,
                ),
                Text(
                  '${_isBeat ? 'Beat' : 'Letra'} • v${widget.work.version}',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  _shortHash(
                    widget.work.contentHash,
                  ),
                  style: const TextStyle(
                    color: Colors.white24,
                    fontSize: 9,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          if (widget.work.integrityVerified)
            const Icon(
              Icons.verified_rounded,
              color: Colors.greenAccent,
              size: 18,
            ),
        ],
      ),
    );
  }

  Widget _buildOwnershipCard() {
    return _section(
      title: 'PROPRIEDADE',
      icon: Icons.account_tree_outlined,
      child: Column(
        children: [
          _ownerRow(
            label: 'Autor original',
            value: widget.work.originalAuthorUserId,
            icon: Icons.history_edu_rounded,
            preserved: true,
          ),
          const SizedBox(
            height: 14,
          ),
          _ownerRow(
            label: 'Proprietário atual',
            value: widget.work.ownerUserId,
            icon: Icons.person_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _ownerRow({
    required String label,
    required String value,
    required IconData icon,
    bool preserved = false,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.035,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: preserved
                ? Colors.greenAccent
                : widget.accentColor,
            size: 17,
          ),
        ),
        const SizedBox(
          width: 11,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                ),
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                value.isEmpty
                    ? 'Não informado'
                    : value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (preserved)
          Text(
            'PRESERVADO',
            style: TextStyle(
              color: Colors.greenAccent.withValues(
                alpha: 0.7,
              ),
              fontSize: 7,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildRecipientCard() {
    return _section(
      title: 'NOVO PROPRIETÁRIO',
      icon: Icons.person_add_alt_1_rounded,
      child: Column(
        children: [
          TextField(
            controller: _recipientController,
            focusNode: _recipientFocus,
            enabled: !_isTransferring,
            onChanged:
                (
                  _,
                ) {
                  setState(
                    () {
                      _errorMessage = null;
                    },
                  );
                },
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
            decoration: _inputDecoration(
              label: 'ID ou @usuário',
              hint: 'Ex: user_456 ou @artista',
              icon: Icons.alternate_email_rounded,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          TextField(
            controller: _noteController,
            enabled: !_isTransferring,
            minLines: 2,
            maxLines: 4,
            maxLength: 240,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
            decoration: _inputDecoration(
              label: 'Nota da transferência',
              hint: 'Opcional: colaboração, venda, cessão...',
              icon: Icons.notes_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: widget.accentColor.withValues(
          alpha: 0.035,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: widget.accentColor.withValues(
            alpha: 0.09,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.shield_outlined,
                color: widget.accentColor,
                size: 20,
              ),
              const SizedBox(
                width: 10,
              ),
              const Expanded(
                child: Text(
                  'O autor original e o hash permanecem preservados. '
                  'A transferência altera apenas o proprietário atual.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _accepted,
            activeColor: widget.accentColor,
            checkColor: Colors.black,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: _isTransferring
                ? null
                : (
                    value,
                  ) {
                    setState(
                      () {
                        _accepted =
                            value ??
                            false;
                      },
                    );
                  },
            title: const Text(
              'Entendo que estou transferindo a propriedade desta obra.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferButton() {
    return SizedBox(
      height: 50,
      child: FilledButton.icon(
        onPressed: _canTransfer
            ? _confirmTransfer
            : null,
        style: FilledButton.styleFrom(
          backgroundColor: widget.accentColor,
          foregroundColor: Colors.black,
          disabledBackgroundColor: Colors.white.withValues(
            alpha: 0.05,
          ),
          disabledForegroundColor: Colors.white24,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              14,
            ),
          ),
        ),
        icon: _isTransferring
            ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : const Icon(
                Icons.swap_horiz_rounded,
                size: 20,
              ),
        label: Text(
          _isTransferring
              ? 'TRANSFERINDO...'
              : 'TRANSFERIR AUTORIA',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Future<
    void
  >
  _confirmTransfer() async {
    final recipient = _recipient;

    if (recipient.isEmpty) {
      setState(
        () {
          _errorMessage = 'Informe o novo proprietário.';
        },
      );
      return;
    }

    if (recipient ==
        widget.work.ownerUserId) {
      setState(
        () {
          _errorMessage = 'Esse usuário já é o proprietário atual.';
        },
      );
      return;
    }

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
                  title: const Text(
                    'Confirmar transferência?',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  content: Text(
                    'A propriedade de "${widget.work.title}" '
                    'será transferida para "$recipient".',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(
                          dialogContext,
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
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(
                          dialogContext,
                          true,
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.accentColor,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text(
                        'CONFIRMAR',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
        );

    if (!mounted ||
        confirmed !=
            true) {
      return;
    }

    await _transfer(
      recipient,
    );
  }

  Future<
    void
  >
  _transfer(
    String recipient,
  ) async {
    setState(
      () {
        _errorMessage = null;
      },
    );

    try {
      final note = _noteController.text.trim();

      final success = await widget.controller.transferWork(
        workId: widget.work.id,
        toUserId: recipient,
        note: note.isEmpty
            ? null
            : note,
      );

      if (!mounted) {
        return;
      }

      if (!success) {
        setState(
          () {
            _errorMessage =
                widget.controller.errorMessage ??
                'Não foi possível transferir a autoria.';
          },
        );

        return;
      }

      Navigator.of(
        context,
      ).pop(
        true,
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      setState(
        () {
          _errorMessage = 'Erro ao transferir autoria: $error';
        },
      );
    }
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.022,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: widget.accentColor.withValues(
                  alpha: 0.75,
                ),
                size: 16,
              ),
              const SizedBox(
                width: 7,
              ),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          child,
        ],
      ),
    );
  }

  Widget _iconBox(
    IconData icon, {
    double size = 42,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: widget.accentColor.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: widget.accentColor.withValues(
            alpha: 0.14,
          ),
        ),
      ),
      child: Icon(
        icon,
        color: widget.accentColor,
        size:
            size *
            0.46,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        color: Colors.white38,
        fontSize: 10,
      ),
      hintStyle: const TextStyle(
        color: Colors.white24,
        fontSize: 10,
      ),
      prefixIcon: Icon(
        icon,
        color: widget.accentColor.withValues(
          alpha: 0.65,
        ),
        size: 18,
      ),
      filled: true,
      fillColor: Colors.white.withValues(
        alpha: 0.025,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          13,
        ),
        borderSide: BorderSide(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          13,
        ),
        borderSide: BorderSide(
          color: widget.accentColor.withValues(
            alpha: 0.55,
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(
        12,
      ),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: Colors.redAccent.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 18,
          ),
          const SizedBox(
            width: 9,
          ),
          Expanded(
            child: Text(
              _errorMessage ??
                  '',
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _shortHash(
    String value,
  ) {
    final hash = value.trim();

    if (hash.length <=
        22) {
      return hash;
    }

    return '${hash.substring(0, 11)}...'
        '${hash.substring(hash.length - 8)}';
  }
}
