-- ============================================================================
-- RF Performance Comercial
-- Validação somente leitura — plano de 90 dias e gestão comercial
-- ============================================================================

with rf_org as (
  select id from public.organizations where slug = 'rf-consorcios' limit 1
),
plan as (
  select cp.*
  from public.commercial_plans cp
  join rf_org o on o.id = cp.organization_id
  where cp.title = 'Plano de Aceleração Comercial — 90 Dias'
  limit 1
),
counts as (
  select
    (select count(*) from plan)::integer as plan_count,
    (select count(*) from public.plan_phases pp join plan p on p.id = pp.plan_id)::integer as phase_count,
    (select count(*) from public.plan_actions pa join plan p on p.id = pa.plan_id)::integer as action_count,
    (select count(*) from public.performance_goals pg join plan p on p.id = pg.plan_id)::integer as goal_count,
    (select count(*) from public.training_modules tm join plan p on p.id = tm.plan_id)::integer as training_count,
    (select count(*) from public.management_rituals mr join plan p on p.id = mr.plan_id)::integer as ritual_count,
    (select count(*) from public.meeting_records mr join plan p on p.id = mr.plan_id)::integer as meeting_count,
    (select count(*) from public.feedback_records fr join plan p on p.id = fr.plan_id)::integer as feedback_count,
    (select count(*) from pg_catalog.pg_policies where schemaname = 'public' and tablename in (
      'commercial_plans', 'plan_phases', 'plan_actions', 'performance_goals',
      'training_modules', 'management_rituals', 'meeting_records', 'feedback_records'
    ))::integer as policy_count,
    (select count(*) from information_schema.role_table_grants where grantee = 'anon' and table_schema = 'public' and table_name in (
      'commercial_plans', 'plan_phases', 'plan_actions', 'performance_goals',
      'training_modules', 'management_rituals', 'meeting_records', 'feedback_records'
    ))::integer as anon_grants
)
select
  case
    when c.plan_count <> 1 then 'FAIL_PLAN'
    when c.phase_count <> 4 then 'FAIL_PHASES'
    when c.action_count <> 31 then 'FAIL_ACTIONS'
    when c.goal_count <> 12 then 'FAIL_GOALS'
    when c.training_count <> 10 then 'FAIL_TRAINING'
    when c.ritual_count <> 9 then 'FAIL_RITUALS'
    when c.meeting_count <> 0 then 'FAIL_FAKE_MEETINGS'
    when c.feedback_count <> 0 then 'FAIL_FAKE_FEEDBACKS'
    when c.anon_grants <> 0 then 'FAIL_ANON_GRANTS'
    when (select baseline_monthly_sales from plan) <> 130 then 'FAIL_BASELINE'
    when (select target_monthly_sales from plan) <> 169 then 'FAIL_TARGET'
    when (select growth_target_percent from plan) <> 30 then 'FAIL_GROWTH'
    else 'PASS'
  end as validation_result,
  c.*,
  (select baseline_monthly_sales from plan) as baseline_monthly_sales,
  (select target_monthly_sales from plan) as target_monthly_sales,
  (select growth_target_percent from plan) as growth_target_percent,
  (select status from plan) as plan_status,
  (select setup_status from plan) as setup_status
from counts c;
