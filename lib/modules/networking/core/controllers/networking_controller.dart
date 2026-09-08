import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NetworkingController
    with
        ChangeNotifier {
  StreamSubscription<List<Map<String, dynamic>>>? _projectSubscription;
  bool _disposed = false;

  final String projectId;
  NetworkingController({
    required this.projectId,
  });

  Map<
    String,
    dynamic
  >?
  projectData;
  bool isLoading = true;

  void initSession() {
    // Escuta em tempo real as mudanças no contrato (JSONB)
    final previous = _projectSubscription;
    if (previous != null) unawaited(previous.cancel());
    _projectSubscription = Supabase.instance.client
        .from(
          'projects',
        )
        .stream(
          primaryKey: [
            'id',
          ],
        )
        .eq(
          'id',
          projectId,
        )
        .listen(
          (
            List<
              Map<
                String,
                dynamic
              >
            >
            snapshot,
          ) {
            if (_disposed) return;
            projectData = snapshot.isNotEmpty ? snapshot.first : null;
            isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<
    void
  >
  updateContract(
    String newContent,
  ) async {
    await Supabase.instance.client
        .from(
          'projects',
        )
        .update(
          {
            'contract_terms': {
              'content': newContent,
            },
            'updated_at': DateTime.now().toIso8601String(),
          },
        )
        .eq(
          'id',
          projectId,
        );
  }
  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final subscription = _projectSubscription;
    _projectSubscription = null;
    if (subscription != null) unawaited(subscription.cancel());
    super.dispose();
  }
}
