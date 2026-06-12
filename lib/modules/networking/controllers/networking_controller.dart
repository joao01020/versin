import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NetworkingController
    with
        ChangeNotifier {
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
    Supabase.instance.client
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
            if (snapshot.isNotEmpty) {
              projectData = snapshot.first;
              isLoading = false;
              notifyListeners();
            }
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
}
