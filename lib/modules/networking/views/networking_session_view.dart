import 'package:flutter/material.dart';

import '../call/views/call_view.dart';
import '../controllers/networking_controller.dart';
import 'sub_features/chat_view.dart';
import 'sub_features/contract_view.dart';
import 'sub_features/members_view.dart';
import 'sub_features/royalties_view.dart';
import 'sub_features/tasks_view.dart';

class NetworkingSessionView
    extends
        StatefulWidget {
  final String projectId;

  const NetworkingSessionView({
    super.key,
    required this.projectId,
  });

  @override
  State<
    NetworkingSessionView
  >
  createState() => _NetworkingSessionViewState();
}

class _NetworkingSessionViewState
    extends
        State<
          NetworkingSessionView
        > {
  late final NetworkingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = NetworkingController(
      projectId: widget.projectId,
    )..initSession();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0F0F0F,
      ),
      appBar: AppBar(
        title: const Text(
          'Studio Session',
          style: TextStyle(
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder:
            (
              context,
              _,
            ) {
              if (_controller.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final projectHash =
                  widget.projectId.length >=
                      8
                  ? widget.projectId
                        .substring(
                          0,
                          8,
                        )
                        .toUpperCase()
                  : widget.projectId.toUpperCase();

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    _buildHeader(
                      projectHash,
                    ),

                    const SizedBox(
                      height: 25,
                    ),

                    Wrap(
                      spacing: 15,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildSmallAction(
                          Icons.chat_bubble_rounded,
                          'Chat',
                          Colors.blue,
                          () => _openPage(
                            ChatView(
                              projectId: widget.projectId,
                            ),
                          ),
                        ),
                        _buildSmallAction(
                          Icons.call_rounded,
                          'Ligar',
                          Colors.green,
                          () => _openPage(
                            CallView(
                              projectId: widget.projectId,
                            ),
                          ),
                        ),
                        _buildSmallAction(
                          Icons.edit_document,
                          'Doc',
                          Colors.amber,
                          () => _openPage(
                            ContractView(
                              projectId: widget.projectId,
                            ),
                          ),
                        ),
                        _buildSmallAction(
                          Icons.percent_rounded,
                          'Royalties',
                          Colors.pink,
                          () => _openPage(
                            RoyaltiesView(
                              projectId: widget.projectId,
                            ),
                          ),
                        ),
                        _buildSmallAction(
                          Icons.person_add_alt_1_rounded,
                          'Membros',
                          Colors.orange,
                          () => _openPage(
                            MembersView(
                              projectId: widget.projectId,
                            ),
                          ),
                        ),
                        _buildSmallAction(
                          Icons.task_alt_rounded,
                          'Tarefas',
                          Colors.teal,
                          () => _openPage(
                            TasksView(
                              projectId: widget.projectId,
                            ),
                          ),
                        ),
                        _buildSmallAction(
                          Icons.close_rounded,
                          'Sair',
                          Colors.red,
                          () => Navigator.pop(
                            context,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
      ),
    );
  }

  Widget _buildHeader(
    String projectHash,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade900,
            Colors.black,
          ],
        ),
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.music_note,
              color: Colors.white,
            ),
          ),

          const SizedBox(
            width: 15,
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Conectados via match',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Hash: #$projectHash',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openPage(
    Widget page,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => page,
      ),
    );
  }

  Widget _buildSmallAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
              border: Border.all(
                color: color.withValues(
                  alpha: 0.3,
                ),
              ),
            ),
            child: Icon(
              icon,
              size: 22,
              color: color,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }
}
