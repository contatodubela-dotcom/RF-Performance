-- ============================================================================
-- RF Performance Comercial
-- Validação somente leitura — template operacional demonstrável
-- ============================================================================

with rf_org as (
  select *
  from public.organizations
  where slug = 'rf-consorcios'
  limit 1
),
rf_operation as (
  select op.*
  from public.operations op
  join rf_org o on o.id = op.organization_id
  where op.slug = 'consorcio-automoveis'
  limit 1
),
pdvs as (
  select sl.*
  from public.sales_locations sl
  join rf_operation op
    on op.id = sl.operation_id
   and op.organization_id = sl.organization_id
  where sl.status = 'active'
    and sl.archived_at is null
),
teams_model as (
  select t.*
  from public.teams t
  join rf_operation op
    on op.id = t.operation_id
   and op.organization_id = t.organization_id
  where t.status = 'active'
    and t.archived_at is null
    and t.metadata ->> 'template_key' = 'commercial_acceleration_v1'
),
capacity as (
  select
    coalesce(sum((metadata ->> 'planned_supervisor_positions')::integer), 0)
      as supervisor_positions,
    coalesce(sum((metadata ->> 'planned_salesperson_capacity')::integer), 0)
      as salesperson_capacity
  from teams_model
),
trigger_check as (
  select count(*)::integer as trigger_count
  from pg_catalog.pg_trigger t
  join pg_catalog.pg_class c on c.oid = t.tgrelid
  join pg_catalog.pg_namespace n on n.oid = c.relnamespace
  where not t.tgisinternal
    and n.nspname = 'public'
    and c.relname = 'team_members'
    and t.tgname = 'team_members_enforce_single_active_salesperson_team'
),
function_check as (
  select count(*)::integer as function_count
  from pg_catalog.pg_proc p
  join pg_catalog.pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'private'
    and p.proname = 'enforce_single_active_salesperson_team'
)
select
  case
    when (select count(*) from rf_org) <> 1
      then 'FAIL_ORGANIZATION'
    when (select count(*) from rf_operation) <> 1
      then 'FAIL_OPERATION'
    when (select count(*) from pdvs) <> 3
      then 'FAIL_PDV_COUNT'
    when (
      select count(*)
      from pdvs
      where metadata ->> 'template_record' = 'true'
        and metadata ->> 'setup_status' = 'pending_confirmation'
    ) <> 3
      then 'FAIL_PDV_TEMPLATE_METADATA'
    when (select count(*) from teams_model) <> 3
      then 'FAIL_TEAM_COUNT'
    when (
      select count(*)
      from teams_model
      where sales_location_id is not null
    ) <> 3
      then 'FAIL_TEAM_PDV_LINKS'
    when (select supervisor_positions from capacity) <> 3
      then 'FAIL_SUPERVISOR_CAPACITY'
    when (select salesperson_capacity from capacity) <> 20
      then 'FAIL_SALESPERSON_CAPACITY'
    when (
      select metadata ->> 'baseline_monthly_sales'
      from rf_org
    ) <> '130'
      then 'FAIL_BASELINE'
    when (
      select metadata ->> 'growth_target_percent'
      from rf_org
    ) <> '30'
      then 'FAIL_GROWTH_TARGET'
    when (
      select metadata ->> 'target_monthly_sales'
      from rf_org
    ) <> '169'
      then 'FAIL_TARGET_SALES'
    when (select trigger_count from trigger_check) <> 1
      then 'FAIL_TRANSFER_TRIGGER'
    when (select function_count from function_check) <> 1
      then 'FAIL_TRANSFER_FUNCTION'
    else 'PASS'
  end as validation_result,

  (select count(*) from pdvs) as active_pdvs,
  (select count(*) from teams_model) as model_teams,
  (select supervisor_positions from capacity) as planned_supervisors,
  (select salesperson_capacity from capacity) as planned_salespersons,
  (select metadata ->> 'baseline_monthly_sales' from rf_org)
    as baseline_monthly_sales,
  (select metadata ->> 'growth_target_percent' from rf_org)
    as growth_target_percent,
  (select metadata ->> 'target_monthly_sales' from rf_org)
    as target_monthly_sales,
  (select trigger_count from trigger_check) as transfer_trigger_count,
  (select function_count from function_check) as transfer_function_count;
