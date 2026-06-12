import 'package:flutter/material.dart';
import 'package:versin/modules/brain/controller/brain_controller.dart';
import 'package:versin/modules/rhymelibrary/views/rhyme_library_page.dart';

class BrainHubPage
    extends
        StatelessWidget {
  final BrainController controller;

  const BrainHubPage({
    super.key,
    required this.controller,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0A0A0A,
      ), // Fundo um pouco mais profundo
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(
            context,
          ),
        ),
        title: const Text(
          "BRAIN_HUB",
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 6,
            color: Colors.white54,
            fontWeight: FontWeight.w300,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 20,
            ),
            const Text(
              "ESTADO DO SISTEMA",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.purpleAccent.withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(
                  4,
                ),
              ),
              child: const Text(
                "VERSIN CORE v2.4 // SINCRONIZADO",
                style: TextStyle(
                  color: Colors.purpleAccent,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(
              height: 32,
            ),

            // Botão de Sincronização Estilizado
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purpleAccent.withValues(
                      alpha: 0.3,
                    ),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(
                  20,
                ),
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: 0.1,
                  ),
                ),
              ),
              child: ListTile(
                onTap: () async => await controller.syncVaultToLibrary(),
                leading: const Icon(
                  Icons.sync_rounded,
                  color: Colors.purpleAccent,
                ),
                title: const Text(
                  "SINCRONIZAR NEURÔNIOS",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  "Atualizar banco de dados local",
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 11,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 32,
            ),
            const Text(
              "MÓDULOS DISPONÍVEIS",
              style: TextStyle(
                color: Colors.white30,
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(
              height: 16,
            ),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildBrainCard(
                    context,
                    "BIBLIOTECA",
                    Icons.library_books_rounded,
                    Colors.blueAccent,
                  ),
                  _buildBrainCard(
                    context,
                    "VAULT NOTES",
                    Icons.edit_note_rounded,
                    Colors.orangeAccent,
                  ),
                  _buildBrainCard(
                    context,
                    "METRÔNOMO",
                    Icons.timer_rounded,
                    Colors.greenAccent,
                  ),
                  _buildBrainCard(
                    context,
                    "PROJETOS",
                    Icons.folder_shared_rounded,
                    Colors.pinkAccent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrainCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(
          0xFF121212,
        ),
        borderRadius: BorderRadius.circular(
          24,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(
              alpha: 0.05,
            ),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(
            24,
          ),
          onTap: () =>
              title ==
                  "BIBLIOTECA"
              ? Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (
                          _,
                        ) => RhymeLibraryPage(
                          controller: controller,
                        ),
                  ),
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(
                  12,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
