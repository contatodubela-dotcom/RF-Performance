-- ============================================================================
-- RF Performance — Avaliações e Certificações — Fase 1D
-- Controle privado de acesso piloto individual
--
-- Objetivos:
--   1. criar uma lista privada e auditável de liberação por versão;
--   2. aplicar bloqueio por padrão nas RPCs de listagem e início;
--   3. liberar somente o Teste 1 ao Usuário Teste RF;
--   4. manter teste e versão em rascunho nesta migration.
--
-- Esta migration NÃO publica avaliações e NÃO cria tentativas.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- Preflight estrito do piloto e do catálogo
-- ----------------------------------------------------------------------------

do $preflight$
declare
  v_linked_questions integer;
  v_private_keys integer;
  v_attempts integer;
begin
  if not exists (
    select 1
    from public.organizations o
    where o.id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and o.status = 'active'
  ) then
    raise exception 'PILOT_ORGANIZATION_NOT_ACTIVE';
  end if;

  if not exists (
    select 1
    from public.organization_members om
    join public.profiles p
      on p.id = om.user_id
     and p.status = 'active'
     and p.archived_at is null
    where om.id = '49239d09-0f85-471f-8f46-5c240cd98600'::uuid
      and om.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and om.user_id = 'e88242b6-e44e-4de7-97cf-dbefc0605eaf'::uuid
      and om.role = 'salesperson'
      and om.status = 'active'
      and om.archived_at is null
  ) then
    raise exception 'PILOT_MEMBER_NOT_ACTIVE_OR_MISMATCHED';
  end if;

  if not exists (
    select 1
    from public.assessment_tests t
    where t.id = '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
      and t.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and t.sequence_no = 1
      and t.code = 'teste_1_diagnostico'
      and t.purpose = 'diagnostic'
      and t.status = 'draft'
      and t.archived_at is null
  ) then
    raise exception 'PILOT_TEST_PREFLIGHT_FAILED';
  end if;

  if not exists (
    select 1
    from public.assessment_test_versions tv
    where tv.id = 'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
      and tv.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and tv.test_id = '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
      and tv.version_code = '2026.08-v1'
      and tv.status = 'draft'
      and tv.question_count = 30
      and tv.archived_at is null
  ) then
    raise exception 'PILOT_VERSION_PREFLIGHT_FAILED';
  end if;

  select count(*)::integer
  into v_linked_questions
  from public.assessment_version_questions avq
  where avq.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and avq.test_version_id = 'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
    and avq.archived_at is null;

  if v_linked_questions <> 30 then
    raise exception 'PILOT_VERSION_QUESTION_COUNT_MISMATCH: %', v_linked_questions;
  end if;

  select count(*)::integer
  into v_private_keys
  from public.assessment_version_questions avq
  join private.assessment_question_keys aqk
    on aqk.organization_id = avq.organization_id
   and aqk.question_id = avq.question_id
  where avq.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and avq.test_version_id = 'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
    and avq.archived_at is null;

  if v_private_keys <> 30 then
    raise exception 'PILOT_VERSION_PRIVATE_KEY_COUNT_MISMATCH: %', v_private_keys;
  end if;

  select count(*)::integer
  into v_attempts
  from public.assessment_attempts aa
  where aa.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and aa.test_id = '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
    and aa.archived_at is null;

  if v_attempts <> 0 then
    raise exception 'PILOT_TEST_ALREADY_HAS_ATTEMPTS: %', v_attempts;
  end if;
end;
$preflight$;

-- ----------------------------------------------------------------------------
-- Lista privada de liberação por versão
-- ----------------------------------------------------------------------------

create table private.assessment_test_access_grants (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations(id),
  test_id uuid not null
    references public.assessment_tests(id),
  test_version_id uuid not null
    references public.assessment_test_versions(id),
  access_scope text not null
    check (access_scope in ('member', 'organization')),
  organization_member_id uuid null
    references public.organization_members(id),
  status text not null default 'active'
    check (status in ('active', 'revoked')),
  valid_from timestamptz null,
  valid_until timestamptz null,
  reason text not null,
  created_at timestamptz not null default now(),
  created_by uuid null,
  updated_at timestamptz not null default now(),
  updated_by uuid null,
  archived_at timestamptz null,
  metadata jsonb not null default '{}'::jsonb,

  constraint assessment_test_access_grants_scope_member_check
    check (
      (access_scope = 'member' and organization_member_id is not null)
      or
      (access_scope = 'organization' and organization_member_id is null)
    ),

  constraint assessment_test_access_grants_validity_check
    check (
      valid_until is null
      or valid_from is null
      or valid_until > valid_from
    )
);

comment on table private.assessment_test_access_grants is
  'Liberações privadas e auditáveis de versões de avaliações por membro ou organização.';

comment on column private.assessment_test_access_grants.access_scope is
  'member para liberação individual; organization para liberação geral futura.';

create unique index assessment_test_access_grants_member_active_uidx
  on private.assessment_test_access_grants (
    organization_id,
    test_version_id,
    organization_member_id
  )
  where access_scope = 'member'
    and status = 'active'
    and archived_at is null;

create unique index assessment_test_access_grants_organization_active_uidx
  on private.assessment_test_access_grants (
    organization_id,
    test_version_id
  )
  where access_scope = 'organization'
    and status = 'active'
    and archived_at is null;

create index assessment_test_access_grants_lookup_idx
  on private.assessment_test_access_grants (
    organization_id,
    test_id,
    test_version_id,
    status
  )
  where archived_at is null;

revoke all on table private.assessment_test_access_grants
  from public, anon, authenticated;

-- ----------------------------------------------------------------------------
-- Helper privado: bloqueio por padrão
-- ----------------------------------------------------------------------------

create or replace function private.assessment_test_access_allowed(
  p_organization_id uuid,
  p_organization_member_id uuid,
  p_test_id uuid,
  p_test_version_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select exists (
    select 1
    from public.organization_members om
    join public.profiles p
      on p.id = om.user_id
     and p.status = 'active'
     and p.archived_at is null
    join public.assessment_tests t
      on t.id = p_test_id
     and t.organization_id = p_organization_id
     and t.archived_at is null
    join public.assessment_test_versions tv
      on tv.id = p_test_version_id
     and tv.organization_id = p_organization_id
     and tv.test_id = p_test_id
     and tv.archived_at is null
    join private.assessment_test_access_grants access_grant
      on access_grant.organization_id = p_organization_id
     and access_grant.test_id = p_test_id
     and access_grant.test_version_id = p_test_version_id
     and access_grant.status = 'active'
     and access_grant.archived_at is null
     and (
       access_grant.valid_from is null
       or access_grant.valid_from <= now()
     )
     and (
       access_grant.valid_until is null
       or access_grant.valid_until > now()
     )
     and (
       (
         access_grant.access_scope = 'member'
         and access_grant.organization_member_id = p_organization_member_id
       )
       or
       (
         access_grant.access_scope = 'organization'
         and access_grant.organization_member_id is null
       )
     )
    where om.id = p_organization_member_id
      and om.organization_id = p_organization_id
      and om.status = 'active'
      and om.archived_at is null
  );
$$;

comment on function private.assessment_test_access_allowed(
  uuid,
  uuid,
  uuid,
  uuid
) is
  'Retorna true somente quando há liberação privada ativa para a versão e o membro está ativo.';

revoke all on function private.assessment_test_access_allowed(
  uuid,
  uuid,
  uuid,
  uuid
) from public, anon, authenticated;

-- ----------------------------------------------------------------------------
-- Grant individual do piloto
-- ----------------------------------------------------------------------------

insert into private.assessment_test_access_grants (
  id,
  organization_id,
  test_id,
  test_version_id,
  access_scope,
  organization_member_id,
  status,
  valid_from,
  valid_until,
  reason,
  created_by,
  updated_by,
  metadata
)
values (
  '986fbc2a-bc95-4930-a827-25d92cdf3cf4'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid,
  'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid,
  'member',
  '49239d09-0f85-471f-8f46-5c240cd98600'::uuid,
  'active',
  now(),
  null,
  'Homologação controlada da Fase 1D com o Usuário Teste RF.',
  null,
  null,
  jsonb_build_object(
    'phase', '1D',
    'pilot', true,
    'pilot_user_id', 'e88242b6-e44e-4de7-97cf-dbefc0605eaf',
    'pilot_email', 'empilhaplus@gmail.com',
    'migration', '20260806023000_avaliacoes_certificacao_fase1d_acesso_piloto_individual'
  )
);

-- ----------------------------------------------------------------------------
-- RPC de listagem: somente versões publicadas E liberadas
-- ----------------------------------------------------------------------------

create or replace function public.get_available_assessments(
  p_organization_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $$
declare
  v_user_id uuid := auth.uid();
  v_member_id uuid;
  v_tests jsonb;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  select om.id
  into v_member_id
  from public.organization_members om
  join public.profiles p
    on p.id = om.user_id
   and p.status = 'active'
   and p.archived_at is null
  where om.organization_id = p_organization_id
    and om.user_id = v_user_id
    and om.status = 'active'
    and om.archived_at is null;

  if v_member_id is null then
    raise exception 'ACTIVE_MEMBERSHIP_REQUIRED' using errcode = '42501';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'test_id', t.id,
        'test_code', t.code,
        'sequence_no', t.sequence_no,
        'title', t.title,
        'description', t.description,
        'purpose', t.purpose,
        'difficulty', t.difficulty,
        'question_count', tv.question_count,
        'time_limit_minutes', t.time_limit_minutes,
        'max_attempts', t.max_attempts,
        'cooldown_hours', t.cooldown_hours,
        'version_id', tv.id,
        'version_code', tv.version_code,
        'passing_score', tv.passing_score,
        'legal_min_score', tv.legal_min_score,
        'prerequisites_met', private.assessment_prerequisites_met(
          p_organization_id,
          v_member_id,
          t.id
        ),
        'attempts_used', coalesce(attempt_summary.attempts_used, 0),
        'in_progress_attempt_id', attempt_summary.in_progress_attempt_id,
        'last_attempt_status', attempt_summary.last_attempt_status,
        'last_attempt_passed', attempt_summary.last_attempt_passed,
        'next_attempt_at', attempt_summary.next_attempt_at,
        'availability', case
          when not private.assessment_prerequisites_met(
            p_organization_id,
            v_member_id,
            t.id
          ) then 'locked_prerequisite'
          when attempt_summary.in_progress_attempt_id is not null then 'in_progress'
          when coalesce(attempt_summary.attempts_used, 0) >= t.max_attempts then 'attempts_exhausted'
          when attempt_summary.next_attempt_at is not null
               and attempt_summary.next_attempt_at > now() then 'cooldown'
          else 'available'
        end
      )
      order by t.sequence_no
    ),
    '[]'::jsonb
  )
  into v_tests
  from public.assessment_tests t
  join public.assessment_test_versions tv
    on tv.test_id = t.id
   and tv.organization_id = t.organization_id
   and tv.status = 'published'
   and tv.archived_at is null
   and (tv.valid_from is null or tv.valid_from <= now())
   and (tv.valid_until is null or tv.valid_until >= now())
  left join lateral (
    select
      count(*) filter (where a.status <> 'cancelled')::integer as attempts_used,
      (
        array_agg(a.id order by a.started_at desc) filter (
          where a.status = 'in_progress'
            and (a.expires_at is null or a.expires_at > now())
        )
      )[1] as in_progress_attempt_id,
      (array_agg(a.status order by a.started_at desc))[1] as last_attempt_status,
      (array_agg(a.passed order by a.started_at desc))[1] as last_attempt_passed,
      max(coalesce(a.graded_at, a.submitted_at, a.started_at)) filter (
        where a.status in ('graded', 'submitted', 'expired')
      ) + make_interval(hours => t.cooldown_hours) as next_attempt_at
    from public.assessment_attempts a
    where a.organization_id = p_organization_id
      and a.organization_member_id = v_member_id
      and a.test_version_id = tv.id
      and a.archived_at is null
  ) attempt_summary on true
  where t.organization_id = p_organization_id
    and t.status = 'active'
    and t.archived_at is null
    and private.assessment_test_access_allowed(
      p_organization_id,
      v_member_id,
      t.id,
      tv.id
    );

  return jsonb_build_object(
    'organization_id', p_organization_id,
    'organization_member_id', v_member_id,
    'tests', v_tests
  );
end;
$$;

-- ----------------------------------------------------------------------------
-- RPC de início: impede acesso direto sem grant
-- ----------------------------------------------------------------------------

create or replace function public.start_assessment_attempt(
  p_organization_id uuid,
  p_test_id uuid
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = pg_catalog, public, private
as $$
declare
  v_user_id uuid := auth.uid();
  v_member_id uuid;
  v_test_id uuid;
  v_version_id uuid;
  v_question_count integer;
  v_time_limit_minutes integer;
  v_max_attempts integer;
  v_cooldown_hours integer;
  v_randomize_questions boolean;
  v_randomize_options boolean;
  v_existing_attempt_id uuid;
  v_attempts_used integer;
  v_last_terminal_at timestamptz;
  v_attempt_no integer;
  v_attempt_id uuid;
  v_inserted_items integer;
  v_catalog_questions integer;
  v_private_keys integer;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  select om.id
  into v_member_id
  from public.organization_members om
  join public.profiles p
    on p.id = om.user_id
   and p.status = 'active'
   and p.archived_at is null
  where om.organization_id = p_organization_id
    and om.user_id = v_user_id
    and om.status = 'active'
    and om.archived_at is null;

  if v_member_id is null then
    raise exception 'ACTIVE_MEMBERSHIP_REQUIRED' using errcode = '42501';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(
      p_organization_id::text || ':' || v_member_id::text || ':' || p_test_id::text,
      0
    )
  );

  select
    t.id,
    tv.id,
    tv.question_count,
    t.time_limit_minutes,
    t.max_attempts,
    t.cooldown_hours,
    tv.randomize_questions,
    tv.randomize_options
  into
    v_test_id,
    v_version_id,
    v_question_count,
    v_time_limit_minutes,
    v_max_attempts,
    v_cooldown_hours,
    v_randomize_questions,
    v_randomize_options
  from public.assessment_tests t
  join public.assessment_test_versions tv
    on tv.test_id = t.id
   and tv.organization_id = t.organization_id
   and tv.status = 'published'
   and tv.archived_at is null
   and (tv.valid_from is null or tv.valid_from <= now())
   and (tv.valid_until is null or tv.valid_until >= now())
  where t.id = p_test_id
    and t.organization_id = p_organization_id
    and t.status = 'active'
    and t.archived_at is null;

  if v_version_id is null then
    raise exception 'ASSESSMENT_NOT_PUBLISHED' using errcode = 'P0001';
  end if;

  if not private.assessment_test_access_allowed(
    p_organization_id,
    v_member_id,
    v_test_id,
    v_version_id
  ) then
    raise exception 'ASSESSMENT_ACCESS_NOT_GRANTED' using errcode = '42501';
  end if;

  if not private.assessment_prerequisites_met(
    p_organization_id,
    v_member_id,
    v_test_id
  ) then
    raise exception 'ASSESSMENT_PREREQUISITE_NOT_MET' using errcode = 'P0001';
  end if;

  update public.assessment_attempts
  set status = 'expired',
      updated_by = v_user_id,
      metadata = metadata || jsonb_build_object('expired_before_restart_at', now())
  where organization_id = p_organization_id
    and organization_member_id = v_member_id
    and test_version_id = v_version_id
    and status = 'in_progress'
    and expires_at is not null
    and expires_at <= now()
    and archived_at is null;

  select a.id
  into v_existing_attempt_id
  from public.assessment_attempts a
  where a.organization_id = p_organization_id
    and a.organization_member_id = v_member_id
    and a.test_version_id = v_version_id
    and a.status = 'in_progress'
    and (a.expires_at is null or a.expires_at > now())
    and a.archived_at is null
  order by a.started_at desc
  limit 1;

  if v_existing_attempt_id is not null then
    return public.get_assessment_attempt(v_existing_attempt_id);
  end if;

  select
    count(*) filter (where a.status <> 'cancelled')::integer,
    max(coalesce(a.graded_at, a.submitted_at, a.started_at)) filter (
      where a.status in ('graded', 'submitted', 'expired')
    ),
    coalesce(max(a.attempt_no), 0) + 1
  into v_attempts_used, v_last_terminal_at, v_attempt_no
  from public.assessment_attempts a
  where a.organization_id = p_organization_id
    and a.organization_member_id = v_member_id
    and a.test_version_id = v_version_id
    and a.archived_at is null;

  if coalesce(v_attempts_used, 0) >= v_max_attempts then
    raise exception 'ASSESSMENT_ATTEMPTS_EXHAUSTED' using errcode = 'P0001';
  end if;

  if v_last_terminal_at is not null
     and v_last_terminal_at + make_interval(hours => v_cooldown_hours) > now() then
    raise exception 'ASSESSMENT_COOLDOWN_ACTIVE' using errcode = 'P0001';
  end if;

  select count(*)
  into v_catalog_questions
  from public.assessment_version_questions vq
  join public.assessment_questions q
    on q.id = vq.question_id
   and q.organization_id = vq.organization_id
   and q.archived_at is null
  where vq.organization_id = p_organization_id
    and vq.test_version_id = v_version_id
    and vq.archived_at is null;

  select count(*)
  into v_private_keys
  from public.assessment_version_questions vq
  join private.assessment_question_keys qk
    on qk.question_id = vq.question_id
   and qk.organization_id = vq.organization_id
  where vq.organization_id = p_organization_id
    and vq.test_version_id = v_version_id
    and vq.archived_at is null;

  if v_catalog_questions <> v_question_count or v_private_keys <> v_question_count then
    raise exception 'ASSESSMENT_CATALOG_INTEGRITY_ERROR' using errcode = 'P0001';
  end if;

  insert into public.assessment_attempts (
    organization_id,
    test_id,
    test_version_id,
    organization_member_id,
    user_id,
    attempt_no,
    status,
    started_at,
    expires_at,
    total_questions,
    answered_questions,
    created_by,
    updated_by,
    metadata
  ) values (
    p_organization_id,
    v_test_id,
    v_version_id,
    v_member_id,
    v_user_id,
    v_attempt_no,
    'in_progress',
    now(),
    case
      when v_time_limit_minutes is null then null
      else now() + make_interval(mins => v_time_limit_minutes)
    end,
    0,
    0,
    v_user_id,
    v_user_id,
    jsonb_build_object('created_by_rpc', 'start_assessment_attempt')
  )
  returning id into v_attempt_id;

  with question_pool as (
    select
      vq.question_id,
      q.competency_id,
      q.block_code,
      q.prompt,
      vq.points,
      vq.sequence_no,
      case
        when v_randomize_questions then random()
        else vq.sequence_no::double precision
      end as question_sort
    from public.assessment_version_questions vq
    join public.assessment_questions q
      on q.id = vq.question_id
     and q.organization_id = vq.organization_id
     and q.archived_at is null
    where vq.organization_id = p_organization_id
      and vq.test_version_id = v_version_id
      and vq.archived_at is null
    order by question_sort, vq.sequence_no
    limit v_question_count
  ), numbered_questions as (
    select
      question_pool.*,
      row_number() over (order by question_sort, sequence_no)::integer as position_no
    from question_pool
  )
  insert into public.assessment_attempt_items (
    organization_id,
    attempt_id,
    question_id,
    competency_id,
    block_code,
    position_no,
    points,
    prompt_snapshot,
    options_snapshot,
    option_order,
    created_by,
    updated_by,
    metadata
  )
  select
    p_organization_id,
    v_attempt_id,
    nq.question_id,
    nq.competency_id,
    nq.block_code,
    nq.position_no,
    nq.points,
    nq.prompt,
    option_data.options_snapshot,
    option_data.option_order,
    v_user_id,
    v_user_id,
    jsonb_build_object('snapshot_version_id', v_version_id)
  from numbered_questions nq
  cross join lateral (
    select
      jsonb_object_agg(option_rows.option_code, option_rows.option_text order by option_rows.option_code)
        as options_snapshot,
      jsonb_agg(option_rows.option_code order by option_rows.option_sort, option_rows.option_code)
        as option_order
    from (
      select
        o.option_code,
        o.option_text,
        case
          when v_randomize_options then random()
          else case o.option_code
            when 'A' then 1::double precision
            when 'B' then 2::double precision
            when 'C' then 3::double precision
            when 'D' then 4::double precision
          end
        end as option_sort
      from public.assessment_question_options o
      where o.organization_id = p_organization_id
        and o.question_id = nq.question_id
        and o.archived_at is null
    ) option_rows
  ) option_data;

  get diagnostics v_inserted_items = row_count;

  if v_inserted_items <> v_question_count then
    raise exception 'ASSESSMENT_SNAPSHOT_INTEGRITY_ERROR' using errcode = 'P0001';
  end if;

  update public.assessment_attempts
  set total_questions = v_inserted_items,
      updated_by = v_user_id
  where id = v_attempt_id;

  return public.get_assessment_attempt(v_attempt_id);
end;
$$;

-- Reafirmação explícita das permissões públicas das RPCs.
revoke all on function public.get_available_assessments(uuid)
  from public, anon;
grant execute on function public.get_available_assessments(uuid)
  to authenticated;

revoke all on function public.start_assessment_attempt(uuid, uuid)
  from public, anon;
grant execute on function public.start_assessment_attempt(uuid, uuid)
  to authenticated;

-- ----------------------------------------------------------------------------
-- Pós-condições: nada é publicado e nenhuma tentativa é criada
-- ----------------------------------------------------------------------------

do $postconditions$
begin
  if exists (
    select 1
    from public.assessment_tests t
    where t.id = '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
      and t.status <> 'draft'
  ) then
    raise exception 'PILOT_TEST_WAS_UNEXPECTEDLY_PUBLISHED';
  end if;

  if exists (
    select 1
    from public.assessment_test_versions tv
    where tv.id = 'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
      and tv.status <> 'draft'
  ) then
    raise exception 'PILOT_VERSION_WAS_UNEXPECTEDLY_PUBLISHED';
  end if;

  if exists (
    select 1
    from public.assessment_attempts aa
    where aa.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and aa.test_id = '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
      and aa.archived_at is null
  ) then
    raise exception 'PILOT_ATTEMPT_WAS_UNEXPECTEDLY_CREATED';
  end if;

  if (
    select count(*)
    from private.assessment_test_access_grants access_grant
    where access_grant.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and access_grant.test_version_id = 'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
      and access_grant.status = 'active'
      and access_grant.archived_at is null
  ) <> 1 then
    raise exception 'PILOT_ACTIVE_GRANT_COUNT_INVALID';
  end if;
end;
$postconditions$;

commit;
