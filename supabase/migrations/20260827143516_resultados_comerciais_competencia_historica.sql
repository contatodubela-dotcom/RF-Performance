begin;

-- ============================================================================
-- RF Performance
-- Resultados Comerciais — competência histórica
--
-- Objetivos:
-- 1. reconstruir as metas mensais vigentes em cada competência usando a
--    trilha imutável de public.audit_logs;
-- 2. disponibilizar somente competências operacionais do plano;
-- 3. impedir que uma competência histórica utilize metas/escopos atuais;
-- 4. preservar public.commercial_sales como fonte exclusiva do realizado;
-- 5. preservar NULL quando não existir apuração;
-- 6. não utilizar performance_goals.actual_value como fallback;
-- 7. manter o drilldown histórico por vendedor inalterado.
--
-- Regra temporal:
-- - o snapshot da competência utiliza o último estado auditado da meta
--   registrado antes do primeiro dia da competência seguinte;
-- - metas template não participam dos Resultados Comerciais;
-- - a primeira competência operacional é derivada da primeira versão
--   auditada da meta organizacional validated_sales com is_template = false.
-- ============================================================================


-- ============================================================================
-- 1. PREFLIGHT
-- ============================================================================

do $preflight$
begin
  if pg_catalog.to_regclass(
    'public.commercial_plans'
  ) is null then
    raise exception
      'Competencia historica abortada: public.commercial_plans ausente.';
  end if;

  if pg_catalog.to_regclass(
    'public.performance_goals'
  ) is null then
    raise exception
      'Competencia historica abortada: public.performance_goals ausente.';
  end if;

  if pg_catalog.to_regclass(
    'public.audit_logs'
  ) is null then
    raise exception
      'Competencia historica abortada: public.audit_logs ausente.';
  end if;

  if pg_catalog.to_regclass(
    'public.commercial_sales'
  ) is null then
    raise exception
      'Competencia historica abortada: public.commercial_sales ausente.';
  end if;

  if pg_catalog.to_regprocedure(
    'public.get_validated_sales_actuals(uuid,date)'
  ) is null then
    raise exception
      'Competencia historica abortada: get_validated_sales_actuals(uuid,date) ausente.';
  end if;

  if pg_catalog.to_regprocedure(
    'public.get_validated_sales_salesperson_drilldown(uuid,date)'
  ) is null then
    raise exception
      'Competencia historica abortada: get_validated_sales_salesperson_drilldown(uuid,date) ausente.';
  end if;

  if pg_catalog.to_regprocedure(
    'public.get_commercial_productivity_indicators(uuid,date)'
  ) is null then
    raise exception
      'Competencia historica abortada: get_commercial_productivity_indicators(uuid,date) ausente.';
  end if;
end;
$preflight$;


-- ============================================================================
-- 2. METAS VIGENTES NA COMPETÊNCIA
--
-- A função reconstrói o estado histórico usando audit_logs.
--
-- IMPORTANTE:
-- - somente metas mensais, operacionais e não arquivadas;
-- - actual_value é sempre NULL neste contrato;
-- - realizado continua sendo calculado exclusivamente pelas RPCs que leem
--   public.commercial_sales.
-- ============================================================================

create or replace function public.get_performance_goals_for_competence(
  p_plan_id uuid,
  p_competence_month date
)
returns table (
  id uuid,
  organization_id uuid,
  plan_id uuid,
  scope_type text,
  scope_id uuid,
  metric_code text,
  label text,
  baseline_value numeric,
  target_value numeric,
  actual_value numeric,
  unit text,
  period_type text,
  status text,
  setup_status text,
  is_template boolean,
  metadata jsonb
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_organization_id uuid;
  v_cutoff timestamptz;
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
    cp.organization_id
  into
    v_organization_id
  from public.commercial_plans cp
  where cp.id = p_plan_id
    and cp.status <> 'archived'
    and cp.archived_at is null
  limit 1;

  if v_organization_id is null then
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

  -- Cutoff exclusivo: primeiro instante UTC do mês seguinte.
  v_cutoff :=
    (
      (
        p_competence_month
        + interval '1 month'
      )::timestamp
      at time zone 'UTC'
    );

  return query
  with latest_audit as (
    select distinct on (al.entity_id)
      al.entity_id,
      al.action,
      al.new_values
    from public.audit_logs al
    where al.entity_type = 'performance_goals'
      and al.entity_id is not null
      and coalesce(
        al.new_values ->> 'plan_id',
        al.old_values ->> 'plan_id'
      ) = p_plan_id::text
      and al.created_at < v_cutoff
    order by
      al.entity_id,
      al.created_at desc,
      al.id desc
  ),
  active_audit as (
    select
      la.entity_id,
      la.new_values
    from latest_audit la
    where la.action <> 'delete'
      and la.new_values is not null
  ),
  goal_states as (
    select
      goal.id,
      goal.organization_id,
      goal.plan_id,
      goal.scope_type,
      goal.scope_id,
      goal.metric_code,
      goal.label,
      goal.baseline_value,
      goal.target_value,
      goal.unit,
      goal.period_type,
      goal.status,
      goal.setup_status,
      goal.is_template,
      goal.metadata,
      goal.archived_at
    from active_audit aa
    cross join lateral pg_catalog.jsonb_to_record(
      aa.new_values
    ) as goal (
      id uuid,
      organization_id uuid,
      plan_id uuid,
      scope_type text,
      scope_id uuid,
      metric_code text,
      label text,
      baseline_value numeric,
      target_value numeric,
      actual_value numeric,
      unit text,
      period_type text,
      status text,
      setup_status text,
      is_template boolean,
      metadata jsonb,
      archived_at timestamptz
    )
  )
  select
    gs.id,
    gs.organization_id,
    gs.plan_id,
    gs.scope_type,
    gs.scope_id,
    gs.metric_code,
    gs.label,
    gs.baseline_value,
    gs.target_value,

    -- Nunca reutilizar o actual_value persistido da meta.
    null::numeric as actual_value,

    gs.unit,
    gs.period_type,
    gs.status,
    gs.setup_status,
    gs.is_template,
    coalesce(
      gs.metadata,
      '{}'::jsonb
    ) as metadata
  from goal_states gs
  where gs.organization_id = v_organization_id
    and gs.plan_id = p_plan_id
    and gs.period_type = 'monthly'
    and gs.status <> 'archived'
    and gs.archived_at is null
    and gs.is_template is false
  order by
    case gs.scope_type
      when 'organization' then 1
      when 'sales_location' then 2
      when 'team' then 3
      when 'organization_member' then 4
      else 5
    end,
    gs.label,
    gs.id;
end;
$function$;

revoke all
on function public.get_performance_goals_for_competence(uuid, date)
from public, anon, authenticated;

grant execute
on function public.get_performance_goals_for_competence(uuid, date)
to authenticated;

comment on function public.get_performance_goals_for_competence(uuid, date)
is
'Retorna o snapshot auditado das metas mensais operacionais vigente na competência. actual_value é sempre NULL e deve ser apurado pelas RPCs transacionais.';


-- ============================================================================
-- 3. COMPETÊNCIAS OPERACIONAIS DISPONÍVEIS
--
-- O primeiro mês é derivado da primeira versão auditada da meta
-- organizacional validated_sales que deixou de ser template.
--
-- A série segue até a competência corrente mesmo sem vendas registradas,
-- permitindo exibir corretamente "Sem apuração".
-- ============================================================================

create or replace function public.get_commercial_result_competences(
  p_plan_id uuid
)
returns table (
  competence_month date,
  is_current boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_organization_id uuid;
  v_first_competence date;
  v_current_competence date;
begin
  if auth.uid() is null then
    return;
  end if;

  if p_plan_id is null then
    return;
  end if;

  select
    cp.organization_id
  into
    v_organization_id
  from public.commercial_plans cp
  where cp.id = p_plan_id
    and cp.status <> 'archived'
    and cp.archived_at is null
  limit 1;

  if v_organization_id is null then
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

  select
    pg_catalog.min(
      pg_catalog.date_trunc(
        'month',
        al.created_at at time zone 'UTC'
      )::date
    )
  into
    v_first_competence
  from public.audit_logs al
  where al.entity_type = 'performance_goals'
    and al.new_values is not null
    and al.new_values ->> 'plan_id' = p_plan_id::text
    and al.new_values ->> 'organization_id'
      = v_organization_id::text
    and al.new_values ->> 'scope_type'
      = 'organization'
    and al.new_values ->> 'scope_id'
      = v_organization_id::text
    and al.new_values ->> 'metric_code'
      = 'validated_sales'
    and al.new_values ->> 'period_type'
      = 'monthly'
    and al.new_values ->> 'is_template'
      = 'false'
    and coalesce(
      al.new_values ->> 'status',
      ''
    ) <> 'archived'
    and nullif(
      al.new_values ->> 'archived_at',
      ''
    ) is null;

  if v_first_competence is null then
    return;
  end if;

  v_current_competence :=
    pg_catalog.date_trunc(
      'month',
      pg_catalog.now() at time zone 'UTC'
    )::date;

  if v_first_competence > v_current_competence then
    return;
  end if;

  return query
  select
    gs.value::date as competence_month,
    (
      gs.value::date = v_current_competence
    ) as is_current
  from pg_catalog.generate_series(
    v_first_competence::timestamp,
    v_current_competence::timestamp,
    interval '1 month'
  ) as gs(value)
  order by
    gs.value;
end;
$function$;

revoke all
on function public.get_commercial_result_competences(uuid)
from public, anon, authenticated;

grant execute
on function public.get_commercial_result_competences(uuid)
to authenticated;

comment on function public.get_commercial_result_competences(uuid)
is
'Lista competências operacionais do plano desde a primeira meta mensal validated_sales não-template até o mês corrente, inclusive meses sem apuração.';


-- ============================================================================
-- 4. APURAÇÃO DE VENDAS VALIDADAS POR ESCOPO
--
-- Evolução da função existente:
-- - realizado continua vindo somente de commercial_sales;
-- - os escopos agora vêm do snapshot histórico da competência,
--   e não do estado atual de performance_goals.
-- ============================================================================

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
    from public.get_performance_goals_for_competence(
      p_plan_id,
      p_competence_month
    ) pg
    where pg.metric_code = 'validated_sales'
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
          pg_catalog.sum(
            vr.units_count
          )::bigint
        from validated_rows vr
      )

      when gs.scope_type = 'sales_location' then (
        select
          pg_catalog.sum(
            vr.units_count
          )::bigint
        from validated_rows vr
        where vr.sales_location_id = gs.scope_id
      )

      when gs.scope_type = 'team' then (
        select
          pg_catalog.sum(
            vr.units_count
          )::bigint
        from validated_rows vr
        where vr.team_id = gs.scope_id
      )

      when gs.scope_type = 'organization_member' then (
        select
          pg_catalog.sum(
            vr.units_count
          )::bigint
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


-- ============================================================================
-- 5. INDICADORES DE PRODUTIVIDADE
--
-- Evolução da função existente:
-- - numerador continua vindo de commercial_sales;
-- - target, referência operacional e denominadores passam a vir do snapshot
--   histórico da competência.
-- ============================================================================

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
          pg.metadata
          ->> 'current_operational_reference',
          ''
        ) ~ '^[0-9]+([.][0-9]+)?$'
        then (
          pg.metadata
          ->> 'current_operational_reference'
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
          pg.metadata
          ->> 'active_producers'
        )::numeric

        when pg.metric_code = 'average_per_pdv'
          and nullif(
            pg.metadata ->> 'active_pdv_count',
            ''
          ) ~ '^[0-9]+([.][0-9]+)?$'
        then (
          pg.metadata
          ->> 'active_pdv_count'
        )::numeric

        else null
      end as denominator
    from public.get_performance_goals_for_competence(
      p_plan_id,
      p_competence_month
    ) pg
    where pg.organization_id = v_organization_id
      and pg.scope_type = 'organization'
      and pg.scope_id = v_organization_id
      and pg.metric_code in (
        'average_per_salesperson',
        'average_per_pdv'
      )
  ),
  validated_sales as (
    select
      pg_catalog.sum(
        cs.units_count
      )::bigint as validated_units
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
      when vs.validated_units is null then
        null

      when ig.denominator is null
        or ig.denominator <= 0
      then
        null

      else
        pg_catalog.round(
          vs.validated_units::numeric
          / ig.denominator,
          2
        )
    end as actual_value

  from indicator_goals ig
  cross join validated_sales vs
  order by
    ig.metric_code;
end;
$function$;

revoke all
on function public.get_commercial_productivity_indicators(uuid, date)
from public, anon, authenticated;

grant execute
on function public.get_commercial_productivity_indicators(uuid, date)
to authenticated;


-- ============================================================================
-- 6. POSTCHECK
-- ============================================================================

do $postcheck$
declare
  v_count integer;
begin
  select
    pg_catalog.count(*)
  into
    v_count
  from pg_catalog.pg_proc p
  join pg_catalog.pg_namespace n
    on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.prosecdef
    and p.provolatile = 's'
    and (
      (
        p.proname =
          'get_performance_goals_for_competence'
        and pg_catalog.pg_get_function_identity_arguments(
          p.oid
        ) =
          'p_plan_id uuid, p_competence_month date'
      )
      or
      (
        p.proname =
          'get_commercial_result_competences'
        and pg_catalog.pg_get_function_identity_arguments(
          p.oid
        ) =
          'p_plan_id uuid'
      )
      or
      (
        p.proname =
          'get_validated_sales_actuals'
        and pg_catalog.pg_get_function_identity_arguments(
          p.oid
        ) =
          'p_plan_id uuid, p_competence_month date'
      )
      or
      (
        p.proname =
          'get_commercial_productivity_indicators'
        and pg_catalog.pg_get_function_identity_arguments(
          p.oid
        ) =
          'p_plan_id uuid, p_competence_month date'
      )
    );

  if v_count <> 4 then
    raise exception
      'Competencia historica abortada: postcheck estrutural encontrou % de 4 RPCs esperadas.',
      v_count;
  end if;

  if not pg_catalog.has_function_privilege(
    'authenticated',
    'public.get_performance_goals_for_competence(uuid,date)',
    'EXECUTE'
  ) then
    raise exception
      'Competencia historica abortada: authenticated não executa get_performance_goals_for_competence.';
  end if;

  if not pg_catalog.has_function_privilege(
    'authenticated',
    'public.get_commercial_result_competences(uuid)',
    'EXECUTE'
  ) then
    raise exception
      'Competencia historica abortada: authenticated não executa get_commercial_result_competences.';
  end if;

  if not pg_catalog.has_function_privilege(
    'authenticated',
    'public.get_validated_sales_actuals(uuid,date)',
    'EXECUTE'
  ) then
    raise exception
      'Competencia historica abortada: authenticated não executa get_validated_sales_actuals.';
  end if;

  if not pg_catalog.has_function_privilege(
    'authenticated',
    'public.get_commercial_productivity_indicators(uuid,date)',
    'EXECUTE'
  ) then
    raise exception
      'Competencia historica abortada: authenticated não executa get_commercial_productivity_indicators.';
  end if;

  if pg_catalog.has_function_privilege(
    'anon',
    'public.get_performance_goals_for_competence(uuid,date)',
    'EXECUTE'
  ) then
    raise exception
      'Competencia historica abortada: anon ainda executa get_performance_goals_for_competence.';
  end if;

  if pg_catalog.has_function_privilege(
    'anon',
    'public.get_commercial_result_competences(uuid)',
    'EXECUTE'
  ) then
    raise exception
      'Competencia historica abortada: anon ainda executa get_commercial_result_competences.';
  end if;

  if pg_catalog.has_function_privilege(
    'anon',
    'public.get_validated_sales_actuals(uuid,date)',
    'EXECUTE'
  ) then
    raise exception
      'Competencia historica abortada: anon ainda executa get_validated_sales_actuals.';
  end if;

  if pg_catalog.has_function_privilege(
    'anon',
    'public.get_commercial_productivity_indicators(uuid,date)',
    'EXECUTE'
  ) then
    raise exception
      'Competencia historica abortada: anon ainda executa get_commercial_productivity_indicators.';
  end if;

  if pg_catalog.to_regprocedure(
    'public.get_validated_sales_salesperson_drilldown(uuid,date)'
  ) is null then
    raise exception
      'Competencia historica abortada: drilldown por vendedor deixou de existir.';
  end if;
end;
$postcheck$;

commit;