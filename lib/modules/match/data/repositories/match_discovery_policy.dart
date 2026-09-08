import 'package:versin/modules/match/models/match_discovery_mode.dart';
import 'package:versin/modules/profile/models/music_role.dart';

/// Separa a elegibilidade profissional da presença do usuário.
abstract final class MatchDiscoveryPolicy {
  static bool requiresOnlinePresence(MatchDiscoveryMode mode) {
    return mode == MatchDiscoveryMode.global;
  }

  static bool allowsPresence({
    required MatchDiscoveryMode mode,
    required bool isOnline,
  }) {
    return !requiresOnlinePresence(mode) || isOnline;
  }

  static bool matchesRoles({
    required MatchDiscoveryMode mode,
    required Iterable<MusicRole> currentRoles,
    required Iterable<MusicRole> lookingForRoles,
    required Iterable<MusicRole> candidateRoles,
    required Iterable<MusicRole> candidateLookingForRoles,
  }) {
    final outgoing = _intersects(lookingForRoles, candidateRoles);
    if (mode != MatchDiscoveryMode.compatible) {
      return outgoing;
    }

    // Compatíveis também inclui quem procura uma função que eu exerço.
    return outgoing || _intersects(currentRoles, candidateLookingForRoles);
  }

  static bool _intersects(
    Iterable<MusicRole> first,
    Iterable<MusicRole> second,
  ) {
    final values = second.toSet();
    return first.any(values.contains);
  }
}
