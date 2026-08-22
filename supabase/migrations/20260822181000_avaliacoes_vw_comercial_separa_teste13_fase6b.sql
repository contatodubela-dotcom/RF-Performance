-- ============================================================================
-- RF Performance — Avaliações e Certificações
-- Volkswagen Comercial
-- Fase 6B — Separação da avaliação comercial como Teste 13
--
-- AUTORIZAÇÃO DE ESCOPO:
--   AUTORIZO_SEPARAR_TESTE_COMERCIAL_VW_COMO_TESTE13_FASE6B
--
-- OBJETIVO
--   Corrigir a identidade arquitetural criada na Fase 6A:
--   - preservar integralmente o Teste 11 regulatório e sua tentativa histórica;
--   - criar um novo Teste 13 exclusivamente comercial;
--   - reparentear SOMENTE a versão comercial já criada na Fase 6A;
--   - manter o conteúdo da versão, questões, alternativas, gabaritos e fontes;
--   - corrigir metadados de identidade de Teste 11 -> Teste 13.
--
-- SEGURANÇA
--   - NÃO edita a migration já aplicada da Fase 6A.
--   - NÃO publica qualquer avaliação.
--   - NÃO cria grant.
--   - NÃO cria tentativa.
--   - NÃO altera a tentativa histórica do Teste 11.
--   - NÃO altera o Teste 12 Fiat.
--   - NÃO altera política: a versão comercial continua 100/100 fail-closed.
--   - NÃO renumera a versão comercial: cnvw-v3.0-comercial-v2 / version_no 2
--     é preservada para manter a rastreabilidade da Fase 6A.
-- ============================================================================

begin;

-- ============================================================================
-- 0. GUARDAS FAIL-CLOSED
-- ============================================================================

do $guard$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;

  v_test11_id uuid := 'dd671e5f-39ec-5018-9263-78613361a7db'::uuid;
  v_test11_v1_id uuid := 'fcf8f979-c44e-5993-beef-d023312ab5b7'::uuid;
  v_commercial_v2_id uuid := '58b09fe5-2bc5-5803-ab0a-2a8834c85607'::uuid;

  v_test13_id uuid := '4f97740e-3f9e-559e-b120-cd043a42c755'::uuid;
  v_test13_code text := 'consorcio_vw_comercial_v1';

  v_pilot_id uuid := '49239d09-0f85-471f-8f46-5c240cd98600'::uuid;
  v_historical_attempt_id uuid := 'ea94b2a3-906f-450f-94cc-67dd9a98709d'::uuid;

  v_internal_source_id uuid := '719215e1-d725-5f6b-be61-70e50eee5593'::uuid;
  v_internal_source_version_id uuid := '766c970d-f0f3-5b0a-b4ef-32263adf99a1'::uuid;

  v_count bigint;
begin
  -- Organização.
  if not exists (
    select 1
    from public.organizations o
    where o.id = v_org_id
      and o.slug = 'rf-consorcios'
      and o.status = 'active'
      and o.archived_at is null
  ) then
    raise exception 'FASE6B_ABORT: organizacao RF esperada nao localizada/ativa.';
  end if;

  -- --------------------------------------------------------------------------
  -- Teste 11 histórico precisa continuar exatamente no estado fechado esperado.
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
      and t.description =
          'Avaliação de conhecimento sobre o Regulamento do Contrato de Consórcio CNVW/Embracon, Versão 3.0, estruturada em oito blocos temáticos.'
      and t.purpose = 'certification'
      and t.status = 'draft'
      and t.archived_at is null
      and v.version_code = 'cnvw-v3.0-v1'
      and v.version_no = 1
      and v.status = 'draft'
      and v.passing_score = 90
      and v.legal_min_score = 90
      and v.question_count = 30
      and v.valid_from is null
      and v.valid_until is null
      and v.published_at is null
  ) then
    raise exception 'FASE6B_ABORT: identidade/estado historico do Teste 11 nao confere.';
  end if;

  if not exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.id = v_historical_attempt_id
      and a.test_id = v_test11_id
      and a.test_version_id = v_test11_v1_id
      and a.organization_member_id = v_pilot_id
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
    raise exception 'FASE6B_ABORT: tentativa historica do Teste 11 nao confere.';
  end if;

  select count(*)
    into v_count
  from public.assessment_attempts a
  where a.organization_id = v_org_id
    and a.test_id = v_test11_id
    and a.archived_at is null;

  if v_count <> 1 then
    raise exception
      'FASE6B_ABORT: Teste 11 deveria manter exatamente 1 tentativa historica; encontrado %.',
      v_count;
  end if;

  -- --------------------------------------------------------------------------
  -- Versão comercial criada pela Fase 6A precisa estar intocada e fail-closed.
  -- --------------------------------------------------------------------------
  if not exists (
    select 1
    from public.assessment_test_versions v
    where v.organization_id = v_org_id
      and v.id = v_commercial_v2_id
      and v.test_id = v_test11_id
      and v.version_code = 'cnvw-v3.0-comercial-v2'
      and v.version_no = 2
      and v.status = 'draft'
      and v.passing_score = 100
      and v.legal_min_score = 100
      and v.question_count = 30
      and v.valid_from is null
      and v.valid_until is null
      and v.published_at is null
      and v.metadata->>'modeling_phase' = '6A'
      and v.metadata->>'catalog_family' = 'commercial_regulatory'
      and v.archived_at is null
  ) then
    raise exception 'FASE6B_ABORT: versao comercial v2 nao esta no estado esperado da Fase 6A.';
  end if;

  select count(*)
    into v_count
  from public.assessment_attempts a
  where a.organization_id = v_org_id
    and a.test_version_id = v_commercial_v2_id
    and a.archived_at is null;

  if v_count <> 0 then
    raise exception
      'FASE6B_ABORT: versao comercial v2 possui tentativa e nao pode ser reparentada; encontrado %.',
      v_count;
  end if;

  select count(*)
    into v_count
  from public.assessment_version_questions avq
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_commercial_v2_id
    and avq.archived_at is null;

  if v_count <> 30 then
    raise exception
      'FASE6B_ABORT: versao comercial deveria possuir 30 questoes vinculadas; encontrado %.',
      v_count;
  end if;

  select count(*)
    into v_count
  from public.assessment_question_options o
  join public.assessment_version_questions avq
    on avq.organization_id = o.organization_id
   and avq.question_id = o.question_id
   and avq.test_version_id = v_commercial_v2_id
   and avq.archived_at is null
  where o.organization_id = v_org_id;

  if v_count <> 120 then
    raise exception
      'FASE6B_ABORT: versao comercial deveria possuir 120 alternativas; encontrado %.',
      v_count;
  end if;

  select count(*)
    into v_count
  from private.assessment_question_keys k
  join public.assessment_version_questions avq
    on avq.organization_id = k.organization_id
   and avq.question_id = k.question_id
   and avq.test_version_id = v_commercial_v2_id
   and avq.archived_at is null
  where k.organization_id = v_org_id;

  if v_count <> 30 then
    raise exception
      'FASE6B_ABORT: versao comercial deveria possuir 30 gabaritos privados; encontrado %.',
      v_count;
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
    and avq.test_version_id = v_commercial_v2_id
    and avq.archived_at is null
    and c.is_legal = true;

  if v_count <> 20 then
    raise exception
      'FASE6B_ABORT: esperado 20 questoes REG na versao comercial; encontrado %.',
      v_count;
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
    and avq.test_version_id = v_commercial_v2_id
    and avq.archived_at is null
    and c.is_legal = false;

  if v_count <> 10 then
    raise exception
      'FASE6B_ABORT: esperado 10 questoes COM na versao comercial; encontrado %.',
      v_count;
  end if;

  select count(*)
    into v_count
  from public.assessment_version_sources avs
  where avs.organization_id = v_org_id
    and avs.test_version_id = v_commercial_v2_id
    and avs.relation_type = 'primary'
    and avs.is_required = true
    and avs.archived_at is null;

  if v_count <> 2 then
    raise exception
      'FASE6B_ABORT: esperado exatamente 2 fontes primary|required na versao comercial; encontrado %.',
      v_count;
  end if;

  -- Não pode haver requisito de certificação já apontando para a versão comercial.
  if exists (
    select 1
    from public.certification_requirements cr
    where cr.organization_id = v_org_id
      and cr.assessment_test_version_id = v_commercial_v2_id
      and cr.archived_at is null
  ) then
    raise exception
      'FASE6B_ABORT: existe requisito de certificacao vinculado a versao comercial; reparentamento abortado.';
  end if;

  -- --------------------------------------------------------------------------
  -- O novo Teste 13 precisa estar totalmente livre.
  -- --------------------------------------------------------------------------
  if exists (
    select 1
    from public.assessment_tests t
    where t.organization_id = v_org_id
      and t.archived_at is null
      and (
        t.id = v_test13_id
        or t.sequence_no = 13
        or t.code = v_test13_code
      )
  ) then
    raise exception
      'FASE6B_ABORT: id, sequence_no 13 ou code do novo Teste 13 ja esta ocupado.';
  end if;

  -- Fonte interna criada na Fase 6A precisa existir e continuar íntegra.
  if not exists (
    select 1
    from public.source_materials sm
    join public.source_material_versions smv
      on smv.organization_id = sm.organization_id
     and smv.source_material_id = sm.id
     and smv.id = v_internal_source_version_id
     and smv.archived_at is null
    where sm.organization_id = v_org_id
      and sm.id = v_internal_source_id
      and sm.code = 'teste11_vw_comercial_rf'
      and sm.status = 'active'
      and sm.archived_at is null
      and smv.version_code = '2026.08-revisao2'
      and smv.status = 'active'
      and lower(smv.content_sha256) =
          '8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de'
  ) then
    raise exception 'FASE6B_ABORT: fonte interna comercial da Fase 6A nao confere.';
  end if;

  -- Quatro competências comerciais não legais.
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
    and c.archived_at is null;

  if v_count <> 4 then
    raise exception
      'FASE6B_ABORT: quatro competencias comerciais da Fase 6A nao estao integras; encontrado %.',
      v_count;
  end if;

  -- Teste 12 Fiat continua fechado.
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.organization_id = t.organization_id
     and v.test_id = t.id
     and v.id = '74243315-ea1e-5178-83b8-d6077ab9dc59'::uuid
     and v.archived_at is null
    where t.organization_id = v_org_id
      and t.id = '61d013e4-3b4b-5676-b39c-6d340f87b046'::uuid
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
    raise exception 'FASE6B_ABORT: Teste 12 Fiat nao esta no estado fechado esperado.';
  end if;

  if exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.test_id = '61d013e4-3b4b-5676-b39c-6d340f87b046'::uuid
      and a.archived_at is null
  ) then
    raise exception 'FASE6B_ABORT: Teste 12 Fiat ganhou tentativa inesperada.';
  end if;
end
$guard$;

-- ============================================================================
-- 1. CRIA O NOVO TESTE 13 — IDENTIDADE COMERCIAL INDEPENDENTE
-- ============================================================================

insert into public.assessment_tests (
  id,
  organization_id,
  code,
  sequence_no,
  title,
  description,
  difficulty,
  purpose,
  target_level_id,
  question_count,
  time_limit_minutes,
  max_attempts,
  cooldown_hours,
  status,
  metadata
)
values (
  '4f97740e-3f9e-559e-b120-cd043a42c755'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'consorcio_vw_comercial_v1',
  13,
  'Avaliação Comercial — Consórcio Volkswagen',
  'Avaliação comercial para vendedores do Consórcio Volkswagen com Embracon, com situações de atendimento, objeções, explicação do produto e pontos regulatórios que não podem ser comunicados incorretamente.',
  'intermediate_advanced',
  'certification',
  null,
  30,
  null,
  2,
  24,
  'draft',
  jsonb_build_object(
    'catalog_family', 'commercial_regulatory',
    'brand', 'Volkswagen',
    'administrator', 'CNVW',
    'service_provider', 'Embracon',
    'test_number', 13,
    'commercial_layer', true,
    'question_distribution', jsonb_build_object('commercial', 10, 'regulatory', 20),
    'source_document_version', '3.0',
    'source_content_sha256', '530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09',
    'authoring_document', 'Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md',
    'authoring_document_sha256', '8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de',
    'separation_phase', '6B',
    'separated_from_test_id', 'dd671e5f-39ec-5018-9263-78613361a7db',
    'separated_from_test_number', 11,
    'separated_version_id', '58b09fe5-2bc5-5803-ab0a-2a8834c85607',
    'version_number_preserved_from_phase6a', true,
    'homologation_status', 'draft_candidate'
  )
);

-- ============================================================================
-- 2. REPARENTEIA SOMENTE A VERSÃO COMERCIAL
-- ============================================================================

update public.assessment_test_versions
set
  test_id = '4f97740e-3f9e-559e-b120-cd043a42c755'::uuid,
  metadata =
    coalesce(metadata, '{}'::jsonb)
    || jsonb_build_object(
      'assessment_code', 'consorcio_vw_comercial_v1',
      'test_number', 13,
      'separation_phase', '6B',
      'separated_from_test_id', 'dd671e5f-39ec-5018-9263-78613361a7db',
      'separated_from_test_number', 11,
      'version_number_preserved_from_phase6a', true,
      'homologation_status', 'draft_candidate'
    )
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and id = '58b09fe5-2bc5-5803-ab0a-2a8834c85607'::uuid
  and test_id = 'dd671e5f-39ec-5018-9263-78613361a7db'::uuid
  and version_code = 'cnvw-v3.0-comercial-v2'
  and version_no = 2
  and status = 'draft'
  and passing_score = 100
  and legal_min_score = 100
  and published_at is null
  and archived_at is null;


-- ============================================================================
-- 3. CORRIGE METADADOS DE IDENTIDADE DO CONTEÚDO COMERCIAL
-- ============================================================================

-- Fonte interna: preserva code/título/arquivo/SHA originais como evidência da
-- autoria da Fase 6A, mas registra a identidade definitiva do Teste 13.
update public.source_materials
set metadata =
    coalesce(metadata, '{}'::jsonb)
    || jsonb_build_object(
      'assessment_code', 'consorcio_vw_comercial_v1',
      'assigned_test_id', '4f97740e-3f9e-559e-b120-cd043a42c755',
      'assigned_test_number', 13,
      'separation_phase', '6B',
      'original_modeling_test_number', 11
    )
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and id = '719215e1-d725-5f6b-be61-70e50eee5593'::uuid
  and code = 'teste11_vw_comercial_rf'
  and status = 'active'
  and archived_at is null;


update public.source_material_versions
set metadata =
    coalesce(metadata, '{}'::jsonb)
    || jsonb_build_object(
      'assessment_code', 'consorcio_vw_comercial_v1',
      'assigned_test_id', '4f97740e-3f9e-559e-b120-cd043a42c755',
      'assigned_test_number', 13,
      'separation_phase', '6B',
      'original_modeling_test_number', 11
    )
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and id = '766c970d-f0f3-5b0a-b4ef-32263adf99a1'::uuid
  and source_material_id = '719215e1-d725-5f6b-be61-70e50eee5593'::uuid
  and version_code = '2026.08-revisao2'
  and status = 'active'
  and archived_at is null;


-- Quatro competências comerciais.
update public.competency_domains
set metadata =
    coalesce(metadata, '{}'::jsonb)
    || jsonb_build_object(
      'assessment_code', 'consorcio_vw_comercial_v1',
      'test_number', 13,
      'separation_phase', '6B',
      'original_modeling_test_number', 11
    )
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and id in (
    'f5c28faf-04e4-57c9-99fd-b3ed36495964'::uuid,
    '590aa9ef-61cf-510e-85c2-a7077687036c'::uuid,
    '8488aa2e-82f6-5c83-bdcc-584ebf15d60d'::uuid,
    'c31f1ba9-d96a-5a84-b0a7-8b9de713512f'::uuid
  )
  and is_legal = false
  and archived_at is null;


-- 30 questões pertencentes exclusivamente à versão comercial.
update public.assessment_questions q
set metadata =
      coalesce(q.metadata, '{}'::jsonb)
      || jsonb_build_object(
        'assessment_code', 'consorcio_vw_comercial_v1',
        'test_number', 13,
        'separation_phase', '6B',
        'original_modeling_test_number', 11
      )
where q.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and q.archived_at is null
  and exists (
    select 1
    from public.assessment_version_questions avq
    where avq.organization_id = q.organization_id
      and avq.test_version_id = '58b09fe5-2bc5-5803-ab0a-2a8834c85607'::uuid
      and avq.question_id = q.id
      and avq.archived_at is null
  );


-- 120 alternativas.
update public.assessment_question_options o
set metadata =
      coalesce(o.metadata, '{}'::jsonb)
      || jsonb_build_object(
        'assessment_code', 'consorcio_vw_comercial_v1',
        'test_number', 13,
        'separation_phase', '6B'
      )
where o.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and exists (
    select 1
    from public.assessment_version_questions avq
    where avq.organization_id = o.organization_id
      and avq.test_version_id = '58b09fe5-2bc5-5803-ab0a-2a8834c85607'::uuid
      and avq.question_id = o.question_id
      and avq.archived_at is null
  );

-- 30 gabaritos privados.
update private.assessment_question_keys k
set metadata =
      coalesce(k.metadata, '{}'::jsonb)
      || jsonb_build_object(
        'assessment_code', 'consorcio_vw_comercial_v1',
        'test_number', 13,
        'separation_phase', '6B'
      )
where k.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and exists (
    select 1
    from public.assessment_version_questions avq
    where avq.organization_id = k.organization_id
      and avq.test_version_id = '58b09fe5-2bc5-5803-ab0a-2a8834c85607'::uuid
      and avq.question_id = k.question_id
      and avq.archived_at is null
  );

-- 30 vínculos da versão.
update public.assessment_version_questions avq
set metadata =
      coalesce(avq.metadata, '{}'::jsonb)
      || jsonb_build_object(
        'assessment_code', 'consorcio_vw_comercial_v1',
        'test_number', 13,
        'separation_phase', '6B'
      )
where avq.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and avq.test_version_id = '58b09fe5-2bc5-5803-ab0a-2a8834c85607'::uuid
  and avq.archived_at is null;

-- Duas fontes da versão: a identidade agora é Teste 13.
update public.assessment_version_sources avs
set
  notes =
    case avs.id
      when '562576bd-e3d9-5140-9df2-a4270f854907'::uuid then
        'Fonte normativa primária e obrigatória da versão comercial do Teste 13 — Consórcio Volkswagen.'
      when '4fcee45b-95c1-5a16-8744-626951960922'::uuid then
        'Fonte de autoria comercial controlada que define a redação, classificação COM/REG, gabaritos comentados e referências da versão comercial do Teste 13.'
      else avs.notes
    end,
  metadata =
    coalesce(avs.metadata, '{}'::jsonb)
    || jsonb_build_object(
      'assessment_code', 'consorcio_vw_comercial_v1',
      'test_number', 13,
      'separation_phase', '6B',
      'original_modeling_test_number', 11
    )
where avs.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and avs.test_version_id = '58b09fe5-2bc5-5803-ab0a-2a8834c85607'::uuid
  and avs.id in (
    '562576bd-e3d9-5140-9df2-a4270f854907'::uuid,
    '4fcee45b-95c1-5a16-8744-626951960922'::uuid
  )
  and avs.archived_at is null;

-- ============================================================================
-- 4. PÓS-CONDIÇÕES
-- ============================================================================

do $post$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
  v_test11_id uuid := 'dd671e5f-39ec-5018-9263-78613361a7db'::uuid;
  v_test11_v1_id uuid := 'fcf8f979-c44e-5993-beef-d023312ab5b7'::uuid;
  v_test13_id uuid := '4f97740e-3f9e-559e-b120-cd043a42c755'::uuid;
  v_commercial_v2_id uuid := '58b09fe5-2bc5-5803-ab0a-2a8834c85607'::uuid;
  v_historical_attempt_id uuid := 'ea94b2a3-906f-450f-94cc-67dd9a98709d'::uuid;
  v_count bigint;
begin
  -- Teste 11 voltou a ter somente sua identidade e versão regulatórias.
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
  ) then
    raise exception 'FASE6B_POST: Teste 11 historico nao foi preservado.';
  end if;

  select count(*)
    into v_count
  from public.assessment_test_versions v
  where v.organization_id = v_org_id
    and v.test_id = v_test11_id
    and v.archived_at is null;

  if v_count <> 1 then
    raise exception
      'FASE6B_POST: Teste 11 deveria possuir somente 1 versao ativa no catalogo; encontrado %.',
      v_count;
  end if;

  if not exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.id = v_historical_attempt_id
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
    raise exception 'FASE6B_POST: tentativa historica do Teste 11 foi alterada.';
  end if;

  -- Novo Teste 13.
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.organization_id = t.organization_id
     and v.test_id = t.id
     and v.id = v_commercial_v2_id
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
      and v.metadata->>'assessment_code' = 'consorcio_vw_comercial_v1'
      and v.metadata->>'test_number' = '13'
      and v.metadata->>'separation_phase' = '6B'
  ) then
    raise exception 'FASE6B_POST: identidade/versao do novo Teste 13 nao confere.';
  end if;

  if exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and (
        a.test_id = v_test13_id
        or a.test_version_id = v_commercial_v2_id
      )
      and a.archived_at is null
  ) then
    raise exception 'FASE6B_POST: Teste 13/versao comercial possui tentativa inesperada.';
  end if;

  if exists (
    select 1
    from private.assessment_test_access_grants g
    where g.organization_id = v_org_id
      and g.test_id = v_test13_id
      and g.status = 'active'
      and g.archived_at is null
  ) then
    raise exception 'FASE6B_POST: Teste 13 possui grant ativo inesperado.';
  end if;

  if exists (
    select 1
    from public.certification_requirements cr
    where cr.organization_id = v_org_id
      and (
        cr.assessment_test_id = v_test13_id
        or cr.assessment_test_version_id = v_commercial_v2_id
      )
      and cr.archived_at is null
  ) then
    raise exception 'FASE6B_POST: Teste 13 ganhou requisito de certificacao inesperado.';
  end if;

  -- Estrutura do Teste 13: 30/120/30.
  select count(*)
    into v_count
  from public.assessment_version_questions avq
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_commercial_v2_id
    and avq.archived_at is null;

  if v_count <> 30 then
    raise exception 'FASE6B_POST: Teste 13 nao manteve 30 questoes.';
  end if;

  select count(*)
    into v_count
  from public.assessment_question_options o
  join public.assessment_version_questions avq
    on avq.organization_id = o.organization_id
   and avq.question_id = o.question_id
   and avq.test_version_id = v_commercial_v2_id
   and avq.archived_at is null
  where o.organization_id = v_org_id;

  if v_count <> 120 then
    raise exception 'FASE6B_POST: Teste 13 nao manteve 120 alternativas.';
  end if;

  select count(*)
    into v_count
  from private.assessment_question_keys k
  join public.assessment_version_questions avq
    on avq.organization_id = k.organization_id
   and avq.question_id = k.question_id
   and avq.test_version_id = v_commercial_v2_id
   and avq.archived_at is null
  where k.organization_id = v_org_id;

  if v_count <> 30 then
    raise exception 'FASE6B_POST: Teste 13 nao manteve 30 gabaritos.';
  end if;

  -- 20 REG + 10 COM.
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
    and avq.test_version_id = v_commercial_v2_id
    and avq.archived_at is null
    and c.is_legal = true;

  if v_count <> 20 then
    raise exception 'FASE6B_POST: Teste 13 nao manteve 20 questoes REG.';
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
    and avq.test_version_id = v_commercial_v2_id
    and avq.archived_at is null
    and c.is_legal = false;

  if v_count <> 10 then
    raise exception 'FASE6B_POST: Teste 13 nao manteve 10 questoes COM.';
  end if;

  -- Duas fontes obrigatórias preservadas.
  select count(*)
    into v_count
  from public.assessment_version_sources avs
  where avs.organization_id = v_org_id
    and avs.test_version_id = v_commercial_v2_id
    and avs.relation_type = 'primary'
    and avs.is_required = true
    and avs.archived_at is null;

  if v_count <> 2 then
    raise exception 'FASE6B_POST: Teste 13 nao manteve 2 fontes primary|required.';
  end if;

  -- Metadados principais devem apontar ao Teste 13.
  select count(*)
    into v_count
  from public.assessment_version_questions avq
  join public.assessment_questions q
    on q.organization_id = avq.organization_id
   and q.id = avq.question_id
   and q.archived_at is null
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_commercial_v2_id
    and avq.archived_at is null
    and q.metadata->>'assessment_code' = 'consorcio_vw_comercial_v1'
    and q.metadata->>'test_number' = '13';

  if v_count <> 30 then
    raise exception 'FASE6B_POST: questoes nao apontam integralmente para a identidade do Teste 13.';
  end if;

  select count(*)
    into v_count
  from public.assessment_version_questions avq
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_commercial_v2_id
    and avq.archived_at is null
    and avq.metadata->>'assessment_code' = 'consorcio_vw_comercial_v1'
    and avq.metadata->>'test_number' = '13';

  if v_count <> 30 then
    raise exception 'FASE6B_POST: vinculos da versao nao apontam integralmente para o Teste 13.';
  end if;

  -- Metadados das quatro competências comerciais.
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
    and c.is_legal = false
    and c.metadata->>'assessment_code' = 'consorcio_vw_comercial_v1'
    and c.metadata->>'test_number' = '13'
    and c.metadata->>'separation_phase' = '6B'
    and c.archived_at is null;

  if v_count <> 4 then
    raise exception 'FASE6B_POST: competencias comerciais nao apontam integralmente para o Teste 13.';
  end if;

  -- Fonte interna preserva a identidade documental original e registra destino Teste 13.
  if not exists (
    select 1
    from public.source_materials sm
    join public.source_material_versions smv
      on smv.organization_id = sm.organization_id
     and smv.source_material_id = sm.id
     and smv.id = '766c970d-f0f3-5b0a-b4ef-32263adf99a1'::uuid
     and smv.archived_at is null
    where sm.organization_id = v_org_id
      and sm.id = '719215e1-d725-5f6b-be61-70e50eee5593'::uuid
      and sm.code = 'teste11_vw_comercial_rf'
      and sm.metadata->>'assessment_code' = 'consorcio_vw_comercial_v1'
      and sm.metadata->>'assigned_test_number' = '13'
      and sm.metadata->>'separation_phase' = '6B'
      and smv.metadata->>'assessment_code' = 'consorcio_vw_comercial_v1'
      and smv.metadata->>'assigned_test_number' = '13'
      and smv.metadata->>'separation_phase' = '6B'
      and sm.archived_at is null
  ) then
    raise exception 'FASE6B_POST: fonte interna nao registra corretamente o destino Teste 13.';
  end if;

  -- Fiat permanece intocado.
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.organization_id = t.organization_id
     and v.test_id = t.id
     and v.id = '74243315-ea1e-5178-83b8-d6077ab9dc59'::uuid
     and v.archived_at is null
    where t.organization_id = v_org_id
      and t.id = '61d013e4-3b4b-5676-b39c-6d340f87b046'::uuid
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
    raise exception 'FASE6B_POST: Teste 12 Fiat foi alterado.';
  end if;
end
$post$;

commit;
