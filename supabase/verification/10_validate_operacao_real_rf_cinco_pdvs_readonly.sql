-- ============================================================================
-- RF Performance Comercial
-- Validação somente leitura — operação real da RF com 5 PDVs
-- ============================================================================

begin;
set transaction read only;

with
target as (
  select
    o.id as organization_id,
    op.id as operation_id
  from public.organizations o
  join public.operations op
    on op.organization_id = o.id
  where o.slug = 'rf-consorcios'
    and op.slug = 'consorcio-automoveis'
),
expected as (
  select *
  from (
    values
      (
        '2971c7eb-93dd-45ea-99c4-165770570b25'::uuid,
        'Volkswagen Caxias'::text,
        'volkswagen-caxias'::text,
        '8e2e83c0-17fc-4e1a-a529-cd4bc5c1a101'::uuid,
        'Equipe Volkswagen Caxias'::text,
        'Josué'::text,
        3,
        4,
        1
      ),
      (
        '192d8616-5dfe-4f0c-8444-328be19a0613'::uuid,
        'Volkswagen Grande Rio'::text,
        'volkswagen-grande-rio'::text,
        '8e2e83c0-17fc-4e1a-a529-cd4bc5c1a102'::uuid,
        'Equipe Volkswagen Grande Rio'::text,
        'Jacqueline'::text,
        2,
        3,
        2
      ),
      (
        '3f903b49-3268-4d12-a3d4-76bcb4bbc01f'::uuid,
        'Volkswagen São Gonçalo'::text,
        'volkswagen-sao-goncalo'::text,
        '8e2e83c0-17fc-4e1a-a529-cd4bc5c1a103'::uuid,
        'Equipe Volkswagen São Gonçalo'::text,
        'Aurélio'::text,
        4,
        5,
        0
      ),
      (
        '1479dad6-60b4-4a4a-a59f-4e2871cd9562'::uuid,
        'FIAT Caxias'::text,
        'fiat-caxias'::text,
        'fa330ac6-fad4-415a-8baa-16a721c199a1'::uuid,
        'Equipe FIAT Caxias'::text,
        'Carlos'::text,
        3,
        4,
        1
      ),
      (
        '5d74b5ed-8a49-44b0-b71e-d7015ffe5789'::uuid,
        'FIAT Grande Rio'::text,
        'fiat-grande-rio'::text,
        '9a6303a3-0e2b-4b77-a5ae-7ca4db15fdfe'::uuid,
        'Equipe FIAT Grande Rio'::text,
        'Edmilson'::text,
        3,
        4,
        1
      )
  ) as v(
    location_id,
    location_name,
    location_slug,
    team_id,
    team_name,
    supervisor_name,
    active_salespersons,
    active_producers,
    vacancies
  )
),
actual as (
  select
    e.*,
    sl.id as actual_location_id,
    sl.name as actual_location_name,
    sl.slug as actual_location_slug,
    sl.status as actual_location_status,
    sl.metadata as location_metadata,
    t.id as actual_team_id,
    t.name as actual_team_name,
    t.status as actual_team_status,
    t.metadata as team_metadata
  from expected e
  left join target x on true
  left join public.sales_locations sl
    on sl.id = e.location_id
   and sl.organization_id = x.organization_id
   and sl.operation_id = x.operation_id
  left join public.teams t
    on t.id = e.team_id
   and t.organization_id = x.organization_id
   and t.operation_id = x.operation_id
   and t.sales_location_id = sl.id
),
checks as (
  select
    (select count(*) from actual
      where actual_location_id is not null) = 5
      as five_locations_found,

    (select count(*) from actual
      where actual_team_id is not null) = 5
      as five_teams_found,

    (select count(*) from actual
      where actual_location_name = location_name
        and actual_location_slug = location_slug
        and actual_location_status = 'active') = 5
      as location_identity_valid,

    (select count(*) from actual
      where actual_team_name = team_name
        and actual_team_status = 'active') = 5
      as team_identity_valid,

    (select count(*) from actual
      where location_metadata ->> 'confirmed_supervisor_name'
              = supervisor_name
        and (location_metadata ->> 'planned_salesperson_capacity')::integer = 4
        and (location_metadata ->> 'planned_supervisor_positions')::integer = 1
        and (location_metadata ->> 'planned_producer_capacity')::integer = 5
        and (location_metadata ->> 'confirmed_active_salespersons')::integer
              = active_salespersons
        and (location_metadata ->> 'confirmed_active_producers')::integer
              = active_producers
        and (location_metadata ->> 'vacant_salesperson_positions')::integer
              = vacancies) = 5
      as location_capacity_valid,

    (select count(*) from actual
      where team_metadata ->> 'confirmed_supervisor_name'
              = supervisor_name
        and (team_metadata ->> 'planned_salesperson_capacity')::integer = 4
        and (team_metadata ->> 'planned_supervisor_positions')::integer = 1
        and (team_metadata ->> 'planned_producer_capacity')::integer = 5
        and (team_metadata ->> 'confirmed_active_salespersons')::integer
              = active_salespersons
        and (team_metadata ->> 'confirmed_active_producers')::integer
              = active_producers
        and (team_metadata ->> 'vacant_salesperson_positions')::integer
              = vacancies) = 5
      as team_capacity_valid,

    (
      select sum(
        (location_metadata ->> 'confirmed_active_salespersons')::integer
      )
      from actual
    ) = 15
      as fifteen_salespersons_confirmed,

    (
      select sum(
        (location_metadata ->> 'confirmed_active_producers')::integer
      )
      from actual
    ) = 20
      as twenty_producers_confirmed,

    (
      select sum(
        (location_metadata ->> 'vacant_salesperson_positions')::integer
      )
      from actual
    ) = 5
      as five_vacancies_confirmed,

    exists (
      select 1
      from target x
      join public.teams t
        on t.id = '8e2e83c0-17fc-4e1a-a529-cd4bc5c1a101'::uuid
       and t.organization_id = x.organization_id
      join public.team_members tm
        on tm.team_id = t.id
       and tm.organization_id = t.organization_id
       and tm.status = 'active'
       and tm.archived_at is null
      join public.organization_members om
        on om.id = tm.organization_member_id
       and om.organization_id = tm.organization_id
      join public.profiles p
        on p.id = om.user_id
      where p.email = 'empilhaplus@gmail.com'
        and t.name = 'Equipe Volkswagen Caxias'
    ) as test_user_membership_preserved,

    not exists (
      select 1
      from target x
      join public.sales_locations sl
        on sl.organization_id = x.organization_id
       and sl.operation_id = x.operation_id
      where sl.name like 'PDV Modelo%'
        and sl.archived_at is null
    ) as no_location_model_names,

    not exists (
      select 1
      from target x
      join public.teams t
        on t.organization_id = x.organization_id
       and t.operation_id = x.operation_id
      where t.name like 'Equipe Modelo%'
        and t.archived_at is null
    ) as no_team_model_names
)
select
  case
    when
      five_locations_found
      and five_teams_found
      and location_identity_valid
      and team_identity_valid
      and location_capacity_valid
      and team_capacity_valid
      and fifteen_salespersons_confirmed
      and twenty_producers_confirmed
      and five_vacancies_confirmed
      and test_user_membership_preserved
      and no_location_model_names
      and no_team_model_names
    then 'PASS'
    else 'FAIL'
  end as validation_result,
  five_locations_found,
  five_teams_found,
  location_identity_valid,
  team_identity_valid,
  location_capacity_valid,
  team_capacity_valid,
  fifteen_salespersons_confirmed,
  twenty_producers_confirmed,
  five_vacancies_confirmed,
  test_user_membership_preserved,
  no_location_model_names,
  no_team_model_names,
  (
    select jsonb_agg(
      jsonb_build_object(
        'location_id', location_id,
        'location_name', actual_location_name,
        'location_slug', actual_location_slug,
        'team_id', team_id,
        'team_name', actual_team_name,
        'supervisor_name',
          location_metadata ->> 'confirmed_supervisor_name',
        'active_salespersons',
          (location_metadata ->> 'confirmed_active_salespersons')::integer,
        'active_producers',
          (location_metadata ->> 'confirmed_active_producers')::integer,
        'vacancies',
          (location_metadata ->> 'vacant_salesperson_positions')::integer
      )
      order by
        (location_metadata ->> 'presentation_order')::integer
    )
    from actual
  ) as structure_details
from checks;

rollback;
