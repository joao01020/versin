import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ============================================================
// CONTRACT VIEW
// ============================================================
//
// Tela de documentação da Studio Session.
//
// Responsável por:
//
// - preencher dados do acordo;
// - definir atividade;
// - definir participação;
// - mostrar preview;
// - gerar PDF;
// - compartilhar / salvar PDF.
//
// ============================================================

class ContractView
    extends
        StatefulWidget {
  final String projectId;

  const ContractView({
    super.key,
    required this.projectId,
  });

  @override
  State<
    ContractView
  >
  createState() => _ContractViewState();
}

// ============================================================
// STATE
// ============================================================

class _ContractViewState
    extends
        State<
          ContractView
        > {
  // ==========================================================
  // CORES
  // ==========================================================

  static const Color _background = Color(
    0xFF08080B,
  );

  static const Color _surface = Color(
    0xFF111116,
  );

  static const Color _surfaceLight = Color(
    0xFF17171E,
  );

  static const Color _purple = Color(
    0xFF8B5CF6,
  );

  static const Color _purpleStrong = Color(
    0xFF6D28D9,
  );

  // ==========================================================
  // CONTROLLERS
  // ==========================================================

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _participationController = TextEditingController();

  final TextEditingController _activityController = TextEditingController();

  // ==========================================================
  // ESTADO
  // ==========================================================

  bool _isGenerating = false;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _nameController.addListener(
      _refreshPreview,
    );

    _participationController.addListener(
      _refreshPreview,
    );

    _activityController.addListener(
      _refreshPreview,
    );
  }

  // ==========================================================
  // PREVIEW
  // ==========================================================

  void _refreshPreview() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ==========================================================
  // HASH VISUAL
  // ==========================================================

  String get _projectHash {
    final value = widget.projectId.trim();

    if (value.length <=
        8) {
      return value.toUpperCase();
    }

    return value
        .substring(
          0,
          8,
        )
        .toUpperCase();
  }

  // ==========================================================
  // NOME
  // ==========================================================

  String get _memberName {
    final value = _nameController.text.trim();

    return value.isEmpty
        ? 'Não informado'
        : value;
  }

  // ==========================================================
  // ATIVIDADE
  // ==========================================================

  String get _activity {
    final value = _activityController.text.trim();

    return value.isEmpty
        ? 'Não informada'
        : value;
  }

  // ==========================================================
  // PARTICIPAÇÃO
  // ==========================================================

  String get _participation {
    final value = _participationController.text.trim();

    return value.isEmpty
        ? '0'
        : value;
  }

  // ==========================================================
  // VALIDAR
  // ==========================================================

  bool _validate() {
    final name = _nameController.text.trim();

    final activity = _activityController.text.trim();

    final participationText = _participationController.text.trim();

    if (name.isEmpty) {
      _showMessage(
        'Informe o nome do membro.',
      );

      return false;
    }

    if (activity.isEmpty) {
      _showMessage(
        'Informe a atividade ou função.',
      );

      return false;
    }

    final participation = double.tryParse(
      participationText.replaceAll(
        ',',
        '.',
      ),
    );

    if (participation ==
        null) {
      _showMessage(
        'Informe uma participação válida.',
      );

      return false;
    }

    if (participation <
            0 ||
        participation >
            100) {
      _showMessage(
        'A participação deve ficar entre 0% e 100%.',
      );

      return false;
    }

    return true;
  }

  // ==========================================================
  // GERAR PDF
  // ==========================================================

  Future<
    void
  >
  _generateAndDownload() async {
    if (_isGenerating) {
      return;
    }

    if (!_validate()) {
      return;
    }

    setState(
      () {
        _isGenerating = true;
      },
    );

    try {
      final pdf = pw.Document();

      final generatedAt = DateTime.now();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,

          margin: const pw.EdgeInsets.all(
            42,
          ),

          build:
              (
                pw.Context context,
              ) {
                return [
                  // ==============================================
                  // HEADER
                  // ==============================================
                  pw.Container(
                    width: double.infinity,

                    padding: const pw.EdgeInsets.all(
                      20,
                    ),

                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey900,

                      borderRadius: pw.BorderRadius.circular(
                        8,
                      ),
                    ),

                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,

                      children: [
                        pw.Text(
                          'VERSIN',
                          style: pw.TextStyle(
                            color: PdfColors.deepPurple200,

                            fontSize: 12,

                            fontWeight: pw.FontWeight.bold,

                            letterSpacing: 2,
                          ),
                        ),

                        pw.SizedBox(
                          height: 6,
                        ),

                        pw.Text(
                          'TERMO DE COLABORAÇÃO',
                          style: pw.TextStyle(
                            color: PdfColors.white,

                            fontSize: 22,

                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),

                        pw.SizedBox(
                          height: 4,
                        ),

                        pw.Text(
                          'Studio Session #$_projectHash',
                          style: const pw.TextStyle(
                            color: PdfColors.grey400,

                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(
                    height: 26,
                  ),

                  // ==============================================
                  // IDENTIFICAÇÃO
                  // ==============================================
                  _buildPdfSectionTitle(
                    '01 · IDENTIFICAÇÃO',
                  ),

                  _buildPdfInfoRow(
                    'Membro',
                    _memberName,
                  ),

                  _buildPdfInfoRow(
                    'Atividade',
                    _activity,
                  ),

                  _buildPdfInfoRow(
                    'Participação',
                    '$_participation%',
                  ),

                  _buildPdfInfoRow(
                    'Projeto',
                    widget.projectId,
                  ),

                  pw.SizedBox(
                    height: 22,
                  ),

                  // ==============================================
                  // ESCOPO
                  // ==============================================
                  _buildPdfSectionTitle(
                    '02 · ESCOPO',
                  ),

                  pw.Text(
                    'Este termo registra a colaboração do membro identificado '
                    'acima dentro da Studio Session Versin. A participação '
                    'descrita representa a divisão acordada entre os envolvidos '
                    'para esta colaboração específica.',
                    style: const pw.TextStyle(
                      fontSize: 10.5,

                      lineSpacing: 4,
                    ),
                  ),

                  pw.SizedBox(
                    height: 20,
                  ),

                  // ==============================================
                  // DIREITOS E DEVERES
                  // ==============================================
                  _buildPdfSectionTitle(
                    '03 · DIREITOS E RESPONSABILIDADES',
                  ),

                  _buildPdfBullet(
                    'O membro participa dos resultados conforme o percentual definido.',
                  ),

                  _buildPdfBullet(
                    'Alterações posteriores de participação devem ser formalizadas por um novo acordo.',
                  ),

                  _buildPdfBullet(
                    'As contribuições individuais devem respeitar autoria e créditos de cada participante.',
                  ),

                  _buildPdfBullet(
                    'Materiais compartilhados dentro da sessão devem ser tratados como conteúdo do projeto.',
                  ),

                  _buildPdfBullet(
                    'Os participantes devem manter registro claro sobre responsabilidades e entregas.',
                  ),

                  pw.SizedBox(
                    height: 24,
                  ),

                  // ==============================================
                  // IDENTIFICADOR
                  // ==============================================
                  _buildPdfSectionTitle(
                    '04 · IDENTIFICADOR DA SESSÃO',
                  ),

                  pw.Container(
                    width: double.infinity,

                    padding: const pw.EdgeInsets.all(
                      12,
                    ),

                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,

                      borderRadius: pw.BorderRadius.circular(
                        5,
                      ),
                    ),

                    child: pw.Text(
                      widget.projectId,
                      style: const pw.TextStyle(
                        fontSize: 9,
                      ),
                    ),
                  ),

                  pw.SizedBox(
                    height: 42,
                  ),

                  // ==============================================
                  // ASSINATURAS
                  // ==============================================
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,

                    children: [
                      _buildPdfSignature(
                        'Membro',
                      ),

                      _buildPdfSignature(
                        'Responsável pela sessão',
                      ),
                    ],
                  ),

                  pw.SizedBox(
                    height: 30,
                  ),

                  pw.Divider(
                    color: PdfColors.grey300,
                  ),

                  pw.Text(
                    'Gerado pelo Versin em '
                    '${_formatPdfDate(generatedAt)}',
                    style: const pw.TextStyle(
                      fontSize: 8,

                      color: PdfColors.grey600,
                    ),
                  ),
                ];
              },
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),

        filename: 'Versin_Contrato_${_safeFileName(_memberName)}.pdf',
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Não foi possível gerar o contrato.',
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _isGenerating = false;
          },
        );
      }
    }
  }

  // ==========================================================
  // PDF SECTION
  // ==========================================================

  pw.Widget _buildPdfSectionTitle(
    String title,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(
        bottom: 10,
      ),

      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,

          fontSize: 11,

          color: PdfColors.deepPurple700,
        ),
      ),
    );
  }

  // ==========================================================
  // PDF INFO
  // ==========================================================

  pw.Widget _buildPdfInfoRow(
    String label,
    String value,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(
        bottom: 7,
      ),

      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,

        children: [
          pw.SizedBox(
            width: 90,

            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,

                fontSize: 9,
              ),
            ),
          ),

          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PDF BULLET
  // ==========================================================

  pw.Widget _buildPdfBullet(
    String text,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(
        bottom: 7,
      ),

      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,

        children: [
          pw.Text(
            '• ',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.Expanded(
            child: pw.Text(
              text,
              style: const pw.TextStyle(
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PDF SIGNATURE
  // ==========================================================

  pw.Widget _buildPdfSignature(
    String label,
  ) {
    return pw.SizedBox(
      width: 190,

      child: pw.Column(
        children: [
          pw.Container(
            height: 1,

            color: PdfColors.grey700,
          ),

          pw.SizedBox(
            height: 6,
          ),

          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: _background,

      appBar: AppBar(
        backgroundColor: Colors.transparent,

        elevation: 0,

        surfaceTintColor: Colors.transparent,

        titleSpacing: 4,

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Documento',
              style: TextStyle(
                color: Colors.white,

                fontSize: 16,

                fontWeight: FontWeight.w700,
              ),
            ),

            Text(
              'Studio Session #$_projectHash',
              style: const TextStyle(
                color: Colors.white38,

                fontSize: 10,
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        top: false,

        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            18,
            12,
            18,
            32,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ============================================
              // HEADER
              // ============================================
              _buildHeroCard(),

              const SizedBox(
                height: 24,
              ),

              // ============================================
              // CONFIGURAÇÃO
              // ============================================
              _buildSectionLabel(
                'CONFIGURAÇÃO DO ACORDO',
              ),

              const SizedBox(
                height: 10,
              ),

              _buildFormCard(),

              const SizedBox(
                height: 24,
              ),

              // ============================================
              // PREVIEW
              // ============================================
              _buildSectionLabel(
                'PREVIEW',
              ),

              const SizedBox(
                height: 10,
              ),

              _buildPreviewCard(),

              const SizedBox(
                height: 26,
              ),

              // ============================================
              // CTA
              // ============================================
              _buildGenerateButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // HERO
  // ==========================================================

  Widget _buildHeroCard() {
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
          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

          colors: [
            Color(
              0xFF21113E,
            ),
            Color(
              0xFF111116,
            ),
          ],
        ),

        border: Border.all(
          color: _purple.withValues(
            alpha: 0.24,
          ),
        ),

        boxShadow: [
          BoxShadow(
            color: _purple.withValues(
              alpha: 0.08,
            ),

            blurRadius: 30,

            spreadRadius: 1,
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 50,

            height: 50,

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                16,
              ),

              color: _purple.withValues(
                alpha: 0.12,
              ),

              border: Border.all(
                color: _purple.withValues(
                  alpha: 0.24,
                ),
              ),
            ),

            child: const Icon(
              Icons.description_outlined,
              color: _purple,
              size: 24,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Acordo de colaboração',
                  style: TextStyle(
                    color: Colors.white,

                    fontSize: 16,

                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  'Formalize função, participação e vínculo desta sessão.',
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.48,
                    ),

                    fontSize: 11,

                    height: 1.4,
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
  // SECTION LABEL
  // ==========================================================

  Widget _buildSectionLabel(
    String text,
  ) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white38,

        fontSize: 10,

        fontWeight: FontWeight.w700,

        letterSpacing: 1.2,
      ),
    );
  }

  // ==========================================================
  // FORM CARD
  // ==========================================================

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(
        16,
      ),

      decoration: BoxDecoration(
        color: _surface,

        borderRadius: BorderRadius.circular(
          20,
        ),

        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.06,
          ),
        ),
      ),

      child: Column(
        children: [
          _buildModernField(
            controller: _nameController,

            icon: Icons.person_outline_rounded,

            label: 'Membro',

            hint: 'Nome artístico ou nome completo',
          ),

          const SizedBox(
            height: 12,
          ),

          _buildModernField(
            controller: _activityController,

            icon: Icons.graphic_eq_rounded,

            label: 'Função',

            hint: 'Ex: Produtor, Beatmaker, Vocal',
          ),

          const SizedBox(
            height: 12,
          ),

          _buildModernField(
            controller: _participationController,

            icon: Icons.percent_rounded,

            label: 'Participação',

            hint: 'Ex: 50',

            suffix: '%',

            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),

            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(
                  r'[0-9,.]',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // FIELD
  // ==========================================================

  Widget _buildModernField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    String? suffix,
    TextInputType? keyboardType,
    List<
      TextInputFormatter
    >?
    inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceLight,

        borderRadius: BorderRadius.circular(
          16,
        ),

        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),

      child: TextField(
        controller: controller,

        keyboardType: keyboardType,

        inputFormatters: inputFormatters,

        style: const TextStyle(
          color: Colors.white,

          fontSize: 13,

          fontWeight: FontWeight.w500,
        ),

        decoration: InputDecoration(
          border: InputBorder.none,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,

            vertical: 13,
          ),

          prefixIcon: Icon(
            icon,
            color: _purple,
            size: 19,
          ),

          labelText: label,

          labelStyle: const TextStyle(
            color: Colors.white54,

            fontSize: 11,
          ),

          hintText: hint,

          hintStyle: const TextStyle(
            color: Colors.white24,

            fontSize: 12,
          ),

          suffixText: suffix,

          suffixStyle: const TextStyle(
            color: _purple,

            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // PREVIEW
  // ==========================================================

  Widget _buildPreviewCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        18,
      ),

      decoration: BoxDecoration(
        color: _surface,

        borderRadius: BorderRadius.circular(
          20,
        ),

        border: Border.all(
          color: _purple.withValues(
            alpha: 0.12,
          ),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,

                  vertical: 5,
                ),

                decoration: BoxDecoration(
                  color: _purple.withValues(
                    alpha: 0.12,
                  ),

                  borderRadius: BorderRadius.circular(
                    20,
                  ),
                ),

                child: const Text(
                  'VERSIN DOC',
                  style: TextStyle(
                    color: _purple,

                    fontSize: 9,

                    fontWeight: FontWeight.w800,

                    letterSpacing: 1,
                  ),
                ),
              ),

              const Spacer(),

              const Icon(
                Icons.lock_outline_rounded,
                color: Colors.white24,
                size: 15,
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          const Text(
            'Termo de colaboração',
            style: TextStyle(
              color: Colors.white,

              fontSize: 17,

              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            '#$_projectHash',
            style: const TextStyle(
              color: Colors.white30,

              fontSize: 10,

              fontFamily: 'monospace',
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          _buildPreviewRow(
            'MEMBRO',
            _memberName,
          ),

          _buildPreviewDivider(),

          _buildPreviewRow(
            'FUNÇÃO',
            _activity,
          ),

          _buildPreviewDivider(),

          _buildPreviewRow(
            'PARTICIPAÇÃO',
            '$_participation%',
            highlight: true,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PREVIEW ROW
  // ==========================================================

  Widget _buildPreviewRow(
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
      ),

      child: Row(
        children: [
          SizedBox(
            width: 110,

            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white30,

                fontSize: 9,

                fontWeight: FontWeight.w700,

                letterSpacing: 0.7,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,

              overflow: TextOverflow.ellipsis,

              style: TextStyle(
                color: highlight
                    ? _purple
                    : Colors.white70,

                fontSize: highlight
                    ? 16
                    : 12,

                fontWeight: highlight
                    ? FontWeight.w800
                    : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DIVIDER
  // ==========================================================

  Widget _buildPreviewDivider() {
    return Divider(
      height: 20,

      color: Colors.white.withValues(
        alpha: 0.05,
      ),
    );
  }

  // ==========================================================
  // BUTTON
  // ==========================================================

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,

      height: 54,

      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            17,
          ),

          gradient: const LinearGradient(
            colors: [
              _purpleStrong,
              _purple,
            ],
          ),

          boxShadow: [
            BoxShadow(
              color: _purple.withValues(
                alpha: 0.18,
              ),

              blurRadius: 22,

              offset: const Offset(
                0,
                7,
              ),
            ),
          ],
        ),

        child: ElevatedButton(
          onPressed: _isGenerating
              ? null
              : _generateAndDownload,

          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,

            disabledBackgroundColor: Colors.transparent,

            shadowColor: Colors.transparent,

            foregroundColor: Colors.white,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                17,
              ),
            ),
          ),

          child: _isGenerating
              ? const SizedBox(
                  width: 20,

                  height: 20,

                  child: CircularProgressIndicator(
                    strokeWidth: 2,

                    color: Colors.white,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 19,
                    ),

                    SizedBox(
                      width: 9,
                    ),

                    Text(
                      'Gerar documento',
                      style: TextStyle(
                        fontSize: 13,

                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
        context,
      )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),

          backgroundColor: _surfaceLight,

          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ==========================================================
  // SAFE FILE NAME
  // ==========================================================

  String _safeFileName(
    String value,
  ) {
    final normalized = value.trim().replaceAll(
      RegExp(
        r'[^a-zA-Z0-9_-]+',
      ),
      '_',
    );

    return normalized.isEmpty
        ? 'documento'
        : normalized;
  }

  // ==========================================================
  // PDF DATE
  // ==========================================================

  String _formatPdfDate(
    DateTime date,
  ) {
    final day = date.day.toString().padLeft(
      2,
      '0',
    );

    final month = date.month.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month/${date.year}';
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _nameController.removeListener(
      _refreshPreview,
    );

    _participationController.removeListener(
      _refreshPreview,
    );

    _activityController.removeListener(
      _refreshPreview,
    );

    _nameController.dispose();

    _participationController.dispose();

    _activityController.dispose();

    super.dispose();
  }
}
