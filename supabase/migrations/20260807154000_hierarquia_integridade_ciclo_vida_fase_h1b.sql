-- ============================================================================
-- RF Performance Comercial
-- Fase H1B — integridade do ciclo de vida da hierarquia
-- Data: 2026-08-07
--
-- Objetivos:
--   1) impedir que vendedor com vínculo ativo em equipe seja inativado,
--      arquivado ou tenha o papel alterado sem encerrar antes o vínculo;
--   2) impedir que supervisor responsável por equipe ativa seja inativado,
--      arquivado ou tenha o papel alterado antes da reatribuição da equipe;
--   3) impedir que uma equipe com vendedores ativos perca PDV, supervisor,
--      status ativo ou seja arquivada;
--   4) revalidar supervisor quando uma equipe é ativada/desarquivada;
--   5) preservar histórico de equipes e vínculos inativos.
-- ============================================================================

begin;

-- --------------------------------------------------------------------------
-- Preflight transacional: aborta se o estado atual já violar as regras H1.
-- --------------------------------------------------------------------------

do $$
begin
  if exists (
    select 1
    from public.team_members tm
    join public.organization_members om
      on om.id = tm.organization_member_id
     and om.organization_id = tm.organization_id
    where tm.status = 'active'
      and tm.archived_at is null
      and (
        om.role <> 'salesperson'
        or om.status <> 'active'
        or om.archived_at is not null
      )
  ) then
    raise exception using
      errcode = '23514',
      message = 'H1B_ABORT_ACTIVE_TEAM_MEMBER_IS_NOT_ACTIVE_SALESPERSON';
  end if;

  if exists (
    select 1
    from public.team_members tm
    join public.teams t
      on t.id = tm.team_id
     and t.organization_id = tm.organization_id
    where tm.status = 'active'
      and tm.archived_at is null
      and (
        t.status <> 'active'
        or t.archived_at is not null
        or t.sales_location_id is null
        or t.supervisor_member_id is null
      )
  ) then
    raise exception using
      errcode = '23514',
      message = 'H1B_ABORT_ACTIVE_ASSIGNMENT_WITH_INCOMPLETE_TEAM_HIERARCHY';
  end if;

  if exists (
    select 1
    from public.teams t
    where t.status = 'active'
      and t.archived_at is null
      and t.supervisor_member_id is not null
      and not exists (
        select 1
        from public.organization_members om
        where om.id = t.supervisor_member_id
          and om.organization_id = t.organization_id
          and om.role = 'supervisor'
          and om.status = 'active'
          and om.archived_at is null
      )
  ) then
    raise exception using
      errcode = '23514',
      message = 'H1B_ABORT_ACTIVE_TEAM_WITH_INVALID_SUPERVISOR';
  end if;
end;
$$;

-- --------------------------------------------------------------------------
-- Supervisor de equipe:
-- histórico/inativo pode manter referência histórica a ex-supervisor.
-- Quando a equipe está ativa, supervisor informado precisa ser supervisor ativo.
-- --------------------------------------------------------------------------

create or replace function private.validate_team_supervisor()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.supervisor_member_id is null then
    return new;
  end if;

  -- Equipes inativas/arquivadas podem preservar o supervisor histórico.
  if new.status <> 'active' or new.archived_at is not null then
    return new;
  end if;

  if not exists (
    select 1
    from public.organization_members om
    where om.id = new.supervisor_member_id
      and om.organization_id = new.organization_id
      and om.role = 'supervisor'
      and om.status = 'active'
      and om.archived_at is null
  ) then
    raise exception using
      errcode = '23514',
      message = 'O supervisor da equipe ativa deve ser um membro supervisor ativo da mesma organização.';
  end if;

  return new;
end;
$$;

revoke all on function private.validate_team_supervisor() from public;

drop trigger if exists teams_validate_supervisor on public.teams;

create trigger teams_validate_supervisor
before insert or update of
  supervisor_member_id,
  organization_id,
  status,
  archived_at
on public.teams
for each row execute function private.validate_team_supervisor();

-- --------------------------------------------------------------------------
-- Guarda da própria equipe:
-- se houver vendedores ativos, a hierarquia da equipe não pode ser quebrada.
-- --------------------------------------------------------------------------

create or replace function private.guard_team_active_assignments_hierarchy()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if exists (
    select 1
    from public.team_members tm
    where tm.organization_id = old.organization_id
      and tm.team_id = old.id
      and tm.status = 'active'
      and tm.archived_at is null
  ) then
    if new.status <> 'active'
       or new.archived_at is not null
       or new.sales_location_id is null
       or new.supervisor_member_id is null then
      raise exception using
        errcode = '23514',
        message = 'A equipe possui vendedores ativos. Remova ou encerre os vínculos antes de inativar, arquivar ou remover PDV/supervisor.';
    end if;
  end if;

  return new;
end;
$$;

revoke all on function private.guard_team_active_assignments_hierarchy() from public;

drop trigger if exists teams_guard_active_assignments_hierarchy on public.teams;

create trigger teams_guard_active_assignments_hierarchy
before update of
  status,
  archived_at,
  sales_location_id,
  supervisor_member_id
on public.teams
for each row execute function private.guard_team_active_assignments_hierarchy();

-- --------------------------------------------------------------------------
-- Guarda do ciclo de vida dos membros:
-- 1) vendedor com vínculo ativo não pode deixar de ser vendedor ativo;
-- 2) supervisor de equipe ativa não pode deixar de ser supervisor ativo.
-- --------------------------------------------------------------------------

create or replace function private.guard_hierarchy_membership_lifecycle()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (
    new.role is distinct from old.role
    or new.status is distinct from old.status
    or new.archived_at is distinct from old.archived_at
  ) then
    if exists (
      select 1
      from public.team_members tm
      where tm.organization_id = old.organization_id
        and tm.organization_member_id = old.id
        and tm.status = 'active'
        and tm.archived_at is null
    ) and (
      new.role <> 'salesperson'
      or new.status <> 'active'
      or new.archived_at is not null
    ) then
      raise exception using
        errcode = '23514',
        message = 'O vendedor possui vínculo ativo com equipe. Encerre o vínculo antes de alterar papel, status ou arquivamento.';
    end if;

    if exists (
      select 1
      from public.teams t
      where t.organization_id = old.organization_id
        and t.supervisor_member_id = old.id
        and t.status = 'active'
        and t.archived_at is null
    ) and (
      new.role <> 'supervisor'
      or new.status <> 'active'
      or new.archived_at is not null
    ) then
      raise exception using
        errcode = '23514',
        message = 'O supervisor é responsável por equipe ativa. Reatribua ou desassocie as equipes antes de alterar papel, status ou arquivamento.';
    end if;
  end if;

  return new;
end;
$$;

revoke all on function private.guard_hierarchy_membership_lifecycle() from public;

drop trigger if exists organization_members_guard_hierarchy_lifecycle
  on public.organization_members;

create trigger organization_members_guard_hierarchy_lifecycle
before update of role, status, archived_at
on public.organization_members
for each row execute function private.guard_hierarchy_membership_lifecycle();

-- --------------------------------------------------------------------------
-- Pós-condições dentro da mesma transação.
-- --------------------------------------------------------------------------

do $$
declare
  v_team_trigger text;
begin
  if not exists (
    select 1
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'private'
      and p.proname = 'guard_hierarchy_membership_lifecycle'
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'H1B_POSTCONDITION_MEMBERSHIP_LIFECYCLE_FUNCTION_MISSING';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_trigger tg
    join pg_catalog.pg_class c on c.oid = tg.tgrelid
    join pg_catalog.pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname = 'organization_members'
      and tg.tgname = 'organization_members_guard_hierarchy_lifecycle'
      and not tg.tgisinternal
      and tg.tgenabled <> 'D'
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'H1B_POSTCONDITION_MEMBERSHIP_LIFECYCLE_TRIGGER_MISSING';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_trigger tg
    join pg_catalog.pg_class c on c.oid = tg.tgrelid
    join pg_catalog.pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname = 'teams'
      and tg.tgname = 'teams_guard_active_assignments_hierarchy'
      and not tg.tgisinternal
      and tg.tgenabled <> 'D'
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'H1B_POSTCONDITION_TEAM_HIERARCHY_TRIGGER_MISSING';
  end if;

  select pg_get_triggerdef(tg.oid, true)
    into v_team_trigger
  from pg_catalog.pg_trigger tg
  join pg_catalog.pg_class c on c.oid = tg.tgrelid
  join pg_catalog.pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'teams'
    and tg.tgname = 'teams_validate_supervisor'
    and not tg.tgisinternal
  limit 1;

  if v_team_trigger is null
     or v_team_trigger not ilike '%status%'
     or v_team_trigger not ilike '%archived_at%' then
    raise exception using
      errcode = 'P0001',
      message = 'H1B_POSTCONDITION_TEAM_SUPERVISOR_TRIGGER_NOT_LIFECYCLE_AWARE';
  end if;
end;
$$;

commit;
