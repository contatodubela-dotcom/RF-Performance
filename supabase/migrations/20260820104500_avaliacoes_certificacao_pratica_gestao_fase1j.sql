-- RF Performance
-- Arquitetura escalável de avaliações e certificações
-- Fase 1J - Gestão segura de avaliações práticas
--
-- Objetivos:
--   1. Expor consulta read-only dos requisitos práticos no escopo gerencial.
--   2. Permitir que Diretor/Supervisor registre uma avaliação prática concluída
--      para um participante que esteja no seu escopo.
--   3. Derivar no servidor assessment_type, programa, versão, usuário-alvo e
--      resultado passed a partir do requisito de certificação.
--
-- Regras de segurança:
--   - não altera migrations anteriores;
--   - não ativa programas de certificação;
--   - não emite certificações;
--   - Platform Admin permanece gestor e não é tratado como avaliador prático;
--   - Diretor avalia Supervisor/Vendedor no seu escopo;
--   - Supervisor avalia somente Vendedores das equipes que gerencia;
--   - o cliente não escolhe o valor de passed;
--   - tabelas continuam sem acesso direto para authenticated.

begin;


-- =============================================================================
-- 0. PREFLIGHT
-- =============================================================================

do $preflight$
declare
  v_missing integer;
begin
  if to_regclass('public.practical_assessments') is null then
    raise exception
      'PRACTICAL_ASSESSMENT_MANAGEMENT_PREFLIGHT_FAILED: public.practical_assessments missing';
  end if;

  if to_regclass('public.certification_requirements') is null then
    raise exception
      'PRACTICAL_ASSESSMENT_MANAGEMENT_PREFLIGHT_FAILED: public.certification_requirements missing';
  end if;

  if to_regclass('public.certification_program_versions') is null then
    raise exception
      'PRACTICAL_ASSESSMENT_MANAGEMENT_PREFLIGHT_FAILED: public.certification_program_versions missing';
  end if;

  if to_regclass('public.certification_programs') is null then
    raise exception
      'PRACTICAL_ASSESSMENT_MANAGEMENT_PREFLIGHT_FAILED: public.certification_programs missing';
  end if;

  if to_regprocedure(
    'private.can_manage_organization_member(uuid,uuid)'
  ) is null then
    raise exception
      'PRACTICAL_ASSESSMENT_MANAGEMENT_PREFLIGHT_FAILED: private.can_manage_organization_member missing';
  end if;

  if to_regprocedure(
    'private.assessment_participant_eligible(uuid,uuid)'
  ) is null then
    raise exception
      'PRACTICAL_ASSESSMENT_MANAGEMENT_PREFLIGHT_FAILED: private.assessment_participant_eligible missing';
  end if;

  if to_regprocedure(
    'public.get_managed_practical_assessment_requirements(uuid,uuid)'
  ) is not null then
    raise exception
      'PRACTICAL_ASSESSMENT_MANAGEMENT_PREFLIGHT_FAILED: get_managed_practical_assessment_requirements already exists';
  end if;

  if to_regprocedure(
    'public.record_practical_assessment(uuid,uuid,uuid,numeric,integer,jsonb,text,jsonb)'
  ) is not null then
    raise exception
      'PRACTICAL_ASSESSMENT_MANAGEMENT_PREFLIGHT_FAILED: record_practical_assessment already exists';
  end if;

  select count(*)
    into v_missing
  from (
    values
      ('practical_assessments', 'organization_id'),
      ('practical_assessments', 'organization_member_id'),
      ('practical_assessments', 'user_id'),
      ('practical_assessments', 'evaluator_member_id'),
      ('practical_assessments', 'assessment_type'),
      ('practical_assessments', 'status'),
      ('practical_assessments', 'score'),
      ('practical_assessments', 'critical_errors'),
      ('practical_assessments', 'passed'),
      ('practical_assessments', 'criteria_scores'),
      ('practical_assessments', 'notes'),
      ('practical_assessments', 'evidence'),
      ('practical_assessments', 'assessed_at'),
      ('practical_assessments', 'certification_program_id'),
      ('practical_assessments', 'certification_program_version_id'),
      ('practical_assessments', 'certification_requirement_id'),
      ('certification_requirements', 'requirement_type'),
      ('certification_requirements', 'requirement_config'),
      ('certification_requirements', 'minimum_score'),
      ('certification_requirements', 'max_critical_errors')
  ) as expected(table_name, column_name)
  where not exists (
    select 1
    from information_schema.columns c
    where c.table_schema = 'public'
      and c.table_name = expected.table_name
      and c.column_name = expected.column_name
  );

  if v_missing <> 0 then
    raise exception
      'PRACTICAL_ASSESSMENT_MANAGEMENT_PREFLIGHT_FAILED: % required columns missing',
      v_missing;
  end if;
end;
$preflight$;


-- =============================================================================
-- 1. CONSULTA READ-ONLY DOS REQUISITOS PRÁTICOS DO MEMBRO GERENCIADO
-- =============================================================================

create function public.get_managed_practical_assessment_requirements(
  p_organization_id uuid,
  p_organization_member_id uuid
)
returns table (
  certification_requirement_id uuid,
  certification_program_id uuid,
  certification_program_version_id uuid,
  program_code text,
  program_name text,
  program_status text,
  version_code text,
  version_no integer,
  version_name text,
  version_status text,
  requirement_sequence_no integer,
  requirement_title text,
  requirement_description text,
  assessment_type text,
  minimum_score numeric,
  max_critical_errors integer,
  latest_practical_assessment_id uuid,
  latest_status text,
  latest_score numeric,
  latest_critical_errors integer,
  latest_passed boolean,
  latest_assessed_at timestamptz,
  latest_evaluator_member_id uuid,
  latest_evaluator_name text
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

  if p_organization_id is null then
    raise exception 'PRACTICAL_ASSESSMENT_ORGANIZATION_REQUIRED';
  end if;

  if p_organization_member_id is null then
    raise exception 'PRACTICAL_ASSESSMENT_MEMBER_REQUIRED';
  end if;

  if not private.can_manage_organization_member(
    p_organization_id,
    p_organization_member_id
  ) then
    raise exception 'PRACTICAL_ASSESSMENT_MANAGEMENT_FORBIDDEN'
      using errcode = '42501';
  end if;

  return query
  select
    r.id as certification_requirement_id,
    cp.id as certification_program_id,
    cpv.id as certification_program_version_id,
    cp.code as program_code,
    cp.name as program_name,
    cp.status as program_status,
    cpv.version_code,
    cpv.version_no,
    cpv.name as version_name,
    cpv.status as version_status,
    r.sequence_no as requirement_sequence_no,
    r.title as requirement_title,
    r.description as requirement_description,
    nullif(btrim(r.requirement_config ->> 'assessment_type'), '') as assessment_type,
    r.minimum_score,
    r.max_critical_errors,
    latest.id as latest_practical_assessment_id,
    latest.status as latest_status,
    latest.score as latest_score,
    latest.critical_errors as latest_critical_errors,
    latest.passed as latest_passed,
    latest.assessed_at as latest_assessed_at,
    latest.evaluator_member_id as latest_evaluator_member_id,
    evaluator_profile.full_name as latest_evaluator_name
  from public.certification_requirements r
  join public.certification_program_versions cpv
    on cpv.id = r.certification_program_version_id
   and cpv.organization_id = r.organization_id
  join public.certification_programs cp
    on cp.id = cpv.certification_program_id
   and cp.organization_id = cpv.organization_id
  left join lateral (
    select pa.*
    from public.practical_assessments pa
    where pa.organization_id = p_organization_id
      and pa.organization_member_id = p_organization_member_id
      and pa.certification_requirement_id = r.id
      and pa.archived_at is null
    order by
      pa.assessed_at desc nulls last,
      pa.created_at desc,
      pa.id desc
    limit 1
  ) latest on true
  left join public.organization_members evaluator_member
    on evaluator_member.id = latest.evaluator_member_id
   and evaluator_member.organization_id = latest.organization_id
  left join public.profiles evaluator_profile
    on evaluator_profile.id = evaluator_member.user_id
  where r.organization_id = p_organization_id
    and r.requirement_type = 'practical_assessment_passed'
    and r.archived_at is null
    and cpv.archived_at is null
    and cp.archived_at is null
  order by
    cp.display_order,
    cp.name,
    cpv.version_no,
    r.sequence_no,
    r.id;
end;
$function$;

comment on function public.get_managed_practical_assessment_requirements(
  uuid,
  uuid
) is
  'Lista requisitos práticos de certificação e a última avaliação prática registrada para um membro dentro do escopo gerencial do usuário autenticado.';


-- =============================================================================
-- 2. REGISTRO SEGURO DE AVALIAÇÃO PRÁTICA CONCLUÍDA
-- =============================================================================

create function public.record_practical_assessment(
  p_organization_id uuid,
  p_organization_member_id uuid,
  p_certification_requirement_id uuid,
  p_score numeric,
  p_critical_errors integer default 0,
  p_criteria_scores jsonb default '{}'::jsonb,
  p_notes text default null,
  p_evidence jsonb default '[]'::jsonb
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = pg_catalog, public, private
as $function$
declare
  v_actor_user_id uuid := auth.uid();
  v_evaluator_member_id uuid;
  v_evaluator_role text;

  v_target_user_id uuid;

  v_requirement public.certification_requirements%rowtype;
  v_program_version public.certification_program_versions%rowtype;

  v_assessment_type text;
  v_passed boolean;
  v_created public.practical_assessments%rowtype;
begin
  if v_actor_user_id is null then
    raise exception 'AUTH_REQUIRED'
      using errcode = '42501';
  end if;

  if p_organization_id is null then
    raise exception 'PRACTICAL_ASSESSMENT_ORGANIZATION_REQUIRED';
  end if;

  if p_organization_member_id is null then
    raise exception 'PRACTICAL_ASSESSMENT_MEMBER_REQUIRED';
  end if;

  if p_certification_requirement_id is null then
    raise exception 'PRACTICAL_ASSESSMENT_REQUIREMENT_REQUIRED';
  end if;

  if p_score is null or p_score < 0 or p_score > 100 then
    raise exception 'PRACTICAL_ASSESSMENT_SCORE_INVALID';
  end if;

  if p_critical_errors is null or p_critical_errors < 0 then
    raise exception 'PRACTICAL_ASSESSMENT_CRITICAL_ERRORS_INVALID';
  end if;

  if p_criteria_scores is null
     or jsonb_typeof(p_criteria_scores) <> 'object' then
    raise exception 'PRACTICAL_ASSESSMENT_CRITERIA_INVALID';
  end if;

  if p_evidence is null
     or jsonb_typeof(p_evidence) <> 'array' then
    raise exception 'PRACTICAL_ASSESSMENT_EVIDENCE_INVALID';
  end if;

  if p_notes is not null and length(p_notes) > 5000 then
    raise exception 'PRACTICAL_ASSESSMENT_NOTES_TOO_LONG';
  end if;

  if private.is_platform_admin() then
    raise exception 'PRACTICAL_ASSESSMENT_PLATFORM_ADMIN_CANNOT_EVALUATE'
      using errcode = '42501';
  end if;

  -- Avaliador precisa ser um membro organizacional ativo com papel gerencial.
  -- Platform Admin continua fora do papel de avaliador prático.
  select
    om.id,
    om.role
  into
    v_evaluator_member_id,
    v_evaluator_role
  from public.organization_members om
  join public.profiles p
    on p.id = om.user_id
   and p.status = 'active'
   and p.archived_at is null
  where om.organization_id = p_organization_id
    and om.user_id = v_actor_user_id
    and om.status = 'active'
    and om.archived_at is null
    and om.role in ('director', 'supervisor')
  order by om.created_at, om.id
  limit 1;

  if v_evaluator_member_id is null then
    raise exception 'PRACTICAL_ASSESSMENT_EVALUATOR_ROLE_REQUIRED'
      using errcode = '42501';
  end if;

  if not private.can_manage_organization_member(
    p_organization_id,
    p_organization_member_id
  ) then
    raise exception 'PRACTICAL_ASSESSMENT_TARGET_FORBIDDEN'
      using errcode = '42501';
  end if;

  if not private.assessment_participant_eligible(
    p_organization_id,
    p_organization_member_id
  ) then
    raise exception 'PRACTICAL_ASSESSMENT_TARGET_NOT_ELIGIBLE'
      using errcode = '42501';
  end if;

  select om.user_id
    into v_target_user_id
  from public.organization_members om
  where om.id = p_organization_member_id
    and om.organization_id = p_organization_id
    and om.status = 'active'
    and om.archived_at is null;

  if v_target_user_id is null then
    raise exception 'PRACTICAL_ASSESSMENT_TARGET_NOT_AVAILABLE';
  end if;

  select r.*
    into v_requirement
  from public.certification_requirements r
  where r.id = p_certification_requirement_id
    and r.organization_id = p_organization_id
    and r.requirement_type = 'practical_assessment_passed'
    and r.archived_at is null;

  if not found then
    raise exception 'PRACTICAL_ASSESSMENT_REQUIREMENT_NOT_AVAILABLE';
  end if;

  select cpv.*
    into v_program_version
  from public.certification_program_versions cpv
  join public.certification_programs cp
    on cp.id = cpv.certification_program_id
   and cp.organization_id = cpv.organization_id
   and cp.archived_at is null
  where cpv.id = v_requirement.certification_program_version_id
    and cpv.organization_id = p_organization_id
    and cpv.archived_at is null;

  if not found then
    raise exception 'PRACTICAL_ASSESSMENT_PROGRAM_VERSION_NOT_AVAILABLE';
  end if;

  v_assessment_type :=
    nullif(btrim(v_requirement.requirement_config ->> 'assessment_type'), '');

  if v_assessment_type is null then
    raise exception 'PRACTICAL_ASSESSMENT_TYPE_NOT_CONFIGURED';
  end if;

  if v_assessment_type not in (
    'role_play',
    'case_presentation',
    'microtraining',
    'full_simulation'
  ) then
    raise exception 'PRACTICAL_ASSESSMENT_TYPE_UNSUPPORTED: %',
      v_assessment_type;
  end if;

  -- O cliente nunca informa passed. O servidor deriva a aprovação usando
  -- exatamente os thresholds configurados no requisito genérico.
  v_passed :=
    (
      v_requirement.minimum_score is null
      or p_score >= v_requirement.minimum_score
    )
    and (
      v_requirement.max_critical_errors is null
      or p_critical_errors <= v_requirement.max_critical_errors
    );

  insert into public.practical_assessments (
    organization_id,
    organization_member_id,
    user_id,
    evaluator_member_id,
    certification_level_id,
    certification_program_id,
    certification_program_version_id,
    certification_requirement_id,
    assessment_type,
    status,
    score,
    critical_errors,
    passed,
    criteria_scores,
    notes,
    evidence,
    scheduled_at,
    assessed_at,
    metadata
  )
  values (
    p_organization_id,
    p_organization_member_id,
    v_target_user_id,
    v_evaluator_member_id,
    null,
    v_program_version.certification_program_id,
    v_program_version.id,
    v_requirement.id,
    v_assessment_type,
    'completed',
    p_score,
    p_critical_errors,
    v_passed,
    p_criteria_scores,
    nullif(btrim(p_notes), ''),
    p_evidence,
    null,
    now(),
    jsonb_build_object(
      'recording_model', 'managed_practical_assessment',
      'recorded_via', 'public.record_practical_assessment',
      'evaluator_role', v_evaluator_role,
      'requirement_minimum_score', v_requirement.minimum_score,
      'requirement_max_critical_errors', v_requirement.max_critical_errors
    )
  )
  returning *
  into v_created;

  return jsonb_build_object(
    'practical_assessment_id', v_created.id,
    'organization_id', v_created.organization_id,
    'organization_member_id', v_created.organization_member_id,
    'evaluator_member_id', v_created.evaluator_member_id,
    'certification_program_id', v_created.certification_program_id,
    'certification_program_version_id', v_created.certification_program_version_id,
    'certification_requirement_id', v_created.certification_requirement_id,
    'assessment_type', v_created.assessment_type,
    'status', v_created.status,
    'score', v_created.score,
    'critical_errors', v_created.critical_errors,
    'passed', v_created.passed,
    'assessed_at', v_created.assessed_at
  );
end;
$function$;

comment on function public.record_practical_assessment(
  uuid,
  uuid,
  uuid,
  numeric,
  integer,
  jsonb,
  text,
  jsonb
) is
  'Registra uma avaliação prática concluída para um requisito genérico de certificação. Somente Diretor/Supervisor autenticado e com escopo sobre o participante pode registrar; programa, versão, tipo e passed são derivados no servidor.';


-- =============================================================================
-- 3. PRIVILÉGIOS
-- =============================================================================

revoke all on function public.get_managed_practical_assessment_requirements(
  uuid,
  uuid
)
from public, anon, authenticated;

grant execute on function public.get_managed_practical_assessment_requirements(
  uuid,
  uuid
)
to authenticated;

revoke all on function public.record_practical_assessment(
  uuid,
  uuid,
  uuid,
  numeric,
  integer,
  jsonb,
  text,
  jsonb
)
from public, anon, authenticated;

grant execute on function public.record_practical_assessment(
  uuid,
  uuid,
  uuid,
  numeric,
  integer,
  jsonb,
  text,
  jsonb
)
to authenticated;


-- =============================================================================
-- 4. POSTCONDITIONS
-- =============================================================================

do $postcondition$
declare
  v_security_definer boolean;
  v_volatility "char";
begin
  if to_regprocedure(
    'public.get_managed_practical_assessment_requirements(uuid,uuid)'
  ) is null then
    raise exception
      'PRACTICAL_ASSESSMENT_MANAGEMENT_POSTCONDITION_FAILED: read RPC missing';
  end if;

  if to_regprocedure(
    'public.record_practical_assessment(uuid,uuid,uuid,numeric,integer,jsonb,text,jsonb)'
  ) is null then
    raise exception
      'PRACTICAL_ASSESSMENT_MANAGEMENT_POSTCONDITION_FAILED: write RPC missing';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.get_managed_practical_assessment_requirements(uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception
      'PRACTICAL_ASSESSMENT_MANAGEMENT_POSTCONDITION_FAILED: authenticated cannot execute read RPC';
  end if;

  if has_function_privilege(
    'anon',
    'public.get_managed_practical_assessment_requirements(uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception
      'PRACTICAL_ASSESSMENT_MANAGEMENT_POSTCONDITION_FAILED: anon can execute read RPC';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.record_practical_assessment(uuid,uuid,uuid,numeric,integer,jsonb,text,jsonb)',
    'EXECUTE'
  ) then
    raise exception
      'PRACTICAL_ASSESSMENT_MANAGEMENT_POSTCONDITION_FAILED: authenticated cannot execute write RPC';
  end if;

  if has_function_privilege(
    'anon',
    'public.record_practical_assessment(uuid,uuid,uuid,numeric,integer,jsonb,text,jsonb)',
    'EXECUTE'
  ) then
    raise exception
      'PRACTICAL_ASSESSMENT_MANAGEMENT_POSTCONDITION_FAILED: anon can execute write RPC';
  end if;

  select p.prosecdef, p.provolatile
    into v_security_definer, v_volatility
  from pg_proc p
  where p.oid = to_regprocedure(
    'public.get_managed_practical_assessment_requirements(uuid,uuid)'
  );

  if v_security_definer is distinct from true
     or v_volatility is distinct from 's'::"char" then
    raise exception
      'PRACTICAL_ASSESSMENT_MANAGEMENT_POSTCONDITION_FAILED: read RPC security/volatility mismatch';
  end if;

  select p.prosecdef, p.provolatile
    into v_security_definer, v_volatility
  from pg_proc p
  where p.oid = to_regprocedure(
    'public.record_practical_assessment(uuid,uuid,uuid,numeric,integer,jsonb,text,jsonb)'
  );

  if v_security_definer is distinct from true
     or v_volatility is distinct from 'v'::"char" then
    raise exception
      'PRACTICAL_ASSESSMENT_MANAGEMENT_POSTCONDITION_FAILED: write RPC security/volatility mismatch';
  end if;
end;
$postcondition$;

commit;
