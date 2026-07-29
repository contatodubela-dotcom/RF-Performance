-- ============================================================================
-- RF Performance Comercial
-- Validação somente leitura — usuário convidado
--
-- Antes de executar, ajuste expected_role na CTE validation_params.
--   TEST_USER_EMAIL
-- Valor atual para este teste: salesperson
-- Valores aceitos:
--   director | supervisor | salesperson
-- ============================================================================

with validation_params as (
  select 'salesperson'::text as expected_role
),
target_auth_user as (
  select
    u.id,
    lower(u.email) as email,
    u.email_confirmed_at,
    u.invited_at,
    u.last_sign_in_at
  from auth.users u
  where lower(u.email) = lower('empilhaplus@gmail.com')
  limit 1
),
target_profile as (
  select p.*
  from public.profiles p
  join target_auth_user u
    on u.id = p.id
),
rf_organization as (
  select o.id
  from public.organizations o
  where o.slug = 'rf-consorcios'
  limit 1
),
target_membership as (
  select om.*
  from public.organization_members om
  join target_auth_user u
    on u.id = om.user_id
  join rf_organization o
    on o.id = om.organization_id
  order by om.created_at desc
  limit 1
),
invite_audit as (
  select count(*)::integer as audit_count
  from public.audit_logs al
  join target_membership om
    on om.id = al.entity_id
  where al.entity_type = 'organization_members'
    and al.action in (
      'invite_sent',
      'membership_created',
      'membership_reactivated',
      'create',
      'activate'
    )
)
select
  case
    when (select count(*) from target_auth_user) <> 1
      then 'FAIL_AUTH_USER'
    when (select count(*) from target_profile) <> 1
      then 'FAIL_PROFILE'
    when (select count(*) from target_membership) <> 1
      then 'FAIL_MEMBERSHIP'
    when (
      select role
      from target_membership
    ) <> (select expected_role from validation_params)
      then 'FAIL_ROLE'
    when (
      select status
      from target_membership
    ) <> 'active'
      then 'FAIL_MEMBERSHIP_STATUS'
    when (
      select archived_at
      from target_membership
    ) is not null
      then 'FAIL_MEMBERSHIP_ARCHIVED'
    when (
      select status
      from target_profile
    ) <> 'active'
      then 'FAIL_PROFILE_STATUS'
    when (
      select system_role
      from target_profile
    ) is not null
      then 'FAIL_UNEXPECTED_SYSTEM_ROLE'
    when (
      select audit_count
      from invite_audit
    ) < 1
      then 'FAIL_AUDIT'
    else 'PASS'
  end as validation_result,

  (select id from target_auth_user) as auth_user_id,
  (select email from target_auth_user) as auth_email,
  (select email_confirmed_at from target_auth_user) as email_confirmed_at,
  (select invited_at from target_auth_user) as auth_invited_at,
  (select last_sign_in_at from target_auth_user) as last_sign_in_at,

  (select id from target_profile) as profile_id,
  (select full_name from target_profile) as full_name,
  (select system_role from target_profile) as system_role,
  (select status from target_profile) as profile_status,

  (select id from target_membership) as membership_id,
  (select role from target_membership) as membership_role,
  (select status from target_membership) as membership_status,
  (select invited_at from target_membership) as membership_invited_at,
  (select joined_at from target_membership) as membership_joined_at,
  (select archived_at from target_membership) as membership_archived_at,

  (select audit_count from invite_audit) as audit_count;
