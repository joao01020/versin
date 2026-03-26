import 'package:flutter/material.dart';

class HowToUsePage extends StatelessWidget {
  const HowToUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("COMMAND CENTER", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // O GÊNESIS DO VERSIN
            const Text(
              "O Gênesis do Versin",
              style: TextStyle(color: Colors.purpleAccent, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            const Text(
              "O Versin nasceu da necessidade de transformar o caos criativo em obras de impacto. "
              "Não somos apenas um bloco de notas; somos um copiloto de estúdio focado na cultura Trap e Rap. "
              "Criado para artistas que levam a sério a métrica, o flow e a evolução constante.",
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 30),

            // TERMINAL DE COMANDOS (MODOS ATIVOS)
            const Text(
              "MODOS DE TERMINAL",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 15),

            // RHYME MODE
            _buildFunctionCard(
              icon: Icons.terminal_rounded,
              color: Colors.greenAccent,
              title: "Rhyme Mode (/modorima)",
              description: "Foca o cérebro da IA exclusivamente em fonética e rimas raras.\n\n"
                  "• /modorima : Ativa o modo e libera o botão '+' para salvar rimas rápido.\n"
                  "• buscar rimas com \"palavra\" : Pesquisa profunda na base de dados.",
            ),

            const SizedBox(height: 15),

            // COMPOSING MODE - CORRIGIDO Icons.history_edu
            _buildFunctionCard(
              icon: Icons.history_edu, 
              color: Colors.blueAccent,
              title: "Composing Mode (/modocompor)",
              description: "Análise técnica de escrita e estrutura de música.\n\n"
                  "• /modocompor : IA foca em métrica, contagem de sílabas e storytelling.\n"
                  "• Analisa se o seu Refrão está chiclete ou se o Verso está fora do tempo.",
            ),

            const SizedBox(height: 15),

            // LIST MODE
            _buildFunctionCard(
              icon: Icons.format_list_bulleted_rounded,
              color: Colors.orangeAccent,
              title: "List Mode (/modolistar)",
              description: "Organização estratégica do seu vocabulário salvo.\n\n"
                  "• /modolistar : IA separa suas rimas entre 'Prioridade Máxima' e 'Lista Geral'.\n"
                  "• Ajuda a conectar palavras que você já salvou para criar novas punchlines.",
            ),

            const SizedBox(height: 15),

            // MARKETING MODE
            _buildFunctionCard(
              icon: Icons.campaign_rounded,
              color: Colors.yellowAccent,
              title: "Marketing Mode (/modomarketing)",
              description: "Consultoria de carreira e expansão de audiência.\n\n"
                  "• /modomarketing : Dicas de como viralizar no TikTok/Reels e estratégias de tráfego pago.\n"
                  "• IA foca em como transformar ouvintes em fãs reais.",
            ),

            const SizedBox(height: 30),

            // COMANDOS GERAIS
            const Text(
              "COMANDOS DE SISTEMA",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 15),
            
            _buildSystemCommand(
              command: "/desligarmodo",
              desc: "Encerra qualquer modo ativo e volta ao Mentor padrão.",
              color: Colors.redAccent,
            ),
            const SizedBox(height: 10),
            _buildSystemCommand(
              command: "/list rima1, rima2",
              desc: "Adiciona rimas em massa diretamente ao seu dicionário.",
              color: Colors.purpleAccent,
            ),

            const SizedBox(height: 40),
            const Center(
              child: Text(
                "FOCO NA CADÊNCIA. O RESTO O VERSIN RESOLVE.",
                style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 2),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFunctionCard({required IconData icon, required Color color, required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemCommand({required String command, required String desc, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(command, style: TextStyle(color: color, fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 10),
          Expanded(child: Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 12))),
        ],
      ),
    );
  }
}