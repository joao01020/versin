// ============================================================
// MATCH DISCOVERY MODE
// ============================================================
//
// Define como os candidatos do Match serão descobertos.
//
// Este enum é compartilhado entre:
//
// - MatchController;
// - MatchRepository;
// - filtros do Match;
// - widgets de seleção do modo.
//
// IMPORTANTE:
//
// A regra de busca NÃO fica neste arquivo.
//
// Este arquivo define apenas:
//
// - os modos disponíveis;
// - propriedades auxiliares;
// - configurações padrão de cada modo;
// - informações utilizadas pela interface.
//
// ============================================================

enum MatchDiscoveryMode {
  // ==========================================================
  // COMPATÍVEIS
  // ==========================================================
  //
  // Mostra usuários que:
  //
  // - estão online;
  // - não são o próprio usuário;
  // - possuem função compatível com lookingForRoles;
  // - são ordenados pelo score profissional.
  //
  // Não utiliza localização.
  //
  // ==========================================================
  compatible,

  // ==========================================================
  // PRÓXIMOS
  // ==========================================================
  //
  // Mostra usuários que:
  //
  // - estão online;
  // - não são o próprio usuário;
  // - possuem função compatível com lookingForRoles;
  // - possuem localização habilitada;
  // - possuem latitude e longitude válidas.
  //
  // Os candidatos são ordenados:
  //
  // 1. do mais próximo para o mais distante;
  // 2. em caso de empate, pelo score de compatibilidade.
  //
  // Antes de utilizar este modo:
  //
  // - o usuário confirma o aviso de localização;
  // - o aplicativo solicita a permissão nativa do sistema;
  // - latitude e longitude são atualizadas no perfil.
  //
  // ==========================================================
  nearby,

  // ==========================================================
  // GLOBAL
  // ==========================================================
  //
  // Mostra usuários que:
  //
  // - estão online;
  // - não são o próprio usuário;
  // - podem possuir qualquer função;
  // - não precisam corresponder ao lookingForRoles.
  //
  // Não aplica filtro de localização.
  //
  // A compatibilidade profissional pode ser utilizada apenas
  // como critério auxiliar de ordenação.
  //
  // ==========================================================
  global,
}

// ============================================================
// MATCH DISCOVERY MODE EXTENSION
// ============================================================
//
// Informações auxiliares utilizadas principalmente por:
//
// - MatchPage;
// - MatchRepository;
// - MatchSessionService;
// - filtros;
// - persistência;
// - analytics.
//
// ============================================================

extension MatchDiscoveryModeExtension
    on
        MatchDiscoveryMode {
  // ==========================================================
  // LABEL
  // ==========================================================

  String get label {
    switch (this) {
      case MatchDiscoveryMode.compatible:
        return 'COMPATÍVEIS';

      case MatchDiscoveryMode.nearby:
        return 'PRÓXIMOS';

      case MatchDiscoveryMode.global:
        return 'GLOBAL';
    }
  }

  // ==========================================================
  // DESCRIÇÃO
  // ==========================================================

  String get description {
    switch (this) {
      case MatchDiscoveryMode.compatible:
        return 'Profissionais compatíveis com o que você procura.';

      case MatchDiscoveryMode.nearby:
        return 'Profissionais compatíveis próximos da sua localização.';

      case MatchDiscoveryMode.global:
        return 'Todos os profissionais disponíveis.';
    }
  }

  // ==========================================================
  // DESCRIÇÃO CURTA
  // ==========================================================
  //
  // Útil para:
  //
  // - subtítulos;
  // - tooltips;
  // - menus compactos.
  //
  // ==========================================================

  String get shortDescription {
    switch (this) {
      case MatchDiscoveryMode.compatible:
        return 'Compatíveis com você';

      case MatchDiscoveryMode.nearby:
        return 'Próximos de você';

      case MatchDiscoveryMode.global:
        return 'Todos online';
    }
  }

  // ==========================================================
  // TÍTULO DOS RESULTADOS
  // ==========================================================

  String get resultsTitle {
    switch (this) {
      case MatchDiscoveryMode.compatible:
        return 'Compatíveis com você';

      case MatchDiscoveryMode.nearby:
        return 'Próximos de você';

      case MatchDiscoveryMode.global:
        return 'Profissionais disponíveis';
    }
  }

  // ==========================================================
  // MENSAGEM SEM RESULTADOS
  // ==========================================================

  String get emptyMessage {
    switch (this) {
      case MatchDiscoveryMode.compatible:
        return 'Nenhum profissional compatível encontrado.';

      case MatchDiscoveryMode.nearby:
        return 'Nenhum profissional compatível foi encontrado por perto.';

      case MatchDiscoveryMode.global:
        return 'Nenhum outro profissional está disponível agora.';
    }
  }

  // ==========================================================
  // KEY
  // ==========================================================
  //
  // Utilizado para:
  //
  // - persistência;
  // - Supabase;
  // - preferências locais;
  // - analytics.
  //
  // ==========================================================

  String get key {
    switch (this) {
      case MatchDiscoveryMode.compatible:
        return 'compatible';

      case MatchDiscoveryMode.nearby:
        return 'nearby';

      case MatchDiscoveryMode.global:
        return 'global';
    }
  }

  // ==========================================================
  // ANALYTICS NAME
  // ==========================================================
  //
  // Mantém uma identificação estável para eventos futuros.
  //
  // ==========================================================

  String get analyticsName {
    switch (this) {
      case MatchDiscoveryMode.compatible:
        return 'match_compatible';

      case MatchDiscoveryMode.nearby:
        return 'match_nearby';

      case MatchDiscoveryMode.global:
        return 'match_global';
    }
  }

  // ==========================================================
  // USA LOCALIZAÇÃO
  // ==========================================================

  bool get usesLocation {
    switch (this) {
      case MatchDiscoveryMode.compatible:
        return false;

      case MatchDiscoveryMode.nearby:
        return true;

      case MatchDiscoveryMode.global:
        return false;
    }
  }

  // ==========================================================
  // EXIGE CONSENTIMENTO DE LOCALIZAÇÃO
  // ==========================================================
  //
  // Atualmente somente o modo nearby necessita do aceite
  // específico apresentado pelo Versin.
  //
  // ==========================================================

  bool get requiresLocationConsent {
    return this ==
        MatchDiscoveryMode.nearby;
  }

  // ==========================================================
  // PERMITE FILTRO DE DISTÂNCIA
  // ==========================================================

  bool get supportsDistanceFilter {
    return this ==
        MatchDiscoveryMode.nearby;
  }

  // ==========================================================
  // RAIO PADRÃO
  // ==========================================================
  //
  // null:
  //
  // o modo não utiliza limite geográfico.
  //
  // nearby:
  //
  // inicia com 50 km.
  //
  // A aplicação pode permitir que o usuário altere esse valor
  // posteriormente através dos filtros.
  //
  // ==========================================================

  double? get defaultRadiusKm {
    switch (this) {
      case MatchDiscoveryMode.compatible:
        return null;

      case MatchDiscoveryMode.nearby:
        return 50.0;

      case MatchDiscoveryMode.global:
        return null;
    }
  }

  // ==========================================================
  // DISTÂNCIA MÁXIMA DISPONÍVEL
  // ==========================================================
  //
  // Valor máximo que a interface pode oferecer no filtro de
  // proximidade.
  //
  // Isso não significa que o filtro já esteja implementado no
  // Repository.
  //
  // ==========================================================

  double? get maximumRadiusKm {
    switch (this) {
      case MatchDiscoveryMode.compatible:
        return null;

      case MatchDiscoveryMode.nearby:
        return 100.0;

      case MatchDiscoveryMode.global:
        return null;
    }
  }

  // ==========================================================
  // OPÇÕES DE RAIO
  // ==========================================================
  //
  // Utilizadas futuramente no filtro do modo Próximos.
  //
  // ==========================================================

  List<
    double
  >
  get availableRadiusOptionsKm {
    switch (this) {
      case MatchDiscoveryMode.compatible:
        return const [];

      case MatchDiscoveryMode.nearby:
        return const [
          5.0,
          10.0,
          25.0,
          50.0,
          100.0,
        ];

      case MatchDiscoveryMode.global:
        return const [];
    }
  }

  // ==========================================================
  // USA COMPATIBILIDADE PROFISSIONAL
  // ==========================================================
  //
  // compatible:
  //
  // somente compatibilidade profissional.
  //
  // nearby:
  //
  // compatibilidade profissional + localização.
  //
  // global:
  //
  // não exige compatibilidade.
  //
  // ==========================================================

  bool get usesProfessionalCompatibility {
    switch (this) {
      case MatchDiscoveryMode.compatible:
        return true;

      case MatchDiscoveryMode.nearby:
        return true;

      case MatchDiscoveryMode.global:
        return false;
    }
  }

  // ==========================================================
  // EXIGE USUÁRIO ONLINE
  // ==========================================================
  //
  // Atualmente todos os modos trabalham apenas com usuários
  // online.
  //
  // Mantemos esta propriedade porque futuramente algum modo
  // poderá permitir descoberta offline.
  //
  // ==========================================================

  bool get requiresOnlineUser {
    return true;
  }

  // ==========================================================
  // É MODO GLOBAL
  // ==========================================================

  bool get isGlobal {
    return this ==
        MatchDiscoveryMode.global;
  }

  // ==========================================================
  // É MODO PRÓXIMO
  // ==========================================================

  bool get isNearby {
    return this ==
        MatchDiscoveryMode.nearby;
  }

  // ==========================================================
  // É MODO COMPATÍVEL
  // ==========================================================

  bool get isCompatible {
    return this ==
        MatchDiscoveryMode.compatible;
  }

  // ==========================================================
  // FROM KEY
  // ==========================================================
  //
  // Converte valores persistidos para o enum.
  //
  // Valores desconhecidos retornam compatible como fallback.
  //
  // ==========================================================

  static MatchDiscoveryMode fromKey(
    String? value,
  ) {
    switch (value?.trim().toLowerCase()) {
      case 'nearby':
        return MatchDiscoveryMode.nearby;

      case 'global':
        return MatchDiscoveryMode.global;

      case 'compatible':
      default:
        return MatchDiscoveryMode.compatible;
    }
  }

  // ==========================================================
  // TRY FROM KEY
  // ==========================================================
  //
  // Diferente de fromKey(), retorna null quando o valor não é
  // reconhecido.
  //
  // Útil para validação de dados vindos de APIs ou banco.
  //
  // ==========================================================

  static MatchDiscoveryMode? tryFromKey(
    String? value,
  ) {
    switch (value?.trim().toLowerCase()) {
      case 'compatible':
        return MatchDiscoveryMode.compatible;

      case 'nearby':
        return MatchDiscoveryMode.nearby;

      case 'global':
        return MatchDiscoveryMode.global;

      default:
        return null;
    }
  }
}
