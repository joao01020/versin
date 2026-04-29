import 'package:flutter/material.dart';

class AIMemoryPage extends StatefulWidget {
  const AIMemoryPage({super.key});

  @override
  State<AIMemoryPage> createState() => _AIMemoryPageState();
}

class _AIMemoryPageState extends State<AIMemoryPage> {
  // Variável que controla o consumo da memória
  double memoryUsage = 1.0;

  // Lógica de cores baseada no consumo
  Color getMemoryColor(double usage) {
    if (usage == 1.0) {
      return Colors.greenAccent; // 100% Livre
    } else if (usage == 0.5) {
      return Colors.yellowAccent; // 50% consumido
    } else if (usage <= 0.1) {
      return Colors.redAccent; // Alerta de consumo alto
    }
    return Colors.purpleAccent;
  }

  String getPercentageText(double usage) {
    int percent = (usage * 100).toInt();
    return usage == 1.0 ? "100% Livre" : "$percent% consumido";
  }

  String getMemoryStatusMessage(double usage) {
    if (usage == 1.0) {
      return "Você tem muito espaço, que tal iniciar sua DAW e fazer uma rima?";
    } else if (usage == 0.5) {
      return "Sua memória já está ficando curta. Você consegue criar, porém lembre de apagar as letras descartáveis.";
    } else if (usage <= 0.1) {
      return "A memória está curta! Apague algo para continuar salvando novas letras.";
    }
    return "Analisando fluxo de dados...";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text(
          'MEMÓRIA DA IA',
          style: TextStyle(
            letterSpacing: 4,
            fontWeight: FontWeight.w300,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.purpleAccent),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Status do Contexto",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: memoryUsage,
                minHeight: 12,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(
                  getMemoryColor(memoryUsage),
                ),
              ),
            ),

            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getPercentageText(memoryUsage),
                  style: TextStyle(
                    color: getMemoryColor(memoryUsage),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Text(
                  "Saldo: 0 tokens",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: getMemoryColor(memoryUsage).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: getMemoryColor(memoryUsage).withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates_outlined,
                        color: getMemoryColor(memoryUsage),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Sugestão do Versin",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    getMemoryStatusMessage(memoryUsage),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() => memoryUsage = 1.0);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Memória de curto prazo limpa!"),
                      backgroundColor: Colors.purpleAccent,
                    ),
                  );
                },
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text("LIMPAR MEMÓRIA DE CURTO PRAZO"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent.withOpacity(0.1),
                  foregroundColor: Colors.purpleAccent,
                  side: const BorderSide(color: Colors.purpleAccent),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
