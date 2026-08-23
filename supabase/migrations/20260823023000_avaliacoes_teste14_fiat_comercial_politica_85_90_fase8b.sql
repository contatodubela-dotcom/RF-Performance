begin;

do $$
declare
  v_org_id constant uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654';

  -- Teste 14 — Avaliação Comercial — Consórcio Fiat
  v_test14_id constant uuid := '85e10e1e-53f2-50a8-a128-ffac41e315ea';
  v_test14_version_id constant uuid := 'b502d8bb-5bef-5f7b-ab1d-daec88b95227';

  v_count bigint;
begin
  /*
   * FASE 8B
   * Autoriza a política 85/90 do Teste 14 Fiat Comercial.
   *
   * Escopo:
   * - altera somente a política da versão do Teste 14;
   * - mantém Teste 14 em draft/draft;
   * - não publica;
   * - não cria grants;
   * - preserva questões, alternativas, gabaritos, fontes e competências;
   * - protege Testes 12 e 13 já publicados.
   */

  /*
   * PRECONDIÇÃO — IDENTIDADE E ESTADO FAIL-CLOSED DO TESTE 14
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

      -- Estado fail-closed criado na Fase 8A.
      and v.passing_score = 100.00
      and v.legal_min_score = 100.00

      -- Política proposta na Fase 8A.
      and v.metadata ->> 'approval_policy_status' = 'pending_authorization'
      and (v.metadata ->> 'proposed_passing_score')::numeric = 85.00
      and (v.metadata ->> 'proposed_legal_min_score')::numeric = 90.00
  ) then
    raise exception
      'FASE8B_ABORT: Teste 14 divergiu do baseline draft/draft fail-closed 100/100 com proposta 85/90.';
  end if;

  /*
   * PRECONDIÇÃO — 30 QUESTÕES, 10 COM + 20 REG
   */
  select count(*)
    into v_count
  from public.assessment_version_questions avq
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_test14_version_id
    and avq.archived_at is null;

  if v_count <> 30 then
    raise exception
      'FASE8B_ABORT: Teste 14 deveria ter 30 questões ativas; encontrado %.', v_count;
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
      'FASE8B_ABORT: Teste 14 deveria ter 10 questões COM não legais; encontrado %.', v_count;
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
      'FASE8B_ABORT: Teste 14 deveria ter 20 questões REG legais; encontrado %.', v_count;
  end if;

  /*
   * PRECONDIÇÃO — 120 ALTERNATIVAS E 30 GABARITOS PRIVADOS VÁLIDOS
   */
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
      'FASE8B_ABORT: Teste 14 deveria ter 120 alternativas ativas; encontrado %.', v_count;
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
      'FASE8B_ABORT: Teste 14 deveria ter 30 gabaritos privados; encontrado %.', v_count;
  end if;

  select count(*)
    into v_count
  from private.assessment_question_keys k
  join public.assessment_version_questions avq
    on avq.question_id = k.question_id
  left join public.assessment_question_options o
    on o.question_id = k.question_id
   and o.option_code = k.correct_option_code
   and o.organization_id = v_org_id
   and o.archived_at is null
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_test14_version_id
    and avq.archived_at is null
    and k.organization_id = v_org_id
    and o.id is null;

  if v_count <> 0 then
    raise exception
      'FASE8B_ABORT: Teste 14 possui % gabaritos sem alternativa correspondente.', v_count;
  end if;

  /*
   * PRECONDIÇÃO — DUAS FONTES OBRIGATÓRIAS
   */
  select count(*)
    into v_count
  from public.assessment_version_sources avs
  where avs.organization_id = v_org_id
    and avs.test_version_id = v_test14_version_id
    and avs.archived_at is null
    and avs.is_required = true;

  if v_count <> 2 then
    raise exception
      'FASE8B_ABORT: Teste 14 deveria ter 2 fontes obrigatórias; encontrado %.', v_count;
  end if;

  /*
   * PRECONDIÇÃO — NENHUM GRANT DO TESTE 14
   */
  select count(*)
    into v_count
  from private.assessment_test_access_grants g
  where g.organization_id = v_org_id
    and g.test_id = v_test14_id
    and g.archived_at is null;

  if v_count <> 0 then
    raise exception
      'FASE8B_ABORT: Teste 14 possui % grants; política não será autorizada.', v_count;
  end if;

  /*
   * PRECONDIÇÃO — CONTROLES TESTE 12 E TESTE 13
   */
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v on v.test_id = t.id
    where t.id = '61d013e4-3b4b-5676-b39c-6d340f87b046'::uuid
      and t.organization_id = v_org_id
      and t.code = 'regulamento_fiat_v1'
      and t.status = 'active'
      and v.id = '74243315-ea1e-5178-83b8-d6077ab9dc59'::uuid
      and v.status = 'published'
      and v.passing_score = 90.00
      and v.legal_min_score = 90.00
  ) then
    raise exception
      'FASE8B_ABORT: Teste 12 Fiat regulatório divergiu do controle active/published 90/90.';
  end if;

  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v on v.test_id = t.id
    where t.id = '4f97740e-3f9e-559e-b120-cd043a42c755'::uuid
      and t.organization_id = v_org_id
      and t.code = 'consorcio_vw_comercial_v1'
      and t.status = 'active'
      and v.id = '58b09fe5-2bc5-5803-ab0a-2a8834c85607'::uuid
      and v.status = 'published'
      and v.passing_score = 85.00
      and v.legal_min_score = 90.00
  ) then
    raise exception
      'FASE8B_ABORT: Teste 13 VW comercial divergiu do controle active/published 85/90.';
  end if;

  /*
   * AUTORIZAÇÃO DA POLÍTICA 85/90
   *
   * 30 questões:
   * - mínimo geral efetivo: 26/30 = 86,67%, porque 25/30 = 83,33%;
   * - 20 questões regulatórias: mínimo 18/20 = 90%.
   */
  update public.assessment_test_versions
  set
    passing_score = 85.00,
    legal_min_score = 90.00,
    metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
      'approval_policy_phase', '8B',
      'approval_policy_status', 'approved',
      'approval_policy_defined', true,
      'approval_policy_authorization',
        'AUTORIZO_POLITICA_TESTE14_FIAT_COMERCIAL_85_90_FASE8B',
      'approval_policy_passing_score', 85,
      'approval_policy_legal_min_score', 90,
      'approval_policy_total_questions', 30,
      'approval_policy_commercial_questions', 10,
      'approval_policy_regulatory_questions', 20,
      'approval_policy_min_correct_answers_out_of_30', 26,
      'approval_policy_min_regulatory_correct_answers_out_of_20', 18,
      'approval_policy_effective_min_overall_score', 86.67,
      'approval_policy_effective_min_legal_score', 90,
      'previous_fail_closed_passing_score', 100,
      'previous_fail_closed_legal_min_score', 100,
      'approval_threshold_strategy', 'authorized_85_overall_90_legal',
      'policy_authorized_for_homologation', true
    )
  where id = v_test14_version_id
    and organization_id = v_org_id
    and status = 'draft'
    and passing_score = 100.00
    and legal_min_score = 100.00;

  get diagnostics v_count = row_count;

  if v_count <> 1 then
    raise exception
      'FASE8B_ABORT: esperava atualizar 1 versão do Teste 14; foram atualizadas %.', v_count;
  end if;

  update public.assessment_tests
  set
    metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
      'approval_policy_phase', '8B',
      'approval_policy_status', 'approved',
      'approval_policy_authorization',
        'AUTORIZO_POLITICA_TESTE14_FIAT_COMERCIAL_85_90_FASE8B',
      'approval_policy_passing_score', 85,
      'approval_policy_legal_min_score', 90,
      'policy_authorized_for_homologation', true
    )
  where id = v_test14_id
    and organization_id = v_org_id
    and status = 'draft';

  get diagnostics v_count = row_count;

  if v_count <> 1 then
    raise exception
      'FASE8B_ABORT: esperava atualizar metadata de 1 teste; foram atualizados %.', v_count;
  end if;

  /*
   * PÓS-CONDIÇÕES — TESTE 14 CONTINUA DRAFT/DRAFT, AGORA 85/90
   */
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.test_id = t.id
    where t.id = v_test14_id
      and t.organization_id = v_org_id
      and t.status = 'draft'
      and t.metadata ->> 'approval_policy_phase' = '8B'
      and t.metadata ->> 'approval_policy_status' = 'approved'
      and coalesce((t.metadata ->> 'policy_authorized_for_homologation')::boolean, false) = true

      and v.id = v_test14_version_id
      and v.status = 'draft'
      and v.passing_score = 85.00
      and v.legal_min_score = 90.00
      and v.metadata ->> 'approval_policy_phase' = '8B'
      and v.metadata ->> 'approval_policy_status' = 'approved'
      and v.metadata ->> 'approval_policy_authorization'
        = 'AUTORIZO_POLITICA_TESTE14_FIAT_COMERCIAL_85_90_FASE8B'
      and coalesce((v.metadata ->> 'approval_policy_defined')::boolean, false) = true
      and coalesce((v.metadata ->> 'policy_authorized_for_homologation')::boolean, false) = true
      and (v.metadata ->> 'approval_policy_min_correct_answers_out_of_30')::integer = 26
      and (v.metadata ->> 'approval_policy_min_regulatory_correct_answers_out_of_20')::integer = 18
  ) then
    raise exception
      'FASE8B_ABORT: pós-condição da política 85/90 do Teste 14 falhou.';
  end if;

  /*
   * PÓS-CONDIÇÃO — CONTINUA SEM GRANTS
   */
  select count(*)
    into v_count
  from private.assessment_test_access_grants g
  where g.organization_id = v_org_id
    and g.test_id = v_test14_id
    and g.archived_at is null;

  if v_count <> 0 then
    raise exception
      'FASE8B_ABORT: autorização da política criou ou deixou % grants no Teste 14.', v_count;
  end if;

  /*
   * PÓS-CONDIÇÃO — TESTES 12 E 13 PRESERVADOS
   */
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v on v.test_id = t.id
    where t.id = '61d013e4-3b4b-5676-b39c-6d340f87b046'::uuid
      and t.status = 'active'
      and v.id = '74243315-ea1e-5178-83b8-d6077ab9dc59'::uuid
      and v.status = 'published'
      and v.passing_score = 90.00
      and v.legal_min_score = 90.00
  ) then
    raise exception
      'FASE8B_ABORT: Teste 12 foi alterado durante a autorização da política do Teste 14.';
  end if;

  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v on v.test_id = t.id
    where t.id = '4f97740e-3f9e-559e-b120-cd043a42c755'::uuid
      and t.status = 'active'
      and v.id = '58b09fe5-2bc5-5803-ab0a-2a8834c85607'::uuid
      and v.status = 'published'
      and v.passing_score = 85.00
      and v.legal_min_score = 90.00
  ) then
    raise exception
      'FASE8B_ABORT: Teste 13 foi alterado durante a autorização da política do Teste 14.';
  end if;
end
$$;

commit;
