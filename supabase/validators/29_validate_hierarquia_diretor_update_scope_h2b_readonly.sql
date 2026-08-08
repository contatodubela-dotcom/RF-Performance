-- RF Performance — H2B VALIDATOR READ ONLY
-- Execute somente após a migration H2B.
-- Não altera dados nem políticas.

with director_policy as (
  select
    cmd,
    roles,
    coalesce(qual, '') as qual,
    coalesce(with_check, '') as with_check
  from pg_catalog.pg_policies
  where schemaname = 'public'
    and tablename = 'organization_members'
    and policyname = 'organization_members_update_director'
),
checks as (
  select
    '01_policy_director_unica'::text as check_name,
    (select count(*) = 1 from director_policy) as passed,
    'Deve existir exatamente uma organization_members_update_director.'::text as detail

  union all

  select
    '02_policy_director_so_update',
    exists (
      select 1 from director_policy where cmd = 'UPDATE'
    ),
    'A policy do Diretor deve ser somente UPDATE.'

  union all

  select
    '03_using_exige_diretor_da_org',
    exists (
      select 1
      from director_policy
      where qual ilike '%private.has_org_role%'
        and qual ilike '%director%'
    ),
    'USING deve exigir papel director na organização alvo.'

  union all

  select
    '04_using_restringe_supervisor_salesperson',
    exists (
      select 1
      from director_policy
      where qual ~* 'role'
        and qual ~* 'supervisor'
        and qual ~* 'salesperson'
    ),
    'USING deve limitar o membro alvo a supervisor/salesperson.'

  union all

  select
    '05_check_exige_diretor_da_org',
    exists (
      select 1
      from director_policy
      where with_check ilike '%private.has_org_role%'
        and with_check ilike '%director%'
    ),
    'WITH CHECK deve manter o escopo da organização do Diretor.'

  union all

  select
    '06_check_restringe_supervisor_salesperson',
    exists (
      select 1
      from director_policy
      where with_check ~* 'role'
        and with_check ~* 'supervisor'
        and with_check ~* 'salesperson'
    ),
    'WITH CHECK deve impedir que o resultado da linha seja director.'

  union all

  select
    '07_platform_admin_preservado',
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
    'A policy do platform_admin deve permanecer intacta.'

  union all

  select
    '08_guard_role_change_preservado',
    exists (
      select 1
      from pg_catalog.pg_proc p
      join pg_catalog.pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'private'
        and p.proname = 'guard_membership_update'
        and pg_catalog.pg_get_functiondef(p.oid) ilike '%alteração de papel exige administrador da plataforma%'
    ),
    'Guard que reserva mudança de role ao platform_admin deve permanecer.'

  union all

  select
    '09_guard_h1b_preservado',
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
    'Trigger H1B de integridade hierárquica deve permanecer ativo.'

  union all

  select
    '10_sem_terceira_policy_update',
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
    'Nenhuma outra policy UPDATE deve ampliar o acesso.'
)
select
  check_name,
  case when passed then 'PASS' else 'FAIL' end as result,
  detail
from checks
order by check_name;
