import { AwsClient } from "aws4fetch";

import {
  createClient,
  SupabaseClient,
} from "@supabase/supabase-js";

// ============================================================
// DELETE WORK FILE
// ============================================================
//
// Responsável por:
//
// - autenticar usuário;
// - receber somente workId;
// - localizar a obra;
// - validar proprietário atual;
// - validar que é beat;
// - obter file_path pelo banco;
// - apagar o objeto correspondente no Cloudflare R2.
//
// O Flutter NÃO envia:
//
// - objectKey;
// - bucket;
// - userId;
// - filePath.
//
// ============================================================

// ============================================================
// TABLE
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

interface DeleteWorkRequestBody {
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
          status: 200,
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
        authorization.length === 0
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
        token.length === 0
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
      // SUPABASE CLIENT
      // ======================================================

      const supabase =
        createAuthenticatedSupabaseClient(
          authorization,
        );

      // ======================================================
      // USUÁRIO AUTENTICADO
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
          "[DELETE WORK] Falha na autenticação:",
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
        userId.length === 0
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
        DeleteWorkRequestBody;

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
        workId.length === 0
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

      const {
        data:
          rawWork,

        error:
          workError,
      } =
        await supabase
          .from(
            STORED_WORKS_TABLE,
          )
          .select(
            "id,"
              + "owner_user_id,"
              + "original_author_user_id,"
              + "type,"
              + "title,"
              + "file_path,"
              + "file_name,"
              + "mime_type",
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
          "[DELETE WORK] Erro ao buscar obra:",
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
        rawWork == null
      ) {
        return jsonResponse(
          {
            error:
              "Obra não encontrada ou acesso não autorizado.",
          },
          404,
        );
      }

      // ======================================================
      // VALIDAR RETORNO
      // ======================================================

      const work =
        parseStoredWork(
          rawWork,
        );

      if (
        work == null
      ) {
        console.error(
          "[DELETE WORK] Registro inválido:",
          rawWork,
        );

        return jsonResponse(
          {
            error:
              "Dados da obra inválidos.",
          },
          500,
        );
      }

      // ======================================================
      // BEAT
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
      // OBJECT KEY
      // ======================================================

      const objectKey =
        work.file_path?.trim() ??
        "";

      if (
        objectKey.length === 0
      ) {
        return jsonResponse(
          {
            success:
              true,

            deleted:
              false,

            workId:
              work.id,

            message:
              "A obra não possui arquivo armazenado.",
          },
          200,
        );
      }

      if (
        !isSafeObjectKey(
          objectKey,
        )
      ) {
        console.error(
          "[DELETE WORK] Object key inválido:",
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
      // CONFIRMAR QUE OBJECT KEY PERTENCE À OBRA
      // ======================================================

      const expectedWorkSegment =
        `/works/${work.id}/`;

      if (
        !objectKey.includes(
          expectedWorkSegment,
        )
      ) {
        console.error(
          "[DELETE WORK] "
            + "Object key não corresponde ao workId:",
          objectKey,
        );

        return jsonResponse(
          {
            error:
              "Arquivo não corresponde à obra informada.",
          },
          500,
        );
      }

      // ======================================================
      // R2
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
      // ASSINAR DELETE
      // ======================================================

      const requestToSign =
        new Request(
          objectUrl,
          {
            method:
              "DELETE",
          },
        );

      const signedRequest =
        await client.sign(
          requestToSign,
        );

      // ======================================================
      // DELETE R2
      // ======================================================

      const deleteResponse =
        await fetch(
          signedRequest,
        );

      if (
        deleteResponse.status <
          200 ||
        deleteResponse.status >=
          300
      ) {
        const responseBody =
          await safeReadText(
            deleteResponse,
          );

        console.error(
          "[DELETE WORK] "
            + `R2 HTTP ${deleteResponse.status}: `
            + responseBody,
        );

        return jsonResponse(
          {
            error:
              "Não foi possível excluir o arquivo do beat.",

            status:
              deleteResponse.status,
          },
          502,
        );
      }

      // ======================================================
      // SUCCESS
      // ======================================================

      console.log(
        "[DELETE WORK] "
          + `Arquivo apagado: ${objectKey}`,
      );

      return jsonResponse(
        {
          success:
            true,

          deleted:
            true,

          workId:
            work.id,

          objectKey,

          message:
            "Arquivo removido do armazenamento.",
        },
        200,
      );
    } catch (
      error
    ) {
      console.error(
        "[DELETE WORK FILE]",
        error,
      );

      return jsonResponse(
        {
          error:
            "Não foi possível excluir o arquivo.",

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
// PARSE STORED WORK
// ============================================================
//
// Evita:
//
// rawWork as StoredWorkRow
//
// que é exatamente o cast que estava gerando:
//
// GenericStringError -> StoredWorkRow
//
// ============================================================

function parseStoredWork(
  value:
    unknown,
): StoredWorkRow | null {
  if (
    typeof value !==
      "object" ||
    value == null
  ) {
    return null;
  }

  const map =
    value as Record<
      string,
      unknown
    >;

  const id =
    readRequiredString(
      map.id,
    );

  const ownerUserId =
    readRequiredString(
      map.owner_user_id,
    );

  const originalAuthorUserId =
    readRequiredString(
      map.original_author_user_id,
    );

  const type =
    readRequiredString(
      map.type,
    );

  const title =
    readRequiredString(
      map.title,
    );

  if (
    id.length === 0 ||
    ownerUserId.length === 0 ||
    originalAuthorUserId.length === 0 ||
    type.length === 0
  ) {
    return null;
  }

  return {
    id,

    owner_user_id:
      ownerUserId,

    original_author_user_id:
      originalAuthorUserId,

    type,

    title,

    file_path:
      readNullableString(
        map.file_path,
      ),

    file_name:
      readNullableString(
        map.file_name,
      ),

    mime_type:
      readNullableString(
        map.mime_type,
      ),
  };
}

// ============================================================
// SUPABASE CLIENT
// ============================================================

function createAuthenticatedSupabaseClient(
  authorization:
    string,
): SupabaseClient {
  const supabaseUrl =
    readEnv(
      "SUPABASE_URL",
    );

  const publicKey =
    readSupabasePublicKey();

  return createClient(
    supabaseUrl,
    publicKey,
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
// SUPABASE KEY
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
    anonKey.length > 0
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
    publishableKey.length > 0
  ) {
    return publishableKey;
  }

  throw new Error(
    "SUPABASE_ANON_KEY ou "
      + "SUPABASE_PUBLISHABLE_KEY não configurado.",
  );
}

// ============================================================
// JSON
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
// BEARER
// ============================================================

function readBearerToken(
  authorization:
    string,
): string {
  const normalized =
    authorization.trim();

  if (
    normalized.length === 0
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
// STRING
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
// NULLABLE STRING
// ============================================================

function readNullableString(
  value:
    unknown,
): string | null {
  if (
    typeof value !==
    "string"
  ) {
    return null;
  }

  const normalized =
    value.trim();

  return normalized.length === 0
    ? null
    : normalized;
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
    value.length === 0 ||
    value.length >
      1024
  ) {
    return false;
  }

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
// OBJECT KEY ENCODE
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
// RESPONSE BODY
// ============================================================

async function safeReadText(
  response:
    Response,
): Promise<string> {
  try {
    return await response.text();
  } catch (_) {
    return "";
  }
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
    value.length === 0
  ) {
    throw new Error(
      `Secret ${name} não configurado.`,
    );
  }

  return value;
}