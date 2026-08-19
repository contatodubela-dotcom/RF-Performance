begin;

-- ============================================================================
-- Fase 1F — Consultas read-only de certificações
--
-- Objetivo:
--   Expor consultas separadas para:
--   1) certificações do próprio participante;
--   2) certificações visíveis ao escopo gerencial.
--
-- Regras:
--   - nenhuma emissão, ativação ou alteração de dados operacionais;
--   - Platform Admin permanece fora do contexto de participante;
--   - gestão:
--       Platform Admin -> director + supervisor + salesperson;
--       Director       -> supervisor + salesperson;
--       Supervisor     -> salesperson das equipes gerenciadas;
--   - histórico de certificações preservado, inclusive revogadas;
--   - funções públicas acessíveis somente a authenticated;
--   - helper de hierarquia permanece privado.
-- ============================================================================


-- ============================================================================
-- Preflight
-- ============================================================================

do $preflight$
declare
  v_missing text;
begin
  if to_regprocedure('private.is_platform_admin()') is null then
    raise exception
      'CERTIFICATION_QUERY_PREFLIGHT_FAILED: private.is_platform_admin() not found';
  end if;

  if to_regprocedure('private.managed_team_ids()') is null then
    raise exception
      'CERTIFICATION_QUERY_PREFLIGHT_FAILED: private.managed_team_ids() not found';
  end if;

  if to_regprocedure(
    'private.assessment_participant_eligible(uuid,uuid)'
  ) is null then
    raise exception
      'CERTIFICATION_QUERY_PREFLIGHT_FAILED: private.assessment_participant_eligible(uuid,uuid) not found';
  end if;

  if to_regclass('public.organizations') is null
     or to_regclass('public.profiles') is null
     or to_regclass('public.organization_members') is null
     or to_regclass('public.teams') is null
     or to_regclass('public.team_members') is null
     or to_regclass('public.sales_locations') is null
     or to_regclass('public.member_certifications') is null
     or to_regclass('public.certification_programs') is null
     or to_regclass('public.certification_program_versions') is null then
    raise exception
      'CERTIFICATION_QUERY_PREFLIGHT_FAILED: required table missing';
  end if;

  select string_agg(x.table_name || '.' || x.column_name, ', ' order by x.table_name, x.column_name)
  into v_missing
  from (
    values
      ('organizations', 'id'),
      ('organizations', 'status'),
      ('organizations', 'archived_at'),

      ('profiles', 'id'),
      ('profiles', 'full_name'),
      ('profiles', 'email'),
      ('profiles', 'system_role'),
      ('profiles', 'status'),
      ('profiles', 'archived_at'),

      ('organization_members', 'id'),
      ('organization_members', 'organization_id'),
      ('organization_members', 'user_id'),
      ('organization_members', 'role'),
      ('organization_members', 'status'),
      ('organization_members', 'created_at'),
      ('organization_members', 'archived_at'),

      ('teams', 'id'),
      ('teams', 'organization_id'),
      ('teams', 'name'),
      ('teams', 'sales_location_id'),
      ('teams', 'supervisor_member_id'),
      ('teams', 'status'),
      ('teams', 'archived_at'),

      ('team_members', 'organization_id'),
      ('team_members', 'team_id'),
      ('team_members', 'organization_member_id'),
      ('team_members', 'membership_type'),
      ('team_members', 'status'),
      ('team_members', 'archived_at'),

      ('sales_locations', 'id'),
      ('sales_locations', 'organization_id'),
      ('sales_locations', 'name'),
      ('sales_locations', 'status'),
      ('sales_locations', 'archived_at'),

      ('member_certifications', 'id'),
      ('member_certifications', 'organization_id'),
      ('member_certifications', 'organization_member_id'),
      ('member_certifications', 'certification_level_id'),
      ('member_certifications', 'certification_program_id'),
      ('member_certifications', 'certification_program_version_id'),
      ('member_certifications', 'certificate_number'),
      ('member_certifications', 'status'),
      ('member_certifications', 'issued_at'),
      ('member_certifications', 'valid_until'),
      ('member_certifications', 'revoked_at'),
      ('member_certifications', 'revocation_reason'),
      ('member_certifications', 'created_at'),
      ('member_certifications', 'archived_at'),

      ('certification_programs', 'id'),
      ('certification_programs', 'organization_id'),
      ('certification_programs', 'code'),
      ('certification_programs', 'name'),
      ('certification_programs', 'description'),
      ('certification_programs', 'category'),
      ('certification_programs', 'display_order'),
      ('certification_programs', 'status'),
      ('certification_programs', 'archived_at'),

      ('certification_program_versions', 'id'),
      ('certification_program_versions', 'organization_id'),
      ('certification_program_versions', 'certification_program_id'),
      ('certification_program_versions', 'version_code'),
      ('certification_program_versions', 'version_no'),
      ('certification_program_versions', 'name'),
      ('certification_program_versions', 'description'),
      ('certification_program_versions', 'status'),
      ('certification_program_versions', 'valid_from'),
      ('certification_program_versions', 'valid_until'),
      ('certification_program_versions', 'archived_at')
  ) as x(table_name, column_name)
  where not exists (
    select 1
    from information_schema.columns c
    where c.table_schema = 'public'
      and c.table_name = x.table_name
      and c.column_name = x.column_name
  );

  if v_missing is not null then
    raise exception
      'CERTIFICATION_QUERY_PREFLIGHT_FAILED: required column(s) missing: %',
      v_missing;
  end if;

  if to_regprocedure(
    'private.can_manage_organization_member(uuid,uuid)'
  ) is not null then
    raise exception
      'CERTIFICATION_QUERY_PREFLIGHT_FAILED: private.can_manage_organization_member already exists';
  end if;

  if to_regprocedure(
    'public.get_my_certifications(uuid)'
  ) is not null then
    raise exception
      'CERTIFICATION_QUERY_PREFLIGHT_FAILED: public.get_my_certifications already exists';
  end if;

  if to_regprocedure(
    'public.get_managed_certifications(uuid)'
  ) is not null then
    raise exception
      'CERTIFICATION_QUERY_PREFLIGHT_FAILED: public.get_managed_certifications already exists';
  end if;
end;
$preflight$;


-- ============================================================================
-- 1. Helper privado — escopo gerencial genérico
-- ============================================================================

create function private.can_manage_organization_member(
  p_organization_id uuid,
  p_organization_member_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $function$
  with target_member as (
    select
      om.id,
      om.role
    from public.organization_members om
    join public.profiles p
      on p.id = om.user_id
     and p.status = 'active'
     and p.archived_at is null
     and p.system_role is distinct from 'platform_admin'
    where om.id = p_organization_member_id
      and om.organization_id = p_organization_id
      and om.status = 'active'
      and om.archived_at is null
      and om.role in ('director', 'supervisor', 'salesperson')
      and exists (
        select 1
        from public.organizations o
        where o.id = p_organization_id
          and o.status = 'active'
          and o.archived_at is null
      )
  ),
  caller_member as (
    select
      om.id,
      om.role
    from public.organization_members om
    join public.profiles p
      on p.id = om.user_id
     and p.status = 'active'
     and p.archived_at is null
    where om.organization_id = p_organization_id
      and om.user_id = auth.uid()
      and om.status = 'active'
      and om.archived_at is null
    order by om.created_at, om.id
    limit 1
  )
  select exists (
    select 1
    from target_member target
    where
      (
        private.is_platform_admin()
        and target.role in ('director', 'supervisor', 'salesperson')
      )
      or exists (
        select 1
        from caller_member caller
        where caller.role = 'director'
          and target.role in ('supervisor', 'salesperson')
      )
      or exists (
        select 1
        from caller_member caller
        where caller.role = 'supervisor'
          and target.role = 'salesperson'
          and exists (
            select 1
            from public.team_members tm
            where tm.organization_id = p_organization_id
              and tm.organization_member_id = target.id
              and tm.membership_type = 'salesperson'
              and tm.status = 'active'
              and tm.archived_at is null
              and tm.team_id in (
                select private.managed_team_ids()
              )
          )
      )
  );
$function$;

comment on function private.can_manage_organization_member(
  uuid,
  uuid
) is
  'Retorna se o usuário autenticado pode gerenciar o membro-alvo na organização. '
  'Platform Admin vê diretor/supervisor/vendedor; Diretor vê supervisor/vendedor; '
  'Supervisor vê somente vendedores das equipes que gerencia.';


-- ============================================================================
-- 2. Consulta pessoal
-- ============================================================================

create function public.get_my_certifications(
  p_organization_id uuid
)
returns table (
  certification_id uuid,
  organization_member_id uuid,
  certification_level_id uuid,
  certification_program_id uuid,
  certification_program_version_id uuid,
  certificate_number text,
  certification_status text,
  issued_at timestamptz,
  valid_until timestamptz,
  revoked_at timestamptz,
  revocation_reason text,
  currently_valid boolean,
  program_code text,
  program_name text,
  program_description text,
  program_category text,
  program_display_order integer,
  program_status text,
  version_code text,
  version_no integer,
  version_name text,
  version_description text,
  version_status text,
  version_valid_from timestamptz,
  version_valid_until timestamptz
)
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $function$
declare
  v_user_id uuid := auth.uid();
  v_member_id uuid;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED'
      using errcode = '42501';
  end if;

  if p_organization_id is null then
    raise exception 'CERTIFICATION_ORGANIZATION_REQUIRED';
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

  if private.is_platform_admin() then
    raise exception 'CERTIFICATION_PARTICIPANT_NOT_ELIGIBLE'
      using errcode = '42501';
  end if;

  select om.id
  into v_member_id
  from public.organization_members om
  join public.profiles p
    on p.id = om.user_id
   and p.status = 'active'
   and p.archived_at is null
  where om.organization_id = p_organization_id
    and om.user_id = v_user_id
    and om.status = 'active'
    and om.archived_at is null
  order by om.created_at, om.id
  limit 1;

  if v_member_id is null then
    raise exception 'ACTIVE_MEMBERSHIP_REQUIRED'
      using errcode = '42501';
  end if;

  if not private.assessment_participant_eligible(
    p_organization_id,
    v_member_id
  ) then
    raise exception 'CERTIFICATION_PARTICIPANT_NOT_ELIGIBLE'
      using errcode = '42501';
  end if;

  return query
  select
    mc.id as certification_id,
    mc.organization_member_id,
    mc.certification_level_id,
    mc.certification_program_id,
    mc.certification_program_version_id,
    mc.certificate_number,
    mc.status as certification_status,
    mc.issued_at,
    mc.valid_until,
    mc.revoked_at,
    mc.revocation_reason,
    (
      mc.status = 'active'
      and mc.revoked_at is null
      and (mc.valid_until is null or mc.valid_until >= now())
    ) as currently_valid,
    cp.code as program_code,
    cp.name as program_name,
    cp.description as program_description,
    cp.category as program_category,
    cp.display_order as program_display_order,
    cp.status as program_status,
    cpv.version_code,
    cpv.version_no,
    cpv.name as version_name,
    cpv.description as version_description,
    cpv.status as version_status,
    cpv.valid_from as version_valid_from,
    cpv.valid_until as version_valid_until
  from public.member_certifications mc
  left join public.certification_programs cp
    on cp.id = mc.certification_program_id
   and cp.organization_id = mc.organization_id
  left join public.certification_program_versions cpv
    on cpv.id = mc.certification_program_version_id
   and cpv.organization_id = mc.organization_id
   and (
     mc.certification_program_id is null
     or cpv.certification_program_id = mc.certification_program_id
   )
  where mc.organization_id = p_organization_id
    and mc.organization_member_id = v_member_id
    and mc.archived_at is null
  order by mc.issued_at desc nulls last, mc.created_at desc, mc.id desc;
end;
$function$;

comment on function public.get_my_certifications(uuid) is
  'Lista o histórico de certificações do próprio participante autenticado. '
  'Platform Admin não participa deste contexto.';


-- ============================================================================
-- 3. Consulta gerencial
-- ============================================================================

create function public.get_managed_certifications(
  p_organization_id uuid
)
returns table (
  organization_member_id uuid,
  user_id uuid,
  member_name text,
  member_email text,
  member_role text,
  team_contexts jsonb,
  certification_id uuid,
  certification_level_id uuid,
  certification_program_id uuid,
  certification_program_version_id uuid,
  certificate_number text,
  certification_status text,
  issued_at timestamptz,
  valid_until timestamptz,
  revoked_at timestamptz,
  revocation_reason text,
  currently_valid boolean,
  program_code text,
  program_name text,
  program_description text,
  program_category text,
  program_display_order integer,
  program_status text,
  version_code text,
  version_no integer,
  version_name text,
  version_description text,
  version_status text,
  version_valid_from timestamptz,
  version_valid_until timestamptz
)
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $function$
declare
  v_user_id uuid := auth.uid();
  v_caller_member_id uuid;
  v_caller_role text;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED'
      using errcode = '42501';
  end if;

  if p_organization_id is null then
    raise exception 'CERTIFICATION_ORGANIZATION_REQUIRED';
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

  if private.is_platform_admin() then
    v_caller_role := 'platform_admin';
  else
    select om.id, om.role
    into v_caller_member_id, v_caller_role
    from public.organization_members om
    join public.profiles p
      on p.id = om.user_id
     and p.status = 'active'
     and p.archived_at is null
    where om.organization_id = p_organization_id
      and om.user_id = v_user_id
      and om.status = 'active'
      and om.archived_at is null
    order by om.created_at, om.id
    limit 1;

    if v_caller_member_id is null then
      raise exception 'ACTIVE_MEMBERSHIP_REQUIRED'
        using errcode = '42501';
    end if;
  end if;

  if v_caller_role not in ('platform_admin', 'director', 'supervisor') then
    raise exception 'CERTIFICATION_MANAGEMENT_FORBIDDEN'
      using errcode = '42501';
  end if;

  return query
  select
    om.id as organization_member_id,
    om.user_id,
    p.full_name as member_name,
    p.email as member_email,
    om.role as member_role,
    coalesce(team_scope.team_contexts, '[]'::jsonb) as team_contexts,
    mc.id as certification_id,
    mc.certification_level_id,
    mc.certification_program_id,
    mc.certification_program_version_id,
    mc.certificate_number,
    mc.status as certification_status,
    mc.issued_at,
    mc.valid_until,
    mc.revoked_at,
    mc.revocation_reason,
    (
      mc.status = 'active'
      and mc.revoked_at is null
      and (mc.valid_until is null or mc.valid_until >= now())
    ) as currently_valid,
    cp.code as program_code,
    cp.name as program_name,
    cp.description as program_description,
    cp.category as program_category,
    cp.display_order as program_display_order,
    cp.status as program_status,
    cpv.version_code,
    cpv.version_no,
    cpv.name as version_name,
    cpv.description as version_description,
    cpv.status as version_status,
    cpv.valid_from as version_valid_from,
    cpv.valid_until as version_valid_until
  from public.member_certifications mc
  join public.organization_members om
    on om.id = mc.organization_member_id
   and om.organization_id = mc.organization_id
  join public.profiles p
    on p.id = om.user_id
   and p.status = 'active'
   and p.archived_at is null
   and p.system_role is distinct from 'platform_admin'
  left join public.certification_programs cp
    on cp.id = mc.certification_program_id
   and cp.organization_id = mc.organization_id
  left join public.certification_program_versions cpv
    on cpv.id = mc.certification_program_version_id
   and cpv.organization_id = mc.organization_id
   and (
     mc.certification_program_id is null
     or cpv.certification_program_id = mc.certification_program_id
   )
  left join lateral (
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'team_id', scoped_team.team_id,
          'team_name', scoped_team.team_name,
          'sales_location_id', scoped_team.sales_location_id,
          'sales_location_name', scoped_team.sales_location_name
        )
        order by scoped_team.team_name, scoped_team.team_id
      ),
      '[]'::jsonb
    ) as team_contexts
    from (
      select distinct
        t.id as team_id,
        t.name as team_name,
        t.sales_location_id,
        sl.name as sales_location_name
      from public.teams t
      left join public.sales_locations sl
        on sl.id = t.sales_location_id
       and sl.organization_id = t.organization_id
       and sl.status = 'active'
       and sl.archived_at is null
      where om.role = 'supervisor'
        and t.organization_id = p_organization_id
        and t.supervisor_member_id = om.id
        and t.status = 'active'
        and t.archived_at is null

      union

      select distinct
        t.id as team_id,
        t.name as team_name,
        t.sales_location_id,
        sl.name as sales_location_name
      from public.team_members tm
      join public.teams t
        on t.id = tm.team_id
       and t.organization_id = tm.organization_id
       and t.status = 'active'
       and t.archived_at is null
      left join public.sales_locations sl
        on sl.id = t.sales_location_id
       and sl.organization_id = t.organization_id
       and sl.status = 'active'
       and sl.archived_at is null
      where om.role = 'salesperson'
        and tm.organization_id = p_organization_id
        and tm.organization_member_id = om.id
        and tm.membership_type = 'salesperson'
        and tm.status = 'active'
        and tm.archived_at is null
        and (
          v_caller_role <> 'supervisor'
          or tm.team_id in (
            select private.managed_team_ids()
          )
        )
    ) scoped_team
  ) team_scope on true
  where mc.organization_id = p_organization_id
    and mc.archived_at is null
    and private.can_manage_organization_member(
      p_organization_id,
      mc.organization_member_id
    )
  order by
    p.full_name nulls last,
    p.email,
    mc.issued_at desc nulls last,
    mc.created_at desc,
    mc.id desc;
end;
$function$;

comment on function public.get_managed_certifications(uuid) is
  'Lista certificações do escopo gerencial do usuário autenticado, respeitando '
  'a hierarquia Platform Admin -> Diretor -> Supervisor -> Vendedor e o escopo '
  'de equipes do Supervisor.';


-- ============================================================================
-- 4. Privilégios
-- ============================================================================

revoke all on function private.can_manage_organization_member(
  uuid,
  uuid
)
from public, anon, authenticated;

revoke all on function public.get_my_certifications(uuid)
from public, anon, authenticated;

grant execute on function public.get_my_certifications(uuid)
to authenticated;

revoke all on function public.get_managed_certifications(uuid)
from public, anon, authenticated;

grant execute on function public.get_managed_certifications(uuid)
to authenticated;


-- ============================================================================
-- 5. Pós-condições
-- ============================================================================

do $postcondition$
declare
  v_function_count integer;
begin
  if to_regprocedure(
    'private.can_manage_organization_member(uuid,uuid)'
  ) is null then
    raise exception
      'CERTIFICATION_QUERY_POSTCONDITION_FAILED: private management helper missing';
  end if;

  if to_regprocedure(
    'public.get_my_certifications(uuid)'
  ) is null then
    raise exception
      'CERTIFICATION_QUERY_POSTCONDITION_FAILED: personal query missing';
  end if;

  if to_regprocedure(
    'public.get_managed_certifications(uuid)'
  ) is null then
    raise exception
      'CERTIFICATION_QUERY_POSTCONDITION_FAILED: management query missing';
  end if;

  select count(*)::integer
  into v_function_count
  from pg_proc p
  where p.oid in (
    to_regprocedure(
      'private.can_manage_organization_member(uuid,uuid)'
    ),
    to_regprocedure(
      'public.get_my_certifications(uuid)'
    ),
    to_regprocedure(
      'public.get_managed_certifications(uuid)'
    )
  )
    and p.prosecdef is true
    and p.provolatile = 's'::"char";

  if v_function_count <> 3 then
    raise exception
      'CERTIFICATION_QUERY_POSTCONDITION_FAILED: functions must be SECURITY DEFINER and STABLE';
  end if;

  if has_function_privilege(
    'authenticated',
    'private.can_manage_organization_member(uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception
      'CERTIFICATION_QUERY_POSTCONDITION_FAILED: authenticated can execute private management helper';
  end if;

  if has_function_privilege(
    'anon',
    'private.can_manage_organization_member(uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception
      'CERTIFICATION_QUERY_POSTCONDITION_FAILED: anon can execute private management helper';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.get_my_certifications(uuid)',
    'EXECUTE'
  ) then
    raise exception
      'CERTIFICATION_QUERY_POSTCONDITION_FAILED: authenticated cannot execute personal query';
  end if;

  if has_function_privilege(
    'anon',
    'public.get_my_certifications(uuid)',
    'EXECUTE'
  ) then
    raise exception
      'CERTIFICATION_QUERY_POSTCONDITION_FAILED: anon can execute personal query';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.get_managed_certifications(uuid)',
    'EXECUTE'
  ) then
    raise exception
      'CERTIFICATION_QUERY_POSTCONDITION_FAILED: authenticated cannot execute management query';
  end if;

  if has_function_privilege(
    'anon',
    'public.get_managed_certifications(uuid)',
    'EXECUTE'
  ) then
    raise exception
      'CERTIFICATION_QUERY_POSTCONDITION_FAILED: anon can execute management query';
  end if;

  if exists (
    select 1
    from pg_proc p
    cross join lateral aclexplode(
      coalesce(p.proacl, acldefault('f', p.proowner))
    ) acl
    where p.oid in (
      to_regprocedure(
        'private.can_manage_organization_member(uuid,uuid)'
      ),
      to_regprocedure(
        'public.get_my_certifications(uuid)'
      ),
      to_regprocedure(
        'public.get_managed_certifications(uuid)'
      )
    )
      and acl.grantee = 0
      and acl.privilege_type = 'EXECUTE'
  ) then
    raise exception
      'CERTIFICATION_QUERY_POSTCONDITION_FAILED: PUBLIC can execute certification query function';
  end if;
end;
$postcondition$;

commit;
