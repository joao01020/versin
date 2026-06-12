// EN: Pure Dart Entity - No external package imports needed here
// PT: Entidade Pura em Dart - Nenhuma importação de pacote externo é necessária aqui

enum UserRole {
  artist,
  beatmaker,
}

enum ConnectionType {
  chat,
  video,
  proximity,
}

class MatchUserEntity {
  final String id;
  final String name;
  final UserRole role;
  final List<
    String
  >
  tags;
  final String bio;
  final String showcaseMediaUrl; // EN: Showcase sample URL | PT: URL do trabalho em destaque na vitrine
  final String showcaseDescription; // EN: Used by AI algorithm | PT: Usado pelo algoritmo da IA
  final double distanceKm;
  final bool isOnline;

  // EN: Enhanced fields supporting the 20-min micro-session & protocol contract pipeline
  // PT: Campos aprimorados suportando a micro-sessão de 20 minutos e o pipeline de contrato do protocolo
  final ConnectionType preferredConnection; // EN: Defines if user is available for chat, video or proximity | PT: Define se está disponível para chat, vídeo ou proximidade
  final DateTime? sessionStartedAt; // EN: Timestamp to validate the strict 20-minute window | PT: Timestamp para validar a janela estrita de 20 minutos
  final String? provisionalHash; // EN: SHA/MD5 temporary workspace lock generated upon intent agreement | PT: Trava temporária do workspace gerada no acordo de intenção

  const MatchUserEntity({
    required this.id,
    required this.name,
    required this.role,
    required this.tags,
    required this.bio,
    required this.showcaseMediaUrl,
    required this.showcaseDescription,
    required this.distanceKm,
    required this.isOnline,
    this.preferredConnection = ConnectionType.proximity,
    this.sessionStartedAt,
    this.provisionalHash,
  });

  // EN: CopyWith method to safely update immutable states inside the controller pipeline
  // PT: Método copyWith para atualizar estados imutáveis com segurança dentro do pipeline do controller
  MatchUserEntity copyWith({
    String? id,
    String? name,
    UserRole? role,
    List<
      String
    >?
    tags,
    String? bio,
    String? showcaseMediaUrl,
    String? showcaseDescription,
    double? distanceKm,
    bool? isOnline,
    ConnectionType? preferredConnection,
    DateTime? sessionStartedAt,
    String? provisionalHash,
  }) {
    return MatchUserEntity(
      id:
          id ??
          this.id,
      name:
          name ??
          this.name,
      role:
          role ??
          this.role,
      tags:
          tags ??
          this.tags,
      bio:
          bio ??
          this.bio,
      showcaseMediaUrl:
          showcaseMediaUrl ??
          this.showcaseMediaUrl,
      showcaseDescription:
          showcaseDescription ??
          this.showcaseDescription,
      distanceKm:
          distanceKm ??
          this.distanceKm,
      isOnline:
          isOnline ??
          this.isOnline,
      preferredConnection:
          preferredConnection ??
          this.preferredConnection,
      sessionStartedAt:
          sessionStartedAt ??
          this.sessionStartedAt,
      provisionalHash:
          provisionalHash ??
          this.provisionalHash,
    );
  }
}
