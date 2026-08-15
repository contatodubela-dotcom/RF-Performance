-- Liberação administrativa de avaliações.
-- Somente Platform Admin administra grants.
-- Participantes elegíveis: salesperson, supervisor e director.

create or replace function public.get_assessment_access_admin_state(
  p_organization_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $function$
declare
  v_tests jsonb;
  v_members jsonb;
  v_grants jsonb;
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if not private.is_platform_admin() then
    raise exception 'ASSESSMENT_ACCESS_MANAGEMENT_FORBIDDEN'
      using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.organizations o
    where o.id = p_organization_id
      and o.status = 'active'
      and o.archived_at is null
  ) then
    raise exception 'ORGANIZATION_NOT_AVAILABLE'
      using errcode = '42501';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'test_id', x.test_id,
        'test_version_id', x.test_version_id,
        'sequence_no', x.sequence_no,
        'title', x.title,
        'version_code', x.version_code
      )
      order by x.sequence_no
    ),
    '[]'::jsonb
  )
  into v_tests
  from (
    select
      t.id as test_id,
      tv.id as test_version_id,
      t.sequence_no,
      t.title,
      tv.version_code
    from public.assessment_tests t
    join public.assessment_test_versions tv
      on tv.test_id = t.id
     and tv.organization_id = t.organization_id
     and tv.status = 'published'
     and tv.archived_at is null
     and (tv.valid_from is null or tv.valid_from <= now())
     and (tv.valid_until is null or tv.valid_until >= now())
    where t.organization_id = p_organization_id
      and t.status = 'active'
      and t.archived_at is null
  ) x;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'organization_member_id', x.organization_member_id,
        'user_id', x.user_id,
        'name', x.full_name,
        'email', x.email,
        'role', x.role
      )
      order by x.full_name, x.email
    ),
    '[]'::jsonb
  )
  into v_members
  from (
    select
      om.id as organization_member_id,
      om.user_id,
      p.full_name,
      p.email,
      om.role
    from public.organization_members om
    join public.profiles p
      on p.id = om.user_id
     and p.status = 'active'
     and p.archived_at is null
    where om.organization_id = p_organization_id
      and om.status = 'active'
      and om.archived_at is null
      and om.role in ('salesperson', 'supervisor', 'director')
  ) x;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'grant_id', g.id,
        'test_id', g.test_id,
        'test_version_id', g.test_version_id,
        'access_scope', g.access_scope,
        'organization_member_id', g.organization_member_id,
        'valid_from', g.valid_from,
        'valid_until', g.valid_until,
        'reason', g.reason
      )
      order by g.created_at
    ),
    '[]'::jsonb
  )
  into v_grants
  from private.assessment_test_access_grants g
  where g.organization_id = p_organization_id
    and g.status = 'active'
    and g.archived_at is null
    and (g.valid_from is null or g.valid_from <= now())
    and (g.valid_until is null or g.valid_until > now());

  return jsonb_build_object(
    'organization_id', p_organization_id,
    'tests', v_tests,
    'members', v_members,
    'active_grants', v_grants
  );
end;
$function$;


create or replace function public.configure_assessment_access(
  p_organization_id uuid,
  p_test_id uuid,
  p_access_scope text,
  p_organization_member_id uuid,
  p_enabled boolean,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $function$
declare
  v_user_id uuid := auth.uid();
  v_version_id uuid;
  v_grant_id uuid;
  v_affected integer := 0;
  v_reason text;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if not private.is_platform_admin() then
    raise exception 'ASSESSMENT_ACCESS_MANAGEMENT_FORBIDDEN'
      using errcode = '42501';
  end if;

  if p_access_scope not in ('member', 'organization') then
    raise exception 'ASSESSMENT_ACCESS_SCOPE_INVALID';
  end if;

  if p_access_scope = 'member'
     and p_organization_member_id is null then
    raise exception 'ASSESSMENT_MEMBER_REQUIRED';
  end if;

  if p_access_scope = 'organization'
     and p_organization_member_id is not null then
    raise exception 'ASSESSMENT_MEMBER_NOT_ALLOWED_FOR_ORGANIZATION_SCOPE';
  end if;

  select tv.id
  into v_version_id
  from public.assessment_tests t
  join public.assessment_test_versions tv
    on tv.test_id = t.id
   and tv.organization_id = t.organization_id
   and tv.status = 'published'
   and tv.archived_at is null
   and (tv.valid_from is null or tv.valid_from <= now())
   and (tv.valid_until is null or tv.valid_until >= now())
  where t.id = p_test_id
    and t.organization_id = p_organization_id
    and t.status = 'active'
    and t.archived_at is null
  limit 1;

  if v_version_id is null then
    raise exception 'ASSESSMENT_NOT_PUBLISHED';
  end if;

  if p_access_scope = 'member' and not exists (
    select 1
    from public.organization_members om
    join public.profiles p
      on p.id = om.user_id
     and p.status = 'active'
     and p.archived_at is null
    where om.id = p_organization_member_id
      and om.organization_id = p_organization_id
      and om.status = 'active'
      and om.archived_at is null
      and om.role in ('salesperson', 'supervisor', 'director')
  ) then
    raise exception 'ASSESSMENT_PARTICIPANT_NOT_ELIGIBLE'
      using errcode = '42501';
  end if;

  v_reason := coalesce(
    nullif(trim(p_reason), ''),
    'Liberação administrativa de avaliação.'
  );

  if p_enabled then
    select g.id
    into v_grant_id
    from private.assessment_test_access_grants g
    where g.organization_id = p_organization_id
      and g.test_version_id = v_version_id
      and g.access_scope = p_access_scope
      and (
        (
          p_access_scope = 'organization'
          and g.organization_member_id is null
        )
        or
        (
          p_access_scope = 'member'
          and g.organization_member_id = p_organization_member_id
        )
      )
      and g.status = 'active'
      and g.archived_at is null
    limit 1;

    if v_grant_id is null then
      insert into private.assessment_test_access_grants (
        organization_id,
        test_id,
        test_version_id,
        access_scope,
        organization_member_id,
        status,
        valid_from,
        valid_until,
        reason,
        created_by,
        updated_by,
        metadata
      )
      values (
        p_organization_id,
        p_test_id,
        v_version_id,
        p_access_scope,
        p_organization_member_id,
        'active',
        now(),
        null,
        v_reason,
        v_user_id,
        v_user_id,
        jsonb_build_object(
          'source', 'assessment_admin_ui',
          'managed_by', 'platform_admin'
        )
      )
      returning id into v_grant_id;

      v_affected := 1;
    end if;

    return jsonb_build_object(
      'enabled', true,
      'grant_id', v_grant_id,
      'affected', v_affected
    );
  end if;

  update private.assessment_test_access_grants g
  set
    status = 'revoked',
    updated_at = now(),
    updated_by = v_user_id,
    metadata = g.metadata || jsonb_build_object(
      'revoked_from', 'assessment_admin_ui',
      'revoked_at', now()
    )
  where g.organization_id = p_organization_id
    and g.test_version_id = v_version_id
    and g.access_scope = p_access_scope
    and (
      (
        p_access_scope = 'organization'
        and g.organization_member_id is null
      )
      or
      (
        p_access_scope = 'member'
        and g.organization_member_id = p_organization_member_id
      )
    )
    and g.status = 'active'
    and g.archived_at is null;

  get diagnostics v_affected = row_count;

  return jsonb_build_object(
    'enabled', false,
    'affected', v_affected
  );
end;
$function$;


revoke all on function
  public.get_assessment_access_admin_state(uuid)
from public, anon, authenticated;

grant execute on function
  public.get_assessment_access_admin_state(uuid)
to authenticated;

revoke all on function
  public.configure_assessment_access(uuid, uuid, text, uuid, boolean, text)
from public, anon, authenticated;

grant execute on function
  public.configure_assessment_access(uuid, uuid, text, uuid, boolean, text)
to authenticated;