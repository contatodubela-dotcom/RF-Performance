-- ============================================================================
-- RF Performance
-- R4 - Indicadores comerciais de produtividade
--
-- Indicadores:
--   average_per_salesperson
--   average_per_pdv
--
-- Fonte do numerador:
--   public.commercial_sales
--
-- Fonte dos denominadores:
--   performance_goals.metadata
--
-- Fórmulas:
--   average_per_salesperson =
--     vendas validadas / active_producers
--
--   average_per_pdv =
--     vendas validadas / active_pdv_count
--
-- Regras:
--   - somente vendas validadas;
--   - validated_at obrigatorio;
--   - venda arquivada nao entra;
--   - competencia mensal explicita;
--   - sem vendas validadas => actual_value NULL;
--   - denominador ausente, invalido ou <= 0 => actual_value NULL;
--   - performance_goals.actual_value NAO e persistido;
--   - somente indicadores organizacionais mensais;
--   - acesso alinhado a pagina Resultados:
--       platform_admin ou director.
-- ============================================================================

begin;

-- --------------------------------------------------------------------------
-- Preflight
-- --------------------------------------------------------------------------

do $guard$
begin
  if pg_catalog.to_regclass(
    'public.commercial_plans'
  ) is null then
    raise exception
      'R4 abortada: public.commercial_plans nao existe.';
  end if;

  if pg_catalog.to_regclass(
    'public.performance_goals'
  ) is null then
    raise exception
      'R4 abortada: public.performance_goals nao existe.';
  end if;

  if pg_catalog.to_regclass(
    'public.commercial_sales'
  ) is null then
    raise exception
      'R4 abortada: public.commercial_sales nao existe.';
  end if;

  if pg_catalog.to_regprocedure(
    'private.is_platform_admin()'
  ) is null then
    raise exception
      'R4 abortada: private.is_platform_admin() nao existe.';
  end if;

  if pg_catalog.to_regprocedure(
    'private.has_org_role(uuid,text[])'
  ) is null then
    raise exception
      'R4 abortada: private.has_org_role(uuid,text[]) nao existe.';
  end if;

  if pg_catalog.to_regprocedure(
    'public.get_commercial_productivity_indicators(uuid,date)'
  ) is not null then
    raise exception
      'R4 abortada: RPC de indicadores de produtividade ja existe.';
  end if;
end;
$guard$;

-- --------------------------------------------------------------------------
-- RPC
-- --------------------------------------------------------------------------

create function public.get_commercial_productivity_indicators(
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
    pg_catalog.coalesce(
      private.is_platform_admin(),
      false
    )
    or pg_catalog.coalesce(
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
      pg_catalog.sum(cs.units_count)::bigint
        as validated_units

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

-- --------------------------------------------------------------------------
-- Privilegios
-- --------------------------------------------------------------------------

revoke all
on function
  public.get_commercial_productivity_indicators(uuid, date)
from public, anon, authenticated;

grant execute
on function
  public.get_commercial_productivity_indicators(uuid, date)
to authenticated;

comment on function
  public.get_commercial_productivity_indicators(uuid, date)
is
  'Calcula indicadores mensais de produtividade comercial a partir de commercial_sales e dos denominadores operacionais definidos em performance_goals.metadata, sem persistir actual_value.';

-- --------------------------------------------------------------------------
-- Post-check
-- --------------------------------------------------------------------------

do $guard$
declare
  v_function_oid oid;
  v_definition text;
begin
  select p.oid
  into v_function_oid
  from pg_catalog.pg_proc p
  join pg_catalog.pg_namespace n
    on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname =
      'get_commercial_productivity_indicators'
    and pg_catalog.pg_get_function_identity_arguments(p.oid)
      = 'p_plan_id uuid, p_competence_month date'
  limit 1;

  if v_function_oid is null then
    raise exception
      'R4 abortada: RPC de indicadores nao foi criada.';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_proc p
    where p.oid = v_function_oid
      and p.prosecdef is true
      and p.provolatile = 's'
  ) then
    raise exception
      'R4 abortada: RPC deve ser STABLE e SECURITY DEFINER.';
  end if;

  select pg_catalog.pg_get_functiondef(
    v_function_oid
  )
  into v_definition;

  if pg_catalog.strpos(
    v_definition,
    'average_per_salesperson'
  ) = 0 then
    raise exception
      'R4 abortada: indicador average_per_salesperson ausente.';
  end if;

  if pg_catalog.strpos(
    v_definition,
    'average_per_pdv'
  ) = 0 then
    raise exception
      'R4 abortada: indicador average_per_pdv ausente.';
  end if;

  if pg_catalog.strpos(
    v_definition,
    'active_producers'
  ) = 0 then
    raise exception
      'R4 abortada: denominador active_producers ausente.';
  end if;

  if pg_catalog.strpos(
    v_definition,
    'active_pdv_count'
  ) = 0 then
    raise exception
      'R4 abortada: denominador active_pdv_count ausente.';
  end if;

  if pg_catalog.strpos(
    v_definition,
    'validation_status = ''validated'''
  ) = 0 then
    raise exception
      'R4 abortada: filtro de vendas validadas ausente.';
  end if;

  if pg_catalog.strpos(
    v_definition,
    'actual_value ='
  ) > 0 then
    raise exception
      'R4 abortada: RPC nao deve persistir performance_goals.actual_value.';
  end if;

  if not pg_catalog.has_function_privilege(
    'authenticated',
    v_function_oid,
    'EXECUTE'
  ) then
    raise exception
      'R4 abortada: authenticated sem EXECUTE.';
  end if;

  if pg_catalog.has_function_privilege(
    'anon',
    v_function_oid,
    'EXECUTE'
  ) then
    raise exception
      'R4 abortada: anon possui EXECUTE indevidamente.';
  end if;
end;
$guard$;

commit;