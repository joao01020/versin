import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

class _ContractViewState
    extends
        State<
          ContractView
        > {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _participationController = TextEditingController();
  final TextEditingController _activityController = TextEditingController();

  Future<
    void
  >
  _generateAndDownload() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build:
            (
              pw.Context context,
            ) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Text(
                      "TERMO DE ACORDO DE COLABORAÇÃO - VERSIN",
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Divider(),
                  pw.SizedBox(
                    height: 20,
                  ),

                  // Seção de Identificação
                  _buildSectionTitle(
                    "1. IDENTIFICAÇÃO",
                  ),
                  pw.Text(
                    "Membro: ${_nameController.text}",
                  ),
                  pw.Text(
                    "Projeto ID: ${widget.projectId}",
                  ),
                  pw.Text(
                    "Atividade: ${_activityController.text}",
                  ),
                  pw.Text(
                    "Participação: ${_participationController.text}%",
                  ),

                  pw.SizedBox(
                    height: 20,
                  ),

                  // Seção de Detalhamento do Match
                  _buildSectionTitle(
                    "2. ESCOPO E OBJETIVOS",
                  ),
                  pw.Text(
                    "O presente termo visa formalizar a colaboração mútua no projeto. "
                    "O colaborador assume a responsabilidade pelas atividades descritas, comprometendo-se com "
                    "prazos e padrões de qualidade estabelecidos pelo coletivo Versin.",
                  ),

                  pw.SizedBox(
                    height: 10,
                  ),

                  _buildSectionTitle(
                    "3. DIREITOS E DEVERES",
                  ),
                  pw.Text(
                    "• O colaborador tem direito à participação sobre os resultados líquidos conforme a porcentagem acima.\n"
                    "• O projeto detém a propriedade intelectual dos materiais produzidos.\n"
                    "• É dever do colaborador manter a confidencialidade das estratégias e segredos do projeto.\n"
                    "• O descumprimento injustificado das entregas autoriza a rescisão imediata e a revisão da participação.",
                  ),

                  pw.Spacer(),

                  // Bloco de Assinaturas Corrigido
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        children: [
                          pw.SizedBox(
                            width: 120,
                            child: pw.Divider(
                              color: PdfColors.black,
                            ),
                          ),
                          pw.Text(
                            "Assinatura do Colaborador",
                          ),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.SizedBox(
                            width: 120,
                            child: pw.Divider(
                              color: PdfColors.black,
                            ),
                          ),
                          pw.Text(
                            "Assinatura do Gestor",
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(
                    height: 20,
                  ),
                  pw.Text(
                    "Data: ${DateTime.now().toString().split(' ')[0]}",
                    style: const pw.TextStyle(
                      fontSize: 9,
                    ),
                  ),
                ],
              );
            },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Contrato_${_nameController.text.replaceAll(' ', '_')}.pdf',
    );
  }

  // Widget auxiliar para títulos no PDF
  pw.Widget _buildSectionTitle(
    String title,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(
        top: 10,
        bottom: 5,
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0F0F0F,
      ),
      appBar: AppBar(
        title: const Text(
          "Documentação de Match",
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(
          20,
        ),
        child: Column(
          children: [
            _buildTextField(
              _nameController,
              "Nome do Membro",
            ),
            _buildTextField(
              _activityController,
              "Atividade ou Função",
            ),
            _buildTextField(
              _participationController,
              "% de Participação",
              isNumber: true,
            ),
            const SizedBox(
              height: 40,
            ),
            ElevatedButton.icon(
              onPressed: _generateAndDownload,
              icon: const Icon(
                Icons.picture_as_pdf,
              ),
              label: const Text(
                "GERAR E BAIXAR CONTRATO",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 15,
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber
            ? TextInputType.number
            : TextInputType.text,
        style: const TextStyle(
          color: Colors.white,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.white70,
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(
              color: Colors.white24,
            ),
          ),
        ),
      ),
    );
  }
}
