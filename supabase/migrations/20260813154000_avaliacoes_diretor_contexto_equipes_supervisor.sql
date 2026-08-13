-- ============================================================================
-- RF Performance — Avaliações — Homologação Diretor
-- Corrige contexto de equipes exibido para supervisores na visão gerencial.
-- Data: 2026-08-13
--
-- Escopo:
--   - NÃO altera membros visíveis;
--   - NÃO altera RLS;
--   - NÃO altera grants de acesso às avaliações;
--   - NÃO altera tentativas, notas, respostas ou gabaritos;
--   - mantém vendedores por public.team_members;
--   - passa a obter equipes de supervisores por public.teams.supervisor_member_id.
-- ============================================================================

begin;

do $preflight$
begin
  if to_regprocedure('public.get_managed_assessment_progress(uuid)') is null then
    raise exception 'DIRECTOR_TEAM_CONTEXT_PREFLIGHT_FAILED: RPC get_managed_assessment_progress(uuid) not found';
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'teams'
      and column_name = 'supervisor_member_id'
  ) then
    raise exception 'DIRECTOR_TEAM_CONTEXT_PREFLIGHT_FAILED: teams.supervisor_member_id not found';
  end if;
end;
$preflight$;

create or replace function public.get_managed_assessment_progress(
  p_organization_id uuid
)
returns table (
  organization_member_id uuid,
  user_id uuid,
  member_name text,
  member_email text,
  member_role text,
  team_contexts jsonb,
  test_id uuid,
  test_code text,
  sequence_no integer,
  test_title text,
  test_purpose text,
  test_version_id uuid,
  version_code text,
  assigned boolean,
  attempts_used integer,
  in_progress_attempt_id uuid,
  last_attempt_id uuid,
  last_attempt_no integer,
  last_attempt_status text,
  last_attempt_started_at timestamptz,
  last_attempt_submitted_at timestamptz,
  last_attempt_graded_at timestamptz,
  last_attempt_overall_score numeric,
  last_attempt_legal_score numeric,
  last_attempt_passed boolean,
  last_graded_attempt_id uuid,
  last_graded_attempt_no integer,
  last_graded_overall_score numeric,
  last_graded_legal_score numeric,
  last_graded_passed boolean,
  progress_status text
)
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $$
declare
  v_user_id uuid := auth.uid();
  v_caller_member_id uuid;
  v_caller_role text;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.organizations o
    where o.id = p_organization_id
      and o.status = 'active'
      and o.archived_at is null
  ) then
    raise exception 'ORGANIZATION_NOT_AVAILABLE' using errcode = '42501';
  end if;

  if private.is_platform_admin() then
    v_caller_role := 'platform_admin';
  else
    select om.id, om.role
      into v_caller_member_id, v_caller_role
    from public.organization_members om
    join public.profiles p
      on p.id = om.user_id
     and p.status = 'active'
     and p.archived_at is null
    where om.organization_id = p_organization_id
      and om.user_id = v_user_id
      and om.status = 'active'
      and om.archived_at is null
    order by om.created_at
    limit 1;

    if v_caller_member_id is null then
      raise exception 'ACTIVE_MEMBERSHIP_REQUIRED' using errcode = '42501';
    end if;
  end if;

  if v_caller_role not in ('platform_admin', 'director', 'supervisor') then
    raise exception 'ASSESSMENT_MANAGEMENT_FORBIDDEN' using errcode = '42501';
  end if;

  return query
  with visible_members as (
    select
      om.id as organization_member_id,
      om.user_id,
      p.full_name as member_name,
      p.email as member_email,
      om.role as member_role
    from public.organization_members om
    join public.profiles p
      on p.id = om.user_id
     and p.status = 'active'
     and p.archived_at is null
    where om.organization_id = p_organization_id
      and om.status = 'active'
      and om.archived_at is null
      and (
        (
          v_caller_role in ('platform_admin', 'director')
          and om.role in ('supervisor', 'salesperson')
        )
        or
        (
          v_caller_role = 'supervisor'
          and om.role = 'salesperson'
          and exists (
            select 1
            from public.team_members tm
            where tm.organization_id = p_organization_id
              and tm.organization_member_id = om.id
              and tm.membership_type = 'salesperson'
              and tm.status = 'active'
              and tm.archived_at is null
              and tm.team_id in (select private.managed_team_ids())
          )
        )
      )
  ),
  published_tests as (
    select
      t.id as test_id,
      t.code as test_code,
      t.sequence_no,
      t.title as test_title,
      t.purpose as test_purpose,
      tv.id as test_version_id,
      tv.version_code
    from public.assessment_tests t
    join public.assessment_test_versions tv
      on tv.test_id = t.id
     and tv.organization_id = t.organization_id
     and tv.status = 'published'
     and tv.archived_at is null
     and (tv.valid_from is null or tv.valid_from <= now())
     and (tv.valid_until is null or tv.valid_until >= now())
    where t.organization_id = p_organization_id
      and t.status = 'active'
      and t.archived_at is null
  )
  select
    vm.organization_member_id,
    vm.user_id,
    vm.member_name,
    vm.member_email,
    vm.member_role,
    coalesce(team_scope.team_contexts, '[]'::jsonb) as team_contexts,
    pt.test_id,
    pt.test_code,
    pt.sequence_no,
    pt.test_title,
    pt.test_purpose,
    pt.test_version_id,
    pt.version_code,
    access_state.assigned,
    coalesce(attempt_summary.attempts_used, 0)::integer as attempts_used,
    attempt_summary.in_progress_attempt_id,
    latest_attempt.id as last_attempt_id,
    latest_attempt.attempt_no as last_attempt_no,
    latest_attempt.status as last_attempt_status,
    latest_attempt.started_at as last_attempt_started_at,
    latest_attempt.submitted_at as last_attempt_submitted_at,
    latest_attempt.graded_at as last_attempt_graded_at,
    latest_attempt.overall_score as last_attempt_overall_score,
    latest_attempt.legal_score as last_attempt_legal_score,
    latest_attempt.passed as last_attempt_passed,
    last_graded.id as last_graded_attempt_id,
    last_graded.attempt_no as last_graded_attempt_no,
    last_graded.overall_score as last_graded_overall_score,
    last_graded.legal_score as last_graded_legal_score,
    last_graded.passed as last_graded_passed,
    case
      when not access_state.assigned then 'not_assigned'
      when attempt_summary.in_progress_attempt_id is not null then 'in_progress'
      when last_graded.id is not null and last_graded.passed is true then 'passed'
      when last_graded.id is not null then 'failed'
      when latest_attempt.status = 'submitted' then 'submitted'
      when latest_attempt.status = 'expired' then 'expired'
      when latest_attempt.status = 'cancelled' then 'cancelled'
      else 'not_started'
    end as progress_status
  from visible_members vm
  cross join published_tests pt
  left join lateral (
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'team_id', scoped_team.team_id,
          'team_name', scoped_team.team_name,
          'sales_location_id', scoped_team.sales_location_id,
          'sales_location_name', scoped_team.sales_location_name
        )
        order by scoped_team.team_name, scoped_team.team_id
      ),
      '[]'::jsonb
    ) as team_contexts
    from (
      -- Supervisor: contexto pelas equipes que ele gerencia.
      select distinct
        t.id as team_id,
        t.name as team_name,
        t.sales_location_id,
        sl.name as sales_location_name
      from public.teams t
      left join public.sales_locations sl
        on sl.id = t.sales_location_id
       and sl.organization_id = t.organization_id
       and sl.status = 'active'
       and sl.archived_at is null
      where vm.member_role = 'supervisor'
        and t.organization_id = p_organization_id
        and t.supervisor_member_id = vm.organization_member_id
        and t.status = 'active'
        and t.archived_at is null

      union

      -- Vendedor: contexto pelas equipes em que possui vínculo ativo.
      select distinct
        t.id as team_id,
        t.name as team_name,
        t.sales_location_id,
        sl.name as sales_location_name
      from public.team_members tm
      join public.teams t
        on t.id = tm.team_id
       and t.organization_id = tm.organization_id
       and t.status = 'active'
       and t.archived_at is null
      left join public.sales_locations sl
        on sl.id = t.sales_location_id
       and sl.organization_id = t.organization_id
       and sl.status = 'active'
       and sl.archived_at is null
      where vm.member_role = 'salesperson'
        and tm.organization_id = p_organization_id
        and tm.organization_member_id = vm.organization_member_id
        and tm.membership_type = 'salesperson'
        and tm.status = 'active'
        and tm.archived_at is null
        and (
          v_caller_role <> 'supervisor'
          or tm.team_id in (select private.managed_team_ids())
        )
    ) scoped_team
  ) team_scope on true
  left join lateral (
    select private.assessment_test_access_allowed(
      p_organization_id,
      vm.organization_member_id,
      pt.test_id,
      pt.test_version_id
    ) as assigned
  ) access_state on true
  left join lateral (
    select
      count(*) filter (where a.status <> 'cancelled')::integer as attempts_used,
      (
        array_agg(a.id order by a.started_at desc, a.id desc)
        filter (
          where a.status = 'in_progress'
            and (a.expires_at is null or a.expires_at > now())
        )
      )[1] as in_progress_attempt_id
    from public.assessment_attempts a
    where a.organization_id = p_organization_id
      and a.organization_member_id = vm.organization_member_id
      and a.test_version_id = pt.test_version_id
      and a.archived_at is null
  ) attempt_summary on true
  left join lateral (
    select
      a.id,
      a.attempt_no,
      a.status,
      a.started_at,
      a.submitted_at,
      a.graded_at,
      a.overall_score,
      a.legal_score,
      a.passed
    from public.assessment_attempts a
    where a.organization_id = p_organization_id
      and a.organization_member_id = vm.organization_member_id
      and a.test_version_id = pt.test_version_id
      and a.archived_at is null
    order by a.attempt_no desc, a.started_at desc, a.id desc
    limit 1
  ) latest_attempt on true
  left join lateral (
    select
      a.id,
      a.attempt_no,
      a.overall_score,
      a.legal_score,
      a.passed
    from public.assessment_attempts a
    where a.organization_id = p_organization_id
      and a.organization_member_id = vm.organization_member_id
      and a.test_version_id = pt.test_version_id
      and a.status = 'graded'
      and a.archived_at is null
    order by a.attempt_no desc, a.started_at desc, a.id desc
    limit 1
  ) last_graded on true
  order by
    vm.member_name,
    vm.organization_member_id,
    pt.sequence_no,
    pt.test_id;
end;
$$;

revoke all on function public.get_managed_assessment_progress(uuid)
from public, anon, authenticated;

grant execute on function public.get_managed_assessment_progress(uuid)
to authenticated;

comment on function public.get_managed_assessment_progress(uuid) is
  'Visão gerencial segura do progresso das avaliações. Supervisor vê somente vendedores das próprias equipes; diretor/admin veem membros operacionais da organização. Contexto de equipe usa team_members para vendedores e teams.supervisor_member_id para supervisores. Não expõe respostas, gabaritos ou correção por questão.';

do $postcondition$
begin
  if to_regprocedure('public.get_managed_assessment_progress(uuid)') is null then
    raise exception 'DIRECTOR_TEAM_CONTEXT_POSTCONDITION_FAILED: RPC missing after replacement';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.get_managed_assessment_progress(uuid)',
    'EXECUTE'
  ) then
    raise exception 'DIRECTOR_TEAM_CONTEXT_POSTCONDITION_FAILED: authenticated lost EXECUTE';
  end if;

  if has_function_privilege(
    'anon',
    'public.get_managed_assessment_progress(uuid)',
    'EXECUTE'
  ) then
    raise exception 'DIRECTOR_TEAM_CONTEXT_POSTCONDITION_FAILED: anon unexpectedly has EXECUTE';
  end if;
end;
$postcondition$;

commit;
