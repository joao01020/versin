-- ============================================================
-- VERSIN - ACCOUNT & PRIVACY HARDENING
-- 2026-09-06
--
-- Objetivos:
-- - permitir exclusão real de conta sem service_role no Flutter;
-- - preservar registros colaborativos/históricos de forma anonimizada;
-- - remover dados privados quando o usuário solicita;
-- - manter stored_works transferidos sem apagar conteúdo de terceiros;
-- - impedir exclusão de conta enquanto o usuário for o dono atual de
--   uma obra recebida por transferência (é necessário transferi-la antes).
-- ============================================================

begin;

-- ============================================================
-- SNAPSHOTS PARA O HISTÓRICO DE OBRAS
-- ============================================================

alter table public.stored_works
  add column if not exists original_author_name_snapshot text;

alter table public.work_transfers
  add column if not exists from_user_name_snapshot text;

alter table public.work_transfers
  add column if not exists to_user_name_snapshot text;

update public.stored_works sw
set original_author_name_snapshot = coalesce(
  nullif(trim(p.artist_name), ''),
  nullif(trim(p.name), ''),
  nullif(trim(p.username), ''),
  'Usuário removido'
)
from public.profiles p
where sw.original_author_user_id = p.id
  and sw.original_author_name_snapshot is null;

update public.work_transfers wt
set from_user_name_snapshot = coalesce(
  nullif(trim(p.artist_name), ''),
  nullif(trim(p.name), ''),
  nullif(trim(p.username), ''),
  'Usuário removido'
)
from public.profiles p
where wt.from_user_id = p.id
  and wt.from_user_name_snapshot is null;

update public.work_transfers wt
set to_user_name_snapshot = coalesce(
  nullif(trim(p.artist_name), ''),
  nullif(trim(p.name), ''),
  nullif(trim(p.username), ''),
  'Usuário removido'
)
from public.profiles p
where wt.to_user_id = p.id
  and wt.to_user_name_snapshot is null;

-- ============================================================
-- FKs HISTÓRICAS: ON DELETE SET NULL
-- ============================================================

alter table public.project_contributions
  alter column user_id drop not null;
alter table public.project_contributions
  drop constraint if exists project_contributions_user_id_fkey;
alter table public.project_contributions
  add constraint project_contributions_user_id_fkey
  foreign key (user_id)
  references auth.users(id)
  on delete set null;

alter table public.contribution_approvals
  alter column user_id drop not null;
alter table public.contribution_approvals
  drop constraint if exists contribution_approvals_user_id_fkey;
alter table public.contribution_approvals
  add constraint contribution_approvals_user_id_fkey
  foreign key (user_id)
  references auth.users(id)
  on delete set null;

alter table public.contribution_deliveries
  alter column uploaded_by drop not null;
alter table public.contribution_deliveries
  drop constraint if exists contribution_deliveries_uploaded_by_fkey;
alter table public.contribution_deliveries
  add constraint contribution_deliveries_uploaded_by_fkey
  foreign key (uploaded_by)
  references auth.users(id)
  on delete set null;

alter table public.delivery_approvals
  alter column user_id drop not null;
alter table public.delivery_approvals
  drop constraint if exists delivery_approvals_user_id_fkey;
alter table public.delivery_approvals
  add constraint delivery_approvals_user_id_fkey
  foreign key (user_id)
  references auth.users(id)
  on delete set null;

alter table public.project_record_events
  drop constraint if exists project_record_events_actor_user_id_fkey;
alter table public.project_record_events
  add constraint project_record_events_actor_user_id_fkey
  foreign key (actor_user_id)
  references auth.users(id)
  on delete set null;

alter table public.royalty_agreements
  alter column created_by drop not null;
alter table public.royalty_agreements
  drop constraint if exists royalty_agreements_created_by_fkey;
alter table public.royalty_agreements
  add constraint royalty_agreements_created_by_fkey
  foreign key (created_by)
  references auth.users(id)
  on delete set null;

alter table public.royalty_approvals
  alter column user_id drop not null;
alter table public.royalty_approvals
  drop constraint if exists royalty_approvals_user_id_fkey;
alter table public.royalty_approvals
  add constraint royalty_approvals_user_id_fkey
  foreign key (user_id)
  references auth.users(id)
  on delete set null;

alter table public.royalty_events
  drop constraint if exists royalty_events_actor_user_id_fkey;
alter table public.royalty_events
  add constraint royalty_events_actor_user_id_fkey
  foreign key (actor_user_id)
  references auth.users(id)
  on delete set null;

alter table public.royalty_shares
  alter column user_id drop not null;
alter table public.royalty_shares
  drop constraint if exists royalty_shares_user_id_fkey;
alter table public.royalty_shares
  add constraint royalty_shares_user_id_fkey
  foreign key (user_id)
  references auth.users(id)
  on delete set null;

alter table public.work_transfers
  alter column from_user_id drop not null;
alter table public.work_transfers
  alter column to_user_id drop not null;

alter table public.work_transfers
  drop constraint if exists work_transfers_from_user_id_fkey;
alter table public.work_transfers
  add constraint work_transfers_from_user_id_fkey
  foreign key (from_user_id)
  references auth.users(id)
  on delete set null;

alter table public.work_transfers
  drop constraint if exists work_transfers_to_user_id_fkey;
alter table public.work_transfers
  add constraint work_transfers_to_user_id_fkey
  foreign key (to_user_id)
  references auth.users(id)
  on delete set null;

-- O autor original pode desaparecer da autenticação, mas o snapshot fica.
alter table public.stored_works
  alter column original_author_user_id drop not null;

alter table public.stored_works
  drop constraint if exists stored_works_original_author_user_id_fkey;

alter table public.stored_works
  add constraint stored_works_original_author_user_id_fkey
  foreign key (original_author_user_id)
  references auth.users(id)
  on delete set null;

-- owner_user_id continua RESTRICT de propósito.
-- Uma conta que recebeu uma obra por transferência precisa resolver
-- a propriedade antes de ser excluída.

-- ============================================================
-- HELPER INTERNO
-- ============================================================

create or replace function public._delete_user_app_data_internal(
  p_user_id uuid,
  p_delete_profile boolean default false
)
returns void
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_remaining_members uuid[];
  v_remaining_founders uuid[];
begin
  if p_user_id is null then
    raise exception 'user_id inválido.';
  end if;

  -- ----------------------------------------------------------
  -- Proteger obras recebidas de terceiros
  -- ----------------------------------------------------------
  if exists (
    select 1
    from public.stored_works sw
    where sw.owner_user_id = p_user_id
      and sw.original_author_user_id is distinct from p_user_id
  ) then
    raise exception
      'Antes de excluir os dados, transfira as obras que você recebeu de outros usuários.'
      using errcode = 'P0001';
  end if;

  -- ----------------------------------------------------------
  -- Preservar snapshots antes de anonimizar
  -- ----------------------------------------------------------
  update public.stored_works sw
  set original_author_name_snapshot = coalesce(
    sw.original_author_name_snapshot,
    (
      select coalesce(
        nullif(trim(p.artist_name), ''),
        nullif(trim(p.name), ''),
        nullif(trim(p.username), ''),
        'Usuário removido'
      )
      from public.profiles p
      where p.id = p_user_id
    ),
    'Usuário removido'
  )
  where sw.original_author_user_id = p_user_id;

  update public.work_transfers wt
  set from_user_name_snapshot = coalesce(
    wt.from_user_name_snapshot,
    (
      select coalesce(
        nullif(trim(p.artist_name), ''),
        nullif(trim(p.name), ''),
        nullif(trim(p.username), ''),
        'Usuário removido'
      )
      from public.profiles p
      where p.id = p_user_id
    ),
    'Usuário removido'
  )
  where wt.from_user_id = p_user_id;

  update public.work_transfers wt
  set to_user_name_snapshot = coalesce(
    wt.to_user_name_snapshot,
    (
      select coalesce(
        nullif(trim(p.artist_name), ''),
        nullif(trim(p.name), ''),
        nullif(trim(p.username), ''),
        'Usuário removido'
      )
      from public.profiles p
      where p.id = p_user_id
    ),
    'Usuário removido'
  )
  where wt.to_user_id = p_user_id;

  -- ----------------------------------------------------------
  -- Sair de projetos sem apagar projetos compartilhados
  -- ----------------------------------------------------------
  update public.projects p
  set
    members = array_remove(
      coalesce(p.members, '{}'::uuid[]),
      p_user_id
    ),
    founders = case
      when cardinality(
        array_remove(
          coalesce(p.founders, '{}'::uuid[]),
          p_user_id
        )
      ) = 0
      and cardinality(
        array_remove(
          coalesce(p.members, '{}'::uuid[]),
          p_user_id
        )
      ) > 0
      then array[
        (
          array_remove(
            coalesce(p.members, '{}'::uuid[]),
            p_user_id
          )
        )[1]
      ]
      else array_remove(
        coalesce(p.founders, '{}'::uuid[]),
        p_user_id
      )
    end,
    status = case
      when cardinality(
        array_remove(
          coalesce(p.members, '{}'::uuid[]),
          p_user_id
        )
      ) = 0
      then 'closed'
      else p.status
    end,
    updated_at = now()
  where p_user_id = any(coalesce(p.members, '{}'::uuid[]))
     or p_user_id = any(coalesce(p.founders, '{}'::uuid[]));

  -- Projetos sem nenhum membro pertenciam somente ao usuário.
  delete from public.projects p
  where cardinality(coalesce(p.members, '{}'::uuid[])) = 0;

  -- ----------------------------------------------------------
  -- Dados pessoais
  -- ----------------------------------------------------------
  delete from public.calendar_event_members
  where user_id = p_user_id;

  delete from public.calendar_events
  where creator_id = p_user_id;

  delete from public.calendar_day_notes
  where user_id = p_user_id;

  delete from public.creative_activity_events
  where user_id = p_user_id;

  delete from public.favorites
  where sender_id = p_user_id
     or target_user_id = p_user_id;

  delete from public.match_passes
  where sender_id = p_user_id
     or target_user_id = p_user_id;

  delete from public.notification_reads
  where user_id = p_user_id;

  delete from public.recent_activities
  where user_id = p_user_id;

  delete from public.user_vocabulary
  where user_id = p_user_id;

  delete from public.lyrics_history
  where user_id = p_user_id;

  delete from public.wallet
  where wallet_id = p_user_id
     or user_id = p_user_id;

  delete from public.works
  where author_id = p_user_id;

  -- Arquivos externos são apagados pela Edge Function antes das linhas.
  delete from public.profile_tracks
  where user_id = p_user_id;

  -- Obras ainda do próprio autor são pessoais.
  delete from public.stored_works sw
  where sw.owner_user_id = p_user_id
    and sw.original_author_user_id = p_user_id;

  -- Obra já transferida para outra pessoa: preservar, mas anonimizar autor.
  update public.stored_works
  set original_author_user_id = null
  where original_author_user_id = p_user_id
    and owner_user_id is distinct from p_user_id;

  -- ----------------------------------------------------------
  -- Comunicação / convites
  -- ----------------------------------------------------------
  delete from public.call_participants
  where user_id = p_user_id;

  delete from public.communication_permissions
  where user_id = p_user_id;

  delete from public.communication_requests
  where sender_id = p_user_id
     or target_user_id = p_user_id;

  delete from public.communication_video_invite_states
  where requester_id = p_user_id
     or target_user_id = p_user_id;

  update public.communication_video_invite_states
  set reopened_by = null
  where reopened_by = p_user_id;

  delete from public.communication_video_permissions
  where user_a_id = p_user_id
     or user_b_id = p_user_id;

  update public.communication_video_permissions
  set video_revoked_by = null
  where video_revoked_by = p_user_id;

  delete from public.project_calls
  where created_by = p_user_id;

  update public.project_calls
  set target_user_id = null
  where target_user_id = p_user_id;

  delete from public.project_invitations
  where invited_by = p_user_id
     or invited_user_id = p_user_id;

  delete from public.project_messages
  where sender_id = p_user_id;

  delete from public.project_recruitment_candidates
  where user_id = p_user_id;

  update public.project_recruitment_candidates
  set invited_by = null
  where invited_by = p_user_id;

  delete from public.project_recruitments
  where created_by = p_user_id;

  delete from public.system_notifications
  where target_user_id = p_user_id;

  -- ----------------------------------------------------------
  -- Registros compartilhados / históricos: anonimizar
  -- ----------------------------------------------------------
  update public.project_contributions
  set user_id = null
  where user_id = p_user_id;

  update public.contribution_approvals
  set user_id = null
  where user_id = p_user_id;

  update public.contribution_deliveries
  set uploaded_by = null
  where uploaded_by = p_user_id;

  update public.delivery_approvals
  set user_id = null
  where user_id = p_user_id;

  update public.project_record_events
  set actor_user_id = null
  where actor_user_id = p_user_id;

  update public.royalty_agreements
  set created_by = null
  where created_by = p_user_id;

  update public.royalty_approvals
  set user_id = null
  where user_id = p_user_id;

  update public.royalty_events
  set actor_user_id = null
  where actor_user_id = p_user_id;

  update public.royalty_shares
  set user_id = null
  where user_id = p_user_id;

  update public.work_transfers
  set from_user_id = null
  where from_user_id = p_user_id;

  update public.work_transfers
  set to_user_id = null
  where to_user_id = p_user_id;

  -- ----------------------------------------------------------
  -- Perfil
  -- ----------------------------------------------------------
  if p_delete_profile then
    delete from public.profiles
    where id = p_user_id;
  else
    update public.profiles
    set
      username = null,
      name = null,
      "profiles.role" = 'artist',
      is_online = false,
      settings = '{"mode":"Rhyme"}'::jsonb,
      tags = '{}'::text[],
      bio = null,
      showcase_url = null,
      showcase_desc = null,
      wallet_address = null,
      ia_memory = '10',
      avatar_url = 'NULL',
      artist_name = null,
      artist_name_updated_at = null,
      primary_role = null,
      roles = '{}'::text[],
      looking_for_roles = '{}'::text[],
      welcome_activity_due_at = null,
      welcome_activity_sent_at = null,
      latitude = null,
      longitude = null,
      location_enabled = false,
      location_updated_at = null,
      nearby_location_consent = false,
      nearby_location_consent_at = null,
      nearby_location_consent_version = null,
      last_seen_at = null,
      available_now = false,
      available_until = null,
      updated_at = now()
    where id = p_user_id;
  end if;
end;
$$;

revoke all on function public._delete_user_app_data_internal(uuid, boolean)
from public, anon, authenticated;

-- ============================================================
-- RPC DO USUÁRIO: EXCLUIR DADOS, MANTER LOGIN
-- ============================================================

create or replace function public.delete_my_app_data()
returns void
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Usuário não autenticado.'
      using errcode = '42501';
  end if;

  perform public._delete_user_app_data_internal(
    v_user_id,
    false
  );
end;
$$;

revoke all on function public.delete_my_app_data()
from public, anon;

grant execute on function public.delete_my_app_data()
to authenticated;

-- ============================================================
-- RPC SERVIDOR: FINALIZAR USUÁRIO JÁ REMOVIDO DO AUTH
-- ============================================================

create or replace function public.finalize_deleted_user(
  p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
begin
  perform public._delete_user_app_data_internal(
    p_user_id,
    true
  );
end;
$$;

revoke all on function public.finalize_deleted_user(uuid)
from public, anon, authenticated;

grant execute on function public.finalize_deleted_user(uuid)
to service_role;

commit;
