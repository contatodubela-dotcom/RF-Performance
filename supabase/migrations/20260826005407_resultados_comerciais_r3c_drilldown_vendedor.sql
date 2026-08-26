-- ============================================================================
-- RF Performance
-- R3C - Drilldown de vendas validadas por vendedor
--
-- Objetivo:
--   fornecer ao frontend uma visao agregada por:
--     PDV -> equipe -> vendedor
--
-- Fonte de verdade:
--   public.commercial_sales
--
-- Regras:
--   - somente vendas validadas;
--   - validated_at obrigatorio;
--   - competencia mensal explicita;
--   - venda arquivada nao entra;
--   - vendedor vem de commercial_sales.salesperson_member_id;
--   - equipe e PDV sao os gravados na propria venda;
--   - nao depende de performance_goals;
--   - nao exige que o vendedor continue atualmente como salesperson;
--   - nao exige vinculo de equipe atualmente ativo;
--   - nao expoe linhas transacionais ao frontend.
--
-- Acesso:
--   - platform_admin;
--   - director da organizacao.
--
-- Isso espelha a autorizacao atual da pagina Resultados.
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
      'R3C abortada: public.commercial_plans nao existe.';
  end if;

  if pg_catalog.to_regclass(
    'public.commercial_sales'
  ) is null then
    raise exception
      'R3C abortada: public.commercial_sales nao existe.';
  end if;

  if pg_catalog.to_regclass(
    'public.sales_locations'
  ) is null then
    raise exception
      'R3C abortada: public.sales_locations nao existe.';
  end if;

  if pg_catalog.to_regclass(
    'public.teams'
  ) is null then
    raise exception
      'R3C abortada: public.teams nao existe.';
  end if;

  if pg_catalog.to_regclass(
    'public.organization_members'
  ) is null then
    raise exception
      'R3C abortada: public.organization_members nao existe.';
  end if;

  if pg_catalog.to_regclass(
    'public.profiles'
  ) is null then
    raise exception
      'R3C abortada: public.profiles nao existe.';
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
      'R3C abortada: commercial_sales.salesperson_member_id uuid nao existe.';
  end if;

  if pg_catalog.to_regprocedure(
    'private.is_platform_admin()'
  ) is null then
    raise exception
      'R3C abortada: private.is_platform_admin() nao existe.';
  end if;

  if pg_catalog.to_regprocedure(
    'private.has_org_role(uuid,text[])'
  ) is null then
    raise exception
      'R3C abortada: private.has_org_role(uuid,text[]) nao existe.';
  end if;

  if pg_catalog.to_regprocedure(
    'public.get_validated_sales_salesperson_drilldown(uuid,date)'
  ) is not null then
    raise exception
      'R3C abortada: RPC de drilldown por vendedor ja existe.';
  end if;
end;
$guard$;

-- --------------------------------------------------------------------------
-- RPC agregadora
-- --------------------------------------------------------------------------

create function public.get_validated_sales_salesperson_drilldown(
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
  select
    p_plan_id,
    v_organization_id,
    p_competence_month,

    cs.sales_location_id,
    sl.name::text as sales_location_name,

    cs.team_id,
    t.name::text as team_name,

    cs.salesperson_member_id,

    pg_catalog.coalesce(
      nullif(pr.full_name, ''),
      pr.email,
      'Vendedor sem nome'
    )::text as salesperson_name,

    pr.email::text as salesperson_email,

    pg_catalog.sum(cs.units_count)::bigint
      as actual_value

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

-- --------------------------------------------------------------------------
-- Privilegios
-- --------------------------------------------------------------------------

revoke all
on function
  public.get_validated_sales_salesperson_drilldown(uuid, date)
from public, anon, authenticated;

grant execute
on function
  public.get_validated_sales_salesperson_drilldown(uuid, date)
to authenticated;

comment on function
  public.get_validated_sales_salesperson_drilldown(uuid, date)
is
  'Retorna vendas validadas agregadas por PDV, equipe e vendedor atribuido, usando commercial_sales como fonte transacional e sem depender de metas individuais.';

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
      'get_validated_sales_salesperson_drilldown'
    and pg_catalog.pg_get_function_identity_arguments(p.oid)
      = 'p_plan_id uuid, p_competence_month date'
  limit 1;

  if v_function_oid is null then
    raise exception
      'R3C abortada: RPC de drilldown nao foi criada.';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_proc p
    where p.oid = v_function_oid
      and p.prosecdef is true
      and p.provolatile = 's'
  ) then
    raise exception
      'R3C abortada: RPC deve ser STABLE e SECURITY DEFINER.';
  end if;

  select pg_catalog.pg_get_functiondef(
    v_function_oid
  )
  into v_definition;

  if pg_catalog.strpos(
    v_definition,
    'salesperson_member_id'
  ) = 0 then
    raise exception
      'R3C abortada: RPC nao usa salesperson_member_id.';
  end if;

  if pg_catalog.strpos(
    v_definition,
    'performance_goals'
  ) > 0 then
    raise exception
      'R3C abortada: drilldown nao deve depender de performance_goals.';
  end if;

  if pg_catalog.strpos(
    v_definition,
    'validation_status = ''validated'''
  ) = 0 then
    raise exception
      'R3C abortada: filtro de vendas validadas ausente.';
  end if;

  if not pg_catalog.has_function_privilege(
    'authenticated',
    v_function_oid,
    'EXECUTE'
  ) then
    raise exception
      'R3C abortada: authenticated sem EXECUTE.';
  end if;

  if pg_catalog.has_function_privilege(
    'anon',
    v_function_oid,
    'EXECUTE'
  ) then
    raise exception
      'R3C abortada: anon possui EXECUTE indevidamente.';
  end if;
end;
$guard$;

commit;