-- ============================================================================
-- RF Performance Comercial
-- Sincroniza organization_members.joined_at após confirmação/login no Auth
-- ============================================================================

create or replace function private.sync_organization_member_joined_at()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.email_confirmed_at is not null
     or new.last_sign_in_at is not null then

    update public.organization_members
    set joined_at = coalesce(
          joined_at,
          new.email_confirmed_at,
          new.last_sign_in_at,
          now()
        ),
        updated_at = now()
    where user_id = new.id
      and status = 'active'
      and archived_at is null
      and joined_at is null;
  end if;

  return new;
end;
$$;

revoke all
on function private.sync_organization_member_joined_at()
from public, anon, authenticated;

drop trigger if exists
  auth_users_sync_organization_member_joined_at
on auth.users;

create trigger auth_users_sync_organization_member_joined_at
after update of email_confirmed_at, last_sign_in_at
on auth.users
for each row
when (
  old.email_confirmed_at is distinct from new.email_confirmed_at
  or old.last_sign_in_at is distinct from new.last_sign_in_at
)
execute function private.sync_organization_member_joined_at();

-- Backfill seguro para usuários que já aceitaram convite ou fizeram login.
update public.organization_members om
set joined_at = coalesce(
      om.joined_at,
      u.email_confirmed_at,
      u.last_sign_in_at,
      now()
    ),
    updated_at = now()
from auth.users u
where u.id = om.user_id
  and om.status = 'active'
  and om.archived_at is null
  and om.joined_at is null
  and (
    u.email_confirmed_at is not null
    or u.last_sign_in_at is not null
  );
