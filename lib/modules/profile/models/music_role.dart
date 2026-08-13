// ============================================================
// MUSIC ROLE
// ============================================================
//
// Representa uma função profissional dentro do ecossistema
// musical do Versin.
//
// Utilizado por:
//
// - Perfil Profissional;
// - Dashboard;
// - Conectar / Match;
// - Repository;
// - Datasource;
// - Supabase.
//
// No Supabase armazenamos a propriedade:
//
// role.key
//
// Na interface mostramos:
//
// role.label
//
// Exemplo:
//
// Supabase:
// "beatmaker"
//
// Interface:
// "Beatmaker"
//
// ============================================================

enum MusicRole {
  // ==========================================================
  // ARTISTA
  // ==========================================================

  artist(
    key: 'artist',
    label: 'Artista',
  ),

  // ==========================================================
  // BEATMAKER
  // ==========================================================

  beatmaker(
    key: 'beatmaker',
    label: 'Beatmaker',
  ),

  // ==========================================================
  // PRODUTOR
  // ==========================================================

  producer(
    key: 'producer',
    label: 'Produtor Musical',
  ),

  // ==========================================================
  // COMPOSITOR
  // ==========================================================

  composer(
    key: 'composer',
    label: 'Compositor',
  ),

  // ==========================================================
  // ENGENHEIRO DE MIXAGEM
  // ==========================================================

  mixEngineer(
    key: 'mix_engineer',
    label: 'Eng. de Mixagem',
  ),

  // ==========================================================
  // ENGENHEIRO DE MASTERIZAÇÃO
  // ==========================================================

  masterEngineer(
    key: 'master_engineer',
    label: 'Eng. de Masterização',
  ),

  // ==========================================================
  // ENGENHEIRO DE GRAVAÇÃO
  // ==========================================================

  recordingEngineer(
    key: 'recording_engineer',
    label: 'Eng. de Gravação',
  ),

  // ==========================================================
  // INSTRUMENTISTA
  // ==========================================================

  instrumentalist(
    key: 'instrumentalist',
    label: 'Instrumentista',
  ),

  // ==========================================================
  // SOUND DESIGNER
  // ==========================================================

  soundDesigner(
    key: 'sound_designer',
    label: 'Sound Designer',
  ),

  // ==========================================================
  // DJ
  // ==========================================================

  dj(
    key: 'dj',
    label: 'DJ',
  );

  // ============================================================
  // PROPRIEDADES
  // ============================================================

  final String key;

  final String label;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const MusicRole({
    required this.key,
    required this.label,
  });

  // ============================================================
  // CONVERTER KEY → MUSIC ROLE
  // ============================================================
  //
  // Recebe o valor armazenado no Supabase:
  //
  // "artist"
  // "beatmaker"
  // "producer"
  //
  // e transforma em:
  //
  // MusicRole.artist
  // MusicRole.beatmaker
  // MusicRole.producer
  //
  // Retorna null quando:
  //
  // - valor for null;
  // - valor estiver vazio;
  // - função não existir.
  //
  // ============================================================

  static MusicRole? fromKey(
    String? key,
  ) {
    if (key ==
        null) {
      return null;
    }

    final normalizedKey = key.trim().toLowerCase();

    if (normalizedKey.isEmpty) {
      return null;
    }

    for (final role in MusicRole.values) {
      if (role.key ==
          normalizedKey) {
        return role;
      }
    }

    return null;
  }

  // ============================================================
  // CONVERTER LISTA DE KEYS → MUSIC ROLES
  // ============================================================
  //
  // Exemplo vindo do Supabase:
  //
  // [
  //   "artist",
  //   "composer",
  //   "beatmaker"
  // ]
  //
  // Resultado:
  //
  // [
  //   MusicRole.artist,
  //   MusicRole.composer,
  //   MusicRole.beatmaker
  // ]
  //
  // Valores desconhecidos são ignorados.
  //
  // ============================================================

  static List<
    MusicRole
  >
  fromKeys(
    Iterable<
      dynamic
    >?
    keys,
  ) {
    if (keys ==
        null) {
      return const [];
    }

    final roles =
        <
          MusicRole
        >{};

    for (final value in keys) {
      final role = fromKey(
        value?.toString(),
      );

      if (role !=
          null) {
        roles.add(
          role,
        );
      }
    }

    return roles.toList();
  }

  // ============================================================
  // CONVERTER MUSIC ROLES → KEYS
  // ============================================================
  //
  // Utilizado antes de enviar para o Supabase.
  //
  // ============================================================

  static List<
    String
  >
  toKeys(
    Iterable<
      MusicRole
    >
    roles,
  ) {
    return roles
        .map(
          (
            role,
          ) => role.key,
        )
        .toSet()
        .toList();
  }

  // ============================================================
  // CONVERTER MUSIC ROLES → LABELS
  // ============================================================
  //
  // Útil para exibição futura no Match.
  //
  // ============================================================

  static List<
    String
  >
  toLabels(
    Iterable<
      MusicRole
    >
    roles,
  ) {
    return roles
        .map(
          (
            role,
          ) => role.label,
        )
        .toSet()
        .toList();
  }
}
