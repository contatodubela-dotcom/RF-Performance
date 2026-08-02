-- ============================================================================
-- RF Performance Comercial
-- Validação somente leitura — Fase 2 do plano e das metas
-- Não altera dados.
-- ============================================================================

with target_org as (
  select o.id, o.slug, o.metadata
  from public.organizations o
  where o.slug = 'rf-consorcios'
  limit 1
),
eligible_plans as (
  select cp.*
  from public.commercial_plans cp
  join target_org o
    on o.id = cp.organization_id
  where cp.status <> 'archived'
),
selected_plan as (
  select ep.*
  from eligible_plans ep
  order by ep.created_at asc
  limit 1
),
location_goals as (
  select
    pg.*,
    sl.name as scope_name,
    sl.metadata as scope_metadata
  from public.performance_goals pg
  join selected_plan sp
    on sp.id = pg.plan_id
  join public.sales_locations sl
    on sl.id = pg.scope_id
   and sl.organization_id = pg.organization_id
  where pg.scope_type = 'sales_location'
    and pg.metric_code = 'validated_sales'
    and pg.status <> 'archived'
    and sl.status = 'active'
),
team_goals as (
  select
    pg.*,
    t.name as scope_name,
    t.metadata as scope_metadata
  from public.performance_goals pg
  join selected_plan sp
    on sp.id = pg.plan_id
  join public.teams t
    on t.id = pg.scope_id
   and t.organization_id = pg.organization_id
  where pg.scope_type = 'team'
    and pg.metric_code = 'validated_sales'
    and pg.status <> 'archived'
    and t.status = 'active'
),
legacy_references as (
  select
    (
      select count(*)
      from selected_plan sp
      where concat_ws(
        ' ',
        sp.description,
        sp.recognition_criteria,
        sp.metadata::text
      ) ~* '(130|169|30%|3[[:space:]]+PDVs|3[[:space:]]+supervisores|20[[:space:]]+vendedores|PDV Modelo|Equipe Modelo|provisional_equal_split)'
    )
    +
    (
      select count(*)
      from public.plan_phases pp
      join selected_plan sp on sp.id = pp.plan_id
      where pp.status <> 'archived'
        and concat_ws(
          ' ',
          pp.name,
          pp.objective,
          pp.metadata::text
        ) ~* '(130|169|30%|3[[:space:]]+PDVs|3[[:space:]]+supervisores|20[[:space:]]+vendedores|PDV Modelo|Equipe Modelo|provisional_equal_split)'
    )
    +
    (
      select count(*)
      from public.plan_actions pa
      join selected_plan sp on sp.id = pa.plan_id
      where pa.status <> 'archived'
        and concat_ws(
          ' ',
          pa.title,
          pa.description,
          pa.metadata::text
        ) ~* '(130|169|30%|3[[:space:]]+PDVs|3[[:space:]]+supervisores|20[[:space:]]+vendedores|PDV Modelo|Equipe Modelo|provisional_equal_split)'
    )
    +
    (
      select count(*)
      from public.performance_goals pg
      join selected_plan sp on sp.id = pg.plan_id
      where pg.status <> 'archived'
        and concat_ws(
          ' ',
          pg.label,
          pg.baseline_value::text,
          pg.target_value::text,
          pg.metadata::text
        ) ~* '(130|169|30%|43[.]3|56[.]3|PDV Modelo|Equipe Modelo|provisional_equal_split)'
    ) as count
),
checks as (
  select
    exists (select 1 from target_org) as organization_found,
    (select count(*) from eligible_plans) = 1
      as exactly_one_non_archived_plan,

    exists (
      select 1
      from selected_plan sp
      where sp.baseline_monthly_sales is null
        and sp.target_monthly_sales = 175
        and sp.growth_target_percent is null
        and sp.setup_status = 'pending_confirmation'
        and sp.is_template = false
    ) as plan_references_valid,

    exists (
      select 1
      from target_org o
      where o.metadata ->> 'historical_baseline_status'
              = 'pending_official_dashboard_validation'
        and (o.metadata ->> 'current_operational_reference')::numeric
              = 140
        and (o.metadata ->> 'full_capacity_reference')::numeric
              = 175
        and (o.metadata ->> 'minimum_monthly_sales_per_producer')::numeric
              = 7
    ) as organization_references_valid,

    exists (
      select 1
      from selected_plan sp
      where (sp.metadata #>> '{expected_structure,pdvs}')::integer = 5
        and (sp.metadata #>> '{expected_structure,teams}')::integer = 5
        and (sp.metadata #>> '{expected_structure,supervisor_sellers}')::integer = 5
        and (sp.metadata #>> '{expected_structure,salespersons}')::integer = 15
        and (sp.metadata #>> '{expected_structure,active_producers}')::integer = 20
        and (sp.metadata #>> '{expected_structure,vacancies}')::integer = 5
        and (sp.metadata #>> '{expected_structure,full_capacity_producers}')::integer = 25
    ) as plan_structure_valid,

    exists (
      select 1
      from public.plan_phases pp
      join selected_plan sp on sp.id = pp.plan_id
      where pp.sequence_no = 1
        and pp.objective ilike '%histórico oficial%'
        and pp.objective ilike '%cinco PDVs%'
    ) as phase_one_updated,

    exists (
      select 1
      from public.plan_actions pa
      join selected_plan sp on sp.id = pa.plan_id
      where pa.title = 'Validar o baseline histórico oficial'
    )
    and exists (
      select 1
      from public.plan_actions pa
      join selected_plan sp on sp.id = pa.plan_id
      where pa.title = 'Diagnosticar o funil dos 5 PDVs'
    )
    and exists (
      select 1
      from public.plan_actions pa
      join selected_plan sp on sp.id = pa.plan_id
      where pa.title = 'Mapear competências dos 20 produtores ativos'
    )
    and exists (
      select 1
      from public.plan_actions pa
      join selected_plan sp on sp.id = pa.plan_id
      where pa.title = 'Avaliar os 5 supervisores-vendedores'
    ) as actions_updated,

    exists (
      select 1
      from public.performance_goals pg
      join selected_plan sp on sp.id = pg.plan_id
      join target_org o on o.id = pg.scope_id
      where pg.scope_type = 'organization'
        and pg.metric_code = 'validated_sales'
        and pg.baseline_value is null
        and pg.target_value = 175
        and (pg.metadata ->> 'current_operational_reference')::numeric = 140
        and pg.setup_status = 'pending_confirmation'
        and pg.is_template = false
    ) as organization_goal_valid,

    (select count(*) from location_goals) = 5
      as five_location_goals,
    (select count(*) from team_goals) = 5
      as five_team_goals,

    not exists (
      select 1
      from location_goals lg
      where lg.baseline_value is not null
         or lg.target_value <> 35
         or (lg.metadata ->> 'current_operational_reference')::numeric
              <> (lg.scope_metadata ->> 'adjusted_monthly_capacity_reference')::numeric
         or lg.label <> 'Cotas validadas — ' || lg.scope_name
         or lg.setup_status <> 'pending_confirmation'
         or lg.is_template <> false
    ) as location_goals_valid,

    not exists (
      select 1
      from team_goals tg
      where tg.baseline_value is not null
         or tg.target_value <> 35
         or (tg.metadata ->> 'current_operational_reference')::numeric
              <> (tg.scope_metadata ->> 'adjusted_monthly_capacity_reference')::numeric
         or tg.label <> 'Cotas validadas — ' || tg.scope_name
         or tg.setup_status <> 'pending_confirmation'
         or tg.is_template <> false
    ) as team_goals_valid,

    coalesce(
      (
        select sum(
          (lg.metadata ->> 'current_operational_reference')::numeric
        )
        from location_goals lg
      ),
      0
    ) = 140
    and coalesce(
      (select sum(lg.target_value) from location_goals lg),
      0
    ) = 175
      as location_totals_valid,

    coalesce(
      (
        select sum(
          (tg.metadata ->> 'current_operational_reference')::numeric
        )
        from team_goals tg
      ),
      0
    ) = 140
    and coalesce(
      (select sum(tg.target_value) from team_goals tg),
      0
    ) = 175
      as team_totals_valid,

    (select count from legacy_references) = 0
      as no_legacy_references
),
result as (
  select
    *,
    (
      organization_found
      and exactly_one_non_archived_plan
      and plan_references_valid
      and organization_references_valid
      and plan_structure_valid
      and phase_one_updated
      and actions_updated
      and organization_goal_valid
      and five_location_goals
      and five_team_goals
      and location_goals_valid
      and team_goals_valid
      and location_totals_valid
      and team_totals_valid
      and no_legacy_references
    ) as all_checks_pass
  from checks
)
select
  case
    when r.all_checks_pass then 'PASS'
    else 'FAIL'
  end as validation_result,

  r.organization_found,
  r.exactly_one_non_archived_plan,
  r.plan_references_valid,
  r.organization_references_valid,
  r.plan_structure_valid,
  r.phase_one_updated,
  r.actions_updated,
  r.organization_goal_valid,
  r.five_location_goals,
  r.five_team_goals,
  r.location_goals_valid,
  r.team_goals_valid,
  r.location_totals_valid,
  r.team_totals_valid,
  r.no_legacy_references,

  (
    select jsonb_build_object(
      'non_archived_plan_count',
        (select count(*) from eligible_plans),
      'phase_count',
        (
          select count(*)
          from public.plan_phases pp
          join selected_plan sp on sp.id = pp.plan_id
          where pp.status <> 'archived'
        ),
      'action_count',
        (
          select count(*)
          from public.plan_actions pa
          join selected_plan sp on sp.id = pa.plan_id
          where pa.status <> 'archived'
        ),
      'completed_action_count',
        (
          select count(*)
          from public.plan_actions pa
          join selected_plan sp on sp.id = pa.plan_id
          where pa.status = 'completed'
        ),
      'in_progress_phase_count',
        (
          select count(*)
          from public.plan_phases pp
          join selected_plan sp on sp.id = pp.plan_id
          where pp.status = 'in_progress'
        ),
      'location_goal_count',
        (select count(*) from location_goals),
      'team_goal_count',
        (select count(*) from team_goals),
      'location_current_total',
        coalesce(
          (
            select sum(
              (lg.metadata ->> 'current_operational_reference')::numeric
            )
            from location_goals lg
          ),
          0
        ),
      'location_full_total',
        coalesce(
          (select sum(lg.target_value) from location_goals lg),
          0
        ),
      'team_current_total',
        coalesce(
          (
            select sum(
              (tg.metadata ->> 'current_operational_reference')::numeric
            )
            from team_goals tg
          ),
          0
        ),
      'team_full_total',
        coalesce(
          (select sum(tg.target_value) from team_goals tg),
          0
        ),
      'legacy_reference_count',
        (select count from legacy_references)
    )
  ) as validation_details,

  (
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'scope_type', x.scope_type,
          'scope_name', x.scope_name,
          'current_reference',
            (x.metadata ->> 'current_operational_reference')::numeric,
          'full_capacity', x.target_value,
          'baseline', x.baseline_value,
          'actual', x.actual_value,
          'setup_status', x.setup_status
        )
        order by x.scope_type, x.scope_name
      ),
      '[]'::jsonb
    )
    from (
      select
        'sales_location'::text as scope_type,
        lg.scope_name,
        lg.metadata,
        lg.target_value,
        lg.baseline_value,
        lg.actual_value,
        lg.setup_status
      from location_goals lg

      union all

      select
        'team'::text as scope_type,
        tg.scope_name,
        tg.metadata,
        tg.target_value,
        tg.baseline_value,
        tg.actual_value,
        tg.setup_status
      from team_goals tg
    ) x
  ) as scope_details
from result r;
