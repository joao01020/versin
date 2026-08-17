import { AwsClient } from "aws4fetch";

// ============================================================
// CREATE WORK UPLOAD URL
// ============================================================
//
// Responsável por:
//
// - validar requisição;
// - identificar usuário autenticado;
// - validar workId;
// - validar nome, MIME e tamanho;
// - gerar objectKey permanente;
// - gerar URL PUT assinada para Cloudflare R2.
//
// NÃO:
//
// - recebe os bytes do beat;
// - grava stored_works;
// - expõe credenciais do R2;
// - altera autoria.
//
// Fluxo:
//
// Flutter
//    ↓
// create-work-upload-url
//    ↓
// presigned PUT URL
//    ↓
// Flutter envia bytes diretamente ao R2
//
// ============================================================

// ============================================================
// CONFIGURAÇÃO
// ============================================================

const MAX_FILE_SIZE_BYTES =
  100 * 1024 * 1024;

const UPLOAD_URL_EXPIRES_SECONDS =
  300;

// ============================================================
// MIME TYPES
// ============================================================

const ALLOWED_CONTENT_TYPES =
  new Set<string>([
    "audio/mpeg",
    "audio/wav",
    "audio/x-wav",
    "audio/mp4",
    "audio/aac",
    "audio/ogg",
    "audio/flac",
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
    "flac",
  ]);

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
// REQUEST BODY
// ============================================================

interface UploadRequestBody {
  workId?: unknown;

  fileName?: unknown;

  contentType?: unknown;

  fileSizeBytes?: unknown;
}

// ============================================================
// JWT
// ============================================================

interface JwtPayload {
  sub?: unknown;

  exp?: unknown;
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
      // USER ID
      // ======================================================

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
              "Usuário não autenticado.",
          },
          401,
        );
      }

      // ======================================================
      // BODY
      // ======================================================

      let body:
        UploadRequestBody;

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
      // FILE NAME
      // ======================================================

      const fileName =
        sanitizeFileName(
          readRequiredString(
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

      // ======================================================
      // EXTENSÃO
      // ======================================================

      const extension =
        getExtension(
          fileName,
        );

      if (
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

      // ======================================================
      // CONTENT TYPE
      // ======================================================

      const contentType =
        readRequiredString(
          body.contentType,
        ).toLowerCase();

      if (
        !ALLOWED_CONTENT_TYPES.has(
          contentType,
        )
      ) {
        return jsonResponse(
          {
            error:
              "Tipo de áudio não permitido.",
          },
          400,
        );
      }

      // ======================================================
      // TAMANHO
      // ======================================================

      const fileSizeBytes =
        readPositiveInteger(
          body.fileSizeBytes,
        );

      if (
        fileSizeBytes <=
        0
      ) {
        return jsonResponse(
          {
            error:
              "Tamanho do arquivo inválido.",
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
              "O beat ultrapassa o limite de 100 MB.",
          },
          413,
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
      // OBJECT KEY
      // ======================================================
      //
      // IMPORTANTE:
      //
      // Não usamos owner atual como parte mutável da identidade
      // da obra.
      //
      // Caminho:
      //
      // users/<autor>/works/<workId>/original.<ext>
      //
      // Em uma transferência futura, não precisamos mover
      // o arquivo físico.
      //
      // ======================================================

      const objectKey =
        [
          "users",
          sanitizePathSegment(
            userId,
          ),
          "works",
          sanitizePathSegment(
            workId,
          ),
          `original.${extension}`,
        ].join(
          "/",
        );

      // ======================================================
      // R2 CLIENT
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
      // R2 URL
      // ======================================================

      const r2BaseUrl =
        `https://${accountId}.r2.cloudflarestorage.com`;

      const objectUrl =
        `${r2BaseUrl}/${encodeURIComponent(bucketName)}/${encodeObjectKey(objectKey)}`;

      // ======================================================
      // SIGNED PUT
      // ======================================================

      const unsignedRequest =
        new Request(
          `${objectUrl}?X-Amz-Expires=${UPLOAD_URL_EXPIRES_SECONDS}`,
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

      return jsonResponse(
        {
          uploadUrl:
            signedRequest.url,

          objectKey,

          workId,

          fileName,

          contentType,

          fileSizeBytes,

          expiresIn:
            UPLOAD_URL_EXPIRES_SECONDS,
        },
        200,
      );
    } catch (
      error
    ) {
      console.error(
        "[CREATE WORK UPLOAD URL]",
        error,
      );

      return jsonResponse(
        {
          error:
            "Não foi possível criar a URL de upload.",

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
// JSON RESPONSE
// ============================================================

function jsonResponse(
  data: unknown,
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
// USER ID DO JWT
// ============================================================
//
// Aqui precisamos somente identificar o usuário.
//
// A validação criptográfica do JWT continua sendo feita pelo
// gateway do Supabase quando verify_jwt está habilitado.
//
// ============================================================

function readUserIdFromJwt(
  token:
    string,
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

    const payloadPart =
      parts[1]
        .replaceAll(
          "-",
          "+",
        )
        .replaceAll(
          "_",
          "/",
        );

    const padded =
      payloadPart.padEnd(
        Math.ceil(
          payloadPart.length /
            4,
        ) *
          4,
        "=",
      );

    const json =
      atob(
        padded,
      );

    const payload =
      JSON.parse(
        json,
      ) as JwtPayload;

    // ========================================================
    // EXPIRAÇÃO
    // ========================================================

    if (
      typeof payload.exp ===
      "number"
    ) {
      const now =
        Math.floor(
          Date.now() /
            1000,
        );

      if (
        payload.exp <=
        now
      ) {
        return "";
      }
    }

    // ========================================================
    // SUBJECT
    // ========================================================

    if (
      typeof payload.sub !==
      "string"
    ) {
      return "";
    }

    return payload.sub.trim();
  } catch (_) {
    return "";
  }
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
// INTEGER
// ============================================================

function readPositiveInteger(
  value:
    unknown,
): number {
  if (
    typeof value ===
    "number"
  ) {
    if (
      Number.isInteger(
        value,
      ) &&
      value >
        0
    ) {
      return value;
    }

    return 0;
  }

  if (
    typeof value ===
    "string"
  ) {
    const parsed =
      Number.parseInt(
        value,
        10,
      );

    if (
      Number.isInteger(
        parsed,
      ) &&
      parsed >
        0
    ) {
      return parsed;
    }
  }

  return 0;
}

// ============================================================
// FILE NAME
// ============================================================

function sanitizeFileName(
  value:
    string,
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
// PATH SEGMENT
// ============================================================

function sanitizePathSegment(
  value:
    string,
): string {
  return value
    .trim()
    .replace(
      /[^a-zA-Z0-9_-]/g,
      "_",
    );
}

// ============================================================
// IDENTIFIER
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
// EXTENSÃO
// ============================================================

function getExtension(
  fileName:
    string,
): string {
  const index =
    fileName.lastIndexOf(
      ".",
    );

  if (
    index <=
      0 ||
    index ===
      fileName.length -
        1
  ) {
    return "";
  }

  return fileName
    .substring(
      index +
        1,
    )
    .toLowerCase();
}

// ============================================================
// OBJECT KEY URL
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