// ============================================================
// RECENT ACTIVITY TYPE
// ============================================================
//
// Tipos de atividades recentes exibidas no Dashboard.
//
// ============================================================

enum RecentActivityType {
  welcome(
    key: 'welcome',
    label: 'Bem-vindo',
  ),

  profileUpdated(
    key: 'profile_updated',
    label: 'Perfil profissional atualizado',
  ),

  connection(
    key: 'connection',
    label: 'Nova conexão',
  ),

  favorite(
    key: 'favorite',
    label: 'Perfil favoritado',
  ),

  fileAdded(
    key: 'file_added',
    label: 'Arquivo adicionado',
  );

  final String key;

  final String label;

  const RecentActivityType({
    required this.key,
    required this.label,
  });

  // ============================================================
  // FROM KEY
  // ============================================================

  static RecentActivityType fromKey(
    String? key,
  ) {
    if (key ==
            null ||
        key.trim().isEmpty) {
      return RecentActivityType.welcome;
    }

    final normalizedKey = key.trim().toLowerCase();

    for (final type in values) {
      if (type.key ==
          normalizedKey) {
        return type;
      }
    }

    return RecentActivityType.welcome;
  }
}
