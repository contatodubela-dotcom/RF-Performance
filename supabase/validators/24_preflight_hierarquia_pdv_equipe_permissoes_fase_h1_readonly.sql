-- ============================================================================
-- RF Performance Comercial
-- Fase H1 — PRE-FLIGHT READ ONLY
-- Execute ANTES da migration 20260807023000.
-- Não altera dados, schema, policies, grants ou funções.
-- ============================================================================

with checks as (
  select
    '01_active_team_members_are_active_salespersons'::text as check_name,
    count(*)::bigint as problem_count
  from public.team_members tm
  join public.organization_members om
    on om.id = tm.organization_member_id
   and om.organization_id = tm.organization_id
  where tm.status = 'active'
    and tm.archived_at is null
    and (
      om.role <> 'salesperson'
      or om.status <> 'active'
      or om.archived_at is not null
    )

  union all

  select
    '02_active_team_members_have_complete_team_hierarchy',
    count(*)::bigint
  from public.team_members tm
  join public.teams t
    on t.id = tm.team_id
   and t.organization_id = tm.organization_id
  where tm.status = 'active'
    and tm.archived_at is null
    and (
      t.status <> 'active'
      or t.archived_at is not null
      or t.sales_location_id is null
      or t.supervisor_member_id is null
    )

  union all

  select
    '03_no_salesperson_has_multiple_active_teams',
    count(*)::bigint
  from (
    select tm.organization_id, tm.organization_member_id
    from public.team_members tm
    where tm.status = 'active'
      and tm.archived_at is null
    group by tm.organization_id, tm.organization_member_id
    having count(*) > 1
  ) duplicated

  union all

  select
    '04_active_teams_have_valid_supervisor_role',
    count(*)::bigint
  from public.teams t
  join public.organization_members om
    on om.id = t.supervisor_member_id
   and om.organization_id = t.organization_id
  where t.status = 'active'
    and t.archived_at is null
    and t.supervisor_member_id is not null
    and (
      om.role <> 'supervisor'
      or om.status <> 'active'
      or om.archived_at is not null
    )
)
select
  check_name,
  problem_count,
  case when problem_count = 0 then 'PASS' else 'FAIL' end as result
from checks
order by check_name;

-- Detalhes de eventuais vendedores com mais de uma equipe ativa.
select
  tm.organization_id,
  tm.organization_member_id,
  count(*) as active_team_count,
  array_agg(tm.team_id order by tm.team_id) as active_team_ids
from public.team_members tm
where tm.status = 'active'
  and tm.archived_at is null
group by tm.organization_id, tm.organization_member_id
having count(*) > 1
order by tm.organization_id, tm.organization_member_id;

-- Detalhes de vínculos ativos cuja equipe não possui PDV/supervisor completos.
select
  tm.id as team_member_id,
  tm.organization_member_id,
  tm.team_id,
  t.name as team_name,
  t.sales_location_id,
  t.supervisor_member_id,
  t.status as team_status,
  t.archived_at as team_archived_at
from public.team_members tm
join public.teams t
  on t.id = tm.team_id
 and t.organization_id = tm.organization_id
where tm.status = 'active'
  and tm.archived_at is null
  and (
    t.status <> 'active'
    or t.archived_at is not null
    or t.sales_location_id is null
    or t.supervisor_member_id is null
  )
order by t.name, tm.organization_member_id;
