// ============================================================
// NETWORK IMAGE URL HELPER
// ============================================================
//
// Centraliza a validação de URLs usadas em:
//
// - NetworkImage;
// - Image.network;
// - DecorationImage;
// - CircleAvatar.backgroundImage.
//
// Evita erros causados por valores inválidos como:
//
// - NULL;
// - null;
// - undefined;
// - none;
// - string vazia;
// - URL sem http/https;
// - URL sem host.
//
// ============================================================

class NetworkImageUrlHelper {
  NetworkImageUrlHelper._();

  // ============================================================
  // INVALID VALUES
  // ============================================================

  static const Set<
    String
  >
  _invalidValues = {
    'null',
    'none',
    'undefined',
    'nil',
    'n/a',
    'na',
    'empty',
    '-',
  };

  // ============================================================
  // NORMALIZE
  // ============================================================

  static String normalize(
    String? value,
  ) {
    return value?.trim() ??
        '';
  }

  // ============================================================
  // IS EMPTY OR INVALID TEXT
  // ============================================================

  static bool _isInvalidText(
    String value,
  ) {
    if (value.isEmpty) {
      return true;
    }

    return _invalidValues.contains(
      value.toLowerCase(),
    );
  }

  // ============================================================
  // IS VALID
  // ============================================================

  static bool isValid(
    String? value,
  ) {
    final normalized = normalize(
      value,
    );

    if (_isInvalidText(
      normalized,
    )) {
      return false;
    }

    final uri = Uri.tryParse(
      normalized,
    );

    if (uri ==
        null) {
      return false;
    }

    if (uri.scheme !=
            'http' &&
        uri.scheme !=
            'https') {
      return false;
    }

    if (uri.host.trim().isEmpty) {
      return false;
    }

    return true;
  }

  // ============================================================
  // VALID URL OR NULL
  // ============================================================

  static String? validUrlOrNull(
    String? value,
  ) {
    final normalized = normalize(
      value,
    );

    if (!isValid(
      normalized,
    )) {
      return null;
    }

    return normalized;
  }

  // ============================================================
  // VALID URL OR FALLBACK
  // ============================================================

  static String validUrlOrFallback(
    String? value,
    String fallback,
  ) {
    return validUrlOrNull(
          value,
        ) ??
        fallback;
  }

  // ============================================================
  // HAS VALID URL
  // ============================================================

  static bool hasValidUrl(
    String? value,
  ) {
    return validUrlOrNull(
          value,
        ) !=
        null;
  }
}
