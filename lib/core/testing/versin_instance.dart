import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Development profiles. The default application keeps its original keys.
class VersinInstance {
  static const String _configured = String.fromEnvironment(
    'VERSIN_INSTANCE',
    defaultValue: '',
  );

  static String get id {
    if (kIsWeb) return '';
    return _configured;
  }

  static bool get isIsolated => id == 'A' || id == 'B';

  static void initialize() {
    if (!kIsWeb && id.isNotEmpty && !isIsolated) {
      throw StateError('VERSIN_INSTANCE deve ser A, B ou vazio.');
    }
    // Must happen before the first SharedPreferences.getInstance().
    // The default prefix is unchanged for the ordinary application.
    if (isIsolated) {
      SharedPreferences.setPrefix('flutter.versin_${id}.');
    }
  }

  static String secureKey(String key) =>
      isIsolated ? 'versin_test_${id}::$key' : key;
}
