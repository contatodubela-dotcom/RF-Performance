begin;

do $$
declare
  v_org_id constant uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654';

  v_test13_id constant uuid := '4f97740e-3f9e-559e-b120-cd043a42c755';
  v_test13_version_id constant uuid := '58b09fe5-2bc5-5803-ab0a-2a8834c85607';
  v_attempt_id constant uuid := '730f4095-9732-4899-934e-65ddbae38530';

  v_test11_id constant uuid := 'dd671e5f-39ec-5018-9263-78613361a7db';
  v_test11_version_id constant uuid := 'fcf8f979-c44e-5993-beef-d023312ab5b7';

  v_count bigint;
begin
  -- Guarda 1: Teste 13 deve estar exatamente na janela temporária aberta pela Fase 6D1.
  if not exists (
    select 1
    from public.assessment_tests t
    where t.id = v_test13_id
      and t.organization_id = v_org_id
      and t.code = 'consorcio_vw_comercial_v1'
      and t.title = 'Avaliação Comercial — Consórcio Volkswagen'
      and t.status = 'active'
      and t.metadata ->> 'homologation_phase' = '6D1'
      and coalesce((t.metadata ->> 'homologation_window')::boolean, false) = true
  ) then
    raise exception
      'FASE6D2_ABORT: Teste 13 não está na janela ativa esperada da Fase 6D1.';
  end if;

  -- Guarda 2: versão comercial deve continuar publicada, com política 85/90 e marcação 6D1.
  if not exists (
    select 1
    from public.assessment_test_versions v
    where v.id = v_test13_version_id
      and v.organization_id = v_org_id
      and v.test_id = v_test13_id
      and v.version_code = 'cnvw-v3.0-comercial-v2'
      and v.version_no = 2
      and v.status = 'published'
      and v.passing_score = 85.00
      and v.legal_min_score = 90.00
      and v.metadata ->> 'homologation_phase' = '6D1'
      and coalesce((v.metadata ->> 'homologation_window')::boolean, false) = true
  ) then
    raise exception
      'FASE6D2_ABORT: versão do Teste 13 divergiu do baseline publicado 85/90 da Fase 6D1.';
  end if;

  -- Guarda 3: conteúdo e fontes do Teste 13 permanecem íntegros.
  select count(*)
    into v_count
  from public.assessment_version_questions avq
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_test13_version_id
    and avq.archived_at is null;

  if v_count <> 30 then
    raise exception
      'FASE6D2_ABORT: Teste 13 deveria manter 30 questões ativas; encontrado %.', v_count;
  end if;

  select count(*)
    into v_count
  from public.assessment_version_sources avs
  where avs.organization_id = v_org_id
    and avs.test_version_id = v_test13_version_id
    and avs.archived_at is null
    and avs.is_required = true;

  if v_count <> 2 then
    raise exception
      'FASE6D2_ABORT: Teste 13 deveria manter 2 fontes obrigatórias ativas; encontrado %.', v_count;
  end if;

  select count(*)
    into v_count
  from public.assessment_version_sources avs
  where avs.organization_id = v_org_id
    and avs.test_version_id = v_test13_version_id
    and avs.archived_at is null;

  if v_count <> 2 then
    raise exception
      'FASE6D2_ABORT: Teste 13 deveria manter exatamente 2 fontes ativas; encontrado %.', v_count;
  end if;

  -- Guarda 4: tentativa funcional homologada deve existir e permanecer com o resultado validado.
  if not exists (
    select 1
    from public.assessment_attempts a
    where a.id = v_attempt_id
      and a.organization_id = v_org_id
      and a.status = 'graded'
      and a.attempt_no = 1
      and a.total_questions = 30
      and a.answered_questions = 30
      and a.correct_answers = 29
      and a.overall_score = 96.67
      and a.legal_score = 95.00
      and a.critical_errors = 0
      and a.passed = true
      and a.result_reason = 'approved'
      and a.submitted_at is not null
      and a.graded_at is not null
  ) then
    raise exception
      'FASE6D2_ABORT: tentativa homologada do Teste 13 ausente ou resultado divergente.';
  end if;

  -- Guarda 5: Teste 11 regulatório histórico continua fechado e protegido.
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.test_id = t.id
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
      'FASE6D2_ABORT: Teste 11 regulatório não está no baseline protegido esperado.';
  end if;

  -- Fechamento da janela temporária: somente Teste 13.
  update public.assessment_tests
  set
    status = 'draft',
    metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
      'homologation_phase', '6D2',
      'homologation_window', false,
      'homologation_closed_at', now(),
      'homologation_scope', 'teste13_vw_comercial',
      'homologation_result', 'approved',
      'homologation_attempt_id', v_attempt_id::text
    )
  where id = v_test13_id
    and organization_id = v_org_id
    and status = 'active';

  if not found then
    raise exception
      'FASE6D2_ABORT: falha ao devolver o Teste 13 para draft.';
  end if;

  update public.assessment_test_versions
  set
    status = 'draft',
    metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
      'homologation_phase', '6D2',
      'homologation_window', false,
      'homologation_closed_at', now(),
      'homologation_scope', 'teste13_vw_comercial',
      'homologation_result', 'approved',
      'homologation_attempt_id', v_attempt_id::text
    )
  where id = v_test13_version_id
    and organization_id = v_org_id
    and test_id = v_test13_id
    and status = 'published'
    and passing_score = 85.00
    and legal_min_score = 90.00;

  if not found then
    raise exception
      'FASE6D2_ABORT: falha ao devolver a versão do Teste 13 para draft.';
  end if;

  -- Pós-condição 1: Teste 13 fechado, mantendo política e rastreabilidade da homologação.
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.test_id = t.id
    where t.id = v_test13_id
      and t.organization_id = v_org_id
      and t.status = 'draft'
      and t.metadata ->> 'homologation_phase' = '6D2'
      and coalesce((t.metadata ->> 'homologation_window')::boolean, true) = false
      and t.metadata ->> 'homologation_result' = 'approved'
      and t.metadata ->> 'homologation_attempt_id' = v_attempt_id::text
      and v.id = v_test13_version_id
      and v.organization_id = v_org_id
      and v.status = 'draft'
      and v.passing_score = 85.00
      and v.legal_min_score = 90.00
      and v.metadata ->> 'homologation_phase' = '6D2'
      and coalesce((v.metadata ->> 'homologation_window')::boolean, true) = false
      and v.metadata ->> 'homologation_result' = 'approved'
      and v.metadata ->> 'homologation_attempt_id' = v_attempt_id::text
  ) then
    raise exception
      'FASE6D2_ABORT: pós-condição de fechamento do Teste 13 não foi satisfeita.';
  end if;

  -- Pós-condição 2: tentativa homologada continua preservada integralmente.
  if not exists (
    select 1
    from public.assessment_attempts a
    where a.id = v_attempt_id
      and a.organization_id = v_org_id
      and a.status = 'graded'
      and a.attempt_no = 1
      and a.total_questions = 30
      and a.answered_questions = 30
      and a.correct_answers = 29
      and a.overall_score = 96.67
      and a.legal_score = 95.00
      and a.critical_errors = 0
      and a.passed = true
      and a.result_reason = 'approved'
  ) then
    raise exception
      'FASE6D2_ABORT: tentativa homologada foi alterada durante o fechamento.';
  end if;

  -- Pós-condição 3: Teste 11 regulatório continua intocado.
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.test_id = t.id
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
      'FASE6D2_ABORT: proteção do Teste 11 falhou; transação será revertida.';
  end if;
end
$$;

commit;
