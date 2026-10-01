-- ============================================================================
-- RF Performance
-- Avaliações — liberação administrativa de tentativa extraordinária
-- Fase 1
--
-- Objetivos:
--   1. preservar integralmente o histórico de tentativas;
--   2. permitir uma nova chance individual e auditável após esgotamento;
--   3. manter o limite normal da avaliação inalterado;
--   4. impedir créditos duplicados ativos para o mesmo participante/versão;
--   5. restringir a concessão ao Platform Admin;
--   6. preparar consumo transacional pelo motor de avaliações.
-- ============================================================================

begin;

-- ============================================================================
-- 1. Ledger privado de tentativas extraordinárias
-- ============================================================================

create table private.assessment_extra_attempt_grants (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null,
  test_id uuid not null,
  test_version_id uuid not null,
  organization_member_id uuid not null,

  status text not null default 'active',
  reason text not null,

  consumed_at timestamptz,
  consumed_attempt_id uuid,

  revoked_at timestamptz,
  revoked_by uuid,

  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,

  metadata jsonb not null default '{}'::jsonb,

  constraint assessment_extra_attempt_grants_status_check
    check (status in ('active', 'consumed', 'revoked')),

  constraint assessment_extra_attempt_grants_reason_check
    check (length(trim(reason)) > 0),

  constraint assessment_extra_attempt_grants_metadata_object_check
    check (jsonb_typeof(metadata) = 'object'),

  constraint assessment_extra_attempt_grants_dates_check
    check (
      updated_at >= created_at
      and (consumed_at is null or consumed_at >= created_at)
      and (revoked_at is null or revoked_at >= created_at)
    ),

  constraint assessment_extra_attempt_grants_lifecycle_check
    check (
      (
        status = 'active'
        and consumed_at is null
        and consumed_attempt_id is null
        and revoked_at is null
        and revoked_by is null
      )
      or
      (
        status = 'consumed'
        and consumed_at is not null
        and consumed_attempt_id is not null
        and revoked_at is null
        and revoked_by is null
      )
      or
      (
        status = 'revoked'
        and consumed_at is null
        and consumed_attempt_id is null
        and revoked_at is not null
        and revoked_by is not null
      )
    ),

  constraint assessment_extra_attempt_grants_member_org_fkey
    foreign key (organization_member_id, organization_id)
    references public.organization_members(id, organization_id)
    on delete restrict,

  constraint assessment_extra_attempt_grants_test_org_fkey
    foreign key (test_id, organization_id)
    references public.assessment_tests(id, organization_id)
    on delete restrict,

  constraint assessment_extra_attempt_grants_version_org_test_fkey
    foreign key (test_version_id, organization_id, test_id)
    references public.assessment_test_versions(id, organization_id, test_id)
    on delete restrict,

  constraint assessment_extra_attempt_grants_consumed_attempt_org_fkey
    foreign key (consumed_attempt_id, organization_id)
    references public.assessment_attempts(id, organization_id)
    on delete restrict,

  constraint assessment_extra_attempt_grants_created_by_fkey
    foreign key (created_by)
    references public.profiles(id)
    on delete set null,

  constraint assessment_extra_attempt_grants_updated_by_fkey
    foreign key (updated_by)
    references public.profiles(id)
    on delete set null,

  constraint assessment_extra_attempt_grants_revoked_by_fkey
    foreign key (revoked_by)
    references public.profiles(id)
    on delete restrict
);

comment on table private.assessment_extra_attempt_grants is
  'Ledger auditável de tentativas extraordinárias liberadas individualmente por Platform Admin. Um registro representa um crédito de tentativa extra; o histórico normal de assessment_attempts nunca é apagado ou reiniciado.';

-- Apenas um crédito ativo simultâneo por participante + versão.
create unique index assessment_extra_attempt_grants_active_uidx
  on private.assessment_extra_attempt_grants (
    organization_id,
    test_version_id,
    organization_member_id
  )
  where status = 'active'
    and archived_at is null;

create index assessment_extra_attempt_grants_lookup_idx
  on private.assessment_extra_attempt_grants (
    organization_id,
    organization_member_id,
    test_version_id,
    status
  )
  where archived_at is null;

-- Uma tentativa não pode consumir dois créditos extraordinários.
create unique index assessment_extra_attempt_grants_consumed_attempt_uidx
  on private.assessment_extra_attempt_grants (consumed_attempt_id)
  where consumed_attempt_id is not null
    and archived_at is null;

revoke all on table private.assessment_extra_attempt_grants
  from public, anon, authenticated;

-- ============================================================================
-- 2. Helper privado: créditos extraordinários atualmente disponíveis
-- ============================================================================

create or replace function private.assessment_extra_attempts_available(
  p_organization_id uuid,
  p_organization_member_id uuid,
  p_test_version_id uuid
)
returns integer
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $function$
  select count(*)::integer
  from private.assessment_extra_attempt_grants g
  where g.organization_id = p_organization_id
    and g.organization_member_id = p_organization_member_id
    and g.test_version_id = p_test_version_id
    and g.status = 'active'
    and g.archived_at is null;
$function$;

comment on function private.assessment_extra_attempts_available(
  uuid,
  uuid,
  uuid
) is
  'Retorna a quantidade de créditos extraordinários ativos para participante e versão da avaliação.';

revoke all on function private.assessment_extra_attempts_available(
  uuid,
  uuid,
  uuid
) from public, anon, authenticated;

-- ============================================================================
-- 3. RPC administrativa para conceder uma tentativa extraordinária
-- ============================================================================

create or replace function public.grant_assessment_extra_attempt(
  p_organization_id uuid,
  p_organization_member_id uuid,
  p_test_id uuid,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $function$
declare
  v_user_id uuid := auth.uid();
  v_test_version_id uuid;
  v_max_attempts integer;
  v_attempts_used integer := 0;
  v_existing_grant_id uuid;
  v_grant_id uuid;
  v_last_graded_attempt_id uuid;
  v_prior_review_available boolean := false;
  v_reason text;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED'
      using errcode = '42501';
  end if;

  if not private.is_platform_admin() then
    raise exception 'ASSESSMENT_EXTRA_ATTEMPT_MANAGEMENT_FORBIDDEN'
      using errcode = '42501';
  end if;

  if not private.assessment_participant_eligible(
    p_organization_id,
    p_organization_member_id
  ) then
    raise exception 'ASSESSMENT_PARTICIPANT_NOT_ELIGIBLE'
      using errcode = '42501';
  end if;

  -- Serializa concessão e início de tentativa para o mesmo participante/teste.
  perform pg_advisory_xact_lock(
    hashtextextended(
      p_organization_id::text
        || ':'
        || p_organization_member_id::text
        || ':'
        || p_test_id::text,
      0
    )
  );

  select
    tv.id,
    t.max_attempts
  into
    v_test_version_id,
    v_max_attempts
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
    and t.archived_at is null
  limit 1;

  if v_test_version_id is null then
    raise exception 'ASSESSMENT_NOT_PUBLISHED'
      using errcode = 'P0001';
  end if;

  if not private.assessment_test_access_allowed(
    p_organization_id,
    p_organization_member_id,
    p_test_id,
    v_test_version_id
  ) then
    raise exception 'ASSESSMENT_ACCESS_NOT_GRANTED'
      using errcode = '42501';
  end if;

  -- Não libera nova chance enquanto ainda existir tentativa ativa ou aguardando
  -- processamento da submissão.
  if exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = p_organization_id
      and a.organization_member_id = p_organization_member_id
      and a.test_version_id = v_test_version_id
      and a.archived_at is null
      and (
        (
          a.status = 'in_progress'
          and (a.expires_at is null or a.expires_at > now())
        )
        or a.status = 'submitted'
      )
  ) then
    raise exception 'ASSESSMENT_EXTRA_ATTEMPT_ACTIVE_ATTEMPT_EXISTS'
      using errcode = 'P0001';
  end if;

  select count(*) filter (
    where a.status <> 'cancelled'
  )::integer
  into v_attempts_used
  from public.assessment_attempts a
  where a.organization_id = p_organization_id
    and a.organization_member_id = p_organization_member_id
    and a.test_version_id = v_test_version_id
    and a.archived_at is null;

  -- Tentativa extraordinária só existe depois do esgotamento da política normal.
  if coalesce(v_attempts_used, 0) < v_max_attempts then
    raise exception 'ASSESSMENT_EXTRA_ATTEMPT_NOT_REQUIRED'
      using errcode = 'P0001';
  end if;

  -- Não há motivo para reabrir uma avaliação já aprovada nesta versão.
  if exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = p_organization_id
      and a.organization_member_id = p_organization_member_id
      and a.test_version_id = v_test_version_id
      and a.status = 'graded'
      and a.passed is true
      and a.archived_at is null
  ) then
    raise exception 'ASSESSMENT_ALREADY_PASSED'
      using errcode = 'P0001';
  end if;

  -- Idempotência: se já existe crédito ativo, devolve o mesmo registro.
  select g.id
  into v_existing_grant_id
  from private.assessment_extra_attempt_grants g
  where g.organization_id = p_organization_id
    and g.organization_member_id = p_organization_member_id
    and g.test_version_id = v_test_version_id
    and g.status = 'active'
    and g.archived_at is null
  limit 1;

  if v_existing_grant_id is not null then
    return jsonb_build_object(
      'granted', true,
      'grant_id', v_existing_grant_id,
      'affected', 0,
      'organization_id', p_organization_id,
      'organization_member_id', p_organization_member_id,
      'test_id', p_test_id,
      'test_version_id', v_test_version_id,
      'attempts_used', coalesce(v_attempts_used, 0),
      'base_max_attempts', v_max_attempts,
      'extra_attempts_available', 1
    );
  end if;

  -- Registra se o último resultado já estava com revisão/gabarito disponível.
  -- Isto é importante para auditoria dos casos existentes anteriores a esta fase.
  select a.id
  into v_last_graded_attempt_id
  from public.assessment_attempts a
  where a.organization_id = p_organization_id
    and a.organization_member_id = p_organization_member_id
    and a.test_version_id = v_test_version_id
    and a.status = 'graded'
    and a.archived_at is null
  order by a.attempt_no desc, a.started_at desc, a.id desc
  limit 1;

    if v_last_graded_attempt_id is not null then
    select coalesce(
      tv.show_review_after_submit
      and a.status = 'graded'
      and (
        t.purpose = 'diagnostic'
        or a.passed is true
        or a.attempt_no >= t.max_attempts
      ),
      false
    )
    into v_prior_review_available
    from public.assessment_attempts a
    join public.assessment_tests t
      on t.id = a.test_id
     and t.organization_id = a.organization_id
    join public.assessment_test_versions tv
      on tv.id = a.test_version_id
     and tv.organization_id = a.organization_id
     and tv.test_id = a.test_id
    where a.id = v_last_graded_attempt_id
      and a.archived_at is null;

    v_prior_review_available :=
      coalesce(v_prior_review_available, false);
  end if;

  v_reason := coalesce(
    nullif(trim(p_reason), ''),
    'Liberação administrativa de tentativa extraordinária.'
  );

  insert into private.assessment_extra_attempt_grants (
    organization_id,
    test_id,
    test_version_id,
    organization_member_id,
    status,
    reason,
    created_by,
    updated_by,
    metadata
  )
  values (
    p_organization_id,
    p_test_id,
    v_test_version_id,
    p_organization_member_id,
    'active',
    v_reason,
    v_user_id,
    v_user_id,
    jsonb_build_object(
      'source', 'assessment_admin_ui',
      'managed_by', 'platform_admin',
      'attempts_used_when_granted', coalesce(v_attempts_used, 0),
      'base_max_attempts', v_max_attempts,
      'prior_review_available', v_prior_review_available,
      'last_graded_attempt_id', v_last_graded_attempt_id
    )
  )
  returning id into v_grant_id;

  return jsonb_build_object(
    'granted', true,
    'grant_id', v_grant_id,
    'affected', 1,
    'organization_id', p_organization_id,
    'organization_member_id', p_organization_member_id,
    'test_id', p_test_id,
    'test_version_id', v_test_version_id,
    'attempts_used', coalesce(v_attempts_used, 0),
    'base_max_attempts', v_max_attempts,
    'extra_attempts_available', 1,
    'prior_review_available', v_prior_review_available
  );
end;
$function$;

comment on function public.grant_assessment_extra_attempt(
  uuid,
  uuid,
  uuid,
  text
) is
  'Concede um único crédito extraordinário de tentativa para participante e versão após esgotamento das tentativas normais. Restrito ao Platform Admin e totalmente auditável.';

revoke all on function public.grant_assessment_extra_attempt(
  uuid,
  uuid,
  uuid,
  text
) from public, anon;

grant execute on function public.grant_assessment_extra_attempt(
  uuid,
  uuid,
  uuid,
  text
) to authenticated;

commit;