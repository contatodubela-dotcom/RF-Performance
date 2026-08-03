begin;

-- Fase compatível: classifica os rituais e cria RPCs seguras sem retirar
-- as policies antigas. Assim, o frontend publicado continua funcionando
-- durante a implantação.
update public.management_rituals
set
  metadata = jsonb_set(
    coalesce(metadata, '{}'::jsonb),
    '{audience_roles}',
    case
      when title in (
        'Abertura do PDV',
        'Fechamento do dia',
        'Feedback individual',
        'Microtreinamento',
        'Role-play'
      ) then '["salesperson","supervisor","director"]'::jsonb
      when title in (
        'Performance mensal',
        'Reunião de supervisores',
        'Revisão de funil'
      ) then '["supervisor","director"]'::jsonb
      when title = 'Reunião executiva de performance'
        then '["director"]'::jsonb
      else coalesce(metadata -> 'audience_roles', '[]'::jsonb)
    end,
    true
  ),
  updated_at = now()
where archived_at is null;

-- Referência mínima do plano para telas operacionais.
create or replace function public.get_commercial_plan_reference(
  p_organization_id uuid
)
returns table (
  id uuid,
  organization_id uuid,
  title text,
  status text
)
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $function$
begin
  if auth.uid() is null then
    return;
  end if;

  if not (
    private.is_platform_admin()
    or private.has_active_membership(p_organization_id)
  ) then
    return;
  end if;

  return query
  select
    cp.id,
    cp.organization_id,
    cp.title,
    cp.status
  from public.commercial_plans cp
  where cp.organization_id = p_organization_id
    and cp.status <> 'archived'
    and cp.archived_at is null
  order by cp.created_at
  limit 1;
end;
$function$;

revoke all
on function public.get_commercial_plan_reference(uuid)
from public;

revoke all
on function public.get_commercial_plan_reference(uuid)
from anon;

grant execute
on function public.get_commercial_plan_reference(uuid)
to authenticated;

-- Lista de rituais já filtrada no servidor conforme o perfil do usuário.
-- A função permite publicar o novo frontend antes de endurecer as policies
-- de leitura direta das tabelas.
create or replace function public.get_management_rituals_for_current_user(
  p_plan_id uuid
)
returns table (
  id uuid,
  organization_id uuid,
  plan_id uuid,
  title text,
  frequency_label text,
  responsible_role text,
  duration_minutes integer,
  expected_output text,
  status text,
  is_template boolean
)
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $function$
declare
  v_organization_id uuid;
begin
  if auth.uid() is null then
    return;
  end if;

  select cp.organization_id
  into v_organization_id
  from public.commercial_plans cp
  where cp.id = p_plan_id
    and cp.status <> 'archived'
    and cp.archived_at is null
  limit 1;

  if v_organization_id is null then
    return;
  end if;

  if not (
    private.is_platform_admin()
    or private.has_active_membership(v_organization_id)
  ) then
    return;
  end if;

  return query
  select
    mr.id,
    mr.organization_id,
    mr.plan_id,
    mr.title,
    mr.frequency_label,
    mr.responsible_role,
    mr.duration_minutes,
    mr.expected_output,
    mr.status,
    mr.is_template
  from public.management_rituals mr
  where mr.plan_id = p_plan_id
    and mr.status <> 'archived'
    and mr.archived_at is null
    and (
      private.is_platform_admin()
      or private.has_org_role(
        v_organization_id,
        array['director'::text]
      )
      or (
        private.has_org_role(
          v_organization_id,
          array['supervisor'::text]
        )
        and coalesce(
          mr.metadata -> 'audience_roles',
          '[]'::jsonb
        ) ? 'supervisor'
      )
      or (
        private.has_org_role(
          v_organization_id,
          array['salesperson'::text]
        )
        and coalesce(
          mr.metadata -> 'audience_roles',
          '[]'::jsonb
        ) ? 'salesperson'
      )
    )
  order by mr.created_at;
end;
$function$;

revoke all
on function public.get_management_rituals_for_current_user(uuid)
from public;

revoke all
on function public.get_management_rituals_for_current_user(uuid)
from anon;

grant execute
on function public.get_management_rituals_for_current_user(uuid)
to authenticated;

comment on function public.get_commercial_plan_reference(uuid)
is 'Retorna somente id, organização, título e status do plano para membros ativos.';

comment on function public.get_management_rituals_for_current_user(uuid)
is 'Retorna rituais filtrados no servidor conforme o perfil do usuário autenticado.';

commit;
