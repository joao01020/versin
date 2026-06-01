import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../controllers/match_controllers.dart';
import '../../models/match_user_entity.dart';

class MatchRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // EN: Computes target alignment rules protecting compilation from missing Enum values
  // PT: Computa as regras de alinhamento de alvos protegendo a compilação de valores ausentes no Enum
  List<String> _determineTargetRoles(UserRole currentUserRole) {
    // Usando String na comparação do nome para evitar quebra caso o Enum mude
    final roleName = currentUserRole.name;

    if (roleName == 'artist') {
      return ['beatmaker', 'investor'];
    } else if (roleName == 'beatmaker') {
      return ['artist', 'investor'];
    } else {
      // Fallback seguro caso o usuário logado seja investidor ou outro papel futuro
      return ['artist', 'beatmaker'];
    }
  }

  // EN: Streams active users and filters them in memory to comply with SupabaseStreamBuilder specs
  // PT: Puxa o fluxo de usuários ativos e filtra em memória para respeitar as primeiras especificações do SupabaseStreamBuilder
  void streamCrossRoleMatches(MatchController controller, UserRole currentUserRole) {
    final allowedRoles = _determineTargetRoles(currentUserRole);

    _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('is_online', true) // Filtro simples aceito nativamente por Streams do Supabase
        .listen((List<Map<String, dynamic>> data) {
          if (data.isEmpty) return;

          // EN: Realtime filtering executed in memory over the pipeline records
          // PT: Filtragem em tempo real executada em memória sobre os registros do pipeline
          final filteredData = data.where((item) {
            final roleStr = item['role'] ?? '';
            return allowedRoles.contains(roleStr);
          }).toList();

          if (filteredData.isEmpty) return;

          // 1. O primeiro da lista filtrada vira o destaque da Vitrine Principal (Discovery)
          final mainItem = filteredData.first;
          final discovery = _mapMapToEntity(mainItem);
          controller.setDiscoveryUser(discovery);

          // 2. O restante vira a lista de Recomendados logo abaixo
          final recommended = filteredData.skip(1).map((item) => _mapMapToEntity(item)).toList();
          controller.updateRecommendedUsers(recommended);
        }, onError: (error) {
          debugPrint("Erro no pipeline do algoritmo de Match: $error");
        });
  }

  // EN: Helper mapping database rows into structured data entities safely using fallbacks
  // PT: Helper mapeando colunas do banco em entidades de dados estruturados com segurança usando fallbacks
  MatchUserEntity _mapMapToEntity(Map<String, dynamic> map) {
    UserRole parsedRole = UserRole.artist;
    final dbRole = map['role'] ?? 'artist';

    if (dbRole == 'beatmaker') {
      parsedRole = UserRole.beatmaker;
    } else if (dbRole == 'investor') {
      // PT: Se o seu Enum ainda não tiver 'investor', joga para 'artist' temporariamente para o app não crashar
      // EN: If your Enum does not have 'investor' yet, fallbacks to 'artist' temporarily to prevent app crashes
      try {
        parsedRole = UserRole.values.byName('investor');
      } catch (_) {
        parsedRole = UserRole.artist;
      }
    } else {
      parsedRole = UserRole.artist;
    }

    return MatchUserEntity(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Sem Nome',
      role: parsedRole,
      tags: List<String>.from(map['tags'] ?? []),
      bio: map['bio'] ?? '',
      showcaseMediaUrl: map['showcase_url'] ?? '',
      showcaseDescription: map['showcase_desc'] ?? '',
      distanceKm: (map['distance'] ?? 0.0).toDouble(),
      isOnline: map['is_online'] ?? false,
    );
  }
}