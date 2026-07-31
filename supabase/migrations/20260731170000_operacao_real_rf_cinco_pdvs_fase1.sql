-- ============================================================================
-- RF Performance Comercial
-- Operação real da RF — Fase 1
--
-- Converte os três registros-modelo existentes em PDVs reais, cria os dois
-- PDVs adicionais e consolida a estrutura confirmada em reunião:
--
--   5 PDVs
--   5 equipes
--   5 supervisores-vendedores
--   15 vendedores ativos
--   20 produtores ativos
--   5 vagas
--   25 produtores em capacidade plena
--
-- Preserva:
--   - os IDs dos três PDVs e das três equipes existentes;
--   - vínculos de usuários já existentes;
--   - o usuário de teste atualmente vinculado à Equipe Modelo 1;
--   - histórico, RLS, policies e demais tabelas.
--
-- Não cria contas, convites ou vínculos fictícios para os supervisores reais.
-- ============================================================================

begin;

do $$
declare
  v_org_id uuid;
  v_operation_id uuid;

  v_vw_caxias_location_id constant uuid :=
    '2971c7eb-93dd-45ea-99c4-165770570b25';
  v_vw_grande_rio_location_id constant uuid :=
    '192d8616-5dfe-4f0c-8444-328be19a0613';
  v_vw_sao_goncalo_location_id constant uuid :=
    '3f903b49-3268-4d12-a3d4-76bcb4bbc01f';
  v_fiat_caxias_location_id constant uuid :=
    '1479dad6-60b4-4a4a-a59f-4e2871cd9562';
  v_fiat_grande_rio_location_id constant uuid :=
    '5d74b5ed-8a49-44b0-b71e-d7015ffe5789';

  v_vw_caxias_team_id constant uuid :=
    '8e2e83c0-17fc-4e1a-a529-cd4bc5c1a101';
  v_vw_grande_rio_team_id constant uuid :=
    '8e2e83c0-17fc-4e1a-a529-cd4bc5c1a102';
  v_vw_sao_goncalo_team_id constant uuid :=
    '8e2e83c0-17fc-4e1a-a529-cd4bc5c1a103';
  v_fiat_caxias_team_id constant uuid :=
    'fa330ac6-fad4-415a-8baa-16a721c199a1';
  v_fiat_grande_rio_team_id constant uuid :=
    '9a6303a3-0e2b-4b77-a5ae-7ca4db15fdfe';

  v_existing_template_locations integer;
  v_existing_template_teams integer;
begin
  select o.id
  into v_org_id
  from public.organizations o
  where o.slug = 'rf-consorcios'
    and o.archived_at is null;

  if v_org_id is null then
    raise exception
      'Organização rf-consorcios não encontrada ou arquivada.';
  end if;

  select op.id
  into v_operation_id
  from public.operations op
  where op.organization_id = v_org_id
    and op.slug = 'consorcio-automoveis'
    and op.archived_at is null;

  if v_operation_id is null then
    raise exception
      'Operação consorcio-automoveis não encontrada ou arquivada.';
  end if;

  select count(*)::integer
  into v_existing_template_locations
  from public.sales_locations sl
  where sl.organization_id = v_org_id
    and sl.operation_id = v_operation_id
    and sl.id in (
      v_vw_caxias_location_id,
      v_vw_grande_rio_location_id,
      v_vw_sao_goncalo_location_id
    );

  if v_existing_template_locations <> 3 then
    raise exception
      'Guarda de segurança: esperados 3 PDVs-base; encontrados %.',
      v_existing_template_locations;
  end if;

  select count(*)::integer
  into v_existing_template_teams
  from public.teams t
  where t.organization_id = v_org_id
    and t.operation_id = v_operation_id
    and t.id in (
      v_vw_caxias_team_id,
      v_vw_grande_rio_team_id,
      v_vw_sao_goncalo_team_id
    );

  if v_existing_template_teams <> 3 then
    raise exception
      'Guarda de segurança: esperadas 3 equipes-base; encontradas %.',
      v_existing_template_teams;
  end if;

  if exists (
    select 1
    from public.sales_locations sl
    where sl.organization_id = v_org_id
      and sl.slug in (
        'volkswagen-caxias',
        'volkswagen-grande-rio',
        'volkswagen-sao-goncalo',
        'fiat-caxias',
        'fiat-grande-rio'
      )
      and sl.id not in (
        v_vw_caxias_location_id,
        v_vw_grande_rio_location_id,
        v_vw_sao_goncalo_location_id,
        v_fiat_caxias_location_id,
        v_fiat_grande_rio_location_id
      )
  ) then
    raise exception
      'Guarda de segurança: já existe PDV com um dos slugs reais e ID inesperado.';
  end if;

  -- --------------------------------------------------------------------------
  -- Organização e operação
  -- --------------------------------------------------------------------------

  update public.organizations
  set
    metadata =
      metadata
      || jsonb_build_object(
        'setup_template', 'commercial_acceleration_real_v1',
        'setup_status', 'operational_structure_confirmed',
        'structure_source', 'meeting_raphael_backoffice',
        'structure_confirmed_at', now(),
        'next_supervisors_alignment_date', '2026-08-04',
        'shopping_center_count', 3,
        'consortium_administrator_count', 2,
        'consortium_administrators',
          jsonb_build_array('FIAT', 'Volkswagen'),
        'planned_location_capacity', 5,
        'planned_supervisor_capacity', 5,
        'planned_salesperson_capacity', 20,
        'planned_producer_capacity', 25,
        'confirmed_active_supervisors', 5,
        'confirmed_active_salespersons', 15,
        'confirmed_active_producers', 20,
        'vacant_salesperson_positions', 5,
        'minimum_monthly_sales_per_producer', 7,
        'adjusted_monthly_capacity_reference', 140,
        'full_monthly_capacity_reference', 175,
        'maturity_curve',
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
    updated_at = now()
  where id = v_org_id;

  update public.operations
  set
    metadata =
      metadata
      || jsonb_build_object(
        'setup_template', 'commercial_acceleration_real_v1',
        'setup_status', 'operational_structure_confirmed',
        'structure_source', 'meeting_raphael_backoffice',
        'structure_confirmed_at', now(),
        'next_supervisors_alignment_date', '2026-08-04',
        'shopping_center_count', 3,
        'consortium_administrators',
          jsonb_build_array('FIAT', 'Volkswagen'),
        'planned_location_capacity', 5,
        'planned_team_capacity', 5,
        'planned_supervisor_capacity', 5,
        'planned_salesperson_capacity', 20,
        'planned_producer_capacity', 25,
        'confirmed_active_producers', 20,
        'vacant_salesperson_positions', 5
      ),
    updated_at = now()
  where id = v_operation_id
    and organization_id = v_org_id;

  -- --------------------------------------------------------------------------
  -- PDVs reais
  --
  -- Mapeamento conservador dos três IDs existentes:
  --   Modelo 1 -> Volkswagen Caxias
  --   Modelo 2 -> Volkswagen Grande Rio
  --   Modelo 3 -> Volkswagen São Gonçalo
  --
  -- O vínculo do usuário de teste da Equipe Modelo 1 permanece no mesmo ID,
  -- agora identificado como Equipe Volkswagen Caxias.
  -- --------------------------------------------------------------------------

  with pdv_data as (
    select *
    from (
      values
        (
          v_vw_caxias_location_id,
          'Volkswagen Caxias'::text,
          'volkswagen-caxias'::text,
          'Caxias Shopping'::text,
          'Duque de Caxias'::text,
          'RJ'::text,
          'rf-pdv-volkswagen-caxias'::text,
          3,
          'volkswagen'::text,
          'Volkswagen'::text,
          'caxias'::text,
          'Josué'::text,
          array['Ana Paula', 'Beatriz', 'Romullo']::text[],
          3,
          1,
          4,
          1
        ),
        (
          v_vw_grande_rio_location_id,
          'Volkswagen Grande Rio'::text,
          'volkswagen-grande-rio'::text,
          'Shopping Grande Rio'::text,
          'São João de Meriti'::text,
          'RJ'::text,
          'rf-pdv-volkswagen-grande-rio'::text,
          2,
          'volkswagen'::text,
          'Volkswagen'::text,
          'grande-rio'::text,
          'Jacqueline'::text,
          array['Cristine', 'Wellington Medeiros']::text[],
          2,
          1,
          3,
          2
        ),
        (
          v_vw_sao_goncalo_location_id,
          'Volkswagen São Gonçalo'::text,
          'volkswagen-sao-goncalo'::text,
          null::text,
          'São Gonçalo'::text,
          'RJ'::text,
          'rf-pdv-volkswagen-sao-goncalo'::text,
          1,
          'volkswagen'::text,
          'Volkswagen'::text,
          'sao-goncalo'::text,
          'Aurélio'::text,
          array['Wagner', 'David', 'Jeferson', 'Leandro Oliveira']::text[],
          4,
          1,
          5,
          0
        ),
        (
          v_fiat_caxias_location_id,
          'FIAT Caxias'::text,
          'fiat-caxias'::text,
          'Caxias Shopping'::text,
          'Duque de Caxias'::text,
          'RJ'::text,
          'rf-pdv-fiat-caxias'::text,
          4,
          'fiat'::text,
          'FIAT'::text,
          'caxias'::text,
          'Carlos'::text,
          array['Kelvin', 'Romulo Evaristo', 'Adriana']::text[],
          3,
          1,
          4,
          1
        ),
        (
          v_fiat_grande_rio_location_id,
          'FIAT Grande Rio'::text,
          'fiat-grande-rio'::text,
          'Shopping Grande Rio'::text,
          'São João de Meriti'::text,
          'RJ'::text,
          'rf-pdv-fiat-grande-rio'::text,
          5,
          'fiat'::text,
          'FIAT'::text,
          'grande-rio'::text,
          'Edmilson'::text,
          array['Fernanda', 'Pietro', 'Leandro Bispo']::text[],
          3,
          1,
          4,
          1
        )
    ) as v(
      id,
      name,
      slug,
      shopping_name,
      city,
      state_code,
      external_id,
      presentation_order,
      administrator_code,
      administrator_name,
      shopping_group_code,
      confirmed_supervisor_name,
      confirmed_salesperson_names,
      confirmed_active_salespersons,
      confirmed_active_supervisors,
      confirmed_active_producers,
      vacant_salesperson_positions
    )
  )
  insert into public.sales_locations (
    id,
    organization_id,
    operation_id,
    name,
    slug,
    location_type,
    shopping_name,
    city,
    state_code,
    status,
    external_id,
    source_system,
    metadata
  )
  select
    d.id,
    v_org_id,
    v_operation_id,
    d.name,
    d.slug,
    'shopping_kiosk',
    d.shopping_name,
    d.city,
    d.state_code,
    'active',
    d.external_id,
    'rf_performance',
    jsonb_build_object(
      'template_record', false,
      'template_key', 'commercial_acceleration_real_v1',
      'setup_status', 'confirmed',
      'data_origin', 'meeting_validation',
      'structure_source', 'meeting_raphael_backoffice',
      'confirmed_at', now(),
      'confirmed_by', null,
      'provisional_name', false,
      'presentation_order', d.presentation_order,
      'administrator_code', d.administrator_code,
      'administrator_name', d.administrator_name,
      'shopping_group_code', d.shopping_group_code,
      'shopping_name_confirmation_pending',
        (d.shopping_name is null),
      'confirmed_supervisor_name', d.confirmed_supervisor_name,
      'confirmed_supervisor_account_pending', true,
      'confirmed_salesperson_names',
        to_jsonb(d.confirmed_salesperson_names),
      'confirmed_active_salespersons',
        d.confirmed_active_salespersons,
      'confirmed_active_supervisors',
        d.confirmed_active_supervisors,
      'confirmed_active_producers',
        d.confirmed_active_producers,
      'planned_salesperson_capacity', 4,
      'planned_supervisor_positions', 1,
      'planned_producer_capacity', 5,
      'vacant_salesperson_positions',
        d.vacant_salesperson_positions,
      'vacancy_fill_target_date',
        case
          when d.vacant_salesperson_positions > 0
            then '2026-08-31'
          else null
        end,
      'minimum_monthly_sales_per_producer', 7,
      'adjusted_monthly_capacity_reference',
        d.confirmed_active_producers * 7,
      'full_monthly_capacity_reference', 35,
      'goal_distribution_status',
        'pending_supervisors_alignment_2026-08-04'
    )
  from pdv_data d
  on conflict (id) do update
  set
    organization_id = excluded.organization_id,
    operation_id = excluded.operation_id,
    name = excluded.name,
    slug = excluded.slug,
    location_type = excluded.location_type,
    shopping_name = excluded.shopping_name,
    city = excluded.city,
    state_code = excluded.state_code,
    status = 'active',
    external_id = excluded.external_id,
    source_system = excluded.source_system,
    archived_at = null,
    metadata =
      (
        public.sales_locations.metadata
        - 'template_record'
        - 'provisional_name'
      )
      || excluded.metadata,
    updated_at = now();

  -- --------------------------------------------------------------------------
  -- Equipes reais
  -- --------------------------------------------------------------------------

  with team_data as (
    select *
    from (
      values
        (
          v_vw_caxias_team_id,
          v_vw_caxias_location_id,
          'Equipe Volkswagen Caxias'::text,
          'Equipe do PDV Volkswagen Caxias, liderada pelo supervisor-vendedor Josué.'::text,
          'rf-team-volkswagen-caxias'::text,
          3,
          'volkswagen'::text,
          'Volkswagen'::text,
          'Josué'::text,
          array['Ana Paula', 'Beatriz', 'Romullo']::text[],
          3,
          1,
          4,
          1
        ),
        (
          v_vw_grande_rio_team_id,
          v_vw_grande_rio_location_id,
          'Equipe Volkswagen Grande Rio'::text,
          'Equipe do PDV Volkswagen Grande Rio, liderada pela supervisora-vendedora Jacqueline.'::text,
          'rf-team-volkswagen-grande-rio'::text,
          2,
          'volkswagen'::text,
          'Volkswagen'::text,
          'Jacqueline'::text,
          array['Cristine', 'Wellington Medeiros']::text[],
          2,
          1,
          3,
          2
        ),
        (
          v_vw_sao_goncalo_team_id,
          v_vw_sao_goncalo_location_id,
          'Equipe Volkswagen São Gonçalo'::text,
          'Equipe do PDV Volkswagen São Gonçalo, liderada pelo supervisor-vendedor Aurélio.'::text,
          'rf-team-volkswagen-sao-goncalo'::text,
          1,
          'volkswagen'::text,
          'Volkswagen'::text,
          'Aurélio'::text,
          array['Wagner', 'David', 'Jeferson', 'Leandro Oliveira']::text[],
          4,
          1,
          5,
          0
        ),
        (
          v_fiat_caxias_team_id,
          v_fiat_caxias_location_id,
          'Equipe FIAT Caxias'::text,
          'Equipe do PDV FIAT Caxias, liderada pelo supervisor-vendedor Carlos.'::text,
          'rf-team-fiat-caxias'::text,
          4,
          'fiat'::text,
          'FIAT'::text,
          'Carlos'::text,
          array['Kelvin', 'Romulo Evaristo', 'Adriana']::text[],
          3,
          1,
          4,
          1
        ),
        (
          v_fiat_grande_rio_team_id,
          v_fiat_grande_rio_location_id,
          'Equipe FIAT Grande Rio'::text,
          'Equipe do PDV FIAT Grande Rio, liderada pelo supervisor-vendedor Edmilson.'::text,
          'rf-team-fiat-grande-rio'::text,
          5,
          'fiat'::text,
          'FIAT'::text,
          'Edmilson'::text,
          array['Fernanda', 'Pietro', 'Leandro Bispo']::text[],
          3,
          1,
          4,
          1
        )
    ) as v(
      id,
      sales_location_id,
      name,
      description,
      external_id,
      presentation_order,
      administrator_code,
      administrator_name,
      confirmed_supervisor_name,
      confirmed_salesperson_names,
      confirmed_active_salespersons,
      confirmed_active_supervisors,
      confirmed_active_producers,
      vacant_salesperson_positions
    )
  )
  insert into public.teams (
    id,
    organization_id,
    operation_id,
    sales_location_id,
    name,
    description,
    supervisor_member_id,
    status,
    external_id,
    source_system,
    metadata
  )
  select
    d.id,
    v_org_id,
    v_operation_id,
    d.sales_location_id,
    d.name,
    d.description,
    null,
    'active',
    d.external_id,
    'rf_performance',
    jsonb_build_object(
      'template_record', false,
      'template_key', 'commercial_acceleration_real_v1',
      'setup_status', 'confirmed',
      'data_origin', 'meeting_validation',
      'structure_source', 'meeting_raphael_backoffice',
      'confirmed_at', now(),
      'confirmed_by', null,
      'provisional_name', false,
      'presentation_order', d.presentation_order,
      'administrator_code', d.administrator_code,
      'administrator_name', d.administrator_name,
      'confirmed_supervisor_name', d.confirmed_supervisor_name,
      'confirmed_supervisor_account_pending', true,
      'confirmed_salesperson_names',
        to_jsonb(d.confirmed_salesperson_names),
      'confirmed_active_salespersons',
        d.confirmed_active_salespersons,
      'confirmed_active_supervisors',
        d.confirmed_active_supervisors,
      'confirmed_active_producers',
        d.confirmed_active_producers,
      'planned_salesperson_capacity', 4,
      'planned_supervisor_positions', 1,
      'planned_producer_capacity', 5,
      'vacant_salesperson_positions',
        d.vacant_salesperson_positions,
      'vacancy_fill_target_date',
        case
          when d.vacant_salesperson_positions > 0
            then '2026-08-31'
          else null
        end,
      'minimum_monthly_sales_per_producer', 7,
      'adjusted_monthly_capacity_reference',
        d.confirmed_active_producers * 7,
      'full_monthly_capacity_reference', 35,
      'goal_distribution_status',
        'pending_supervisors_alignment_2026-08-04'
    )
  from team_data d
  on conflict (id) do update
  set
    organization_id = excluded.organization_id,
    operation_id = excluded.operation_id,
    sales_location_id = excluded.sales_location_id,
    name = excluded.name,
    description = excluded.description,
    status = 'active',
    external_id = excluded.external_id,
    source_system = excluded.source_system,
    archived_at = null,
    metadata =
      (
        public.teams.metadata
        - 'template_record'
        - 'provisional_name'
      )
      || excluded.metadata,
    updated_at = now();

  -- Não substitui um supervisor_member_id real já vinculado.
  -- Os cinco nomes confirmados permanecem em metadata até os convites oficiais.
  update public.teams
  set supervisor_member_id = supervisor_member_id
  where organization_id = v_org_id
    and operation_id = v_operation_id
    and id in (
      v_vw_caxias_team_id,
      v_vw_grande_rio_team_id,
      v_vw_sao_goncalo_team_id,
      v_fiat_caxias_team_id,
      v_fiat_grande_rio_team_id
    );

  insert into public.audit_logs (
    organization_id,
    user_id,
    action,
    entity_type,
    entity_id,
    old_values,
    new_values
  ) values (
    v_org_id,
    null,
    'confirm_real_operational_structure',
    'organization',
    v_org_id,
    jsonb_build_object(
      'previous_location_capacity', 3,
      'previous_supervisor_capacity', 3,
      'previous_salesperson_capacity', 20
    ),
    jsonb_build_object(
      'sales_locations', 5,
      'teams', 5,
      'confirmed_supervisors', 5,
      'confirmed_salespersons', 15,
      'confirmed_active_producers', 20,
      'vacant_salesperson_positions', 5,
      'planned_producer_capacity', 25,
      'source', 'meeting_raphael_backoffice'
    )
  );
end
$$;

commit;
