import 'package:flutter/material.dart';
import 'package:versin/app/locator.dart';

import '../../controllers/dashboard_controller.dart';
import '../../widgets/calendar_card_widget.dart';

class CalendarPage
    extends
        StatefulWidget {
  const CalendarPage({
    super.key,
  });

  @override
  State<
    CalendarPage
  >
  createState() => _CalendarPageState();
}

class _CalendarPageState
    extends
        State<
          CalendarPage
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

        // ======================================================
        // GRADIENTE
        // ======================================================
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
                        'AGENDA COMPLETA',

                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 24,
                ),

                // ==================================================
                // CALENDÁRIO
                // ==================================================
                CalendarCardWidget(
                  controller: controller,

                  onStateChanged: () {
                    if (!mounted) {
                      return;
                    }

                    setState(
                      () {},
                    );
                  },

                  onAddAppointmentTap: () {
                    // ==============================================
                    // FUTURA LÓGICA PARA ADICIONAR AGENDAMENTO
                    // ==============================================
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
