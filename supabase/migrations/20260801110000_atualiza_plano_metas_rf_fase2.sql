-- ============================================================================
-- RF Performance Comercial
-- Fase 2 — atualização do plano, metas e referências da operação real
-- Data: 2026-08-01
--
-- Objetivos:
--   * remover do plano operacional as referências provisórias 130 -> 169 / +30%;
--   * manter o baseline histórico como pendente de validação;
--   * registrar 140 como referência operacional atual (20 produtores x 7);
--   * registrar 175 como capacidade plena inicial (25 produtores x 7);
--   * atualizar as referências para 5 PDVs, 5 equipes e 5 supervisores-vendedores;
--   * criar/atualizar metas dos 5 PDVs e das 5 equipes por capacidade;
--   * preservar status, progresso, evidências, conclusões e valores realizados.
--
-- Não altera RLS, grants, funções ou estrutura das tabelas.
-- ============================================================================

begin;

do $$
declare
  v_org_id uuid;
  v_plan_id uuid;
  v_plan_count integer;
  v_location_count integer;
  v_team_count integer;
  v_location_goal_count integer;
  v_team_goal_count integer;
  v_legacy_reference_count integer;
  v_location_current_sum numeric;
  v_location_full_sum numeric;
  v_team_current_sum numeric;
  v_team_full_sum numeric;
begin
  select o.id
    into v_org_id
  from public.organizations o
  where o.slug = 'rf-consorcios'
  limit 1;

  if v_org_id is null then
    raise exception
      'Fase 2 abortada: organização rf-consorcios não encontrada.';
  end if;

  select count(*)
    into v_plan_count
  from public.commercial_plans cp
  where cp.organization_id = v_org_id
    and cp.status <> 'archived';

  if v_plan_count <> 1 then
    raise exception
      'Fase 2 abortada: esperado 1 plano não arquivado para RF, encontrado %.',
      v_plan_count;
  end if;

  select cp.id
    into v_plan_id
  from public.commercial_plans cp
  where cp.organization_id = v_org_id
    and cp.status <> 'archived'
  order by cp.created_at asc
  limit 1;

  select count(*)
    into v_location_count
  from public.sales_locations sl
  where sl.organization_id = v_org_id
    and sl.status = 'active';

  select count(*)
    into v_team_count
  from public.teams t
  where t.organization_id = v_org_id
    and t.status = 'active';

  if v_location_count <> 5 or v_team_count <> 5 then
    raise exception
      'Fase 2 abortada: esperado 5 PDVs e 5 equipes; encontrados % PDVs e % equipes.',
      v_location_count,
      v_team_count;
  end if;

  if exists (
    select 1
    from public.sales_locations sl
    where sl.organization_id = v_org_id
      and sl.status = 'active'
      and (
        coalesce(sl.metadata ->> 'adjusted_monthly_capacity_reference', '') = ''
        or coalesce(sl.metadata ->> 'full_monthly_capacity_reference', '') = ''
      )
  ) then
    raise exception
      'Fase 2 abortada: há PDV ativo sem referências de capacidade da Fase 1.';
  end if;

  if exists (
    select 1
    from public.teams t
    where t.organization_id = v_org_id
      and t.status = 'active'
      and (
        coalesce(t.metadata ->> 'adjusted_monthly_capacity_reference', '') = ''
        or coalesce(t.metadata ->> 'full_monthly_capacity_reference', '') = ''
      )
  ) then
    raise exception
      'Fase 2 abortada: há equipe ativa sem referências de capacidade da Fase 1.';
  end if;

  -- ------------------------------------------------------------------------
  -- Metadados da organização
  -- ------------------------------------------------------------------------

  update public.organizations o
  set
    metadata =
      coalesce(o.metadata, '{}'::jsonb)
      || jsonb_build_object(
        'baseline_monthly_sales', null,
        'historical_baseline_status',
          'pending_official_dashboard_validation',
        'growth_target_percent', null,
        'target_monthly_sales', 175,
        'current_operational_reference', 140,
        'full_capacity_reference', 175,
        'minimum_monthly_sales_per_producer', 7,
        'goal_distribution_status',
          'pending_supervisors_alignment_2026-08-04',
        'plan_reference_updated_at', now()
      ),
    updated_at = now()
  where o.id = v_org_id;

  -- ------------------------------------------------------------------------
  -- Plano comercial
  -- ------------------------------------------------------------------------

  update public.commercial_plans cp
  set
    description =
      'Plano de 90 dias aplicado à estrutura real de cinco PDVs, com diagnóstico, padronização, treinamento, coaching, metas, follow-up e gestão por dados.',
    baseline_monthly_sales = null,
    target_monthly_sales = 175,
    growth_target_percent = null,
    recognition_criteria =
      'Venda reconhecida somente quando registrada e validada pela administradora. Cancelamentos, desistências e inadimplência econômica até a 8ª parcela devem ser acompanhados na leitura de qualidade e persistência.',
    setup_status = 'pending_confirmation',
    is_template = false,
    metadata =
      coalesce(cp.metadata, '{}'::jsonb)
      || jsonb_build_object(
        'data_origin', 'meeting_validation',
        'historical_baseline_status',
          'pending_official_dashboard_validation',
        'current_operational_reference', 140,
        'full_capacity_reference', 175,
        'minimum_monthly_sales_per_producer', 7,
        'expected_structure',
          jsonb_build_object(
            'pdvs', 5,
            'teams', 5,
            'supervisor_sellers', 5,
            'salespersons', 15,
            'active_producers', 20,
            'vacancies', 5,
            'full_capacity_producers', 25,
            'shopping_centers', 3,
            'consortium_administrators', 2
          ),
        'maturity_curve',
          coalesce(
            (
              select o.metadata -> 'maturity_curve'
              from public.organizations o
              where o.id = v_org_id
            ),
            jsonb_build_array(
              jsonb_build_object(
                'month', 3,
                'sales_per_producer', 7,
                'full_capacity_sales', 175
              ),
              jsonb_build_object(
                'month', 6,
                'sales_per_producer', 8,
                'full_capacity_sales', 200
              ),
              jsonb_build_object(
                'month', 9,
                'sales_per_producer', 9,
                'full_capacity_sales', 225
              ),
              jsonb_build_object(
                'month', 12,
                'sales_per_producer', 10,
                'full_capacity_sales', 250
              )
            )
          ),
        'goal_distribution_status',
          'pending_supervisors_alignment_2026-08-04',
        'protection_expectation',
          'As referências de 140 e 175 cotas são objetivos de capacidade operacional. Devem ser recalibradas com o histórico oficial validado, a capacidade observada e a disciplina de execução; não constituem garantia de venda.',
        'first_milestone',
          'Ao final dos 10 primeiros dias úteis: histórico oficial validado ou pendência documentada, cinco maiores gargalos, referências preliminares e plano detalhado das semanas 3 a 12.',
        'reference_updated_at', now()
      ),
    updated_at = now()
  where cp.id = v_plan_id
    and cp.organization_id = v_org_id;

  -- ------------------------------------------------------------------------
  -- Fase de diagnóstico
  -- Preserva status, progresso e datas da fase.
  -- ------------------------------------------------------------------------

  update public.plan_phases pp
  set
    objective =
      'Validar o histórico oficial de vendas, documentar divergências e localizar os maiores vazamentos do funil nos cinco PDVs.',
    metadata =
      coalesce(pp.metadata, '{}'::jsonb)
      || jsonb_build_object(
        'historical_baseline_status',
          'pending_official_dashboard_validation',
        'deliverable',
          'Dashboard oficial validado ou pendência documentada, observação em campo, mapa de gargalos e score inicial.',
        'reference_updated_at', now()
      ),
    updated_at = now()
  where pp.plan_id = v_plan_id
    and pp.organization_id = v_org_id
    and pp.sequence_no = 1;

  -- ------------------------------------------------------------------------
  -- Ações com referências antigas
  -- Não altera status, evidência, completed_at, prioridade ou responsável.
  -- ------------------------------------------------------------------------

  update public.plan_actions pa
  set
    description =
      'Consolidar o dashboard oficial de vendas validadas, crédito, qualidade, equipe, funil, produto, incentivos e base de oportunidades.',
    metadata =
      coalesce(pa.metadata, '{}'::jsonb)
      || jsonb_build_object(
        'historical_data_scope', 'official_validated_sales',
        'reference_updated_at', now()
      ),
    updated_at = now()
  where pa.plan_id = v_plan_id
    and pa.organization_id = v_org_id
    and pa.title = 'Solicitar dados dos últimos 3 a 6 meses';

  update public.plan_actions pa
  set
    title = 'Validar o baseline histórico oficial',
    description =
      'Confrontar o dashboard de vendas validadas de fevereiro a julho com cancelamentos, pendências, sazonalidade, dias de funcionamento, férias, campanhas e persistência.',
    metadata =
      coalesce(pa.metadata, '{}'::jsonb)
      || jsonb_build_object(
        'historical_baseline_status',
          'pending_official_dashboard_validation',
        'reference_updated_at', now()
      ),
    updated_at = now()
  where pa.plan_id = v_plan_id
    and pa.organization_id = v_org_id
    and pa.title in (
      'Validar o baseline de 130 cotas',
      'Validar o baseline histórico oficial'
    );

  update public.plan_actions pa
  set
    title = 'Diagnosticar o funil dos 5 PDVs',
    description =
      'Mapear abordagens, conversas, diagnósticos, simulações, propostas, vendas validadas e follow-ups nos cinco PDVs.',
    metadata =
      coalesce(pa.metadata, '{}'::jsonb)
      || jsonb_build_object(
        'pdv_count', 5,
        'reference_updated_at', now()
      ),
    updated_at = now()
  where pa.plan_id = v_plan_id
    and pa.organization_id = v_org_id
    and pa.title in (
      'Diagnosticar o funil dos 3 PDVs',
      'Diagnosticar o funil dos 5 PDVs'
    );

  update public.plan_actions pa
  set
    title = 'Mapear competências dos 20 produtores ativos',
    description =
      'Classificar os 5 supervisores-vendedores e os 15 vendedores em produto, técnica, processo, comportamento e produtividade.',
    metadata =
      coalesce(pa.metadata, '{}'::jsonb)
      || jsonb_build_object(
        'active_producer_count', 20,
        'supervisor_seller_count', 5,
        'salesperson_count', 15,
        'reference_updated_at', now()
      ),
    updated_at = now()
  where pa.plan_id = v_plan_id
    and pa.organization_id = v_org_id
    and pa.title in (
      'Mapear competências dos 20 vendedores',
      'Mapear competências dos 20 produtores ativos'
    );

  update public.plan_actions pa
  set
    title = 'Avaliar os 5 supervisores-vendedores',
    description =
      'Aplicar score inicial de gestão de funil, coaching, feedback, forecast e atuação comercial aos cinco supervisores-vendedores.',
    metadata =
      coalesce(pa.metadata, '{}'::jsonb)
      || jsonb_build_object(
        'supervisor_seller_count', 5,
        'reference_updated_at', now()
      ),
    updated_at = now()
  where pa.plan_id = v_plan_id
    and pa.organization_id = v_org_id
    and pa.title in (
      'Avaliar os 3 supervisores',
      'Avaliar os 5 supervisores-vendedores'
    );

  update public.plan_actions pa
  set
    description =
      'Propor referências iniciais por RF, PDV, equipe e produtor a partir de 140 cotas na estrutura atual e 175 cotas em capacidade plena, sujeitas à validação.',
    metadata =
      coalesce(pa.metadata, '{}'::jsonb)
      || jsonb_build_object(
        'current_operational_reference', 140,
        'full_capacity_reference', 175,
        'reference_updated_at', now()
      ),
    updated_at = now()
  where pa.plan_id = v_plan_id
    and pa.organization_id = v_org_id
    and pa.title = 'Definir metas preliminares';

  update public.plan_actions pa
  set
    description =
      'Alinhar com os cinco supervisores-vendedores a distribuição por PDV e equipe, considerando fluxo, turnos, equipe ativa, vagas, histórico e maturidade.',
    metadata =
      coalesce(pa.metadata, '{}'::jsonb)
      || jsonb_build_object(
        'alignment_status',
          'pending_supervisors_alignment_2026-08-04',
        'reference_updated_at', now()
      ),
    updated_at = now()
  where pa.plan_id = v_plan_id
    and pa.organization_id = v_org_id
    and pa.title = 'Aprovar metas por PDV e equipe';

  -- ------------------------------------------------------------------------
  -- Metas gerais
  -- O actual_value existente é preservado em conflitos.
  -- ------------------------------------------------------------------------

  insert into public.performance_goals as pg (
    organization_id,
    plan_id,
    scope_type,
    scope_id,
    metric_code,
    label,
    baseline_value,
    target_value,
    unit,
    period_type,
    status,
    setup_status,
    is_template,
    metadata
  )
  values
    (
      v_org_id,
      v_plan_id,
      'organization',
      v_org_id,
      'validated_sales',
      'Cotas validadas por mês',
      null,
      175,
      'count',
      'monthly',
      'active',
      'pending_confirmation',
      false,
      jsonb_build_object(
        'recognition',
          'Venda registrada e validada pela administradora; acompanhar cancelamentos, desistências e inadimplência econômica até a 8ª parcela.',
        'historical_baseline_status',
          'pending_official_dashboard_validation',
        'current_operational_reference', 140,
        'full_capacity_reference', 175,
        'minimum_monthly_sales_per_producer', 7,
        'reference_type', 'operational_capacity',
        'goal_distribution_status',
          'pending_supervisors_alignment_2026-08-04'
      )
    ),
    (
      v_org_id,
      v_plan_id,
      'organization',
      v_org_id,
      'average_per_salesperson',
      'Mínimo por produtor/mês',
      null,
      7,
      'ratio',
      'monthly',
      'active',
      'pending_confirmation',
      false,
      jsonb_build_object(
        'current_operational_reference', 7,
        'scope_definition',
          'Produtor inclui supervisor-vendedor e vendedor.',
        'active_producers', 20,
        'full_capacity_producers', 25,
        'reference_type', 'minimum_operational_reference'
      )
    ),
    (
      v_org_id,
      v_plan_id,
      'organization',
      v_org_id,
      'average_per_pdv',
      'Capacidade média por PDV/mês',
      null,
      35,
      'ratio',
      'monthly',
      'active',
      'pending_confirmation',
      false,
      jsonb_build_object(
        'current_operational_reference', 28,
        'active_pdv_count', 5,
        'reference_type', 'operational_capacity'
      )
    )
  on conflict (plan_id, scope_type, scope_id, metric_code)
  do update
  set
    label = excluded.label,
    baseline_value = excluded.baseline_value,
    target_value = excluded.target_value,
    unit = excluded.unit,
    period_type = excluded.period_type,
    status = 'active',
    setup_status = excluded.setup_status,
    is_template = excluded.is_template,
    archived_at = null,
    metadata =
      coalesce(pg.metadata, '{}'::jsonb)
      || excluded.metadata,
    updated_at = now();

  -- ------------------------------------------------------------------------
  -- Metas dos 5 PDVs
  -- ------------------------------------------------------------------------

  insert into public.performance_goals as pg (
    organization_id,
    plan_id,
    scope_type,
    scope_id,
    metric_code,
    label,
    baseline_value,
    target_value,
    unit,
    period_type,
    status,
    setup_status,
    is_template,
    metadata
  )
  select
    v_org_id,
    v_plan_id,
    'sales_location',
    sl.id,
    'validated_sales',
    'Cotas validadas — ' || sl.name,
    null,
    (sl.metadata ->> 'full_monthly_capacity_reference')::numeric,
    'count',
    'monthly',
    'active',
    'pending_confirmation',
    false,
    jsonb_build_object(
      'data_origin', 'meeting_validation',
      'distribution',
        'capacity_based_pending_supervisors_alignment',
      'current_operational_reference',
        (sl.metadata ->> 'adjusted_monthly_capacity_reference')::numeric,
      'full_capacity_reference',
        (sl.metadata ->> 'full_monthly_capacity_reference')::numeric,
      'active_producers',
        coalesce(
          (sl.metadata ->> 'confirmed_active_producers')::numeric,
          0
        ),
      'full_capacity_producers',
        coalesce(
          (sl.metadata ->> 'planned_producer_capacity')::numeric,
          0
        ),
      'vacancies',
        coalesce(
          (sl.metadata ->> 'vacant_salesperson_positions')::numeric,
          0
        ),
      'minimum_monthly_sales_per_producer', 7,
      'goal_distribution_status',
        'pending_supervisors_alignment_2026-08-04'
    )
  from public.sales_locations sl
  where sl.organization_id = v_org_id
    and sl.status = 'active'
  on conflict (plan_id, scope_type, scope_id, metric_code)
  do update
  set
    label = excluded.label,
    baseline_value = excluded.baseline_value,
    target_value = excluded.target_value,
    unit = excluded.unit,
    period_type = excluded.period_type,
    status = 'active',
    setup_status = excluded.setup_status,
    is_template = excluded.is_template,
    archived_at = null,
    metadata =
      coalesce(pg.metadata, '{}'::jsonb)
      || excluded.metadata,
    updated_at = now();

  -- ------------------------------------------------------------------------
  -- Metas das 5 equipes
  -- ------------------------------------------------------------------------

  insert into public.performance_goals as pg (
    organization_id,
    plan_id,
    scope_type,
    scope_id,
    metric_code,
    label,
    baseline_value,
    target_value,
    unit,
    period_type,
    status,
    setup_status,
    is_template,
    metadata
  )
  select
    v_org_id,
    v_plan_id,
    'team',
    t.id,
    'validated_sales',
    'Cotas validadas — ' || t.name,
    null,
    (t.metadata ->> 'full_monthly_capacity_reference')::numeric,
    'count',
    'monthly',
    'active',
    'pending_confirmation',
    false,
    jsonb_build_object(
      'data_origin', 'meeting_validation',
      'distribution',
        'capacity_based_pending_supervisors_alignment',
      'current_operational_reference',
        (t.metadata ->> 'adjusted_monthly_capacity_reference')::numeric,
      'full_capacity_reference',
        (t.metadata ->> 'full_monthly_capacity_reference')::numeric,
      'active_producers',
        coalesce(
          (t.metadata ->> 'confirmed_active_producers')::numeric,
          0
        ),
      'full_capacity_producers',
        coalesce(
          (t.metadata ->> 'planned_producer_capacity')::numeric,
          0
        ),
      'vacancies',
        coalesce(
          (t.metadata ->> 'vacant_salesperson_positions')::numeric,
          0
        ),
      'minimum_monthly_sales_per_producer', 7,
      'goal_distribution_status',
        'pending_supervisors_alignment_2026-08-04'
    )
  from public.teams t
  where t.organization_id = v_org_id
    and t.status = 'active'
  on conflict (plan_id, scope_type, scope_id, metric_code)
  do update
  set
    label = excluded.label,
    baseline_value = excluded.baseline_value,
    target_value = excluded.target_value,
    unit = excluded.unit,
    period_type = excluded.period_type,
    status = 'active',
    setup_status = excluded.setup_status,
    is_template = excluded.is_template,
    archived_at = null,
    metadata =
      coalesce(pg.metadata, '{}'::jsonb)
      || excluded.metadata,
    updated_at = now();

  -- ------------------------------------------------------------------------
  -- Validações transacionais
  -- ------------------------------------------------------------------------

  select count(*)
    into v_location_goal_count
  from public.performance_goals pg
  where pg.plan_id = v_plan_id
    and pg.organization_id = v_org_id
    and pg.scope_type = 'sales_location'
    and pg.metric_code = 'validated_sales'
    and pg.status <> 'archived';

  select count(*)
    into v_team_goal_count
  from public.performance_goals pg
  where pg.plan_id = v_plan_id
    and pg.organization_id = v_org_id
    and pg.scope_type = 'team'
    and pg.metric_code = 'validated_sales'
    and pg.status <> 'archived';

  if v_location_goal_count <> 5 or v_team_goal_count <> 5 then
    raise exception
      'Fase 2 abortada: esperado 5 metas de PDV e 5 metas de equipe; encontradas % e %.',
      v_location_goal_count,
      v_team_goal_count;
  end if;

  select
    coalesce(
      sum(
        (pg.metadata ->> 'current_operational_reference')::numeric
      ),
      0
    ),
    coalesce(sum(pg.target_value), 0)
  into
    v_location_current_sum,
    v_location_full_sum
  from public.performance_goals pg
  where pg.plan_id = v_plan_id
    and pg.organization_id = v_org_id
    and pg.scope_type = 'sales_location'
    and pg.metric_code = 'validated_sales'
    and pg.status <> 'archived';

  select
    coalesce(
      sum(
        (pg.metadata ->> 'current_operational_reference')::numeric
      ),
      0
    ),
    coalesce(sum(pg.target_value), 0)
  into
    v_team_current_sum,
    v_team_full_sum
  from public.performance_goals pg
  where pg.plan_id = v_plan_id
    and pg.organization_id = v_org_id
    and pg.scope_type = 'team'
    and pg.metric_code = 'validated_sales'
    and pg.status <> 'archived';

  if
    v_location_current_sum <> 140
    or v_location_full_sum <> 175
    or v_team_current_sum <> 140
    or v_team_full_sum <> 175
  then
    raise exception
      'Fase 2 abortada: somas inválidas. PDVs atual/plena=%/%, equipes atual/plena=%/%.',
      v_location_current_sum,
      v_location_full_sum,
      v_team_current_sum,
      v_team_full_sum;
  end if;

  if not exists (
    select 1
    from public.commercial_plans cp
    where cp.id = v_plan_id
      and cp.organization_id = v_org_id
      and cp.baseline_monthly_sales is null
      and cp.target_monthly_sales = 175
      and cp.growth_target_percent is null
      and cp.setup_status = 'pending_confirmation'
      and cp.is_template = false
  ) then
    raise exception
      'Fase 2 abortada: plano comercial não ficou com baseline pendente e capacidade plena 175.';
  end if;

  select
    (
      select count(*)
      from public.commercial_plans cp
      where cp.id = v_plan_id
        and concat_ws(
          ' ',
          cp.description,
          cp.recognition_criteria,
          cp.metadata::text
        ) ~* '(130|169|30%|3[[:space:]]+PDVs|3[[:space:]]+supervisores|20[[:space:]]+vendedores|PDV Modelo|Equipe Modelo|provisional_equal_split)'
    )
    +
    (
      select count(*)
      from public.plan_phases pp
      where pp.plan_id = v_plan_id
        and pp.status <> 'archived'
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
      where pa.plan_id = v_plan_id
        and pa.status <> 'archived'
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
      where pg.plan_id = v_plan_id
        and pg.status <> 'archived'
        and concat_ws(
          ' ',
          pg.label,
          pg.baseline_value::text,
          pg.target_value::text,
          pg.metadata::text
        ) ~* '(130|169|30%|43[.]3|56[.]3|PDV Modelo|Equipe Modelo|provisional_equal_split)'
    )
  into v_legacy_reference_count;

  if v_legacy_reference_count <> 0 then
    raise exception
      'Fase 2 abortada: ainda existem % registros com referências antigas.',
      v_legacy_reference_count;
  end if;
end;
$$;

commit;
