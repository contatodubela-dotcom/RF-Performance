begin;

-- ============================================================================
-- RF Performance
-- Hotfix Resultados Comerciais
-- Corrige uso invalido de pg_catalog.coalesce(...) em RPCs de Resultados.
--
-- IMPORTANTE:
-- - nao altera migrations historicas ja aplicadas;
-- - preserva assinaturas, retornos, filtros, permissoes e semantica;
-- - altera somente COALESCE, que e construcao SQL e nao funcao de pg_catalog.
-- ============================================================================

do $preflight$
begin
  if pg_catalog.to_regprocedure(
    'public.get_validated_sales_actuals(uuid,date)'
  ) is null then
    raise exception
      'Hotfix abortado: get_validated_sales_actuals(uuid,date) nao existe.';
  end if;

  if pg_catalog.to_regprocedure(
    'public.get_validated_sales_salesperson_drilldown(uuid,date)'
  ) is null then
    raise exception
      'Hotfix abortado: get_validated_sales_salesperson_drilldown(uuid,date) nao existe.';
  end if;

  if pg_catalog.to_regprocedure(
    'public.get_commercial_productivity_indicators(uuid,date)'
  ) is null then
    raise exception
      'Hotfix abortado: get_commercial_productivity_indicators(uuid,date) nao existe.';
  end if;
end;
$preflight$;

create or replace function public.get_validated_sales_actuals(
  p_plan_id uuid,
  p_competence_month date
)
returns table (
  plan_id uuid,
  organization_id uuid,
  competence_month date,
  scope_type text,
  scope_id uuid,
  actual_value bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_organization_id uuid;
  v_operation_id uuid;
begin
  if auth.uid() is null then
    return;
  end if;

  if p_plan_id is null
     or p_competence_month is null
  then
    return;
  end if;

  if p_competence_month <>
    pg_catalog.date_trunc(
      'month',
      p_competence_month::timestamp
    )::date
  then
    raise exception using
      errcode = '22023',
      message =
        'p_competence_month deve ser o primeiro dia do mes.';
  end if;

  select
    cp.organization_id,
    cp.operation_id
  into
    v_organization_id,
    v_operation_id
  from public.commercial_plans cp
  where cp.id = p_plan_id
    and cp.status <> 'archived'
    and cp.archived_at is null
  limit 1;

  if v_organization_id is null
     or v_operation_id is null
  then
    return;
  end if;

  if not (
    coalesce(
      private.is_platform_admin(),
      false
    )
    or coalesce(
      private.has_org_role(
        v_organization_id,
        array['director']
      ),
      false
    )
  ) then
    return;
  end if;

  return query
  with goal_scopes as (
    select
      pg.scope_type,
      pg.scope_id
    from public.performance_goals pg
    where pg.plan_id = p_plan_id
      and pg.organization_id = v_organization_id
      and pg.metric_code = 'validated_sales'
      and pg.period_type = 'monthly'
      and pg.status <> 'archived'
      and pg.archived_at is null
      and pg.scope_type in (
        'organization',
        'sales_location',
        'team',
        'organization_member'
      )
  ),
  validated_rows as (
    select
      cs.sales_location_id,
      cs.team_id,
      cs.salesperson_member_id,
      cs.units_count
    from public.commercial_sales cs
    where cs.organization_id = v_organization_id
      and cs.operation_id = v_operation_id
      and cs.competence_month = p_competence_month
      and cs.validation_status = 'validated'
      and cs.validated_at is not null
      and cs.archived_at is null
  )
  select
    p_plan_id,
    v_organization_id,
    p_competence_month,
    gs.scope_type,
    gs.scope_id,
    case
      when gs.scope_type = 'organization' then (
        select pg_catalog.sum(vr.units_count)::bigint
        from validated_rows vr
      )
      when gs.scope_type = 'sales_location' then (
        select pg_catalog.sum(vr.units_count)::bigint
        from validated_rows vr
        where vr.sales_location_id = gs.scope_id
      )
      when gs.scope_type = 'team' then (
        select pg_catalog.sum(vr.units_count)::bigint
        from validated_rows vr
        where vr.team_id = gs.scope_id
      )
      when gs.scope_type = 'organization_member' then (
        select pg_catalog.sum(vr.units_count)::bigint
        from validated_rows vr
        where vr.salesperson_member_id = gs.scope_id
      )
      else null::bigint
    end as actual_value
  from goal_scopes gs
  order by
    case gs.scope_type
      when 'organization' then 1
      when 'sales_location' then 2
      when 'team' then 3
      when 'organization_member' then 4
      else 5
    end,
    gs.scope_id;
end;
$function$;

revoke all
on function public.get_validated_sales_actuals(uuid, date)
from public, anon, authenticated;

grant execute
on function public.get_validated_sales_actuals(uuid, date)
to authenticated;

create or replace function public.get_validated_sales_salesperson_drilldown(
  p_plan_id uuid,
  p_competence_month date
)
returns table (
  plan_id uuid,
  organization_id uuid,
  competence_month date,
  sales_location_id uuid,
  sales_location_name text,
  team_id uuid,
  team_name text,
  salesperson_member_id uuid,
  salesperson_name text,
  salesperson_email text,
  actual_value bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_organization_id uuid;
  v_operation_id uuid;
begin
  if auth.uid() is null then
    return;
  end if;

  if p_plan_id is null
     or p_competence_month is null
  then
    return;
  end if;

  if p_competence_month <>
    pg_catalog.date_trunc(
      'month',
      p_competence_month::timestamp
    )::date
  then
    raise exception using
      errcode = '22023',
      message =
        'p_competence_month deve ser o primeiro dia do mes.';
  end if;

  select
    cp.organization_id,
    cp.operation_id
  into
    v_organization_id,
    v_operation_id
  from public.commercial_plans cp
  where cp.id = p_plan_id
    and cp.status <> 'archived'
    and cp.archived_at is null
  limit 1;

  if v_organization_id is null
     or v_operation_id is null
  then
    return;
  end if;

  if not (
    coalesce(
      private.is_platform_admin(),
      false
    )
    or coalesce(
      private.has_org_role(
        v_organization_id,
        array['director']
      ),
      false
    )
  ) then
    return;
  end if;

  return query
  select
    p_plan_id,
    v_organization_id,
    p_competence_month,
    cs.sales_location_id,
    sl.name::text as sales_location_name,
    cs.team_id,
    t.name::text as team_name,
    cs.salesperson_member_id,
    coalesce(
      nullif(pr.full_name, ''),
      pr.email,
      'Vendedor sem nome'
    )::text as salesperson_name,
    pr.email::text as salesperson_email,
    pg_catalog.sum(cs.units_count)::bigint as actual_value
  from public.commercial_sales cs
  join public.sales_locations sl
    on sl.id = cs.sales_location_id
   and sl.organization_id = cs.organization_id
   and sl.operation_id = cs.operation_id
  join public.teams t
    on t.id = cs.team_id
   and t.organization_id = cs.organization_id
   and t.operation_id = cs.operation_id
  left join public.organization_members om
    on om.id = cs.salesperson_member_id
   and om.organization_id = cs.organization_id
  left join public.profiles pr
    on pr.id = om.user_id
  where cs.organization_id = v_organization_id
    and cs.operation_id = v_operation_id
    and cs.competence_month = p_competence_month
    and cs.validation_status = 'validated'
    and cs.validated_at is not null
    and cs.archived_at is null
    and cs.salesperson_member_id is not null
  group by
    cs.sales_location_id,
    sl.name,
    cs.team_id,
    t.name,
    cs.salesperson_member_id,
    pr.full_name,
    pr.email
  order by
    sl.name,
    t.name,
    salesperson_name,
    cs.salesperson_member_id;
end;
$function$;

revoke all
on function public.get_validated_sales_salesperson_drilldown(uuid, date)
from public, anon, authenticated;

grant execute
on function public.get_validated_sales_salesperson_drilldown(uuid, date)
to authenticated;

create or replace function public.get_commercial_productivity_indicators(
  p_plan_id uuid,
  p_competence_month date
)
returns table (
  plan_id uuid,
  organization_id uuid,
  competence_month date,
  metric_code text,
  label text,
  unit text,
  target_value numeric,
  operational_reference numeric,
  denominator numeric,
  validated_units bigint,
  actual_value numeric
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_organization_id uuid;
  v_operation_id uuid;
begin
  if auth.uid() is null then
    return;
  end if;

  if p_plan_id is null
     or p_competence_month is null
  then
    return;
  end if;

  if p_competence_month <>
    pg_catalog.date_trunc(
      'month',
      p_competence_month::timestamp
    )::date
  then
    raise exception using
      errcode = '22023',
      message =
        'p_competence_month deve ser o primeiro dia do mes.';
  end if;

  select
    cp.organization_id,
    cp.operation_id
  into
    v_organization_id,
    v_operation_id
  from public.commercial_plans cp
  where cp.id = p_plan_id
    and cp.status <> 'archived'
    and cp.archived_at is null
  limit 1;

  if v_organization_id is null
     or v_operation_id is null
  then
    return;
  end if;

  if not (
    coalesce(
      private.is_platform_admin(),
      false
    )
    or coalesce(
      private.has_org_role(
        v_organization_id,
        array['director']
      ),
      false
    )
  ) then
    return;
  end if;

  return query
  with indicator_goals as (
    select
      pg.id,
      pg.metric_code,
      pg.label,
      pg.unit,
      pg.target_value,
      case
        when nullif(
          pg.metadata ->> 'current_operational_reference',
          ''
        ) ~ '^[0-9]+([.][0-9]+)?$'
        then (
          pg.metadata ->> 'current_operational_reference'
        )::numeric
        else null
      end as operational_reference,
      case
        when pg.metric_code = 'average_per_salesperson'
          and nullif(
            pg.metadata ->> 'active_producers',
            ''
          ) ~ '^[0-9]+([.][0-9]+)?$'
        then (
          pg.metadata ->> 'active_producers'
        )::numeric
        when pg.metric_code = 'average_per_pdv'
          and nullif(
            pg.metadata ->> 'active_pdv_count',
            ''
          ) ~ '^[0-9]+([.][0-9]+)?$'
        then (
          pg.metadata ->> 'active_pdv_count'
        )::numeric
        else null
      end as denominator
    from public.performance_goals pg
    where pg.plan_id = p_plan_id
      and pg.organization_id = v_organization_id
      and pg.scope_type = 'organization'
      and pg.scope_id = v_organization_id
      and pg.metric_code in (
        'average_per_salesperson',
        'average_per_pdv'
      )
      and pg.period_type = 'monthly'
      and pg.status <> 'archived'
      and pg.archived_at is null
  ),
  validated_sales as (
    select
      pg_catalog.sum(cs.units_count)::bigint as validated_units
    from public.commercial_sales cs
    where cs.organization_id = v_organization_id
      and cs.operation_id = v_operation_id
      and cs.competence_month = p_competence_month
      and cs.validation_status = 'validated'
      and cs.validated_at is not null
      and cs.archived_at is null
  )
  select
    p_plan_id,
    v_organization_id,
    p_competence_month,
    ig.metric_code,
    ig.label,
    ig.unit,
    ig.target_value,
    ig.operational_reference,
    ig.denominator,
    vs.validated_units,
    case
      when vs.validated_units is null then null
      when ig.denominator is null
        or ig.denominator <= 0
      then null
      else pg_catalog.round(
        vs.validated_units::numeric
        / ig.denominator,
        2
      )
    end as actual_value
  from indicator_goals ig
  cross join validated_sales vs
  order by ig.metric_code;
end;
$function$;

revoke all
on function public.get_commercial_productivity_indicators(uuid, date)
from public, anon, authenticated;

grant execute
on function public.get_commercial_productivity_indicators(uuid, date)
to authenticated;

do $postcheck$
declare
  v_count integer;
begin
  select pg_catalog.count(*)
  into v_count
  from pg_catalog.pg_proc p
  join pg_catalog.pg_namespace n
    on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname in (
      'get_validated_sales_actuals',
      'get_validated_sales_salesperson_drilldown',
      'get_commercial_productivity_indicators'
    )
    and pg_catalog.pg_get_function_identity_arguments(p.oid)
      = 'p_plan_id uuid, p_competence_month date'
    and p.prosecdef
    and p.provolatile = 's';

  if v_count <> 3 then
    raise exception
      'Hotfix abortado: postcheck estrutural encontrou % de 3 RPCs esperadas.',
      v_count;
  end if;

  if pg_catalog.has_function_privilege(
       'anon',
       'public.get_validated_sales_actuals(uuid,date)',
       'EXECUTE'
     )
     or pg_catalog.has_function_privilege(
       'anon',
       'public.get_validated_sales_salesperson_drilldown(uuid,date)',
       'EXECUTE'
     )
     or pg_catalog.has_function_privilege(
       'anon',
       'public.get_commercial_productivity_indicators(uuid,date)',
       'EXECUTE'
     )
  then
    raise exception
      'Hotfix abortado: anon nao pode manter EXECUTE nas RPCs.';
  end if;

  if not pg_catalog.has_function_privilege(
       'authenticated',
       'public.get_validated_sales_actuals(uuid,date)',
       'EXECUTE'
     )
     or not pg_catalog.has_function_privilege(
       'authenticated',
       'public.get_validated_sales_salesperson_drilldown(uuid,date)',
       'EXECUTE'
     )
     or not pg_catalog.has_function_privilege(
       'authenticated',
       'public.get_commercial_productivity_indicators(uuid,date)',
       'EXECUTE'
     )
  then
    raise exception
      'Hotfix abortado: authenticated deve manter EXECUTE nas RPCs.';
  end if;
end;
$postcheck$;

commit;
