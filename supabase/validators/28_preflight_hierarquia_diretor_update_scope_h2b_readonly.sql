-- RF Performance — H2B PRE-FLIGHT READ ONLY
-- Não altera dados nem políticas.
-- Esperado antes da migration: todos os checks PASS.

with checks as (
  select
    '01_rls_organization_members_ativa'::text as check_name,
    exists (
      select 1
      from pg_catalog.pg_class c
      join pg_catalog.pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public'
        and c.relname = 'organization_members'
        and c.relrowsecurity
    ) as passed,
    'RLS deve estar ativa em public.organization_members.'::text as detail

  union all

  select
    '02_policy_platform_admin_update_existe',
    exists (
      select 1
      from pg_catalog.pg_policies
      where schemaname = 'public'
        and tablename = 'organization_members'
        and policyname = 'organization_members_update_platform_admin'
        and cmd = 'UPDATE'
        and coalesce(qual, '') ilike '%private.is_platform_admin()%'
        and coalesce(with_check, '') ilike '%private.is_platform_admin()%'
    ),
    'A policy de UPDATE do platform_admin deve permanecer existente.'

  union all

  select
    '03_policy_director_update_existe',
    exists (
      select 1
      from pg_catalog.pg_policies
      where schemaname = 'public'
        and tablename = 'organization_members'
        and policyname = 'organization_members_update_director'
        and cmd = 'UPDATE'
        and coalesce(qual, '') ilike '%private.has_org_role%'
        and coalesce(with_check, '') ilike '%private.has_org_role%'
    ),
    'A policy atual do Diretor deve existir antes de ser substituída.'

  union all

  select
    '04_guard_membership_update_existe',
    exists (
      select 1
      from pg_catalog.pg_proc p
      join pg_catalog.pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'private'
        and p.proname = 'guard_membership_update'
    ),
    'Guard base de membership deve existir.'

  union all

  select
    '05_guard_hierarchy_lifecycle_existe',
    exists (
      select 1
      from pg_catalog.pg_proc p
      join pg_catalog.pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'private'
        and p.proname = 'guard_hierarchy_membership_lifecycle'
    ),
    'Guard H1B de ciclo de vida deve existir.'

  union all

  select
    '06_trigger_guard_update_existe',
    exists (
      select 1
      from pg_catalog.pg_trigger t
      join pg_catalog.pg_class c on c.oid = t.tgrelid
      join pg_catalog.pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public'
        and c.relname = 'organization_members'
        and t.tgname = 'organization_members_guard_update'
        and not t.tgisinternal
    ),
    'Trigger do guard base deve estar ativo.'

  union all

  select
    '07_trigger_guard_hierarchy_existe',
    exists (
      select 1
      from pg_catalog.pg_trigger t
      join pg_catalog.pg_class c on c.oid = t.tgrelid
      join pg_catalog.pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public'
        and c.relname = 'organization_members'
        and t.tgname = 'organization_members_guard_hierarchy_lifecycle'
        and not t.tgisinternal
    ),
    'Trigger H1B deve estar ativo.'

  union all

  select
    '08_sem_policy_update_supervisor',
    not exists (
      select 1
      from pg_catalog.pg_policies
      where schemaname = 'public'
        and tablename = 'organization_members'
        and cmd = 'UPDATE'
        and policyname not in (
          'organization_members_update_platform_admin',
          'organization_members_update_director'
        )
    ),
    'Não deve existir terceira policy de UPDATE ampliando o acesso.'
)
select
  check_name,
  case when passed then 'PASS' else 'FAIL' end as result,
  detail
from checks
order by check_name;
