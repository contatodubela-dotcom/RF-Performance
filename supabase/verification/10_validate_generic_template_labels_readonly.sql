-- ============================================================================
-- RF Performance Comercial
-- Validação somente leitura — rótulos multiempresa do template comercial
-- ============================================================================

with rf_org as (
  select id
  from public.organizations
  where slug = 'rf-consorcios'
  limit 1
),
plan as (
  select cp.id
  from public.commercial_plans cp
  join rf_org o on o.id = cp.organization_id
  where cp.archived_at is null
  order by cp.created_at
  limit 1
),
checks as (
  select
    count(*) filter (
      where mr.title = 'Reunião executiva de performance'
    )::integer as generic_executive_ritual_count,
    count(*) filter (
      where mr.title ilike '%Raphael%'
    )::integer as personal_name_ritual_count,
    count(*) filter (
      where mr.responsible_role = 'EPSA / RF'
    )::integer as legacy_rf_role_count,
    count(*) filter (
      where mr.responsible_role = 'EPSA / Direção'
        and mr.title = 'Reunião executiva de performance'
    )::integer as generic_role_count
  from public.management_rituals mr
  join plan p on p.id = mr.plan_id
  where mr.archived_at is null
)
select
  case
    when generic_executive_ritual_count <> 1
      then 'FAIL_GENERIC_EXECUTIVE_RITUAL'
    when personal_name_ritual_count <> 0
      then 'FAIL_PERSONAL_NAME_FOUND'
    when legacy_rf_role_count <> 0
      then 'FAIL_LEGACY_RF_ROLE_FOUND'
    when generic_role_count <> 1
      then 'FAIL_GENERIC_ROLE'
    else 'PASS'
  end as validation_result,
  generic_executive_ritual_count,
  personal_name_ritual_count,
  legacy_rf_role_count,
  generic_role_count
from checks;
