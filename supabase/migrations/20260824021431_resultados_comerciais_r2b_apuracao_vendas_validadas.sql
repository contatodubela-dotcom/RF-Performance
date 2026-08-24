-- ============================================================================
-- RF Performance
-- R2B - Motor de apuracao de vendas validadas
--
-- Fonte de verdade:
--   public.commercial_sales
--
-- Regra:
--   - competencia = commercial_sales.competence_month
--   - somente validation_status = 'validated'
--   - somente registros nao arquivados
--   - realizado = SUM(units_count)
--   - sem vendas validadas = NULL ("Sem apuracao")
--   - nao persiste resultado em performance_goals.actual_value
--
-- Escopos suportados nesta fase:
--   - organization
--   - sales_location
--   - team
--
-- Acesso:
--   - platform_admin
--   - director da organizacao
-- ============================================================================

begin;

-- --------------------------------------------------------------------------
-- Preflight
-- --------------------------------------------------------------------------

do $guard$
begin
  if pg_catalog.to_regclass('public.commercial_plans') is null then
    raise exception
      'R2B abortada: public.commercial_plans nao existe.';
  end if;

  if pg_catalog.to_regclass('public.performance_goals') is null then
    raise exception
      'R2B abortada: public.performance_goals nao existe.';
  end if;

  if pg_catalog.to_regclass('public.commercial_sales') is null then
    raise exception
      'R2B abortada: public.commercial_sales nao existe. A R2A deve estar aplicada.';
  end if;

  if pg_catalog.to_regprocedure('private.is_platform_admin()') is null then
    raise exception
      'R2B abortada: private.is_platform_admin() nao existe.';
  end if;

  if pg_catalog.to_regprocedure(
    'private.has_org_role(uuid,text[])'
  ) is null then
    raise exception
      'R2B abortada: private.has_org_role(uuid,text[]) nao existe.';
  end if;
end;
$guard$;

-- --------------------------------------------------------------------------
-- RPC de apuracao
-- --------------------------------------------------------------------------

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
  -- A RPC nunca opera anonimamente.
  if auth.uid() is null then
    return;
  end if;

  if p_plan_id is null or p_competence_month is null then
    return;
  end if;

  -- commercial_sales.competence_month usa sempre o primeiro dia do mes.
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

  -- Resolve organizacao e operacao a partir do plano.
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

  -- Resultados comerciais R2 permanecem restritos aos perfis
  -- estrategicos que ja acessam /app/resultados.
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
        'team'
      )
  ),
  validated_rows as (
    select
      cs.sales_location_id,
      cs.team_id,
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
        select
          pg_catalog.sum(vr.units_count)::bigint
        from validated_rows vr
      )

      when gs.scope_type = 'sales_location' then (
        select
          pg_catalog.sum(vr.units_count)::bigint
        from validated_rows vr
        where vr.sales_location_id = gs.scope_id
      )

      when gs.scope_type = 'team' then (
        select
          pg_catalog.sum(vr.units_count)::bigint
        from validated_rows vr
        where vr.team_id = gs.scope_id
      )

      else null::bigint
    end as actual_value
  from goal_scopes gs
  order by
    case gs.scope_type
      when 'organization' then 1
      when 'sales_location' then 2
      when 'team' then 3
      else 4
    end,
    gs.scope_id;
end;
$function$;

-- --------------------------------------------------------------------------
-- Privilegios
-- --------------------------------------------------------------------------

revoke all
on function public.get_validated_sales_actuals(uuid, date)
from public, anon, authenticated;

grant execute
on function public.get_validated_sales_actuals(uuid, date)
to authenticated;

comment on function
  public.get_validated_sales_actuals(uuid, date)
is
  'Calcula validated_sales por competencia para organizacao, PDV e equipe a partir de commercial_sales. Nao persiste performance_goals.actual_value.';

-- --------------------------------------------------------------------------
-- Post-check
-- --------------------------------------------------------------------------

do $guard$
declare
  v_function_oid oid;
begin
  select p.oid
  into v_function_oid
  from pg_catalog.pg_proc p
  join pg_catalog.pg_namespace n
    on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'get_validated_sales_actuals'
    and pg_catalog.pg_get_function_identity_arguments(p.oid)
      = 'p_plan_id uuid, p_competence_month date'
  limit 1;

  if v_function_oid is null then
    raise exception
      'R2B abortada: RPC get_validated_sales_actuals nao foi criada.';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_proc p
    where p.oid = v_function_oid
      and p.prosecdef is true
      and p.provolatile = 's'
  ) then
    raise exception
      'R2B abortada: RPC deve ser STABLE e SECURITY DEFINER.';
  end if;

  if not pg_catalog.has_function_privilege(
    'authenticated',
    v_function_oid,
    'EXECUTE'
  ) then
    raise exception
      'R2B abortada: authenticated nao possui EXECUTE na RPC.';
  end if;

  if pg_catalog.has_function_privilege(
    'anon',
    v_function_oid,
    'EXECUTE'
  ) then
    raise exception
      'R2B abortada: anon possui EXECUTE indevidamente na RPC.';
  end if;
end;
$guard$;

commit;