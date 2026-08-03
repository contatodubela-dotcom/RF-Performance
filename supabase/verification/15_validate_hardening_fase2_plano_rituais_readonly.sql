-- Validador somente leitura — Fase 2 do hardening de plano e rituais.
-- Não cria, altera ou remove dados, funções, privilégios ou policies.

with checks as (
  select
    'rls_commercial_plans_ativa'::text as check_name,
    coalesce((
      select c.relrowsecurity
      from pg_class c
      join pg_namespace n
        on n.oid = c.relnamespace
      where n.nspname = 'public'
        and c.relname = 'commercial_plans'
        and c.relkind = 'r'
    ), false) as passed

  union all

  select
    'rls_management_rituals_ativa',
    coalesce((
      select c.relrowsecurity
      from pg_class c
      join pg_namespace n
        on n.oid = c.relnamespace
      where n.nspname = 'public'
        and c.relname = 'management_rituals'
        and c.relkind = 'r'
    ), false)

  union all

  select
    'policy_ampla_commercial_plans_removida',
    not exists (
      select 1
      from pg_policies
      where schemaname = 'public'
        and tablename = 'commercial_plans'
        and policyname = 'commercial_plans_select_members'
    )

  union all

  select
    'policy_ampla_management_rituals_removida',
    not exists (
      select 1
      from pg_policies
      where schemaname = 'public'
        and tablename = 'management_rituals'
        and policyname = 'management_rituals_select_members'
    )

  union all

  select
    'sem_select_por_membership_em_commercial_plans',
    not exists (
      select 1
      from pg_policies
      where schemaname = 'public'
        and tablename = 'commercial_plans'
        and cmd = 'SELECT'
        and coalesce(qual, '') ilike '%has_active_membership%'
    )

  union all

  select
    'sem_select_por_membership_em_management_rituals',
    not exists (
      select 1
      from pg_policies
      where schemaname = 'public'
        and tablename = 'management_rituals'
        and cmd = 'SELECT'
        and coalesce(qual, '') ilike '%has_active_membership%'
    )

  union all

  select
    'policy_lideranca_commercial_plans_preservada',
    exists (
      select 1
      from pg_policies
      where schemaname = 'public'
        and tablename = 'commercial_plans'
        and policyname = 'commercial_plans_manage_leadership'
        and cmd = 'ALL'
        and coalesce(qual, '') ilike '%is_platform_admin%'
        and coalesce(qual, '') ilike '%has_org_role%'
        and coalesce(qual, '') ilike '%director%'
    )

  union all

  select
    'policy_lideranca_management_rituals_preservada',
    exists (
      select 1
      from pg_policies
      where schemaname = 'public'
        and tablename = 'management_rituals'
        and policyname = 'management_rituals_manage_leadership'
        and cmd = 'ALL'
        and coalesce(qual, '') ilike '%is_platform_admin%'
        and coalesce(qual, '') ilike '%has_org_role%'
        and coalesce(qual, '') ilike '%director%'
    )

  union all

  select
    'authenticated_mantem_select_tabela_commercial_plans',
    has_table_privilege('authenticated', 'public.commercial_plans', 'SELECT')

  union all

  select
    'authenticated_mantem_select_tabela_management_rituals',
    has_table_privilege('authenticated', 'public.management_rituals', 'SELECT')

  union all

  select
    'rpc_referencia_plano_security_definer',
    coalesce((
      select p.prosecdef
      from pg_proc p
      where p.oid = to_regprocedure('public.get_commercial_plan_reference(uuid)')
    ), false)

  union all

  select
    'rpc_rituais_security_definer',
    coalesce((
      select p.prosecdef
      from pg_proc p
      where p.oid = to_regprocedure('public.get_management_rituals_for_current_user(uuid)')
    ), false)

  union all

  select
    'rpc_referencia_plano_stable',
    coalesce((
      select p.provolatile = 's'
      from pg_proc p
      where p.oid = to_regprocedure('public.get_commercial_plan_reference(uuid)')
    ), false)

  union all

  select
    'rpc_rituais_stable',
    coalesce((
      select p.provolatile = 's'
      from pg_proc p
      where p.oid = to_regprocedure('public.get_management_rituals_for_current_user(uuid)')
    ), false)

  union all

  select
    'rpc_referencia_plano_search_path_fixo',
    coalesce((
      select p.proconfig @> array['search_path=pg_catalog, public, private']::text[]
      from pg_proc p
      where p.oid = to_regprocedure('public.get_commercial_plan_reference(uuid)')
    ), false)

  union all

  select
    'rpc_rituais_search_path_fixo',
    coalesce((
      select p.proconfig @> array['search_path=pg_catalog, public, private']::text[]
      from pg_proc p
      where p.oid = to_regprocedure('public.get_management_rituals_for_current_user(uuid)')
    ), false)

  union all

  select
    'authenticated_executa_rpc_referencia_plano',
    has_function_privilege(
      'authenticated',
      to_regprocedure('public.get_commercial_plan_reference(uuid)'),
      'EXECUTE'
    )

  union all

  select
    'authenticated_executa_rpc_rituais',
    has_function_privilege(
      'authenticated',
      to_regprocedure('public.get_management_rituals_for_current_user(uuid)'),
      'EXECUTE'
    )

  union all

  select
    'anon_nao_executa_rpc_referencia_plano',
    not has_function_privilege(
      'anon',
      to_regprocedure('public.get_commercial_plan_reference(uuid)'),
      'EXECUTE'
    )

  union all

  select
    'anon_nao_executa_rpc_rituais',
    not has_function_privilege(
      'anon',
      to_regprocedure('public.get_management_rituals_for_current_user(uuid)'),
      'EXECUTE'
    )
)
select
  case
    when bool_and(passed) then 'PASS'
    else 'FAIL'
  end as result,
  count(*) filter (where passed) as checks_passed,
  count(*) as checks_total,
  jsonb_agg(
    jsonb_build_object(
      'check',
      check_name,
      'passed',
      passed
    )
    order by check_name
  ) as details
from checks;
