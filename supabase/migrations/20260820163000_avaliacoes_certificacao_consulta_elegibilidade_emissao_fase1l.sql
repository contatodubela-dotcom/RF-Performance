-- RF Performance
-- Arquitetura escalável de avaliações e certificações
-- Fase 1L - Consulta segura de elegibilidade para emissão autorizada
--
-- Objetivo:
--   Expor ao Platform Admin uma consulta read-only que reutiliza o motor
--   genérico de requisitos para mostrar, antes da emissão, se um participante
--   está elegível para cada versão de programa de certificação.
--
-- Regras:
--   - não emite certificações;
--   - não ativa programas/versões;
--   - não altera dados operacionais;
--   - somente Platform Admin autenticado pode consultar;
--   - a elegibilidade é calculada exclusivamente pelo motor privado já
--     homologado, sem duplicar regras no frontend;
--   - a consulta é genérica e serve para N1, N2, N3 e futuros programas.

begin;


-- =============================================================================
-- 0. PREFLIGHT
-- =============================================================================

do $preflight$
begin
  if to_regclass('public.organizations') is null then
    raise exception
      'CERTIFICATION_ISSUANCE_STATE_PREFLIGHT_FAILED: public.organizations missing';
  end if;

  if to_regclass('public.organization_members') is null then
    raise exception
      'CERTIFICATION_ISSUANCE_STATE_PREFLIGHT_FAILED: public.organization_members missing';
  end if;

  if to_regclass('public.certification_programs') is null then
    raise exception
      'CERTIFICATION_ISSUANCE_STATE_PREFLIGHT_FAILED: public.certification_programs missing';
  end if;

  if to_regclass('public.certification_program_versions') is null then
    raise exception
      'CERTIFICATION_ISSUANCE_STATE_PREFLIGHT_FAILED: public.certification_program_versions missing';
  end if;

  if to_regclass('public.member_certifications') is null then
    raise exception
      'CERTIFICATION_ISSUANCE_STATE_PREFLIGHT_FAILED: public.member_certifications missing';
  end if;

  if to_regprocedure('private.is_platform_admin()') is null then
    raise exception
      'CERTIFICATION_ISSUANCE_STATE_PREFLIGHT_FAILED: private.is_platform_admin missing';
  end if;

  if to_regprocedure(
    'private.evaluate_certification_program_version(uuid,uuid,uuid)'
  ) is null then
    raise exception
      'CERTIFICATION_ISSUANCE_STATE_PREFLIGHT_FAILED: certification evaluation engine missing';
  end if;

  if to_regprocedure(
    'public.get_certification_issuance_state(uuid,uuid)'
  ) is not null then
    raise exception
      'CERTIFICATION_ISSUANCE_STATE_PREFLIGHT_FAILED: public.get_certification_issuance_state already exists';
  end if;
end;
$preflight$;


-- =============================================================================
-- 1. CONSULTA READ-ONLY DE ELEGIBILIDADE
-- =============================================================================

create function public.get_certification_issuance_state(
  p_organization_id uuid,
  p_organization_member_id uuid
)
returns table (
  certification_program_id uuid,
  program_code text,
  program_name text,
  program_description text,
  program_status text,
  program_display_order integer,

  certification_program_version_id uuid,
  version_code text,
  version_no integer,
  version_name text,
  version_description text,
  version_status text,
  version_valid_from timestamptz,
  version_valid_until timestamptz,

  participant_eligible boolean,
  program_active boolean,
  version_currently_valid boolean,
  requirements_satisfied boolean,
  required_units_total integer,
  required_units_satisfied integer,
  eligible_for_issuance boolean,
  issuance_reason text,
  requirements jsonb,
  requirement_groups jsonb,

  active_member_certification_id uuid,
  active_certificate_number text,
  active_certification_issued_at timestamptz,
  active_certification_valid_until timestamptz,
  active_certification_currently_valid boolean
)
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $function$
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED'
      using errcode = '42501';
  end if;

  if not private.is_platform_admin() then
    raise exception 'CERTIFICATION_ISSUANCE_FORBIDDEN'
      using errcode = '42501';
  end if;

  if p_organization_id is null then
    raise exception 'CERTIFICATION_ORGANIZATION_REQUIRED';
  end if;

  if p_organization_member_id is null then
    raise exception 'CERTIFICATION_MEMBER_REQUIRED';
  end if;

  if not exists (
    select 1
    from public.organizations o
    where o.id = p_organization_id
      and o.status = 'active'
      and o.archived_at is null
  ) then
    raise exception 'ORGANIZATION_NOT_AVAILABLE';
  end if;

  if not exists (
    select 1
    from public.organization_members om
    where om.id = p_organization_member_id
      and om.organization_id = p_organization_id
      and om.archived_at is null
  ) then
    raise exception 'CERTIFICATION_MEMBER_NOT_FOUND';
  end if;

  return query
  select
    cp.id as certification_program_id,
    cp.code as program_code,
    cp.name as program_name,
    cp.description as program_description,
    cp.status as program_status,
    cp.display_order as program_display_order,

    cpv.id as certification_program_version_id,
    cpv.version_code,
    cpv.version_no,
    cpv.name as version_name,
    cpv.description as version_description,
    cpv.status as version_status,
    cpv.valid_from as version_valid_from,
    cpv.valid_until as version_valid_until,

    coalesce((evaluation.result ->> 'participant_eligible')::boolean, false)
      as participant_eligible,
    coalesce((evaluation.result ->> 'program_active')::boolean, false)
      as program_active,
    coalesce((evaluation.result ->> 'version_currently_valid')::boolean, false)
      as version_currently_valid,
    coalesce((evaluation.result ->> 'requirements_satisfied')::boolean, false)
      as requirements_satisfied,
    coalesce((evaluation.result ->> 'required_units_total')::integer, 0)
      as required_units_total,
    coalesce((evaluation.result ->> 'required_units_satisfied')::integer, 0)
      as required_units_satisfied,
    coalesce((evaluation.result ->> 'eligible_for_issuance')::boolean, false)
      as eligible_for_issuance,
    coalesce(evaluation.result ->> 'issuance_reason', 'UNKNOWN_REASON')
      as issuance_reason,
    coalesce(evaluation.result -> 'requirements', '[]'::jsonb)
      as requirements,
    coalesce(evaluation.result -> 'groups', '[]'::jsonb)
      as requirement_groups,

    active_certification.id as active_member_certification_id,
    active_certification.certificate_number as active_certificate_number,
    active_certification.issued_at as active_certification_issued_at,
    active_certification.valid_until as active_certification_valid_until,
    (
      active_certification.id is not null
      and active_certification.status = 'active'
      and active_certification.archived_at is null
      and (
        active_certification.valid_until is null
        or active_certification.valid_until >= now()
      )
    ) as active_certification_currently_valid

  from public.certification_program_versions cpv
  join public.certification_programs cp
    on cp.id = cpv.certification_program_id
   and cp.organization_id = cpv.organization_id
  cross join lateral (
    select private.evaluate_certification_program_version(
      p_organization_id,
      p_organization_member_id,
      cpv.id
    ) as result
  ) evaluation
  left join lateral (
    select mc.*
    from public.member_certifications mc
    where mc.organization_id = p_organization_id
      and mc.organization_member_id = p_organization_member_id
      and mc.certification_program_id = cp.id
      and mc.status = 'active'
      and mc.archived_at is null
    order by
      mc.issued_at desc nulls last,
      mc.created_at desc,
      mc.id desc
    limit 1
  ) active_certification on true
  where cpv.organization_id = p_organization_id
    and cpv.archived_at is null
    and cp.archived_at is null
  order by
    cp.display_order,
    cp.name,
    cpv.version_no,
    cpv.id;
end;
$function$;

comment on function public.get_certification_issuance_state(
  uuid,
  uuid
) is
  'Consulta read-only para Platform Admin: avalia, por participante e versão de programa, os requisitos e a elegibilidade para emissão autorizada, reutilizando o motor genérico de certificação.';


-- =============================================================================
-- 2. PRIVILÉGIOS
-- =============================================================================

revoke all on function public.get_certification_issuance_state(
  uuid,
  uuid
)
from public, anon, authenticated;

grant execute on function public.get_certification_issuance_state(
  uuid,
  uuid
)
to authenticated;


-- =============================================================================
-- 3. POSTCONDITIONS
-- =============================================================================

do $postcondition$
declare
  v_security_definer boolean;
  v_volatility "char";
begin
  if to_regprocedure(
    'public.get_certification_issuance_state(uuid,uuid)'
  ) is null then
    raise exception
      'CERTIFICATION_ISSUANCE_STATE_POSTCONDITION_FAILED: public RPC missing';
  end if;

  select
    p.prosecdef,
    p.provolatile
  into
    v_security_definer,
    v_volatility
  from pg_proc p
  where p.oid = to_regprocedure(
    'public.get_certification_issuance_state(uuid,uuid)'
  );

  if v_security_definer is distinct from true then
    raise exception
      'CERTIFICATION_ISSUANCE_STATE_POSTCONDITION_FAILED: public RPC is not SECURITY DEFINER';
  end if;

  if v_volatility is distinct from 's'::"char" then
    raise exception
      'CERTIFICATION_ISSUANCE_STATE_POSTCONDITION_FAILED: public RPC is not STABLE';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.get_certification_issuance_state(uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception
      'CERTIFICATION_ISSUANCE_STATE_POSTCONDITION_FAILED: authenticated cannot execute public RPC';
  end if;

  if has_function_privilege(
    'anon',
    'public.get_certification_issuance_state(uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception
      'CERTIFICATION_ISSUANCE_STATE_POSTCONDITION_FAILED: anon can execute public RPC';
  end if;

  -- Garante que o wrapper público de emissão autorizado continua disponível
  -- e que esta migration não alterou seu modelo de autorização.
  if to_regprocedure(
    'public.issue_certification_program_version(uuid,uuid,uuid)'
  ) is null then
    raise exception
      'CERTIFICATION_ISSUANCE_STATE_POSTCONDITION_FAILED: authorized issuance RPC missing';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.issue_certification_program_version(uuid,uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception
      'CERTIFICATION_ISSUANCE_STATE_POSTCONDITION_FAILED: authenticated cannot reach authorized issuance wrapper';
  end if;
end;
$postcondition$;

commit;
