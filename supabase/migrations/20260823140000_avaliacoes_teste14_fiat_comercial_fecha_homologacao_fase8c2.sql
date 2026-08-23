begin;

do $$
declare
  v_org_id constant uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654';

  -- Teste 14 — Avaliação Comercial — Consórcio Fiat
  v_test14_id constant uuid := '85e10e1e-53f2-50a8-a128-ffac41e315ea';
  v_test14_version_id constant uuid := 'b502d8bb-5bef-5f7b-ab1d-daec88b95227';
  v_attempt_id constant uuid := '4352abc8-d5c3-42d3-831f-dc9f4a8d8da1';

  -- Controles de produção
  v_test11_id constant uuid := 'dd671e5f-39ec-5018-9263-78613361a7db';
  v_test11_version_id constant uuid := 'fcf8f979-c44e-5993-beef-d023312ab5b7';

  v_test12_id constant uuid := '61d013e4-3b4b-5676-b39c-6d340f87b046';
  v_test12_version_id constant uuid := '74243315-ea1e-5178-83b8-d6077ab9dc59';

  v_test13_id constant uuid := '4f97740e-3f9e-559e-b120-cd043a42c755';
  v_test13_version_id constant uuid := '58b09fe5-2bc5-5803-ab0a-2a8834c85607';

  v_count bigint;
begin
  /*
   * FASE 8C2
   * Fecha a janela de homologação funcional do Teste 14 Fiat Comercial.
   *
   * Regras:
   * - retorna Teste 14 para draft/draft;
   * - preserva política 85/90;
   * - preserva tentativa funcional e seu resultado;
   * - exige ausência de grant efetivo;
   * - não apaga histórico;
   * - protege Testes 11, 12 e 13 já publicados.
   */

  /*
   * PRECONDIÇÃO — TESTE 14 ESTÁ NA JANELA 8C1
   */
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.test_id = t.id
    where t.id = v_test14_id
      and t.organization_id = v_org_id
      and t.code = 'consorcio_fiat_comercial_v1'
      and t.title = 'Avaliação Comercial — Consórcio Fiat'
      and t.sequence_no = 14
      and t.status = 'active'
      and t.question_count = 30
      and t.metadata ->> 'homologation_phase' = '8C1'
      and coalesce((t.metadata ->> 'homologation_window')::boolean, false) = true
      and t.metadata ->> 'homologation_status' = 'functional_validation_open'
      and t.metadata ->> 'homologation_result' = 'pending'
      and coalesce((t.metadata ->> 'published_for_operation')::boolean, true) = false

      and v.id = v_test14_version_id
      and v.organization_id = v_org_id
      and v.version_code = 'fiat-v3-comercial-v1'
      and v.version_no = 1
      and v.status = 'published'
      and v.question_count = 30
      and v.passing_score = 85.00
      and v.legal_min_score = 90.00
      and v.metadata ->> 'homologation_phase' = '8C1'
      and coalesce((v.metadata ->> 'homologation_window')::boolean, false) = true
      and v.metadata ->> 'homologation_status' = 'functional_validation_open'
      and v.metadata ->> 'homologation_result' = 'pending'
      and coalesce((v.metadata ->> 'published_for_operation')::boolean, true) = false
  ) then
    raise exception
      'FASE8C2_ABORT: Teste 14 divergiu do baseline active/published da janela 8C1.';
  end if;

  /*
   * PRECONDIÇÃO — CONTEÚDO E FONTES PRESERVADOS
   */
  select count(*)
    into v_count
  from public.assessment_version_questions avq
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_test14_version_id
    and avq.archived_at is null;

  if v_count <> 30 then
    raise exception
      'FASE8C2_ABORT: Teste 14 deveria ter 30 questões ativas; encontrado %.', v_count;
  end if;

  select count(*)
    into v_count
  from public.assessment_version_sources avs
  where avs.organization_id = v_org_id
    and avs.test_version_id = v_test14_version_id
    and avs.archived_at is null
    and avs.is_required = true;

  if v_count <> 2 then
    raise exception
      'FASE8C2_ABORT: Teste 14 deveria ter 2 fontes obrigatórias; encontrado %.', v_count;
  end if;

  /*
   * PRECONDIÇÃO — TENTATIVA FUNCIONAL EXATA
   */
  if not exists (
    select 1
    from public.assessment_attempts a
    where a.id = v_attempt_id
      and a.organization_id = v_org_id
      and a.test_id = v_test14_id
      and a.test_version_id = v_test14_version_id
      and a.status = 'graded'
      and a.attempt_no = 1
      and a.total_questions = 30
      and a.answered_questions = 30
      and a.correct_answers = 26
      and a.overall_score = 86.67
      and a.legal_score = 85.00
      and a.critical_errors = 0
      and a.passed = false
      and a.result_reason = 'legal_score_below_minimum'
  ) then
    raise exception
      'FASE8C2_ABORT: tentativa funcional do Teste 14 ausente ou divergente.';
  end if;

  select count(*)
    into v_count
  from public.assessment_attempt_items ai
  where ai.attempt_id = v_attempt_id;

  if v_count <> 30 then
    raise exception
      'FASE8C2_ABORT: tentativa do Teste 14 deveria preservar 30 snapshot items; encontrado %.', v_count;
  end if;

  select count(*)
    into v_count
  from public.assessment_attempt_answers aa
  where aa.attempt_id = v_attempt_id;

  if v_count <> 30 then
    raise exception
      'FASE8C2_ABORT: tentativa do Teste 14 deveria preservar 30 respostas; encontrado %.', v_count;
  end if;

  /*
   * PRECONDIÇÃO — SEM GRANT EFETIVO APÓS REVOGAÇÃO
   */
  select count(*)
    into v_count
  from private.assessment_test_access_grants g
  where g.organization_id = v_org_id
    and g.test_id = v_test14_id
    and g.archived_at is null
    and g.status = 'active'
    and (g.valid_from is null or g.valid_from <= now())
    and (g.valid_until is null or g.valid_until > now());

  if v_count <> 0 then
    raise exception
      'FASE8C2_ABORT: Teste 14 ainda possui % grants efetivos.', v_count;
  end if;

  /*
   * PRECONDIÇÃO — CONTROLES 11/12/13
   */
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v on v.test_id = t.id
    where t.id = v_test11_id
      and t.organization_id = v_org_id
      and t.status = 'active'
      and v.id = v_test11_version_id
      and v.status = 'published'
      and v.passing_score = 90.00
      and v.legal_min_score = 90.00
  ) then
    raise exception
      'FASE8C2_ABORT: Teste 11 divergiu do controle active/published 90/90.';
  end if;

  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v on v.test_id = t.id
    where t.id = v_test12_id
      and t.organization_id = v_org_id
      and t.status = 'active'
      and v.id = v_test12_version_id
      and v.status = 'published'
      and v.passing_score = 90.00
      and v.legal_min_score = 90.00
  ) then
    raise exception
      'FASE8C2_ABORT: Teste 12 divergiu do controle active/published 90/90.';
  end if;

  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v on v.test_id = t.id
    where t.id = v_test13_id
      and t.organization_id = v_org_id
      and t.status = 'active'
      and v.id = v_test13_version_id
      and v.status = 'published'
      and v.passing_score = 85.00
      and v.legal_min_score = 90.00
  ) then
    raise exception
      'FASE8C2_ABORT: Teste 13 divergiu do controle active/published 85/90.';
  end if;

  /*
   * FECHAMENTO DA JANELA
   */
  update public.assessment_tests
  set
    status = 'draft',
    metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
      'homologation_phase', '8C2',
      'homologation_scope', 'teste14_fiat_comercial',
      'homologation_window', false,
      'homologation_status', 'functional_validation_closed',
      'homologation_result', 'validated',
      'homologation_closed_at', now(),
      'homologation_attempt_id', v_attempt_id,
      'homologation_attempt_outcome', 'not_approved',
      'homologation_attempt_result_reason', 'legal_score_below_minimum',
      'published_for_operation', false,
      'grants_created_by_homologation_close', false
    )
  where id = v_test14_id
    and organization_id = v_org_id
    and status = 'active';

  get diagnostics v_count = row_count;

  if v_count <> 1 then
    raise exception
      'FASE8C2_ABORT: esperava retornar 1 teste para draft; foram atualizados %.', v_count;
  end if;

  update public.assessment_test_versions
  set
    status = 'draft',
    metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
      'homologation_phase', '8C2',
      'homologation_scope', 'teste14_fiat_comercial',
      'homologation_window', false,
      'homologation_status', 'functional_validation_closed',
      'homologation_result', 'validated',
      'homologation_closed_at', now(),
      'homologation_attempt_id', v_attempt_id,
      'homologation_attempt_outcome', 'not_approved',
      'homologation_attempt_result_reason', 'legal_score_below_minimum',
      'published_for_operation', false,
      'grants_created_by_homologation_close', false
    )
  where id = v_test14_version_id
    and organization_id = v_org_id
    and status = 'published';

  get diagnostics v_count = row_count;

  if v_count <> 1 then
    raise exception
      'FASE8C2_ABORT: esperava retornar 1 versão para draft; foram atualizadas %.', v_count;
  end if;

  /*
   * PÓS-CONDIÇÃO — TESTE 14 FECHADO E POLÍTICA PRESERVADA
   */
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.test_id = t.id
    where t.id = v_test14_id
      and t.organization_id = v_org_id
      and t.status = 'draft'
      and t.metadata ->> 'homologation_phase' = '8C2'
      and coalesce((t.metadata ->> 'homologation_window')::boolean, true) = false
      and t.metadata ->> 'homologation_status' = 'functional_validation_closed'
      and t.metadata ->> 'homologation_result' = 'validated'
      and t.metadata ->> 'homologation_attempt_id' = v_attempt_id::text
      and t.metadata ->> 'homologation_attempt_outcome' = 'not_approved'
      and t.metadata ->> 'homologation_attempt_result_reason' = 'legal_score_below_minimum'

      and v.id = v_test14_version_id
      and v.status = 'draft'
      and v.passing_score = 85.00
      and v.legal_min_score = 90.00
      and v.metadata ->> 'homologation_phase' = '8C2'
      and coalesce((v.metadata ->> 'homologation_window')::boolean, true) = false
      and v.metadata ->> 'homologation_status' = 'functional_validation_closed'
      and v.metadata ->> 'homologation_result' = 'validated'
      and v.metadata ->> 'homologation_attempt_id' = v_attempt_id::text
      and v.metadata ->> 'homologation_attempt_outcome' = 'not_approved'
      and v.metadata ->> 'homologation_attempt_result_reason' = 'legal_score_below_minimum'
  ) then
    raise exception
      'FASE8C2_ABORT: pós-condição de fechamento do Teste 14 falhou.';
  end if;

  /*
   * PÓS-CONDIÇÃO — TENTATIVA HISTÓRICA CONTINUA PRESERVADA
   */
  if not exists (
    select 1
    from public.assessment_attempts a
    where a.id = v_attempt_id
      and a.status = 'graded'
      and a.total_questions = 30
      and a.answered_questions = 30
      and a.correct_answers = 26
      and a.overall_score = 86.67
      and a.legal_score = 85.00
      and a.critical_errors = 0
      and a.passed = false
      and a.result_reason = 'legal_score_below_minimum'
  ) then
    raise exception
      'FASE8C2_ABORT: histórico da tentativa do Teste 14 foi alterado durante o fechamento.';
  end if;

  /*
   * PÓS-CONDIÇÃO — CONTINUA SEM GRANT EFETIVO
   */
  select count(*)
    into v_count
  from private.assessment_test_access_grants g
  where g.organization_id = v_org_id
    and g.test_id = v_test14_id
    and g.archived_at is null
    and g.status = 'active'
    and (g.valid_from is null or g.valid_from <= now())
    and (g.valid_until is null or g.valid_until > now());

  if v_count <> 0 then
    raise exception
      'FASE8C2_ABORT: fechamento deixou % grants efetivos no Teste 14.', v_count;
  end if;

  /*
   * PÓS-CONDIÇÃO — CONTROLES 11/12/13 INALTERADOS
   */
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v on v.test_id = t.id
    where t.id = v_test11_id
      and t.status = 'active'
      and v.id = v_test11_version_id
      and v.status = 'published'
      and v.passing_score = 90.00
      and v.legal_min_score = 90.00
  ) then
    raise exception
      'FASE8C2_ABORT: Teste 11 foi alterado durante o fechamento.';
  end if;

  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v on v.test_id = t.id
    where t.id = v_test12_id
      and t.status = 'active'
      and v.id = v_test12_version_id
      and v.status = 'published'
      and v.passing_score = 90.00
      and v.legal_min_score = 90.00
  ) then
    raise exception
      'FASE8C2_ABORT: Teste 12 foi alterado durante o fechamento.';
  end if;

  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v on v.test_id = t.id
    where t.id = v_test13_id
      and t.status = 'active'
      and v.id = v_test13_version_id
      and v.status = 'published'
      and v.passing_score = 85.00
      and v.legal_min_score = 90.00
  ) then
    raise exception
      'FASE8C2_ABORT: Teste 13 foi alterado durante o fechamento.';
  end if;
end
$$;

commit;
