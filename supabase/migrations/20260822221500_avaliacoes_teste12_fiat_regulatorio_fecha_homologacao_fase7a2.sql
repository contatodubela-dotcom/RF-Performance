begin;

do $$
declare
  v_org_id constant uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654';

  -- Teste 12 — Fiat regulatório
  v_test12_id constant uuid := '61d013e4-3b4b-5676-b39c-6d340f87b046';
  v_test12_version_id constant uuid := '74243315-ea1e-5178-83b8-d6077ab9dc59';
  v_attempt_id constant uuid := '8658e309-7fa8-403e-92e5-3f7967ae38d5';

  -- Controles de isolamento
  v_test11_id constant uuid := 'dd671e5f-39ec-5018-9263-78613361a7db';
  v_test11_version_id constant uuid := 'fcf8f979-c44e-5993-beef-d023312ab5b7';

  v_test13_id constant uuid := '4f97740e-3f9e-559e-b120-cd043a42c755';
  v_test13_version_id constant uuid := '58b09fe5-2bc5-5803-ab0a-2a8834c85607';

  v_count bigint;
begin
  -- Guarda 1: Teste 12 deve estar exatamente na janela temporária aberta pela Fase 7A1.
  if not exists (
    select 1
    from public.assessment_tests t
    where t.id = v_test12_id
      and t.organization_id = v_org_id
      and t.code = 'regulamento_fiat_v1'
      and t.status = 'active'
      and t.metadata ->> 'homologation_phase' = '7A1'
      and coalesce((t.metadata ->> 'homologation_window')::boolean, false) = true
  ) then
    raise exception
      'FASE7A2_ABORT: Teste 12 Fiat não está na janela ativa esperada da Fase 7A1.';
  end if;

  -- Guarda 2: versão Fiat publicada, mantendo a política 90/90.
  if not exists (
    select 1
    from public.assessment_test_versions v
    where v.id = v_test12_version_id
      and v.organization_id = v_org_id
      and v.test_id = v_test12_id
      and v.version_code = 'fiat-v3-v1'
      and v.version_no = 1
      and v.status = 'published'
      and v.passing_score = 90.00
      and v.legal_min_score = 90.00
      and v.metadata ->> 'homologation_phase' = '7A1'
      and coalesce((v.metadata ->> 'homologation_window')::boolean, false) = true
  ) then
    raise exception
      'FASE7A2_ABORT: versão do Teste 12 Fiat divergiu do baseline publicado 90/90 da Fase 7A1.';
  end if;

  -- Guarda 3: conteúdo e fonte do Teste 12 continuam íntegros.
  select count(*)
    into v_count
  from public.assessment_version_questions avq
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_test12_version_id
    and avq.archived_at is null;

  if v_count <> 30 then
    raise exception
      'FASE7A2_ABORT: Teste 12 Fiat deveria manter 30 questões ativas; encontrado %.', v_count;
  end if;

  select count(*)
    into v_count
  from public.assessment_version_sources avs
  where avs.organization_id = v_org_id
    and avs.test_version_id = v_test12_version_id
    and avs.archived_at is null
    and avs.is_required = true;

  if v_count <> 1 then
    raise exception
      'FASE7A2_ABORT: Teste 12 Fiat deveria manter 1 fonte obrigatória ativa; encontrado %.', v_count;
  end if;

  select count(*)
    into v_count
  from public.assessment_version_sources avs
  where avs.organization_id = v_org_id
    and avs.test_version_id = v_test12_version_id
    and avs.archived_at is null;

  if v_count <> 1 then
    raise exception
      'FASE7A2_ABORT: Teste 12 Fiat deveria manter exatamente 1 fonte ativa; encontrado %.', v_count;
  end if;

  -- Guarda 4: tentativa funcional deve existir com o resultado observado na homologação.
  -- A reprovação do participante é esperada e valida a aplicação da política 90/90.
  if not exists (
    select 1
    from public.assessment_attempts a
    where a.id = v_attempt_id
      and a.organization_id = v_org_id
      and a.status = 'graded'
      and a.attempt_no = 1
      and a.total_questions = 30
      and a.answered_questions = 30
      and a.correct_answers = 26
      and a.overall_score = 86.67
      and a.legal_score = 86.67
      and a.critical_errors = 0
      and a.passed = false
      and a.result_reason = 'overall_score_below_minimum'
      and a.submitted_at is not null
      and a.graded_at is not null
  ) then
    raise exception
      'FASE7A2_ABORT: tentativa homologada do Teste 12 Fiat ausente ou resultado divergente.';
  end if;

  -- Guarda 5: Teste 11 VW regulatório permanece fechado e protegido.
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v on v.test_id = t.id
    where t.id = v_test11_id
      and t.organization_id = v_org_id
      and t.code = 'regulamento_vw_cnvw_v1'
      and t.status = 'draft'
      and v.id = v_test11_version_id
      and v.organization_id = v_org_id
      and v.version_code = 'cnvw-v3.0-v1'
      and v.version_no = 1
      and v.status = 'draft'
      and v.passing_score = 90.00
      and v.legal_min_score = 90.00
  ) then
    raise exception
      'FASE7A2_ABORT: Teste 11 VW regulatório não está no baseline protegido esperado.';
  end if;

  -- Guarda 6: Teste 13 VW comercial permanece fechado e protegido.
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v on v.test_id = t.id
    where t.id = v_test13_id
      and t.organization_id = v_org_id
      and t.code = 'consorcio_vw_comercial_v1'
      and t.status = 'draft'
      and v.id = v_test13_version_id
      and v.organization_id = v_org_id
      and v.version_code = 'cnvw-v3.0-comercial-v2'
      and v.version_no = 2
      and v.status = 'draft'
      and v.passing_score = 85.00
      and v.legal_min_score = 90.00
  ) then
    raise exception
      'FASE7A2_ABORT: Teste 13 VW comercial não está no baseline protegido esperado.';
  end if;

  -- Fechamento da janela temporária: somente Teste 12 Fiat.
  update public.assessment_tests
  set
    status = 'draft',
    metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
      'homologation_phase', '7A2',
      'homologation_window', false,
      'homologation_closed_at', now(),
      'homologation_scope', 'teste12_fiat_regulatorio',
      'homologation_result', 'validated',
      'homologation_attempt_id', v_attempt_id::text,
      'homologation_attempt_outcome', 'not_approved'
    )
  where id = v_test12_id
    and organization_id = v_org_id
    and status = 'active';

  if not found then
    raise exception
      'FASE7A2_ABORT: falha ao devolver o Teste 12 Fiat para draft.';
  end if;

  update public.assessment_test_versions
  set
    status = 'draft',
    metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
      'homologation_phase', '7A2',
      'homologation_window', false,
      'homologation_closed_at', now(),
      'homologation_scope', 'teste12_fiat_regulatorio',
      'homologation_result', 'validated',
      'homologation_attempt_id', v_attempt_id::text,
      'homologation_attempt_outcome', 'not_approved'
    )
  where id = v_test12_version_id
    and organization_id = v_org_id
    and test_id = v_test12_id
    and status = 'published'
    and passing_score = 90.00
    and legal_min_score = 90.00;

  if not found then
    raise exception
      'FASE7A2_ABORT: falha ao devolver a versão do Teste 12 Fiat para draft.';
  end if;

  -- Pós-condição 1: Teste 12 fechado, política preservada e homologação registrada.
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v on v.test_id = t.id
    where t.id = v_test12_id
      and t.organization_id = v_org_id
      and t.status = 'draft'
      and t.metadata ->> 'homologation_phase' = '7A2'
      and coalesce((t.metadata ->> 'homologation_window')::boolean, true) = false
      and t.metadata ->> 'homologation_result' = 'validated'
      and t.metadata ->> 'homologation_attempt_id' = v_attempt_id::text
      and t.metadata ->> 'homologation_attempt_outcome' = 'not_approved'
      and v.id = v_test12_version_id
      and v.organization_id = v_org_id
      and v.status = 'draft'
      and v.passing_score = 90.00
      and v.legal_min_score = 90.00
      and v.metadata ->> 'homologation_phase' = '7A2'
      and coalesce((v.metadata ->> 'homologation_window')::boolean, true) = false
      and v.metadata ->> 'homologation_result' = 'validated'
      and v.metadata ->> 'homologation_attempt_id' = v_attempt_id::text
      and v.metadata ->> 'homologation_attempt_outcome' = 'not_approved'
  ) then
    raise exception
      'FASE7A2_ABORT: pós-condição de fechamento do Teste 12 Fiat não foi satisfeita.';
  end if;

  -- Pós-condição 2: tentativa homologada permanece preservada.
  if not exists (
    select 1
    from public.assessment_attempts a
    where a.id = v_attempt_id
      and a.organization_id = v_org_id
      and a.status = 'graded'
      and a.attempt_no = 1
      and a.total_questions = 30
      and a.answered_questions = 30
      and a.correct_answers = 26
      and a.overall_score = 86.67
      and a.legal_score = 86.67
      and a.critical_errors = 0
      and a.passed = false
      and a.result_reason = 'overall_score_below_minimum'
  ) then
    raise exception
      'FASE7A2_ABORT: tentativa homologada do Teste 12 Fiat foi alterada durante o fechamento.';
  end if;

  -- Pós-condição 3: Teste 11 permanece intocado.
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v on v.test_id = t.id
    where t.id = v_test11_id
      and t.organization_id = v_org_id
      and t.status = 'draft'
      and v.id = v_test11_version_id
      and v.organization_id = v_org_id
      and v.status = 'draft'
      and v.passing_score = 90.00
      and v.legal_min_score = 90.00
  ) then
    raise exception
      'FASE7A2_ABORT: proteção do Teste 11 VW falhou; transação será revertida.';
  end if;

  -- Pós-condição 4: Teste 13 permanece intocado.
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v on v.test_id = t.id
    where t.id = v_test13_id
      and t.organization_id = v_org_id
      and t.status = 'draft'
      and v.id = v_test13_version_id
      and v.organization_id = v_org_id
      and v.status = 'draft'
      and v.passing_score = 85.00
      and v.legal_min_score = 90.00
  ) then
    raise exception
      'FASE7A2_ABORT: proteção do Teste 13 VW comercial falhou; transação será revertida.';
  end if;
end
$$;

commit;
