-- Validação somente leitura
-- Segregação de dados estratégicos da organização.

with function_catalog as (
  select
    p.oid,
    p.proname,
    p.prosecdef,
    pg_get_functiondef(p.oid) as definition
  from pg_proc p
  join pg_namespace n
    on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname in (
      'get_organization_strategic_metadata',
      'list_organizations_for_platform_admin'
    )
),
checks as (
  select
    'authenticated_sem_select_geral_organizations'::text as check_name,
    not has_table_privilege(
      'authenticated',
      'public.organizations',
      'select'
    ) as passed

  union all

  select
    'authenticated_le_colunas_basicas',
    has_column_privilege(
      'authenticated',
      'public.organizations',
      'id',
      'select'
    )
    and has_column_privilege(
      'authenticated',
      'public.organizations',
      'trade_name',
      'select'
    )
    and has_column_privilege(
      'authenticated',
      'public.organizations',
      'slug',
      'select'
    )
    and has_column_privilege(
      'authenticated',
      'public.organizations',
      'logo_url',
      'select'
    )
    and has_column_privilege(
      'authenticated',
      'public.organizations',
      'status',
      'select'
    )
    and has_column_privilege(
      'authenticated',
      'public.organizations',
      'source_system',
      'select'
    )

  union all

  select
    'authenticated_nao_le_metadata',
    not has_column_privilege(
      'authenticated',
      'public.organizations',
      'metadata',
      'select'
    )

  union all

  select
    'anon_sem_select_organizations',
    not has_table_privilege(
      'anon',
      'public.organizations',
      'select'
    )
    and not has_column_privilege(
      'anon',
      'public.organizations',
      'metadata',
      'select'
    )

  union all

  select
    'rpc_metadata_existe_security_definer',
    coalesce(
      (
        select fc.prosecdef
        from function_catalog fc
        where fc.proname =
          'get_organization_strategic_metadata'
      ),
      false
    )

  union all

  select
    'rpc_lista_admin_existe_security_definer',
    coalesce(
      (
        select fc.prosecdef
        from function_catalog fc
        where fc.proname =
          'list_organizations_for_platform_admin'
      ),
      false
    )

  union all

  select
    'authenticated_executa_rpc_metadata',
    has_function_privilege(
      'authenticated',
      'public.get_organization_strategic_metadata(uuid)',
      'execute'
    )

  union all

  select
    'authenticated_executa_rpc_lista_admin',
    has_function_privilege(
      'authenticated',
      'public.list_organizations_for_platform_admin()',
      'execute'
    )

  union all

  select
    'rpc_metadata_verifica_diretor_ou_admin',
    coalesce(
      (
        select
          fc.definition like '%private.is_platform_admin()%'
          and fc.definition like '%private.has_org_role%'
          and fc.definition like '%director%'
        from function_catalog fc
        where fc.proname =
          'get_organization_strategic_metadata'
      ),
      false
    )

  union all

  select
    'rpc_lista_verifica_platform_admin',
    coalesce(
      (
        select
          fc.definition like '%private.is_platform_admin()%'
        from function_catalog fc
        where fc.proname =
          'list_organizations_for_platform_admin'
      ),
      false
    )

  union all

  select
    'estrutura_operacional_preservada',
    (
      select count(*)
      from public.sales_locations
      where organization_id =
        '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
        and status = 'active'
    ) = 5
    and (
      select count(*)
      from public.teams
      where organization_id =
        '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
        and status = 'active'
    ) = 5
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
      'check', check_name,
      'passed', passed
    )
    order by check_name
  ) as details
from checks;
