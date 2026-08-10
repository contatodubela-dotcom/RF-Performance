-- ============================================================================
-- H3E - PREFLIGHT READ-ONLY
-- plan_actions: alinhar UPDATE ao frontend (platform_admin + director)
-- NÃO ALTERA DADOS, POLICIES OU SCHEMA
-- ============================================================================

with policies as (
  select
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
  from pg_catalog.pg_policies
  where schemaname = 'public'
    and tablename = 'plan_actions'
),
checks as (
  select
    1 as ord,
    '01_plan_actions_existe' as check_name,
    case when to_regclass('public.plan_actions') is not null then 'PASS' else 'FAIL' end as status,
    coalesce(to_regclass('public.plan_actions')::text, 'missing') as detail

  union all

  select
    2,
    '02_rls_habilitado',
    case when exists (
      select 1
      from pg_catalog.pg_class c
      join pg_catalog.pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public'
        and c.relname = 'plan_actions'
        and c.relrowsecurity
    ) then 'PASS' else 'FAIL' end,
    coalesce((
      select format('rls=%s force_rls=%s', c.relrowsecurity, c.relforcerowsecurity)
      from pg_catalog.pg_class c
      join pg_catalog.pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public'
        and c.relname = 'plan_actions'
    ), 'table missing')

  union all

  select
    3,
    '03_exatamente_uma_policy_update',
    case when count(*) filter (where cmd = 'UPDATE') = 1 then 'PASS' else 'FAIL' end,
    format('update_policies=%s', count(*) filter (where cmd = 'UPDATE'))
  from policies

  union all

  select
    4,
    '04_policy_update_esperada_existe',
    case when count(*) = 1 then 'PASS' else 'FAIL' end,
    format('matches=%s', count(*))
  from policies
  where cmd = 'UPDATE'
    and policyname = 'plan_actions_update_management'

  union all

  select
    5,
    '05_policy_update_permissive_authenticated',
    case when exists (
      select 1
      from policies
      where cmd = 'UPDATE'
        and policyname = 'plan_actions_update_management'
        and permissive = 'PERMISSIVE'
        and 'authenticated' = any(roles)
    ) then 'PASS' else 'FAIL' end,
    coalesce((
      select format('permissive=%s roles=%s', permissive, roles::text)
      from policies
      where cmd = 'UPDATE'
        and policyname = 'plan_actions_update_management'
      limit 1
    ), 'policy missing')

  union all

  select
    6,
    '06_estado_atual_update_inclui_admin_diretor_supervisor',
    case when exists (
      select 1
      from policies
      where cmd = 'UPDATE'
        and policyname = 'plan_actions_update_management'
        and lower(coalesce(qual, '')) like '%is_platform_admin%'
        and lower(coalesce(qual, '')) like '%director%'
        and lower(coalesce(qual, '')) like '%supervisor%'
        and lower(coalesce(with_check, '')) like '%is_platform_admin%'
        and lower(coalesce(with_check, '')) like '%director%'
        and lower(coalesce(with_check, '')) like '%supervisor%'
    ) then 'PASS' else 'FAIL' end,
    coalesce((
      select format('using=%s | with_check=%s', qual, with_check)
      from policies
      where cmd = 'UPDATE'
        and policyname = 'plan_actions_update_management'
      limit 1
    ), 'policy missing')

  union all

  select
    7,
    '07_insert_permanece_sem_supervisor',
    case when exists (
      select 1
      from policies
      where cmd = 'INSERT'
        and lower(coalesce(with_check, '')) like '%is_platform_admin%'
        and lower(coalesce(with_check, '')) like '%director%'
        and lower(coalesce(with_check, '')) not like '%supervisor%'
    ) then 'PASS' else 'FAIL' end,
    coalesce((
      select string_agg(policyname || ': ' || coalesce(with_check, ''), ' || ' order by policyname)
      from policies
      where cmd = 'INSERT'
    ), 'no INSERT policy')

  union all

  select
    8,
    '08_sem_policy_delete',
    case when count(*) filter (where cmd = 'DELETE') = 0 then 'PASS' else 'FAIL' end,
    format('delete_policies=%s', count(*) filter (where cmd = 'DELETE'))
  from policies
)
select check_name, status, detail
from checks
order by ord;
