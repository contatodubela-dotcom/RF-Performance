begin;

-- ============================================================================
-- Avaliações e Certificações — Arquitetura escalável
-- Fase 1C — Motor genérico de avaliação de requisitos
--
-- OBJETIVO
--   Criar uma camada privada e somente leitura capaz de:
--
--   1. avaliar um requisito individual;
--   2. avaliar um grupo lógico (all / any / at_least);
--   3. avaliar uma versão completa de programa de certificação;
--   4. distinguir:
--        requirements_satisfied
--        eligible_for_issuance
--
-- NÃO FAZ NESTA FASE
--   - não emite certificação;
--   - não cria member_certification;
--   - não grava member_certification_evidence;
--   - não altera tentativas;
--   - não altera avaliações práticas;
--   - não altera grants/liberações de testes;
--   - não cria RPC pública;
--   - não concede EXECUTE a authenticated/anon.
--
-- TIPOS IMPLEMENTADOS
--   assessment_graded
--   assessment_passed
--   certification_active
--   practical_assessment_passed
--
-- PREPARADOS, MAS AINDA NÃO IMPLEMENTADOS
--   training_completed
--   manual_validation
-- ============================================================================


-- ============================================================================
-- 0. PREFLIGHT
-- ============================================================================

do $preflight$
declare
  v_missing integer;
begin

  -- --------------------------------------------------------------------------
  -- Tabelas obrigatórias
  -- --------------------------------------------------------------------------

  select count(*)
    into v_missing
  from (
    values
      ('organization_members'),
      ('assessment_attempts'),
      ('practical_assessments'),
      ('member_certifications'),
      ('certification_programs'),
      ('certification_program_versions'),
      ('certification_requirement_groups'),
      ('certification_requirements')
  ) as expected(table_name)
  where to_regclass('public.' || expected.table_name) is null;

  if v_missing <> 0 then
    raise exception
      'PRECONDITION_FAILED: % required tables are missing',
      v_missing;
  end if;


  -- --------------------------------------------------------------------------
  -- Colunas estruturais adicionadas nas fases anteriores
  -- --------------------------------------------------------------------------

  select count(*)
    into v_missing
  from (
    values
      ('certification_requirements', 'assessment_test_version_id'),
      ('certification_requirements', 'requirement_group_id'),
      ('practical_assessments', 'certification_program_id'),
      ('practical_assessments', 'certification_program_version_id'),
      ('practical_assessments', 'certification_requirement_id'),
      ('member_certifications', 'certification_program_id'),
      ('member_certifications', 'certification_program_version_id')
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
      'PRECONDITION_FAILED: % required architecture columns are missing',
      v_missing;
  end if;


  -- --------------------------------------------------------------------------
  -- Proteção central de participante
  -- --------------------------------------------------------------------------

  if to_regprocedure(
    'private.assessment_participant_eligible(uuid,uuid)'
  ) is null then
    raise exception
      'PRECONDITION_FAILED: private.assessment_participant_eligible(uuid,uuid) missing';
  end if;


  -- --------------------------------------------------------------------------
  -- Não sobrescrever motor existente silenciosamente
  -- --------------------------------------------------------------------------

  if to_regprocedure(
    'private.evaluate_certification_requirement(uuid,uuid,uuid)'
  ) is not null then
    raise exception
      'PRECONDITION_FAILED: evaluate_certification_requirement already exists';
  end if;

  if to_regprocedure(
    'private.evaluate_certification_requirement_group(uuid,uuid,uuid)'
  ) is not null then
    raise exception
      'PRECONDITION_FAILED: evaluate_certification_requirement_group already exists';
  end if;

  if to_regprocedure(
    'private.evaluate_certification_program_version(uuid,uuid,uuid)'
  ) is not null then
    raise exception
      'PRECONDITION_FAILED: evaluate_certification_program_version already exists';
  end if;

end;
$preflight$;


-- ============================================================================
-- 1. AVALIAR REQUISITO INDIVIDUAL
-- ============================================================================

create function private.evaluate_certification_requirement(
  p_organization_id uuid,
  p_organization_member_id uuid,
  p_certification_requirement_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $function$
declare
  v_requirement public.certification_requirements%rowtype;

  v_attempt public.assessment_attempts%rowtype;
  v_practical public.practical_assessments%rowtype;
  v_certification public.member_certifications%rowtype;

  v_practical_type text;

  v_supported boolean := true;
  v_satisfied boolean := false;

  v_reason text := 'NOT_SATISFIED';

  v_evidence_type text;
  v_evidence_id uuid;
  v_evidence jsonb;
begin

  -- --------------------------------------------------------------------------
  -- Organização / membro precisam existir.
  --
  -- O membro não precisa ser participante elegível aqui:
  -- essa distinção é feita no nível do programa.
  --
  -- Isso permite avaliar requisitos historicamente sem transformar
  -- a função individual em portão de emissão.
  -- --------------------------------------------------------------------------

  if not exists (
    select 1
    from public.organization_members om
    where om.id = p_organization_member_id
      and om.organization_id = p_organization_id
  ) then
    raise exception
      'CERTIFICATION_MEMBER_NOT_FOUND: member % not found in organization %',
      p_organization_member_id,
      p_organization_id;
  end if;


  select r.*
    into v_requirement
  from public.certification_requirements r
  where r.id = p_certification_requirement_id
    and r.organization_id = p_organization_id
    and r.archived_at is null;

  if not found then
    raise exception
      'CERTIFICATION_REQUIREMENT_NOT_FOUND: requirement % not found in organization %',
      p_certification_requirement_id,
      p_organization_id;
  end if;


  -- ==========================================================================
  -- assessment_graded / assessment_passed
  --
  -- Sempre usa a versão EXATA da avaliação vinculada ao requisito.
  --
  -- assessment_graded:
  --   basta existir tentativa graded que também cumpra quaisquer
  --   thresholds explicitamente configurados no requisito.
  --
  -- assessment_passed:
  --   além disso exige attempt.passed = true.
  -- ==========================================================================

  if v_requirement.requirement_type in (
    'assessment_graded',
    'assessment_passed'
  ) then

    select a.*
      into v_attempt
    from public.assessment_attempts a
    where a.organization_id = p_organization_id
      and a.organization_member_id = p_organization_member_id

      and a.test_id = v_requirement.assessment_test_id
      and a.test_version_id =
        v_requirement.assessment_test_version_id

      and a.status = 'graded'
      and a.archived_at is null

      and (
        v_requirement.requirement_type = 'assessment_graded'
        or a.passed is true
      )

      and (
        v_requirement.minimum_score is null
        or (
          a.overall_score is not null
          and a.overall_score >= v_requirement.minimum_score
        )
      )

      and (
        v_requirement.minimum_legal_score is null
        or (
          a.legal_score is not null
          and a.legal_score >= v_requirement.minimum_legal_score
        )
      )

      and (
        v_requirement.max_critical_errors is null
        or a.critical_errors <= v_requirement.max_critical_errors
      )

    order by
      a.graded_at desc nulls last,
      a.attempt_no desc,
      a.started_at desc
    limit 1;

    if found then
      v_satisfied := true;
      v_reason := 'SATISFIED';

      v_evidence_type := 'assessment_attempt';
      v_evidence_id := v_attempt.id;

      v_evidence := jsonb_build_object(
        'assessment_attempt_id', v_attempt.id,
        'test_id', v_attempt.test_id,
        'test_version_id', v_attempt.test_version_id,
        'attempt_no', v_attempt.attempt_no,
        'status', v_attempt.status,
        'graded_at', v_attempt.graded_at,
        'overall_score', v_attempt.overall_score,
        'legal_score', v_attempt.legal_score,
        'critical_errors', v_attempt.critical_errors,
        'passed', v_attempt.passed
      );
    else
      v_reason :=
        case
          when v_requirement.requirement_type = 'assessment_graded'
            then 'NO_QUALIFYING_GRADED_ATTEMPT'
          else 'NO_QUALIFYING_PASSED_ATTEMPT'
        end;
    end if;


  -- ==========================================================================
  -- certification_active
  --
  -- O requisito aponta para o PROGRAMA anterior.
  -- Qualquer versão desse programa pode satisfazer o requisito,
  -- desde que a certificação esteja ativa e dentro da validade.
  -- ==========================================================================

  elsif v_requirement.requirement_type = 'certification_active' then

    select mc.*
      into v_certification
    from public.member_certifications mc
    where mc.organization_id = p_organization_id
      and mc.organization_member_id = p_organization_member_id

      and mc.certification_program_id =
        v_requirement.required_certification_program_id

      and mc.status = 'active'
      and mc.archived_at is null

      and mc.issued_at is not null
      and mc.issued_at <= now()

      and (
        mc.valid_until is null
        or mc.valid_until >= now()
      )

    order by
      mc.issued_at desc,
      mc.created_at desc
    limit 1;

    if found then
      v_satisfied := true;
      v_reason := 'SATISFIED';

      v_evidence_type := 'member_certification';
      v_evidence_id := v_certification.id;

      v_evidence := jsonb_build_object(
        'member_certification_id', v_certification.id,
        'certification_program_id',
          v_certification.certification_program_id,
        'certification_program_version_id',
          v_certification.certification_program_version_id,
        'certificate_number',
          v_certification.certificate_number,
        'status',
          v_certification.status,
        'issued_at',
          v_certification.issued_at,
        'valid_until',
          v_certification.valid_until
      );
    else
      v_reason := 'NO_ACTIVE_CERTIFICATION';
    end if;


  -- ==========================================================================
  -- practical_assessment_passed
  --
  -- A prática precisa:
  --   - estar completed;
  --   - passed = true;
  --   - ser do tipo configurado no requisito;
  --   - cumprir nota mínima e erros críticos;
  --   - estar vinculada ao requisito exato OU, como fallback estruturado,
  --     à mesma versão do programa e ao mesmo assessment_type.
  --
  -- Não há fallback para certification_level_id legado.
  -- ==========================================================================

  elsif v_requirement.requirement_type =
    'practical_assessment_passed' then

    v_practical_type :=
      nullif(
        btrim(
          coalesce(
            v_requirement.requirement_config ->> 'assessment_type',
            ''
          )
        ),
        ''
      );

    if v_practical_type is null then

      v_supported := false;
      v_reason := 'PRACTICAL_ASSESSMENT_TYPE_NOT_CONFIGURED';

    else

      select pa.*
        into v_practical
      from public.practical_assessments pa
      where pa.organization_id = p_organization_id
        and pa.organization_member_id =
          p_organization_member_id

        and pa.status = 'completed'
        and pa.passed is true
        and pa.archived_at is null

        and pa.assessment_type = v_practical_type

        and (
          pa.certification_requirement_id =
            v_requirement.id

          or (
            pa.certification_requirement_id is null
            and pa.certification_program_version_id =
              v_requirement.certification_program_version_id
          )
        )

        and (
          v_requirement.minimum_score is null
          or (
            pa.score is not null
            and pa.score >= v_requirement.minimum_score
          )
        )

        and (
          v_requirement.max_critical_errors is null
          or pa.critical_errors <=
            v_requirement.max_critical_errors
        )

      order by
        pa.assessed_at desc nulls last,
        pa.created_at desc
      limit 1;

      if found then
        v_satisfied := true;
        v_reason := 'SATISFIED';

        v_evidence_type := 'practical_assessment';
        v_evidence_id := v_practical.id;

        v_evidence := jsonb_build_object(
          'practical_assessment_id',
            v_practical.id,
          'assessment_type',
            v_practical.assessment_type,
          'certification_program_id',
            v_practical.certification_program_id,
          'certification_program_version_id',
            v_practical.certification_program_version_id,
          'certification_requirement_id',
            v_practical.certification_requirement_id,
          'match_mode',
            case
              when v_practical.certification_requirement_id =
                v_requirement.id
                then 'exact_requirement'
              else 'program_version_and_type'
            end,
          'status',
            v_practical.status,
          'score',
            v_practical.score,
          'critical_errors',
            v_practical.critical_errors,
          'passed',
            v_practical.passed,
          'assessed_at',
            v_practical.assessed_at
        );
      else
        v_reason := 'NO_QUALIFYING_PRACTICAL_ASSESSMENT';
      end if;

    end if;


  -- ==========================================================================
  -- Tipos ainda sem fonte integrada
  -- ==========================================================================

  elsif v_requirement.requirement_type in (
    'training_completed',
    'manual_validation'
  ) then

    v_supported := false;
    v_satisfied := false;

    v_reason :=
      case v_requirement.requirement_type
        when 'training_completed'
          then 'TRAINING_REQUIREMENT_NOT_IMPLEMENTED'
        when 'manual_validation'
          then 'MANUAL_VALIDATION_NOT_IMPLEMENTED'
      end;


  -- ==========================================================================
  -- Fail closed para qualquer tipo futuro ainda desconhecido
  -- ==========================================================================

  else

    v_supported := false;
    v_satisfied := false;
    v_reason := 'UNSUPPORTED_REQUIREMENT_TYPE';

  end if;


  return jsonb_build_object(
    'requirement_id',
      v_requirement.id,
    'certification_program_version_id',
      v_requirement.certification_program_version_id,
    'requirement_group_id',
      v_requirement.requirement_group_id,
    'sequence_no',
      v_requirement.sequence_no,
    'requirement_type',
      v_requirement.requirement_type,
    'title',
      v_requirement.title,
    'is_required',
      v_requirement.is_required,

    'supported',
      v_supported,
    'satisfied',
      v_satisfied,
    'reason',
      v_reason,

    'evidence_type',
      v_evidence_type,
    'evidence_id',
      v_evidence_id,
    'evidence',
      v_evidence
  );

end;
$function$;


revoke all on function
  private.evaluate_certification_requirement(uuid, uuid, uuid)
from public, anon, authenticated;


comment on function
  private.evaluate_certification_requirement(uuid, uuid, uuid)
is
  'Motor privado e somente leitura para avaliar um requisito individual de certificação e retornar a evidência candidata que o satisfaz.';


-- ============================================================================
-- 2. AVALIAR GRUPO LÓGICO
-- ============================================================================

create function private.evaluate_certification_requirement_group(
  p_organization_id uuid,
  p_organization_member_id uuid,
  p_certification_requirement_group_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $function$
declare
  v_group public.certification_requirement_groups%rowtype;

  v_requirements jsonb := '[]'::jsonb;

  v_total integer := 0;
  v_satisfied integer := 0;
  v_supported integer := 0;

  v_group_satisfied boolean := false;
  v_reason text := 'NOT_SATISFIED';
begin

  select g.*
    into v_group
  from public.certification_requirement_groups g
  where g.id = p_certification_requirement_group_id
    and g.organization_id = p_organization_id
    and g.archived_at is null;

  if not found then
    raise exception
      'CERTIFICATION_REQUIREMENT_GROUP_NOT_FOUND: group % not found in organization %',
      p_certification_requirement_group_id,
      p_organization_id;
  end if;


  select
    coalesce(
      jsonb_agg(
        evaluated.result
        order by r.sequence_no
      ),
      '[]'::jsonb
    ),
    count(*)::integer,
    count(*) filter (
      where coalesce(
        (evaluated.result ->> 'satisfied')::boolean,
        false
      )
    )::integer,
    count(*) filter (
      where coalesce(
        (evaluated.result ->> 'supported')::boolean,
        false
      )
    )::integer
  into
    v_requirements,
    v_total,
    v_satisfied,
    v_supported
  from public.certification_requirements r
  cross join lateral (
    select private.evaluate_certification_requirement(
      p_organization_id,
      p_organization_member_id,
      r.id
    ) as result
  ) evaluated
  where r.organization_id = p_organization_id
    and r.certification_program_version_id =
      v_group.certification_program_version_id
    and r.requirement_group_id = v_group.id
    and r.archived_at is null;


  if v_total = 0 then

    v_group_satisfied := false;
    v_reason := 'EMPTY_GROUP';

  elsif v_group.group_mode = 'all' then

    v_group_satisfied :=
      v_satisfied = v_total;

    v_reason :=
      case
        when v_group_satisfied then 'SATISFIED'
        else 'NOT_ALL_REQUIREMENTS_SATISFIED'
      end;

  elsif v_group.group_mode = 'any' then

    v_group_satisfied :=
      v_satisfied >= 1;

    v_reason :=
      case
        when v_group_satisfied then 'SATISFIED'
        else 'NO_ALTERNATIVE_SATISFIED'
      end;

  elsif v_group.group_mode = 'at_least' then

    v_group_satisfied :=
      v_satisfied >= v_group.minimum_required;

    v_reason :=
      case
        when v_group_satisfied then 'SATISFIED'
        else 'MINIMUM_REQUIRED_NOT_REACHED'
      end;

  else

    -- Constraint atual já impede este caso,
    -- mas o motor continua fail-closed.

    v_group_satisfied := false;
    v_reason := 'UNSUPPORTED_GROUP_MODE';

  end if;


  return jsonb_build_object(
    'group_id',
      v_group.id,
    'certification_program_version_id',
      v_group.certification_program_version_id,
    'sequence_no',
      v_group.sequence_no,
    'code',
      v_group.code,
    'name',
      v_group.name,
    'group_mode',
      v_group.group_mode,
    'minimum_required',
      v_group.minimum_required,
    'is_required',
      v_group.is_required,

    'requirements_total',
      v_total,
    'requirements_supported',
      v_supported,
    'requirements_satisfied',
      v_satisfied,

    'satisfied',
      v_group_satisfied,
    'reason',
      v_reason,

    'requirements',
      v_requirements
  );

end;
$function$;


revoke all on function
  private.evaluate_certification_requirement_group(uuid, uuid, uuid)
from public, anon, authenticated;


comment on function
  private.evaluate_certification_requirement_group(uuid, uuid, uuid)
is
  'Avalia grupo lógico de requisitos de certificação nos modos all, any ou at_least.';


-- ============================================================================
-- 3. AVALIAR VERSÃO COMPLETA DO PROGRAMA
-- ============================================================================

create function private.evaluate_certification_program_version(
  p_organization_id uuid,
  p_organization_member_id uuid,
  p_certification_program_version_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $function$
declare
  v_version public.certification_program_versions%rowtype;
  v_program public.certification_programs%rowtype;

  v_participant_eligible boolean := false;
  v_program_active boolean := false;
  v_version_currently_valid boolean := false;

  v_requirements jsonb := '[]'::jsonb;
  v_groups jsonb := '[]'::jsonb;

  v_ungrouped_required_total integer := 0;
  v_ungrouped_required_satisfied integer := 0;

  v_required_groups_total integer := 0;
  v_required_groups_satisfied integer := 0;

  v_required_units_total integer := 0;
  v_required_units_satisfied integer := 0;

  v_requirements_satisfied boolean := false;
  v_eligible_for_issuance boolean := false;

  v_requirements_reason text;
  v_issuance_reason text;
begin

  -- --------------------------------------------------------------------------
  -- Membro precisa pertencer à organização.
  -- --------------------------------------------------------------------------

  if not exists (
    select 1
    from public.organization_members om
    where om.id = p_organization_member_id
      and om.organization_id = p_organization_id
  ) then
    raise exception
      'CERTIFICATION_MEMBER_NOT_FOUND: member % not found in organization %',
      p_organization_member_id,
      p_organization_id;
  end if;


  -- --------------------------------------------------------------------------
  -- Versão e programa.
  --
  -- Não filtramos draft/archived aqui porque o motor deve conseguir
  -- diagnosticar uma versão mesmo quando ela ainda não pode emitir.
  -- --------------------------------------------------------------------------

  select pv.*
    into v_version
  from public.certification_program_versions pv
  where pv.id = p_certification_program_version_id
    and pv.organization_id = p_organization_id;

  if not found then
    raise exception
      'CERTIFICATION_PROGRAM_VERSION_NOT_FOUND: version % not found in organization %',
      p_certification_program_version_id,
      p_organization_id;
  end if;


  select p.*
    into v_program
  from public.certification_programs p
  where p.id = v_version.certification_program_id
    and p.organization_id = p_organization_id;

  if not found then
    raise exception
      'CERTIFICATION_PROGRAM_NOT_FOUND: program % not found in organization %',
      v_version.certification_program_id,
      p_organization_id;
  end if;


  -- --------------------------------------------------------------------------
  -- Regra central já homologada:
  -- salesperson / supervisor / director ativos;
  -- platform_admin nunca participante.
  -- --------------------------------------------------------------------------

  v_participant_eligible :=
    private.assessment_participant_eligible(
      p_organization_id,
      p_organization_member_id
    );


  -- --------------------------------------------------------------------------
  -- Para emissão automática/futura, programa E versão precisam estar ativos.
  --
  -- Enquanto os programas da Fase 1B estiverem draft,
  -- eligible_for_issuance será false mesmo que todos os requisitos
  -- tenham sido cumpridos.
  -- --------------------------------------------------------------------------

  v_program_active :=
    v_program.status = 'active'
    and v_program.archived_at is null
    and v_version.status = 'active'
    and v_version.archived_at is null;


  v_version_currently_valid :=
    (
      v_version.valid_from is null
      or v_version.valid_from <= now()
    )
    and (
      v_version.valid_until is null
      or v_version.valid_until >= now()
    );


  -- --------------------------------------------------------------------------
  -- Resultado individual de TODOS os requisitos.
  -- --------------------------------------------------------------------------

  select coalesce(
    jsonb_agg(
      evaluated.result
      order by r.sequence_no
    ),
    '[]'::jsonb
  )
  into v_requirements
  from public.certification_requirements r
  cross join lateral (
    select private.evaluate_certification_requirement(
      p_organization_id,
      p_organization_member_id,
      r.id
    ) as result
  ) evaluated
  where r.organization_id = p_organization_id
    and r.certification_program_version_id =
      p_certification_program_version_id
    and r.archived_at is null;


  -- --------------------------------------------------------------------------
  -- Grupos existentes.
  -- --------------------------------------------------------------------------

  select coalesce(
    jsonb_agg(
      evaluated.result
      order by g.sequence_no
    ),
    '[]'::jsonb
  )
  into v_groups
  from public.certification_requirement_groups g
  cross join lateral (
    select private.evaluate_certification_requirement_group(
      p_organization_id,
      p_organization_member_id,
      g.id
    ) as result
  ) evaluated
  where g.organization_id = p_organization_id
    and g.certification_program_version_id =
      p_certification_program_version_id
    and g.archived_at is null;


  -- --------------------------------------------------------------------------
  -- Unidades obrigatórias NÃO agrupadas.
  --
  -- Um requisito dentro de grupo não é contado novamente no nível
  -- superior. O grupo é uma única unidade lógica.
  -- --------------------------------------------------------------------------

  select
    count(*)::integer,
    count(*) filter (
      where coalesce(
        (evaluated.result ->> 'satisfied')::boolean,
        false
      )
    )::integer
  into
    v_ungrouped_required_total,
    v_ungrouped_required_satisfied
  from public.certification_requirements r
  cross join lateral (
    select private.evaluate_certification_requirement(
      p_organization_id,
      p_organization_member_id,
      r.id
    ) as result
  ) evaluated
  where r.organization_id = p_organization_id
    and r.certification_program_version_id =
      p_certification_program_version_id

    and r.requirement_group_id is null
    and r.is_required = true
    and r.archived_at is null;


  -- --------------------------------------------------------------------------
  -- Grupos obrigatórios.
  --
  -- Dentro do grupo, todos os requisitos participam da lógica do grupo,
  -- independentemente do is_required individual.
  --
  -- Isso é necessário para:
  --   case_presentation OR microtraining
  -- onde nenhum requisito alternativo é individualmente obrigatório,
  -- mas o GRUPO é obrigatório.
  -- --------------------------------------------------------------------------

  select
    count(*)::integer,
    count(*) filter (
      where coalesce(
        (evaluated.result ->> 'satisfied')::boolean,
        false
      )
    )::integer
  into
    v_required_groups_total,
    v_required_groups_satisfied
  from public.certification_requirement_groups g
  cross join lateral (
    select private.evaluate_certification_requirement_group(
      p_organization_id,
      p_organization_member_id,
      g.id
    ) as result
  ) evaluated
  where g.organization_id = p_organization_id
    and g.certification_program_version_id =
      p_certification_program_version_id
    and g.is_required = true
    and g.archived_at is null;


  v_required_units_total :=
    v_ungrouped_required_total
    + v_required_groups_total;

  v_required_units_satisfied :=
    v_ungrouped_required_satisfied
    + v_required_groups_satisfied;


  -- --------------------------------------------------------------------------
  -- Lógica global da versão.
  --
  -- FAIL CLOSED:
  -- versão sem unidade obrigatória não é considerada satisfeita.
  -- --------------------------------------------------------------------------

  if v_required_units_total = 0 then

    v_requirements_satisfied := false;
    v_requirements_reason := 'NO_REQUIRED_UNITS';

  elsif v_version.requirements_mode = 'all' then

    v_requirements_satisfied :=
      v_required_units_satisfied =
      v_required_units_total;

    v_requirements_reason :=
      case
        when v_requirements_satisfied
          then 'SATISFIED'
        else 'NOT_ALL_REQUIRED_UNITS_SATISFIED'
      end;

  elsif v_version.requirements_mode = 'any' then

    v_requirements_satisfied :=
      v_required_units_satisfied >= 1;

    v_requirements_reason :=
      case
        when v_requirements_satisfied
          then 'SATISFIED'
        else 'NO_REQUIRED_UNIT_SATISFIED'
      end;

  else

    v_requirements_satisfied := false;
    v_requirements_reason := 'UNSUPPORTED_REQUIREMENTS_MODE';

  end if;


  -- --------------------------------------------------------------------------
  -- Elegibilidade final para emissão.
  --
  -- Separada de requirements_satisfied.
  -- --------------------------------------------------------------------------

  v_eligible_for_issuance :=
    v_participant_eligible
    and v_program_active
    and v_version_currently_valid
    and v_requirements_satisfied;


  v_issuance_reason :=
    case
      when not v_participant_eligible
        then 'PARTICIPANT_NOT_ELIGIBLE'

      when not v_program_active
        then 'PROGRAM_OR_VERSION_NOT_ACTIVE'

      when not v_version_currently_valid
        then 'PROGRAM_VERSION_OUTSIDE_VALIDITY_WINDOW'

      when not v_requirements_satisfied
        then 'REQUIREMENTS_NOT_SATISFIED'

      else 'ELIGIBLE'
    end;


  return jsonb_build_object(
    'organization_id',
      p_organization_id,
    'organization_member_id',
      p_organization_member_id,

    'certification_program_id',
      v_program.id,
    'certification_program_code',
      v_program.code,
    'certification_program_status',
      v_program.status,

    'certification_program_version_id',
      v_version.id,
    'version_code',
      v_version.version_code,
    'version_no',
      v_version.version_no,
    'version_status',
      v_version.status,
    'requirements_mode',
      v_version.requirements_mode,

    'participant_eligible',
      v_participant_eligible,
    'program_active',
      v_program_active,
    'version_currently_valid',
      v_version_currently_valid,
    'version_valid_from',
      v_version.valid_from,
    'version_valid_until',
      v_version.valid_until,

    'required_units_total',
      v_required_units_total,
    'required_units_satisfied',
      v_required_units_satisfied,

    'ungrouped_required_total',
      v_ungrouped_required_total,
    'ungrouped_required_satisfied',
      v_ungrouped_required_satisfied,

    'required_groups_total',
      v_required_groups_total,
    'required_groups_satisfied',
      v_required_groups_satisfied,

    'requirements_satisfied',
      v_requirements_satisfied,
    'requirements_reason',
      v_requirements_reason,

    'eligible_for_issuance',
      v_eligible_for_issuance,
    'issuance_reason',
      v_issuance_reason,

    'requirements',
      v_requirements,
    'groups',
      v_groups
  );

end;
$function$;


revoke all on function
  private.evaluate_certification_program_version(uuid, uuid, uuid)
from public, anon, authenticated;


comment on function
  private.evaluate_certification_program_version(uuid, uuid, uuid)
is
  'Motor privado e somente leitura que calcula requisitos cumpridos e elegibilidade de emissão para uma versão de programa de certificação.';


-- ============================================================================
-- 4. PÓS-CONDIÇÕES
-- ============================================================================

do $postconditions$
declare
  v_invalid integer;
begin

  -- --------------------------------------------------------------------------
  -- As três funções precisam existir.
  -- --------------------------------------------------------------------------

  select count(*)
    into v_invalid
  from (
    values
      (
        'private.evaluate_certification_requirement(uuid,uuid,uuid)'
      ),
      (
        'private.evaluate_certification_requirement_group(uuid,uuid,uuid)'
      ),
      (
        'private.evaluate_certification_program_version(uuid,uuid,uuid)'
      )
  ) as expected(signature)
  where to_regprocedure(expected.signature) is null;

  if v_invalid <> 0 then
    raise exception
      'POSTCONDITION_FAILED: % engine functions are missing',
      v_invalid;
  end if;


  -- --------------------------------------------------------------------------
  -- Todas devem ser SECURITY DEFINER + STABLE.
  -- --------------------------------------------------------------------------

  select count(*)
    into v_invalid
  from pg_proc p
  join pg_namespace n
    on n.oid = p.pronamespace
  where n.nspname = 'private'
    and p.proname in (
      'evaluate_certification_requirement',
      'evaluate_certification_requirement_group',
      'evaluate_certification_program_version'
    )
    and (
      p.prosecdef is distinct from true
      or p.provolatile <> 's'
    );

  if v_invalid <> 0 then
    raise exception
      'POSTCONDITION_FAILED: % engine functions have invalid security/volatility',
      v_invalid;
  end if;


  -- --------------------------------------------------------------------------
  -- authenticated e anon não podem executar diretamente.
  --
  -- Se PUBLIC ainda tivesse EXECUTE, esses checks também seriam true,
  -- pois ambos herdariam o privilégio de PUBLIC.
  -- --------------------------------------------------------------------------

  if has_function_privilege(
    'authenticated',
    'private.evaluate_certification_requirement(uuid,uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception
      'POSTCONDITION_FAILED: authenticated can execute evaluate_certification_requirement';
  end if;

  if has_function_privilege(
    'anon',
    'private.evaluate_certification_requirement(uuid,uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception
      'POSTCONDITION_FAILED: anon can execute evaluate_certification_requirement';
  end if;


  if has_function_privilege(
    'authenticated',
    'private.evaluate_certification_requirement_group(uuid,uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception
      'POSTCONDITION_FAILED: authenticated can execute evaluate_certification_requirement_group';
  end if;

  if has_function_privilege(
    'anon',
    'private.evaluate_certification_requirement_group(uuid,uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception
      'POSTCONDITION_FAILED: anon can execute evaluate_certification_requirement_group';
  end if;


  if has_function_privilege(
    'authenticated',
    'private.evaluate_certification_program_version(uuid,uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception
      'POSTCONDITION_FAILED: authenticated can execute evaluate_certification_program_version';
  end if;

  if has_function_privilege(
    'anon',
    'private.evaluate_certification_program_version(uuid,uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception
      'POSTCONDITION_FAILED: anon can execute evaluate_certification_program_version';
  end if;

end;
$postconditions$;


commit;