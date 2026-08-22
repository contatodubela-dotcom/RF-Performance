-- ============================================================================
-- RF Performance — Avaliações e Certificações
-- Teste 13 — Avaliação Comercial — Consórcio Volkswagen
-- Fase 6C — Política definitiva de aprovação 85/90
--
-- AUTORIZAÇÃO DE ESCOPO:
--   AUTORIZO_POLITICA_TESTE13_VW_COMERCIAL_85_90_FASE6C
--
-- POLÍTICA APROVADA:
--   passing_score   = 85
--   legal_min_score = 90
--
-- Efeito discreto com a composição atual:
--   - 30 questões totais: mínimo prático de 26 acertos = 86,67%;
--   - 20 questões regulatórias: mínimo de 18 acertos REG = 90%.
--
-- SEGURANÇA:
--   - Teste 13 permanece draft.
--   - Versão comercial permanece draft e inédita.
--   - NÃO publica.
--   - NÃO cria grant.
--   - NÃO cria tentativa.
--   - NÃO altera questões, alternativas, gabaritos, competências ou fontes.
--   - NÃO altera o Teste 11 regulatório nem sua tentativa histórica.
--   - NÃO altera o Teste 12 Fiat.
--   - NÃO edita migrations já aplicadas.
-- ============================================================================

begin;

do $policy$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;

  v_test11_id uuid := 'dd671e5f-39ec-5018-9263-78613361a7db'::uuid;
  v_test11_v1_id uuid := 'fcf8f979-c44e-5993-beef-d023312ab5b7'::uuid;
  v_test11_attempt_id uuid := 'ea94b2a3-906f-450f-94cc-67dd9a98709d'::uuid;

  v_test12_id uuid := '61d013e4-3b4b-5676-b39c-6d340f87b046'::uuid;
  v_test12_v1_id uuid := '74243315-ea1e-5178-83b8-d6077ab9dc59'::uuid;

  v_test13_id uuid := '4f97740e-3f9e-559e-b120-cd043a42c755'::uuid;
  v_test13_v2_id uuid := '58b09fe5-2bc5-5803-ab0a-2a8834c85607'::uuid;

  v_count bigint;
begin
  -- ==========================================================================
  -- 0. GUARDAS FAIL-CLOSED
  -- ==========================================================================

  if not exists (
    select 1
    from public.organizations o
    where o.id = v_org_id
      and o.slug = 'rf-consorcios'
      and o.status = 'active'
      and o.archived_at is null
  ) then
    raise exception 'FASE6C_ABORT: organizacao RF esperada nao localizada/ativa.';
  end if;

  -- --------------------------------------------------------------------------
  -- Teste 13 deve estar exatamente como encerrado pela Fase 6B.
  -- --------------------------------------------------------------------------
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.organization_id = t.organization_id
     and v.test_id = t.id
     and v.id = v_test13_v2_id
     and v.archived_at is null
    where t.organization_id = v_org_id
      and t.id = v_test13_id
      and t.sequence_no = 13
      and t.code = 'consorcio_vw_comercial_v1'
      and t.title = 'Avaliação Comercial — Consórcio Volkswagen'
      and t.purpose = 'certification'
      and t.question_count = 30
      and t.status = 'draft'
      and t.archived_at is null
      and v.version_code = 'cnvw-v3.0-comercial-v2'
      and v.version_no = 2
      and v.status = 'draft'
      and v.passing_score = 100
      and v.legal_min_score = 100
      and v.question_count = 30
      and v.valid_from is null
      and v.valid_until is null
      and v.published_at is null
      and v.metadata->>'catalog_family' = 'commercial_regulatory'
      and v.metadata->>'assessment_code' = 'consorcio_vw_comercial_v1'
      and v.metadata->>'test_number' = '13'
      and v.metadata->>'separation_phase' = '6B'
      and v.metadata->>'homologation_status' = 'draft_candidate'
  ) then
    raise exception
      'FASE6C_ABORT: Teste 13 / cnvw-v3.0-comercial-v2 nao esta no estado fail-closed esperado.';
  end if;

  select count(*)
    into v_count
  from public.assessment_test_versions v
  where v.organization_id = v_org_id
    and v.test_id = v_test13_id
    and v.archived_at is null;

  if v_count <> 1 then
    raise exception
      'FASE6C_ABORT: Teste 13 deveria possuir exatamente 1 versao nao arquivada; encontrado %.',
      v_count;
  end if;

  select count(*)
    into v_count
  from public.assessment_version_questions avq
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_test13_v2_id
    and avq.archived_at is null;

  if v_count <> 30 then
    raise exception
      'FASE6C_ABORT: Teste 13 deveria possuir 30 questoes vinculadas; encontrado %.',
      v_count;
  end if;

  select count(*)
    into v_count
  from public.assessment_question_options o
  join public.assessment_version_questions avq
    on avq.organization_id = o.organization_id
   and avq.question_id = o.question_id
   and avq.test_version_id = v_test13_v2_id
   and avq.archived_at is null
  where o.organization_id = v_org_id;

  if v_count <> 120 then
    raise exception
      'FASE6C_ABORT: Teste 13 deveria possuir 120 alternativas; encontrado %.',
      v_count;
  end if;

  select count(*)
    into v_count
  from private.assessment_question_keys k
  join public.assessment_version_questions avq
    on avq.organization_id = k.organization_id
   and avq.question_id = k.question_id
   and avq.test_version_id = v_test13_v2_id
   and avq.archived_at is null
  where k.organization_id = v_org_id;

  if v_count <> 30 then
    raise exception
      'FASE6C_ABORT: Teste 13 deveria possuir 30 gabaritos privados; encontrado %.',
      v_count;
  end if;

  -- 20 REG.
  select count(*)
    into v_count
  from public.assessment_version_questions avq
  join public.assessment_questions q
    on q.organization_id = avq.organization_id
   and q.id = avq.question_id
   and q.archived_at is null
  join public.competency_domains c
    on c.organization_id = q.organization_id
   and c.id = q.competency_id
   and c.archived_at is null
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_test13_v2_id
    and avq.archived_at is null
    and c.is_legal = true;

  if v_count <> 20 then
    raise exception
      'FASE6C_ABORT: Teste 13 deveria possuir 20 questoes REG; encontrado %.',
      v_count;
  end if;

  -- 10 COM.
  select count(*)
    into v_count
  from public.assessment_version_questions avq
  join public.assessment_questions q
    on q.organization_id = avq.organization_id
   and q.id = avq.question_id
   and q.archived_at is null
  join public.competency_domains c
    on c.organization_id = q.organization_id
   and c.id = q.competency_id
   and c.archived_at is null
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_test13_v2_id
    and avq.archived_at is null
    and c.is_legal = false;

  if v_count <> 10 then
    raise exception
      'FASE6C_ABORT: Teste 13 deveria possuir 10 questoes COM; encontrado %.',
      v_count;
  end if;

  -- Duas fontes primary|required.
  select count(*)
    into v_count
  from public.assessment_version_sources avs
  where avs.organization_id = v_org_id
    and avs.test_version_id = v_test13_v2_id
    and avs.relation_type = 'primary'
    and avs.is_required = true
    and avs.archived_at is null;

  if v_count <> 2 then
    raise exception
      'FASE6C_ABORT: Teste 13 deveria possuir 2 fontes primary|required; encontrado %.',
      v_count;
  end if;

  -- Quatro competências comerciais não legais da camada VW.
  select count(*)
    into v_count
  from public.competency_domains c
  where c.organization_id = v_org_id
    and c.id in (
      'f5c28faf-04e4-57c9-99fd-b3ed36495964'::uuid,
      '590aa9ef-61cf-510e-85c2-a7077687036c'::uuid,
      '8488aa2e-82f6-5c83-bdcc-584ebf15d60d'::uuid,
      'c31f1ba9-d96a-5a84-b0a7-8b9de713512f'::uuid
    )
    and c.sequence_no between 59 and 62
    and c.is_legal = false
    and c.status = 'draft'
    and c.archived_at is null
    and c.metadata->>'assessment_code' = 'consorcio_vw_comercial_v1'
    and c.metadata->>'test_number' = '13';

  if v_count <> 4 then
    raise exception
      'FASE6C_ABORT: quatro competencias comerciais do Teste 13 nao estao integras; encontrado %.',
      v_count;
  end if;

  -- Nenhum acesso/tentativa/requisito antes de definir a política.
  select count(*)
    into v_count
  from private.assessment_test_access_grants g
  where g.organization_id = v_org_id
    and g.test_id = v_test13_id
    and g.status = 'active'
    and g.archived_at is null;

  if v_count <> 0 then
    raise exception 'FASE6C_ABORT: Teste 13 possui grant ativo.';
  end if;

  select count(*)
    into v_count
  from public.assessment_attempts a
  where a.organization_id = v_org_id
    and (
      a.test_id = v_test13_id
      or a.test_version_id = v_test13_v2_id
    )
    and a.archived_at is null;

  if v_count <> 0 then
    raise exception 'FASE6C_ABORT: Teste 13 possui tentativa registrada.';
  end if;

  select count(*)
    into v_count
  from public.certification_requirements cr
  where cr.organization_id = v_org_id
    and (
      cr.assessment_test_id = v_test13_id
      or cr.assessment_test_version_id = v_test13_v2_id
    )
    and cr.archived_at is null;

  if v_count <> 0 then
    raise exception 'FASE6C_ABORT: Teste 13 possui requisito de certificacao associado.';
  end if;

  -- --------------------------------------------------------------------------
  -- Teste 11 deve permanecer histórico e intocado.
  -- --------------------------------------------------------------------------
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.organization_id = t.organization_id
     and v.test_id = t.id
     and v.id = v_test11_v1_id
     and v.archived_at is null
    where t.organization_id = v_org_id
      and t.id = v_test11_id
      and t.sequence_no = 11
      and t.code = 'regulamento_vw_cnvw_v1'
      and t.title = 'Avaliação Regulamentar — Consórcio Volkswagen'
      and t.status = 'draft'
      and t.archived_at is null
      and v.version_code = 'cnvw-v3.0-v1'
      and v.version_no = 1
      and v.status = 'draft'
      and v.passing_score = 90
      and v.legal_min_score = 90
      and v.question_count = 30
      and v.published_at is null
  ) then
    raise exception 'FASE6C_ABORT: Teste 11 historico nao esta preservado.';
  end if;

  if not exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.id = v_test11_attempt_id
      and a.test_id = v_test11_id
      and a.test_version_id = v_test11_v1_id
      and a.status = 'graded'
      and a.correct_answers = 25
      and round(a.overall_score::numeric, 2) = 83.33
      and round(a.legal_score::numeric, 2) = 83.33
      and a.critical_errors = 0
      and a.passed is false
      and a.result_reason = 'overall_score_below_minimum'
      and a.archived_at is null
  ) then
    raise exception 'FASE6C_ABORT: tentativa historica do Teste 11 nao confere.';
  end if;

  select count(*)
    into v_count
  from public.assessment_attempts a
  where a.organization_id = v_org_id
    and a.test_id = v_test11_id
    and a.archived_at is null;

  if v_count <> 1 then
    raise exception
      'FASE6C_ABORT: Teste 11 deveria manter exatamente 1 tentativa; encontrado %.',
      v_count;
  end if;

  -- --------------------------------------------------------------------------
  -- Teste 12 Fiat permanece intocado.
  -- --------------------------------------------------------------------------
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.organization_id = t.organization_id
     and v.test_id = t.id
     and v.id = v_test12_v1_id
     and v.archived_at is null
    where t.organization_id = v_org_id
      and t.id = v_test12_id
      and t.sequence_no = 12
      and t.code = 'regulamento_fiat_v1'
      and t.title = 'Avaliação Regulamentar — Consórcio Fiat'
      and t.status = 'draft'
      and t.archived_at is null
      and v.version_code = 'fiat-v3-v1'
      and v.version_no = 1
      and v.status = 'draft'
      and v.passing_score = 90
      and v.legal_min_score = 90
      and v.question_count = 30
      and v.published_at is null
  ) then
    raise exception 'FASE6C_ABORT: Teste 12 Fiat nao esta preservado.';
  end if;

  if exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.test_id = v_test12_id
      and a.archived_at is null
  ) then
    raise exception 'FASE6C_ABORT: Teste 12 Fiat possui tentativa inesperada.';
  end if;

  -- ==========================================================================
  -- 1. APLICAÇÃO DA POLÍTICA 85/90 AO TESTE 13
  -- ==========================================================================

  update public.assessment_test_versions
  set
    passing_score = 85,
    legal_min_score = 90,
    metadata =
      coalesce(metadata, '{}'::jsonb)
      || jsonb_build_object(
           'approval_policy_status', 'approved',
           'approval_policy_phase', '6C',
           'approval_policy_passing_score', 85,
           'approval_policy_legal_min_score', 90,
           'approval_policy_total_questions', 30,
           'approval_policy_regulatory_questions', 20,
           'approval_policy_commercial_questions', 10,
           'approval_policy_min_correct_answers_out_of_30', 26,
           'approval_policy_effective_min_overall_score', 86.67,
           'approval_policy_min_regulatory_correct_answers_out_of_20', 18,
           'approval_policy_effective_min_legal_score', 90,
           'previous_fail_closed_passing_score', 100,
           'previous_fail_closed_legal_min_score', 100,
           'approval_policy_authorization',
             'AUTORIZO_POLITICA_TESTE13_VW_COMERCIAL_85_90_FASE6C',
           'approval_policy_defined', true
         )
  where organization_id = v_org_id
    and id = v_test13_v2_id
    and test_id = v_test13_id
    and version_code = 'cnvw-v3.0-comercial-v2'
    and version_no = 2
    and status = 'draft'
    and passing_score = 100
    and legal_min_score = 100
    and valid_from is null
    and valid_until is null
    and published_at is null
    and archived_at is null;

  if not found then
    raise exception 'FASE6C_ABORT: politica 85/90 do Teste 13 nao foi aplicada.';
  end if;

  -- ==========================================================================
  -- 2. PÓS-CONDIÇÕES
  -- ==========================================================================

  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.organization_id = t.organization_id
     and v.test_id = t.id
     and v.id = v_test13_v2_id
     and v.archived_at is null
    where t.organization_id = v_org_id
      and t.id = v_test13_id
      and t.sequence_no = 13
      and t.code = 'consorcio_vw_comercial_v1'
      and t.title = 'Avaliação Comercial — Consórcio Volkswagen'
      and t.status = 'draft'
      and t.archived_at is null
      and v.version_code = 'cnvw-v3.0-comercial-v2'
      and v.version_no = 2
      and v.status = 'draft'
      and v.passing_score = 85
      and v.legal_min_score = 90
      and v.question_count = 30
      and v.valid_from is null
      and v.valid_until is null
      and v.published_at is null
      and v.metadata->>'approval_policy_status' = 'approved'
      and v.metadata->>'approval_policy_phase' = '6C'
      and v.metadata->>'approval_policy_passing_score' = '85'
      and v.metadata->>'approval_policy_legal_min_score' = '90'
      and v.metadata->>'approval_policy_min_correct_answers_out_of_30' = '26'
      and v.metadata->>'approval_policy_min_regulatory_correct_answers_out_of_20' = '18'
      and v.metadata->>'approval_policy_defined' = 'true'
  ) then
    raise exception 'FASE6C_POST: politica final do Teste 13 nao confere.';
  end if;

  -- Estrutura permanece 30/120/30 e 20 REG + 10 COM.
  select count(*)
    into v_count
  from public.assessment_version_questions avq
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_test13_v2_id
    and avq.archived_at is null;

  if v_count <> 30 then
    raise exception 'FASE6C_POST: quantidade de questoes do Teste 13 foi alterada.';
  end if;

  select count(*)
    into v_count
  from public.assessment_question_options o
  join public.assessment_version_questions avq
    on avq.organization_id = o.organization_id
   and avq.question_id = o.question_id
   and avq.test_version_id = v_test13_v2_id
   and avq.archived_at is null
  where o.organization_id = v_org_id;

  if v_count <> 120 then
    raise exception 'FASE6C_POST: quantidade de alternativas do Teste 13 foi alterada.';
  end if;

  select count(*)
    into v_count
  from private.assessment_question_keys k
  join public.assessment_version_questions avq
    on avq.organization_id = k.organization_id
   and avq.question_id = k.question_id
   and avq.test_version_id = v_test13_v2_id
   and avq.archived_at is null
  where k.organization_id = v_org_id;

  if v_count <> 30 then
    raise exception 'FASE6C_POST: quantidade de gabaritos do Teste 13 foi alterada.';
  end if;

  select count(*)
    into v_count
  from public.assessment_version_questions avq
  join public.assessment_questions q
    on q.organization_id = avq.organization_id
   and q.id = avq.question_id
   and q.archived_at is null
  join public.competency_domains c
    on c.organization_id = q.organization_id
   and c.id = q.competency_id
   and c.archived_at is null
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_test13_v2_id
    and avq.archived_at is null
    and c.is_legal = true;

  if v_count <> 20 then
    raise exception 'FASE6C_POST: quantidade REG do Teste 13 foi alterada.';
  end if;

  select count(*)
    into v_count
  from public.assessment_version_questions avq
  join public.assessment_questions q
    on q.organization_id = avq.organization_id
   and q.id = avq.question_id
   and q.archived_at is null
  join public.competency_domains c
    on c.organization_id = q.organization_id
   and c.id = q.competency_id
   and c.archived_at is null
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_test13_v2_id
    and avq.archived_at is null
    and c.is_legal = false;

  if v_count <> 10 then
    raise exception 'FASE6C_POST: quantidade COM do Teste 13 foi alterada.';
  end if;

  -- Continua fechado para operação.
  if exists (
    select 1
    from private.assessment_test_access_grants g
    where g.organization_id = v_org_id
      and g.test_id = v_test13_id
      and g.status = 'active'
      and g.archived_at is null
  ) then
    raise exception 'FASE6C_POST: Teste 13 ganhou grant ativo inesperado.';
  end if;

  if exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and (
        a.test_id = v_test13_id
        or a.test_version_id = v_test13_v2_id
      )
      and a.archived_at is null
  ) then
    raise exception 'FASE6C_POST: Teste 13 ganhou tentativa inesperada.';
  end if;

  if exists (
    select 1
    from public.certification_requirements cr
    where cr.organization_id = v_org_id
      and (
        cr.assessment_test_id = v_test13_id
        or cr.assessment_test_version_id = v_test13_v2_id
      )
      and cr.archived_at is null
  ) then
    raise exception 'FASE6C_POST: Teste 13 ganhou requisito de certificacao inesperado.';
  end if;

  -- Teste 11 e tentativa histórica permanecem exatamente no mesmo estado.
  if not exists (
    select 1
    from public.assessment_test_versions v
    where v.organization_id = v_org_id
      and v.id = v_test11_v1_id
      and v.test_id = v_test11_id
      and v.version_code = 'cnvw-v3.0-v1'
      and v.status = 'draft'
      and v.passing_score = 90
      and v.legal_min_score = 90
      and v.question_count = 30
      and v.published_at is null
      and v.archived_at is null
  ) then
    raise exception 'FASE6C_POST: versao historica do Teste 11 foi alterada.';
  end if;

  if not exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.id = v_test11_attempt_id
      and a.test_id = v_test11_id
      and a.test_version_id = v_test11_v1_id
      and a.status = 'graded'
      and a.correct_answers = 25
      and round(a.overall_score::numeric, 2) = 83.33
      and round(a.legal_score::numeric, 2) = 83.33
      and a.critical_errors = 0
      and a.passed is false
      and a.result_reason = 'overall_score_below_minimum'
      and a.archived_at is null
  ) then
    raise exception 'FASE6C_POST: tentativa historica do Teste 11 foi alterada.';
  end if;

  -- Fiat permanece 90/90, draft e sem tentativa.
  if not exists (
    select 1
    from public.assessment_test_versions v
    where v.organization_id = v_org_id
      and v.id = v_test12_v1_id
      and v.test_id = v_test12_id
      and v.version_code = 'fiat-v3-v1'
      and v.status = 'draft'
      and v.passing_score = 90
      and v.legal_min_score = 90
      and v.question_count = 30
      and v.published_at is null
      and v.archived_at is null
  ) then
    raise exception 'FASE6C_POST: versao Fiat foi alterada.';
  end if;

  if exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.test_id = v_test12_id
      and a.archived_at is null
  ) then
    raise exception 'FASE6C_POST: Teste 12 Fiat ganhou tentativa inesperada.';
  end if;
end
$policy$;

commit;
