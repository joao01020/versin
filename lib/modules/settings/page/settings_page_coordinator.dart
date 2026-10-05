import 'package:flutter/foundation.dart';

// ============================================================
// SETTINGS PAGE COORDINATOR
// ============================================================
//
// Boundary estável da página de Settings.
//
// Nesta etapa segura a implementação histórica foi movida para
// SettingsPageView sem alterar contratos sensíveis de:
//
// - logout;
// - heartbeat/presença;
// - perfil público;
// - quota;
// - rotas.
//
// ============================================================

class SettingsPageCoordinator extends ChangeNotifier {
  bool _disposed = false;

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    super.dispose();
  }
}
