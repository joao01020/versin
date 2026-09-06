import 'package:flutter/foundation.dart';

// ============================================================
// CHAT PAGE COORDINATOR
// ============================================================
//
// Boundary de página para evolução incremental.
//
// Nesta etapa segura, a implementação histórica do Chat foi
// movida integralmente para ChatPageView para preservar todos os
// contratos existentes. Este coordinator concentra somente estado
// pertencente ao composition root.
//
// Ele existe como ponto estável para a próxima decomposição de:
//
// - bootstrap da IA;
// - quota;
// - source switching;
// - onboarding;
// - navegação do Chat.
//
// ============================================================

class ChatPageCoordinator extends ChangeNotifier {
  bool _disposed = false;

  bool get isDisposed => _disposed;

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    super.dispose();
  }
}
