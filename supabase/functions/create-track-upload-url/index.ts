import { AwsClient } from "aws4fetch";

// ============================================================
// CREATE TRACK UPLOAD URL
// ============================================================
//
// Responsável por:
//
// - receber solicitação autenticada;
// - identificar auth.uid através do JWT;
// - validar nome, MIME e tamanho;
// - gerar objectKey;
// - gerar presigned PUT URL;
// - retornar uploadUrl + objectKey.
//
// NÃO:
//
// - recebe bytes da música;
// - envia arquivo ao R2;
// - cria profile_tracks;
// - expõe secrets;
// - consulta Postgres.
//
// ============================================================

// ============================================================
// LIMITES
// ============================================================

const MAX_FILE_SIZE_BYTES =
  8 * 1024 * 1024;

const UPLOAD_URL_EXPIRES_SECONDS =
  300;

// ============================================================
// MIME TYPES
// ============================================================

const ALLOWED_CONTENT_TYPES =
  new Set<string>([
    "audio/mpeg",
    "audio/wav",
    "audio/mp4",
    "audio/aac",
    "audio/ogg",
  ]);

// ============================================================
// EXTENSÕES
// ============================================================

const ALLOWED_EXTENSIONS =
  new Set<string>([
    "mp3",
    "wav",
    "m4a",
    "aac",
    "ogg",
  ]);

// ============================================================
// CORS
// ============================================================

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods":
    "POST, OPTIONS",
};

// ============================================================
// RESPONSE HEADERS
// ============================================================

const jsonHeaders: Record<string, string> = {
  ...corsHeaders,
  "Content-Type": "application/json; charset=utf-8",
};

// ============================================================
// TYPES
// ============================================================

interface UploadRequestBody {
  fileName?: unknown;
  contentType?: unknown;
  fileSizeBytes?: unknown;
}

interface JwtPayload {
  sub?: unknown;
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
      "[UPLOAD] Início da requisição.",
    );

    // ==========================================================
    // OPTIONS
    // ==========================================================

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

    // ==========================================================
    // METHOD
    // ==========================================================

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
      // ========================================================
      // AUTHORIZATION
      // ========================================================

      console.log(
        "[UPLOAD] Lendo Authorization.",
      );

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

      // ========================================================
      // USER ID
      // ========================================================

      const userId =
        readUserIdFromJwt(
          token,
        );

      if (
        userId.length ===
        0
      ) {
        return jsonResponse(
          {
            error:
              "Usuário autenticado não encontrado.",
          },
          401,
        );
      }

      console.log(
        "[UPLOAD] Usuário autenticado identificado.",
      );

      // ========================================================
      // BODY
      // ========================================================

      const body =
        await readJsonBody(
          request,
        );

      // ========================================================
      // FILE NAME
      // ========================================================

      const fileName =
        sanitizeFileName(
          readString(
            body.fileName,
          ),
        );

      if (
        fileName.length ===
        0
      ) {
        return jsonResponse(
          {
            error:
              "fileName é obrigatório.",
          },
          400,
        );
      }

      // ========================================================
      // EXTENSION
      // ========================================================

      const extension =
        readExtension(
          fileName,
        );

      if (
        extension.length ===
          0 ||
        !ALLOWED_EXTENSIONS.has(
          extension,
        )
      ) {
        return jsonResponse(
          {
            error:
              "Extensão de áudio não permitida.",
          },
          400,
        );
      }

      // ========================================================
      // CONTENT TYPE
      // ========================================================

      const contentType =
        normalizeContentType(
          readString(
            body.contentType,
          ),
        );

      if (
        contentType.length ===
        0
      ) {
        return jsonResponse(
          {
            error:
              "contentType é obrigatório.",
          },
          400,
        );
      }

      if (
        !ALLOWED_CONTENT_TYPES.has(
          contentType,
        )
      ) {
        return jsonResponse(
          {
            error:
              "Formato de áudio não permitido.",
          },
          400,
        );
      }

      // ========================================================
      // FILE SIZE
      // ========================================================

      const fileSizeBytes =
        readInteger(
          body.fileSizeBytes,
        );

      if (
        fileSizeBytes <=
        0
      ) {
        return jsonResponse(
          {
            error:
              "fileSizeBytes inválido.",
          },
          400,
        );
      }

      if (
        fileSizeBytes >
        MAX_FILE_SIZE_BYTES
      ) {
        return jsonResponse(
          {
            error:
              "A música ultrapassa o limite de 8 MB.",
          },
          413,
        );
      }

      console.log(
        "[UPLOAD] Arquivo validado.",
      );

      // ========================================================
      // R2 SECRETS
      // ========================================================

      const accountId =
        readRequiredEnv(
          "R2_ACCOUNT_ID",
        );

      const accessKeyId =
        readRequiredEnv(
          "R2_ACCESS_KEY_ID",
        );

      const secretAccessKey =
        readRequiredEnv(
          "R2_SECRET_ACCESS_KEY",
        );

      const bucket =
        readRequiredEnv(
          "R2_BUCKET",
        );

      // ========================================================
      // OBJECT KEY
      // ========================================================

      const objectId =
        crypto.randomUUID();

      const objectKey =
        [
          "profiles",
          userId,
          "tracks",
          `${objectId}.${extension}`,
        ].join(
          "/",
        );

      console.log(
        "[UPLOAD] Object key criado.",
      );

      // ========================================================
      // AWS CLIENT
      // ========================================================

      const r2 =
        new AwsClient({
          service:
            "s3",

          region:
            "auto",

          accessKeyId:
            accessKeyId,

          secretAccessKey:
            secretAccessKey,
        });

      // ========================================================
      // ENDPOINT
      // ========================================================

      const encodedObjectKey =
        encodeObjectKey(
          objectKey,
        );

      const endpoint =
        `https://${accountId}.r2.cloudflarestorage.com/` +
        `${encodeURIComponent(bucket)}/` +
        encodedObjectKey;

      // ========================================================
      // PRESIGNED PUT
      // ========================================================

      const url =
        new URL(
          endpoint,
        );

      url.searchParams.set(
        "X-Amz-Expires",
        UPLOAD_URL_EXPIRES_SECONDS
          .toString(),
      );

      console.log(
        "[UPLOAD] Gerando presigned PUT URL.",
      );

      const unsignedRequest =
        new Request(
          url.toString(),
          {
            method:
              "PUT",

            headers: {
              "Content-Type":
                contentType,
            },
          },
        );

      const signedRequest =
        await r2.sign(
          unsignedRequest,
          {
            aws: {
              signQuery:
                true,
            },
          },
        );

      const uploadUrl =
        signedRequest.url;

      if (
        uploadUrl.length ===
        0
      ) {
        throw new Error(
          "Não foi possível gerar uploadUrl.",
        );
      }

      // ========================================================
      // SUCCESS
      // ========================================================

      const elapsed =
        Date.now() -
        startedAt;

      console.log(
        `[UPLOAD] Finalizado em ${elapsed} ms.`,
      );

      return jsonResponse(
        {
          uploadUrl:
            uploadUrl,

          objectKey:
            objectKey,

          contentType:
            contentType,

          expiresIn:
            UPLOAD_URL_EXPIRES_SECONDS,
        },
        200,
      );
    } catch (
      error
    ) {
      const elapsed =
        Date.now() -
        startedAt;

      console.error(
        `[UPLOAD] Falhou após ${elapsed} ms.`,
      );

      console.error(
        "[UPLOAD] Erro:",
        safeErrorMessage(
          error,
        ),
      );

      return jsonResponse(
        {
          error:
            "Não foi possível gerar a URL de upload.",
        },
        500,
      );
    }
  },
);

// ============================================================
// JSON RESPONSE
// ============================================================

function jsonResponse(
  body: Record<string, unknown>,
  status: number,
): Response {
  return new Response(
    JSON.stringify(
      body,
    ),
    {
      status:
        status,

      headers:
        jsonHeaders,
    },
  );
}

// ============================================================
// JSON BODY
// ============================================================

async function readJsonBody(
  request: Request,
): Promise<UploadRequestBody> {
  try {
    const value: unknown =
      await request.json();

    if (
      value ===
        null ||
      typeof value !==
        "object" ||
      Array.isArray(
        value,
      )
    ) {
      return {};
    }

    return value as UploadRequestBody;
  } catch {
    return {};
  }
}

// ============================================================
// BEARER TOKEN
// ============================================================

function readBearerToken(
  authorization: string,
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
    !normalized.startsWith(
      prefix,
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
// USER FROM JWT
// ============================================================

function readUserIdFromJwt(
  token: string,
): string {
  try {
    const parts =
      token.split(
        ".",
      );

    if (
      parts.length !==
      3
    ) {
      return "";
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
        "object" ||
      Array.isArray(
        parsed,
      )
    ) {
      return "";
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
      "[UPLOAD] Falha ao ler JWT:",
      safeErrorMessage(
        error,
      ),
    );

    return "";
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
        "-",
        "+",
      )
      .replaceAll(
        "_",
        "/",
      );

  const remainder =
    normalized.length %
    4;

  if (
    remainder !==
    0
  ) {
    normalized +=
      "=".repeat(
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
      ) =>
        character.charCodeAt(
          0,
        ),
    );

  return new TextDecoder()
    .decode(
      bytes,
    );
}

// ============================================================
// REQUIRED ENV
// ============================================================

function readRequiredEnv(
  name: string,
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
    return "";
  }

  return String(
    value,
  ).trim();
}

// ============================================================
// INTEGER
// ============================================================

function readInteger(
  value: unknown,
): number {
  if (
    typeof value ===
      "number" &&
    Number.isFinite(
      value,
    )
  ) {
    return Math.trunc(
      value,
    );
  }

  const parsed =
    Number.parseInt(
      readString(
        value,
      ),
      10,
    );

  if (
    !Number.isFinite(
      parsed,
    )
  ) {
    return 0;
  }

  return parsed;
}

// ============================================================
// CONTENT TYPE
// ============================================================

function normalizeContentType(
  value: string,
): string {
  const normalized =
    value
      .trim()
      .toLowerCase();

  if (
    normalized ===
    "audio/mp3"
  ) {
    return "audio/mpeg";
  }

  if (
    normalized ===
    "audio/x-wav"
  ) {
    return "audio/wav";
  }

  return normalized;
}

// ============================================================
// FILE NAME
// ============================================================

function sanitizeFileName(
  value: string,
): string {
  return value
    .trim()
    .replace(
      /[^a-zA-Z0-9._-]/g,
      "_",
    )
    .replace(
      /_+/g,
      "_",
    );
}

// ============================================================
// EXTENSION
// ============================================================

function readExtension(
  fileName: string,
): string {
  const lastDot =
    fileName.lastIndexOf(
      ".",
    );

  if (
    lastDot <
      0 ||
    lastDot ===
      fileName.length -
        1
  ) {
    return "";
  }

  return fileName
    .substring(
      lastDot +
        1,
    )
    .trim()
    .toLowerCase();
}

// ============================================================
// OBJECT KEY
// ============================================================

function encodeObjectKey(
  objectKey: string,
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
// ERROR
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