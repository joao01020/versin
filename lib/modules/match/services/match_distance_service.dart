import 'dart:math' as math;

// ============================================================
// MATCH DISTANCE SERVICE
// ============================================================
//
// Responsável exclusivamente por cálculos de distância usados
// pelo modo:
//
// PRÓXIMOS
//
// Utiliza a fórmula de Haversine para calcular a distância
// aproximada entre duas coordenadas geográficas.
//
// Este service NÃO:
//
// - acessa GPS;
// - solicita permissão;
// - acessa Supabase;
// - salva localização;
// - controla UI;
// - conhece MatchController;
// - conhece MatchRepository.
//
// Fluxo futuro:
//
// GPS
//   ↓
// latitude / longitude do usuário
//   ↓
// MatchRepository
//   ↓
// MatchDistanceService
//   ↓
// distância em quilômetros
//
// ============================================================

class MatchDistanceService {
  // ============================================================
  // RAIO MÉDIO DA TERRA
  // ============================================================

  static const double _earthRadiusKm = 6371.0088;

  // ============================================================
  // CONSTRUTOR
  // ============================================================
  //
  // Não existem estados internos.
  //
  // ============================================================

  const MatchDistanceService();

  // ============================================================
  // CALCULAR DISTÂNCIA
  // ============================================================
  //
  // Retorna a distância em quilômetros.
  //
  // Exemplo:
  //
  // final distance = MatchDistanceService.calculateKm(
  //   latitudeA: -23.532,
  //   longitudeA: -46.791,
  //   latitudeB: -23.550,
  //   longitudeB: -46.760,
  // );
  //
  // ============================================================

  static double calculateKm({
    required double latitudeA,
    required double longitudeA,
    required double latitudeB,
    required double longitudeB,
  }) {
    // ==========================================================
    // VALIDAR COORDENADAS
    // ==========================================================

    if (!isValidCoordinate(
      latitude: latitudeA,
      longitude: longitudeA,
    )) {
      throw ArgumentError(
        'A coordenada A é inválida.',
      );
    }

    if (!isValidCoordinate(
      latitude: latitudeB,
      longitude: longitudeB,
    )) {
      throw ArgumentError(
        'A coordenada B é inválida.',
      );
    }

    // ==========================================================
    // MESMA LOCALIZAÇÃO
    // ==========================================================

    if (latitudeA ==
            latitudeB &&
        longitudeA ==
            longitudeB) {
      return 0;
    }

    // ==========================================================
    // CONVERTER PARA RADIANOS
    // ==========================================================

    final latitudeARadians = _degreesToRadians(
      latitudeA,
    );

    final latitudeBRadians = _degreesToRadians(
      latitudeB,
    );

    final latitudeDifference = _degreesToRadians(
      latitudeB -
          latitudeA,
    );

    final longitudeDifference = _degreesToRadians(
      longitudeB -
          longitudeA,
    );

    // ==========================================================
    // HAVERSINE
    // ==========================================================

    final latitudeSin = math.sin(
      latitudeDifference /
          2,
    );

    final longitudeSin = math.sin(
      longitudeDifference /
          2,
    );

    final haversine =
        latitudeSin *
            latitudeSin +
        math.cos(
              latitudeARadians,
            ) *
            math.cos(
              latitudeBRadians,
            ) *
            longitudeSin *
            longitudeSin;

    // ==========================================================
    // PROTEÇÃO NUMÉRICA
    // ==========================================================
    //
    // Por arredondamento de ponto flutuante, o resultado pode
    // eventualmente sair alguns decimais de 0..1.
    //
    // ==========================================================

    final normalizedHaversine = haversine.clamp(
      0.0,
      1.0,
    );

    final centralAngle =
        2 *
        math.atan2(
          math.sqrt(
            normalizedHaversine,
          ),
          math.sqrt(
            1 -
                normalizedHaversine,
          ),
        );

    // ==========================================================
    // DISTÂNCIA
    // ==========================================================

    return _earthRadiusKm *
        centralAngle;
  }

  // ============================================================
  // CALCULAR DISTÂNCIA OU NULL
  // ============================================================
  //
  // Versão segura para dados vindos do banco.
  //
  // Diferente de calculateKm(), não lança erro quando alguma
  // coordenada é inválida.
  //
  // ============================================================

  static double? tryCalculateKm({
    required double? latitudeA,
    required double? longitudeA,
    required double? latitudeB,
    required double? longitudeB,
  }) {
    if (latitudeA ==
            null ||
        longitudeA ==
            null ||
        latitudeB ==
            null ||
        longitudeB ==
            null) {
      return null;
    }

    if (!isValidCoordinate(
          latitude: latitudeA,
          longitude: longitudeA,
        ) ||
        !isValidCoordinate(
          latitude: latitudeB,
          longitude: longitudeB,
        )) {
      return null;
    }

    return calculateKm(
      latitudeA: latitudeA,
      longitudeA: longitudeA,
      latitudeB: latitudeB,
      longitudeB: longitudeB,
    );
  }

  // ============================================================
  // ESTÁ DENTRO DO RAIO
  // ============================================================

  static bool isWithinRadius({
    required double distanceKm,
    required double radiusKm,
  }) {
    if (!distanceKm.isFinite ||
        !radiusKm.isFinite ||
        distanceKm <
            0 ||
        radiusKm <
            0) {
      return false;
    }

    return distanceKm <=
        radiusKm;
  }

  // ============================================================
  // CALCULAR E VERIFICAR RAIO
  // ============================================================
  //
  // Útil diretamente no Repository.
  //
  // ============================================================

  static bool isLocationWithinRadius({
    required double? currentLatitude,
    required double? currentLongitude,
    required double? candidateLatitude,
    required double? candidateLongitude,
    required double radiusKm,
  }) {
    final distance = tryCalculateKm(
      latitudeA: currentLatitude,
      longitudeA: currentLongitude,
      latitudeB: candidateLatitude,
      longitudeB: candidateLongitude,
    );

    if (distance ==
        null) {
      return false;
    }

    return isWithinRadius(
      distanceKm: distance,
      radiusKm: radiusKm,
    );
  }

  // ============================================================
  // VALIDAR COORDENADA
  // ============================================================

  static bool isValidCoordinate({
    required double latitude,
    required double longitude,
  }) {
    if (!latitude.isFinite ||
        !longitude.isFinite) {
      return false;
    }

    if (latitude <
            -90 ||
        latitude >
            90) {
      return false;
    }

    if (longitude <
            -180 ||
        longitude >
            180) {
      return false;
    }

    return true;
  }

  // ============================================================
  // FORMATAR DISTÂNCIA
  // ============================================================
  //
  // Exemplos:
  //
  // 0.4 km
  //      ↓
  // 400 m
  //
  // 3.2 km
  //      ↓
  // 3,2 km
  //
  // 24.7 km
  //      ↓
  // 25 km
  //
  // ============================================================

  static String formatDistance(
    double distanceKm,
  ) {
    if (!distanceKm.isFinite ||
        distanceKm <
            0) {
      return '';
    }

    // ==========================================================
    // MENOS DE 1 KM
    // ==========================================================

    if (distanceKm <
        1) {
      final meters =
          (distanceKm *
                  1000)
              .round();

      return '$meters m';
    }

    // ==========================================================
    // MENOS DE 10 KM
    // ==========================================================

    if (distanceKm <
        10) {
      return '${distanceKm.toStringAsFixed(1).replaceAll('.', ',')} km';
    }

    // ==========================================================
    // 10 KM OU MAIS
    // ==========================================================

    return '${distanceKm.round()} km';
  }

  // ============================================================
  // CONVERTER GRAUS → RADIANOS
  // ============================================================

  static double _degreesToRadians(
    double degrees,
  ) {
    return degrees *
        math.pi /
        180;
  }
}
