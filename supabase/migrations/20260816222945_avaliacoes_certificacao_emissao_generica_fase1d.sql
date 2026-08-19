-- RF Performance
-- Arquitetura escalável de avaliações e certificações
-- Fase 1D - Emissão genérica e snapshot auditável de evidências
--
-- IMPORTANTE:
--   - esta migration NÃO emite certificações;
--   - NÃO ativa programas;
--   - NÃO altera dados operacionais;
--   - cria apenas o mecanismo privado de emissão;
--   - a emissão só ocorre quando a função for chamada explicitamente;
--   - a elegibilidade continua sendo responsabilidade exclusiva do motor da Fase 1C.

begin;


-- ============================================================================
-- 0. PRECONDITIONS
-- ============================================================================

do $preflight$
declare
  v_missing integer;
begin

  -- --------------------------------------------------------------------------
  -- Estruturas obrigatórias
  -- --------------------------------------------------------------------------

  if to_regclass('public.organization_members') is null then
    raise exception
      'PRECONDITION_FAILED: public.organization_members missing';
  end if;

  if to_regclass('public.certification_programs') is null then
    raise exception
      'PRECONDITION_FAILED: public.certification_programs missing';
  end if;

  if to_regclass('public.certification_program_versions') is null then
    raise exception
      'PRECONDITION_FAILED: public.certification_program_versions missing';
  end if;

  if to_regclass('public.certification_requirements') is null then
    raise exception
      'PRECONDITION_FAILED: public.certification_requirements missing';
  end if;

  if to_regclass('public.member_certifications') is null then
    raise exception
      'PRECONDITION_FAILED: public.member_certifications missing';
  end if;

  if to_regclass('public.member_certification_evidence') is null then
    raise exception
      'PRECONDITION_FAILED: public.member_certification_evidence missing';
  end if;


  -- --------------------------------------------------------------------------
  -- Motor genérico da Fase 1C precisa existir
  -- --------------------------------------------------------------------------

  if to_regprocedure(
    'private.evaluate_certification_program_version(uuid,uuid,uuid)'
  ) is null then
    raise exception
      'PRECONDITION_FAILED: evaluate_certification_program_version missing';
  end if;


  -- --------------------------------------------------------------------------
  -- Índice de defesa contra duas certificações ativas do mesmo programa
  -- --------------------------------------------------------------------------

  if to_regclass(
    'public.member_certifications_one_active_program_idx'
  ) is null then
    raise exception
      'PRECONDITION_FAILED: member_certifications_one_active_program_idx missing';
  end if;


  -- --------------------------------------------------------------------------
  -- Colunas necessárias
  -- --------------------------------------------------------------------------

  select count(*)
    into v_missing
  from (
    values
      ('organization_members', 'id'),
      ('organization_members', 'organization_id'),
      ('organization_members', 'user_id'),

      ('certification_program_versions', 'id'),
      ('certification_program_versions', 'organization_id'),
      ('certification_program_versions', 'certification_program_id'),
      ('certification_program_versions', 'validity_months'),

      ('member_certifications', 'id'),
      ('member_certifications', 'organization_id'),
      ('member_certifications', 'organization_member_id'),
      ('member_certifications', 'user_id'),
      ('member_certifications', 'certification_level_id'),
      ('member_certifications', 'certification_program_id'),
      ('member_certifications', 'certification_program_version_id'),
      ('member_certifications', 'source_attempt_id'),
      ('member_certifications', 'source_practical_assessment_id'),
      ('member_certifications', 'certificate_number'),
      ('member_certifications', 'status'),
      ('member_certifications', 'issued_at'),
      ('member_certifications', 'valid_until'),
      ('member_certifications', 'archived_at'),
      ('member_certifications', 'metadata'),

      ('member_certification_evidence', 'organization_id'),
      ('member_certification_evidence', 'member_certification_id'),
      ('member_certification_evidence', 'certification_requirement_id'),
      ('member_certification_evidence', 'evidence_type'),
      ('member_certification_evidence', 'assessment_attempt_id'),
      ('member_certification_evidence', 'practical_assessment_id'),
      ('member_certification_evidence', 'source_member_certification_id'),
      ('member_certification_evidence', 'status'),
      ('member_certification_evidence', 'satisfied_at'),
      ('member_certification_evidence', 'validated_by'),
      ('member_certification_evidence', 'evidence_data'),
      ('member_certification_evidence', 'created_at'),
      ('member_certification_evidence', 'created_by'),
      ('member_certification_evidence', 'updated_at'),
      ('member_certification_evidence', 'updated_by'),
      ('member_certification_evidence', 'archived_at'),
      ('member_certification_evidence', 'metadata')
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
      'PRECONDITION_FAILED: % required columns missing',
      v_missing;
  end if;


  -- --------------------------------------------------------------------------
  -- O modelo genérico precisa permitir certification_level_id NULL
  -- --------------------------------------------------------------------------

  if exists (
    select 1
    from information_schema.columns c
    where c.table_schema = 'public'
      and c.table_name = 'member_certifications'
      and c.column_name = 'certification_level_id'
      and c.is_nullable <> 'YES'
  ) then
    raise exception
      'PRECONDITION_FAILED: member_certifications.certification_level_id must be nullable';
  end if;


  -- --------------------------------------------------------------------------
  -- Não sobrescrever mecanismo de emissão existente silenciosamente
  -- --------------------------------------------------------------------------

  if to_regprocedure(
    'private.issue_certification_program_version(uuid,uuid,uuid)'
  ) is not null then
    raise exception
      'PRECONDITION_FAILED: issue_certification_program_version already exists';
  end if;

end;
$preflight$;


-- ============================================================================
-- 1. EMISSÃO GENÉRICA DE CERTIFICAÇÃO
-- ============================================================================

create function private.issue_certification_program_version(
  p_organization_id uuid,
  p_organization_member_id uuid,
  p_certification_program_version_id uuid
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = pg_catalog, public, private
as $function$
declare

  v_member public.organization_members%rowtype;
  v_version public.certification_program_versions%rowtype;

  v_existing public.member_certifications%rowtype;
  v_created public.member_certifications%rowtype;

  v_existing_found boolean := false;

  v_evaluation jsonb;
  v_requirement_evaluation jsonb;

  v_requirement_id uuid;

  v_engine_evidence_type text;
  v_persisted_evidence_type text;
  v_evidence_id_text text;

  v_assessment_attempt_id uuid;
  v_practical_assessment_id uuid;
  v_source_member_certification_id uuid;

  v_evidence_data jsonb;

  v_expected_evidence_count integer := 0;
  v_evidence_count integer := 0;

  v_now timestamptz := now();
  v_valid_until timestamptz;

  v_certification_id uuid;
  v_certificate_number text;

  v_actor uuid := auth.uid();

begin

  -- ==========================================================================
  -- Organização / membro
  -- ==========================================================================

  select om.*
    into v_member
  from public.organization_members om
  where om.id = p_organization_member_id
    and om.organization_id = p_organization_id;

  if not found then
    raise exception
      'CERTIFICATION_MEMBER_NOT_FOUND: member % not found in organization %',
      p_organization_member_id,
      p_organization_id;
  end if;


  if v_member.user_id is null then
    raise exception
      'CERTIFICATION_MEMBER_USER_MISSING: member % has no user_id',
      p_organization_member_id;
  end if;


  -- ==========================================================================
  -- Versão exata do programa
  -- ==========================================================================

  select cpv.*
    into v_version
  from public.certification_program_versions cpv
  where cpv.id = p_certification_program_version_id
    and cpv.organization_id = p_organization_id
    and cpv.archived_at is null;

  if not found then
    raise exception
      'CERTIFICATION_PROGRAM_VERSION_NOT_FOUND: version % not found in organization %',
      p_certification_program_version_id,
      p_organization_id;
  end if;


  -- ==========================================================================
  -- Serialização por organização + membro + programa
  --
  -- Impede duas emissões concorrentes para o mesmo programa.
  -- O índice UNIQUE de certificação ativa continua como defesa final.
  -- ==========================================================================

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      'certification_issue:'
      || p_organization_id::text
      || ':'
      || p_organization_member_id::text
      || ':'
      || v_version.certification_program_id::text,
      0::bigint
    )
  );


  -- ==========================================================================
  -- Idempotência
  --
  -- Uma certificação ativa e ainda vigente para o mesmo programa é retornada
  -- sem criar novo registro.
  -- ==========================================================================

  select mc.*
    into v_existing
  from public.member_certifications mc
  where mc.organization_id = p_organization_id
    and mc.organization_member_id = p_organization_member_id
    and mc.certification_program_id =
      v_version.certification_program_id
    and mc.status = 'active'
    and mc.archived_at is null
  order by
    mc.issued_at desc nulls last,
    mc.created_at desc
  limit 1
  for update;

  v_existing_found := found;


  if v_existing_found
     and (
       v_existing.valid_until is null
       or v_existing.valid_until >= v_now
     )
  then

    return jsonb_build_object(
      'created',
        false,
      'outcome',
        'ALREADY_ACTIVE',

      'organization_id',
        p_organization_id,
      'organization_member_id',
        p_organization_member_id,

      'certification_program_id',
        v_existing.certification_program_id,
      'requested_certification_program_version_id',
        p_certification_program_version_id,
      'certification_program_version_id',
        v_existing.certification_program_version_id,

      'member_certification_id',
        v_existing.id,
      'certificate_number',
        v_existing.certificate_number,

      'status',
        v_existing.status,
      'issued_at',
        v_existing.issued_at,
      'valid_until',
        v_existing.valid_until,

      'evidence_count',
        (
          select count(*)
          from public.member_certification_evidence e
          where e.organization_id = p_organization_id
            and e.member_certification_id = v_existing.id
            and e.archived_at is null
        )
    );

  end if;


  -- ==========================================================================
  -- Avaliação única da elegibilidade
  --
  -- O JSON retornado aqui é o snapshot usado para autorizar a emissão E para
  -- persistir as evidências. Não recalculamos requisito por requisito depois.
  -- ==========================================================================

  v_evaluation :=
    private.evaluate_certification_program_version(
      p_organization_id,
      p_organization_member_id,
      p_certification_program_version_id
    );


  if v_evaluation is null
     or jsonb_typeof(v_evaluation) <> 'object'
  then
    raise exception
      'CERTIFICATION_ENGINE_INVALID_RESULT: program evaluation is not an object';
  end if;


  if jsonb_typeof(
    v_evaluation -> 'eligible_for_issuance'
  ) <> 'boolean' then
    raise exception
      'CERTIFICATION_ENGINE_INVALID_RESULT: eligible_for_issuance is not boolean';
  end if;


  if jsonb_typeof(
    v_evaluation -> 'requirements'
  ) <> 'array' then
    raise exception
      'CERTIFICATION_ENGINE_INVALID_RESULT: requirements is not an array';
  end if;


  if coalesce(
    (v_evaluation ->> 'eligible_for_issuance')::boolean,
    false
  ) is not true then

    raise exception
      'CERTIFICATION_NOT_ELIGIBLE: %',
      coalesce(
        v_evaluation ->> 'issuance_reason',
        'UNKNOWN_REASON'
      );

  end if;


  -- ==========================================================================
  -- Uma certificação ativa antiga pode continuar com status = active mesmo
  -- depois de valid_until. Ela só é expirada aqui se uma nova emissão realmente
  -- estiver autorizada.
  -- ==========================================================================

  if v_existing_found
     and v_existing.valid_until is not null
     and v_existing.valid_until < v_now
  then

    update public.member_certifications
       set status = 'expired',
           updated_at = v_now,
           updated_by = coalesce(v_actor, updated_by),
           metadata =
             coalesce(metadata, '{}'::jsonb)
             || jsonb_build_object(
                  'expired_during_reissuance_at',
                    v_now,
                  'expired_during_reissuance_by',
                    'private.issue_certification_program_version'
                )
     where id = v_existing.id
       and organization_id = p_organization_id
       and status = 'active'
       and archived_at is null;

  end if;


  -- ==========================================================================
  -- Validade da certificação
  -- ==========================================================================

  if v_version.validity_months is null then
    v_valid_until := null;
  else
    v_valid_until :=
      v_now
      + pg_catalog.make_interval(
          months => v_version.validity_months
        );
  end if;


  -- ==========================================================================
  -- Identidade da certificação / número público
  --
  -- O mesmo UUID primário gera um número opaco e globalmente único.
  -- Não existe contador sequencial ou estado adicional.
  -- ==========================================================================

  v_certification_id := gen_random_uuid();

  v_certificate_number :=
    'RFP-CERT-'
    || upper(
         replace(
           v_certification_id::text,
           '-',
           ''
         )
       );


  -- ==========================================================================
  -- Criação da certificação genérica
  -- ==========================================================================

  insert into public.member_certifications (
    id,
    organization_id,
    organization_member_id,
    user_id,

    certification_level_id,
    certification_program_id,
    certification_program_version_id,

    source_attempt_id,
    source_practical_assessment_id,

    certificate_number,
    status,

    issued_at,
    valid_until,

    created_by,
    updated_by,

    metadata
  )
  values (
    v_certification_id,
    p_organization_id,
    p_organization_member_id,
    v_member.user_id,

    null,
    v_version.certification_program_id,
    v_version.id,

    null,
    null,

    v_certificate_number,
    'active',

    v_now,
    v_valid_until,

    v_actor,
    v_actor,

    jsonb_build_object(
      'issuance_model',
        'certification_program',
      'issued_by',
        'private.issue_certification_program_version',
      'engine',
        'private.evaluate_certification_program_version',
      'engine_snapshot',
        v_evaluation
    )
  )
  returning *
  into v_created;


  -- ==========================================================================
  -- Quantidade de requisitos satisfeitos no snapshot
  -- ==========================================================================

  select count(*)
    into v_expected_evidence_count
  from jsonb_array_elements(
    v_evaluation -> 'requirements'
  ) as item(value)
  where coalesce(
    (item.value ->> 'satisfied')::boolean,
    false
  ) is true;


  -- ==========================================================================
  -- Snapshot auditável das evidências
  --
  -- Persistimos todos os requisitos que estavam satisfeitos no mesmo snapshot
  -- que autorizou a certificação.
  --
  -- Para grupos ANY/AT_LEAST, somente alternativas realmente satisfeitas são
  -- gravadas.
  -- ==========================================================================

  for v_requirement_evaluation in
    select item.value
    from jsonb_array_elements(
      v_evaluation -> 'requirements'
    ) as item(value)
    where coalesce(
      (item.value ->> 'satisfied')::boolean,
      false
    ) is true
    order by
      coalesce(
        (item.value ->> 'sequence_no')::integer,
        2147483647
      )
  loop

    -- ------------------------------------------------------------------------
    -- Identidade do requisito
    -- ------------------------------------------------------------------------

    if nullif(
      v_requirement_evaluation ->> 'requirement_id',
      ''
    ) is null then
      raise exception
        'CERTIFICATION_EVIDENCE_INVALID: satisfied requirement without requirement_id';
    end if;


    v_requirement_id :=
      (
        v_requirement_evaluation ->> 'requirement_id'
      )::uuid;


    -- ------------------------------------------------------------------------
    -- Tipo e identidade da evidência
    -- ------------------------------------------------------------------------

    v_engine_evidence_type :=
      nullif(
        v_requirement_evaluation ->> 'evidence_type',
        ''
      );

    v_evidence_id_text :=
      nullif(
        v_requirement_evaluation ->> 'evidence_id',
        ''
      );


    if v_engine_evidence_type is null then
      raise exception
        'CERTIFICATION_EVIDENCE_INVALID: satisfied requirement % without evidence_type',
        v_requirement_id;
    end if;


    v_assessment_attempt_id := null;
    v_practical_assessment_id := null;
    v_source_member_certification_id := null;
    v_persisted_evidence_type := null;


    case v_engine_evidence_type

      when 'assessment_attempt' then

        if v_evidence_id_text is null then
          raise exception
            'CERTIFICATION_EVIDENCE_INVALID: assessment requirement % without evidence_id',
            v_requirement_id;
        end if;

        v_persisted_evidence_type :=
          'assessment_attempt';

        v_assessment_attempt_id :=
          v_evidence_id_text::uuid;


      when 'practical_assessment' then

        if v_evidence_id_text is null then
          raise exception
            'CERTIFICATION_EVIDENCE_INVALID: practical requirement % without evidence_id',
            v_requirement_id;
        end if;

        v_persisted_evidence_type :=
          'practical_assessment';

        v_practical_assessment_id :=
          v_evidence_id_text::uuid;


      when 'member_certification' then

        if v_evidence_id_text is null then
          raise exception
            'CERTIFICATION_EVIDENCE_INVALID: certification requirement % without evidence_id',
            v_requirement_id;
        end if;

        -- Tradução explícita entre contrato do motor e tabela persistente.
        v_persisted_evidence_type :=
          'certification';

        v_source_member_certification_id :=
          v_evidence_id_text::uuid;


      when 'certification' then

        if v_evidence_id_text is null then
          raise exception
            'CERTIFICATION_EVIDENCE_INVALID: certification requirement % without evidence_id',
            v_requirement_id;
        end if;

        v_persisted_evidence_type :=
          'certification';

        v_source_member_certification_id :=
          v_evidence_id_text::uuid;


      when 'training' then

        -- Preparação para evolução futura do motor.
        -- A tabela atual não possui FK específica para treinamento.
        v_persisted_evidence_type :=
          'training';


      when 'manual_validation' then

        -- Preparação para evolução futura do motor.
        -- Não inventamos referência externa inexistente.
        v_persisted_evidence_type :=
          'manual_validation';


      else

        raise exception
          'CERTIFICATION_EVIDENCE_UNSUPPORTED_TYPE: requirement %, type %',
          v_requirement_id,
          v_engine_evidence_type;

    end case;


    -- ------------------------------------------------------------------------
    -- Payload original da evidência
    -- ------------------------------------------------------------------------

    if v_requirement_evaluation -> 'evidence' is null
       or jsonb_typeof(
         v_requirement_evaluation -> 'evidence'
       ) = 'null'
    then

      v_evidence_data := '{}'::jsonb;

    elsif jsonb_typeof(
      v_requirement_evaluation -> 'evidence'
    ) <> 'object'
    then

      raise exception
        'CERTIFICATION_EVIDENCE_INVALID_DATA: requirement % evidence must be object',
        v_requirement_id;

    else

      v_evidence_data :=
        v_requirement_evaluation -> 'evidence';

    end if;


    -- ------------------------------------------------------------------------
    -- Persistência
    -- ------------------------------------------------------------------------

    insert into public.member_certification_evidence (
      organization_id,

      member_certification_id,
      certification_requirement_id,

      evidence_type,

      assessment_attempt_id,
      practical_assessment_id,
      source_member_certification_id,

      status,
      satisfied_at,
      validated_by,

      evidence_data,

      created_at,
      created_by,
      updated_at,
      updated_by,

      metadata
    )
    values (
      p_organization_id,

      v_created.id,
      v_requirement_id,

      v_persisted_evidence_type,

      v_assessment_attempt_id,
      v_practical_assessment_id,
      v_source_member_certification_id,

      'satisfied',
      v_now,
      null,

      v_evidence_data,

      v_now,
      v_actor,
      v_now,
      v_actor,

      jsonb_build_object(
        'captured_by',
          'private.issue_certification_program_version',
        'engine_requirement_snapshot',
          v_requirement_evaluation
      )
    );


    v_evidence_count :=
      v_evidence_count + 1;

  end loop;


  -- ==========================================================================
  -- Defesa: toda evidência satisfeita do snapshot deve ter sido persistida
  -- ==========================================================================

  if v_evidence_count <> v_expected_evidence_count then
    raise exception
      'CERTIFICATION_EVIDENCE_COUNT_MISMATCH: expected %, persisted %',
      v_expected_evidence_count,
      v_evidence_count;
  end if;


  -- ==========================================================================
  -- Resultado
  -- ==========================================================================

  return jsonb_build_object(
    'created',
      true,
    'outcome',
      'ISSUED',

    'organization_id',
      p_organization_id,
    'organization_member_id',
      p_organization_member_id,

    'certification_program_id',
      v_created.certification_program_id,
    'certification_program_version_id',
      v_created.certification_program_version_id,

    'member_certification_id',
      v_created.id,
    'certificate_number',
      v_created.certificate_number,

    'status',
      v_created.status,
    'issued_at',
      v_created.issued_at,
    'valid_until',
      v_created.valid_until,

    'evidence_count',
      v_evidence_count,

    'evaluation',
      v_evaluation
  );

end;
$function$;


-- ============================================================================
-- 2. SEGURANÇA
-- ============================================================================

revoke all on function
  private.issue_certification_program_version(uuid, uuid, uuid)
from public, anon, authenticated;


comment on function
  private.issue_certification_program_version(uuid, uuid, uuid)
is
  'Emite certificação genérica somente após aprovação do motor privado da Fase 1C, serializa concorrência, mantém idempotência por programa e persiste snapshot auditável das evidências. Não exposta diretamente ao cliente.';


-- ============================================================================
-- 3. POSTCONDITIONS
-- ============================================================================

do $postconditions$
declare
  v_security_definer boolean;
  v_volatility "char";
begin

  if to_regprocedure(
    'private.issue_certification_program_version(uuid,uuid,uuid)'
  ) is null then
    raise exception
      'POSTCONDITION_FAILED: issue_certification_program_version missing';
  end if;


  select
    p.prosecdef,
    p.provolatile
  into
    v_security_definer,
    v_volatility
  from pg_proc p
  where p.oid = to_regprocedure(
    'private.issue_certification_program_version(uuid,uuid,uuid)'
  );


  if v_security_definer is not true then
    raise exception
      'POSTCONDITION_FAILED: issue_certification_program_version must be SECURITY DEFINER';
  end if;


  if v_volatility <> 'v' then
    raise exception
      'POSTCONDITION_FAILED: issue_certification_program_version must be VOLATILE';
  end if;


  -- Se PUBLIC possuísse EXECUTE, anon/authenticated herdariam.
  if has_function_privilege(
    'authenticated',
    'private.issue_certification_program_version(uuid,uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception
      'POSTCONDITION_FAILED: authenticated can execute issue_certification_program_version';
  end if;


  if has_function_privilege(
    'anon',
    'private.issue_certification_program_version(uuid,uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception
      'POSTCONDITION_FAILED: anon can execute issue_certification_program_version';
  end if;

end;
$postconditions$;


commit;
