-- ============================================================================
-- RF Performance Comercial
-- Validação somente leitura — joined_at de usuário convidado
--
-- Substitua TEST_USER_EMAIL pelo e-mail de teste.
-- ============================================================================

with target_user as (
  select
    u.id,
    lower(u.email) as email,
    u.email_confirmed_at,
    u.last_sign_in_at
  from auth.users u
  where lower(u.email) = lower('empilhaplus@gmail.com')
  limit 1
),
target_membership as (
  select
    om.id,
    om.role,
    om.status,
    om.joined_at,
    om.archived_at,
    om.updated_at
  from public.organization_members om
  join target_user u
    on u.id = om.user_id
  join public.organizations o
    on o.id = om.organization_id
   and o.slug = 'rf-consorcios'
  order by om.created_at desc
  limit 1
),
trigger_check as (
  select count(*)::integer as trigger_count
  from pg_catalog.pg_trigger t
  join pg_catalog.pg_class c
    on c.oid = t.tgrelid
  join pg_catalog.pg_namespace n
    on n.oid = c.relnamespace
  where not t.tgisinternal
    and n.nspname = 'auth'
    and c.relname = 'users'
    and t.tgname = 'auth_users_sync_organization_member_joined_at'
),
function_check as (
  select count(*)::integer as function_count
  from pg_catalog.pg_proc p
  join pg_catalog.pg_namespace n
    on n.oid = p.pronamespace
  where n.nspname = 'private'
    and p.proname = 'sync_organization_member_joined_at'
)
select
  case
    when (select count(*) from target_user) <> 1
      then 'FAIL_AUTH_USER'
    when (select count(*) from target_membership) <> 1
      then 'FAIL_MEMBERSHIP'
    when (
      select email_confirmed_at
      from target_user
    ) is null
      then 'FAIL_EMAIL_NOT_CONFIRMED'
    when (
      select last_sign_in_at
      from target_user
    ) is null
      then 'FAIL_USER_NEVER_SIGNED_IN'
    when (
      select joined_at
      from target_membership
    ) is null
      then 'FAIL_JOINED_AT_NULL'
    when (
      select status
      from target_membership
    ) <> 'active'
      then 'FAIL_MEMBERSHIP_INACTIVE'
    when (
      select archived_at
      from target_membership
    ) is not null
      then 'FAIL_MEMBERSHIP_ARCHIVED'
    when (
      select trigger_count
      from trigger_check
    ) <> 1
      then 'FAIL_TRIGGER'
    when (
      select function_count
      from function_check
    ) <> 1
      then 'FAIL_FUNCTION'
    else 'PASS'
  end as validation_result,

  (select email from target_user) as auth_email,
  (select email_confirmed_at from target_user) as email_confirmed_at,
  (select last_sign_in_at from target_user) as last_sign_in_at,
  (select id from target_membership) as membership_id,
  (select role from target_membership) as membership_role,
  (select status from target_membership) as membership_status,
  (select joined_at from target_membership) as membership_joined_at,
  (select updated_at from target_membership) as membership_updated_at,
  (select trigger_count from trigger_check) as trigger_count,
  (select function_count from function_check) as function_count;
