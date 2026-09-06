import 'dart:async';

import 'package:flutter/material.dart';

import 'package:versin/modules/networking/page/networking_session_coordinator.dart';
import 'package:versin/modules/networking/page/widgets/networking_session_action_button.dart';
import 'package:versin/modules/networking/page/widgets/networking_session_header.dart';
import 'package:versin/modules/networking/page/widgets/networking_session_overlays.dart';

class NetworkingSessionPageView extends StatelessWidget {
  final NetworkingSessionCoordinator coordinator;

  const NetworkingSessionPageView({super.key, required this.coordinator});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('Sessão de Estúdio', style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: ListenableBuilder(
              listenable: coordinator.controller,
              builder: (context, _) {
                if (coordinator.controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      NetworkingSessionHeader(
                        projectHash: coordinator.projectHash,
                      ),
                      const SizedBox(height: 25),
                      Wrap(
                        spacing: 15,
                        runSpacing: 20,
                        alignment: WrapAlignment.center,
                        children: [
                          NetworkingSessionActionButton(
                            icon: Icons.chat_bubble_rounded,
                            label: 'Chat',
                            color: Colors.blue,
                            onTap: () {
                              unawaited(coordinator.openChat(context));
                            },
                          ),
                          NetworkingSessionActionButton(
                            icon: Icons.call_rounded,
                            label: 'Ligar',
                            color: Colors.green,
                            onTap: () {
                              unawaited(coordinator.openCall(context));
                            },
                          ),
                          NetworkingSessionActionButton(
                            icon: Icons.edit_document,
                            label: 'Doc',
                            color: Colors.amber,
                            onTap: () {
                              unawaited(coordinator.openContract(context));
                            },
                          ),
                          NetworkingSessionActionButton(
                            icon: Icons.percent_rounded,
                            label: 'Royalties',
                            color: Colors.pink,
                            onTap: () {
                              unawaited(coordinator.openRoyalties(context));
                            },
                          ),
                          NetworkingSessionActionButton(
                            icon: Icons.person_add_alt_1_rounded,
                            label: 'Membros',
                            color: Colors.orange,
                            onTap: () {
                              unawaited(coordinator.openMembers(context));
                            },
                          ),
                          NetworkingSessionActionButton(
                            icon: Icons.task_alt_rounded,
                            label: 'Tarefas',
                            color: Colors.teal,
                            onTap: () {
                              unawaited(coordinator.openTasks(context));
                            },
                          ),
                          NetworkingSessionActionButton(
                            icon: Icons.logout_rounded,
                            label: coordinator.isLeavingProject
                                ? 'Saindo...'
                                : 'Sair',
                            color: Colors.red,
                            onTap: () {
                              if (coordinator.isLeavingProject) {
                                return;
                              }

                              unawaited(
                                coordinator.requestLeaveProject(context),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: NetworkingSessionOverlays(coordinator: coordinator),
          ),
        ],
      ),
    );
  }
}
