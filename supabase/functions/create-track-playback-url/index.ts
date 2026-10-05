import { AwsClient } from 'aws4fetch';

// ============================================================
// CREATE TRACK PLAYBACK URL
// ============================================================
//
// Fluxo:
//
// Flutter
//    ↓
// trackId
//    ↓
// create-track-playback-url
//    ↓
// identifica usuário pelo JWT
//    ↓
// busca public.profile_tracks
//    ↓
// valida demo
//    ↓
// lê storage_path
//    ↓
// gera presigned GET
//    ↓
// Cloudflare R2
//
// NÃO:
//
// - recebe fileName;
// - recebe bytes;
// - faz upload;
// - altera profile_tracks;
// - salva playbackUrl;
// - expõe secrets.
//
// ============================================================

// ============================================================
// CONFIGURAÇÃO
// ============================================================

const PLAYBACK_URL_EXPIRES_SECONDS = 600;

const DATABASE_TIMEOUT_MS = 8000;

// ============================================================
// CORS
// ============================================================

const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',

  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',

  'Access-Control-Allow-Methods':
    'POST, OPTIONS',
};

// ============================================================
// TYPES
// ============================================================

interface PlaybackRequestBody {
  trackId?: unknown;
}

interface JwtPayload {
  sub?: unknown;
}

interface ProfileTrackRow {
  id: string;

  userId: string;

  title: string;

  storagePath: string;

  isActive: boolean;

  audienceRoles: string[];
}

// ============================================================
// MAIN
// ============================================================

Deno.serve(
  async (
    request: Request,
  ): Promise<Response> => {
    const startedAt =
      Date.now();

    console.log(
      '[PLAYBACK] Início.',
    );

    // ==========================================================
    // CORS PREFLIGHT
    // ==========================================================

    if (
      request.method ===
      'OPTIONS'
    ) {
      return new Response(
        'ok',
        {
          status: 200,

          headers:
            corsHeaders,
        },
      );
    }

    // ==========================================================
    // METHOD
    // ==========================================================

    if (
      request.method !==
      'POST'
    ) {
      return jsonResponse(
        {
          error:
            'Método não permitido.',
        },
        405,
      );
    }

    try {
      // ========================================================
      // AUTHORIZATION
      // ========================================================

      console.log(
        '[PLAYBACK] Lendo Authorization.',
      );

      const authorization =
        request.headers
          .get(
            'Authorization',
          )
          ?.trim() ??
        '';

      if (
        authorization.length ===
        0
      ) {
        return jsonResponse(
          {
            error:
              'Usuário não autenticado.',
          },
          401,
        );
      }

      // ========================================================
      // ACCESS TOKEN
      // ========================================================

      const accessToken =
        getBearerToken(
          authorization,
        );

      if (
        accessToken.length ===
        0
      ) {
        return jsonResponse(
          {
            error:
              'Token inválido.',
          },
          401,
        );
      }

      // ========================================================
      // USER ID
      // ========================================================

      const currentUserId =
        getUserIdFromJwt(
          accessToken,
        );

      if (
        currentUserId.length ===
        0
      ) {
        return jsonResponse(
          {
            error:
              'Não foi possível identificar o usuário.',
          },
          401,
        );
      }

      console.log(
        '[PLAYBACK] Usuário identificado.',
      );

      // ========================================================
      // BODY
      // ========================================================

      const body =
        await readJsonBody(
          request,
        );

      const trackId =
        readString(
          body.trackId,
        );

      if (
        trackId.length ===
        0
      ) {
        return jsonResponse(
          {
            error:
              'trackId é obrigatório.',
          },
          400,
        );
      }

      console.log(
        '[PLAYBACK] Track ID recebido.',
      );

      // ========================================================
      // SUPABASE CONFIG
      // ========================================================

      const supabaseUrl =
        requiredEnv(
          'SUPABASE_URL',
        );

      const serviceRoleKey =
        requiredEnv(
          'SUPABASE_SERVICE_ROLE_KEY',
        );

      // ========================================================
      // TRACK
      // ========================================================

      const track =
        await fetchTrack({
          supabaseUrl:
            supabaseUrl,

          serviceRoleKey:
            serviceRoleKey,

          trackId:
            trackId,
        });

      if (
        track ===
        null
      ) {
        return jsonResponse(
          {
            error:
              'Demo não encontrada.',
          },
          404,
        );
      }

      console.log(
        '[PLAYBACK] Track encontrada.',
      );

      // ========================================================
      // ACTIVE
      // ========================================================

      if (
        !track.isActive
      ) {
        return jsonResponse(
          {
            error:
              'Esta demo está inativa.',
          },
          403,
        );
      }

      // ========================================================
      // STORAGE PATH
      // ========================================================

      const objectKey =
        track.storagePath
          .trim();

      if (
        objectKey.length ===
        0
      ) {
        return jsonResponse(
          {
            error:
              'Arquivo da demo não encontrado.',
          },
          404,
        );
      }

      // ========================================================
      // OWNER
      // ========================================================

      const isOwner =
        track.userId ===
        currentUserId;

      if (
        isOwner
      ) {
        console.log(
          '[PLAYBACK] Reprodução pelo proprietário.',
        );
      } else {
        console.log(
          '[PLAYBACK] Reprodução de demo ativa.',
        );
      }

      // ========================================================
      // AUDIENCE
      // ========================================================
      //
      // Por enquanto NÃO bloqueamos por audience_roles.
      //
      // Primeiro estamos validando:
      //
      // - upload;
      // - banco;
      // - playback;
      // - R2.
      //
      // Depois adicionamos a regra completa usando as roles reais
      // do módulo Match.
      //
      // ========================================================

      console.log(
        '[PLAYBACK] Audience roles:',
        track.audienceRoles,
      );

      // ========================================================
      // R2 CONFIG
      // ========================================================

      const accountId =
        requiredEnv(
          'R2_ACCOUNT_ID',
        );

      const accessKeyId =
        requiredEnv(
          'R2_ACCESS_KEY_ID',
        );

      const secretAccessKey =
        requiredEnv(
          'R2_SECRET_ACCESS_KEY',
        );

      const bucket =
        requiredEnv(
          'R2_BUCKET',
        );

      // ========================================================
      // AWS CLIENT
      // ========================================================

      const aws =
        new AwsClient({
          service:
            's3',

          region:
            'auto',

          accessKeyId:
            accessKeyId,

          secretAccessKey:
            secretAccessKey,
        });

      // ========================================================
      // OBJECT URL
      // ========================================================

      const encodedObjectKey =
        encodeObjectKey(
          objectKey,
        );

      const objectUrl =
        `https://${accountId}.r2.cloudflarestorage.com/` +
        `${encodeURIComponent(bucket)}/` +
        encodedObjectKey;

      const signUrl =
        new URL(
          objectUrl,
        );

      // ========================================================
      // EXPIRAÇÃO
      // ========================================================

      signUrl.searchParams.set(
        'X-Amz-Expires',
        PLAYBACK_URL_EXPIRES_SECONDS
          .toString(),
      );

      // ========================================================
      // PRESIGNED GET
      // ========================================================

      console.log(
        '[PLAYBACK] Gerando presigned GET.',
      );

      const unsignedRequest =
        new Request(
          signUrl.toString(),
          {
            method:
              'GET',
          },
        );

      const signedRequest =
        await aws.sign(
          unsignedRequest,
          {
            aws: {
              signQuery:
                true,
            },
          },
        );

      const playbackUrl =
        signedRequest.url;

      if (
        playbackUrl.length ===
        0
      ) {
        throw new Error(
          'URL de reprodução vazia.',
        );
      }

      // ========================================================
      // SUCCESS
      // ========================================================

      const elapsed =
        Date.now() -
        startedAt;

      console.log(
        `[PLAYBACK] URL criada em ${elapsed} ms.`,
      );

      return jsonResponse(
        {
          playbackUrl:
            playbackUrl,

          trackId:
            track.id,

          expiresIn:
            PLAYBACK_URL_EXPIRES_SECONDS,
        },
        200,
      );
    } catch (
      error
    ) {
      // ========================================================
      // ERROR
      // ========================================================

      const elapsed =
        Date.now() -
        startedAt;

      console.error(
        `[PLAYBACK] Erro após ${elapsed} ms:`,
        safeErrorMessage(
          error,
        ),
      );

      return jsonResponse(
        {
          error:
            'Não foi possível gerar a URL de reprodução.',
        },
        500,
      );
    }
  },
);

// ============================================================
// FETCH TRACK
// ============================================================

async function fetchTrack({
  supabaseUrl,
  serviceRoleKey,
  trackId,
}: {
  supabaseUrl: string;

  serviceRoleKey: string;

  trackId: string;
}): Promise<ProfileTrackRow | null> {
  const url =
    new URL(
      `${supabaseUrl}/rest/v1/profile_tracks`,
    );

  // ==========================================================
  // SELECT
  // ==========================================================

  url.searchParams.set(
    'select',
    [
      'id',
      'user_id',
      'title',
      'storage_path',
      'is_active',
      'audience_roles',
    ].join(
      ',',
    ),
  );

  // ==========================================================
  // FILTER
  // ==========================================================

  url.searchParams.set(
    'id',
    `eq.${trackId}`,
  );

  url.searchParams.set(
    'limit',
    '1',
  );

  console.log(
    '[PLAYBACK] Consultando profile_tracks.',
  );

  // ==========================================================
  // REQUEST
  // ==========================================================

  const response =
    await fetchWithTimeout(
      url.toString(),
      {
        method:
          'GET',

        headers: {
          'apikey':
            serviceRoleKey,

          'Authorization':
            `Bearer ${serviceRoleKey}`,

          'Accept':
            'application/json',
        },
      },
    );

  // ==========================================================
  // RESPONSE ERROR
  // ==========================================================

  if (
    !response.ok
  ) {
    const responseBody =
      await safeReadText(
        response,
      );

    throw new Error(
      `Erro ao buscar demo. HTTP ${response.status}. ${responseBody}`,
    );
  }

  // ==========================================================
  // JSON
  // ==========================================================

  const data: unknown =
    await response.json();

  if (
    !Array.isArray(
      data,
    ) ||
    data.length ===
    0
  ) {
    return null;
  }

  const first =
    data[0];

  if (
    first ===
      null ||
    typeof first !==
      'object' ||
    Array.isArray(
      first,
    )
  ) {
    return null;
  }

  const row =
    first as Record<
      string,
      unknown
    >;

  // ==========================================================
  // MODEL
  // ==========================================================

  return {
    id:
      readString(
        row.id,
      ),

    userId:
      readString(
        row.user_id,
      ),

    title:
      readString(
        row.title,
      ),

    storagePath:
      readString(
        row.storage_path,
      ),

    isActive:
      readBoolean(
        row.is_active,
        true,
      ),

    audienceRoles:
      readStringArray(
        row.audience_roles,
      ),
  };
}

// ============================================================
// FETCH COM TIMEOUT
// ============================================================

async function fetchWithTimeout(
  input: string,
  init: RequestInit,
): Promise<Response> {
  const controller =
    new AbortController();

  const timeoutId =
    setTimeout(
      () => {
        controller.abort();
      },
      DATABASE_TIMEOUT_MS,
    );

  try {
    return await fetch(
      input,
      {
        ...init,

        signal:
          controller.signal,
      },
    );
  } finally {
    clearTimeout(
      timeoutId,
    );
  }
}

// ============================================================
// JSON BODY
// ============================================================

async function readJsonBody(
  request: Request,
): Promise<PlaybackRequestBody> {
  try {
    const value: unknown =
      await request.json();

    if (
      value ===
        null ||
      typeof value !==
        'object' ||
      Array.isArray(
        value,
      )
    ) {
      return {};
    }

    return value as PlaybackRequestBody;
  } catch {
    return {};
  }
}

// ============================================================
// JSON RESPONSE
// ============================================================

function jsonResponse(
  body: Record<string, unknown>,
  status = 200,
): Response {
  return new Response(
    JSON.stringify(
      body,
    ),
    {
      status:
        status,

      headers: {
        ...corsHeaders,

        'Content-Type':
          'application/json; charset=utf-8',
      },
    },
  );
}

// ============================================================
// ENV
// ============================================================

function requiredEnv(
  key: string,
): string {
  const value =
    Deno.env
      .get(
        key,
      )
      ?.trim() ??
    '';

  if (
    value.length ===
    0
  ) {
    throw new Error(
      `Variável ${key} não configurada.`,
    );
  }

  return value;
}

// ============================================================
// BEARER TOKEN
// ============================================================

function getBearerToken(
  authorization: string,
): string {
  const normalized =
    authorization.trim();

  const prefix =
    'Bearer ';

  if (
    !normalized.startsWith(
      prefix,
    )
  ) {
    return '';
  }

  return normalized
    .substring(
      prefix.length,
    )
    .trim();
}

// ============================================================
// JWT USER ID
// ============================================================

function getUserIdFromJwt(
  token: string,
): string {
  try {
    const parts =
      token.split(
        '.',
      );

    if (
      parts.length !==
      3
    ) {
      return '';
    }

    const payload =
      decodeBase64Url(
        parts[1],
      );

    const parsed: unknown =
      JSON.parse(
        payload,
      );

    if (
      parsed ===
        null ||
      typeof parsed !==
        'object' ||
      Array.isArray(
        parsed,
      )
    ) {
      return '';
    }

    const jwt =
      parsed as JwtPayload;

    return readString(
      jwt.sub,
    );
  } catch (
    error
  ) {
    console.error(
      '[PLAYBACK] Erro ao ler JWT:',
      safeErrorMessage(
        error,
      ),
    );

    return '';
  }
}

// ============================================================
// BASE64 URL
// ============================================================

function decodeBase64Url(
  value: string,
): string {
  let normalized =
    value
      .replaceAll(
        '-',
        '+',
      )
      .replaceAll(
        '_',
        '/',
      );

  const remainder =
    normalized.length %
    4;

  if (
    remainder !==
    0
  ) {
    normalized +=
      '='.repeat(
        4 -
          remainder,
      );
  }

  const binary =
    atob(
      normalized,
    );

  const bytes =
    Uint8Array.from(
      binary,
      (
        character,
      ) => {
        return character.charCodeAt(
          0,
        );
      },
    );

  return new TextDecoder()
    .decode(
      bytes,
    );
}

// ============================================================
// STRING
// ============================================================

function readString(
  value: unknown,
): string {
  if (
    value ===
      null ||
    value ===
      undefined
  ) {
    return '';
  }

  return String(
    value,
  ).trim();
}

// ============================================================
// BOOLEAN
// ============================================================

function readBoolean(
  value: unknown,
  fallback = false,
): boolean {
  if (
    typeof value ===
    'boolean'
  ) {
    return value;
  }

  if (
    typeof value ===
    'number'
  ) {
    return value !==
      0;
  }

  const normalized =
    readString(
      value,
    ).toLowerCase();

  if (
    normalized ===
      'true' ||
    normalized ===
      '1'
  ) {
    return true;
  }

  if (
    normalized ===
      'false' ||
    normalized ===
      '0'
  ) {
    return false;
  }

  return fallback;
}

// ============================================================
// STRING ARRAY
// ============================================================

function readStringArray(
  value: unknown,
): string[] {
  if (
    !Array.isArray(
      value,
    )
  ) {
    return [];
  }

  const values =
    value
      .map(
        (
          item,
        ) => {
          return readString(
            item,
          )
            .toLowerCase()
            .replace(
              /\s+/g,
              '_',
            );
        },
      )
      .filter(
        (
          item,
        ) => {
          return item.length >
            0;
        },
      );

  return [
    ...new Set(
      values,
    ),
  ];
}

// ============================================================
// ENCODE OBJECT KEY
// ============================================================

function encodeObjectKey(
  objectKey: string,
): string {
  return objectKey
    .split(
      '/',
    )
    .map(
      (
        segment,
      ) => {
        return encodeURIComponent(
          segment,
        );
      },
    )
    .join(
      '/',
    );
}

// ============================================================
// SAFE READ TEXT
// ============================================================

async function safeReadText(
  response: Response,
): Promise<string> {
  try {
    return await response.text();
  } catch {
    return '';
  }
}

// ============================================================
// SAFE ERROR
// ============================================================

function safeErrorMessage(
  error: unknown,
): string {
  if (
    error instanceof
    Error
  ) {
    return error.message;
  }

  return String(
    error,
  );
}