import { createClient } from '@supabase/supabase-js';
import { AwsClient } from 'aws4fetch';

// ============================================================
// DELETE PROFILE TRACK
// ============================================================
//
// Fluxo:
//
// Flutter
//   ↓
// delete-profile-track
//   ↓
// valida JWT
//   ↓
// busca profile_tracks
//   ↓
// confirma user_id == auth.uid()
//   ↓
// remove arquivo do Cloudflare R2
//   ↓
// remove registro do Supabase Postgres
//
// IMPORTANTE:
//
// O Flutter envia apenas:
//
// {
//   "trackId": "..."
// }
//
// O objectKey NÃO é confiado ao cliente.
// Ele é obtido diretamente de:
//
// public.profile_tracks.storage_path
//
// ============================================================

// ============================================================
// CORS
// ============================================================

const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin':
    '*',

  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',

  'Access-Control-Allow-Methods':
    'POST, OPTIONS',
};

// ============================================================
// RESPONSE
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
      status,

      headers: {
        ...corsHeaders,

        'Content-Type':
          'application/json',
      },
    },
  );
}

// ============================================================
// ENV
// ============================================================

function requiredEnv(
  name: string,
): string {
  const value =
    Deno.env
      .get(
        name,
      )
      ?.trim();

  if (!value) {
    throw new Error(
      `Variável de ambiente ausente: ${name}`,
    );
  }

  return value;
}

// ============================================================
// OBJECT KEY
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
      ) =>
        encodeURIComponent(
          segment,
        ),
    )
    .join(
      '/',
    );
}

// ============================================================
// BODY
// ============================================================

type DeleteTrackRequestBody = {
  trackId?: unknown;
};

// ============================================================
// TRACK ROW
// ============================================================

type TrackRow = {
  id: string;
  user_id: string;
  storage_path: string;
};

// ============================================================
// EDGE FUNCTION
// ============================================================

Deno.serve(
  async (
    request: Request,
  ): Promise<Response> => {
    // ==========================================================
    // CORS
    // ==========================================================

    if (
      request.method ===
      'OPTIONS'
    ) {
      return new Response(
        'ok',
        {
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
      // SUPABASE ENV
      // ========================================================

      const supabaseUrl =
        requiredEnv(
          'SUPABASE_URL',
        );

      const supabaseAnonKey =
        requiredEnv(
          'SUPABASE_ANON_KEY',
        );

      // ========================================================
      // AUTHORIZATION
      // ========================================================

      const authorization =
        request.headers.get(
          'Authorization',
        );

      if (!authorization) {
        return jsonResponse(
          {
            error:
              'Usuário não autenticado.',
          },
          401,
        );
      }

      // ========================================================
      // USER CLIENT
      // ========================================================
      //
      // Esse cliente respeita o JWT do usuário e as policies RLS.
      //
      // ========================================================

      const supabase =
        createClient(
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
            },
          },
        );

      // ========================================================
      // AUTH USER
      // ========================================================

      const {
        data:
          userData,
        error:
          userError,
      } =
        await supabase.auth.getUser();

      if (
        userError ||
        !userData.user
      ) {
        console.error(
          '[TRACK DELETE] Auth:',
          userError,
        );

        return jsonResponse(
          {
            error:
              'Sessão inválida.',
          },
          401,
        );
      }

      const userId =
        userData.user.id;

      // ========================================================
      // BODY
      // ========================================================

      let body:
        DeleteTrackRequestBody;

      try {
        body =
          await request.json();
      } catch {
        return jsonResponse(
          {
            error:
              'JSON inválido.',
          },
          400,
        );
      }

      // ========================================================
      // TRACK ID
      // ========================================================

      const rawTrackId =
        body.trackId;

      if (
        typeof rawTrackId !==
          'string' ||
        rawTrackId
          .trim()
          .length ===
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

      const trackId =
        rawTrackId.trim();

      // ========================================================
      // BUSCAR TRACK
      // ========================================================

      const {
        data:
          trackData,
        error:
          trackError,
      } =
        await supabase
          .from(
            'profile_tracks',
          )
          .select(
            `
            id,
            user_id,
            storage_path
            `,
          )
          .eq(
            'id',
            trackId,
          )
          .maybeSingle();

      if (trackError) {
        console.error(
          '[TRACK DELETE] '
            + 'Erro ao buscar track:',
          trackError,
        );

        return jsonResponse(
          {
            error:
              'Não foi possível localizar a música.',
          },
          500,
        );
      }

      if (!trackData) {
        return jsonResponse(
          {
            error:
              'Música não encontrada.',
          },
          404,
        );
      }

      const track =
        trackData as TrackRow;

      // ========================================================
      // VALIDAR PROPRIETÁRIO
      // ========================================================

      if (
        track.user_id !==
        userId
      ) {
        console.warn(
          '[TRACK DELETE] '
            + 'Tentativa não autorizada.',
          {
            userId,
            trackId,
          },
        );

        return jsonResponse(
          {
            error:
              'Você não pode excluir esta música.',
          },
          403,
        );
      }

      // ========================================================
      // STORAGE PATH
      // ========================================================

      const objectKey =
        track.storage_path
          ?.trim();

      if (!objectKey) {
        return jsonResponse(
          {
            error:
              'A música não possui storage_path válido.',
          },
          500,
        );
      }

      // ========================================================
      // SEGURANÇA EXTRA DO PATH
      // ========================================================
      //
      // Mesmo vindo do banco, exigimos que a chave esteja dentro
      // da pasta do próprio usuário.
      //
      // ========================================================

      const expectedPrefix =
        `profiles/${userId}/tracks/`;

      if (
        !objectKey.startsWith(
          expectedPrefix,
        )
      ) {
        console.error(
          '[TRACK DELETE] '
            + 'Object key fora do prefixo esperado.',
          {
            userId,
            trackId,
            objectKey,
          },
        );

        return jsonResponse(
          {
            error:
              'Caminho do arquivo inválido.',
          },
          500,
        );
      }

      // ========================================================
      // R2 ENV
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
      // R2 URL
      // ========================================================

      const encodedObjectKey =
        encodeObjectKey(
          objectKey,
        );

      const endpoint =
        `https://${accountId}.r2.cloudflarestorage.com`;

      const objectUrl =
        `${endpoint}/${bucket}/${encodedObjectKey}`;

      // ========================================================
      // AWS CLIENT
      // ========================================================

      const awsClient =
        new AwsClient({
          service:
            's3',

          region:
            'auto',

          accessKeyId,

          secretAccessKey,
        });

      // ========================================================
      // DELETE R2
      // ========================================================

      const unsignedDeleteRequest =
        new Request(
          objectUrl,
          {
            method:
              'DELETE',
          },
        );

      const signedDeleteRequest =
        await awsClient.sign(
          unsignedDeleteRequest,
        );

      const r2Response =
        await fetch(
          signedDeleteRequest,
        );

      // ========================================================
      // VALIDAR DELETE R2
      // ========================================================

      if (
        !r2Response.ok
      ) {
        const responseText =
          await r2Response.text();

        console.error(
          '[TRACK DELETE] '
            + 'Erro no R2:',
          {
            status:
              r2Response.status,

            response:
              responseText,

            objectKey,
          },
        );

        return jsonResponse(
          {
            error:
              'Não foi possível remover o arquivo.',
          },
          502,
        );
      }

      // ========================================================
      // REMOVER DO POSTGRES
      // ========================================================
      //
      // Só removemos a linha depois que o arquivo foi removido.
      //
      // ========================================================

      const {
        error:
          deleteDatabaseError,
      } =
        await supabase
          .from(
            'profile_tracks',
          )
          .delete()
          .eq(
            'id',
            trackId,
          )
          .eq(
            'user_id',
            userId,
          );

      if (
        deleteDatabaseError
      ) {
        console.error(
          '[TRACK DELETE] '
            + 'Arquivo removido do R2, '
            + 'mas banco falhou:',
          deleteDatabaseError,
        );

        return jsonResponse(
          {
            error:
              'O arquivo foi removido, mas não foi possível atualizar o banco.',

            code:
              'DATABASE_DELETE_FAILED',
          },
          500,
        );
      }

      // ========================================================
      // LOG
      // ========================================================

      console.log(
        '[TRACK DELETE] '
          + 'Track removida.',
        {
          userId,
          trackId,
          objectKey,
        },
      );

      // ========================================================
      // SUCCESS
      // ========================================================

      return jsonResponse(
        {
          success:
            true,

          trackId,

          objectKey,
        },
      );
    } catch (
      error
    ) {
      console.error(
        '[TRACK DELETE] '
          + 'Erro interno:',
        error,
      );

      return jsonResponse(
        {
          error:
            'Não foi possível excluir a música.',
        },
        500,
      );
    }
  },
);