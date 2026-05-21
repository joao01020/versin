import 'package:flutter/material.dart';
import 'package:versin/app/locator.dart';
import '../../controllers/dashboard_controller.dart';

class ContractsPage extends StatefulWidget {
  const ContractsPage({super.key});

  @override
  State<ContractsPage> createState() => _ContractsPageState();
}

class _ContractsPageState extends State<ContractsPage> {
  final DashboardController controller = sl<DashboardController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Mantemos o fundo como a cor principal do seu gradiente ou transparente
      backgroundColor: const Color(0xFF0D0B1F), 
      body: Container(
        // Aplicando o mesmo gradiente do seu Card original
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1F1A3A), Color(0xFF0D0B1F)],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40), // Espaço para não ficar atrás da status bar
              const Text(
                "MEUS CONTRATOS",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: const Center(
                  child: Text(
                    "Nenhum contrato ativo no momento",
                    style: TextStyle(color: Colors.white24)
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}