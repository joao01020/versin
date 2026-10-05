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
  // ============================================================
  // CONTROLLER
  // ============================================================

  final DashboardController controller =
      sl<
        DashboardController
      >();

  // ============================================================
  // VOLTAR
  // ============================================================

  void _goBack() {
    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).maybePop();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0D0B1F,
      ),

      body: Container(
        width: double.infinity,

        height: double.infinity,

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

        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),

            padding: const EdgeInsets.symmetric(
              horizontal: 20,

              vertical: 20,
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // ==================================================
                // CABEÇALHO
                // ==================================================
                Row(
                  children: [
                    // ==============================================
                    // BOTÃO VOLTAR
                    // ==============================================
                    Material(
                      color: Colors.transparent,

                      child: InkWell(
                        onTap: _goBack,

                        borderRadius: BorderRadius.circular(
                          12,
                        ),

                        child: Container(
                          width: 42,

                          height: 42,

                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: 0.06,
                            ),

                            borderRadius: BorderRadius.circular(
                              12,
                            ),

                            border: Border.all(
                              color: Colors.white.withValues(
                                alpha: 0.08,
                              ),
                            ),
                          ),

                          child: const Icon(
                            Icons.arrow_back_rounded,

                            color: Colors.white,

                            size: 21,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 14,
                    ),

                    // ==============================================
                    // TÍTULO
                    // ==============================================
                    const Expanded(
                      child: Text(
                        'MEUS CONTRATOS',

                        style: TextStyle(
                          color: Colors.white,

                          fontSize: 18,

                          fontWeight: FontWeight.bold,

                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 24,
                ),

                // ==================================================
                // CONTEÚDO
                // ==================================================
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

                      textAlign: TextAlign.center,

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
      ),
    );
  }
}
