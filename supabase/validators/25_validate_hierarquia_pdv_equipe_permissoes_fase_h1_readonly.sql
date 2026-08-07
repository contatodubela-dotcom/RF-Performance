-- ============================================================================
-- RF Performance Comercial
-- Fase H1 — VALIDAÇÃO PÓS-MIGRATION READ ONLY
-- Não altera dados, schema, policies, grants ou funções.
-- ============================================================================

with validation as (
  select
    '01_unique_active_team_index_exists'::text as check_name,
    exists (
      select 1
      from pg_catalog.pg_indexes
      where schemaname = 'public'
        and tablename = 'team_members'
        and indexname = 'team_members_active_member_org_uidx'
    ) as passed

  union all

  select
    '02_assignment_validation_function_exists',
    exists (
      select 1
      from pg_catalog.pg_proc p
      join pg_catalog.pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'private'
        and p.proname = 'validate_team_member_assignment'
    )

  union all

  select
    '03_assignment_validation_trigger_exists',
    exists (
      select 1
      from pg_catalog.pg_trigger tg
      join pg_catalog.pg_class c on c.oid = tg.tgrelid
      join pg_catalog.pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public'
        and c.relname = 'team_members'
        and tg.tgname = 'team_members_validate_assignment'
        and not tg.tgisinternal
        and tg.tgenabled <> 'D'
    )

  union all

  select
    '04_no_invalid_active_team_member_role',
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
    '05_no_incomplete_active_team_hierarchy',
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
    '06_no_multiple_active_teams_per_salesperson',
    not exists (
      select 1
      from public.team_members tm
      where tm.status = 'active'
        and tm.archived_at is null
      group by tm.organization_id, tm.organization_member_id
      having count(*) > 1
    )

  union all

  select
    '07_supervisor_still_has_no_direct_team_member_insert_policy',
    not exists (
      select 1
      from pg_catalog.pg_policies p
      where p.schemaname = 'public'
        and p.tablename = 'team_members'
        and p.cmd = 'INSERT'
        and coalesce(p.with_check, '') ilike '%supervisor%'
    )
)
select
  check_name,
  case when passed then 'PASS' else 'FAIL' end as result
from validation
order by check_name;

-- Resumo esperado: 7 PASS / 0 FAIL.
select
  count(*) filter (where status = 'active' and archived_at is null) as active_team_members
from public.team_members;
