-- RF Performance Comercial
-- Validação somente leitura do bootstrap do administrador inicial.
-- Substitua ADMIN_EMAIL_AQUI somente no SQL Editor antes de executar.

with params as (
  select lower('cleverson128@hotmail.com')::text as admin_email
),
admin_user as (
  select
    u.id,
    u.email,
    u.email_confirmed_at,
    u.created_at
  from params p
  left join auth.users u
    on lower(u.email) = p.admin_email
),
admin_profile as (
  select
    p.id,
    p.full_name,
    p.email,
    p.system_role,
    p.status,
    p.archived_at,
    p.created_at,
    p.updated_at
  from admin_user au
  left join public.profiles p
    on p.id = au.id
),
admin_audit as (
  select count(*)::integer as promotion_audit_count
  from public.audit_logs al
  join admin_user au
    on au.id = al.entity_id
  where al.entity_type = 'profiles'
    and al.action = 'update'
    and al.new_values ->> 'system_role' = 'platform_admin'
),
admin_memberships as (
  select count(*)::integer as organization_membership_count
  from public.organization_members om
  join admin_user au
    on au.id = om.user_id
  where om.status = 'active'
    and om.archived_at is null
),
foundation as (
  select
    (select count(*)::integer
       from public.organizations o
      where o.slug = 'rf-consorcios'
        and o.status = 'active'
        and o.archived_at is null) as rf_organization_count,
    (select count(*)::integer
       from public.operations op
      where op.slug = 'consorcio-automoveis'
        and op.status = 'active'
        and op.archived_at is null) as automotive_operation_count,
    (select count(*)::integer
       from public.sales_locations sl
       join public.organizations o
         on o.id = sl.organization_id
      where o.slug = 'rf-consorcios'
        and sl.status = 'active'
        and sl.archived_at is null) as active_location_count
)
select
  au.id as auth_user_id,
  au.email as auth_email,
  (au.email_confirmed_at is not null) as email_confirmed,
  ap.id as profile_id,
  (ap.id is not null and ap.id = au.id) as profile_matches_auth_user,
  ap.full_name,
  ap.system_role,
  ap.status,
  ap.archived_at,
  aa.promotion_audit_count,
  am.organization_membership_count,
  f.rf_organization_count,
  f.automotive_operation_count,
  f.active_location_count,
  case
    when au.id is null then 'FAIL_AUTH_USER_MISSING'
    when au.email_confirmed_at is null then 'FAIL_EMAIL_NOT_CONFIRMED'
    when ap.id is null then 'FAIL_PROFILE_MISSING'
    when ap.system_role <> 'platform_admin' then 'FAIL_NOT_PLATFORM_ADMIN'
    when ap.status <> 'active' or ap.archived_at is not null then 'FAIL_PROFILE_INACTIVE'
    when aa.promotion_audit_count < 1 then 'FAIL_PROMOTION_AUDIT_MISSING'
    when f.rf_organization_count <> 1 then 'FAIL_RF_ORGANIZATION'
    when f.automotive_operation_count <> 1 then 'FAIL_AUTOMOTIVE_OPERATION'
    when f.active_location_count <> 3 then 'FAIL_INITIAL_LOCATIONS'
    else 'PASS'
  end as validation_result
from admin_user au
cross join admin_profile ap
cross join admin_audit aa
cross join admin_memberships am
cross join foundation f;
