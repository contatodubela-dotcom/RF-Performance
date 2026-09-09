begin;

-- RF Performance
-- Transferência segura e atômica de vendedor entre equipes.
-- Regras:
--   * somente platform_admin ou director;
--   * vendedor deve pertencer à organização e estar ativo;
--   * destino deve ser uma equipe ativa da mesma organização, com PDV e supervisor ativo;
--   * respeita a capacidade planejada quando planned_salesperson_capacity > 0;
--   * encerra o vínculo anterior e cria o novo vínculo na mesma transação;
--   * preserva histórico e registra auditoria.

create or replace function public.transfer_salesperson_team(
  p_organization_id uuid,
  p_organization_member_id uuid,
  p_destination_team_id uuid
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $function$
declare
  v_actor_user_id uuid := auth.uid();
  v_now timestamptz := pg_catalog.now();

  v_member public.organization_members%rowtype;
  v_source_assignment public.team_members%rowtype;
  v_source_team public.teams%rowtype;
  v_destination_team public.teams%rowtype;

  v_destination_supervisor public.organization_members%rowtype;
  v_destination_capacity integer := 0;
  v_destination_active_salespersons integer := 0;
  v_new_assignment_id uuid;
begin
  if v_actor_user_id is null then
    raise exception 'AUTH_REQUIRED'
      using errcode = '42501';
  end if;

  if p_organization_id is null
     or p_organization_member_id is null
     or p_destination_team_id is null then
    raise exception 'SALESPERSON_TRANSFER_INVALID_INPUT'
      using errcode = '22023';
  end if;

  if not (
    pg_catalog.coalesce(private.is_platform_admin(), false)
    or pg_catalog.coalesce(
      private.has_org_role(
        p_organization_id,
        array['director']::text[]
      ),
      false
    )
  ) then
    raise exception 'SALESPERSON_TRANSFER_FORBIDDEN'
      using errcode = '42501';
  end if;

  select om.*
    into v_member
  from public.organization_members om
  where om.id = p_organization_member_id
    and om.organization_id = p_organization_id
    and om.role = 'salesperson'
    and om.status = 'active'
    and om.archived_at is null
  for update;

  if not found then
    raise exception 'SALESPERSON_NOT_ACTIVE'
      using errcode = 'P0002';
  end if;

  -- O índice único parcial de team_members garante apenas um vínculo ativo
  -- por vendedor/organização. O lock abaixo serializa transferências concorrentes
  -- do mesmo vendedor.
  select tm.*
    into v_source_assignment
  from public.team_members tm
  where tm.organization_id = p_organization_id
    and tm.organization_member_id = p_organization_member_id
    and tm.status = 'active'
    and tm.archived_at is null
  for update;

  if not found then
    raise exception 'SALESPERSON_ACTIVE_TEAM_NOT_FOUND'
      using errcode = 'P0002';
  end if;

  select t.*
    into v_source_team
  from public.teams t
  where t.id = v_source_assignment.team_id
    and t.organization_id = p_organization_id;

  -- Lock da equipe de destino também serializa a validação de capacidade
  -- entre transferências concorrentes para a mesma equipe.
  select t.*
    into v_destination_team
  from public.teams t
  where t.id = p_destination_team_id
    and t.organization_id = p_organization_id
    and t.status = 'active'
    and t.archived_at is null
  for update;

  if not found then
    raise exception 'DESTINATION_TEAM_NOT_ACTIVE'
      using errcode = 'P0002';
  end if;

  if v_destination_team.id = v_source_assignment.team_id then
    raise exception 'SALESPERSON_ALREADY_IN_DESTINATION_TEAM'
      using errcode = '22023';
  end if;

  if v_destination_team.sales_location_id is null then
    raise exception 'DESTINATION_TEAM_WITHOUT_SALES_LOCATION'
      using errcode = '23514';
  end if;

  if v_destination_team.supervisor_member_id is null then
    raise exception 'DESTINATION_TEAM_WITHOUT_SUPERVISOR'
      using errcode = '23514';
  end if;

  select om.*
    into v_destination_supervisor
  from public.organization_members om
  where om.id = v_destination_team.supervisor_member_id
    and om.organization_id = p_organization_id
    and om.role = 'supervisor'
    and om.status = 'active'
    and om.archived_at is null;

  if not found then
    raise exception 'DESTINATION_TEAM_SUPERVISOR_NOT_ACTIVE'
      using errcode = '23514';
  end if;

  if (
    pg_catalog.jsonb_typeof(
      v_destination_team.metadata -> 'planned_salesperson_capacity'
    ) = 'number'
  ) then
    v_destination_capacity := pg_catalog.floor(
      (v_destination_team.metadata ->> 'planned_salesperson_capacity')::numeric
    )::integer;
  end if;

  select pg_catalog.count(*)::integer
    into v_destination_active_salespersons
  from public.team_members tm
  join public.organization_members om
    on om.id = tm.organization_member_id
   and om.organization_id = tm.organization_id
  where tm.organization_id = p_organization_id
    and tm.team_id = p_destination_team_id
    and tm.status = 'active'
    and tm.archived_at is null
    and om.role = 'salesperson'
    and om.status = 'active'
    and om.archived_at is null;

  -- Capacidade 0/ausente mantém o comportamento legado de "sem limite definido".
  if v_destination_capacity > 0
     and v_destination_active_salespersons >= v_destination_capacity then
    raise exception 'DESTINATION_TEAM_CAPACITY_EXCEEDED'
      using errcode = '23514',
            detail = pg_catalog.format(
              'Equipe destino possui %s de %s vendedores ativos.',
              v_destination_active_salespersons,
              v_destination_capacity
            );
  end if;

  update public.team_members
  set status = 'inactive',
      end_at = v_now,
      updated_at = v_now,
      updated_by = v_actor_user_id
  where id = v_source_assignment.id;

  insert into public.team_members (
    organization_id,
    team_id,
    organization_member_id,
    membership_type,
    start_at,
    end_at,
    status,
    created_by,
    updated_by,
    metadata
  )
  values (
    p_organization_id,
    p_destination_team_id,
    p_organization_member_id,
    'salesperson',
    v_now,
    null,
    'active',
    v_actor_user_id,
    v_actor_user_id,
    pg_catalog.jsonb_build_object(
      'transfer_source', 'transfer_salesperson_team',
      'transferred_from_team_id', v_source_assignment.team_id,
      'transferred_from_team_member_id', v_source_assignment.id,
      'transferred_at', v_now,
      'transferred_by', v_actor_user_id
    )
  )
  returning id into v_new_assignment_id;

  insert into public.audit_logs (
    organization_id,
    user_id,
    action,
    entity_type,
    entity_id,
    old_values,
    new_values
  )
  values (
    p_organization_id,
    v_actor_user_id,
    'salesperson_team_transferred',
    'organization_member',
    p_organization_member_id,
    pg_catalog.jsonb_build_object(
      'team_member_id', v_source_assignment.id,
      'team_id', v_source_assignment.team_id,
      'team_name', v_source_team.name,
      'membership_type', v_source_assignment.membership_type,
      'status', v_source_assignment.status,
      'start_at', v_source_assignment.start_at
    ),
    pg_catalog.jsonb_build_object(
      'team_member_id', v_new_assignment_id,
      'team_id', v_destination_team.id,
      'team_name', v_destination_team.name,
      'membership_type', 'salesperson',
      'status', 'active',
      'start_at', v_now,
      'transferred_at', v_now
    )
  );

  return pg_catalog.jsonb_build_object(
    'success', true,
    'organization_id', p_organization_id,
    'organization_member_id', p_organization_member_id,
    'source_team_id', v_source_assignment.team_id,
    'source_team_name', v_source_team.name,
    'destination_team_id', v_destination_team.id,
    'destination_team_name', v_destination_team.name,
    'previous_team_member_id', v_source_assignment.id,
    'new_team_member_id', v_new_assignment_id,
    'transferred_at', v_now
  );
end;
$function$;

comment on function public.transfer_salesperson_team(uuid, uuid, uuid) is
  'Transfere atomicamente um vendedor entre equipes. Permitido somente para platform_admin ou director; preserva histórico em team_members e registra audit_logs.';

revoke all on function public.transfer_salesperson_team(uuid, uuid, uuid) from public;
revoke all on function public.transfer_salesperson_team(uuid, uuid, uuid) from anon;
grant execute on function public.transfer_salesperson_team(uuid, uuid, uuid) to authenticated;

commit;
