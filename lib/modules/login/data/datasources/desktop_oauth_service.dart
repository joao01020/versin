import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fluxo OAuth exclusivo do desktop Linux.
///
/// O código de autorização e o verificador PKCE permanecem em memória.
/// Cada tentativa utiliza uma porta local e um caminho aleatório próprios.
class DesktopOAuthService {
  DesktopOAuthService._();

  static final DesktopOAuthService instance = DesktopOAuthService._();

  Future<
    void
  >?
  _pending;

  static const _timeout = Duration(
    minutes: 5,
  );

  // ============================================================
  // INICIAR LOGIN
  // ============================================================

  Future<
    void
  >
  signIn(
    OAuthProvider provider,
  ) {
    final active = _pending;

    if (active !=
        null) {
      return active;
    }

    final future = _run(
      provider,
    );

    _pending = future;

    return future.whenComplete(
      () {
        if (identical(
          _pending,
          future,
        )) {
          _pending = null;
        }
      },
    );
  }

  // ============================================================
  // PKCE
  // ============================================================

  static String _randomToken() {
    final random = Random.secure();

    return base64UrlEncode(
      List<
        int
      >.generate(
        32,
        (
          _,
        ) => random.nextInt(
          256,
        ),
      ),
    ).replaceAll(
      '=',
      '',
    );
  }

  @visibleForTesting
  static String pkceChallenge(
    String verifier,
  ) {
    return base64UrlEncode(
      sha256
          .convert(
            ascii.encode(
              verifier,
            ),
          )
          .bytes,
    ).replaceAll(
      '=',
      '',
    );
  }

  // ============================================================
  // EXECUTAR OAUTH
  // ============================================================

  Future<
    void
  >
  _run(
    OAuthProvider provider,
  ) async {
    final serverUrl =
        dotenv.env['SUPABASE_URL']?.trim() ??
        '';
    final anonKey =
        dotenv.env['SUPABASE_ANON_KEY']?.trim() ??
        '';

    final base = Uri.tryParse(
      serverUrl,
    );

    if (base ==
            null ||
        base.scheme !=
            'https' ||
        base.host.isEmpty ||
        (base.path.isNotEmpty &&
            base.path !=
                '/') ||
        base.hasQuery ||
        base.hasFragment ||
        anonKey.isEmpty) {
      throw StateError(
        'Configuração pública do Supabase inválida.',
      );
    }

    final auth = Supabase.instance.client.auth;

    final initialUserId = auth.currentUser?.id;

    final verifier = _randomToken();
    final nonce = _randomToken();

    // Cada processo recebe uma porta própria.
    // Isso permite que Versin A e B tenham callbacks independentes.
    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );

    final callback = Uri(
      scheme: 'http',
      host: '127.0.0.1',
      port: server.port,
      path: '/oauth/$nonce',
    );

    final completion =
        Completer<
          Uri
        >();

    StreamSubscription<
      HttpRequest
    >?
    subscription;

    try {
      // ========================================================
      // SERVIDOR LOCAL DE CALLBACK
      // ========================================================

      subscription = server.listen(
        (
          request,
        ) async {
          try {
            final uri = request.uri;

            if (request.method !=
                    'GET' ||
                uri.path !=
                    callback.path ||
                uri.queryParameters.keys.any(
                  (
                    key,
                  ) =>
                      key !=
                          'code' &&
                      key !=
                          'error' &&
                      key !=
                          'error_description',
                )) {
              request.response.statusCode = HttpStatus.notFound;

              await request.response.close();

              return;
            }

            final hasCode =
                uri.queryParameters['code']?.isNotEmpty ==
                true;

            final hasError = uri.queryParameters.containsKey(
              'error',
            );

            if (!hasCode &&
                !hasError) {
              request.response.statusCode = HttpStatus.badRequest;

              await request.response.close();

              return;
            }

            // ==================================================
            // RESPOSTA HTML
            // ==================================================
            //
            // A página apenas informa que o callback foi recebido.
            // O código OAuth não é colocado no HTML.
            //
            // ==================================================

            request.response.headers
              ..contentType = ContentType.html
              ..set(
                'Cache-Control',
                'no-store',
              )
              ..set(
                'X-Content-Type-Options',
                'nosniff',
              )
              ..set(
                'Referrer-Policy',
                'no-referrer',
              )
              ..set(
                'Content-Security-Policy',
                "default-src 'none'; style-src 'unsafe-inline'",
              );

            request.response.write(
              _buildOAuthCallbackPageHtml(
                hasError: hasError,
                providerName: provider.name,
              ),
            );

            await request.response.close();

            if (!completion.isCompleted) {
              completion.complete(
                uri,
              );
            }
          } catch (
            error,
            stackTrace
          ) {
            if (!completion.isCompleted) {
              completion.completeError(
                error,
                stackTrace,
              );
            }
          }
        },
        onError:
            (
              Object error,
              StackTrace stackTrace,
            ) {
              if (!completion.isCompleted) {
                completion.completeError(
                  error,
                  stackTrace,
                );
              }
            },
      );

      // ========================================================
      // URL DE AUTORIZAÇÃO
      // ========================================================

      final authorize = base.replace(
        path: '/auth/v1/authorize',
        queryParameters:
            <
              String,
              String
            >{
              'provider': provider.name,
              'redirect_to': callback.toString(),
              'flow_type': 'pkce',
              'code_challenge': pkceChallenge(
                verifier,
              ),
              'code_challenge_method': 's256',
            },
      );

      await _openFirefox(
        authorize,
      );

      // ========================================================
      // AGUARDAR CALLBACK
      // ========================================================

      final returned = await completion.future.timeout(
        _timeout,
      );

      if (returned.queryParameters.containsKey(
        'error',
      )) {
        throw StateError(
          'Autorização cancelada ou recusada pelo provedor.',
        );
      }

      final code = returned.queryParameters['code'];

      if (code ==
              null ||
          code.isEmpty) {
        throw StateError(
          'O provedor não retornou um código de autorização.',
        );
      }

      // ========================================================
      // TROCAR CÓDIGO POR SESSÃO
      // ========================================================
      //
      // Nunca registrar em logs:
      //
      // - código OAuth;
      // - verificador PKCE;
      // - corpo da resposta;
      // - access token;
      // - refresh token;
      // - URL completa do callback.
      //
      // ========================================================

      final client = HttpClient();

      String refreshToken;

      try {
        final request = await client
            .postUrl(
              base.replace(
                path: '/auth/v1/token',
                queryParameters:
                    <
                      String,
                      String
                    >{
                      'grant_type': 'pkce',
                    },
              ),
            )
            .timeout(
              const Duration(
                seconds: 20,
              ),
            );

        request.followRedirects = false;

        request.headers
          ..contentType = ContentType.json
          ..set(
            'apikey',
            anonKey,
          )
          ..set(
            'Cache-Control',
            'no-store',
          );

        request.write(
          jsonEncode(
            <
              String,
              String
            >{
              'auth_code': code,
              'code_verifier': verifier,
            },
          ),
        );

        final response = await request.close().timeout(
          const Duration(
            seconds: 20,
          ),
        );

        final body = await utf8.decoder
            .bind(
              response,
            )
            .join()
            .timeout(
              const Duration(
                seconds: 20,
              ),
            );

        if (response.statusCode !=
            200) {
          throw StateError(
            'Supabase recusou a troca OAuth '
            '(HTTP ${response.statusCode}).',
          );
        }

        final decoded = jsonDecode(
          body,
        );

        if (decoded
            is! Map<
              String,
              dynamic
            >) {
          throw StateError(
            'Resposta de autenticação inválida.',
          );
        }

        refreshToken =
            decoded['refresh_token']?.toString() ??
            '';

        if (refreshToken.isEmpty) {
          throw StateError(
            'A autenticação não retornou uma sessão.',
          );
        }
      } finally {
        client.close(
          force: true,
        );
      }

      // ========================================================
      // PROTEGER CONTA ATUAL
      // ========================================================

      if (auth.currentUser?.id !=
          initialUserId) {
        throw StateError(
          'A conta mudou durante a autorização. '
          'Tente novamente.',
        );
      }

      // ========================================================
      // RESTAURAR SESSÃO
      // ========================================================

      await auth.setSession(
        refreshToken,
      );

      debugPrint(
        '[VERSIN AUTH] OAuth desktop concluído.',
      );
    } finally {
      await subscription?.cancel();

      await server.close(
        force: true,
      );
    }
  }

  // ============================================================
  // PÁGINA DE CALLBACK
  // ============================================================

  static String _buildOAuthCallbackPageHtml({
    required bool hasError,
    required String providerName,
  }) {
    final title = hasError
        ? 'Autorização não concluída'
        : 'Autorização recebida';

    final subtitle = hasError
        ? 'Não foi possível concluir a autorização. '
              'Volte ao Versin e tente novamente.'
        : 'O Versin recebeu o retorno da sua autorização. '
              'Volte ao aplicativo para continuar.';

    final status = hasError
        ? 'Não autorizado'
        : 'Autorização recebida';

    final providerLabel = switch (providerName.toLowerCase()) {
      'github' => 'GitHub',
      'google' => 'Google',
      _ => 'Sua conta',
    };

    final statusColor = hasError
        ? '#FF8A9A'
        : '#CDA0FF';

    final statusBackground = hasError
        ? 'rgba(255, 95, 109, 0.12)'
        : 'rgba(192, 38, 255, 0.12)';

    final statusBorder = hasError
        ? 'rgba(255, 95, 109, 0.22)'
        : 'rgba(192, 38, 255, 0.22)';

    final statusIcon = hasError
        ? '''
          <path d="M12 9v4m0 4h.01M10.3 3.9 2.6 17.2A2 2 0 0 0 4.3 20h15.4a2 2 0 0 0 1.7-2.8L13.7 3.9a2 2 0 0 0-3.4 0Z"/>
        '''
        : '''
          <path d="m5 12 4 4L19 6"/>
        ''';

    final note = hasError
        ? 'Nenhuma sessão foi confirmada por esta página. '
              'Você pode fechar esta aba e tentar novamente.'
        : 'Esta página não precisa permanecer aberta. '
              'A autenticação continua no aplicativo Versin.';

    return '''
<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="dark">
  <title>Versin • Autenticação</title>

  <style>
    :root {
      color-scheme: dark;

      --bg: #090611;
      --surface: #15101f;
      --surface-light: #1b1527;

      --border: rgba(255,255,255,0.08);

      --text: #f7f3ff;
      --muted: #aaa3b8;
      --subtle: #777084;

      --accent: #c026ff;
      --accent-light: #e879f9;

      --status: $statusColor;
      --status-bg: $statusBackground;
      --status-border: $statusBorder;
    }

    * {
      box-sizing: border-box;
    }

    html {
      min-height: 100%;
      background: var(--bg);
    }

    body {
      min-height: 100vh;
      margin: 0;
      padding: 32px 20px;

      display: flex;
      align-items: center;
      justify-content: center;

      font-family:
        Inter,
        system-ui,
        -apple-system,
        BlinkMacSystemFont,
        "Segoe UI",
        sans-serif;

      color: var(--text);

      background:
        radial-gradient(
          circle at 50% 0%,
          rgba(192,38,255,0.12),
          transparent 38%
        ),
        radial-gradient(
          circle at 100% 100%,
          rgba(92,38,164,0.08),
          transparent 32%
        ),
        var(--bg);
    }

    .shell {
      width: 100%;
      max-width: 460px;
    }

    .brand {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 14px;

      margin-bottom: 30px;
    }

    .brand-mark {
      width: 72px;
      height: 72px;

      display: flex;
      align-items: center;
      justify-content: center;

      border-radius: 24px;

      background: rgba(192,38,255,0.10);
      border: 1px solid rgba(192,38,255,0.28);

      color: var(--accent-light);

      box-shadow:
        0 12px 36px rgba(0,0,0,0.24),
        inset 0 1px 0 rgba(255,255,255,0.04);
    }

    .brand-mark svg {
      width: 38px;
      height: 38px;
    }

    .brand-name {
      font-size: 29px;
      font-weight: 800;
      letter-spacing: 0.19em;
      line-height: 1;
    }

    .brand-subtitle {
      margin-top: -6px;

      color: var(--subtle);

      font-size: 11px;
      font-weight: 600;
      letter-spacing: 0.16em;
      text-transform: uppercase;
    }

    .card {
      padding: 30px;

      border: 1px solid var(--border);
      border-radius: 26px;

      background:
        linear-gradient(
          145deg,
          rgba(255,255,255,0.025),
          transparent 45%
        ),
        var(--surface);

      box-shadow: 0 24px 70px rgba(0,0,0,0.28);
    }

    .status {
      display: inline-flex;
      align-items: center;
      gap: 8px;

      padding: 8px 12px;

      border-radius: 999px;

      background: var(--status-bg);
      border: 1px solid var(--status-border);

      color: var(--status);

      font-size: 12px;
      font-weight: 700;
      letter-spacing: 0.01em;
    }

    .status-dot {
      width: 6px;
      height: 6px;

      border-radius: 50%;
      background: currentColor;
    }

    .result-icon {
      width: 64px;
      height: 64px;

      display: flex;
      align-items: center;
      justify-content: center;

      margin-top: 25px;
      margin-bottom: 20px;

      border-radius: 21px;

      background: var(--status-bg);
      border: 1px solid var(--status-border);

      color: var(--status);
    }

    .result-icon svg {
      width: 29px;
      height: 29px;
    }

    h1 {
      margin: 0 0 12px;

      font-size: 28px;
      font-weight: 750;
      letter-spacing: -0.035em;
      line-height: 1.15;
    }

    .description {
      margin: 0;

      color: var(--muted);

      font-size: 14px;
      line-height: 1.7;
    }

    .provider {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;

      margin-top: 25px;
      padding: 14px 16px;

      border-radius: 15px;
      border: 1px solid rgba(255,255,255,0.055);

      background: rgba(255,255,255,0.025);
    }

    .provider-label {
      color: var(--subtle);

      font-size: 12px;
      font-weight: 500;
    }

    .provider-value {
      color: var(--text);

      font-size: 13px;
      font-weight: 700;
    }

    .divider {
      height: 1px;

      margin: 25px 0;

      background: rgba(255,255,255,0.07);
    }

    .instruction {
      display: flex;
      align-items: flex-start;
      gap: 12px;
    }

    .instruction-icon {
      width: 34px;
      height: 34px;

      flex-shrink: 0;

      display: flex;
      align-items: center;
      justify-content: center;

      border-radius: 11px;

      background: rgba(192,38,255,0.10);

      color: var(--accent-light);
    }

    .instruction-icon svg {
      width: 17px;
      height: 17px;
    }

    .instruction strong {
      display: block;

      margin-bottom: 4px;

      font-size: 13px;
      font-weight: 700;
    }

    .instruction p {
      margin: 0;

      color: var(--muted);

      font-size: 12px;
      line-height: 1.65;
    }

.note {
      margin-top: 17px;

      color: var(--subtle);

      font-size: 11px;
      line-height: 1.7;
      text-align: center;
    }

    .footer {
      margin-top: 24px;

      color: rgba(255,255,255,0.25);

      font-size: 10px;
      font-weight: 600;
      letter-spacing: 0.12em;
      text-align: center;
      text-transform: uppercase;
    }

    @media (max-width: 480px) {
      body {
        padding: 22px 16px;
      }

      .card {
        padding: 23px;
        border-radius: 22px;
      }

      h1 {
        font-size: 25px;
      }
    }
  </style>
</head>

<body>
  <main class="shell">

    <header class="brand">
      <div class="brand-mark" aria-hidden="true">
        <svg
          viewBox="0 0 64 64"
          fill="none"
          stroke="currentColor"
          stroke-width="5"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <path
            d="M32 32
               C24 20, 18 17, 12 17
               C5 17, 2 23, 2 32
               C2 41, 5 47, 12 47
               C20 47, 25 39, 32 32
               C39 25, 44 17, 52 17
               C59 17, 62 23, 62 32
               C62 41, 59 47, 52 47
               C46 47, 40 44, 32 32"
          />
        </svg>
      </div>

      <div class="brand-name">VERSIN</div>
      <div class="brand-subtitle">Ecossistema Criativo</div>
    </header>

    <section class="card">
      <div class="status">
        <span class="status-dot"></span>
        $status
      </div>

      <div class="result-icon" aria-hidden="true">
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          $statusIcon
        </svg>
      </div>

      <h1>$title</h1>

      <p class="description">
        $subtitle
      </p>

      <div class="provider">
        <span class="provider-label">Método de autenticação</span>
        <span class="provider-value">$providerLabel</span>
      </div>

      <div class="divider"></div>

      <div class="instruction">
        <div class="instruction-icon" aria-hidden="true">
          <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <rect x="3" y="4" width="18" height="16" rx="2"/>
            <path d="M3 9h18"/>
            <path d="m10 13 3 3 3-3"/>
          </svg>
        </div>

        <div>
          <strong>Continue no aplicativo</strong>
          <p>
            Volte à janela do Versin para acessar sua conta.
            Esta aba pode ser fechada.
          </p>
        </div>
      </div>

<p class="note">
        $note
      </p>
    </section>

    <footer class="footer">
      Versin · Autenticação Desktop
    </footer>

  </main>
</body>
</html>
''';
  }

  // ============================================================
  // ABRIR FIREFOX
  // ============================================================

  static Future<
    void
  >
  _openFirefox(
    Uri url,
  ) async {
    // Não utiliza shell nem a associação ambígua do navegador
    // padrão do sistema.

    for (final executable
        in <
          String
        >[
          'firefox-esr',
          'firefox',
        ]) {
      try {
        await Process.start(
          executable,
          <
            String
          >[
            url.toString(),
          ],
          mode: ProcessStartMode.detached,
        );

        return;
      } on ProcessException {
        // Tenta o próximo executável disponível.
      }
    }

    throw StateError(
      'Firefox não encontrado. '
      'Instale Firefox ESR ou Firefox para continuar.',
    );
  }
}
