import 'package:flutter_test/flutter_test.dart';
import 'package:versin/modules/login/data/datasources/desktop_oauth_service.dart';

void main() {
  test('PKCE S256 matches the RFC 7636 test vector', () {
    expect(
      DesktopOAuthService.pkceChallenge(
        'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk',
      ),
      'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
    );
  });
}
