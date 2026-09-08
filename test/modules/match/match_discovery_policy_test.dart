import 'package:flutter_test/flutter_test.dart';
import 'package:versin/modules/match/data/repositories/match_discovery_policy.dart';
import 'package:versin/modules/match/models/match_discovery_mode.dart';
import 'package:versin/modules/profile/models/music_role.dart';

void main() {
  group('Presença na descoberta', () {
    test('Compatíveis e Próximos aceitam online e offline', () {
      for (final mode in [
        MatchDiscoveryMode.compatible,
        MatchDiscoveryMode.nearby,
      ]) {
        expect(
          MatchDiscoveryPolicy.allowsPresence(mode: mode, isOnline: true),
          isTrue,
        );
        expect(
          MatchDiscoveryPolicy.allowsPresence(mode: mode, isOnline: false),
          isTrue,
        );
      }
    });

    test('Agora exige presença online', () {
      expect(
        MatchDiscoveryPolicy.allowsPresence(
          mode: MatchDiscoveryMode.global,
          isOnline: true,
        ),
        isTrue,
      );
      expect(
        MatchDiscoveryPolicy.allowsPresence(
          mode: MatchDiscoveryMode.global,
          isOnline: false,
        ),
        isFalse,
      );
    });
  });

  group('Compatibilidade profissional', () {
    final artist = MusicRole.fromKey('artist');
    final beatmaker = MusicRole.fromKey('beatmaker');

    test('reconhece as funções de teste', () {
      expect(artist, isNotNull);
      expect(beatmaker, isNotNull);
    });

    test('Compatíveis aceita interesse em qualquer direção', () {
      final me = [artist!];
      final wanted = [beatmaker!];

      expect(
        MatchDiscoveryPolicy.matchesRoles(
          mode: MatchDiscoveryMode.compatible,
          currentRoles: me,
          lookingForRoles: wanted,
          candidateRoles: wanted,
          candidateLookingForRoles: const [],
        ),
        isTrue,
      );

      expect(
        MatchDiscoveryPolicy.matchesRoles(
          mode: MatchDiscoveryMode.compatible,
          currentRoles: me,
          lookingForRoles: const [],
          candidateRoles: wanted,
          candidateLookingForRoles: me,
        ),
        isTrue,
      );
    });

    test('Agora e Próximos preservam a busca por funções desejadas', () {
      final me = [artist!];
      final wanted = [beatmaker!];

      for (final mode in [
        MatchDiscoveryMode.global,
        MatchDiscoveryMode.nearby,
      ]) {
        expect(
          MatchDiscoveryPolicy.matchesRoles(
            mode: mode,
            currentRoles: me,
            lookingForRoles: const [],
            candidateRoles: wanted,
            candidateLookingForRoles: me,
          ),
          isFalse,
        );
      }
    });

    test('não considera perfis sem correspondência profissional', () {
      expect(
        MatchDiscoveryPolicy.matchesRoles(
          mode: MatchDiscoveryMode.compatible,
          currentRoles: [artist!],
          lookingForRoles: const [],
          candidateRoles: [beatmaker!],
          candidateLookingForRoles: const [],
        ),
        isFalse,
      );
    });
  });
}
