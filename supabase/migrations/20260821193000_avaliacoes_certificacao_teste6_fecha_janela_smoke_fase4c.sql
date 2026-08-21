-- ============================================================================
-- RF Performance — Avaliações e Certificações
-- Homologação do Catálogo Ampliado
-- Fase 4C — Fechamento da janela controlada do smoke test funcional do Teste 6
--
-- Objetivo:
--   Encerrar a publicação temporária do Teste 6 após smoke test aprovado.
--
-- ESCOPO / SEGURANÇA
--   - Retorna somente o Teste 6 e sua versão 2026.08-v1 para draft.
--   - Remove a validade/publicação temporária da versão.
--   - Preserva integralmente a tentativa homologada, respostas, resultados,
--     scores por competência e o grant já revogado.
--   - Registra em metadata o encerramento e o resultado do smoke test.
--   - Mantém Testes 7 a 12 em draft.
--   - Não altera questões, alternativas, gabaritos, fontes, competências ou cortes.
-- ============================================================================

begin;

do $guard$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
  v_test_id uuid := '77c2984e-c0e8-5829-94ba-fcb0076ce8b6'::uuid;
  v_version_id uuid := '07ed48aa-b1ac-547f-8fa5-a93c1441cc3c'::uuid;
  v_member_id uuid := '49239d09-0f85-471f-8f46-5c240cd98600'::uuid;
  v_attempt_id uuid := '1b59ead6-5380-41cc-94ea-ee7d0158143e'::uuid;
begin
  -- Identidade e estado temporariamente publicado do Teste 6.
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions tv
      on tv.test_id = t.id
     and tv.organization_id = t.organization_id
     and tv.archived_at is null
    where t.organization_id = v_org_id
      and t.id = v_test_id
      and t.sequence_no = 6
      and t.code = 'teste_6_vap_fundamentos_mentalidade_valor'
      and t.status = 'active'
      and t.archived_at is null
      and coalesce((t.metadata ->> 'homologation_window')::boolean, false) = true
      and t.metadata ->> 'homologation_window_scope' = 'functional_smoke_test'
      and tv.id = v_version_id
      and tv.version_code = '2026.08-v1'
      and tv.status = 'published'
      and tv.passing_score = 75
      and tv.legal_min_score = 80
      and tv.question_count = 30
      and tv.valid_from is not null
      and tv.valid_until is not null
      and tv.published_at is not null
      and coalesce((tv.metadata ->> 'homologation_window')::boolean, false) = true
      and tv.metadata ->> 'homologation_window_scope' = 'functional_smoke_test'
      and tv.metadata ->> 'homologation_window_publication' = 'temporary'
      and coalesce((tv.metadata ->> 'homologation_window_requires_member_grant')::boolean, false) = true
  ) then
    raise exception 'Fechamento smoke Teste 6 abortado: identidade/estado da janela temporária não conferem.';
  end if;

  -- O grant do piloto deve ter sido revogado, sem qualquer grant ativo remanescente.
  if exists (
    select 1
    from private.assessment_test_access_grants g
    where g.organization_id = v_org_id
      and g.test_id = v_test_id
      and g.status = 'active'
      and g.archived_at is null
  ) then
    raise exception 'Fechamento smoke Teste 6 abortado: ainda existe grant ativo.';
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
    raise exception 'Fechamento smoke Teste 6 abortado: esperado exatamente 1 grant revogado do piloto.';
  end if;

  -- Deve existir exatamente a tentativa de homologação esperada, já corrigida e aprovada.
  if (
    select count(*)
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.test_id = v_test_id
      and a.test_version_id = v_version_id
      and a.archived_at is null
  ) <> 1 then
    raise exception 'Fechamento smoke Teste 6 abortado: esperado exatamente 1 histórico de tentativa.';
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
      and round(a.legal_score::numeric, 2) = 100.00
      and a.passed is true
      and a.critical_errors = 0
      and a.result_reason = 'approved'
      and a.submitted_at is not null
      and a.graded_at is not null
      and a.archived_at is null
  ) then
    raise exception 'Fechamento smoke Teste 6 abortado: resultado homologado da tentativa não confere.';
  end if;

  if (
    select count(*)
    from public.assessment_attempt_answers aa
    where aa.organization_id = v_org_id
      and aa.attempt_id = v_attempt_id
  ) <> 30 then
    raise exception 'Fechamento smoke Teste 6 abortado: esperado 30 respostas persistidas.';
  end if;

  if (
    select count(*)
    from public.assessment_competency_scores cs
    where cs.organization_id = v_org_id
      and cs.attempt_id = v_attempt_id
  ) <> 4 then
    raise exception 'Fechamento smoke Teste 6 abortado: esperado 4 scores de competência.';
  end if;

  -- Testes 7 a 12 devem permanecer integralmente fora da janela.
  if (
    select count(*)
    from public.assessment_tests t
    join public.assessment_test_versions tv
      on tv.test_id = t.id
     and tv.organization_id = t.organization_id
     and tv.archived_at is null
    where t.organization_id = v_org_id
      and t.sequence_no between 7 and 12
      and t.archived_at is null
      and t.status = 'draft'
      and tv.status = 'draft'
  ) <> 6 then
    raise exception 'Fechamento smoke Teste 6 abortado: Testes 7 a 12 não estão integralmente preservados em draft.';
  end if;
end
$guard$;

-- Fecha a janela no cadastro do teste, preservando a evidência de homologação em metadata.
update public.assessment_tests
set
  status = 'draft',
  metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
    'homologation_window', false,
    'homologation_window_status', 'closed',
    'homologation_smoke_test_status', 'passed',
    'homologation_smoke_test_completed_on', '2026-08-21',
    'homologation_smoke_test_attempt_id', '1b59ead6-5380-41cc-94ea-ee7d0158143e'
  )
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and id = '77c2984e-c0e8-5829-94ba-fcb0076ce8b6'::uuid
  and sequence_no = 6
  and code = 'teste_6_vap_fundamentos_mentalidade_valor'
  and status = 'active'
  and archived_at is null;

-- Retorna a versão a draft e remove somente os marcadores temporais de publicação.
update public.assessment_test_versions
set
  status = 'draft',
  valid_from = null,
  valid_until = null,
  published_at = null,
  metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
    'homologation_window', false,
    'homologation_window_status', 'closed',
    'homologation_window_publication', 'closed',
    'homologation_policy_status', 'smoke_test_passed',
    'homologation_smoke_test_status', 'passed',
    'homologation_smoke_test_completed_on', '2026-08-21',
    'homologation_smoke_test_attempt_id', '1b59ead6-5380-41cc-94ea-ee7d0158143e',
    'homologation_smoke_test_overall_score', 83.33,
    'homologation_smoke_test_legal_score', 100,
    'homologation_smoke_test_correct_answers', 25,
    'homologation_smoke_test_critical_errors', 0
  )
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and id = '07ed48aa-b1ac-547f-8fa5-a93c1441cc3c'::uuid
  and test_id = '77c2984e-c0e8-5829-94ba-fcb0076ce8b6'::uuid
  and version_code = '2026.08-v1'
  and status = 'published'
  and passing_score = 75
  and legal_min_score = 80
  and archived_at is null;

do $postcheck$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
  v_test_id uuid := '77c2984e-c0e8-5829-94ba-fcb0076ce8b6'::uuid;
  v_version_id uuid := '07ed48aa-b1ac-547f-8fa5-a93c1441cc3c'::uuid;
  v_member_id uuid := '49239d09-0f85-471f-8f46-5c240cd98600'::uuid;
  v_attempt_id uuid := '1b59ead6-5380-41cc-94ea-ee7d0158143e'::uuid;
begin
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions tv
      on tv.test_id = t.id
     and tv.organization_id = t.organization_id
     and tv.archived_at is null
    where t.organization_id = v_org_id
      and t.id = v_test_id
      and t.status = 'draft'
      and t.archived_at is null
      and coalesce((t.metadata ->> 'homologation_window')::boolean, true) = false
      and t.metadata ->> 'homologation_window_status' = 'closed'
      and t.metadata ->> 'homologation_smoke_test_status' = 'passed'
      and tv.id = v_version_id
      and tv.status = 'draft'
      and tv.passing_score = 75
      and tv.legal_min_score = 80
      and tv.valid_from is null
      and tv.valid_until is null
      and tv.published_at is null
      and coalesce((tv.metadata ->> 'homologation_window')::boolean, true) = false
      and tv.metadata ->> 'homologation_window_status' = 'closed'
      and tv.metadata ->> 'homologation_policy_status' = 'smoke_test_passed'
      and tv.metadata ->> 'homologation_smoke_test_status' = 'passed'
  ) then
    raise exception 'Fechamento smoke Teste 6 inválido: retorno a draft/metadata não conferiu.';
  end if;

  if exists (
    select 1
    from private.assessment_test_access_grants g
    where g.organization_id = v_org_id
      and g.test_id = v_test_id
      and g.status = 'active'
      and g.archived_at is null
  ) then
    raise exception 'Fechamento smoke Teste 6 inválido: grant ativo reapareceu.';
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
    raise exception 'Fechamento smoke Teste 6 inválido: histórico do grant revogado foi alterado.';
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
      and a.total_questions = 30
      and a.answered_questions = 30
      and a.correct_answers = 25
      and round(a.overall_score::numeric, 2) = 83.33
      and round(a.legal_score::numeric, 2) = 100.00
      and a.passed is true
      and a.critical_errors = 0
      and a.result_reason = 'approved'
      and a.archived_at is null
  ) then
    raise exception 'Fechamento smoke Teste 6 inválido: histórico da tentativa foi alterado.';
  end if;

  if (
    select count(*)
    from public.assessment_attempt_answers aa
    where aa.organization_id = v_org_id
      and aa.attempt_id = v_attempt_id
  ) <> 30 then
    raise exception 'Fechamento smoke Teste 6 inválido: respostas da tentativa foram alteradas.';
  end if;

  if (
    select count(*)
    from public.assessment_competency_scores cs
    where cs.organization_id = v_org_id
      and cs.attempt_id = v_attempt_id
  ) <> 4 then
    raise exception 'Fechamento smoke Teste 6 inválido: scores de competência foram alterados.';
  end if;

  if (
    select count(*)
    from public.assessment_tests t
    join public.assessment_test_versions tv
      on tv.test_id = t.id
     and tv.organization_id = t.organization_id
     and tv.archived_at is null
    where t.organization_id = v_org_id
      and t.sequence_no between 7 and 12
      and t.archived_at is null
      and t.status = 'draft'
      and tv.status = 'draft'
  ) <> 6 then
    raise exception 'Fechamento smoke Teste 6 inválido: Testes 7 a 12 foram alterados.';
  end if;
end
$postcheck$;

commit;
