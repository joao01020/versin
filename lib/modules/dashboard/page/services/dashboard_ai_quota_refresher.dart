import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';
import 'package:versin/modules/chat/ai/services/private_api/private_ai_client.dart';
import 'package:versin/modules/chat/ai/services/private_api/private_api_service.dart';
import 'package:versin/modules/chat/ai/services/provider/ai_provider_service.dart';
import 'package:versin/modules/chat/data/datasources/chat_remote_datasource.dart';
import 'package:versin/modules/chat/data/repositories/chat_repository_impl.dart';

// ============================================================
// DASHBOARD AI QUOTA REFRESHER
// ============================================================
//
// Isola do DashboardPage/Coordinator:
//
// - autenticação atual;
// - composição do repositório de Chat;
// - fetch da quota;
// - validação de troca de conta;
// - aplicação da quota no RhymesController.
//
// O Dashboard apenas dispara refresh() em background.
//
// ============================================================

class DashboardAiQuotaRefresher {
  final SupabaseClient _supabase;
  final RhymesController _rhymesController;

  DashboardAiQuotaRefresher({
    required RhymesController rhymesController,
    SupabaseClient? supabase,
  }) : _rhymesController = rhymesController,
       _supabase = supabase ?? Supabase.instance.client;

  Future<void> refresh() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      debugPrint(
        '[DASHBOARD] '
        'Quota não atualizada: usuário não autenticado.',
      );

      return;
    }

    final userId = user.id.trim();

    if (userId.isEmpty) {
      debugPrint(
        '[DASHBOARD] '
        'Quota não atualizada: userId inválido.',
      );

      return;
    }

    debugPrint(
      '[DASHBOARD] '
      'Atualizando quota real da IA Versin.',
    );

    final repository = _buildRepository();

    try {
      final quota = await repository.fetchAiQuota();

      final currentUserId = _supabase.auth.currentUser?.id.trim();

      if (currentUserId != userId) {
        debugPrint(
          '[DASHBOARD] '
          'Resposta de quota descartada: '
          'a conta autenticada mudou.',
        );

        return;
      }

      if (quota.isEmpty) {
        _applyEmptyState();

        return;
      }

      _rhymesController.updateAiQuotaFromMap(quota, notify: true);

      debugPrint(
        '[DASHBOARD] '
        'Quota real atualizada com sucesso.',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[DASHBOARD] '
        'Não foi possível atualizar a quota real: '
        '$error',
      );

      debugPrint(
        '[DASHBOARD] '
        'Mantendo quota/cache atual.',
      );

      debugPrint('$stackTrace');
    }
  }

  ChatRepositoryImpl _buildRepository() {
    final privateApiService = PrivateApiService();

    final aiProviderService = AiProviderService(
      privateApiService: privateApiService,
    );

    final privateAiClient = PrivateAiClient();

    final remoteDatasource = ChatRemoteDatasource();

    return ChatRepositoryImpl(
      remoteDatasource: remoteDatasource,
      aiProviderService: aiProviderService,
      privateAiClient: privateAiClient,
    );
  }

  void _applyEmptyState() {
    _rhymesController.updateAiQuotaFromMap(<String, dynamic>{
      'usage_percentage': 0.0,
      'progress': 0.0,
      'level': 'normal',
      'message': 'Cota ainda não inicializada.',
      'blocked': false,
      'can_use_ai': true,
      'used_tokens': 0,
      'remaining_tokens': 0,
      'limit_tokens': 0,
    }, notify: true);

    debugPrint(
      '[DASHBOARD] '
      'Estado inicial da quota aplicado: '
      '0 usados | 0 restantes | 0 limite.',
    );
  }
}
