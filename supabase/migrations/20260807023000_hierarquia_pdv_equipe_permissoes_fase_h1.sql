-- ============================================================================
-- RF Performance Comercial
-- Fase H1 — integridade de hierarquia PDV -> Equipe -> Supervisor -> Vendedor
-- Data: 2026-08-07
--
-- Objetivos:
--   1) garantir no banco que vínculo ativo em team_members pertence a vendedor;
--   2) impedir vendedor ativo em mais de uma equipe simultaneamente;
--   3) exigir equipe ativa, com PDV e supervisor, para receber vendedor ativo;
--   4) preservar o modelo atual de RLS: supervisor continua sem escrita direta
--      em team_members; o cadastro hierárquico ocorre pela Edge Function segura.
-- ============================================================================

begin;

-- --------------------------------------------------------------------------
-- Preflight transacional: não aplicar se houver legado incompatível.
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
      message = 'H1_ABORT_ACTIVE_TEAM_MEMBER_IS_NOT_ACTIVE_SALESPERSON';
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
      message = 'H1_ABORT_ACTIVE_TEAM_MEMBER_WITH_INCOMPLETE_TEAM_HIERARCHY';
  end if;

  if exists (
    select 1
    from public.team_members tm
    where tm.status = 'active'
      and tm.archived_at is null
    group by tm.organization_id, tm.organization_member_id
    having count(*) > 1
  ) then
    raise exception using
      errcode = '23514',
      message = 'H1_ABORT_SALESPERSON_WITH_MULTIPLE_ACTIVE_TEAMS';
  end if;
end;
$$;

-- --------------------------------------------------------------------------
-- Regra estrutural: um vendedor pode ter apenas uma equipe ativa por organização.
-- Histórico inativo permanece preservado e pode conter múltiplos períodos.
-- --------------------------------------------------------------------------

create unique index if not exists team_members_active_member_org_uidx
  on public.team_members (organization_id, organization_member_id)
  where status = 'active' and archived_at is null;

-- --------------------------------------------------------------------------
-- Validação de vínculo ativo.
-- A trigger atua inclusive em operações executadas por service role.
-- --------------------------------------------------------------------------

create or replace function private.validate_team_member_assignment()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Registros históricos/inativos não precisam manter a estrutura atual ativa.
  if new.status <> 'active' or new.archived_at is not null then
    return new;
  end if;

  if not exists (
    select 1
    from public.organization_members om
    where om.id = new.organization_member_id
      and om.organization_id = new.organization_id
      and om.role = 'salesperson'
      and om.status = 'active'
      and om.archived_at is null
  ) then
    raise exception using
      errcode = '23514',
      message = 'O membro ativo da equipe deve ser um vendedor ativo da mesma organização.';
  end if;

  if not exists (
    select 1
    from public.teams t
    where t.id = new.team_id
      and t.organization_id = new.organization_id
      and t.status = 'active'
      and t.archived_at is null
      and t.sales_location_id is not null
      and t.supervisor_member_id is not null
  ) then
    raise exception using
      errcode = '23514',
      message = 'A equipe do vendedor deve estar ativa e possuir PDV e supervisor definidos.';
  end if;

  if exists (
    select 1
    from public.team_members tm
    where tm.organization_id = new.organization_id
      and tm.organization_member_id = new.organization_member_id
      and tm.status = 'active'
      and tm.archived_at is null
      and tm.id <> new.id
  ) then
    raise exception using
      errcode = '23505',
      message = 'O vendedor já possui vínculo ativo com outra equipe.';
  end if;

  new.membership_type := 'salesperson';
  return new;
end;
$$;

revoke all on function private.validate_team_member_assignment() from public;

-- Nome iniciado por "team_members_validate" para coexistir com os guards atuais.
drop trigger if exists team_members_validate_assignment on public.team_members;
create trigger team_members_validate_assignment
before insert or update of
  organization_id,
  team_id,
  organization_member_id,
  status,
  archived_at,
  membership_type
on public.team_members
for each row execute function private.validate_team_member_assignment();

-- --------------------------------------------------------------------------
-- Pós-condições dentro da mesma transação.
-- --------------------------------------------------------------------------

do $$
begin
  if not exists (
    select 1
    from pg_catalog.pg_indexes
    where schemaname = 'public'
      and tablename = 'team_members'
      and indexname = 'team_members_active_member_org_uidx'
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'H1_POSTCONDITION_UNIQUE_ACTIVE_TEAM_INDEX_MISSING';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_trigger tg
    join pg_catalog.pg_class c on c.oid = tg.tgrelid
    join pg_catalog.pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname = 'team_members'
      and tg.tgname = 'team_members_validate_assignment'
      and not tg.tgisinternal
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'H1_POSTCONDITION_VALIDATION_TRIGGER_MISSING';
  end if;
end;
$$;

commit;
