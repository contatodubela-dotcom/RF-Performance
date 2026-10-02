begin;

-- RF Performance
-- Promoção segura de vendedor para supervisor.
-- Regras:
--   * somente Platform Admin ou Diretor da organização;
--   * vendedor deve estar ativo e não arquivado;
--   * encerra vínculos ativos como vendedor em team_members, preservando histórico;
--   * altera organization_members.role sem recriar o usuário/membership;
--   * opcionalmente atribui o novo supervisor a uma equipe ativa;
--   * quando há equipe, reutiliza a rotina segura de troca de supervisor;
--   * preserva vendas, avaliações, treinamentos e demais históricos ligados ao membership;
--   * registra auditoria semântica da promoção.

create or replace function private.promote_salesperson_to_supervisor_impl(
  p_organization_id uuid,
  p_organization_member_id uuid,
  p_team_id uuid default null
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
  v_profile_name text;
  v_active_assignment_count integer := 0;
  v_source_team_ids jsonb := '[]'::jsonb;
  v_team_change jsonb := null;
begin
  if v_actor_user_id is null then
    raise exception 'AUTH_REQUIRED'
      using errcode = '42501';
  end if;

  if p_organization_id is null
     or p_organization_member_id is null then
    raise exception 'SALESPERSON_PROMOTION_INVALID_INPUT'
      using errcode = '22023';
  end if;

  if not (
    coalesce(private.is_platform_admin(), false)
    or coalesce(
      private.has_org_role(
        p_organization_id,
        array['director']::text[]
      ),
      false
    )
  ) then
    raise exception 'SALESPERSON_PROMOTION_FORBIDDEN'
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

  select p.full_name
    into v_profile_name
  from public.profiles p
  where p.id = v_member.user_id;

  if p_team_id is not null then
    perform 1
    from public.teams t
    where t.id = p_team_id
      and t.organization_id = p_organization_id
      and t.status = 'active'
      and t.archived_at is null
    for update;

    if not found then
      raise exception 'PROMOTION_TEAM_NOT_ACTIVE'
        using errcode = 'P0002';
    end if;
  end if;

  select
    pg_catalog.count(*)::integer,
    coalesce(
      pg_catalog.jsonb_agg(
        pg_catalog.jsonb_build_object(
          'team_member_id', tm.id,
          'team_id', tm.team_id,
          'start_at', tm.start_at
        )
        order by tm.created_at
      ),
      '[]'::jsonb
    )
  into
    v_active_assignment_count,
    v_source_team_ids
  from public.team_members tm
  where tm.organization_id = p_organization_id
    and tm.organization_member_id = p_organization_member_id
    and tm.membership_type = 'salesperson'
    and tm.status = 'active'
    and tm.archived_at is null;

  update public.team_members
  set status = 'inactive',
      end_at = coalesce(end_at, v_now),
      updated_at = v_now,
      updated_by = v_actor_user_id,
      metadata = coalesce(metadata, '{}'::jsonb)
        || pg_catalog.jsonb_build_object(
          'ended_reason', 'promoted_to_supervisor',
          'promoted_at', v_now,
          'promoted_by', v_actor_user_id
        )
  where organization_id = p_organization_id
    and organization_member_id = p_organization_member_id
    and membership_type = 'salesperson'
    and status = 'active'
    and archived_at is null;

  update public.organization_members
  set role = 'supervisor',
      updated_at = v_now,
      updated_by = v_actor_user_id,
      metadata = coalesce(metadata, '{}'::jsonb)
        || pg_catalog.jsonb_build_object(
          'promoted_from_role', 'salesperson',
          'promoted_to_role', 'supervisor',
          'promoted_at', v_now,
          'promoted_by', v_actor_user_id
        )
  where id = p_organization_member_id
    and organization_id = p_organization_id;

  if p_team_id is not null then
    v_team_change := private.change_team_supervisor_impl(
      p_organization_id,
      p_team_id,
      p_organization_member_id
    );
  end if;

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
    'salesperson_promoted_to_supervisor',
    'organization_member',
    p_organization_member_id,
    pg_catalog.jsonb_build_object(
      'role', 'salesperson',
      'active_salesperson_assignments', v_source_team_ids
    ),
    pg_catalog.jsonb_build_object(
      'role', 'supervisor',
      'profile_name', v_profile_name,
      'ended_salesperson_assignment_count', v_active_assignment_count,
      'assigned_team_id', p_team_id,
      'team_supervisor_change', v_team_change,
      'promoted_at', v_now
    )
  );

  return pg_catalog.jsonb_build_object(
    'success', true,
    'organization_id', p_organization_id,
    'organization_member_id', p_organization_member_id,
    'user_id', v_member.user_id,
    'profile_name', v_profile_name,
    'previous_role', 'salesperson',
    'new_role', 'supervisor',
    'ended_salesperson_assignment_count', v_active_assignment_count,
    'assigned_team_id', p_team_id,
    'team_supervisor_change', v_team_change,
    'promoted_at', v_now
  );
end;
$function$;

comment on function private.promote_salesperson_to_supervisor_impl(uuid, uuid, uuid) is
  'Promove vendedor ativo a supervisor preservando o mesmo membership e todo o histórico; encerra vínculos ativos de vendedor e pode atribuir uma equipe.';

revoke all on function private.promote_salesperson_to_supervisor_impl(uuid, uuid, uuid)
from public, anon, authenticated;

grant execute on function private.promote_salesperson_to_supervisor_impl(uuid, uuid, uuid)
to authenticated;

create or replace function public.promote_salesperson_to_supervisor(
  p_organization_id uuid,
  p_organization_member_id uuid,
  p_team_id uuid default null
)
returns jsonb
language sql
volatile
security invoker
set search_path = ''
as $function$
  select private.promote_salesperson_to_supervisor_impl(
    p_organization_id,
    p_organization_member_id,
    p_team_id
  );
$function$;

comment on function public.promote_salesperson_to_supervisor(uuid, uuid, uuid) is
  'Wrapper autenticado para promoção segura de vendedor a supervisor.';

revoke all on function public.promote_salesperson_to_supervisor(uuid, uuid, uuid)
from public, anon, authenticated;

grant execute on function public.promote_salesperson_to_supervisor(uuid, uuid, uuid)
to authenticated;

do $postcondition$
begin
  if pg_catalog.to_regprocedure(
    'private.promote_salesperson_to_supervisor_impl(uuid,uuid,uuid)'
  ) is null then
    raise exception 'SALESPERSON_PROMOTION_POSTCONDITION_FAILED: implementação privada ausente';
  end if;

  if pg_catalog.to_regprocedure(
    'public.promote_salesperson_to_supervisor(uuid,uuid,uuid)'
  ) is null then
    raise exception 'SALESPERSON_PROMOTION_POSTCONDITION_FAILED: wrapper público ausente';
  end if;

  if pg_catalog.has_function_privilege(
    'anon',
    'public.promote_salesperson_to_supervisor(uuid,uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception 'SALESPERSON_PROMOTION_POSTCONDITION_FAILED: anon possui EXECUTE inesperado';
  end if;

  if not pg_catalog.has_function_privilege(
    'authenticated',
    'public.promote_salesperson_to_supervisor(uuid,uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception 'SALESPERSON_PROMOTION_POSTCONDITION_FAILED: authenticated sem EXECUTE';
  end if;
end
$postcondition$;

commit;
