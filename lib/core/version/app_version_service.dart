import 'package:package_info_plus/package_info_plus.dart';

/// Fonte única dos metadados da versão instalada.
class AppVersionService {
  AppVersionService._();

  static final AppVersionService instance = AppVersionService._();

  Future<PackageInfo>? _pending;

  Future<PackageInfo> load() {
    return _pending ??= _read();
  }

  Future<PackageInfo> _read() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (_) {
      _pending = null;
      rethrow;
    }
  }

  Future<String> get displayVersion async {
    final info = await load();
    return 'Versin Genesis v${info.version}';
  }

  void invalidate() {
    _pending = null;
  }
}
