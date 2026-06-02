import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../controllers/hub_telemetry_controller.dart';

class MasterSearchCard
    extends
        StatelessWidget {
  final HubTelemetryController controller;
  final bool online;
  final String mensagemSub;

  const MasterSearchCard({
    super.key,
    required this.controller,
    required this.online,
    required this.mensagemSub,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    const Color primaryPurple = Color(
      0xFF6A1B9A,
    );
    const Color accentNeon = Color(
      0xFFE040FB,
    );
    const Color hardwareRed = Color(
      0xFFFF2A6D,
    );
    const Color hackerGreen = Color(
      0xFF00FF66,
    );

    return ValueListenableBuilder<
      SearchState
    >(
      valueListenable: controller.searchState,
      builder:
          (
            context,
            state,
            _,
          ) {
            Color currentBorderColor;
            Color buttonBgColor;
            Color buttonContentColor;
            String buttonText;
            IconData buttonIcon;

            switch (state) {
              case SearchState.searching:
                currentBorderColor = accentNeon.withValues(
                  alpha: 0.5,
                );
                buttonBgColor = Colors.redAccent.withValues(
                  alpha: 0.15,
                );
                buttonContentColor = Colors.redAccent;
                buttonText = "CANCELAR BUSCA";
                buttonIcon = Icons.power_settings_new;
                break;
              case SearchState.found:
                currentBorderColor = hackerGreen.withValues(
                  alpha: 0.7,
                );
                buttonBgColor = hackerGreen.withValues(
                  alpha: 0.2,
                );
                buttonContentColor = hackerGreen;
                buttonText = "CONEXÃO FIRMADA";
                buttonIcon = Icons.check_circle;
                break;
              case SearchState.notFound:
                currentBorderColor = hardwareRed.withValues(
                  alpha: 0.7,
                );
                buttonBgColor = hardwareRed.withValues(
                  alpha: 0.2,
                );
                buttonContentColor = hardwareRed;
                buttonText = "CHASSI NÃO ENCONTRADO";
                buttonIcon = Icons.error_outline;
                break;
              case SearchState.idle:
                currentBorderColor = Colors.white.withValues(
                  alpha: 0.06,
                );
                buttonBgColor = primaryPurple.withValues(
                  alpha: 0.2,
                );
                buttonContentColor = Colors.white;
                buttonText = "SINCRONIZAR";
                buttonIcon = Icons.sync_lock_rounded;
                break;
            }

            return AnimatedContainer(
              duration: const Duration(
                milliseconds: 400,
              ),
              width: double.infinity,
              height: 210,
              decoration: BoxDecoration(
                color:
                    state ==
                        SearchState.found
                    ? hackerGreen.withValues(
                        alpha: 0.03,
                      )
                    : state ==
                          SearchState.notFound
                    ? hardwareRed.withValues(
                        alpha: 0.03,
                      )
                    : Colors.white.withValues(
                        alpha: 0.02,
                      ),
                borderRadius: BorderRadius.circular(
                  26,
                ),
                border: Border.all(
                  color: currentBorderColor,
                  width:
                      state !=
                          SearchState.idle
                      ? 1.5
                      : 1.0,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  25,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ValueListenableBuilder<
                      bool
                    >(
                      valueListenable: controller.isGlobalSearching,
                      builder:
                          (
                            context,
                            globalSearching,
                            _,
                          ) {
                            if (!globalSearching) return const SizedBox.shrink();
                            return AnimatedBuilder(
                              animation: controller.globalSearchController,
                              builder:
                                  (
                                    context,
                                    child,
                                  ) {
                                    return CustomPaint(
                                      painter: RadarPulsePainter(
                                        progress: controller.globalSearchController.value,
                                        pulseColor: accentNeon,
                                      ),
                                      child: const SizedBox.expand(),
                                    );
                                  },
                            );
                          },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(
                        24,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Varredura Sem Fio Global".toUpperCase(),
                                    style: TextStyle(
                                      color:
                                          state ==
                                              SearchState.found
                                          ? hackerGreen
                                          : state ==
                                                SearchState.notFound
                                          ? hardwareRed
                                          : accentNeon,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 4,
                                  ),
                                  const Text(
                                    "Procurando Versin Chassi Pro",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: online
                                              ? hackerGreen
                                              : hardwareRed,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  (online
                                                          ? hackerGreen
                                                          : hardwareRed)
                                                      .withValues(
                                                        alpha: 0.5,
                                                      ),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 6,
                                      ),
                                      Text(
                                        online
                                            ? "Online"
                                            : "Offline",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 2,
                                  ),
                                  Text(
                                    mensagemSub,
                                    style: const TextStyle(
                                      color: Colors.white24,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                if (state ==
                                    SearchState.searching) {
                                  controller.cancelActiveSearch();
                                } else if (state ==
                                    SearchState.idle) {
                                  if (controller.forceOffline.value) {
                                    controller.forceOffline.value = false;
                                  } else {
                                    controller.startActiveHardwareSearch(
                                      online,
                                    );
                                  }
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(
                                  milliseconds: 250,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: buttonBgColor,
                                  borderRadius: BorderRadius.circular(
                                    16,
                                  ),
                                  border: Border.all(
                                    color: buttonContentColor.withValues(
                                      alpha: 0.4,
                                    ),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    if (controller.isGlobalSearching.value ||
                                        state ==
                                            SearchState.found)
                                      BoxShadow(
                                        color: buttonContentColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      buttonIcon,
                                      color: buttonContentColor,
                                      size: 18,
                                    ),
                                    const SizedBox(
                                      width: 12,
                                    ),
                                    Text(
                                      buttonText,
                                      style: TextStyle(
                                        color: buttonContentColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Text(
                            state ==
                                    SearchState.searching
                                ? "Sintonizando transceptores de rádio 2.4GHz..."
                                : state ==
                                      SearchState.found
                                ? "Handshake com ESP32 efetuado com sucesso!"
                                : state ==
                                      SearchState.notFound
                                ? "Nenhum sinal recebido nos broadcasts UDP/HTTP."
                                : "Interface de acoplamento em modo de escuta passiva",
                            style: TextStyle(
                              color:
                                  state ==
                                      SearchState.searching
                                  ? Colors.white60
                                  : state ==
                                        SearchState.idle
                                  ? Colors.white24
                                  : buttonContentColor.withValues(
                                      alpha: 0.7,
                                    ),
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }
}

class RadarPulsePainter
    extends
        CustomPainter {
  final double progress;
  final Color pulseColor;

  RadarPulsePainter({
    required this.progress,
    required this.pulseColor,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final double maxRadius =
        math.sqrt(
          size.width *
                  size.width +
              size.height *
                  size.height,
        ) /
        2;
    final double currentRadius =
        maxRadius *
        progress;
    final double opacity =
        (1.0 -
                progress)
            .clamp(
              0.0,
              1.0,
            );

    final Paint paint = Paint()
      ..color = pulseColor.withValues(
        alpha:
            opacity *
            0.15,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(
      Offset(
        size.width /
            2,
        size.height /
            2,
      ),
      currentRadius,
      paint,
    );
  }

  @override
  bool
  shouldRepaint(
    covariant RadarPulsePainter oldDelegate,
  ) =>
      oldDelegate.progress !=
      progress;
}
