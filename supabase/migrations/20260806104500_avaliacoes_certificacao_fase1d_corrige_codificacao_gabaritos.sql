-- ============================================================================
-- RF Performance — Avaliações e Certificações — Fase 1D
-- Correção auditável da codificação dos textos privados dos gabaritos
--
-- Objetivos:
--   1. corrigir mojibake WIN1252 -> UTF8 em justificativas e referências;
--   2. preservar integralmente os textos anteriores em tabela privada de auditoria;
--   3. não alterar alternativas corretas, criticidade, tentativas, notas ou certificados;
--   4. manter a tabela de auditoria sem acesso direto pelo navegador.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- Preflight estrito
-- ----------------------------------------------------------------------------

do $preflight$
declare
  v_total_keys integer;
  v_justification_candidates integer;
  v_reference_candidates integer;
  v_critical_reason_candidates integer;
  v_justification_still_suspect integer;
  v_reference_still_suspect integer;
  v_critical_reason_still_suspect integer;
begin
  if to_regclass('private.assessment_question_keys') is null then
    raise exception 'ASSESSMENT_QUESTION_KEYS_NOT_FOUND';
  end if;

  if to_regclass('private.assessment_question_key_text_repairs') is not null then
    raise exception 'ENCODING_REPAIR_AUDIT_TABLE_ALREADY_EXISTS';
  end if;

  if not exists (
    select 1
    from public.organizations o
    where o.id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and o.status = 'active'
  ) then
    raise exception 'TARGET_ORGANIZATION_NOT_ACTIVE';
  end if;

  select
    count(*)::integer,
    count(*) filter (
      where coalesce(qk.justification, '') ~
        '(Ã.|Â.|â€”|â€“|â€œ|â€|â€™|â€¦|�)'
    )::integer,
    count(*) filter (
      where coalesce(qk.source_reference, '') ~
        '(Ã.|Â.|â€”|â€“|â€œ|â€|â€™|â€¦|�)'
    )::integer,
    count(*) filter (
      where coalesce(qk.critical_reason, '') ~
        '(Ã.|Â.|â€”|â€“|â€œ|â€|â€™|â€¦|�)'
    )::integer
  into
    v_total_keys,
    v_justification_candidates,
    v_reference_candidates,
    v_critical_reason_candidates
  from private.assessment_question_keys qk
  where qk.organization_id =
    '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;

  if v_total_keys <> 150 then
    raise exception 'PRIVATE_KEY_COUNT_MISMATCH: %', v_total_keys;
  end if;

  if v_justification_candidates <> 149 then
    raise exception 'JUSTIFICATION_CANDIDATE_COUNT_MISMATCH: %',
      v_justification_candidates;
  end if;

  if v_reference_candidates <> 150 then
    raise exception 'SOURCE_REFERENCE_CANDIDATE_COUNT_MISMATCH: %',
      v_reference_candidates;
  end if;

  if v_critical_reason_candidates <> 0 then
    raise exception 'CRITICAL_REASON_MUST_NOT_BE_CONVERTED: %',
      v_critical_reason_candidates;
  end if;

  select
    count(*) filter (
      where coalesce(
        case
          when coalesce(qk.justification, '') ~
            '(Ã.|Â.|â€”|â€“|â€œ|â€|â€™|â€¦|�)'
          then convert_from(convert_to(qk.justification, 'WIN1252'), 'UTF8')
          else qk.justification
        end,
        ''
      ) ~ '(Ã.|Â.|â€”|â€“|â€œ|â€|â€™|â€¦|�)'
    )::integer,
    count(*) filter (
      where coalesce(
        case
          when coalesce(qk.source_reference, '') ~
            '(Ã.|Â.|â€”|â€“|â€œ|â€|â€™|â€¦|�)'
          then convert_from(convert_to(qk.source_reference, 'WIN1252'), 'UTF8')
          else qk.source_reference
        end,
        ''
      ) ~ '(Ã.|Â.|â€”|â€“|â€œ|â€|â€™|â€¦|�)'
    )::integer,
    count(*) filter (
      where coalesce(
        case
          when coalesce(qk.critical_reason, '') ~
            '(Ã.|Â.|â€”|â€“|â€œ|â€|â€™|â€¦|�)'
          then convert_from(convert_to(qk.critical_reason, 'WIN1252'), 'UTF8')
          else qk.critical_reason
        end,
        ''
      ) ~ '(Ã.|Â.|â€”|â€“|â€œ|â€|â€™|â€¦|�)'
    )::integer
  into
    v_justification_still_suspect,
    v_reference_still_suspect,
    v_critical_reason_still_suspect
  from private.assessment_question_keys qk
  where qk.organization_id =
    '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;

  if v_justification_still_suspect <> 0
     or v_reference_still_suspect <> 0
     or v_critical_reason_still_suspect <> 0 then
    raise exception
      'ENCODING_CONVERSION_PREFLIGHT_FAILED: justification=%, reference=%, critical_reason=%',
      v_justification_still_suspect,
      v_reference_still_suspect,
      v_critical_reason_still_suspect;
  end if;

  if (
    select count(*)
    from private.assessment_question_keys qk
    where qk.organization_id =
      '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and qk.is_critical
  ) <> 0 then
    raise exception 'CRITICAL_FAILURE_KEYS_MUST_REMAIN_DISABLED';
  end if;

  if (
    select count(*) filter (where qk.correct_option_code = 'A') = 38
       and count(*) filter (where qk.correct_option_code = 'B') = 38
       and count(*) filter (where qk.correct_option_code = 'C') = 37
       and count(*) filter (where qk.correct_option_code = 'D') = 37
    from private.assessment_question_keys qk
    where qk.organization_id =
      '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  ) is not true then
    raise exception 'ANSWER_KEY_DISTRIBUTION_PREFLIGHT_FAILED';
  end if;
end;
$preflight$;

-- ----------------------------------------------------------------------------
-- Auditoria privada e inacessível ao navegador
-- ----------------------------------------------------------------------------

create table private.assessment_question_key_text_repairs (
  organization_id uuid not null,
  question_id uuid not null,
  repair_code text not null,
  correct_option_code_before text not null,
  is_critical_before boolean not null,
  justification_before text not null,
  justification_after text not null,
  source_reference_before text not null,
  source_reference_after text not null,
  critical_reason_before text,
  critical_reason_after text,
  reviewed_by_before uuid,
  reviewed_at_before timestamptz,
  created_at_before timestamptz not null,
  created_by_before uuid,
  updated_at_before timestamptz not null,
  updated_by_before uuid,
  metadata_before jsonb not null,
  repaired_at timestamptz not null default now(),
  repair_metadata jsonb not null default '{}'::jsonb,
  constraint assessment_question_key_text_repairs_pkey
    primary key (organization_id, question_id, repair_code),
  constraint assessment_question_key_text_repairs_question_org_fkey
    foreign key (question_id, organization_id)
    references public.assessment_questions(id, organization_id)
    on delete restrict,
  constraint assessment_question_key_text_repairs_option_check
    check (correct_option_code_before in ('A', 'B', 'C', 'D')),
  constraint assessment_question_key_text_repairs_metadata_before_check
    check (jsonb_typeof(metadata_before) = 'object'),
  constraint assessment_question_key_text_repairs_repair_metadata_check
    check (jsonb_typeof(repair_metadata) = 'object')
);

alter table private.assessment_question_key_text_repairs
  enable row level security;

alter table private.assessment_question_key_text_repairs
  force row level security;

revoke all on table private.assessment_question_key_text_repairs
  from public, anon, authenticated;

comment on table private.assessment_question_key_text_repairs is
  'Auditoria privada da correção WIN1252 para UTF8 dos textos dos gabaritos. Não expor por SELECT direto ao cliente.';

-- ----------------------------------------------------------------------------
-- Snapshot antes/depois
-- ----------------------------------------------------------------------------

insert into private.assessment_question_key_text_repairs (
  organization_id,
  question_id,
  repair_code,
  correct_option_code_before,
  is_critical_before,
  justification_before,
  justification_after,
  source_reference_before,
  source_reference_after,
  critical_reason_before,
  critical_reason_after,
  reviewed_by_before,
  reviewed_at_before,
  created_at_before,
  created_by_before,
  updated_at_before,
  updated_by_before,
  metadata_before,
  repair_metadata
)
select
  qk.organization_id,
  qk.question_id,
  '20260806104500_win1252_to_utf8',
  qk.correct_option_code,
  qk.is_critical,
  qk.justification,
  case
    when coalesce(qk.justification, '') ~
      '(Ã.|Â.|â€”|â€“|â€œ|â€|â€™|â€¦|�)'
    then convert_from(convert_to(qk.justification, 'WIN1252'), 'UTF8')
    else qk.justification
  end,
  qk.source_reference,
  case
    when coalesce(qk.source_reference, '') ~
      '(Ã.|Â.|â€”|â€“|â€œ|â€|â€™|â€¦|�)'
    then convert_from(convert_to(qk.source_reference, 'WIN1252'), 'UTF8')
    else qk.source_reference
  end,
  qk.critical_reason,
  qk.critical_reason,
  qk.reviewed_by,
  qk.reviewed_at,
  qk.created_at,
  qk.created_by,
  qk.updated_at,
  qk.updated_by,
  qk.metadata,
  jsonb_build_object(
    'migration',
      '20260806104500_avaliacoes_certificacao_fase1d_corrige_codificacao_gabaritos',
    'source_encoding', 'WIN1252',
    'target_encoding', 'UTF8',
    'repair_scope', 'justification_and_source_reference',
    'preflight_verified', true
  )
from private.assessment_question_keys qk
where qk.organization_id =
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;

-- ----------------------------------------------------------------------------
-- Correção determinística
-- ----------------------------------------------------------------------------

do $repair$
declare
  v_updated_rows integer;
begin
  update private.assessment_question_keys qk
  set justification = repair.justification_after,
      source_reference = repair.source_reference_after,
      updated_at = now(),
      metadata = qk.metadata || jsonb_build_object(
        'encoding_repair_20260806104500',
        jsonb_build_object(
          'repair_code', repair.repair_code,
          'source_encoding', 'WIN1252',
          'target_encoding', 'UTF8',
          'audit_table', 'private.assessment_question_key_text_repairs',
          'repaired_at', now()
        )
      )
  from private.assessment_question_key_text_repairs repair
  where repair.organization_id = qk.organization_id
    and repair.question_id = qk.question_id
    and repair.repair_code = '20260806104500_win1252_to_utf8'
    and qk.organization_id =
      '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;

  get diagnostics v_updated_rows = row_count;

  if v_updated_rows <> 150 then
    raise exception 'ENCODING_REPAIR_UPDATED_ROW_COUNT_MISMATCH: %',
      v_updated_rows;
  end if;
end;
$repair$;

-- ----------------------------------------------------------------------------
-- Pós-condições estritas
-- ----------------------------------------------------------------------------

do $postconditions$
declare
  v_audit_rows integer;
  v_justification_suspects integer;
  v_reference_suspects integer;
  v_critical_reason_suspects integer;
begin
  select count(*)::integer
  into v_audit_rows
  from private.assessment_question_key_text_repairs repair
  where repair.organization_id =
      '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and repair.repair_code = '20260806104500_win1252_to_utf8';

  if v_audit_rows <> 150 then
    raise exception 'ENCODING_REPAIR_AUDIT_ROW_COUNT_MISMATCH: %',
      v_audit_rows;
  end if;

  select
    count(*) filter (
      where coalesce(qk.justification, '') ~
        '(Ã.|Â.|â€”|â€“|â€œ|â€|â€™|â€¦|�)'
    )::integer,
    count(*) filter (
      where coalesce(qk.source_reference, '') ~
        '(Ã.|Â.|â€”|â€“|â€œ|â€|â€™|â€¦|�)'
    )::integer,
    count(*) filter (
      where coalesce(qk.critical_reason, '') ~
        '(Ã.|Â.|â€”|â€“|â€œ|â€|â€™|â€¦|�)'
    )::integer
  into
    v_justification_suspects,
    v_reference_suspects,
    v_critical_reason_suspects
  from private.assessment_question_keys qk
  where qk.organization_id =
    '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;

  if v_justification_suspects <> 0
     or v_reference_suspects <> 0
     or v_critical_reason_suspects <> 0 then
    raise exception
      'ENCODING_REPAIR_POSTCONDITION_FAILED: justification=%, reference=%, critical_reason=%',
      v_justification_suspects,
      v_reference_suspects,
      v_critical_reason_suspects;
  end if;

  if exists (
    select 1
    from private.assessment_question_key_text_repairs repair
    join private.assessment_question_keys qk
      on qk.organization_id = repair.organization_id
     and qk.question_id = repair.question_id
    where repair.organization_id =
        '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and repair.repair_code = '20260806104500_win1252_to_utf8'
      and (
        qk.correct_option_code <> repair.correct_option_code_before
        or qk.is_critical <> repair.is_critical_before
        or qk.critical_reason is distinct from repair.critical_reason_before
        or qk.reviewed_by is distinct from repair.reviewed_by_before
        or qk.reviewed_at is distinct from repair.reviewed_at_before
        or qk.created_at is distinct from repair.created_at_before
        or qk.created_by is distinct from repair.created_by_before
        or qk.updated_by is distinct from repair.updated_by_before
      )
  ) then
    raise exception 'NON_TEXT_ANSWER_KEY_FIELDS_CHANGED';
  end if;

  if (
    select count(*) filter (where qk.correct_option_code = 'A') = 38
       and count(*) filter (where qk.correct_option_code = 'B') = 38
       and count(*) filter (where qk.correct_option_code = 'C') = 37
       and count(*) filter (where qk.correct_option_code = 'D') = 37
    from private.assessment_question_keys qk
    where qk.organization_id =
      '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  ) is not true then
    raise exception 'ANSWER_KEY_DISTRIBUTION_POSTCONDITION_FAILED';
  end if;

  if (
    select count(*)
    from private.assessment_question_keys qk
    where qk.organization_id =
      '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and qk.is_critical
  ) <> 0 then
    raise exception 'CRITICAL_FAILURE_KEYS_CHANGED';
  end if;
end;
$postconditions$;

commit;
