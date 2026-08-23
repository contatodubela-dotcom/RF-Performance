begin;

do $$
declare
  v_org_id constant uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654';

  -- Teste 11 — Regulamentar Volkswagen
  v_test11_id constant uuid := 'dd671e5f-39ec-5018-9263-78613361a7db';
  v_test11_version_id constant uuid := 'fcf8f979-c44e-5993-beef-d023312ab5b7';
  v_test11_attempt_id constant uuid := 'ea94b2a3-906f-450f-94cc-67dd9a98709d';

  -- Teste 12 — Regulamentar Fiat
  v_test12_id constant uuid := '61d013e4-3b4b-5676-b39c-6d340f87b046';
  v_test12_version_id constant uuid := '74243315-ea1e-5178-83b8-d6077ab9dc59';
  v_test12_attempt_id constant uuid := '8658e309-7fa8-403e-92e5-3f7967ae38d5';

  -- Teste 13 — Comercial Volkswagen
  v_test13_id constant uuid := '4f97740e-3f9e-559e-b120-cd043a42c755';
  v_test13_version_id constant uuid := '58b09fe5-2bc5-5803-ab0a-2a8834c85607';
  v_test13_attempt_id constant uuid := '730f4095-9732-4899-934e-65ddbae38530';

  v_count bigint;
begin
  /*
   * PRECONDIÇÕES — IDENTIDADE, STATUS, POLÍTICA E CONTEÚDO
   */

  -- Teste 11
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.test_id = t.id
    where t.id = v_test11_id
      and t.organization_id = v_org_id
      and t.code = 'regulamento_vw_cnvw_v1'
      and t.title = 'Avaliação Regulamentar — Consórcio Volkswagen'
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
      'FASE7B1_ABORT: Teste 11 VW regulatório divergiu do baseline draft/draft 90/90.';
  end if;

  select count(*)
    into v_count
  from public.assessment_version_questions avq
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_test11_version_id
    and avq.archived_at is null;

  if v_count <> 30 then
    raise exception
      'FASE7B1_ABORT: Teste 11 deveria ter 30 questões ativas; encontrado %.', v_count;
  end if;

  select count(*)
    into v_count
  from public.assessment_version_sources avs
  where avs.organization_id = v_org_id
    and avs.test_version_id = v_test11_version_id
    and avs.archived_at is null
    and avs.is_required = true;

  if v_count <> 1 then
    raise exception
      'FASE7B1_ABORT: Teste 11 deveria ter 1 fonte obrigatória ativa; encontrado %.', v_count;
  end if;

  -- Teste 12
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.test_id = t.id
    where t.id = v_test12_id
      and t.organization_id = v_org_id
      and t.code = 'regulamento_fiat_v1'
      and t.title = 'Avaliação Regulamentar — Consórcio Fiat'
      and t.status = 'draft'
      and v.id = v_test12_version_id
      and v.organization_id = v_org_id
      and v.version_code = 'fiat-v3-v1'
      and v.version_no = 1
      and v.status = 'draft'
      and v.passing_score = 90.00
      and v.legal_min_score = 90.00
      and coalesce((t.metadata ->> 'homologation_window')::boolean, false) = false
      and coalesce((v.metadata ->> 'homologation_window')::boolean, false) = false
  ) then
    raise exception
      'FASE7B1_ABORT: Teste 12 Fiat divergiu do baseline fechado draft/draft 90/90.';
  end if;

  select count(*)
    into v_count
  from public.assessment_version_questions avq
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_test12_version_id
    and avq.archived_at is null;

  if v_count <> 30 then
    raise exception
      'FASE7B1_ABORT: Teste 12 deveria ter 30 questões ativas; encontrado %.', v_count;
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
      'FASE7B1_ABORT: Teste 12 deveria ter 1 fonte obrigatória ativa; encontrado %.', v_count;
  end if;

  -- Teste 13
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.test_id = t.id
    where t.id = v_test13_id
      and t.organization_id = v_org_id
      and t.code = 'consorcio_vw_comercial_v1'
      and t.title = 'Avaliação Comercial — Consórcio Volkswagen'
      and t.status = 'draft'
      and v.id = v_test13_version_id
      and v.organization_id = v_org_id
      and v.version_code = 'cnvw-v3.0-comercial-v2'
      and v.version_no = 2
      and v.status = 'draft'
      and v.passing_score = 85.00
      and v.legal_min_score = 90.00
      and coalesce((t.metadata ->> 'homologation_window')::boolean, false) = false
      and coalesce((v.metadata ->> 'homologation_window')::boolean, false) = false
  ) then
    raise exception
      'FASE7B1_ABORT: Teste 13 VW comercial divergiu do baseline fechado draft/draft 85/90.';
  end if;

  select count(*)
    into v_count
  from public.assessment_version_questions avq
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_test13_version_id
    and avq.archived_at is null;

  if v_count <> 30 then
    raise exception
      'FASE7B1_ABORT: Teste 13 deveria ter 30 questões ativas; encontrado %.', v_count;
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
      'FASE7B1_ABORT: Teste 13 deveria ter 2 fontes obrigatórias ativas; encontrado %.', v_count;
  end if;

  -- Guarda consolidada: 90 questões ativas nos três testes.
  select count(*)
    into v_count
  from public.assessment_version_questions avq
  where avq.organization_id = v_org_id
    and avq.test_version_id in (
      v_test11_version_id,
      v_test12_version_id,
      v_test13_version_id
    )
    and avq.archived_at is null;

  if v_count <> 90 then
    raise exception
      'FASE7B1_ABORT: conjunto 11/12/13 deveria ter 90 questões ativas; encontrado %.', v_count;
  end if;

  /*
   * PRECONDIÇÃO — NENHUMA LIBERAÇÃO EFETIVA
   */

  select count(*)
    into v_count
  from private.assessment_test_access_grants g
  where g.organization_id = v_org_id
    and g.test_id in (v_test11_id, v_test12_id, v_test13_id)
    and g.archived_at is null
    and g.status = 'active'
    and (g.valid_from is null or g.valid_from <= now())
    and (g.valid_until is null or g.valid_until > now());

  if v_count <> 0 then
    raise exception
      'FASE7B1_ABORT: existem % liberações efetivas nos Testes 11/12/13; publicação cancelada.', v_count;
  end if;

  /*
   * PRECONDIÇÃO — HISTÓRICO DE HOMOLOGAÇÃO PRESERVADO
   */

  if not exists (
    select 1
    from public.assessment_attempts a
    where a.id = v_test11_attempt_id
      and a.organization_id = v_org_id
      and a.status = 'graded'
      and a.total_questions = 30
      and a.answered_questions = 30
      and a.correct_answers = 25
      and a.overall_score = 83.33
      and a.legal_score = 83.33
      and a.critical_errors = 0
      and a.passed = false
      and a.result_reason = 'overall_score_below_minimum'
  ) then
    raise exception
      'FASE7B1_ABORT: tentativa histórica homologada do Teste 11 ausente ou divergente.';
  end if;

  if not exists (
    select 1
    from public.assessment_attempts a
    where a.id = v_test12_attempt_id
      and a.organization_id = v_org_id
      and a.status = 'graded'
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
      'FASE7B1_ABORT: tentativa histórica homologada do Teste 12 ausente ou divergente.';
  end if;

  if not exists (
    select 1
    from public.assessment_attempts a
    where a.id = v_test13_attempt_id
      and a.organization_id = v_org_id
      and a.status = 'graded'
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
      'FASE7B1_ABORT: tentativa histórica homologada do Teste 13 ausente ou divergente.';
  end if;

  /*
   * PUBLICAÇÃO DEFINITIVA — NÃO CRIA GRANTS
   */

  update public.assessment_tests
  set
    status = 'active',
    metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
      'publication_phase', '7B1',
      'publication_mode', 'operational',
      'published_for_operation', true,
      'operational_published_at', now(),
      'publication_scope', 'testes_11_12_13',
      'grants_created_by_publication', false
    )
  where id in (v_test11_id, v_test12_id, v_test13_id)
    and organization_id = v_org_id
    and status = 'draft';

  get diagnostics v_count = row_count;

  if v_count <> 3 then
    raise exception
      'FASE7B1_ABORT: esperava ativar 3 testes; foram atualizados %.', v_count;
  end if;

  update public.assessment_test_versions
  set
    status = 'published',
    metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
      'publication_phase', '7B1',
      'publication_mode', 'operational',
      'published_for_operation', true,
      'operational_published_at', now(),
      'publication_scope', 'testes_11_12_13',
      'grants_created_by_publication', false
    )
  where id in (
      v_test11_version_id,
      v_test12_version_id,
      v_test13_version_id
    )
    and organization_id = v_org_id
    and status = 'draft';

  get diagnostics v_count = row_count;

  if v_count <> 3 then
    raise exception
      'FASE7B1_ABORT: esperava publicar 3 versões; foram atualizadas %.', v_count;
  end if;

  /*
   * PÓS-CONDIÇÕES — STATUS E POLÍTICAS
   */

  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v on v.test_id = t.id
    where t.id = v_test11_id
      and t.organization_id = v_org_id
      and t.status = 'active'
      and t.metadata ->> 'publication_phase' = '7B1'
      and coalesce((t.metadata ->> 'published_for_operation')::boolean, false) = true
      and v.id = v_test11_version_id
      and v.status = 'published'
      and v.passing_score = 90.00
      and v.legal_min_score = 90.00
      and v.metadata ->> 'publication_phase' = '7B1'
      and coalesce((v.metadata ->> 'published_for_operation')::boolean, false) = true
  ) then
    raise exception
      'FASE7B1_ABORT: pós-condição de publicação do Teste 11 falhou.';
  end if;

  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v on v.test_id = t.id
    where t.id = v_test12_id
      and t.organization_id = v_org_id
      and t.status = 'active'
      and t.metadata ->> 'publication_phase' = '7B1'
      and coalesce((t.metadata ->> 'published_for_operation')::boolean, false) = true
      and v.id = v_test12_version_id
      and v.status = 'published'
      and v.passing_score = 90.00
      and v.legal_min_score = 90.00
      and v.metadata ->> 'publication_phase' = '7B1'
      and coalesce((v.metadata ->> 'published_for_operation')::boolean, false) = true
  ) then
    raise exception
      'FASE7B1_ABORT: pós-condição de publicação do Teste 12 falhou.';
  end if;

  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v on v.test_id = t.id
    where t.id = v_test13_id
      and t.organization_id = v_org_id
      and t.status = 'active'
      and t.metadata ->> 'publication_phase' = '7B1'
      and coalesce((t.metadata ->> 'published_for_operation')::boolean, false) = true
      and v.id = v_test13_version_id
      and v.status = 'published'
      and v.passing_score = 85.00
      and v.legal_min_score = 90.00
      and v.metadata ->> 'publication_phase' = '7B1'
      and coalesce((v.metadata ->> 'published_for_operation')::boolean, false) = true
  ) then
    raise exception
      'FASE7B1_ABORT: pós-condição de publicação do Teste 13 falhou.';
  end if;

  /*
   * PÓS-CONDIÇÃO — PUBLICAÇÃO NÃO CRIOU GRANTS EFETIVOS
   */

  select count(*)
    into v_count
  from private.assessment_test_access_grants g
  where g.organization_id = v_org_id
    and g.test_id in (v_test11_id, v_test12_id, v_test13_id)
    and g.archived_at is null
    and g.status = 'active'
    and (g.valid_from is null or g.valid_from <= now())
    and (g.valid_until is null or g.valid_until > now());

  if v_count <> 0 then
    raise exception
      'FASE7B1_ABORT: publicação gerou ou deixou % grants efetivos; transação será revertida.', v_count;
  end if;

  /*
   * PÓS-CONDIÇÃO — HISTÓRICO DE TENTATIVAS CONTINUA PRESERVADO
   */

  if not exists (
    select 1
    from public.assessment_attempts a
    where a.id = v_test11_attempt_id
      and a.status = 'graded'
      and a.correct_answers = 25
      and a.overall_score = 83.33
      and a.legal_score = 83.33
      and a.critical_errors = 0
      and a.passed = false
      and a.result_reason = 'overall_score_below_minimum'
  ) then
    raise exception
      'FASE7B1_ABORT: histórico do Teste 11 foi alterado durante a publicação.';
  end if;

  if not exists (
    select 1
    from public.assessment_attempts a
    where a.id = v_test12_attempt_id
      and a.status = 'graded'
      and a.correct_answers = 26
      and a.overall_score = 86.67
      and a.legal_score = 86.67
      and a.critical_errors = 0
      and a.passed = false
      and a.result_reason = 'overall_score_below_minimum'
  ) then
    raise exception
      'FASE7B1_ABORT: histórico do Teste 12 foi alterado durante a publicação.';
  end if;

  if not exists (
    select 1
    from public.assessment_attempts a
    where a.id = v_test13_attempt_id
      and a.status = 'graded'
      and a.correct_answers = 29
      and a.overall_score = 96.67
      and a.legal_score = 95.00
      and a.critical_errors = 0
      and a.passed = true
      and a.result_reason = 'approved'
  ) then
    raise exception
      'FASE7B1_ABORT: histórico do Teste 13 foi alterado durante a publicação.';
  end if;
end
$$;

commit;
