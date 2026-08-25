-- ============================================================================
-- RF Performance
-- R3B - Apuracao de vendas validadas por vendedor
--
-- Evolui:
--   public.get_validated_sales_actuals(uuid, date)
--
-- Fonte de verdade:
--   public.commercial_sales
--
-- Mantem os escopos existentes:
--   - organization
--   - sales_location
--   - team
--
-- Adiciona:
--   - organization_member
--
-- Regra individual:
--   performance_goals.scope_id
--     = commercial_sales.salesperson_member_id
--
-- Sem vendas validadas atribuidas:
--   actual_value = NULL ("Sem apuracao")
--
-- Nao persiste resultado em performance_goals.actual_value.
-- Acesso permanece restrito a platform_admin e director.
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
      'R3B abortada: public.commercial_plans nao existe.';
  end if;

  if pg_catalog.to_regclass(
    'public.performance_goals'
  ) is null then
    raise exception
      'R3B abortada: public.performance_goals nao existe.';
  end if;

  if pg_catalog.to_regclass(
    'public.commercial_sales'
  ) is null then
    raise exception
      'R3B abortada: public.commercial_sales nao existe.';
  end if;

  if not exists (
    select 1
    from information_schema.columns c
    where c.table_schema = 'public'
      and c.table_name = 'commercial_sales'
      and c.column_name = 'salesperson_member_id'
      and c.data_type = 'uuid'
  ) then
    raise exception
      'R3B abortada: commercial_sales.salesperson_member_id uuid nao existe. R3A deve estar aplicada.';
  end if;

  if pg_catalog.to_regprocedure(
    'public.get_validated_sales_actuals(uuid,date)'
  ) is null then
    raise exception
      'R3B abortada: RPC R2B get_validated_sales_actuals nao existe.';
  end if;

  if pg_catalog.to_regprocedure(
    'private.is_platform_admin()'
  ) is null then
    raise exception
      'R3B abortada: private.is_platform_admin() nao existe.';
  end if;

  if pg_catalog.to_regprocedure(
    'private.has_org_role(uuid,text[])'
  ) is null then
    raise exception
      'R3B abortada: private.has_org_role(uuid,text[]) nao existe.';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_constraint con
    join pg_catalog.pg_class c
      on c.oid = con.conrelid
    join pg_catalog.pg_namespace n
      on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname = 'performance_goals'
      and con.contype = 'c'
      and pg_catalog.strpos(
  pg_catalog.pg_get_constraintdef(con.oid),
  'organization_member'
) > 0

  ) then
    raise exception
      'R3B abortada: performance_goals nao aceita scope_type organization_member.';
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

      when gs.scope_type = 'organization_member' then (
        select
          pg_catalog.sum(vr.units_count)::bigint
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
  'Calcula validated_sales por competencia para organizacao, PDV, equipe e organization_member a partir de commercial_sales. Para organization_member usa salesperson_member_id. Nao persiste performance_goals.actual_value.';

-- --------------------------------------------------------------------------
-- Post-check
-- --------------------------------------------------------------------------

do $guard$
declare
  v_function_oid oid;
  v_function_definition text;
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
      'R3B abortada: RPC get_validated_sales_actuals nao foi atualizada.';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_proc p
    where p.oid = v_function_oid
      and p.prosecdef is true
      and p.provolatile = 's'
  ) then
    raise exception
      'R3B abortada: RPC deve permanecer STABLE e SECURITY DEFINER.';
  end if;

  select pg_catalog.pg_get_functiondef(
    v_function_oid
  )
  into v_function_definition;

  if pg_catalog.strpos(
  v_function_definition,
  'organization_member'
) = 0 then
    raise exception
      'R3B abortada: RPC nao contem escopo organization_member.';
  end if;

  if pg_catalog.strpos(
  v_function_definition,
  'salesperson_member_id'
) = 0 then
    raise exception
      'R3B abortada: RPC nao usa salesperson_member_id.';
  end if;

  if not pg_catalog.has_function_privilege(
    'authenticated',
    v_function_oid,
    'EXECUTE'
  ) then
    raise exception
      'R3B abortada: authenticated nao possui EXECUTE na RPC.';
  end if;

  if pg_catalog.has_function_privilege(
    'anon',
    v_function_oid,
    'EXECUTE'
  ) then
    raise exception
      'R3B abortada: anon possui EXECUTE indevidamente na RPC.';
  end if;
end;
$guard$;

commit;