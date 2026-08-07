-- ============================================================================
-- RF Performance Comercial
-- Fase H1B — VALIDAÇÃO PÓS-MIGRATION READ ONLY
-- Não altera dados, schema, policies, grants, triggers ou funções.
-- ============================================================================

with validation as (
  select
    '01_membership_lifecycle_function_exists'::text as check_name,
    exists (
      select 1
      from pg_catalog.pg_proc p
      join pg_catalog.pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'private'
        and p.proname = 'guard_hierarchy_membership_lifecycle'
    ) as passed

  union all

  select
    '02_membership_lifecycle_trigger_exists',
    exists (
      select 1
      from pg_catalog.pg_trigger tg
      join pg_catalog.pg_class c on c.oid = tg.tgrelid
      join pg_catalog.pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public'
        and c.relname = 'organization_members'
        and tg.tgname = 'organization_members_guard_hierarchy_lifecycle'
        and not tg.tgisinternal
        and tg.tgenabled <> 'D'
    )

  union all

  select
    '03_team_assignment_guard_function_exists',
    exists (
      select 1
      from pg_catalog.pg_proc p
      join pg_catalog.pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'private'
        and p.proname = 'guard_team_active_assignments_hierarchy'
    )

  union all

  select
    '04_team_assignment_guard_trigger_exists',
    exists (
      select 1
      from pg_catalog.pg_trigger tg
      join pg_catalog.pg_class c on c.oid = tg.tgrelid
      join pg_catalog.pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public'
        and c.relname = 'teams'
        and tg.tgname = 'teams_guard_active_assignments_hierarchy'
        and not tg.tgisinternal
        and tg.tgenabled <> 'D'
    )

  union all

  select
    '05_team_supervisor_trigger_is_lifecycle_aware',
    exists (
      select 1
      from pg_catalog.pg_trigger tg
      join pg_catalog.pg_class c on c.oid = tg.tgrelid
      join pg_catalog.pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public'
        and c.relname = 'teams'
        and tg.tgname = 'teams_validate_supervisor'
        and not tg.tgisinternal
        and tg.tgenabled <> 'D'
        and pg_get_triggerdef(tg.oid, true) ilike '%status%'
        and pg_get_triggerdef(tg.oid, true) ilike '%archived_at%'
    )

  union all

  select
    '06_no_invalid_active_salesperson_assignment',
    not exists (
      select 1
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
    )

  union all

  select
    '07_no_incomplete_active_assignment_hierarchy',
    not exists (
      select 1
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
    )

  union all

  select
    '08_no_active_team_with_invalid_assigned_supervisor',
    not exists (
      select 1
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
    )
),
result_rows as (
  select
    check_name,
    case when passed then 'PASS' else 'FAIL' end as result,
    null::bigint as value
  from validation

  union all

  select
    '09_validation_summary',
    case when count(*) filter (where passed) = 8 then 'PASS' else 'FAIL' end,
    count(*) filter (where passed)::bigint
  from validation
)
select
  check_name,
  result,
  value
from result_rows
order by check_name;
