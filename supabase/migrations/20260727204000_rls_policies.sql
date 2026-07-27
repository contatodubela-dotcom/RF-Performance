-- ============================================================================
-- RF Performance Comercial
-- Migration 002 — Funções de autorização, grants e policies RLS
-- Data: 2026-07-27
-- ============================================================================

begin;

-- --------------------------------------------------------------------------
-- Funções auxiliares de autorização
-- --------------------------------------------------------------------------

create or replace function private.is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.system_role = 'platform_admin'
      and p.status = 'active'
      and p.archived_at is null
  );
$$;

create or replace function private.has_active_membership(p_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.organization_members om
    where om.user_id = auth.uid()
      and om.organization_id = p_organization_id
      and om.status = 'active'
      and om.archived_at is null
  );
$$;

create or replace function private.has_org_role(
  p_organization_id uuid,
  p_allowed_roles text[]
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.organization_members om
    where om.user_id = auth.uid()
      and om.organization_id = p_organization_id
      and om.role = any(p_allowed_roles)
      and om.status = 'active'
      and om.archived_at is null
  );
$$;

create or replace function private.current_member_id(p_organization_id uuid)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select om.id
  from public.organization_members om
  where om.user_id = auth.uid()
    and om.organization_id = p_organization_id
    and om.status = 'active'
    and om.archived_at is null
  order by om.created_at
  limit 1;
$$;

create or replace function private.managed_team_ids()
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select t.id
  from public.teams t
  join public.organization_members om
    on om.id = t.supervisor_member_id
   and om.organization_id = t.organization_id
  where om.user_id = auth.uid()
    and om.role = 'supervisor'
    and om.status = 'active'
    and om.archived_at is null
    and t.status = 'active'
    and t.archived_at is null;
$$;

create or replace function private.managed_location_ids()
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select distinct t.sales_location_id
  from public.teams t
  join public.organization_members om
    on om.id = t.supervisor_member_id
   and om.organization_id = t.organization_id
  where om.user_id = auth.uid()
    and om.role = 'supervisor'
    and om.status = 'active'
    and om.archived_at is null
    and t.status = 'active'
    and t.archived_at is null
    and t.sales_location_id is not null;
$$;

create or replace function private.current_user_team_ids()
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select tm.team_id
  from public.team_members tm
  join public.organization_members om
    on om.id = tm.organization_member_id
   and om.organization_id = tm.organization_id
  where om.user_id = auth.uid()
    and om.status = 'active'
    and om.archived_at is null
    and tm.status = 'active'
    and tm.archived_at is null;
$$;

create or replace function private.can_view_profile(p_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    private.is_platform_admin()
    or p_profile_id = auth.uid()
    or exists (
      select 1
      from public.organization_members target_member
      join public.organization_members actor_member
        on actor_member.organization_id = target_member.organization_id
      where target_member.user_id = p_profile_id
        and target_member.status = 'active'
        and target_member.archived_at is null
        and actor_member.user_id = auth.uid()
        and actor_member.role = 'director'
        and actor_member.status = 'active'
        and actor_member.archived_at is null
    )
    or exists (
      select 1
      from public.organization_members target_member
      join public.team_members tm
        on tm.organization_member_id = target_member.id
       and tm.organization_id = target_member.organization_id
      where target_member.user_id = p_profile_id
        and target_member.status = 'active'
        and target_member.archived_at is null
        and tm.status = 'active'
        and tm.archived_at is null
        and tm.team_id in (select private.managed_team_ids())
    );
$$;

create or replace function private.can_view_team(p_team_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    private.is_platform_admin()
    or p_team_id in (select private.managed_team_ids())
    or p_team_id in (select private.current_user_team_ids())
    or exists (
      select 1
      from public.teams t
      where t.id = p_team_id
        and private.has_org_role(t.organization_id, array['director'])
    );
$$;

-- --------------------------------------------------------------------------
-- Privilégios das funções auxiliares
-- --------------------------------------------------------------------------

revoke all on all functions in schema private from public;
grant usage on schema private to authenticated;

grant execute on function private.is_platform_admin() to authenticated;
grant execute on function private.has_active_membership(uuid) to authenticated;
grant execute on function private.has_org_role(uuid, text[]) to authenticated;
grant execute on function private.current_member_id(uuid) to authenticated;
grant execute on function private.managed_team_ids() to authenticated;
grant execute on function private.managed_location_ids() to authenticated;
grant execute on function private.current_user_team_ids() to authenticated;
grant execute on function private.can_view_profile(uuid) to authenticated;
grant execute on function private.can_view_team(uuid) to authenticated;

-- --------------------------------------------------------------------------
-- Grants das tabelas; RLS continua sendo a barreira efetiva
-- --------------------------------------------------------------------------

grant select, update on table public.profiles to authenticated;
grant select, insert, update on table public.organizations to authenticated;
grant select, update on table public.organization_members to authenticated;
grant select, insert, update on table public.operations to authenticated;
grant select, insert, update on table public.sales_locations to authenticated;
grant select, insert, update on table public.teams to authenticated;
grant select, insert, update on table public.team_members to authenticated;
grant select on table public.audit_logs to authenticated;

-- --------------------------------------------------------------------------
-- Policies: profiles
-- --------------------------------------------------------------------------

create policy profiles_select_authorized
on public.profiles
for select
to authenticated
using (private.can_view_profile(id));

create policy profiles_update_self
on public.profiles
for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

create policy profiles_update_platform_admin
on public.profiles
for update
to authenticated
using (private.is_platform_admin())
with check (private.is_platform_admin());

-- --------------------------------------------------------------------------
-- Policies: organizations
-- --------------------------------------------------------------------------

create policy organizations_select_authorized
on public.organizations
for select
to authenticated
using (
  private.is_platform_admin()
  or private.has_active_membership(id)
);

create policy organizations_insert_platform_admin
on public.organizations
for insert
to authenticated
with check (private.is_platform_admin());

create policy organizations_update_platform_admin
on public.organizations
for update
to authenticated
using (private.is_platform_admin())
with check (private.is_platform_admin());

create policy organizations_update_director
on public.organizations
for update
to authenticated
using (private.has_org_role(id, array['director']))
with check (private.has_org_role(id, array['director']));

-- --------------------------------------------------------------------------
-- Policies: organization_members
-- --------------------------------------------------------------------------

create policy organization_members_select_authorized
on public.organization_members
for select
to authenticated
using (
  private.is_platform_admin()
  or user_id = auth.uid()
  or private.has_org_role(organization_id, array['director'])
  or exists (
    select 1
    from public.team_members tm
    where tm.organization_member_id = organization_members.id
      and tm.organization_id = organization_members.organization_id
      and tm.status = 'active'
      and tm.archived_at is null
      and tm.team_id in (select private.managed_team_ids())
  )
);

create policy organization_members_update_platform_admin
on public.organization_members
for update
to authenticated
using (private.is_platform_admin())
with check (private.is_platform_admin());

create policy organization_members_update_director
on public.organization_members
for update
to authenticated
using (private.has_org_role(organization_id, array['director']))
with check (private.has_org_role(organization_id, array['director']));

-- Inserts de vínculos serão feitos por Edge Function segura usando service role.

-- --------------------------------------------------------------------------
-- Policies: operations
-- --------------------------------------------------------------------------

create policy operations_select_authorized
on public.operations
for select
to authenticated
using (
  private.is_platform_admin()
  or private.has_org_role(organization_id, array['director'])
  or exists (
    select 1
    from public.teams t
    where t.operation_id = operations.id
      and private.can_view_team(t.id)
  )
);

create policy operations_insert_management
on public.operations
for insert
to authenticated
with check (
  private.is_platform_admin()
  or private.has_org_role(organization_id, array['director'])
);

create policy operations_update_management
on public.operations
for update
to authenticated
using (
  private.is_platform_admin()
  or private.has_org_role(organization_id, array['director'])
)
with check (
  private.is_platform_admin()
  or private.has_org_role(organization_id, array['director'])
);

-- --------------------------------------------------------------------------
-- Policies: sales_locations
-- --------------------------------------------------------------------------

create policy sales_locations_select_authorized
on public.sales_locations
for select
to authenticated
using (
  private.is_platform_admin()
  or private.has_org_role(organization_id, array['director'])
  or id in (select private.managed_location_ids())
  or exists (
    select 1
    from public.teams t
    where t.sales_location_id = sales_locations.id
      and t.id in (select private.current_user_team_ids())
  )
);

create policy sales_locations_insert_management
on public.sales_locations
for insert
to authenticated
with check (
  private.is_platform_admin()
  or private.has_org_role(organization_id, array['director'])
);

create policy sales_locations_update_management
on public.sales_locations
for update
to authenticated
using (
  private.is_platform_admin()
  or private.has_org_role(organization_id, array['director'])
)
with check (
  private.is_platform_admin()
  or private.has_org_role(organization_id, array['director'])
);

-- --------------------------------------------------------------------------
-- Policies: teams
-- --------------------------------------------------------------------------

create policy teams_select_authorized
on public.teams
for select
to authenticated
using (private.can_view_team(id));

create policy teams_insert_management
on public.teams
for insert
to authenticated
with check (
  private.is_platform_admin()
  or private.has_org_role(organization_id, array['director'])
);

create policy teams_update_management
on public.teams
for update
to authenticated
using (
  private.is_platform_admin()
  or private.has_org_role(organization_id, array['director'])
)
with check (
  private.is_platform_admin()
  or private.has_org_role(organization_id, array['director'])
);

-- --------------------------------------------------------------------------
-- Policies: team_members
-- --------------------------------------------------------------------------

create policy team_members_select_authorized
on public.team_members
for select
to authenticated
using (
  private.is_platform_admin()
  or private.has_org_role(organization_id, array['director'])
  or team_id in (select private.managed_team_ids())
  or organization_member_id = private.current_member_id(organization_id)
);

create policy team_members_insert_management
on public.team_members
for insert
to authenticated
with check (
  private.is_platform_admin()
  or private.has_org_role(organization_id, array['director'])
);

create policy team_members_update_management
on public.team_members
for update
to authenticated
using (
  private.is_platform_admin()
  or private.has_org_role(organization_id, array['director'])
)
with check (
  private.is_platform_admin()
  or private.has_org_role(organization_id, array['director'])
);

-- --------------------------------------------------------------------------
-- Policies: audit_logs (somente leitura autorizada)
-- --------------------------------------------------------------------------

create policy audit_logs_select_authorized
on public.audit_logs
for select
to authenticated
using (
  private.is_platform_admin()
  or (
    organization_id is not null
    and private.has_org_role(organization_id, array['director'])
  )
);

commit;
