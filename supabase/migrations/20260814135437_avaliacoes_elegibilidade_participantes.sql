-- Avaliações: somente perfis participantes podem receber/acessar provas.
-- Platform Admin permanece exclusivamente como gestor.

create or replace function private.assessment_test_access_allowed(
  p_organization_id uuid,
  p_organization_member_id uuid,
  p_test_id uuid,
  p_test_version_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $function$
  select exists (
    select 1
    from public.organization_members om
    join public.profiles p
      on p.id = om.user_id
     and p.status = 'active'
     and p.archived_at is null
    join public.assessment_tests t
      on t.id = p_test_id
     and t.organization_id = p_organization_id
     and t.archived_at is null
    join public.assessment_test_versions tv
      on tv.id = p_test_version_id
     and tv.organization_id = p_organization_id
     and tv.test_id = p_test_id
     and tv.archived_at is null
    join private.assessment_test_access_grants access_grant
      on access_grant.organization_id = p_organization_id
     and access_grant.test_id = p_test_id
     and access_grant.test_version_id = p_test_version_id
     and access_grant.status = 'active'
     and access_grant.archived_at is null
     and (
       access_grant.valid_from is null
       or access_grant.valid_from <= now()
     )
     and (
       access_grant.valid_until is null
       or access_grant.valid_until > now()
     )
     and (
       (
         access_grant.access_scope = 'member'
         and access_grant.organization_member_id = p_organization_member_id
       )
       or
       (
         access_grant.access_scope = 'organization'
         and access_grant.organization_member_id is null
       )
     )
    where om.id = p_organization_member_id
      and om.organization_id = p_organization_id
      and om.status = 'active'
      and om.archived_at is null
      and om.role in ('salesperson', 'supervisor', 'director')
  );
$function$;