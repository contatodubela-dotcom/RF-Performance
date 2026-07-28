-- ============================================================================
-- RF Performance Comercial
-- Migration 001 — Fundação estrutural
-- Data: 2026-07-27
--
-- Cria a fundação multiempresa, vínculos organizacionais, operações, PDVs,
-- equipes, membros, auditoria, validações cruzadas e sincronização com Auth.
--
-- Segurança: RLS é ativada nesta migration sem policies permissivas. Até a
-- migration seguinte, as tabelas permanecem fechadas para o Data API.
-- ============================================================================

begin;

create schema if not exists private;
revoke all on schema private from public;
alter default privileges in schema private revoke execute on functions from public;

-- --------------------------------------------------------------------------
-- Funções genéricas de normalização e autoria
-- --------------------------------------------------------------------------

create or replace function private.set_row_metadata()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.created_at := coalesce(new.created_at, now());
    new.updated_at := coalesce(new.updated_at, new.created_at, now());

    if new.created_by is null then
      new.created_by := auth.uid();
    end if;

    if new.updated_by is null then
      new.updated_by := coalesce(auth.uid(), new.created_by);
    end if;
  else
    new.created_at := old.created_at;
    new.created_by := old.created_by;
    new.updated_at := now();

    if new.updated_by is null or new.updated_by = old.updated_by then
      new.updated_by := coalesce(auth.uid(), old.updated_by);
    end if;
  end if;

  if to_jsonb(new) ? 'status' and to_jsonb(new) ? 'archived_at' then
    if new.status = 'archived' and new.archived_at is null then
      new.archived_at := now();
    elsif new.status <> 'archived' then
      new.archived_at := null;
    end if;
  end if;

  return new;
end;
$$;

-- --------------------------------------------------------------------------
-- Tabelas
-- --------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  preferred_name text,
  email text,
  phone text,
  avatar_url text,
  system_role text,
  status text not null default 'active',
  last_access_at timestamptz,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint profiles_system_role_check
    check (system_role is null or system_role = 'platform_admin'),
  constraint profiles_status_check
    check (status in ('active', 'inactive')),
  constraint profiles_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  legal_name text,
  trade_name text not null,
  slug text not null,
  document_number text,
  email text,
  phone text,
  logo_url text,
  status text not null default 'active',
  external_id text,
  source_system text not null default 'rf_performance',
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint organizations_slug_key unique (slug),
  constraint organizations_id_organization_key unique (id),
  constraint organizations_status_check
    check (status in ('active', 'inactive', 'archived')),
  constraint organizations_slug_format_check
    check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  constraint organizations_source_system_check
    check (source_system in (
      'rf_performance', 'epsa_core', 'mci_consorcio',
      'manual_import', 'spreadsheet_import', 'api'
    )),
  constraint organizations_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);

create table public.organization_members (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  user_id uuid not null,
  role text not null,
  status text not null default 'active',
  invited_at timestamptz,
  joined_at timestamptz,
  external_id text,
  source_system text not null default 'rf_performance',
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint organization_members_organization_id_fkey
    foreign key (organization_id)
    references public.organizations(id)
    on delete restrict,
  constraint organization_members_user_id_fkey
    foreign key (user_id)
    references public.profiles(id)
    on delete restrict,
  constraint organization_members_id_org_key
    unique (id, organization_id),
  constraint organization_members_role_check
    check (role in ('director', 'supervisor', 'salesperson')),
  constraint organization_members_status_check
    check (status in ('active', 'inactive', 'archived')),
  constraint organization_members_source_system_check
    check (source_system in (
      'rf_performance', 'epsa_core', 'mci_consorcio',
      'manual_import', 'spreadsheet_import', 'api'
    )),
  constraint organization_members_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);

create table public.operations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  name text not null,
  slug text not null,
  description text,
  operation_type text,
  status text not null default 'active',
  external_id text,
  source_system text not null default 'rf_performance',
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint operations_organization_id_fkey
    foreign key (organization_id)
    references public.organizations(id)
    on delete restrict,
  constraint operations_org_slug_key
    unique (organization_id, slug),
  constraint operations_id_org_key
    unique (id, organization_id),
  constraint operations_status_check
    check (status in ('active', 'inactive', 'archived')),
  constraint operations_slug_format_check
    check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  constraint operations_source_system_check
    check (source_system in (
      'rf_performance', 'epsa_core', 'mci_consorcio',
      'manual_import', 'spreadsheet_import', 'api'
    )),
  constraint operations_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);

create table public.sales_locations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  operation_id uuid not null,
  name text not null,
  slug text not null,
  location_type text not null default 'shopping_kiosk',
  shopping_name text,
  address_line text,
  city text,
  state_code text,
  timezone text not null default 'America/Sao_Paulo',
  status text not null default 'active',
  external_id text,
  source_system text not null default 'rf_performance',
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint sales_locations_organization_id_fkey
    foreign key (organization_id)
    references public.organizations(id)
    on delete restrict,
  constraint sales_locations_operation_org_fkey
    foreign key (operation_id, organization_id)
    references public.operations(id, organization_id)
    on delete restrict,
  constraint sales_locations_org_slug_key
    unique (organization_id, slug),
  constraint sales_locations_id_org_operation_key
    unique (id, organization_id, operation_id),
  constraint sales_locations_status_check
    check (status in ('active', 'inactive', 'archived')),
  constraint sales_locations_slug_format_check
    check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  constraint sales_locations_state_code_check
    check (state_code is null or state_code ~ '^[A-Z]{2}$'),
  constraint sales_locations_source_system_check
    check (source_system in (
      'rf_performance', 'epsa_core', 'mci_consorcio',
      'manual_import', 'spreadsheet_import', 'api'
    )),
  constraint sales_locations_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);

create table public.teams (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  operation_id uuid not null,
  sales_location_id uuid,
  name text not null,
  description text,
  supervisor_member_id uuid,
  status text not null default 'active',
  external_id text,
  source_system text not null default 'rf_performance',
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint teams_organization_id_fkey
    foreign key (organization_id)
    references public.organizations(id)
    on delete restrict,
  constraint teams_operation_org_fkey
    foreign key (operation_id, organization_id)
    references public.operations(id, organization_id)
    on delete restrict,
  constraint teams_location_org_operation_fkey
    foreign key (sales_location_id, organization_id, operation_id)
    references public.sales_locations(id, organization_id, operation_id)
    on delete restrict,
  constraint teams_supervisor_org_fkey
    foreign key (supervisor_member_id, organization_id)
    references public.organization_members(id, organization_id)
    on delete restrict,
  constraint teams_id_org_key
    unique (id, organization_id),
  constraint teams_status_check
    check (status in ('active', 'inactive', 'archived')),
  constraint teams_source_system_check
    check (source_system in (
      'rf_performance', 'epsa_core', 'mci_consorcio',
      'manual_import', 'spreadsheet_import', 'api'
    )),
  constraint teams_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);

create table public.team_members (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  team_id uuid not null,
  organization_member_id uuid not null,
  membership_type text not null default 'member',
  start_at timestamptz,
  end_at timestamptz,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint team_members_organization_id_fkey
    foreign key (organization_id)
    references public.organizations(id)
    on delete restrict,
  constraint team_members_team_org_fkey
    foreign key (team_id, organization_id)
    references public.teams(id, organization_id)
    on delete restrict,
  constraint team_members_member_org_fkey
    foreign key (organization_member_id, organization_id)
    references public.organization_members(id, organization_id)
    on delete restrict,
  constraint team_members_status_check
    check (status in ('active', 'inactive', 'archived')),
  constraint team_members_dates_check
    check (end_at is null or start_at is null or end_at >= start_at),
  constraint team_members_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid,
  user_id uuid,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  old_values jsonb,
  new_values jsonb,
  created_at timestamptz not null default now(),
  constraint audit_logs_organization_id_fkey
    foreign key (organization_id)
    references public.organizations(id)
    on delete set null,
  constraint audit_logs_user_id_fkey
    foreign key (user_id)
    references public.profiles(id)
    on delete set null
);

-- --------------------------------------------------------------------------
-- Chaves de autoria (adicionadas depois de profiles existir)
-- --------------------------------------------------------------------------

alter table public.profiles
  add constraint profiles_created_by_fkey
    foreign key (created_by) references public.profiles(id) on delete set null,
  add constraint profiles_updated_by_fkey
    foreign key (updated_by) references public.profiles(id) on delete set null;

alter table public.organizations
  add constraint organizations_created_by_fkey
    foreign key (created_by) references public.profiles(id) on delete set null,
  add constraint organizations_updated_by_fkey
    foreign key (updated_by) references public.profiles(id) on delete set null;

alter table public.organization_members
  add constraint organization_members_created_by_fkey
    foreign key (created_by) references public.profiles(id) on delete set null,
  add constraint organization_members_updated_by_fkey
    foreign key (updated_by) references public.profiles(id) on delete set null;

alter table public.operations
  add constraint operations_created_by_fkey
    foreign key (created_by) references public.profiles(id) on delete set null,
  add constraint operations_updated_by_fkey
    foreign key (updated_by) references public.profiles(id) on delete set null;

alter table public.sales_locations
  add constraint sales_locations_created_by_fkey
    foreign key (created_by) references public.profiles(id) on delete set null,
  add constraint sales_locations_updated_by_fkey
    foreign key (updated_by) references public.profiles(id) on delete set null;

alter table public.teams
  add constraint teams_created_by_fkey
    foreign key (created_by) references public.profiles(id) on delete set null,
  add constraint teams_updated_by_fkey
    foreign key (updated_by) references public.profiles(id) on delete set null;

alter table public.team_members
  add constraint team_members_created_by_fkey
    foreign key (created_by) references public.profiles(id) on delete set null,
  add constraint team_members_updated_by_fkey
    foreign key (updated_by) references public.profiles(id) on delete set null;

-- --------------------------------------------------------------------------
-- Índices
-- --------------------------------------------------------------------------

create unique index organization_members_active_user_org_uidx
  on public.organization_members (organization_id, user_id)
  where status = 'active' and archived_at is null;

create unique index team_members_active_team_member_uidx
  on public.team_members (team_id, organization_member_id)
  where status = 'active' and archived_at is null;

create unique index organizations_source_external_uidx
  on public.organizations (source_system, external_id)
  where external_id is not null;

create unique index organization_members_source_external_uidx
  on public.organization_members (organization_id, source_system, external_id)
  where external_id is not null;

create unique index operations_source_external_uidx
  on public.operations (organization_id, source_system, external_id)
  where external_id is not null;

create unique index sales_locations_source_external_uidx
  on public.sales_locations (organization_id, source_system, external_id)
  where external_id is not null;

create unique index teams_source_external_uidx
  on public.teams (organization_id, source_system, external_id)
  where external_id is not null;

create index organization_members_user_id_idx
  on public.organization_members (user_id);
create index organization_members_org_status_idx
  on public.organization_members (organization_id, status);
create index operations_org_status_idx
  on public.operations (organization_id, status);
create index sales_locations_org_operation_status_idx
  on public.sales_locations (organization_id, operation_id, status);
create index teams_org_operation_status_idx
  on public.teams (organization_id, operation_id, status);
create index teams_supervisor_member_id_idx
  on public.teams (supervisor_member_id);
create index team_members_org_team_status_idx
  on public.team_members (organization_id, team_id, status);
create index team_members_org_member_idx
  on public.team_members (organization_id, organization_member_id);
create index audit_logs_org_created_at_idx
  on public.audit_logs (organization_id, created_at desc);
create index audit_logs_entity_idx
  on public.audit_logs (entity_type, entity_id, created_at desc);
create index audit_logs_user_created_at_idx
  on public.audit_logs (user_id, created_at desc);

-- --------------------------------------------------------------------------
-- Validações sensíveis
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
      message = 'O supervisor deve ser um membro supervisor ativo da mesma organização.';
  end if;

  return new;
end;
$$;

create or replace function private.guard_profile_sensitive_fields()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_actor_is_admin boolean := false;
begin
  if v_actor is null then
    return new;
  end if;

  select exists (
    select 1
    from public.profiles p
    where p.id = v_actor
      and p.system_role = 'platform_admin'
      and p.status = 'active'
      and p.archived_at is null
  ) into v_actor_is_admin;

  if not v_actor_is_admin then
    if new.system_role is distinct from old.system_role
       or new.status is distinct from old.status
       or new.archived_at is distinct from old.archived_at then
      raise exception using
        errcode = '42501',
        message = 'Campos administrativos do perfil não podem ser alterados por este usuário.';
    end if;
  end if;

  return new;
end;
$$;

create or replace function private.guard_membership_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_actor_is_admin boolean := false;
begin
  if new.organization_id is distinct from old.organization_id
     or new.user_id is distinct from old.user_id then
    raise exception using
      errcode = '42501',
      message = 'Organização e usuário do vínculo são imutáveis.';
  end if;

  if v_actor is null then
    return new;
  end if;

  select exists (
    select 1
    from public.profiles p
    where p.id = v_actor
      and p.system_role = 'platform_admin'
      and p.status = 'active'
      and p.archived_at is null
  ) into v_actor_is_admin;

  if not v_actor_is_admin and new.role is distinct from old.role then
    raise exception using
      errcode = '42501',
      message = 'A alteração de papel exige administrador da plataforma.';
  end if;

  return new;
end;
$$;

create or replace function private.guard_organization_scope()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.organization_id is distinct from old.organization_id then
    raise exception using
      errcode = '42501',
      message = 'A organização do registro é imutável.';
  end if;

  return new;
end;
$$;

-- --------------------------------------------------------------------------
-- Sincronização auth.users -> public.profiles
-- --------------------------------------------------------------------------

create or replace function private.sync_auth_user_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_full_name text;
begin
  v_full_name := coalesce(
    nullif(new.raw_user_meta_data ->> 'full_name', ''),
    nullif(new.raw_user_meta_data ->> 'name', ''),
    split_part(coalesce(new.email, ''), '@', 1),
    ''
  );

  insert into public.profiles (
    id,
    full_name,
    preferred_name,
    email,
    status,
    created_at,
    updated_at,
    metadata
  ) values (
    new.id,
    v_full_name,
    nullif(new.raw_user_meta_data ->> 'preferred_name', ''),
    new.email,
    'active',
    coalesce(new.created_at, now()),
    now(),
    '{}'::jsonb
  )
  on conflict (id) do update
  set
    email = excluded.email,
    full_name = case
      when public.profiles.full_name = '' then excluded.full_name
      else public.profiles.full_name
    end,
    preferred_name = coalesce(
      public.profiles.preferred_name,
      excluded.preferred_name
    ),
    updated_at = now();

  return new;
end;
$$;

-- --------------------------------------------------------------------------
-- Auditoria automática
-- --------------------------------------------------------------------------

create or replace function private.write_audit_log()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old jsonb;
  v_new jsonb;
  v_row jsonb;
  v_org_id uuid;
  v_entity_id uuid;
  v_action text;
  v_user_id uuid;
begin
  v_old := case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) end;
  v_new := case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) end;
  v_row := coalesce(v_new, v_old);

  if tg_table_name = 'organizations' then
    v_org_id := nullif(v_row ->> 'id', '')::uuid;
  else
    v_org_id := nullif(v_row ->> 'organization_id', '')::uuid;
  end if;

  v_entity_id := nullif(v_row ->> 'id', '')::uuid;

  if tg_op = 'INSERT' then
    v_action := 'create';
  elsif tg_op = 'DELETE' then
    v_action := 'delete';
  elsif (v_old ->> 'status') is distinct from (v_new ->> 'status') then
    v_action := case v_new ->> 'status'
      when 'active' then 'activate'
      when 'inactive' then 'deactivate'
      when 'archived' then 'archive'
      else 'update'
    end;
  else
    v_action := 'update';
  end if;

  select case
    when exists (select 1 from public.profiles p where p.id = auth.uid())
      then auth.uid()
    else null
  end into v_user_id;

  insert into public.audit_logs (
    organization_id,
    user_id,
    action,
    entity_type,
    entity_id,
    old_values,
    new_values,
    created_at
  ) values (
    v_org_id,
    v_user_id,
    v_action,
    tg_table_name,
    v_entity_id,
    v_old,
    v_new,
    now()
  );

  return null;
end;
$$;

-- --------------------------------------------------------------------------
-- Triggers
-- --------------------------------------------------------------------------

create trigger profiles_set_row_metadata
before insert or update on public.profiles
for each row execute function private.set_row_metadata();

create trigger organizations_set_row_metadata
before insert or update on public.organizations
for each row execute function private.set_row_metadata();

create trigger organization_members_set_row_metadata
before insert or update on public.organization_members
for each row execute function private.set_row_metadata();

create trigger operations_set_row_metadata
before insert or update on public.operations
for each row execute function private.set_row_metadata();

create trigger sales_locations_set_row_metadata
before insert or update on public.sales_locations
for each row execute function private.set_row_metadata();

create trigger teams_set_row_metadata
before insert or update on public.teams
for each row execute function private.set_row_metadata();

create trigger team_members_set_row_metadata
before insert or update on public.team_members
for each row execute function private.set_row_metadata();

create trigger teams_validate_supervisor
before insert or update of supervisor_member_id, organization_id on public.teams
for each row execute function private.validate_team_supervisor();

create trigger profiles_guard_sensitive_fields
before update on public.profiles
for each row execute function private.guard_profile_sensitive_fields();

create trigger organization_members_guard_update
before update on public.organization_members
for each row execute function private.guard_membership_update();

create trigger operations_guard_organization_scope
before update on public.operations
for each row execute function private.guard_organization_scope();

create trigger sales_locations_guard_organization_scope
before update on public.sales_locations
for each row execute function private.guard_organization_scope();

create trigger teams_guard_organization_scope
before update on public.teams
for each row execute function private.guard_organization_scope();

create trigger team_members_guard_organization_scope
before update on public.team_members
for each row execute function private.guard_organization_scope();

create trigger auth_users_sync_profile_on_insert
  after insert
  on auth.users
  for each row execute function private.sync_auth_user_profile();

create trigger auth_users_sync_profile_on_update
  after update of email, raw_user_meta_data
  on auth.users
  for each row execute function private.sync_auth_user_profile();

-- Backfill seguro para usuários Auth que eventualmente já existam.
insert into public.profiles (
  id,
  full_name,
  preferred_name,
  email,
  status,
  created_at,
  updated_at,
  metadata
)
select
  u.id,
  coalesce(
    nullif(u.raw_user_meta_data ->> 'full_name', ''),
    nullif(u.raw_user_meta_data ->> 'name', ''),
    split_part(coalesce(u.email, ''), '@', 1),
    ''
  ),
  nullif(u.raw_user_meta_data ->> 'preferred_name', ''),
  u.email,
  'active',
  coalesce(u.created_at, now()),
  now(),
  '{}'::jsonb
from auth.users u
on conflict (id) do nothing;

create trigger profiles_audit
  after insert or update or delete on public.profiles
  for each row execute function private.write_audit_log();
create trigger organizations_audit
  after insert or update or delete on public.organizations
  for each row execute function private.write_audit_log();
create trigger organization_members_audit
  after insert or update or delete on public.organization_members
  for each row execute function private.write_audit_log();
create trigger operations_audit
  after insert or update or delete on public.operations
  for each row execute function private.write_audit_log();
create trigger sales_locations_audit
  after insert or update or delete on public.sales_locations
  for each row execute function private.write_audit_log();
create trigger teams_audit
  after insert or update or delete on public.teams
  for each row execute function private.write_audit_log();
create trigger team_members_audit
  after insert or update or delete on public.team_members
  for each row execute function private.write_audit_log();

-- --------------------------------------------------------------------------
-- RLS fechada por padrão
-- --------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.organizations enable row level security;
alter table public.organization_members enable row level security;
alter table public.operations enable row level security;
alter table public.sales_locations enable row level security;
alter table public.teams enable row level security;
alter table public.team_members enable row level security;
alter table public.audit_logs enable row level security;

revoke all on table public.profiles from anon, authenticated;
revoke all on table public.organizations from anon, authenticated;
revoke all on table public.organization_members from anon, authenticated;
revoke all on table public.operations from anon, authenticated;
revoke all on table public.sales_locations from anon, authenticated;
revoke all on table public.teams from anon, authenticated;
revoke all on table public.team_members from anon, authenticated;
revoke all on table public.audit_logs from anon, authenticated;

revoke all on all functions in schema private from public;

commit;
