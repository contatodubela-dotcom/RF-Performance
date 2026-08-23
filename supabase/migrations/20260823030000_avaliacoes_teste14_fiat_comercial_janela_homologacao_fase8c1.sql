begin;

do $$
declare
  v_org_id constant uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654';

  -- Teste 14 — Avaliação Comercial — Consórcio Fiat
  v_test14_id constant uuid := '85e10e1e-53f2-50a8-a128-ffac41e315ea';
  v_test14_version_id constant uuid := 'b502d8bb-5bef-5f7b-ab1d-daec88b95227';

  -- Controles já publicados
  v_test11_id constant uuid := 'dd671e5f-39ec-5018-9263-78613361a7db';
  v_test11_version_id constant uuid := 'fcf8f979-c44e-5993-beef-d023312ab5b7';

  v_test12_id constant uuid := '61d013e4-3b4b-5676-b39c-6d340f87b046';
  v_test12_version_id constant uuid := '74243315-ea1e-5178-83b8-d6077ab9dc59';

  v_test13_id constant uuid := '4f97740e-3f9e-559e-b120-cd043a42c755';
  v_test13_version_id constant uuid := '58b09fe5-2bc5-5803-ab0a-2a8834c85607';

  v_count bigint;
begin
  /*
   * FASE 8C1
   * Abre uma janela temporária de homologação funcional do Teste 14.
   *
   * Regras:
   * - Teste 14 sai temporariamente de draft/draft para active/published;
   * - política 85/90 permanece inalterada;
   * - não cria grant;
   * - preserva questões, alternativas, chaves, fontes e competências;
   * - Testes 11, 12 e 13 permanecem exatamente como estão em produção;
   * - o fechamento da janela será feito em migration posterior (8C2).
   */

  /*
   * PRECONDIÇÃO — IDENTIDADE E POLÍTICA DO TESTE 14
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
      and t.status = 'draft'
      and t.question_count = 30

      and v.id = v_test14_version_id
      and v.organization_id = v_org_id
      and v.version_code = 'fiat-v3-comercial-v1'
      and v.version_no = 1
      and v.status = 'draft'
      and v.question_count = 30
      and v.passing_score = 85.00
      and v.legal_min_score = 90.00

      and v.metadata ->> 'approval_policy_phase' = '8B'
      and v.metadata ->> 'approval_policy_status' = 'approved'
      and v.metadata ->> 'approval_policy_authorization'
        = 'AUTORIZO_POLITICA_TESTE14_FIAT_COMERCIAL_85_90_FASE8B'
      and coalesce(
        (v.metadata ->> 'policy_authorized_for_homologation')::boolean,
        false
      ) = true
  ) then
    raise exception
      'FASE8C1_ABORT: Teste 14 divergiu do baseline draft/draft 85/90 autorizado na Fase 8B.';
  end if;

  /*
   * PRECONDIÇÃO — CONTEÚDO DO TESTE 14
   */
  select count(*)
    into v_count
  from public.assessment_version_questions avq
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_test14_version_id
    and avq.archived_at is null;

  if v_count <> 30 then
    raise exception
      'FASE8C1_ABORT: Teste 14 deveria ter 30 questões ativas; encontrado %.', v_count;
  end if;

  select count(*)
    into v_count
  from public.assessment_question_options o
  join public.assessment_version_questions avq
    on avq.question_id = o.question_id
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_test14_version_id
    and avq.archived_at is null
    and o.organization_id = v_org_id
    and o.archived_at is null;

  if v_count <> 120 then
    raise exception
      'FASE8C1_ABORT: Teste 14 deveria ter 120 alternativas ativas; encontrado %.', v_count;
  end if;

  select count(*)
    into v_count
  from private.assessment_question_keys k
  join public.assessment_version_questions avq
    on avq.question_id = k.question_id
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_test14_version_id
    and avq.archived_at is null
    and k.organization_id = v_org_id;

  if v_count <> 30 then
    raise exception
      'FASE8C1_ABORT: Teste 14 deveria ter 30 gabaritos privados; encontrado %.', v_count;
  end if;

  select count(*)
    into v_count
  from public.assessment_version_questions avq
  join public.assessment_questions q
    on q.id = avq.question_id
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_test14_version_id
    and avq.archived_at is null
    and q.archived_at is null
    and q.metadata ->> 'question_class' = 'COM'
    and coalesce((q.metadata ->> 'legal_scoring')::boolean, false) = false;

  if v_count <> 10 then
    raise exception
      'FASE8C1_ABORT: Teste 14 deveria ter 10 questões COM; encontrado %.', v_count;
  end if;

  select count(*)
    into v_count
  from public.assessment_version_questions avq
  join public.assessment_questions q
    on q.id = avq.question_id
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_test14_version_id
    and avq.archived_at is null
    and q.archived_at is null
    and q.metadata ->> 'question_class' = 'REG'
    and coalesce((q.metadata ->> 'legal_scoring')::boolean, false) = true;

  if v_count <> 20 then
    raise exception
      'FASE8C1_ABORT: Teste 14 deveria ter 20 questões REG; encontrado %.', v_count;
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
      'FASE8C1_ABORT: Teste 14 deveria ter 2 fontes obrigatórias; encontrado %.', v_count;
  end if;

  /*
   * PRECONDIÇÃO — TESTE 14 SEM GRANT
   */
  select count(*)
    into v_count
  from private.assessment_test_access_grants g
  where g.organization_id = v_org_id
    and g.test_id = v_test14_id
    and g.archived_at is null;

  if v_count <> 0 then
    raise exception
      'FASE8C1_ABORT: Teste 14 possui % grants antes da abertura da janela.', v_count;
  end if;

  /*
   * PRECONDIÇÃO — CONTROLES DE PRODUÇÃO 11/12/13
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
      'FASE8C1_ABORT: Teste 11 divergiu do controle active/published 90/90.';
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
      'FASE8C1_ABORT: Teste 12 divergiu do controle active/published 90/90.';
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
      'FASE8C1_ABORT: Teste 13 divergiu do controle active/published 85/90.';
  end if;

  /*
   * ABERTURA TEMPORÁRIA DA JANELA
   */
  update public.assessment_tests
  set
    status = 'active',
    metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
      'homologation_phase', '8C1',
      'homologation_scope', 'teste14_fiat_comercial',
      'homologation_window', true,
      'homologation_status', 'functional_validation_open',
      'homologation_result', 'pending',
      'homologation_opened_at', now(),
      'published_for_operation', false,
      'grants_created_by_homologation_open', false
    )
  where id = v_test14_id
    and organization_id = v_org_id
    and status = 'draft';

  get diagnostics v_count = row_count;

  if v_count <> 1 then
    raise exception
      'FASE8C1_ABORT: esperava ativar 1 teste; foram atualizados %.', v_count;
  end if;

  update public.assessment_test_versions
  set
    status = 'published',
    metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
      'homologation_phase', '8C1',
      'homologation_scope', 'teste14_fiat_comercial',
      'homologation_window', true,
      'homologation_status', 'functional_validation_open',
      'homologation_result', 'pending',
      'homologation_opened_at', now(),
      'published_for_operation', false,
      'grants_created_by_homologation_open', false
    )
  where id = v_test14_version_id
    and organization_id = v_org_id
    and status = 'draft';

  get diagnostics v_count = row_count;

  if v_count <> 1 then
    raise exception
      'FASE8C1_ABORT: esperava publicar temporariamente 1 versão; foram atualizadas %.', v_count;
  end if;

  /*
   * PÓS-CONDIÇÃO — TESTE 14 ABERTO, POLÍTICA PRESERVADA
   */
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v on v.test_id = t.id
    where t.id = v_test14_id
      and t.organization_id = v_org_id
      and t.status = 'active'
      and t.metadata ->> 'homologation_phase' = '8C1'
      and coalesce((t.metadata ->> 'homologation_window')::boolean, false) = true
      and t.metadata ->> 'homologation_status' = 'functional_validation_open'
      and t.metadata ->> 'homologation_result' = 'pending'
      and coalesce((t.metadata ->> 'published_for_operation')::boolean, true) = false

      and v.id = v_test14_version_id
      and v.status = 'published'
      and v.passing_score = 85.00
      and v.legal_min_score = 90.00
      and v.metadata ->> 'homologation_phase' = '8C1'
      and coalesce((v.metadata ->> 'homologation_window')::boolean, false) = true
      and v.metadata ->> 'homologation_status' = 'functional_validation_open'
      and v.metadata ->> 'homologation_result' = 'pending'
      and coalesce((v.metadata ->> 'published_for_operation')::boolean, true) = false
  ) then
    raise exception
      'FASE8C1_ABORT: pós-condição da janela de homologação do Teste 14 falhou.';
  end if;

  /*
   * PÓS-CONDIÇÃO — ABERTURA NÃO CRIOU GRANTS
   */
  select count(*)
    into v_count
  from private.assessment_test_access_grants g
  where g.organization_id = v_org_id
    and g.test_id = v_test14_id
    and g.archived_at is null;

  if v_count <> 0 then
    raise exception
      'FASE8C1_ABORT: abertura da homologação criou ou deixou % grants no Teste 14.', v_count;
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
      'FASE8C1_ABORT: Teste 11 foi alterado durante a abertura da homologação.';
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
      'FASE8C1_ABORT: Teste 12 foi alterado durante a abertura da homologação.';
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
      'FASE8C1_ABORT: Teste 13 foi alterado durante a abertura da homologação.';
  end if;
end
$$;

commit;
