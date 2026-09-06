import 'package:flutter/material.dart';

import 'package:versin/modules/chat/page/chat_page_coordinator.dart';
import 'package:versin/modules/chat/page/chat_page_view.dart';

// ============================================================
// CHAT PAGE
// ============================================================
//
// Composition root público do Chat.
//
// Mantém AutomaticKeepAlive porque o Chat vive no PageView do
// Dashboard e seu estado não deve ser recriado ao trocar de aba.
//
// ============================================================

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with AutomaticKeepAliveClientMixin {
  late final ChatPageCoordinator _coordinator;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _coordinator = ChatPageCoordinator();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return const ChatPageView();
  }

  @override
  void dispose() {
    _coordinator.dispose();

    super.dispose();
  }
}
