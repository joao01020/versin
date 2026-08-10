import 'package:flutter/material.dart';
import 'package:versin/app/locator.dart';

import '../../controllers/dashboard_controller.dart';

class ContractsPage
    extends
        StatefulWidget {
  const ContractsPage({
    super.key,
  });

  @override
  State<
    ContractsPage
  >
  createState() => _ContractsPageState();
}

class _ContractsPageState
    extends
        State<
          ContractsPage
        > {
  final DashboardController controller =
      sl<
        DashboardController
      >();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0D0B1F,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(
                0xFF1F1A3A,
              ),
              Color(
                0xFF0D0B1F,
              ),
            ],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 40,
              ),

              const Text(
                'MEUS CONTRATOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.05,
                  ),
                  borderRadius: BorderRadius.circular(
                    16,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: 0.05,
                    ),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Nenhum contrato ativo no momento',
                    style: TextStyle(
                      color: Colors.white24,
                    ),
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
