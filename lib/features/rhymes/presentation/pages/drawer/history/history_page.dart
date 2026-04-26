import 'package:flutter/material.dart';
// Importação utilizando o caminho completo do package conforme sua nova estrutura
import 'package:versin/features/rhymes/presentation/widgets/empty_state_widget/empty_state_widget.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text(
          "HISTÓRICO", 
          style: TextStyle(
            fontSize: 12, 
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
            color: Colors.white38,
          )
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const VersinEmptyState(
        title: "HISTÓRICO VAZIO",
        subtitle: "Seus projetos antigos aparecerão aqui.",
        icon: Icons.history_rounded,
      ),
    );
  }
}