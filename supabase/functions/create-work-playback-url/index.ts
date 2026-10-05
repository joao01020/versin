import { AwsClient } from "aws4fetch";

import {
  createClient,
  SupabaseClient,
} from "npm:@supabase/supabase-js@2";

// ============================================================
// CREATE WORK PLAYBACK URL
// ============================================================
//
// Responsável por:
//
// - validar autenticação;
// - identificar usuário;
// - validar workId;
// - buscar a obra em stored_works;
// - confirmar que é um beat;
// - confirmar que o usuário é o proprietário atual;
// - obter file_path;
// - gerar URL GET temporária para Cloudflare R2.
//
// NÃO:
//
// - expõe credenciais do R2;
// - altera stored_works;
// - transfere propriedade;
// - torna o bucket público.
//
// Fluxo:
//
// Flutter
//    ↓
// create-work-playback-url
//    ↓
// autenticação
//    ↓
// stored_works
//    ↓
// verificar owner_user_id
//    ↓
// pegar file_path
//    ↓
// gerar GET assinado
//    ↓
// Cloudflare R2
//
// ============================================================

// ============================================================
// CONFIGURAÇÃO
// ============================================================

const PLAYBACK_URL_EXPIRES_SECONDS =
  600;

// ============================================================
// TABELAS
// ============================================================

const STORED_WORKS_TABLE =
  "stored_works";

// ============================================================
// CORS
// ============================================================

const corsHeaders: Record<
  string,
  string
> = {
  "Access-Control-Allow-Origin":
    "*",

  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",

  "Access-Control-Allow-Methods":
    "POST, OPTIONS",
};

// ============================================================
// JSON HEADERS
// ============================================================

const jsonHeaders: Record<
  string,
  string
> = {
  ...corsHeaders,

  "Content-Type":
    "application/json; charset=utf-8",
};

// ============================================================
// BODY
// ============================================================

interface PlaybackRequestBody {
  workId?: unknown;
}

// ============================================================
// WORK
// ============================================================

interface StoredWorkRow {
  id: string;

  owner_user_id: string;

  original_author_user_id: string;

  type: string;

  title: string;

  file_path: string | null;

  file_name: string | null;

  mime_type: string | null;
}

// ============================================================
// MAIN
// ============================================================

Deno.serve(
  async (
    request: Request,
  ): Promise<Response> => {
    // ========================================================
    // OPTIONS
    // ========================================================

    if (
      request.method ===
      "OPTIONS"
    ) {
      return new Response(
        "ok",
        {
          status:
            200,

          headers:
            corsHeaders,
        },
      );
    }

    // ========================================================
    // METHOD
    // ========================================================

    if (
      request.method !==
      "POST"
    ) {
      return jsonResponse(
        {
          error:
            "Método não permitido.",
        },
        405,
      );
    }

    try {
      // ======================================================
      // AUTHORIZATION
      // ======================================================

      const authorization =
        request.headers
          .get(
            "Authorization",
          )
          ?.trim() ??
        "";

      if (
        authorization.length ===
        0
      ) {
        return jsonResponse(
          {
            error:
              "Authorization não informado.",
          },
          401,
        );
      }

      // ======================================================
      // TOKEN
      // ======================================================

      const token =
        readBearerToken(
          authorization,
        );

      if (
        token.length ===
        0
      ) {
        return jsonResponse(
          {
            error:
              "Token inválido.",
          },
          401,
        );
      }

      // ======================================================
      // SUPABASE
      // ======================================================

      const supabase =
        createAuthenticatedSupabaseClient(
          authorization,
        );

      // ======================================================
      // VALIDAR USUÁRIO
      // ======================================================
      //
      // Não confiamos apenas no payload decodificado do JWT.
      //
      // getUser(token) confirma o token com Supabase Auth.
      //
      // ======================================================

      const {
        data:
          userData,

        error:
          userError,
      } =
        await supabase.auth.getUser(
          token,
        );

      if (
        userError != null ||
        userData.user == null
      ) {
        console.error(
          "[WORK PLAYBACK] "
            + "Falha na autenticação:",
          userError,
        );

        return jsonResponse(
          {
            error:
              "Usuário não autenticado.",
          },
          401,
        );
      }

      const userId =
        userData.user.id.trim();

      if (
        userId.length ===
        0
      ) {
        return jsonResponse(
          {
            error:
              "Usuário inválido.",
          },
          401,
        );
      }

      // ======================================================
      // BODY
      // ======================================================

      let body:
        PlaybackRequestBody;

      try {
        body =
          await request.json();
      } catch (_) {
        return jsonResponse(
          {
            error:
              "JSON inválido.",
          },
          400,
        );
      }

      // ======================================================
      // WORK ID
      // ======================================================

      const workId =
        readRequiredString(
          body.workId,
        );

      if (
        workId.length ===
        0
      ) {
        return jsonResponse(
          {
            error:
              "workId é obrigatório.",
          },
          400,
        );
      }

      if (
        !isSafeIdentifier(
          workId,
        )
      ) {
        return jsonResponse(
          {
            error:
              "workId inválido.",
          },
          400,
        );
      }

      // ======================================================
      // BUSCAR OBRA
      // ======================================================
      //
      // Além da RLS, fazemos explicitamente:
      //
      // owner_user_id = usuário autenticado.
      //
      // Portanto uma obra transferida deixa de ser acessível
      // ao proprietário anterior.
      //
      // ======================================================

      const {
        data:
          workData,

        error:
          workError,
      } =
        await supabase
          .from(
            STORED_WORKS_TABLE,
          )
          .select(
            [
              "id",
              "owner_user_id",
              "original_author_user_id",
              "type",
              "title",
              "file_path",
              "file_name",
              "mime_type",
            ].join(
              ",",
            ),
          )
          .eq(
            "id",
            workId,
          )
          .eq(
            "owner_user_id",
            userId,
          )
          .maybeSingle();

      if (
        workError != null
      ) {
        console.error(
          "[WORK PLAYBACK] "
            + "Erro ao buscar obra:",
          workError,
        );

        return jsonResponse(
          {
            error:
              "Não foi possível consultar a obra.",
          },
          500,
        );
      }

      if (
        workData == null
      ) {
        return jsonResponse(
          {
            error:
              "Obra não encontrada ou acesso não autorizado.",
          },
          404,
        );
      }

      const work =
        workData as StoredWorkRow;

      // ======================================================
      // TIPO
      // ======================================================

      if (
        work.type !==
        "beat"
      ) {
        return jsonResponse(
          {
            error:
              "A obra informada não é um beat.",
          },
          400,
        );
      }

      // ======================================================
      // PROPRIETÁRIO
      // ======================================================

      if (
        work.owner_user_id !==
        userId
      ) {
        return jsonResponse(
          {
            error:
              "Você não possui acesso a este beat.",
          },
          403,
        );
      }

      // ======================================================
      // FILE PATH
      // ======================================================

      const objectKey =
        work.file_path?.trim() ??
        "";

      if (
        objectKey.length ===
        0
      ) {
        return jsonResponse(
          {
            error:
              "Este beat não possui arquivo armazenado.",
          },
          404,
        );
      }

      // ======================================================
      // VALIDAR OBJECT KEY
      // ======================================================

      if (
        !isSafeObjectKey(
          objectKey,
        )
      ) {
        console.error(
          "[WORK PLAYBACK] "
            + "Object key inválido:",
          objectKey,
        );

        return jsonResponse(
          {
            error:
              "Referência de armazenamento inválida.",
          },
          500,
        );
      }

      // ======================================================
      // SECRETS R2
      // ======================================================

      const accountId =
        readEnv(
          "R2_ACCOUNT_ID",
        );

      const accessKeyId =
        readEnv(
          "R2_ACCESS_KEY_ID",
        );

      const secretAccessKey =
        readEnv(
          "R2_SECRET_ACCESS_KEY",
        );

      const bucketName =
        readEnv(
          "R2_WORKS_BUCKET",
        );

      // ======================================================
      // AWS CLIENT
      // ======================================================

      const client =
        new AwsClient(
          {
            service:
              "s3",

            region:
              "auto",

            accessKeyId,

            secretAccessKey,
          },
        );

      // ======================================================
      // OBJECT URL
      // ======================================================

      const r2BaseUrl =
        `https://${accountId}.r2.cloudflarestorage.com`;

      const objectUrl =
        `${r2BaseUrl}/`
        + `${encodeURIComponent(bucketName)}/`
        + `${encodeObjectKey(objectKey)}`;

      // ======================================================
      // SIGNED GET
      // ======================================================
      //
      // GET temporário.
      //
      // A URL pode ser utilizada apenas até expirar.
      //
      // ======================================================

      const unsignedRequest =
        new Request(
          `${objectUrl}`
          + `?X-Amz-Expires=${PLAYBACK_URL_EXPIRES_SECONDS}`,
          {
            method:
              "GET",
          },
        );

      const signedRequest =
        await client.sign(
          unsignedRequest,
          {
            aws: {
              signQuery:
                true,
            },
          },
        );

      // ======================================================
      // RESPONSE
      // ======================================================

      console.log(
        "[WORK PLAYBACK] "
          + `URL criada para ${work.id}`,
      );

      return jsonResponse(
        {
          playbackUrl:
            signedRequest.url,

          workId:
            work.id,

          title:
            work.title,

          fileName:
            work.file_name,

          contentType:
            work.mime_type,

          expiresIn:
            PLAYBACK_URL_EXPIRES_SECONDS,
        },
        200,
      );
    } catch (
      error
    ) {
      console.error(
        "[CREATE WORK PLAYBACK URL]",
        error,
      );

      return jsonResponse(
        {
          error:
            "Não foi possível criar a URL de reprodução.",

          details:
            error instanceof Error
              ? error.message
              : String(
                  error,
                ),
        },
        500,
      );
    }
  },
);

// ============================================================
// CRIAR SUPABASE CLIENT
// ============================================================
//
// Usa o Authorization recebido do Flutter.
//
// Isso faz com que consultas ao banco respeitem as políticas
// RLS do usuário autenticado.
//
// ============================================================

function createAuthenticatedSupabaseClient(
  authorization:
    string,
): SupabaseClient {
  const supabaseUrl =
    readEnv(
      "SUPABASE_URL",
    );

  const supabaseAnonKey =
    readSupabasePublicKey();

  return createClient(
    supabaseUrl,
    supabaseAnonKey,
    {
      global: {
        headers: {
          Authorization:
            authorization,
        },
      },

      auth: {
        persistSession:
          false,

        autoRefreshToken:
          false,

        detectSessionInUrl:
          false,
      },
    },
  );
}

// ============================================================
// PUBLIC / ANON KEY
// ============================================================
//
// Projetos existentes normalmente possuem:
//
// SUPABASE_ANON_KEY
//
// Mantemos esse fallback porque ele é compatível com o fluxo
// atual das suas Edge Functions.
//
// ============================================================

function readSupabasePublicKey():
  string {
  const anonKey =
    Deno.env
      .get(
        "SUPABASE_ANON_KEY",
      )
      ?.trim() ??
    "";

  if (
    anonKey.length >
    0
  ) {
    return anonKey;
  }

  const publishableKey =
    Deno.env
      .get(
        "SUPABASE_PUBLISHABLE_KEY",
      )
      ?.trim() ??
    "";

  if (
    publishableKey.length >
    0
  ) {
    return publishableKey;
  }

  throw new Error(
    "SUPABASE_ANON_KEY ou "
      + "SUPABASE_PUBLISHABLE_KEY não configurado.",
  );
}

// ============================================================
// JSON RESPONSE
// ============================================================

function jsonResponse(
  data:
    unknown,

  status:
    number,
): Response {
  return new Response(
    JSON.stringify(
      data,
    ),
    {
      status,

      headers:
        jsonHeaders,
    },
  );
}

// ============================================================
// BEARER TOKEN
// ============================================================

function readBearerToken(
  authorization:
    string,
): string {
  const normalized =
    authorization.trim();

  if (
    normalized.length ===
    0
  ) {
    return "";
  }

  const prefix =
    "Bearer ";

  if (
    !normalized
      .toLowerCase()
      .startsWith(
        prefix.toLowerCase(),
      )
  ) {
    return "";
  }

  return normalized
    .substring(
      prefix.length,
    )
    .trim();
}

// ============================================================
// REQUIRED STRING
// ============================================================

function readRequiredString(
  value:
    unknown,
): string {
  if (
    typeof value !==
    "string"
  ) {
    return "";
  }

  return value.trim();
}

// ============================================================
// WORK ID
// ============================================================

function isSafeIdentifier(
  value:
    string,
): boolean {
  return /^[a-zA-Z0-9_-]{1,180}$/.test(
    value,
  );
}

// ============================================================
// OBJECT KEY
// ============================================================

function isSafeObjectKey(
  value:
    string,
): boolean {
  if (
    value.length ===
      0 ||
    value.length >
      1024
  ) {
    return false;
  }

  // Não permitimos path traversal.
  if (
    value.includes(
      "..",
    )
  ) {
    return false;
  }

  if (
    value.startsWith(
      "/",
    )
  ) {
    return false;
  }

  return true;
}

// ============================================================
// ENCODE OBJECT KEY
// ============================================================

function encodeObjectKey(
  objectKey:
    string,
): string {
  return objectKey
    .split(
      "/",
    )
    .map(
      (
        segment,
      ) =>
        encodeURIComponent(
          segment,
        ),
    )
    .join(
      "/",
    );
}

// ============================================================
// ENV
// ============================================================

function readEnv(
  name:
    string,
): string {
  const value =
    Deno.env
      .get(
        name,
      )
      ?.trim() ??
    "";

  if (
    value.length ===
    0
  ) {
    throw new Error(
      `Secret ${name} não configurado.`,
    );
  }

  return value;
}