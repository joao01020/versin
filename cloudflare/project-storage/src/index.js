export default {
  async fetch(request, env) {
    try {
      const url = new URL(request.url);

      // ========================================================
      // HEALTH CHECK
      // ========================================================

      if (
        request.method === "GET" &&
        url.pathname === "/"
      ) {
        return jsonResponse(
          {
            ok: true,
            service: "versin-project-storage",
            bucketConfigured:
              !!env.PROJECT_DELIVERIES,
          },
          200,
        );
      }

      // ========================================================
      // AUTH
      // ========================================================

      const authError =
        validateInternalSecret(
          request,
          env,
        );

      if (authError) {
        return authError;
      }

      // ========================================================
      // ROUTES
      // ========================================================

      if (
        request.method === "PUT" &&
        url.pathname === "/object"
      ) {
        return await handleUpload(
          request,
          env,
        );
      }

      if (
        request.method === "GET" &&
        url.pathname === "/object"
      ) {
        return await handleDownload(
          request,
          env,
          url,
        );
      }

      if (
        request.method === "HEAD" &&
        url.pathname === "/object"
      ) {
        return await handleHead(
          env,
          url,
        );
      }

      if (
        request.method === "DELETE" &&
        url.pathname === "/object"
      ) {
        return await handleDelete(
          env,
          url,
        );
      }

      return jsonResponse(
        {
          ok: false,
          error: "Route not found.",
        },
        404,
      );
    } catch (error) {
      return jsonResponse(
        {
          ok: false,
          error:
            error instanceof Error
              ? error.message
              : String(error),
        },
        500,
      );
    }
  },
};

// ============================================================
// AUTH
// ============================================================

function validateInternalSecret(
  request,
  env,
) {
  const expectedSecret =
    String(
      env.VERSIN_API_SECRET ?? "",
    ).trim();

  if (!expectedSecret) {
    return jsonResponse(
      {
        ok: false,
        error:
          "Server secret is not configured.",
      },
      500,
    );
  }

  const receivedSecret =
    String(
      request.headers.get(
        "x-versin-secret",
      ) ?? "",
    ).trim();

  if (!receivedSecret) {
    return jsonResponse(
      {
        ok: false,
        error:
          "Missing internal authentication.",
      },
      401,
    );
  }

  if (
    receivedSecret !==
    expectedSecret
  ) {
    return jsonResponse(
      {
        ok: false,
        error:
          "Invalid internal authentication.",
      },
      403,
    );
  }

  return null;
}

// ============================================================
// UPLOAD
// ============================================================
//
// PUT /object
//
// Headers:
//
// x-versin-secret
// x-storage-path
// content-type
//
// Body:
//
// bytes do arquivo
//
// ============================================================

async function handleUpload(
  request,
  env,
) {
  const storagePath =
    normalizeStoragePath(
      request.headers.get(
        "x-storage-path",
      ),
    );

  if (!storagePath) {
    return jsonResponse(
      {
        ok: false,
        error:
          "Missing or invalid x-storage-path.",
      },
      400,
    );
  }

  const contentType =
    normalizeContentType(
      request.headers.get(
        "content-type",
      ),
    );

  const bytes =
    await request.arrayBuffer();

  if (
    !bytes ||
    bytes.byteLength === 0
  ) {
    return jsonResponse(
      {
        ok: false,
        error:
          "File body is empty.",
      },
      400,
    );
  }

  // ==========================================================
  // MAX SIZE
  // ==========================================================
  //
  // Exemplo inicial:
  //
  // 2 GB
  //
  // Depois podemos mover isso para env.
  //
  // ==========================================================

  const maxFileSize =
    2 *
    1024 *
    1024 *
    1024;

  if (
    bytes.byteLength >
    maxFileSize
  ) {
    return jsonResponse(
      {
        ok: false,
        error:
          "File exceeds the maximum allowed size.",
      },
      413,
    );
  }

  const result =
    await env.PROJECT_DELIVERIES.put(
      storagePath,
      bytes,
      {
        httpMetadata: {
          contentType,
        },
        customMetadata: {
          uploadedBy:
            "versin-api",
        },
      },
    );

  return jsonResponse(
    {
      ok: true,
      storagePath,
      size:
        result.size,
      etag:
        result.etag,
      uploaded:
        new Date().toISOString(),
    },
    201,
  );
}

// ============================================================
// DOWNLOAD
// ============================================================
//
// GET /object?path=...
//
// ============================================================

async function handleDownload(
  request,
  env,
  url,
) {
  const storagePath =
    normalizeStoragePath(
      url.searchParams.get(
        "path",
      ),
    );

  if (!storagePath) {
    return jsonResponse(
      {
        ok: false,
        error:
          "Missing or invalid path.",
      },
      400,
    );
  }

  const object =
    await env.PROJECT_DELIVERIES.get(
      storagePath,
    );

  if (!object) {
    return jsonResponse(
      {
        ok: false,
        error:
          "Object not found.",
      },
      404,
    );
  }

  const headers =
    new Headers();

  object.writeHttpMetadata(
    headers,
  );

  headers.set(
    "etag",
    object.httpEtag,
  );

  headers.set(
    "cache-control",
    "private, no-store",
  );

  headers.set(
    "content-length",
    String(
      object.size,
    ),
  );

  return new Response(
    object.body,
    {
      status: 200,
      headers,
    },
  );
}

// ============================================================
// HEAD
// ============================================================
//
// HEAD /object?path=...
//
// ============================================================

async function handleHead(
  env,
  url,
) {
  const storagePath =
    normalizeStoragePath(
      url.searchParams.get(
        "path",
      ),
    );

  if (!storagePath) {
    return new Response(
      null,
      {
        status: 400,
      },
    );
  }

  const object =
    await env.PROJECT_DELIVERIES.head(
      storagePath,
    );

  if (!object) {
    return new Response(
      null,
      {
        status: 404,
      },
    );
  }

  const headers =
    new Headers();

  object.writeHttpMetadata(
    headers,
  );

  headers.set(
    "etag",
    object.httpEtag,
  );

  headers.set(
    "content-length",
    String(
      object.size,
    ),
  );

  return new Response(
    null,
    {
      status: 200,
      headers,
    },
  );
}

// ============================================================
// DELETE
// ============================================================
//
// DELETE /object?path=...
//
// Use apenas para rollback de upload ainda não formalizado.
//
// ============================================================

async function handleDelete(
  env,
  url,
) {
  const storagePath =
    normalizeStoragePath(
      url.searchParams.get(
        "path",
      ),
    );

  if (!storagePath) {
    return jsonResponse(
      {
        ok: false,
        error:
          "Missing or invalid path.",
      },
      400,
    );
  }

  const existing =
    await env.PROJECT_DELIVERIES.head(
      storagePath,
    );

  if (!existing) {
    return jsonResponse(
      {
        ok: true,
        deleted:
          false,
        storagePath,
      },
      200,
    );
  }

  await env.PROJECT_DELIVERIES.delete(
    storagePath,
  );

  return jsonResponse(
    {
      ok: true,
      deleted:
        true,
      storagePath,
    },
    200,
  );
}

// ============================================================
// STORAGE PATH
// ============================================================

function normalizeStoragePath(
  value,
) {
  const normalized =
    String(
      value ?? "",
    )
      .trim()
      .replace(
        /^\/+/,
        "",
      );

  if (!normalized) {
    return null;
  }

  if (
    normalized.includes(
      "..",
    )
  ) {
    return null;
  }

  if (
    normalized.includes(
      "\\",
    )
  ) {
    return null;
  }

  if (
    normalized.length >
    1024
  ) {
    return null;
  }

  const parts =
    normalized
      .split("/")
      .filter(
        Boolean,
      );

  // Esperamos pelo menos:
  //
  // projectId/
  // userId/
  // contributionId/
  // v1/
  // arquivo

  if (
    parts.length <
    5
  ) {
    return null;
  }

  return parts.join("/");
}

// ============================================================
// CONTENT TYPE
// ============================================================

function normalizeContentType(
  value,
) {
  const normalized =
    String(
      value ?? "",
    ).trim();

  if (!normalized) {
    return "application/octet-stream";
  }

  if (
    normalized.length >
    120
  ) {
    return "application/octet-stream";
  }

  return normalized;
}

// ============================================================
// JSON RESPONSE
// ============================================================

function jsonResponse(
  data,
  status = 200,
) {
  return new Response(
    JSON.stringify(
      data,
    ),
    {
      status,
      headers: {
        "content-type":
          "application/json; charset=utf-8",

        "cache-control":
          "no-store",
      },
    },
  );
}