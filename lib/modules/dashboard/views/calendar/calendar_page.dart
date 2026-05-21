import 'package:flutter/material.dart';
import 'package:versin/app/locator.dart'; 
import '../../controllers/dashboard_controller.dart';
import '../../widgets/calendar_card_widget.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final DashboardController controller = sl<DashboardController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1F),
      body: Container(
        // Aplicando o mesmo gradiente para manter a identidade visual
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
              const SizedBox(height: 40), // Espaço para barra de status
              const Text(
                "AGENDA COMPLETA",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              CalendarCardWidget(
                controller: controller,
                onStateChanged: () {
                  if (mounted) setState(() {});
                },
                onAddAppointmentTap: () {
                  // Lógica de adicionar agendamento
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}