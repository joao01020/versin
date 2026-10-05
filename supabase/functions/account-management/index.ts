import { createClient } from '@supabase/supabase-js';
import { AwsClient } from 'aws4fetch';

const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

type Action =
  | 'delete_data'
  | 'delete_account';

type StoredWorkRow = {
  id: string;
  original_author_user_id: string | null;
  owner_user_id: string;
  file_path: string | null;
};

type TrackRow = {
  id: string;
  storage_path: string;
};

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', {
      headers: corsHeaders,
    });
  }

  if (request.method !== 'POST') {
    return jsonResponse(
      {
        error: 'Método não permitido.',
        code: 'METHOD_NOT_ALLOWED',
      },
      405,
    );
  }

  try {
    const supabaseUrl =
      requiredEnv('SUPABASE_URL');

    const anonKey =
      requiredEnv('SUPABASE_ANON_KEY');

    const serviceRoleKey =
      requiredEnv('SUPABASE_SERVICE_ROLE_KEY');

    const authorization =
      request.headers.get('Authorization')?.trim();

    if (!authorization) {
      return jsonResponse(
        {
          error: 'Sessão ausente.',
          code: 'MISSING_AUTHORIZATION',
        },
        401,
      );
    }

    const userClient =
      createClient(
        supabaseUrl,
        anonKey,
        {
          global: {
            headers: {
              Authorization: authorization,
            },
          },
          auth: {
            persistSession: false,
            autoRefreshToken: false,
          },
        },
      );

    const adminClient =
      createClient(
        supabaseUrl,
        serviceRoleKey,
        {
          auth: {
            persistSession: false,
            autoRefreshToken: false,
          },
        },
      );

    const {
      data: userData,
      error: userError,
    } =
      await userClient.auth.getUser();

    if (
      userError ||
      !userData.user
    ) {
      return jsonResponse(
        {
          error:
            'Sua sessão expirou. Entre novamente para continuar.',
          code: 'INVALID_SESSION',
        },
        401,
      );
    }

    const userId =
      userData.user.id;

    const body =
      await safeJson(request);

    const action =
      body.action as Action | undefined;

    if (
      action !== 'delete_data' &&
      action !== 'delete_account'
    ) {
      return jsonResponse(
        {
          error: 'Ação inválida.',
          code: 'INVALID_ACTION',
        },
        400,
      );
    }

    // ========================================================
    // LEVANTAR ARQUIVOS ANTES DE ALTERAR O BANCO
    // ========================================================

    const {
      data: tracks,
      error: tracksError,
    } =
      await adminClient
        .from('profile_tracks')
        .select('id, storage_path')
        .eq('user_id', userId);

    if (tracksError) {
      throw tracksError;
    }

    const {
      data: ownedWorks,
      error: worksError,
    } =
      await adminClient
        .from('stored_works')
        .select(
          'id, original_author_user_id, owner_user_id, file_path',
        )
        .eq('owner_user_id', userId);

    if (worksError) {
      throw worksError;
    }

    const transferredIn =
      (ownedWorks ?? [])
        .filter(
          (work: StoredWorkRow) =>
            work.original_author_user_id !==
            userId,
        );

    if (transferredIn.length > 0) {
      return jsonResponse(
        {
          error:
            'Você possui obra(s) recebida(s) por transferência. '
            + 'Transfira essas obras antes de excluir seus dados ou sua conta.',
          code: 'TRANSFERRED_WORK_OWNERSHIP_BLOCK',
        },
        409,
      );
    }

    // ========================================================
    // ARQUIVOS EXTERNOS
    // ========================================================

    await deleteAvatarFiles(
      adminClient,
      userId,
    );

    await deleteProfileTrackFiles(
      (tracks ?? []) as TrackRow[],
    );

    await deleteOwnedWorkFiles(
      (ownedWorks ?? []) as StoredWorkRow[],
      userId,
    );

    // ========================================================
    // EXCLUIR DADOS, MANTER CONTA
    // ========================================================

    if (action === 'delete_data') {
      const {
        error,
      } =
        await userClient.rpc(
          'delete_my_app_data',
        );

      if (error) {
        throw error;
      }

      return jsonResponse(
        {
          ok: true,
          action,
        },
      );
    }

    // ========================================================
    // EXCLUIR CONTA
    // ========================================================
    //
    // Primeiro removemos os dados elimináveis usando a sessão
    // válida do próprio usuário. Depois removemos auth.users.
    // Por último executamos uma limpeza idempotente via service_role.
    //
    // A service_role nunca sai desta Edge Function.
    // ========================================================

    const {
      error: appDataError,
    } =
      await userClient.rpc(
        'delete_my_app_data',
      );

    if (appDataError) {
      throw appDataError;
    }

    const {
      error: deleteUserError,
    } =
      await adminClient.auth.admin.deleteUser(
        userId,
      );

    if (deleteUserError) {
      throw deleteUserError;
    }

    const {
      error: finalizeError,
    } =
      await adminClient.rpc(
        'finalize_deleted_user',
        {
          p_user_id: userId,
        },
      );

    if (finalizeError) {
      console.error(
        '[ACCOUNT MANAGEMENT] '
          + 'Conta removida, mas limpeza final falhou:',
        finalizeError,
      );
    }

    return jsonResponse(
      {
        ok: true,
        action,
      },
    );
  } catch (error) {
    console.error(
      '[ACCOUNT MANAGEMENT]',
      error,
    );

    return jsonResponse(
      {
        error:
          'Não foi possível concluir a operação. '
          + 'Tente novamente.',
        code: 'ACCOUNT_MANAGEMENT_FAILED',
      },
      500,
    );
  }
});

// ============================================================
// SUPABASE STORAGE - AVATAR
// ============================================================

async function deleteAvatarFiles(
  adminClient: ReturnType<typeof createClient>,
  userId: string,
): Promise<void> {
  const {
    data,
    error,
  } =
    await adminClient.storage
      .from('avatars')
      .list(
        userId,
        {
          limit: 100,
        },
      );

  if (error) {
    // O bucket pode ainda não existir em ambientes novos.
    console.warn(
      '[ACCOUNT MANAGEMENT] '
        + 'Não foi possível listar avatar:',
      error.message,
    );

    return;
  }

  const paths =
    (data ?? [])
      .filter(
        (item) =>
          item.name &&
          item.name !== '.emptyFolderPlaceholder',
      )
      .map(
        (item) =>
          `${userId}/${item.name}`,
      );

  if (paths.length === 0) {
    return;
  }

  const {
    error: removeError,
  } =
    await adminClient.storage
      .from('avatars')
      .remove(paths);

  if (removeError) {
    throw removeError;
  }
}

// ============================================================
// CLOUDFLARE R2 - TRACKS
// ============================================================

async function deleteProfileTrackFiles(
  tracks: TrackRow[],
): Promise<void> {
  if (tracks.length === 0) {
    return;
  }

  const bucket =
    requiredEnv('R2_BUCKET');

  for (const track of tracks) {
    const objectKey =
      track.storage_path?.trim();

    if (!objectKey) {
      continue;
    }

    await deleteR2Object(
      bucket,
      objectKey,
    );
  }
}

// ============================================================
// CLOUDFLARE R2 - STORED WORKS
// ============================================================

async function deleteOwnedWorkFiles(
  works: StoredWorkRow[],
  userId: string,
): Promise<void> {
  if (works.length === 0) {
    return;
  }

  const bucket =
    requiredEnv('R2_WORKS_BUCKET');

  for (const work of works) {
    if (
      work.original_author_user_id !==
      userId
    ) {
      continue;
    }

    const objectKey =
      work.file_path?.trim();

    if (!objectKey) {
      continue;
    }

    await deleteR2Object(
      bucket,
      objectKey,
    );
  }
}

async function deleteR2Object(
  bucket: string,
  objectKey: string,
): Promise<void> {
  const accountId =
    requiredEnv('R2_ACCOUNT_ID');

  const accessKeyId =
    requiredEnv('R2_ACCESS_KEY_ID');

  const secretAccessKey =
    requiredEnv('R2_SECRET_ACCESS_KEY');

  const aws =
    new AwsClient({
      service: 's3',
      region: 'auto',
      accessKeyId,
      secretAccessKey,
    });

  const encodedKey =
    objectKey
      .split('/')
      .map(encodeURIComponent)
      .join('/');

  const objectUrl =
    `https://${accountId}.r2.cloudflarestorage.com/`
    + `${encodeURIComponent(bucket)}/${encodedKey}`;

  const signed =
    await aws.sign(
      new Request(
        objectUrl,
        {
          method: 'DELETE',
        },
      ),
    );

  const response =
    await fetch(signed);

  if (
    !response.ok &&
    response.status !== 404
  ) {
    const detail =
      await response.text();

    throw new Error(
      `Falha ao excluir objeto R2 (${response.status}): ${detail}`,
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

function requiredEnv(
  name: string,
): string {
  const value =
    Deno.env.get(name)?.trim();

  if (!value) {
    throw new Error(
      `Variável obrigatória ausente: ${name}`,
    );
  }

  return value;
}

async function safeJson(
  request: Request,
): Promise<Record<string, unknown>> {
  try {
    const value =
      await request.json();

    if (
      value &&
      typeof value === 'object' &&
      !Array.isArray(value)
    ) {
      return value as Record<string, unknown>;
    }
  } catch (_) {
    // Retorna objeto vazio.
  }

  return {};
}

function jsonResponse(
  body: Record<string, unknown>,
  status = 200,
): Response {
  return new Response(
    JSON.stringify(body),
    {
      status,
      headers: {
        ...corsHeaders,
        'Content-Type':
          'application/json; charset=utf-8',
      },
    },
  );
}
