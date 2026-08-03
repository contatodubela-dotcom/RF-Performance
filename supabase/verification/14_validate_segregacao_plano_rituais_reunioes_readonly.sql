with rf_org as (
  select id
  from public.organizations
  where slug = 'rf-consorcios'
  limit 1
),
rf_rituals as (
  select mr.*
  from public.management_rituals mr
  join rf_org ro
    on ro.id = mr.organization_id
  where mr.archived_at is null
),
checks as (
  select *
  from (
    values
      (
        'compat_commercial_plans_policy_antiga_preservada',
        exists (
          select 1
          from pg_policies
          where schemaname = 'public'
            and tablename = 'commercial_plans'
            and policyname = 'commercial_plans_select_members'
        )
      ),
      (
        'compat_management_rituals_policy_antiga_preservada',
        exists (
          select 1
          from pg_policies
          where schemaname = 'public'
            and tablename = 'management_rituals'
            and policyname = 'management_rituals_select_members'
        )
      ),
      (
        'rpc_referencia_plano_existe_security_definer',
        exists (
          select 1
          from pg_proc p
          join pg_namespace n on n.oid = p.pronamespace
          where n.nspname = 'public'
            and p.proname = 'get_commercial_plan_reference'
            and p.prosecdef
        )
      ),
      (
        'rpc_referencia_verifica_vinculo_ativo',
        exists (
          select 1
          from pg_proc p
          join pg_namespace n on n.oid = p.pronamespace
          where n.nspname = 'public'
            and p.proname = 'get_commercial_plan_reference'
            and pg_get_functiondef(p.oid) ilike '%has_active_membership%'
        )
      ),
      (
        'authenticated_executa_rpc_referencia',
        has_function_privilege(
          'authenticated',
          'public.get_commercial_plan_reference(uuid)',
          'execute'
        )
      ),
      (
        'anon_nao_executa_rpc_referencia',
        not has_function_privilege(
          'anon',
          'public.get_commercial_plan_reference(uuid)',
          'execute'
        )
      ),
      (
        'rpc_rituais_existe_security_definer',
        exists (
          select 1
          from pg_proc p
          join pg_namespace n on n.oid = p.pronamespace
          where n.nspname = 'public'
            and p.proname = 'get_management_rituals_for_current_user'
            and p.prosecdef
        )
      ),
      (
        'rpc_rituais_verifica_vinculo_e_perfis',
        exists (
          select 1
          from pg_proc p
          join pg_namespace n on n.oid = p.pronamespace
          where n.nspname = 'public'
            and p.proname = 'get_management_rituals_for_current_user'
            and pg_get_functiondef(p.oid) ilike '%has_active_membership%'
            and pg_get_functiondef(p.oid) ilike '%salesperson%'
            and pg_get_functiondef(p.oid) ilike '%supervisor%'
            and pg_get_functiondef(p.oid) ilike '%director%'
        )
      ),
      (
        'authenticated_executa_rpc_rituais',
        has_function_privilege(
          'authenticated',
          'public.get_management_rituals_for_current_user(uuid)',
          'execute'
        )
      ),
      (
        'anon_nao_executa_rpc_rituais',
        not has_function_privilege(
          'anon',
          'public.get_management_rituals_for_current_user(uuid)',
          'execute'
        )
      ),
      (
        'rf_preserva_nove_rituais',
        (select count(*) from rf_rituals) = 9
      ),
      (
        'rf_vendedor_recebe_cinco_rituais',
        (
          select count(*)
          from rf_rituals
          where coalesce(metadata -> 'audience_roles', '[]'::jsonb)
            ? 'salesperson'
        ) = 5
      ),
      (
        'rf_supervisor_recebe_oito_rituais',
        (
          select count(*)
          from rf_rituals
          where coalesce(metadata -> 'audience_roles', '[]'::jsonb)
            ? 'supervisor'
        ) = 8
      ),
      (
        'rf_diretor_recebe_nove_rituais',
        (
          select count(*)
          from rf_rituals
          where coalesce(metadata -> 'audience_roles', '[]'::jsonb)
            ? 'director'
        ) = 9
      ),
      (
        'reuniao_executiva_exclusiva_direcao',
        exists (
          select 1
          from rf_rituals
          where title = 'Reunião executiva de performance'
            and metadata -> 'audience_roles' = '["director"]'::jsonb
        )
      ),
      (
        'meeting_records_policy_equipe_preservada',
        exists (
          select 1
          from pg_policies
          where schemaname = 'public'
            and tablename = 'meeting_records'
            and policyname = 'meeting_records_select_authorized'
            and qual ilike '%current_user_team_ids%'
            and qual ilike '%managed_team_ids%'
        )
      ),
      (
        'estrutura_rf_preservada',
        (
          select count(*)
          from public.sales_locations sl
          join rf_org ro on ro.id = sl.organization_id
          where sl.status = 'active'
            and sl.archived_at is null
        ) = 5
        and
        (
          select count(*)
          from public.teams t
          join rf_org ro on ro.id = t.organization_id
          where t.status = 'active'
            and t.archived_at is null
        ) = 5
      )
  ) as t(check_name, passed)
),
summary as (
  select
    case when bool_and(passed) then 'PASS' else 'FAIL' end as result,
    count(*) filter (where passed) as checks_passed,
    count(*) as checks_total,
    jsonb_agg(
      jsonb_build_object('check', check_name, 'passed', passed)
      order by check_name
    ) as details
  from checks
)
select *
from summary;
