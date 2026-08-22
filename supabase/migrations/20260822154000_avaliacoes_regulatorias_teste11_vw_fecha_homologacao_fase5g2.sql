-- ============================================================================
-- RF Performance — Avaliações e Certificações
-- Homologação Regulatória
-- Fase 5G2 — Fechamento da homologação funcional do Teste 11 Volkswagen
--
-- Objetivo:
--   Encerrar de forma auditável a janela temporária da Fase 5G1 após o smoke
--   funcional completo do Teste 11 — Volkswagen.
--
-- ESCOPO / SEGURANÇA
--   - Revoga somente o grant ativo do participante piloto.
--   - Retorna somente o Teste 11 e a versão cnvw-v3.0-v1 para draft.
--   - Remove os marcadores temporais de publicação da versão.
--   - Preserva integralmente a tentativa homologada, snapshot, respostas,
--     resultado e scores por competência.
--   - Mantém a política regulatória 90/90.
--   - Mantém o Teste 12 — Fiat integralmente em draft.
--   - Não altera questões, alternativas, gabaritos, fontes ou competências.
-- ============================================================================

begin;

do $guard$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
  v_test_id uuid := 'dd671e5f-39ec-5018-9263-78613361a7db'::uuid;
  v_version_id uuid := 'fcf8f979-c44e-5993-beef-d023312ab5b7'::uuid;
  v_member_id uuid := '49239d09-0f85-471f-8f46-5c240cd98600'::uuid;
  v_attempt_id uuid := 'ea94b2a3-906f-450f-94cc-67dd9a98709d'::uuid;

  v_fiat_test_id uuid := '61d013e4-3b4b-5676-b39c-6d340f87b046'::uuid;
  v_fiat_version_id uuid := '74243315-ea1e-5178-83b8-d6077ab9dc59'::uuid;
begin
  -- Identidade/estado da janela temporária já expirada.
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.organization_id = t.organization_id
     and v.test_id = t.id
     and v.id = v_version_id
     and v.archived_at is null
    where t.organization_id = v_org_id
      and t.id = v_test_id
      and t.sequence_no = 11
      and t.code = 'regulamento_vw_cnvw_v1'
      and t.title = 'Avaliação Regulamentar — Consórcio Volkswagen'
      and t.description =
          'Avaliação de conhecimento sobre o Regulamento do Contrato de Consórcio CNVW/Embracon, Versão 3.0, estruturada em oito blocos temáticos.'
      and t.status = 'active'
      and t.archived_at is null
      and coalesce((t.metadata->>'homologation_window')::boolean, false) = true
      and t.metadata->>'homologation_window_phase' = '5G1'
      and v.version_code = 'cnvw-v3.0-v1'
      and v.status = 'published'
      and v.passing_score = 90
      and v.legal_min_score = 90
      and v.question_count = 30
      and v.valid_from is not null
      and v.valid_until is not null
      and v.valid_until < now()
      and v.published_at is not null
      and v.metadata->>'approval_policy_status' = 'approved'
      and v.metadata->>'approval_policy_phase' = '5F'
      and coalesce((v.metadata->>'homologation_window')::boolean, false) = true
      and v.metadata->>'homologation_window_phase' = '5G1'
      and v.metadata->>'homologation_window_publication' = 'temporary'
      and coalesce((v.metadata->>'homologation_window_requires_member_grant')::boolean, false) = true
  ) then
    raise exception
      'FASE5G2_ABORT: identidade/estado da janela temporaria expirada do Teste 11 nao conferem.';
  end if;

  -- Deve existir exatamente um grant ativo, e ele deve ser o grant individual do piloto.
  if (
    select count(*)
    from private.assessment_test_access_grants g
    where g.organization_id = v_org_id
      and g.test_id = v_test_id
      and g.status = 'active'
      and g.archived_at is null
  ) <> 1 then
    raise exception
      'FASE5G2_ABORT: esperado exatamente 1 grant ativo no Teste 11.';
  end if;

  if (
    select count(*)
    from private.assessment_test_access_grants g
    where g.organization_id = v_org_id
      and g.test_id = v_test_id
      and g.test_version_id = v_version_id
      and g.access_scope = 'member'
      and g.organization_member_id = v_member_id
      and g.status = 'active'
      and g.archived_at is null
  ) <> 1 then
    raise exception
      'FASE5G2_ABORT: grant ativo esperado do participante piloto nao confere.';
  end if;

  -- A tentativa funcional deve estar completamente corrigida e preservada.
  if (
    select count(*)
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.test_id = v_test_id
      and a.test_version_id = v_version_id
      and a.archived_at is null
  ) <> 1 then
    raise exception
      'FASE5G2_ABORT: esperado exatamente 1 historico de tentativa do Teste 11.';
  end if;

  if not exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.id = v_attempt_id
      and a.test_id = v_test_id
      and a.test_version_id = v_version_id
      and a.organization_member_id = v_member_id
      and a.status = 'graded'
      and a.attempt_no = 1
      and a.total_questions = 30
      and a.answered_questions = 30
      and a.correct_answers = 25
      and round(a.overall_score::numeric, 2) = 83.33
      and round(a.legal_score::numeric, 2) = 83.33
      and a.critical_errors = 0
      and a.passed is false
      and a.result_reason = 'overall_score_below_minimum'
      and a.submitted_at is not null
      and a.graded_at is not null
      and a.archived_at is null
  ) then
    raise exception
      'FASE5G2_ABORT: resultado homologado da tentativa do Teste 11 nao confere.';
  end if;

  if (
    select count(*)
    from public.assessment_attempt_items ai
    where ai.organization_id = v_org_id
      and ai.attempt_id = v_attempt_id
  ) <> 30 then
    raise exception
      'FASE5G2_ABORT: esperado snapshot com 30 itens.';
  end if;

  if (
    select count(*)
    from public.assessment_attempt_answers aa
    where aa.organization_id = v_org_id
      and aa.attempt_id = v_attempt_id
  ) <> 30 then
    raise exception
      'FASE5G2_ABORT: esperado 30 respostas persistidas.';
  end if;

  if (
    select count(*)
    from public.assessment_competency_scores cs
    where cs.organization_id = v_org_id
      and cs.attempt_id = v_attempt_id
  ) <> 8 then
    raise exception
      'FASE5G2_ABORT: esperado 8 scores de competencia.';
  end if;

  -- Fiat continua completamente fechado.
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.organization_id = t.organization_id
     and v.test_id = t.id
     and v.id = v_fiat_version_id
     and v.archived_at is null
    where t.organization_id = v_org_id
      and t.id = v_fiat_test_id
      and t.sequence_no = 12
      and t.code = 'regulamento_fiat_v1'
      and t.status = 'draft'
      and t.archived_at is null
      and v.version_code = 'fiat-v3-v1'
      and v.status = 'draft'
      and v.passing_score = 90
      and v.legal_min_score = 90
      and v.published_at is null
  ) then
    raise exception
      'FASE5G2_ABORT: Teste 12 Fiat nao esta no estado fechado esperado.';
  end if;
end
$guard$;

-- ============================================================================
-- 1. Revoga somente o grant individual residual do piloto.
-- ============================================================================

update private.assessment_test_access_grants
set
  status = 'revoked',
  valid_until = case
    when valid_until is null or valid_until > now() then now()
    else valid_until
  end,
  updated_at = now(),
  metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
    'revoked_from', 'homologation_closure_migration',
    'revoked_at', now(),
    'homologation_phase', '5G2',
    'homologation_test_number', 11
  )
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and test_id = 'dd671e5f-39ec-5018-9263-78613361a7db'::uuid
  and test_version_id = 'fcf8f979-c44e-5993-beef-d023312ab5b7'::uuid
  and access_scope = 'member'
  and organization_member_id = '49239d09-0f85-471f-8f46-5c240cd98600'::uuid
  and status = 'active'
  and archived_at is null;

-- ============================================================================
-- 2. Fecha a janela no cadastro do Teste 11.
-- ============================================================================

update public.assessment_tests
set
  status = 'draft',
  metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
    'homologation_window', false,
    'homologation_window_status', 'closed',
    'homologation_window_phase', '5G2',
    'homologation_functional_status', 'passed',
    'homologation_functional_completed_on', '2026-08-22',
    'homologation_functional_attempt_id',
      'ea94b2a3-906f-450f-94cc-67dd9a98709d'
  )
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and id = 'dd671e5f-39ec-5018-9263-78613361a7db'::uuid
  and sequence_no = 11
  and code = 'regulamento_vw_cnvw_v1'
  and status = 'active'
  and archived_at is null;

-- ============================================================================
-- 3. Retorna a versão homologada a draft, preservando a política 90/90.
-- ============================================================================

update public.assessment_test_versions
set
  status = 'draft',
  valid_from = null,
  valid_until = null,
  published_at = null,
  metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
    'homologation_window', false,
    'homologation_window_status', 'closed',
    'homologation_window_phase', '5G2',
    'homologation_window_publication', 'closed',
    'homologation_functional_status', 'passed',
    'homologation_functional_completed_on', '2026-08-22',
    'homologation_functional_attempt_id',
      'ea94b2a3-906f-450f-94cc-67dd9a98709d',
    'homologation_functional_attempt_passed', false,
    'homologation_functional_overall_score', 83.33,
    'homologation_functional_legal_score', 83.33,
    'homologation_functional_correct_answers', 25,
    'homologation_functional_critical_errors', 0
  )
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and id = 'fcf8f979-c44e-5993-beef-d023312ab5b7'::uuid
  and test_id = 'dd671e5f-39ec-5018-9263-78613361a7db'::uuid
  and version_code = 'cnvw-v3.0-v1'
  and status = 'published'
  and passing_score = 90
  and legal_min_score = 90
  and archived_at is null;

-- ============================================================================
-- Pós-check fail-closed.
-- ============================================================================

do $postcheck$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
  v_test_id uuid := 'dd671e5f-39ec-5018-9263-78613361a7db'::uuid;
  v_version_id uuid := 'fcf8f979-c44e-5993-beef-d023312ab5b7'::uuid;
  v_member_id uuid := '49239d09-0f85-471f-8f46-5c240cd98600'::uuid;
  v_attempt_id uuid := 'ea94b2a3-906f-450f-94cc-67dd9a98709d'::uuid;

  v_fiat_test_id uuid := '61d013e4-3b4b-5676-b39c-6d340f87b046'::uuid;
  v_fiat_version_id uuid := '74243315-ea1e-5178-83b8-d6077ab9dc59'::uuid;
begin
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.organization_id = t.organization_id
     and v.test_id = t.id
     and v.id = v_version_id
     and v.archived_at is null
    where t.organization_id = v_org_id
      and t.id = v_test_id
      and t.status = 'draft'
      and t.archived_at is null
      and coalesce((t.metadata->>'homologation_window')::boolean, true) = false
      and t.metadata->>'homologation_window_status' = 'closed'
      and t.metadata->>'homologation_window_phase' = '5G2'
      and t.metadata->>'homologation_functional_status' = 'passed'
      and v.version_code = 'cnvw-v3.0-v1'
      and v.status = 'draft'
      and v.passing_score = 90
      and v.legal_min_score = 90
      and v.valid_from is null
      and v.valid_until is null
      and v.published_at is null
      and coalesce((v.metadata->>'homologation_window')::boolean, true) = false
      and v.metadata->>'homologation_window_status' = 'closed'
      and v.metadata->>'homologation_window_phase' = '5G2'
      and v.metadata->>'homologation_window_publication' = 'closed'
      and v.metadata->>'homologation_functional_status' = 'passed'
  ) then
    raise exception
      'FASE5G2_ABORT: fechamento/retorno a draft do Teste 11 nao conferiu.';
  end if;

  if exists (
    select 1
    from private.assessment_test_access_grants g
    where g.organization_id = v_org_id
      and g.test_id = v_test_id
      and g.status = 'active'
      and g.archived_at is null
  ) then
    raise exception
      'FASE5G2_ABORT: permaneceu grant ativo no Teste 11.';
  end if;

  if (
    select count(*)
    from private.assessment_test_access_grants g
    where g.organization_id = v_org_id
      and g.test_id = v_test_id
      and g.test_version_id = v_version_id
      and g.access_scope = 'member'
      and g.organization_member_id = v_member_id
      and g.status = 'revoked'
      and g.archived_at is null
  ) <> 1 then
    raise exception
      'FASE5G2_ABORT: grant revogado do piloto nao conferiu.';
  end if;

  -- A tentativa histórica não pode sofrer qualquer alteração material.
  if not exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.id = v_attempt_id
      and a.test_id = v_test_id
      and a.test_version_id = v_version_id
      and a.organization_member_id = v_member_id
      and a.status = 'graded'
      and a.attempt_no = 1
      and a.total_questions = 30
      and a.answered_questions = 30
      and a.correct_answers = 25
      and round(a.overall_score::numeric, 2) = 83.33
      and round(a.legal_score::numeric, 2) = 83.33
      and a.critical_errors = 0
      and a.passed is false
      and a.result_reason = 'overall_score_below_minimum'
      and a.submitted_at is not null
      and a.graded_at is not null
      and a.archived_at is null
  ) then
    raise exception
      'FASE5G2_ABORT: tentativa historica do Teste 11 foi alterada.';
  end if;

  if (
    select count(*)
    from public.assessment_attempt_answers aa
    where aa.organization_id = v_org_id
      and aa.attempt_id = v_attempt_id
  ) <> 30 then
    raise exception
      'FASE5G2_ABORT: respostas historicas do Teste 11 foram alteradas.';
  end if;

  if (
    select count(*)
    from public.assessment_competency_scores cs
    where cs.organization_id = v_org_id
      and cs.attempt_id = v_attempt_id
  ) <> 8 then
    raise exception
      'FASE5G2_ABORT: scores historicos do Teste 11 foram alterados.';
  end if;

  -- Fiat permanece integralmente fechado.
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.organization_id = t.organization_id
     and v.test_id = t.id
     and v.id = v_fiat_version_id
     and v.archived_at is null
    where t.organization_id = v_org_id
      and t.id = v_fiat_test_id
      and t.sequence_no = 12
      and t.code = 'regulamento_fiat_v1'
      and t.status = 'draft'
      and t.archived_at is null
      and v.version_code = 'fiat-v3-v1'
      and v.status = 'draft'
      and v.passing_score = 90
      and v.legal_min_score = 90
      and v.published_at is null
  ) then
    raise exception
      'FASE5G2_ABORT: Teste 12 Fiat foi alterado indevidamente.';
  end if;
end
$postcheck$;

commit;
