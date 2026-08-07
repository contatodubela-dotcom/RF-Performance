-- ============================================================================
-- RF Performance Comercial
-- Fase H1B — PREFLIGHT READ ONLY
-- Não altera dados, schema, policies, grants, triggers ou funções.
-- ============================================================================

with
active_invalid_salesperson_assignment as (
  select tm.id
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
),
active_incomplete_assignment_hierarchy as (
  select tm.id
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
),
active_team_invalid_supervisor as (
  select t.id
  from public.teams t
  where t.status = 'active'
    and t.archived_at is null
    and t.supervisor_member_id is not null
    and not exists (
      select 1
      from public.organization_members om
      where om.id = t.supervisor_member_id
        and om.organization_id = t.organization_id
        and om.role = 'supervisor'
        and om.status = 'active'
        and om.archived_at is null
    )
),
current_team_trigger as (
  select pg_get_triggerdef(tg.oid, true) as definition
  from pg_catalog.pg_trigger tg
  join pg_catalog.pg_class c on c.oid = tg.tgrelid
  join pg_catalog.pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'teams'
    and tg.tgname = 'teams_validate_supervisor'
    and not tg.tgisinternal
)
select
  '01_validate_team_supervisor_function_exists'::text as check_name,
  case when exists (
    select 1
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'private'
      and p.proname = 'validate_team_supervisor'
  ) then 'PASS' else 'FAIL' end as result,
  null::text as detail

union all

select
  '02_teams_validate_supervisor_trigger_exists',
  case when exists (select 1 from current_team_trigger)
    then 'PASS' else 'FAIL' end,
  null

union all

select
  '03_no_active_team_with_invalid_supervisor',
  case when count(*) = 0 then 'PASS' else 'FAIL' end,
  count(*)::text
from active_team_invalid_supervisor

union all

select
  '04_no_active_assignment_with_invalid_salesperson',
  case when count(*) = 0 then 'PASS' else 'FAIL' end,
  count(*)::text
from active_invalid_salesperson_assignment

union all

select
  '05_no_active_assignment_with_incomplete_team_hierarchy',
  case when count(*) = 0 then 'PASS' else 'FAIL' end,
  count(*)::text
from active_incomplete_assignment_hierarchy

union all

select
  '06_current_team_supervisor_trigger_definition',
  'INFO',
  coalesce((select definition from current_team_trigger limit 1), 'TRIGGER_NOT_FOUND')

order by check_name;
