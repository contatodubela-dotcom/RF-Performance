-- ============================================================================
-- RF Performance Comercial
-- Template operacional demonstrável e editável
--
-- Prepara os três PDVs e as três equipes da RF como registros de modelo.
-- Não cria supervisores ou vendedores fictícios.
-- ============================================================================

begin;

update public.organizations
set metadata = metadata || jsonb_build_object(
      'setup_template', 'commercial_acceleration_v1',
      'setup_status', 'presentation_template',
      'baseline_monthly_sales', 130,
      'growth_target_percent', 30,
      'target_monthly_sales', 169,
      'planned_location_capacity', 3,
      'planned_supervisor_capacity', 3,
      'planned_salesperson_capacity', 20,
      'plan_duration_days', 90,
      'template_updated_at', now()
    ),
    updated_at = now()
where slug = 'rf-consorcios';

update public.operations
set metadata = metadata || jsonb_build_object(
      'setup_template', 'commercial_acceleration_v1',
      'setup_status', 'presentation_template',
      'plan_duration_days', 90,
      'template_updated_at', now()
    ),
    updated_at = now()
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'
  and slug = 'consorcio-automoveis';

update public.sales_locations
set name = case id
      when '2971c7eb-93dd-45ea-99c4-165770570b25'::uuid
        then 'PDV Modelo 1'
      when '192d8616-5dfe-4f0c-8444-328be19a0613'::uuid
        then 'PDV Modelo 2'
      when '3f903b49-3268-4d12-a3d4-76bcb4bbc01f'::uuid
        then 'PDV Modelo 3'
      else name
    end,
    metadata = metadata || jsonb_build_object(
      'template_record', true,
      'template_key', 'commercial_acceleration_v1',
      'setup_status', 'pending_confirmation',
      'data_origin', 'template',
      'confirmed_at', null,
      'confirmed_by', null,
      'presentation_order', case id
        when '2971c7eb-93dd-45ea-99c4-165770570b25'::uuid then 1
        when '192d8616-5dfe-4f0c-8444-328be19a0613'::uuid then 2
        when '3f903b49-3268-4d12-a3d4-76bcb4bbc01f'::uuid then 3
      end,
      'planned_supervisor_positions', 1,
      'planned_salesperson_capacity', case id
        when '2971c7eb-93dd-45ea-99c4-165770570b25'::uuid then 7
        when '192d8616-5dfe-4f0c-8444-328be19a0613'::uuid then 7
        when '3f903b49-3268-4d12-a3d4-76bcb4bbc01f'::uuid then 6
      end,
      'provisional_name', true,
      'template_updated_at', now()
    ),
    updated_at = now()
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'
  and id in (
    '2971c7eb-93dd-45ea-99c4-165770570b25',
    '192d8616-5dfe-4f0c-8444-328be19a0613',
    '3f903b49-3268-4d12-a3d4-76bcb4bbc01f'
  );

insert into public.teams (
  id,
  organization_id,
  operation_id,
  sales_location_id,
  name,
  description,
  status,
  external_id,
  source_system,
  metadata
) values
  (
    '8e2e83c0-17fc-4e1a-a529-cd4bc5c1a101',
    '414a2e84-bc62-4c64-99ee-76db1cbc4654',
    'c3982529-3988-47f5-a216-8e4b04187a10',
    '2971c7eb-93dd-45ea-99c4-165770570b25',
    'Equipe Modelo 1',
    'Estrutura demonstrativa editável vinculada ao PDV Modelo 1.',
    'active',
    'team-model-1',
    'rf_performance',
    jsonb_build_object(
      'template_record', true,
      'template_key', 'commercial_acceleration_v1',
      'setup_status', 'pending_confirmation',
      'data_origin', 'template',
      'confirmed_at', null,
      'confirmed_by', null,
      'presentation_order', 1,
      'planned_supervisor_positions', 1,
      'planned_salesperson_capacity', 7,
      'provisional_name', true
    )
  ),
  (
    '8e2e83c0-17fc-4e1a-a529-cd4bc5c1a102',
    '414a2e84-bc62-4c64-99ee-76db1cbc4654',
    'c3982529-3988-47f5-a216-8e4b04187a10',
    '192d8616-5dfe-4f0c-8444-328be19a0613',
    'Equipe Modelo 2',
    'Estrutura demonstrativa editável vinculada ao PDV Modelo 2.',
    'active',
    'team-model-2',
    'rf_performance',
    jsonb_build_object(
      'template_record', true,
      'template_key', 'commercial_acceleration_v1',
      'setup_status', 'pending_confirmation',
      'data_origin', 'template',
      'confirmed_at', null,
      'confirmed_by', null,
      'presentation_order', 2,
      'planned_supervisor_positions', 1,
      'planned_salesperson_capacity', 7,
      'provisional_name', true
    )
  ),
  (
    '8e2e83c0-17fc-4e1a-a529-cd4bc5c1a103',
    '414a2e84-bc62-4c64-99ee-76db1cbc4654',
    'c3982529-3988-47f5-a216-8e4b04187a10',
    '3f903b49-3268-4d12-a3d4-76bcb4bbc01f',
    'Equipe Modelo 3',
    'Estrutura demonstrativa editável vinculada ao PDV Modelo 3.',
    'active',
    'team-model-3',
    'rf_performance',
    jsonb_build_object(
      'template_record', true,
      'template_key', 'commercial_acceleration_v1',
      'setup_status', 'pending_confirmation',
      'data_origin', 'template',
      'confirmed_at', null,
      'confirmed_by', null,
      'presentation_order', 3,
      'planned_supervisor_positions', 1,
      'planned_salesperson_capacity', 6,
      'provisional_name', true
    )
  )
on conflict (id) do update
set
  organization_id = excluded.organization_id,
  operation_id = excluded.operation_id,
  sales_location_id = excluded.sales_location_id,
  name = case
    when public.teams.metadata ->> 'setup_status' = 'confirmed'
      then public.teams.name
    else excluded.name
  end,
  description = case
    when public.teams.metadata ->> 'setup_status' = 'confirmed'
      then public.teams.description
    else excluded.description
  end,
  status = 'active',
  external_id = excluded.external_id,
  source_system = excluded.source_system,
  metadata = public.teams.metadata || excluded.metadata,
  updated_at = now();

create or replace function private.enforce_single_active_salesperson_team()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member_role text;
begin
  if new.status <> 'active' or new.archived_at is not null then
    return new;
  end if;

  select om.role
    into v_member_role
  from public.organization_members om
  where om.id = new.organization_member_id
    and om.organization_id = new.organization_id;

  if v_member_role = 'salesperson'
     and exists (
       select 1
       from public.team_members existing
       where existing.organization_id = new.organization_id
         and existing.organization_member_id = new.organization_member_id
         and existing.status = 'active'
         and existing.archived_at is null
         and existing.id <> new.id
     ) then
    raise exception using
      errcode = '23505',
      message = 'O vendedor já pertence a uma equipe ativa. Encerre o vínculo anterior antes da transferência.';
  end if;

  return new;
end;
$$;

revoke all
on function private.enforce_single_active_salesperson_team()
from public, anon, authenticated;

drop trigger if exists
  team_members_enforce_single_active_salesperson_team
on public.team_members;

create trigger team_members_enforce_single_active_salesperson_team
before insert or update of organization_member_id, organization_id, status, archived_at
on public.team_members
for each row
execute function private.enforce_single_active_salesperson_team();

commit;
