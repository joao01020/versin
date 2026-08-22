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
// - MatchSessionService;
// - filtros do Match;
// - widgets de seleção do modo.
//
// IMPORTANTE:
//
// A regra de busca NÃO fica neste arquivo.
//
// Este arquivo define:
//
// - os modos disponíveis;
// - propriedades auxiliares;
// - configurações padrão;
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
  // - estão realmente online;
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
  // - estão realmente online;
  // - não são o próprio usuário;
  // - possuem função compatível com lookingForRoles;
  // - possuem localização habilitada;
  // - possuem latitude e longitude válidas.
  //
  // Ordenação:
  //
  // 1. distância;
  // 2. compatibilidade profissional.
  //
  // ==========================================================
  nearby,

  // ==========================================================
  // DISPONÍVEIS AGORA
  // ==========================================================
  //
  // INTERNAMENTE:
  //
  // O valor continua chamado "global" temporariamente.
  //
  // Isso evita quebrar:
  //
  // - persistência existente;
  // - controllers;
  // - repository;
  // - analytics;
  // - preferências já salvas.
  //
  // VISUALMENTE:
  //
  // global = DISPONÍVEIS AGORA
  //
  // Este modo mostra somente usuários que:
  //
  // - estão realmente online;
  // - possuem heartbeat recente;
  // - ativaram available_now;
  // - available_until ainda não expirou;
  // - possuem função compatível com o que o usuário procura.
  //
  // Não utiliza localização.
  //
  // Exemplo:
  //
  // usuário procura:
  //
  //   Beatmaker
  //
  // candidato:
  //
  //   roles contém Beatmaker
  //   online real
  //   disponível agora
  //
  // resultado:
  //
  //   aparece em Disponíveis agora.
  //
  // ==========================================================
  global,
}

// ============================================================
// MATCH DISCOVERY MODE EXTENSION
// ============================================================

extension MatchDiscoveryModeExtension on MatchDiscoveryMode {
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
        return 'DISPONÍVEIS AGORA';
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
        return 'Profissionais que podem se conectar com você agora.';
    }
  }

  // ==========================================================
  // DESCRIÇÃO CURTA
  // ==========================================================

  String get shortDescription {
    switch (this) {
      case MatchDiscoveryMode.compatible:
        return 'Compatíveis com você';

      case MatchDiscoveryMode.nearby:
        return 'Próximos de você';

      case MatchDiscoveryMode.global:
        return 'Disponíveis agora';
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
        return 'Disponíveis agora';
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
        return 'Ninguém com a função que você procura está disponível agora.';
    }
  }

  // ==========================================================
  // KEY
  // ==========================================================
  //
  // IMPORTANTE:
  //
  // Mantemos "global" por compatibilidade com dados e
  // preferências existentes.
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
  // Também mantido temporariamente para não quebrar eventos
  // existentes.
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

  bool get requiresLocationConsent {
    return this == MatchDiscoveryMode.nearby;
  }

  // ==========================================================
  // PERMITE FILTRO DE DISTÂNCIA
  // ==========================================================

  bool get supportsDistanceFilter {
    return this == MatchDiscoveryMode.nearby;
  }

  // ==========================================================
  // RAIO PADRÃO
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
  // DISTÂNCIA MÁXIMA
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

  List<double> get availableRadiusOptionsKm {
    switch (this) {
      case MatchDiscoveryMode.compatible:
        return const [];

      case MatchDiscoveryMode.nearby:
        return const [5.0, 10.0, 25.0, 50.0, 100.0];

      case MatchDiscoveryMode.global:
        return const [];
    }
  }

  // ==========================================================
  // USA COMPATIBILIDADE PROFISSIONAL
  // ==========================================================
  //
  // IMPORTANTE:
  //
  // Disponíveis agora também exige compatibilidade de função.
  //
  // Ou seja:
  //
  // lookingForRoles do usuário
  //
  // deve cruzar com
  //
  // roles do candidato.
  //
  // ==========================================================

  bool get usesProfessionalCompatibility {
    switch (this) {
      case MatchDiscoveryMode.compatible:
        return true;

      case MatchDiscoveryMode.nearby:
        return true;

      case MatchDiscoveryMode.global:
        return true;
    }
  }

  // ==========================================================
  // EXIGE USUÁRIO ONLINE
  // ==========================================================

  bool get requiresOnlineUser {
    return true;
  }

  // ==========================================================
  // EXIGE DISPONIBILIDADE IMEDIATA
  // ==========================================================
  //
  // Somente o antigo modo global.
  //
  // ==========================================================

  bool get requiresImmediateAvailability {
    return this == MatchDiscoveryMode.global;
  }

  // ==========================================================
  // É DISPONÍVEIS AGORA
  // ==========================================================

  bool get isAvailableNow {
    return this == MatchDiscoveryMode.global;
  }

  // ==========================================================
  // É MODO GLOBAL
  // ==========================================================
  //
  // Mantido temporariamente por compatibilidade.
  //
  // Código novo deve preferir:
  //
  // isAvailableNow
  //
  // ==========================================================

  bool get isGlobal {
    return this == MatchDiscoveryMode.global;
  }

  // ==========================================================
  // É MODO PRÓXIMO
  // ==========================================================

  bool get isNearby {
    return this == MatchDiscoveryMode.nearby;
  }

  // ==========================================================
  // É MODO COMPATÍVEL
  // ==========================================================

  bool get isCompatible {
    return this == MatchDiscoveryMode.compatible;
  }

  // ==========================================================
  // FROM KEY
  // ==========================================================
  //
  // Aceitamos:
  //
  // global
  //
  // e também:
  //
  // available_now
  //
  // Isso já deixa o código preparado para uma futura migração.
  //
  // ==========================================================

  static MatchDiscoveryMode fromKey(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'nearby':
        return MatchDiscoveryMode.nearby;

      case 'available_now':
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

  static MatchDiscoveryMode? tryFromKey(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'compatible':
        return MatchDiscoveryMode.compatible;

      case 'nearby':
        return MatchDiscoveryMode.nearby;

      case 'available_now':
      case 'global':
        return MatchDiscoveryMode.global;

      default:
        return null;
    }
  }
}
