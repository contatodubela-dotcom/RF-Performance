-- ============================================================================
-- RF Performance — Avaliações e Certificações
-- Teste 11 Volkswagen — Versão Comercial v2
-- Fase 6A — Modelagem versionada, fail-closed
--
-- AUTORIZAÇÃO DE ESCOPO:
--   AUTORIZO_MODELAGEM_TESTE11_COMERCIAL_V2
--
-- OBJETIVO
--   Criar uma NOVA versão do Teste 11, com linguagem comercial para vendedores,
--   preservando integralmente a versão histórica cnvw-v3.0-v1 e sua tentativa.
--
-- SEGURANÇA
--   - NÃO publica a nova versão.
--   - NÃO cria grant.
--   - NÃO cria tentativa.
--   - NÃO altera questões, gabaritos ou vínculos da versão histórica v1.
--   - NÃO altera o Teste 12 Fiat.
--   - Mantém política da candidata em 100/100 (fail-closed) até autorização
--     separada da política definitiva sugerida (85 geral / 90 regulatório).
--   - Cria 10 questões comerciais (competências não legais) e 20 regulatórias
--     (competências legais já existentes), permitindo legal_score separado.
-- ============================================================================

begin;

do $guard$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
  v_test_id uuid := 'dd671e5f-39ec-5018-9263-78613361a7db'::uuid;
  v_v1_id uuid := 'fcf8f979-c44e-5993-beef-d023312ab5b7'::uuid;
  v_v2_id uuid := '58b09fe5-2bc5-5803-ab0a-2a8834c85607'::uuid;
  v_pilot_id uuid := '49239d09-0f85-471f-8f46-5c240cd98600'::uuid;
  v_attempt_id uuid := 'ea94b2a3-906f-450f-94cc-67dd9a98709d'::uuid;
  v_official_source_version_id uuid := 'aca73af3-6ded-5461-88c9-acbd17064862'::uuid;
  v_internal_source_id uuid := '719215e1-d725-5f6b-be61-70e50eee5593'::uuid;
  v_internal_source_version_id uuid := '766c970d-f0f3-5b0a-b4ef-32263adf99a1'::uuid;
begin
  if not exists (
    select 1
    from public.organizations o
    where o.id = v_org_id
      and o.slug = 'rf-consorcios'
      and o.status = 'active'
      and o.archived_at is null
  ) then
    raise exception 'FASE6A_ABORT: organizacao RF esperada nao localizada/ativa.';
  end if;

  -- Teste 11 deve estar fechado em draft após a homologação histórica 5G2.
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.organization_id = t.organization_id
     and v.test_id = t.id
     and v.id = v_v1_id
     and v.archived_at is null
    where t.organization_id = v_org_id
      and t.id = v_test_id
      and t.sequence_no = 11
      and t.code = 'regulamento_vw_cnvw_v1'
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
      and v.metadata->>'homologation_window_status' = 'closed'
      and v.metadata->>'homologation_window_phase' = '5G2'
      and v.metadata->>'homologation_functional_status' = 'passed'
  ) then
    raise exception 'FASE6A_ABORT: Teste 11 / v1 nao esta no estado historico fechado esperado.';
  end if;

  if (
    select count(*)
    from public.assessment_version_questions avq
    where avq.organization_id = v_org_id
      and avq.test_version_id = v_v1_id
      and avq.archived_at is null
  ) <> 30 then
    raise exception 'FASE6A_ABORT: versao historica v1 deveria manter 30 questoes.';
  end if;

  -- Tentativa histórica deve permanecer exatamente como homologada.
  if not exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.id = v_attempt_id
      and a.test_id = v_test_id
      and a.test_version_id = v_v1_id
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
    raise exception 'FASE6A_ABORT: tentativa historica v1 nao confere.';
  end if;

  if (
    select count(*)
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.test_id = v_test_id
      and a.archived_at is null
  ) <> 1 then
    raise exception 'FASE6A_ABORT: esperado exatamente 1 historico de tentativa no Teste 11.';
  end if;

  if exists (
    select 1
    from private.assessment_test_access_grants g
    where g.organization_id = v_org_id
      and g.test_id = v_test_id
      and g.status = 'active'
      and g.archived_at is null
  ) then
    raise exception 'FASE6A_ABORT: Teste 11 possui grant ativo.';
  end if;

  -- Fonte oficial V3.0 já reconciliada e verificada.
  if not exists (
    select 1
    from public.source_material_versions smv
    where smv.organization_id = v_org_id
      and smv.id = v_official_source_version_id
      and smv.version_code = 'v3.0-res285-23'
      and smv.status = 'active'
      and smv.content_sha256 = '530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09'
      and coalesce((smv.metadata->>'external_currency_verified')::boolean, false) = true
      and smv.archived_at is null
  ) then
    raise exception 'FASE6A_ABORT: fonte oficial CNVW/Embracon V3.0 nao confere.';
  end if;

  -- A nova versão não pode existir previamente.
  if exists (
    select 1
    from public.assessment_test_versions v
    where v.organization_id = v_org_id
      and v.test_id = v_test_id
      and v.archived_at is null
      and (
        v.id = v_v2_id
        or v.version_no = 2
        or v.version_code = 'cnvw-v3.0-comercial-v2'
      )
  ) then
    raise exception 'FASE6A_ABORT: versao comercial v2 ja existe ou version_no 2 esta ocupado.';
  end if;

  -- Fonte interna da autoria comercial deve ser nova.
  if exists (
    select 1
    from public.source_materials sm
    where sm.organization_id = v_org_id
      and sm.archived_at is null
      and (
        sm.id = v_internal_source_id
        or sm.code = 'teste11_vw_comercial_rf'
      )
  ) then
    raise exception 'FASE6A_ABORT: fonte interna comercial do Teste 11 ja existe.';
  end if;

  if exists (
    select 1
    from public.source_material_versions smv
    where smv.organization_id = v_org_id
      and smv.archived_at is null
      and smv.id = v_internal_source_version_id
  ) then
    raise exception 'FASE6A_ABORT: id da versao da fonte interna comercial ja existe.';
  end if;

  -- Competências comerciais 59..62 devem estar livres.
  if exists (
    select 1
    from public.competency_domains c
    where c.organization_id = v_org_id
      and c.archived_at is null
      and (
        c.sequence_no between 59 and 62
        or c.code in (
          'vw_com_produto_posicionamento',
          'vw_com_objecoes_conducao',
          'vw_com_diagnostico_consultivo',
          'vw_com_pos_venda'
        )
        or c.id in (
          'f5c28faf-04e4-57c9-99fd-b3ed36495964'::uuid,
          '590aa9ef-61cf-510e-85c2-a7077687036c'::uuid,
          '8488aa2e-82f6-5c83-bdcc-584ebf15d60d'::uuid,
          'c31f1ba9-d96a-5a84-b0a7-8b9de713512f'::uuid
        )
      )
  ) then
    raise exception 'FASE6A_ABORT: sequencia/codigo/id das competencias comerciais 59..62 ja esta ocupado.';
  end if;

  -- As oito competências regulatórias históricas precisam continuar legais.
  if (
    select count(*)
    from public.competency_domains c
    where c.organization_id = v_org_id
      and c.archived_at is null
      and c.is_legal = true
      and c.id in (
        'dfb721a3-7005-591e-af41-655027fa487b'::uuid,
        '0cf51b7a-f52c-544d-a0ea-c32436d4a113'::uuid,
        '860b1e56-0438-536c-bb88-c213c1b9bfac'::uuid,
        '9c4fdbc5-ed84-5b2f-ba18-0ba6f03b1330'::uuid,
        '24e64406-c6c8-58d8-9e3e-1de6eea804d5'::uuid,
        '976964de-40bf-5860-a663-93737500b1e5'::uuid,
        'baa037cf-3f7f-581e-9d22-de5acfd02004'::uuid,
        '9527c059-e9b5-53c7-a6dd-bc73aaf38a47'::uuid
      )
  ) <> 8 then
    raise exception 'FASE6A_ABORT: competencias regulatorias historicas do VW nao estao integras/is_legal.';
  end if;

  -- Namespace de questões da v2 deve estar livre.
  if exists (
    select 1
    from public.assessment_questions q
    where q.organization_id = v_org_id
      and q.archived_at is null
      and q.code like 'vw_com_v2_q%'
  ) then
    raise exception 'FASE6A_ABORT: namespace vw_com_v2_q ja possui questoes.';
  end if;

  -- Fiat deve permanecer fechado e intocado.
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
    raise exception 'FASE6A_ABORT: Teste 12 Fiat nao esta no estado fechado esperado.';
  end if;

  if exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.test_id = '61d013e4-3b4b-5676-b39c-6d340f87b046'::uuid
      and a.archived_at is null
  ) then
    raise exception 'FASE6A_ABORT: Teste 12 Fiat ganhou tentativa inesperada.';
  end if;
end
$guard$;

-- ============================================================================
-- 1. Fonte interna controlada da autoria comercial revisada
-- ============================================================================

insert into public.source_materials (
  id, organization_id, code, title, description, material_type,
  issuer, status, metadata
)
values (
  '719215e1-d725-5f6b-be61-70e50eee5593'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'teste11_vw_comercial_rf',
  'Teste 11 Comercial — Consórcio Nacional Volkswagen com Embracon',
  'Material de autoria/controladoria RF para linguagem comercial de vendedores, com 30 questões revisadas e rastreabilidade regulatória à fonte CNVW/Embracon V3.0.',
  'internal_content',
  'RF Performance',
  'active',
  jsonb_build_object(
    'catalog_family', 'commercial_regulatory',
    'assessment_code', 'regulamento_vw_cnvw_v1',
    'target_assessment_version', 'cnvw-v3.0-comercial-v2',
    'source_filename', 'Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md',
    'content_sha256', '8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de',
    'authoring_revision', 2,
    'regulatory_source_version_id', 'aca73af3-6ded-5461-88c9-acbd17064862',
    'regulatory_source_sha256', '530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09'
  )
);

insert into public.source_material_versions (
  id, organization_id, source_material_id, version_code, version_no,
  status, effective_from, effective_until, published_at, source_date,
  content_sha256, source_locator, metadata
)
values (
  '766c970d-f0f3-5b0a-b4ef-32263adf99a1'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '719215e1-d725-5f6b-be61-70e50eee5593'::uuid,
  '2026.08-revisao2',
  1,
  'active',
  null,
  null,
  null,
  '2026-08-22'::date,
  '8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de',
  jsonb_build_object(
    'file_name', 'Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md',
    'revision', 2,
    'prepared_on', '2026-08-22'
  ),
  jsonb_build_object(
    'catalog_family', 'commercial_regulatory',
    'version_identity_basis', 'authoring_revision_and_sha256',
    'source_content_sha256', '8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de',
    'regulatory_source_version_id', 'aca73af3-6ded-5461-88c9-acbd17064862',
    'regulatory_source_sha256', '530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09',
    'question_count', 30,
    'commercial_question_count', 10,
    'regulatory_question_count', 20
  )
);

-- ============================================================================
-- 2. Competências comerciais não legais
-- ============================================================================

with payload as (
  select *
  from jsonb_to_recordset($commercial_competencies$[{"id":"f5c28faf-04e4-57c9-99fd-b3ed36495964","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_produto_posicionamento","sequence_no":59,"name":"VW Comercial — Produto e Posicionamento","description":"Explicação do consórcio, diferenciação, crédito, custos e adequação de segmento.","domain_type":"knowledge","is_legal":false,"default_weight":0,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","commercial_layer":true,"authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"590aa9ef-61cf-510e-85c2-a7077687036c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_objecoes_conducao","sequence_no":60,"name":"VW Comercial — Objeções e Condução","description":"Tratamento transparente de objeções de prazo, contemplação e comparação com financiamento.","domain_type":"knowledge","is_legal":false,"default_weight":0,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","commercial_layer":true,"authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"8488aa2e-82f6-5c83-bdcc-584ebf15d60d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_diagnostico_consultivo","sequence_no":61,"name":"VW Comercial — Diagnóstico Consultivo","description":"Investigação de objetivo, urgência, orçamento e adequação do plano antes da proposta.","domain_type":"knowledge","is_legal":false,"default_weight":0,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","commercial_layer":true,"authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"c31f1ba9-d96a-5a84-b0a7-8b9de713512f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_pos_venda","sequence_no":62,"name":"VW Comercial — Pós-venda","description":"Orientação de acompanhamento, canais, assembleias, vencimentos e relacionamento após a contratação.","domain_type":"knowledge","is_legal":false,"default_weight":0,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","commercial_layer":true,"authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}}]$commercial_competencies$::jsonb) as x(
    id uuid,
    organization_id uuid,
    code text,
    sequence_no integer,
    name text,
    description text,
    domain_type text,
    is_legal boolean,
    default_weight numeric,
    status text,
    metadata jsonb
  )
)
insert into public.competency_domains (
  id, organization_id, code, sequence_no, name, description,
  domain_type, is_legal, default_weight, status, metadata
)
select
  id, organization_id, code, sequence_no, name, description,
  domain_type, is_legal, default_weight, status, metadata
from payload;

-- ============================================================================
-- 3. Nova versão do Teste 11 — candidata, sem publicação, fail-closed
-- ============================================================================

insert into public.assessment_test_versions (
  id, organization_id, test_id, version_code, version_no, status,
  passing_score, legal_min_score, question_count, randomize_questions,
  randomize_options, show_review_after_submit, valid_from, valid_until,
  published_at, normative_basis, metadata
)
values (
  '58b09fe5-2bc5-5803-ab0a-2a8834c85607'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'dd671e5f-39ec-5018-9263-78613361a7db'::uuid,
  'cnvw-v3.0-comercial-v2',
  2,
  'draft',
  100,
  100,
  30,
  true,
  true,
  false,
  null,
  null,
  null,
  jsonb_build_array(
    jsonb_build_object(
      'instrument', 'Regulamento do Contrato de Consórcio CNVW/Embracon',
      'version', '3.0',
      'references', jsonb_build_array('Resolução 285/23', 'C.E. 07/24')
    )
  ),
  jsonb_build_object(
    'catalog_family', 'commercial_regulatory',
    'administrator', 'CNVW',
    'commercial_layer', true,
    'source_material_code', 'regulamento_cnvw_embracon',
    'source_material_version_id', 'aca73af3-6ded-5461-88c9-acbd17064862',
    'source_document_version', '3.0',
    'source_content_sha256', '530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09',
    'external_currency_verified', true,
    'authoring_source_material_id', '719215e1-d725-5f6b-be61-70e50eee5593',
    'authoring_source_material_version_id', '766c970d-f0f3-5b0a-b4ef-32263adf99a1',
    'authoring_document', 'Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md',
    'authoring_document_sha256', '8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de',
    'question_distribution', jsonb_build_object('commercial', 10, 'regulatory', 20),
    'approval_policy_defined', false,
    'approval_threshold_placeholder', 100,
    'legal_threshold_placeholder', 100,
    'approval_threshold_strategy', 'fail_closed_until_policy_authorization',
    'proposed_passing_score', 85,
    'proposed_legal_min_score', 90,
    'review_policy_defined', false,
    'legal_review_required_before_publication', true,
    'homologation_status', 'draft_candidate',
    'modeling_phase', '6A'
  )
);

-- Duas fontes primárias e obrigatórias:
-- 1) documento oficial normativo V3.0;
-- 2) material interno controlado que define a formulação comercial das questões.
insert into public.assessment_version_sources (
  id, organization_id, test_version_id, source_material_version_id,
  relation_type, is_required, notes, metadata
)
values
(
  '562576bd-e3d9-5140-9df2-a4270f854907'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '58b09fe5-2bc5-5803-ab0a-2a8834c85607'::uuid,
  'aca73af3-6ded-5461-88c9-acbd17064862'::uuid,
  'primary',
  true,
  'Fonte normativa primária e obrigatória da versão comercial do Teste 11.',
  jsonb_build_object(
    'source_role', 'normative_primary',
    'source_content_sha256', '530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09',
    'external_currency_verified', true,
    'modeling_phase', '6A'
  )
),
(
  '4fcee45b-95c1-5a16-8744-626951960922'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '58b09fe5-2bc5-5803-ab0a-2a8834c85607'::uuid,
  '766c970d-f0f3-5b0a-b4ef-32263adf99a1'::uuid,
  'primary',
  true,
  'Fonte de autoria comercial controlada que define a redação, classificação COM/REG, gabaritos comentados e referências da versão v2.',
  jsonb_build_object(
    'source_role', 'commercial_authoring_primary',
    'source_content_sha256', '8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de',
    'modeling_phase', '6A'
  )
);

-- ============================================================================
-- 4. Questões
-- ============================================================================

with payload as (
  select *
  from jsonb_to_recordset($vw_commercial_questions$[{"id":"4ebfdd04-920c-5c31-920b-75ef4bb9db25","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q01","competency_id":"f5c28faf-04e4-57c9-99fd-b3ed36495964","block_code":"commercial_product","prompt":"Um cliente pergunta: “Consórcio, afinal, é o quê?” Qual resposta é mais clara e correta?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":1,"question_class":"COM","legal_scoring":false,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"a29b5c52-086c-5a41-96a4-e478eacd9bbf","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q02","competency_id":"f5c28faf-04e4-57c9-99fd-b3ed36495964","block_code":"commercial_product","prompt":"O cliente diz: “Mas qual é a principal diferença para financiar o carro?” Qual abordagem é mais adequada?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":2,"question_class":"COM","legal_scoring":false,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"a099493d-aed9-5d2c-b9f9-1fb9dacdc832","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q03","competency_id":"976964de-40bf-5860-a663-93737500b1e5","block_code":"contemplacao_lances","prompt":"Um cliente pergunta: “Se eu entrar hoje, consigo ser contemplado logo?” O vendedor deve responder:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":3,"question_class":"REG","legal_scoring":true,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"ffe7cbf8-9aae-5a97-97df-4dff874289a1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q04","competency_id":"976964de-40bf-5860-a663-93737500b1e5","block_code":"contemplacao_lances","prompt":"Como o vendedor deve explicar as formas de contemplação do consorciado ativo?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":4,"question_class":"REG","legal_scoring":true,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"a593dcaa-912e-573f-9e9c-aad48b6262a9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q05","competency_id":"f5c28faf-04e4-57c9-99fd-b3ed36495964","block_code":"commercial_product","prompt":"Qual explicação é mais útil para um cliente que pergunta o que acontece depois da contemplação?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":5,"question_class":"COM","legal_scoring":false,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"2e0d4900-c29c-53aa-9e74-25b85d472d54","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q06","competency_id":"0cf51b7a-f52c-544d-a0ea-c32436d4a113","block_code":"planos","prompt":"Um cliente quer entender o principal benefício do Plano Smart antes da contemplação. Qual resposta é correta?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":6,"question_class":"REG","legal_scoring":true,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"32c65f63-f761-5e41-93c6-6f624a3adca1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q07","competency_id":"0cf51b7a-f52c-544d-a0ea-c32436d4a113","block_code":"planos","prompt":"Qual é a forma mais correta de explicar o Essencial 50?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":7,"question_class":"REG","legal_scoring":true,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"403b8bbf-a26d-500a-be36-cd8c66a71b36","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q08","competency_id":"590aa9ef-61cf-510e-85c2-a7077687036c","block_code":"commercial_objections","prompt":"Qual resposta demonstra melhor técnica comercial sem distorcer o produto?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":8,"question_class":"COM","legal_scoring":false,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"e2772585-960f-585e-8154-ae1fe8e54510","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q09","competency_id":"f5c28faf-04e4-57c9-99fd-b3ed36495964","block_code":"commercial_product","prompt":"O cliente pergunta: “O que é lance?” Qual resposta é melhor?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":9,"question_class":"COM","legal_scoring":false,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"808090d4-b4ce-565a-bdea-f66dba94638e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q10","competency_id":"976964de-40bf-5860-a663-93737500b1e5","block_code":"contemplacao_lances","prompt":"Como explicar o lance embutido sem induzir o cliente a erro?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":10,"question_class":"REG","legal_scoring":true,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"533e705d-6e3b-576b-bba6-8577be500c5c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q11","competency_id":"dfb721a3-7005-591e-af41-655027fa487b","block_code":"definicoes_adesao","prompt":"O cliente pergunta qual é o papel da CNVW e da Embracon. Qual resposta é correta?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":11,"question_class":"REG","legal_scoring":true,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"a82d22d8-2b51-529d-a6c6-7f50d93fbbb9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q12","competency_id":"f5c28faf-04e4-57c9-99fd-b3ed36495964","block_code":"commercial_product","prompt":"Qual frase é comercialmente forte e ao mesmo tempo transparente?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":12,"question_class":"COM","legal_scoring":false,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"67020dce-e70a-5b74-8f09-03d93cc62555","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q13","competency_id":"dfb721a3-7005-591e-af41-655027fa487b","block_code":"definicoes_adesao","prompt":"Um cliente pergunta por que precisa comprovar renda. Qual explicação está mais alinhada ao regulamento?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":13,"question_class":"REG","legal_scoring":true,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"f23e87b8-5435-548d-b8d0-7cd3e5909acf","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q14","competency_id":"9527c059-e9b5-53c7-a6dd-bc73aaf38a47","block_code":"cessao_exclusao_prescricao","prompt":"O cliente pergunta: “Se eu desistir, recebo tudo de volta na hora?” Qual resposta é adequada?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":14,"question_class":"REG","legal_scoring":true,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"c61bb1ed-c594-5d8a-91d3-5638e12277ce","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q15","competency_id":"9527c059-e9b5-53c7-a6dd-bc73aaf38a47","block_code":"cessao_exclusao_prescricao","prompt":"O cliente pergunta: “Quantas parcelas eu posso atrasar sem problema?” Qual deve ser a postura do vendedor?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":15,"question_class":"REG","legal_scoring":true,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"be6dbed6-3d86-594c-9d87-5879e4e5a2af","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q16","competency_id":"baa037cf-3f7f-581e-9d22-de5acfd02004","block_code":"credito_garantias","prompt":"Após a contemplação e aquisição do veículo, qual explicação é correta sobre a garantia?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":16,"question_class":"REG","legal_scoring":true,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"6bd6c673-9ef0-5ec3-85f6-a3b2327cab2e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q17","competency_id":"8488aa2e-82f6-5c83-bdcc-584ebf15d60d","block_code":"commercial_diagnosis","prompt":"Um empresário pergunta se o Consórcio Volkswagen com a Embracon pode fazer sentido para aquisição planejada de caminhões. Qual resposta é mais adequada?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":17,"question_class":"COM","legal_scoring":false,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"52c11077-fb82-5673-a35c-2abd1f85e670","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q18","competency_id":"590aa9ef-61cf-510e-85c2-a7077687036c","block_code":"commercial_objections","prompt":"O cliente diz: “Prefiro financiar porque quero o carro imediatamente.” Qual resposta é mais profissional?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":18,"question_class":"COM","legal_scoring":false,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"f7a171c4-646d-5a8e-b299-ad7a60a39231","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q19","competency_id":"860b1e56-0438-536c-bb88-c213c1b9bfac","block_code":"contribuicoes_taxas","prompt":"Qual orientação pós-venda é correta?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":19,"question_class":"REG","legal_scoring":true,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"b49fe748-ee8b-5b4d-ac58-e701a6a8abfd","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q20","competency_id":"baa037cf-3f7f-581e-9d22-de5acfd02004","block_code":"credito_garantias","prompt":"Como explicar corretamente a proteção relacionada ao seguro prestamista?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":20,"question_class":"REG","legal_scoring":true,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"7fa22525-b0a9-596e-9dcc-b9da95687bca","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q21","competency_id":"9527c059-e9b5-53c7-a6dd-bc73aaf38a47","block_code":"cessao_exclusao_prescricao","prompt":"O cliente pergunta se pode transferir a cota para outra pessoa. Qual resposta é correta?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":21,"question_class":"REG","legal_scoring":true,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"bb202c4d-8944-5e6d-aa87-6285105c9927","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q22","competency_id":"976964de-40bf-5860-a663-93737500b1e5","block_code":"contemplacao_lances","prompt":"Um consorciado não contemplado pergunta se pode mudar o valor do crédito. Qual explicação é mais segura?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":22,"question_class":"REG","legal_scoring":true,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"f495f6fc-ff83-5878-b7ec-b58e82e952ec","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q23","competency_id":"baa037cf-3f7f-581e-9d22-de5acfd02004","block_code":"credito_garantias","prompt":"O cliente contemplado pergunta se pode comprar um veículo usado. Qual resposta é correta?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":23,"question_class":"REG","legal_scoring":true,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"10a27573-2193-5463-a033-db1c63d182e5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q24","competency_id":"dfb721a3-7005-591e-af41-655027fa487b","block_code":"definicoes_adesao","prompt":"O cliente pergunta: “Quem fiscaliza esse sistema?” Qual resposta é correta?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":24,"question_class":"REG","legal_scoring":true,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"c4fb2eae-8795-5466-b467-92aa35f6fe9f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q25","competency_id":"baa037cf-3f7f-581e-9d22-de5acfd02004","block_code":"credito_garantias","prompt":"O cliente pergunta: “Depois de contemplado posso usar o crédito para qualquer coisa?” Qual resposta está correta?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":25,"question_class":"REG","legal_scoring":true,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"1e919036-13bc-5416-ac8f-6df2e35c26da","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q26","competency_id":"baa037cf-3f7f-581e-9d22-de5acfd02004","block_code":"credito_garantias","prompt":"O cliente contemplado pergunta se poderá pedir o crédito em dinheiro se não comprar o bem. Qual resposta é correta?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":26,"question_class":"REG","legal_scoring":true,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"4f4622b7-0fc6-5671-8029-6b0338b29624","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q27","competency_id":"860b1e56-0438-536c-bb88-c213c1b9bfac","block_code":"contribuicoes_taxas","prompt":"Qual explicação é correta quando o cliente pergunta por que a parcela pode sofrer alteração durante o plano?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":27,"question_class":"REG","legal_scoring":true,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"175692a4-137a-5064-b523-44c036cb4493","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q28","competency_id":"24e64406-c6c8-58d8-9e3e-1de6eea804d5","block_code":"assembleias","prompt":"Qual explicação é mais correta sobre a Assembleia Geral Ordinária?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":28,"question_class":"REG","legal_scoring":true,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"e581bbdb-90ef-5012-bb51-2066dcd933b1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q29","competency_id":"8488aa2e-82f6-5c83-bdcc-584ebf15d60d","block_code":"commercial_diagnosis","prompt":"Antes de recomendar um plano ao cliente, qual conduta comercial é mais responsável?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":29,"question_class":"COM","legal_scoring":false,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}},{"id":"79a53971-b2ae-5796-b72e-136d35187038","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vw_com_v2_q30","competency_id":"c31f1ba9-d96a-5a84-b0a7-8b9de713512f","block_code":"commercial_post_sale","prompt":"Depois da contratação, qual postura gera um pós-venda mais responsável?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v3.0-comercial-v2","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":30,"question_class":"COM","legal_scoring":false,"official_source_version_id":"aca73af3-6ded-5461-88c9-acbd17064862","official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document":"Teste_11_Comercial_Vendedores_CNVW_Embracon_Revisado_v2.md","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","homologation_status":"draft_candidate"}}]$vw_commercial_questions$::jsonb) as x(
    id uuid,
    organization_id uuid,
    code text,
    competency_id uuid,
    block_code text,
    prompt text,
    question_type text,
    difficulty text,
    content_version text,
    legal_review_date date,
    status text,
    metadata jsonb
  )
)
insert into public.assessment_questions (
  id, organization_id, code, competency_id, block_code, prompt,
  question_type, difficulty, content_version, legal_review_date, status, metadata
)
select
  id, organization_id, code, competency_id, block_code, prompt,
  question_type, difficulty, content_version, legal_review_date, status, metadata
from payload;

-- ============================================================================
-- 5. Alternativas
-- ============================================================================

with payload as (
  select *
  from jsonb_to_recordset($vw_commercial_options$[{"id":"b1e7a684-58e5-584f-a570-561ccda03238","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4ebfdd04-920c-5c31-920b-75ef4bb9db25","option_code":"A","option_text":"É um financiamento coletivo com juros menores.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":1,"question_class":"COM"}},{"id":"ce1b57f4-0c47-5848-b208-39fd3f3225cb","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4ebfdd04-920c-5c31-920b-75ef4bb9db25","option_code":"B","option_text":"É um grupo de pessoas ou empresas que contribuem para um fundo comum com o objetivo de adquirir bens por autofinanciamento.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":1,"question_class":"COM"}},{"id":"965d49c8-eac7-5bda-9215-b1bdd44833d9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4ebfdd04-920c-5c31-920b-75ef4bb9db25","option_code":"C","option_text":"É um investimento que garante valorização do dinheiro.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":1,"question_class":"COM"}},{"id":"c6daac16-8ad3-5bcd-9fda-fd87e6205c8c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4ebfdd04-920c-5c31-920b-75ef4bb9db25","option_code":"D","option_text":"É um empréstimo liberado depois de alguns meses.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":1,"question_class":"COM"}},{"id":"2b7f2787-e1f6-548b-bb08-2b28df95c8b6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a29b5c52-086c-5a41-96a4-e478eacd9bbf","option_code":"A","option_text":"“No consórcio não existe nenhum custo.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":2,"question_class":"COM"}},{"id":"b4dfc517-0d38-5e9f-a776-a80b20d3fb76","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a29b5c52-086c-5a41-96a4-e478eacd9bbf","option_code":"B","option_text":"“No consórcio você não paga juros de financiamento; existem taxa de administração e demais componentes previstos no contrato.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":2,"question_class":"COM"}},{"id":"dfccd1b6-5088-50bd-8289-49be8db11897","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a29b5c52-086c-5a41-96a4-e478eacd9bbf","option_code":"C","option_text":"“Consórcio sempre sai mais barato em qualquer situação.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":2,"question_class":"COM"}},{"id":"71e845e7-2495-5afd-a529-ebeace5fd442","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a29b5c52-086c-5a41-96a4-e478eacd9bbf","option_code":"D","option_text":"“Financiamento e consórcio são iguais, muda apenas o nome.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":2,"question_class":"COM"}},{"id":"dd873cf3-8417-52fb-9621-17cd05dec459","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a099493d-aed9-5d2c-b9f9-1fb9dacdc832","option_code":"A","option_text":"“Sim. Em até 30 dias é praticamente certo.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":3,"question_class":"REG"}},{"id":"f0a224a6-d3c8-5485-a296-fc61463f50eb","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a099493d-aed9-5d2c-b9f9-1fb9dacdc832","option_code":"B","option_text":"“Se você der um lance, eu garanto a contemplação.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":3,"question_class":"REG"}},{"id":"8a8bb75c-6528-5850-ac4b-e1701da53472","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a099493d-aed9-5d2c-b9f9-1fb9dacdc832","option_code":"C","option_text":"“Existe possibilidade de contemplação por sorteio ou lance, mas não é correto prometer uma data.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":3,"question_class":"REG"}},{"id":"90e6d0d3-7e74-5a96-9763-fdd033a637e2","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a099493d-aed9-5d2c-b9f9-1fb9dacdc832","option_code":"D","option_text":"“Só é possível ser contemplado depois de pagar metade do plano.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":3,"question_class":"REG"}},{"id":"b227a3de-e143-5805-9c9a-e7cacd81e453","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ffe7cbf8-9aae-5a97-97df-4dff874289a1","option_code":"A","option_text":"Somente por sorteio.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":4,"question_class":"REG"}},{"id":"e86b3bc0-8766-51b3-a857-9063ec212f70","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ffe7cbf8-9aae-5a97-97df-4dff874289a1","option_code":"B","option_text":"Somente por lance.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":4,"question_class":"REG"}},{"id":"59a5f1db-5ed3-507f-b1ec-f6b7ced7bd30","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ffe7cbf8-9aae-5a97-97df-4dff874289a1","option_code":"C","option_text":"Por sorteio ou lance, conforme as regras do grupo e da assembleia.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":4,"question_class":"REG"}},{"id":"cdfc94d4-0ab6-5e04-9a13-b59bb424946d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ffe7cbf8-9aae-5a97-97df-4dff874289a1","option_code":"D","option_text":"Por decisão da concessionária.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":4,"question_class":"REG"}},{"id":"54998da9-ac45-5b0f-8bc2-82589a3d0a9b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a593dcaa-912e-573f-9e9c-aad48b6262a9","option_code":"A","option_text":"“Você recebe automaticamente dinheiro livre na sua conta.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":5,"question_class":"COM"}},{"id":"dda9ac90-4f1b-5a1e-869a-613f9eb7207b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a593dcaa-912e-573f-9e9c-aad48b6262a9","option_code":"B","option_text":"“A contemplação dá o direito de utilizar o crédito contratado para adquirir o bem dentro das regras do plano.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":5,"question_class":"COM"}},{"id":"ee82e999-7ec9-535e-b919-e132c0f25ff5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a593dcaa-912e-573f-9e9c-aad48b6262a9","option_code":"C","option_text":"“A administradora escolhe o veículo por você.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":5,"question_class":"COM"}},{"id":"ff8a2ce6-9811-51a2-93e8-6cab3353cc2a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a593dcaa-912e-573f-9e9c-aad48b6262a9","option_code":"D","option_text":"“O crédito vira um cartão de compras.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":5,"question_class":"COM"}},{"id":"d7eb8d41-3730-5479-aecb-a592d0465afb","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"2e0d4900-c29c-53aa-9e74-25b85d472d54","option_code":"A","option_text":"“Você não paga nenhuma taxa de administração desde a primeira parcela.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":6,"question_class":"REG"}},{"id":"af8c7c9e-8d2d-5a32-b618-7e2ab26cf556","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"2e0d4900-c29c-53aa-9e74-25b85d472d54","option_code":"B","option_text":"“Há benefício de isenção da taxa de administração sobre cada parcela paga até a contemplação, mas a taxa de administração antecipada prevista no contrato continua incidindo nas primeiras parcelas.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":6,"question_class":"REG"}},{"id":"ec8ac73b-fddf-5867-9844-754bc134d0a4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"2e0d4900-c29c-53aa-9e74-25b85d472d54","option_code":"C","option_text":"“Depois de contemplado, a taxa de administração deixa de existir.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":6,"question_class":"REG"}},{"id":"af5059bc-ddb4-5d52-8a79-5fa875fd6b01","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"2e0d4900-c29c-53aa-9e74-25b85d472d54","option_code":"D","option_text":"“O Plano Smart garante contemplação mais rápida.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":6,"question_class":"REG"}},{"id":"54c1e1d8-c194-569d-95c5-a9db3fafec01","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"32c65f63-f761-5e41-93c6-6f624a3adca1","option_code":"A","option_text":"“O carro fica 50% mais barato.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":7,"question_class":"REG"}},{"id":"4ffab977-de86-50b8-9fb9-ddd76b44e354","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"32c65f63-f761-5e41-93c6-6f624a3adca1","option_code":"B","option_text":"“Todos os componentes da parcela ficam obrigatoriamente pela metade.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":7,"question_class":"REG"}},{"id":"64ff3e48-8ab6-5a4e-b90e-7b3d5db05173","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"32c65f63-f761-5e41-93c6-6f624a3adca1","option_code":"C","option_text":"“Até a contemplação, o recolhimento mensal ao fundo comum e ao fundo de reserva, quando houver, é reduzido em 50%; para utilizar 100% do crédito, a diferença precisa ser tratada pelas opções previstas no contrato.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":7,"question_class":"REG"}},{"id":"016cadf4-e39e-5fa3-bf78-e04edb6b2ec7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"32c65f63-f761-5e41-93c6-6f624a3adca1","option_code":"D","option_text":"“O cliente recebe apenas 50% do crédito em qualquer situação.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":7,"question_class":"REG"}},{"id":"111bd7e9-320e-5d02-9b80-aea61300fef6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"403b8bbf-a26d-500a-be36-cd8c66a71b36","option_code":"A","option_text":"“Fique tranquilo, eu consigo uma data para você.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":8,"question_class":"COM"}},{"id":"fffc0d00-a272-519b-bba6-f03c656f0db8","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"403b8bbf-a26d-500a-be36-cd8c66a71b36","option_code":"B","option_text":"“Essa incerteza existe porque a contemplação ocorre pelas regras do grupo. Se prazo imediato for indispensável, precisamos avaliar se o consórcio é adequado; se houver planejamento, sorteio e lance são os caminhos de contemplação.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":8,"question_class":"COM"}},{"id":"f34f5539-5e48-5cf3-8d6c-852b13d173db","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"403b8bbf-a26d-500a-be36-cd8c66a71b36","option_code":"C","option_text":"“Todo cliente que paga em dia é contemplado rapidamente.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":8,"question_class":"COM"}},{"id":"ebd4e552-025e-5d28-a4b4-93f4f50fffe5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"403b8bbf-a26d-500a-be36-cd8c66a71b36","option_code":"D","option_text":"“Não fale sobre prazo para o cliente não desistir.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":8,"question_class":"COM"}},{"id":"c0ba7a9b-2c2d-5f5c-9e5f-818773aefe99","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"e2772585-960f-585e-8154-ae1fe8e54510","option_code":"A","option_text":"É uma taxa extra cobrada pela administradora.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":9,"question_class":"COM"}},{"id":"60e85412-f660-55ef-8211-c1391f481046","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"e2772585-960f-585e-8154-ae1fe8e54510","option_code":"B","option_text":"É uma oferta feita pelo consorciado para tentar antecipar a contemplação, sujeita às regras da assembleia.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":9,"question_class":"COM"}},{"id":"7bf4965b-2ae0-5b86-8b5c-a68e8f3dcff8","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"e2772585-960f-585e-8154-ae1fe8e54510","option_code":"C","option_text":"É uma garantia de contemplação.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":9,"question_class":"COM"}},{"id":"73c84861-a852-5ccb-a0d3-67a71e8cd10d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"e2772585-960f-585e-8154-ae1fe8e54510","option_code":"D","option_text":"É um seguro obrigatório.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":9,"question_class":"COM"}},{"id":"da7495f9-4c29-577c-8b5c-6dac3835d818","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"808090d4-b4ce-565a-bdea-f66dba94638e","option_code":"A","option_text":"É um bônus gratuito concedido pela administradora.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":10,"question_class":"REG"}},{"id":"c7fcb1d7-1c11-5603-95b0-71084b7d73da","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"808090d4-b4ce-565a-bdea-f66dba94638e","option_code":"B","option_text":"Usa parte do próprio crédito contratado como lance; se utilizado, essa parcela é deduzida do crédito disponível.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":10,"question_class":"REG"}},{"id":"4bea8026-ff7a-5753-b0e9-32af0c5488eb","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"808090d4-b4ce-565a-bdea-f66dba94638e","option_code":"C","option_text":"Dobra o valor da carta de crédito.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":10,"question_class":"REG"}},{"id":"6e103225-9682-5e79-8c19-65d323de0843","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"808090d4-b4ce-565a-bdea-f66dba94638e","option_code":"D","option_text":"Elimina o saldo devedor do consórcio.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":10,"question_class":"REG"}},{"id":"0109ee0b-9bc3-5942-808d-16c0f8283bb8","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"533e705d-6e3b-576b-bba6-8577be500c5c","option_code":"A","option_text":"A Embracon é a única responsável legal pelos grupos.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":11,"question_class":"REG"}},{"id":"e9d22ae0-6eba-5f76-af02-4508536612a1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"533e705d-6e3b-576b-bba6-8577be500c5c","option_code":"B","option_text":"A concessionária é responsável legal pelo grupo depois da venda.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":11,"question_class":"REG"}},{"id":"e030d6c9-27f9-5ffa-82c1-477cf4bd0ef0","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"533e705d-6e3b-576b-bba6-8577be500c5c","option_code":"C","option_text":"CNVW e Embracon possuem parceria de prestação de serviços, e o Consórcio Nacional Volkswagen é o responsável legal pelos grupos, conforme o regulamento.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":11,"question_class":"REG"}},{"id":"efcb6380-db7d-5769-92be-1aa53bff1eac","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"533e705d-6e3b-576b-bba6-8577be500c5c","option_code":"D","option_text":"Nenhuma das empresas responde pelo grupo; a responsabilidade é do Banco Central.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":11,"question_class":"REG"}},{"id":"792eb092-79d5-5615-8bea-753d558c94f7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a82d22d8-2b51-529d-a6c6-7f50d93fbbb9","option_code":"A","option_text":"“Consórcio não tem juros de financiamento, mas existem custos previstos no contrato, como taxa de administração e outros componentes aplicáveis ao plano.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":12,"question_class":"COM"}},{"id":"a65b08d7-96cd-554a-8f85-af8d19a748ee","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a82d22d8-2b51-529d-a6c6-7f50d93fbbb9","option_code":"B","option_text":"“Consórcio não tem custo nenhum.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":12,"question_class":"COM"}},{"id":"ca03f7a4-762b-5991-91a5-f03a6841a3cd","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a82d22d8-2b51-529d-a6c6-7f50d93fbbb9","option_code":"C","option_text":"“A taxa de administração é opcional.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":12,"question_class":"COM"}},{"id":"31095a03-55ff-58d7-b48d-7fb238a36f86","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a82d22d8-2b51-529d-a6c6-7f50d93fbbb9","option_code":"D","option_text":"“Os custos só aparecem depois da contemplação.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":12,"question_class":"COM"}},{"id":"e79c4c24-d07c-5d83-b48a-df2cea3026a8","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"67020dce-e70a-5b74-8f09-03d93cc62555","option_code":"A","option_text":"“É apenas uma formalidade interna.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":13,"question_class":"REG"}},{"id":"a83b1f16-558d-5fa6-a293-c2174270bfff","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"67020dce-e70a-5b74-8f09-03d93cc62555","option_code":"B","option_text":"“A administradora verifica a capacidade de pagamento; o regulamento considera, entre os critérios, comprovação de renda/remuneração mensal igual ou superior a três vezes o valor da parcela, observadas as regras aplicáveis.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":13,"question_class":"REG"}},{"id":"67f491a1-3180-57cb-8a9e-bf21bab0242d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"67020dce-e70a-5b74-8f09-03d93cc62555","option_code":"C","option_text":"“Somente pessoa jurídica comprova renda.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":13,"question_class":"REG"}},{"id":"68815dd1-b796-5af2-b82e-06f87f02b8e1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"67020dce-e70a-5b74-8f09-03d93cc62555","option_code":"D","option_text":"“A renda só é analisada depois que o cliente compra o veículo.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":13,"question_class":"REG"}},{"id":"cde4e6f3-f3b3-5f19-891a-f09f21d1c4af","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f23e87b8-5435-548d-b8d0-7cd3e5909acf","option_code":"A","option_text":"“Sim, a devolução é imediata.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":14,"question_class":"REG"}},{"id":"af2c4a1b-2bf2-51fb-a3d1-80e1c38e4794","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f23e87b8-5435-548d-b8d0-7cd3e5909acf","option_code":"B","option_text":"“Não existe possibilidade de desistência.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":14,"question_class":"REG"}},{"id":"d7d5a82b-125d-5e59-9cc9-e5bafc9ce0bb","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f23e87b8-5435-548d-b8d0-7cd3e5909acf","option_code":"C","option_text":"“A desistência leva à exclusão, e a restituição segue as regras do grupo, normalmente vinculada à contemplação da cota excluída por sorteio e sujeita às deduções contratuais aplicáveis.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":14,"question_class":"REG"}},{"id":"3420d97e-846a-5cba-bbdd-e45955577a80","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f23e87b8-5435-548d-b8d0-7cd3e5909acf","option_code":"D","option_text":"“A devolução depende da autorização do vendedor.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":14,"question_class":"REG"}},{"id":"959268a0-7709-5280-ace4-0278ece1e85b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c61bb1ed-c594-5d8a-91d3-5638e12277ce","option_code":"A","option_text":"Garantir que existe uma tolerância fixa e que nada acontece antes dela.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":15,"question_class":"REG"}},{"id":"35efdf6a-d87b-57d9-8730-e30712766cd4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c61bb1ed-c594-5d8a-91d3-5638e12277ce","option_code":"B","option_text":"Incentivar o cliente a atrasar e regularizar quando puder.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":15,"question_class":"REG"}},{"id":"08d7b648-529c-51a2-b6e9-721bab75ad2a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c61bb1ed-c594-5d8a-91d3-5638e12277ce","option_code":"C","option_text":"Explicar que atraso pode gerar perda do direito de concorrer à contemplação e até exclusão, e orientar o cliente a consultar a regra vigente do contrato/canais oficiais em vez de prometer uma tolerância.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":15,"question_class":"REG"}},{"id":"57eabf9f-c429-5d14-a9d3-d0eb000f3248","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c61bb1ed-c594-5d8a-91d3-5638e12277ce","option_code":"D","option_text":"Dizer que atraso só gera juros e nunca afeta a participação no grupo.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":15,"question_class":"REG"}},{"id":"9f6e75ab-2cff-5e0c-9e20-e72de479a710","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"be6dbed6-3d86-594c-9d87-5879e4e5a2af","option_code":"A","option_text":"O veículo sempre fica livre de garantia.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":16,"question_class":"REG"}},{"id":"e24e4ca9-6b24-5bfd-aae8-fb796423144d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"be6dbed6-3d86-594c-9d87-5879e4e5a2af","option_code":"B","option_text":"A modalidade de garantia prevista para o bem é a alienação fiduciária em favor da administradora, enquanto existirem as obrigações correspondentes.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":16,"question_class":"REG"}},{"id":"c7e20a79-ea48-5d4f-a89b-385157ed188e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"be6dbed6-3d86-594c-9d87-5879e4e5a2af","option_code":"C","option_text":"O cliente obrigatoriamente precisa dar um imóvel em garantia.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":16,"question_class":"REG"}},{"id":"c94bcc83-410c-5db8-96fc-22b2032bc1a5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"be6dbed6-3d86-594c-9d87-5879e4e5a2af","option_code":"D","option_text":"A garantia é prestada pela concessionária, não pela administradora.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":16,"question_class":"REG"}},{"id":"cde6bffb-bc31-5ce4-9fad-cae68a425b3f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"6bd6c673-9ef0-5ec3-85f6-a3b2327cab2e","option_code":"A","option_text":"“Não. O produto é exclusivo para automóvel de pessoa física.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":17,"question_class":"COM"}},{"id":"181cbcb3-99d9-5013-a786-dc5f58f83db3","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"6bd6c673-9ef0-5ec3-85f6-a3b2327cab2e","option_code":"B","option_text":"“Existe oferta de consórcio para carros e caminhões; precisamos verificar o segmento, crédito e plano disponíveis para a necessidade da empresa.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":17,"question_class":"COM"}},{"id":"64e447c4-983f-5653-8b49-073f1532ff2d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"6bd6c673-9ef0-5ec3-85f6-a3b2327cab2e","option_code":"C","option_text":"“Sim, e toda empresa é contemplada mais rápido.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":17,"question_class":"COM"}},{"id":"54e2d174-e06d-5f3d-a7ac-92c678cf9414","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"6bd6c673-9ef0-5ec3-85f6-a3b2327cab2e","option_code":"D","option_text":"“Sim, mas somente para veículo usado.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":17,"question_class":"COM"}},{"id":"bdad987f-85d4-520a-8388-3ce49071ea37","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"52c11077-fb82-5673-a35c-2abd1f85e670","option_code":"A","option_text":"“Então consórcio nunca serve para você.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":18,"question_class":"COM"}},{"id":"51235bcd-08da-56e8-ad0c-97c12dfd5289","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"52c11077-fb82-5673-a35c-2abd1f85e670","option_code":"B","option_text":"“O financiamento pode atender melhor quando a necessidade é imediata. O consórcio é outra lógica: compra planejada, sem juros de financiamento e com contemplação por sorteio ou lance. Precisamos entender qual prioridade é maior para você.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":18,"question_class":"COM"}},{"id":"c2c5f0e5-ec7c-5b9e-83f6-41f2ebfa936f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"52c11077-fb82-5673-a35c-2abd1f85e670","option_code":"C","option_text":"“No consórcio a entrega também é imediata.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":18,"question_class":"COM"}},{"id":"1cbc3764-52c2-5e81-9c0a-602a79894d07","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"52c11077-fb82-5673-a35c-2abd1f85e670","option_code":"D","option_text":"“Financiamento sempre é uma escolha ruim.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":18,"question_class":"COM"}},{"id":"c0324c10-1e4e-509c-9b41-8219b2baa2e4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f7a171c4-646d-5a8e-b299-ad7a60a39231","option_code":"A","option_text":"Se o boleto não chegar, o cliente pode ignorar o vencimento.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":19,"question_class":"REG"}},{"id":"26bcd948-ee6d-55c1-83ab-f27490be1bd3","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f7a171c4-646d-5a8e-b299-ad7a60a39231","option_code":"B","option_text":"O cliente deve observar o vencimento mesmo se houver atraso no aviso de cobrança e manter seus dados cadastrais atualizados, pois comunicações são feitas pelos canais informados.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":19,"question_class":"REG"}},{"id":"be218d7b-31a0-5ebe-b3ca-147d24a05a99","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f7a171c4-646d-5a8e-b299-ad7a60a39231","option_code":"C","option_text":"O vendedor é responsável por pagar o boleto se o cliente não recebê-lo.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":19,"question_class":"REG"}},{"id":"7b01b542-fcc1-55f2-afdc-5dbac93af957","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f7a171c4-646d-5a8e-b299-ad7a60a39231","option_code":"D","option_text":"O aviso de cobrança só pode ser enviado em papel.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":19,"question_class":"REG"}},{"id":"1dbc6efc-ad15-57ea-8b5a-2280b4a13a9a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"b49fe748-ee8b-5b4d-ac58-e701a6a8abfd","option_code":"A","option_text":"“Se o cliente morrer, qualquer cota é quitada automaticamente.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":20,"question_class":"REG"}},{"id":"3b0c1562-8420-5b1f-9682-05f480353d9e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"b49fe748-ee8b-5b4d-ac58-e701a6a8abfd","option_code":"B","option_text":"“Se houver seguro prestamista contratado, o sinistro for aprovado e a indenização atender às condições do regulamento, o valor pago pela seguradora pode ser tratado como lance vencedor para a contemplação, observada também a disponibilidade de recursos do grupo.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":20,"question_class":"REG"}},{"id":"9741c6f8-52de-559c-b9b8-e06a43c51950","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"b49fe748-ee8b-5b4d-ac58-e701a6a8abfd","option_code":"C","option_text":"“O seguro é obrigatório em todos os planos e sempre paga o carro inteiro.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":20,"question_class":"REG"}},{"id":"b52aa523-c5e9-557b-b048-e78559f1d2aa","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"b49fe748-ee8b-5b4d-ac58-e701a6a8abfd","option_code":"D","option_text":"“A cota é automaticamente cancelada e os herdeiros não têm qualquer direito.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":20,"question_class":"REG"}},{"id":"aeda81f8-96a5-55df-89f7-f6d6c2eefabe","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"7fa22525-b0a9-596e-9dcc-b9da95687bca","option_code":"A","option_text":"“Pode transferir diretamente, sem aprovação.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":21,"question_class":"REG"}},{"id":"a1d4ec21-a2ff-5184-8198-f8eebc672a50","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"7fa22525-b0a9-596e-9dcc-b9da95687bca","option_code":"B","option_text":"“A transferência é possível, mas depende de anuência e aceite da administradora, análise aplicável e pagamento da taxa de transferência prevista.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":21,"question_class":"REG"}},{"id":"81cfaaf2-8083-5fc9-8a21-f2cebae14c51","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"7fa22525-b0a9-596e-9dcc-b9da95687bca","option_code":"C","option_text":"“Só pode transferir para parentes.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":21,"question_class":"REG"}},{"id":"ff11f8f2-7a18-5906-9ac7-d22c78682797","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"7fa22525-b0a9-596e-9dcc-b9da95687bca","option_code":"D","option_text":"“Cota de consórcio nunca pode ser transferida.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":21,"question_class":"REG"}},{"id":"a81bd57e-ceeb-56a5-bc97-85c4db49e83a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"bb202c4d-8944-5e6d-aa87-6285105c9927","option_code":"A","option_text":"“Pode mudar quantas vezes quiser.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":22,"question_class":"REG"}},{"id":"7f15be24-23ef-597a-bcf5-fb764ae051f1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"bb202c4d-8944-5e6d-aa87-6285105c9927","option_code":"B","option_text":"“Nunca pode mudar.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":22,"question_class":"REG"}},{"id":"21c6549f-3a86-5666-b011-d1025cd50981","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"bb202c4d-8944-5e6d-aa87-6285105c9927","option_code":"C","option_text":"“O regulamento permite solicitar a mudança uma única vez, após a quinta assembleia de participação, dentro dos limites do grupo e das demais condições previstas.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":22,"question_class":"REG"}},{"id":"96329b71-c8db-55e2-83dc-4f0735109bec","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"bb202c4d-8944-5e6d-aa87-6285105c9927","option_code":"D","option_text":"“Pode mudar somente depois de contemplado.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":22,"question_class":"REG"}},{"id":"23e0f5a7-d037-531a-89a3-d6addd09cf95","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f495f6fc-ff83-5878-b7ec-b58e82e952ec","option_code":"A","option_text":"“Não, o consórcio aceita somente veículo zero quilômetro.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":23,"question_class":"REG"}},{"id":"2bc0b253-2a3e-554e-85f1-75c741a34a67","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f495f6fc-ff83-5878-b7ec-b58e82e952ec","option_code":"B","option_text":"“Pode, desde que a aquisição esteja dentro do segmento do plano e sejam cumpridos os documentos, avaliação, vistoria e demais condições exigidas pela administradora.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":23,"question_class":"REG"}},{"id":"75b4ec7b-e216-5f8d-8a50-b62adf2caff8","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f495f6fc-ff83-5878-b7ec-b58e82e952ec","option_code":"C","option_text":"“Pode comprar qualquer veículo usado, independentemente de categoria ou avaliação.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":23,"question_class":"REG"}},{"id":"5e546c02-3a95-5d13-b868-764140f5b4a3","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f495f6fc-ff83-5878-b7ec-b58e82e952ec","option_code":"D","option_text":"“Veículo usado só pode ser comprado de pessoa jurídica.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":23,"question_class":"REG"}},{"id":"81dea5e9-c45c-5782-a2b6-061a279a1699","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"10a27573-2193-5463-a033-db1c63d182e5","option_code":"A","option_text":"Apenas a Volkswagen.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":24,"question_class":"REG"}},{"id":"4f795e2b-c63b-5ef1-8f1a-d25c550f3300","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"10a27573-2193-5463-a033-db1c63d182e5","option_code":"B","option_text":"Apenas a Embracon.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":24,"question_class":"REG"}},{"id":"6e507759-9405-5b32-bda0-ed685ffd7f8b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"10a27573-2193-5463-a033-db1c63d182e5","option_code":"C","option_text":"O sistema de consórcios é regulado e fiscalizado pelo Banco Central do Brasil, e a CNVW é administradora autorizada.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":24,"question_class":"REG"}},{"id":"39ecdbe9-96e5-5233-a067-3d7c5a725e81","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"10a27573-2193-5463-a033-db1c63d182e5","option_code":"D","option_text":"Não existe órgão fiscalizador.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":24,"question_class":"REG"}},{"id":"933b8855-6910-53ae-9e29-c99586e5f8d1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c4fb2eae-8795-5466-b467-92aa35f6fe9f","option_code":"A","option_text":"Sim, depois da contemplação o dinheiro é livre.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":25,"question_class":"REG"}},{"id":"64b9e0a5-ea98-532a-98c2-e065a360b584","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c4fb2eae-8795-5466-b467-92aa35f6fe9f","option_code":"B","option_text":"Não. O crédito deve ser utilizado para aquisição de bem compatível com a natureza, categoria e espécie referenciada no plano, observadas as regras contratuais.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":25,"question_class":"REG"}},{"id":"68adf367-4fad-5a8a-ac81-7f643e6f05e8","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c4fb2eae-8795-5466-b467-92aa35f6fe9f","option_code":"C","option_text":"Só pode ser usado para pagar parcelas.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":25,"question_class":"REG"}},{"id":"02e634cf-bf6b-57ee-b7c1-a930282d8113","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c4fb2eae-8795-5466-b467-92aa35f6fe9f","option_code":"D","option_text":"Pode ser usado para viagens e despesas pessoais.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":25,"question_class":"REG"}},{"id":"c555cb89-4bea-5bd6-8f78-80c7ad7f395b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1e919036-13bc-5416-ac8f-6df2e35c26da","option_code":"A","option_text":"“Pode receber no dia seguinte à contemplação.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":26,"question_class":"REG"}},{"id":"7fbc8702-67d9-5558-97f1-96450300c2f8","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1e919036-13bc-5416-ac8f-6df2e35c26da","option_code":"B","option_text":"“Nunca pode receber em espécie.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":26,"question_class":"REG"}},{"id":"cf2425fa-4784-56e9-bef9-f0da921f0435","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1e919036-13bc-5416-ac8f-6df2e35c26da","option_code":"C","option_text":"“Após 180 dias da contemplação, se o crédito não tiver sido utilizado e houver quitação total das obrigações com o grupo e a administradora, poderá ser solicitado o recebimento em espécie, conforme o regulamento.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":26,"question_class":"REG"}},{"id":"97fdca12-5678-597c-b778-346d06aaa33b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1e919036-13bc-5416-ac8f-6df2e35c26da","option_code":"D","option_text":"“Pode receber depois de 30 dias, mesmo com parcelas em aberto.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":26,"question_class":"REG"}},{"id":"e88d1c37-857d-5e9f-96c0-130b70259c57","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4f4622b7-0fc6-5671-8029-6b0338b29624","option_code":"A","option_text":"“A parcela nunca pode mudar.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":27,"question_class":"REG"}},{"id":"add44c21-3c58-527c-b0c4-9677a4711f00","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4f4622b7-0fc6-5671-8029-6b0338b29624","option_code":"B","option_text":"“O valor do crédito pode ser atualizado conforme a referência do plano — por exemplo, crédito referencial/IPCA ou tabela do fabricante — e as contribuições acompanham essa atualização para preservar o poder de compra do grupo.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":27,"question_class":"REG"}},{"id":"eaffb5fd-ac62-55b6-8499-c7b2a75ae810","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4f4622b7-0fc6-5671-8029-6b0338b29624","option_code":"C","option_text":"“A administradora aumenta quando quiser.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":27,"question_class":"REG"}},{"id":"6010352f-d4ef-5de3-81b2-1fbcfe302ab4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4f4622b7-0fc6-5671-8029-6b0338b29624","option_code":"D","option_text":"“A parcela só muda se o vendedor solicitar.”","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":27,"question_class":"REG"}},{"id":"7c91e95a-e95a-532b-9651-d61a0b7ef0d7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"175692a4-137a-5064-b523-44c036cb4493","option_code":"A","option_text":"É uma reunião sem relação com contemplação.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":28,"question_class":"REG"}},{"id":"2bbf410b-85a6-5c59-9de4-9f26583584b1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"175692a4-137a-5064-b523-44c036cb4493","option_code":"B","option_text":"É realizada mensalmente e de forma eletrônica; nela ocorrem atos como contemplações e prestação de informações do grupo, com resultados disponibilizados nos canais oficiais.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":28,"question_class":"REG"}},{"id":"91156da1-e2f1-5f6d-84ec-7c44ebbce316","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"175692a4-137a-5064-b523-44c036cb4493","option_code":"C","option_text":"O cliente precisa comparecer presencialmente todo mês.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":28,"question_class":"REG"}},{"id":"af43b848-b5f3-5284-aa7a-d46e633a245f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"175692a4-137a-5064-b523-44c036cb4493","option_code":"D","option_text":"Só existe assembleia no encerramento do grupo.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":28,"question_class":"REG"}},{"id":"f39bd09c-0514-5fa3-aa4f-5d96852df553","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"e581bbdb-90ef-5012-bb51-2066dcd933b1","option_code":"A","option_text":"Escolher sempre o maior crédito disponível.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":29,"question_class":"COM"}},{"id":"54c572a0-badd-5134-bae3-3d01cbced766","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"e581bbdb-90ef-5012-bb51-2066dcd933b1","option_code":"B","option_text":"Perguntar objetivo, urgência, orçamento, capacidade de pagamento e expectativa de contemplação antes de apresentar a alternativa mais adequada.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":29,"question_class":"COM"}},{"id":"9af22528-9478-51ca-8e44-ba6ff8faa853","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"e581bbdb-90ef-5012-bb51-2066dcd933b1","option_code":"C","option_text":"Evitar falar de prazo e custos até a assinatura.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":29,"question_class":"COM"}},{"id":"3638ec47-8813-5a7a-b31d-714d895263f6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"e581bbdb-90ef-5012-bb51-2066dcd933b1","option_code":"D","option_text":"Apresentar somente a parcela mais baixa, independentemente das condições.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":29,"question_class":"COM"}},{"id":"d079bbcd-6bec-54aa-8123-95075ff4c49e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"79a53971-b2ae-5796-b72e-136d35187038","option_code":"A","option_text":"Encerrar o contato imediatamente, porque o vendedor não tem mais função.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":30,"question_class":"COM"}},{"id":"d0e08ffc-e65b-5313-82c3-6da74d82774b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"79a53971-b2ae-5796-b72e-136d35187038","option_code":"B","option_text":"Orientar o cliente a acompanhar vencimentos, assembleias e canais oficiais, manter seus dados atualizados e procurar atendimento quando houver dúvida sobre o contrato.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":30,"question_class":"COM"}},{"id":"9bd0faa3-7acc-5687-9fbb-198cf53ae714","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"79a53971-b2ae-5796-b72e-136d35187038","option_code":"C","option_text":"Falar com o cliente apenas quando houver atraso.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":30,"question_class":"COM"}},{"id":"96bdb8a5-97a5-5a8f-b455-c16da1402e93","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"79a53971-b2ae-5796-b72e-136d35187038","option_code":"D","option_text":"Prometer acompanhar pessoalmente cada sorteio e garantir a contemplação.","metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":30,"question_class":"COM"}}]$vw_commercial_options$::jsonb) as x(
    id uuid,
    organization_id uuid,
    question_id uuid,
    option_code text,
    option_text text,
    metadata jsonb
  )
)
insert into public.assessment_question_options (
  id, organization_id, question_id, option_code, option_text, metadata
)
select
  id, organization_id, question_id, option_code, option_text, metadata
from payload;

-- ============================================================================
-- 6. Gabaritos privados
-- ============================================================================

with payload as (
  select *
  from jsonb_to_recordset($vw_commercial_keys$[{"question_id":"4ebfdd04-920c-5c31-920b-75ef4bb9db25","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"O consórcio é uma modalidade de autofinanciamento em grupo. Essa explicação é simples, correta e evita comparar o produto a empréstimo ou investimento.","source_reference":"Regulamento CNVW/Embracon V3.0 — Resumo das Condições Gerais, definição de “Consórcio”; Volkswagen Financial Services — página institucional de Consórcio.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":1,"question_class":"COM","legal_scoring":false,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"a29b5c52-086c-5a41-96a4-e478eacd9bbf","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"A comunicação comercial pode explorar a ausência de juros de financiamento, mas nunca deve transformar isso em “custo zero”. O contrato prevê taxa de administração e pode prever outros componentes.","source_reference":"Volkswagen Financial Services — comunicação institucional do Consórcio Volkswagen com a Embracon (“sem juros”); Regulamento V3.0 — Taxa de Administração e decomposição dos pagamentos.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":2,"question_class":"COM","legal_scoring":false,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"a099493d-aed9-5d2c-b9f9-1fb9dacdc832","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"A contemplação depende das regras da assembleia, sorteio, lances, habilitação da cota e recursos do grupo. O vendedor não deve criar garantia de prazo que o regulamento não oferece.","source_reference":"Regulamento V3.0 — Resumo das Condições Gerais, “Contemplação”, “Sorteio” e “Lance”.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":3,"question_class":"REG","legal_scoring":true,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"ffe7cbf8-9aae-5a97-97df-4dff874289a1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"Para consorciados ativos, o regulamento prevê contemplação por sorteio e por lance.","source_reference":"Regulamento V3.0 — Resumo das Condições Gerais, “Contemplação”.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":4,"question_class":"REG","legal_scoring":true,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"a593dcaa-912e-573f-9e9c-aad48b6262a9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"O ponto comercial correto é mostrar que a contemplação dá ao cliente o direito de usar o crédito, respeitando o segmento e as condições contratuais.","source_reference":"Regulamento V3.0 — Resumo das Condições Gerais, “Contemplação” e “Da utilização do crédito”.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":5,"question_class":"COM","legal_scoring":false,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"2e0d4900-c29c-53aa-9e74-25b85d472d54","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"O benefício existe, mas possui uma exceção relevante: a taxa de administração antecipada. O vendedor precisa mencionar essa condição para não criar expectativa incorreta.","source_reference":"Regulamento V3.0 — Cláusula 3.3 e parágrafos do Plano Smart.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":6,"question_class":"REG","legal_scoring":true,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"32c65f63-f761-5e41-93c6-6f624a3adca1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"A redução está ligada aos percentuais de fundo comum e fundo de reserva. Não é correto vender o plano como “50% de desconto na parcela total” sem explicar os demais componentes e o tratamento da diferença na contemplação.","source_reference":"Regulamento V3.0 — Cláusula 3.4.1, Plano Essencial 50.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":7,"question_class":"REG","legal_scoring":true,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"403b8bbf-a26d-500a-be36-cd8c66a71b36","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"A resposta reconhece a objeção, preserva a transparência e posiciona o produto para o perfil correto.","source_reference":"Regulamento V3.0 — regras de contemplação, sorteio e lance; aplicação comercial derivada dessas regras.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":8,"question_class":"COM","legal_scoring":false,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"e2772585-960f-585e-8154-ae1fe8e54510","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Lance é uma forma de concorrer à contemplação; não deve ser apresentado como garantia.","source_reference":"Regulamento V3.0 — “Lance” e Cláusula 18.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":9,"question_class":"COM","legal_scoring":false,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"808090d4-b4ce-565a-bdea-f66dba94638e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"O lance embutido utiliza parte do crédito contratado para compor a oferta e, por isso, reduz o montante de crédito disponível na forma prevista no regulamento.","source_reference":"Regulamento V3.0 — Cláusula 18, Parágrafo Terceiro.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":10,"question_class":"REG","legal_scoring":true,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"533e705d-6e3b-576b-bba6-8577be500c5c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"A parceria pode ser usada como argumento institucional, mas os papéis precisam ser explicados corretamente. O regulamento identifica a CNVW como responsável legal e descreve os serviços prestados pela Embracon.","source_reference":"Regulamento V3.0 — Resumo das Condições Gerais, “Administradora de Consórcio” e “Prestadora de Serviços de Administração”.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":11,"question_class":"REG","legal_scoring":true,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"a82d22d8-2b51-529d-a6c6-7f50d93fbbb9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"A","justification":"“Sem juros” é uma comunicação institucional possível, mas o vendedor deve deixar claro que o produto possui custos contratuais.","source_reference":"Volkswagen Financial Services — página institucional do Consórcio Volkswagen com a Embracon; Regulamento V3.0 — Taxa de Administração e decomposição dos pagamentos.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":12,"question_class":"COM","legal_scoring":false,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"67020dce-e70a-5b74-8f09-03d93cc62555","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"A análise de capacidade de pagamento é uma condição regulatória e protege a sustentabilidade da obrigação assumida pelo consorciado.","source_reference":"Regulamento V3.0 — Cláusula 1.2, Condições de Não Aceite.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":13,"question_class":"REG","legal_scoring":true,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"f23e87b8-5435-548d-b8d0-7cd3e5909acf","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"Prometer devolução imediata é incorreto. A restituição do excluído segue regras próprias.","source_reference":"Regulamento V3.0 — Resumo das Condições Gerais e seção “Da desistência e exclusão do consorciado”.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":14,"question_class":"REG","legal_scoring":true,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"c61bb1ed-c594-5d8a-91d3-5638e12277ce","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"Esta versão do regulamento contém uma divergência interna entre o resumo e a seção de exclusão quanto à quantidade de parcelas. Por isso, o teste não exige decorar um número conflitante; avalia a conduta segura do vendedor.","source_reference":"Regulamento V3.0 — Resumo das Condições Gerais (menção a 3 parcelas) e seção “Da exclusão do consorciado” (menção a 2 parcelas). Questão deliberadamente desenhada para evitar reproduzir a inconsistência documental.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":15,"question_class":"REG","legal_scoring":true,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"be6dbed6-3d86-594c-9d87-5879e4e5a2af","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"O regulamento estabelece alienação fiduciária como modalidade de garantia.","source_reference":"Regulamento V3.0 — Cláusula 33 e regras de aquisição de veículo novo/usado.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":16,"question_class":"REG","legal_scoring":true,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"6bd6c673-9ef0-5ec3-85f6-a3b2327cab2e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"A comunicação institucional atual contempla consórcio de carros e caminhões. O vendedor deve confirmar a oferta vigente e enquadrar corretamente o cliente e o segmento.","source_reference":"Volkswagen Financial Services — página atual do Consórcio Volkswagen com a Embracon; Regulamento V3.0 — possibilidade de participação de pessoas naturais e jurídicas.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":17,"question_class":"COM","legal_scoring":false,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"52c11077-fb82-5673-a35c-2abd1f85e670","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"O vendedor não precisa desqualificar outro produto. Uma venda consultiva compara necessidade imediata versus planejamento e apresenta o consórcio sem promessa indevida.","source_reference":"Volkswagen Financial Services — páginas institucionais de Consórcio e Financiamento; Regulamento V3.0 — contemplação por sorteio/lance.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":18,"question_class":"COM","legal_scoring":false,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"f7a171c4-646d-5a8e-b299-ad7a60a39231","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"O não recebimento do aviso não elimina a obrigação de acompanhar o vencimento. O regulamento também exige manutenção dos dados cadastrais atualizados.","source_reference":"Regulamento V3.0 — Cláusula 6.2; Resumo das Condições Gerais, obrigação de atualização cadastral.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":19,"question_class":"REG","legal_scoring":true,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"b49fe748-ee8b-5b4d-ac58-e701a6a8abfd","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"A proteção depende de contratação do seguro, aprovação do sinistro, montante da indenização e demais condições do regulamento; não é uma quitação automática universal.","source_reference":"Regulamento V3.0 — regras de lance decorrente de indenização e seguro prestamista.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":20,"question_class":"REG","legal_scoring":true,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"7fa22525-b0a9-596e-9dcc-b9da95687bca","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"A cessão depende de processo formal e aprovação da administradora; não é uma negociação que se conclui apenas entre cedente e comprador.","source_reference":"Regulamento V3.0 — Cláusula 37, Da Cessão do Contrato.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":21,"question_class":"REG","legal_scoring":true,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"bb202c4d-8944-5e6d-aa87-6285105c9927","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"A alteração para o não contemplado possui regras específicas, incluindo momento, limite de variação e faixa de créditos do grupo.","source_reference":"Regulamento V3.0 — Cláusula 23 e subcláusulas sobre alteração do crédito.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":22,"question_class":"REG","legal_scoring":true,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"f495f6fc-ff83-5878-b7ec-b58e82e952ec","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"O regulamento prevê compra de automóvel usado em concessionária/revendedor e também de terceiros, com documentação e requisitos próprios.","source_reference":"Regulamento V3.0 — Cláusula 26 e parágrafos sobre aquisição de bem automotivo usado.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":23,"question_class":"REG","legal_scoring":true,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"10a27573-2193-5463-a033-db1c63d182e5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"Esse é um argumento institucional forte e objetivo, sem necessidade de exagero comercial.","source_reference":"Regulamento V3.0 — Resumo das Condições Gerais, identificação da Administradora e papel do Banco Central.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":24,"question_class":"REG","legal_scoring":true,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"c4fb2eae-8795-5466-b467-92aa35f6fe9f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"A contemplação não transforma o crédito em dinheiro de livre destinação. A utilização deve respeitar o bem/segmento do plano.","source_reference":"Regulamento V3.0 — Resumo das Condições Gerais e Cláusulas 24 a 26, Da Utilização do Crédito.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":25,"question_class":"REG","legal_scoring":true,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"1e919036-13bc-5416-ac8f-6df2e35c26da","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"O prazo e a quitação são condições essenciais e não devem ser omitidos na explicação comercial.","source_reference":"Regulamento V3.0 — Cláusula 32 e Resumo das Condições Gerais.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":26,"question_class":"REG","legal_scoring":true,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"4f4622b7-0fc6-5671-8029-6b0338b29624","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"O vendedor deve explicar a atualização antes da contratação para evitar surpresa futura.","source_reference":"Regulamento V3.0 — Resumo das Condições Gerais, “Contribuições Mensais”; Cláusulas 3.2 e 4.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":27,"question_class":"REG","legal_scoring":true,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"175692a4-137a-5064-b523-44c036cb4493","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"A assembleia é parte central do funcionamento do consórcio e ocorre mensalmente de forma eletrônica.","source_reference":"Regulamento V3.0 — Cláusula 13 e Resumo das Condições Gerais; publicação no site/área do cliente e aplicativo CNVW.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":28,"question_class":"REG","legal_scoring":true,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"e581bbdb-90ef-5012-bb51-2066dcd933b1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Esta é uma questão de competência comercial, não uma reprodução literal do regulamento. A prática é coerente com a necessidade de enquadrar o cliente, capacidade contributiva, plano e expectativas antes da contratação.","source_reference":"Governança comercial RF — aplicação consultiva apoiada nas exigências do Regulamento V3.0 sobre capacidade de pagamento, plano contratado e transparência das condições. Não classificar como regra legal textual.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":29,"question_class":"COM","legal_scoring":false,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}},{"question_id":"79a53971-b2ae-5796-b72e-136d35187038","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"O vendedor não substitui a administradora, mas pode fortalecer a relação orientando o cliente sobre comportamento e canais corretos ao longo do contrato.","source_reference":"Regulamento V3.0 — atualização cadastral, aviso de cobrança e assembleias; Volkswagen Financial Services — canais oficiais de atendimento. A formulação de pós-venda é de competência comercial, não obrigação legal específica do vendedor.","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"commercial_regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":30,"question_class":"COM","legal_scoring":false,"official_source_content_sha256":"530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09","authoring_document_sha256":"8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de","criticality_basis":"no_critical_items_authorized_for_candidate"}}]$vw_commercial_keys$::jsonb) as x(
    question_id uuid,
    organization_id uuid,
    correct_option_code text,
    justification text,
    source_reference text,
    is_critical boolean,
    critical_reason text,
    metadata jsonb
  )
)
insert into private.assessment_question_keys (
  question_id, organization_id, correct_option_code, justification,
  source_reference, is_critical, critical_reason, metadata
)
select
  question_id, organization_id, correct_option_code, justification,
  source_reference, is_critical, critical_reason, metadata
from payload;

-- ============================================================================
-- 7. Vínculo das 30 questões à versão v2
-- ============================================================================

with payload as (
  select *
  from jsonb_to_recordset($vw_commercial_links$[{"id":"0fb91841-b169-551e-a2df-1acbb417b271","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"4ebfdd04-920c-5c31-920b-75ef4bb9db25","sequence_no":1,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":1,"question_class":"COM"}},{"id":"e6db3b30-7bff-5544-a5a5-df64c8d91f77","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"a29b5c52-086c-5a41-96a4-e478eacd9bbf","sequence_no":2,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":2,"question_class":"COM"}},{"id":"4df021ba-1090-5097-a8b3-3788a30037ce","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"a099493d-aed9-5d2c-b9f9-1fb9dacdc832","sequence_no":3,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":3,"question_class":"REG"}},{"id":"29bbf3ed-df3a-56cc-a616-3175a654f59f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"ffe7cbf8-9aae-5a97-97df-4dff874289a1","sequence_no":4,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":4,"question_class":"REG"}},{"id":"9cd5781d-9930-535d-8d09-b61bf65dddff","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"a593dcaa-912e-573f-9e9c-aad48b6262a9","sequence_no":5,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":5,"question_class":"COM"}},{"id":"782b0506-5e10-5943-9584-96f410ea3ef9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"2e0d4900-c29c-53aa-9e74-25b85d472d54","sequence_no":6,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":6,"question_class":"REG"}},{"id":"7b38871d-7d38-509b-95a6-8fdfc506fb84","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"32c65f63-f761-5e41-93c6-6f624a3adca1","sequence_no":7,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":7,"question_class":"REG"}},{"id":"d5dc7947-6c15-57c8-b601-762174d9c8da","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"403b8bbf-a26d-500a-be36-cd8c66a71b36","sequence_no":8,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":8,"question_class":"COM"}},{"id":"a302d7e1-77d8-55a2-9f2d-42856e8838a4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"e2772585-960f-585e-8154-ae1fe8e54510","sequence_no":9,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":9,"question_class":"COM"}},{"id":"68d44f31-b472-5da3-935e-eabb962be7b1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"808090d4-b4ce-565a-bdea-f66dba94638e","sequence_no":10,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":10,"question_class":"REG"}},{"id":"b9be8366-e60e-557c-b441-5d0fdbde215c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"533e705d-6e3b-576b-bba6-8577be500c5c","sequence_no":11,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":11,"question_class":"REG"}},{"id":"b97faf74-4713-5186-8039-bf68f949c88a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"a82d22d8-2b51-529d-a6c6-7f50d93fbbb9","sequence_no":12,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":12,"question_class":"COM"}},{"id":"e6c75481-d30b-5cd2-b2fd-caf74d710258","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"67020dce-e70a-5b74-8f09-03d93cc62555","sequence_no":13,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":13,"question_class":"REG"}},{"id":"4e1d685f-f0dd-5a3c-ba32-6a543ea7c670","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"f23e87b8-5435-548d-b8d0-7cd3e5909acf","sequence_no":14,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":14,"question_class":"REG"}},{"id":"0aeae8d3-38a7-571d-a47f-d5f9825573fc","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"c61bb1ed-c594-5d8a-91d3-5638e12277ce","sequence_no":15,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":15,"question_class":"REG"}},{"id":"3168e0b3-2eb6-5efc-b8a3-12ed8a1acc5f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"be6dbed6-3d86-594c-9d87-5879e4e5a2af","sequence_no":16,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":16,"question_class":"REG"}},{"id":"f93bfb78-e2d5-50e3-80f0-965bf3ecaf84","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"6bd6c673-9ef0-5ec3-85f6-a3b2327cab2e","sequence_no":17,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":17,"question_class":"COM"}},{"id":"fffb92ec-a63d-5d19-a407-97e2bf952aac","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"52c11077-fb82-5673-a35c-2abd1f85e670","sequence_no":18,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":18,"question_class":"COM"}},{"id":"ba336bd3-6a90-5018-9c43-2502f8bb11a6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"f7a171c4-646d-5a8e-b299-ad7a60a39231","sequence_no":19,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":19,"question_class":"REG"}},{"id":"f3a9874e-e659-5bdf-bf53-fa9d856171fe","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"b49fe748-ee8b-5b4d-ac58-e701a6a8abfd","sequence_no":20,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":20,"question_class":"REG"}},{"id":"eaa8a748-f27a-5d9f-8127-57554393d5da","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"7fa22525-b0a9-596e-9dcc-b9da95687bca","sequence_no":21,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":21,"question_class":"REG"}},{"id":"49ee9a5a-60bd-53c6-8081-cc0a356d5cec","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"bb202c4d-8944-5e6d-aa87-6285105c9927","sequence_no":22,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":22,"question_class":"REG"}},{"id":"a02f6ed0-a936-59f8-8c5c-5149ed7b89aa","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"f495f6fc-ff83-5878-b7ec-b58e82e952ec","sequence_no":23,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":23,"question_class":"REG"}},{"id":"6a6e3ff9-2b7f-55c9-a3bc-ae54c2885eba","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"10a27573-2193-5463-a033-db1c63d182e5","sequence_no":24,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":24,"question_class":"REG"}},{"id":"912ec504-1366-5984-883e-27556f393a10","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"c4fb2eae-8795-5466-b467-92aa35f6fe9f","sequence_no":25,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":25,"question_class":"REG"}},{"id":"ccd3161a-464e-5360-a3e7-237ff831a8d5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"1e919036-13bc-5416-ac8f-6df2e35c26da","sequence_no":26,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":26,"question_class":"REG"}},{"id":"7b41b75b-b3ff-5c9d-879a-bc6ef42352f6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"4f4622b7-0fc6-5671-8029-6b0338b29624","sequence_no":27,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":27,"question_class":"REG"}},{"id":"46fe1934-5b8c-5d63-b6df-4dc8bc957fd6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"175692a4-137a-5064-b523-44c036cb4493","sequence_no":28,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":28,"question_class":"REG"}},{"id":"ae1f5627-b2da-5c06-88b0-5bbb4e4018fc","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"e581bbdb-90ef-5012-bb51-2066dcd933b1","sequence_no":29,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":29,"question_class":"COM"}},{"id":"5d5a472e-9724-5161-bd03-4d43555760a9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"58b09fe5-2bc5-5803-ab0a-2a8834c85607","question_id":"79a53971-b2ae-5796-b72e-136d35187038","sequence_no":30,"points":1,"is_required":true,"metadata":{"catalog_family":"commercial_regulatory","test_number":11,"assessment_version_code":"cnvw-v3.0-comercial-v2","question_number":30,"question_class":"COM"}}]$vw_commercial_links$::jsonb) as x(
    id uuid,
    organization_id uuid,
    test_version_id uuid,
    question_id uuid,
    sequence_no integer,
    points numeric,
    is_required boolean,
    metadata jsonb
  )
)
insert into public.assessment_version_questions (
  id, organization_id, test_version_id, question_id,
  sequence_no, points, is_required, metadata
)
select
  id, organization_id, test_version_id, question_id,
  sequence_no, points, is_required, metadata
from payload;

-- ============================================================================
-- 8. Pós-condições fail-closed
-- ============================================================================

do $postcheck$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
  v_test_id uuid := 'dd671e5f-39ec-5018-9263-78613361a7db'::uuid;
  v_v1_id uuid := 'fcf8f979-c44e-5993-beef-d023312ab5b7'::uuid;
  v_v2_id uuid := '58b09fe5-2bc5-5803-ab0a-2a8834c85607'::uuid;
  v_attempt_id uuid := 'ea94b2a3-906f-450f-94cc-67dd9a98709d'::uuid;
  v_pilot_id uuid := '49239d09-0f85-471f-8f46-5c240cd98600'::uuid;
  v_total integer;
  v_legal integer;
  v_commercial integer;
begin
  -- v1 histórica segue preservada e fechada.
  if not exists (
    select 1
    from public.assessment_test_versions v
    where v.organization_id = v_org_id
      and v.id = v_v1_id
      and v.test_id = v_test_id
      and v.version_code = 'cnvw-v3.0-v1'
      and v.version_no = 1
      and v.status = 'draft'
      and v.passing_score = 90
      and v.legal_min_score = 90
      and v.question_count = 30
      and v.valid_from is null
      and v.valid_until is null
      and v.published_at is null
      and v.archived_at is null
  ) then
    raise exception 'FASE6A_POST: versao historica v1 foi alterada.';
  end if;

  if not exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.id = v_attempt_id
      and a.test_id = v_test_id
      and a.test_version_id = v_v1_id
      and a.organization_member_id = v_pilot_id
      and a.status = 'graded'
      and a.correct_answers = 25
      and round(a.overall_score::numeric, 2) = 83.33
      and round(a.legal_score::numeric, 2) = 83.33
      and a.critical_errors = 0
      and a.passed is false
      and a.result_reason = 'overall_score_below_minimum'
      and a.archived_at is null
  ) then
    raise exception 'FASE6A_POST: tentativa historica v1 foi alterada.';
  end if;

  -- Nova versão candidata permanece fechada.
  if not exists (
    select 1
    from public.assessment_test_versions v
    where v.organization_id = v_org_id
      and v.id = v_v2_id
      and v.test_id = v_test_id
      and v.version_code = 'cnvw-v3.0-comercial-v2'
      and v.version_no = 2
      and v.status = 'draft'
      and v.passing_score = 100
      and v.legal_min_score = 100
      and v.question_count = 30
      and v.randomize_questions = true
      and v.randomize_options = true
      and v.show_review_after_submit = false
      and v.valid_from is null
      and v.valid_until is null
      and v.published_at is null
      and v.metadata->>'approval_policy_defined' = 'false'
      and v.metadata->>'approval_threshold_strategy' = 'fail_closed_until_policy_authorization'
      and v.metadata->>'homologation_status' = 'draft_candidate'
      and v.metadata->>'authoring_document_sha256' = '8205dc23af4be3fba8968abea748c6e7312aa0297327f309163e353fe15ce3de'
      and v.metadata->>'source_content_sha256' = '530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09'
      and v.archived_at is null
  ) then
    raise exception 'FASE6A_POST: nova versao comercial v2 nao confere.';
  end if;

  select count(*)
    into v_total
  from public.assessment_version_questions avq
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_v2_id
    and avq.is_required = true
    and avq.archived_at is null;

  if v_total <> 30 then
    raise exception 'FASE6A_POST: esperado 30 vinculos obrigatorios na v2; encontrado %.', v_total;
  end if;

  if (
    select count(distinct avq.question_id)
    from public.assessment_version_questions avq
    where avq.organization_id = v_org_id
      and avq.test_version_id = v_v2_id
      and avq.archived_at is null
  ) <> 30 then
    raise exception 'FASE6A_POST: v2 nao possui 30 questoes distintas.';
  end if;

  if (
    select count(*)
    from public.assessment_question_options o
    join public.assessment_version_questions avq
      on avq.organization_id = o.organization_id
     and avq.question_id = o.question_id
     and avq.test_version_id = v_v2_id
     and avq.archived_at is null
    where o.organization_id = v_org_id
  ) <> 120 then
    raise exception 'FASE6A_POST: esperado 120 alternativas na v2.';
  end if;

  if (
    select count(*)
    from private.assessment_question_keys k
    join public.assessment_version_questions avq
      on avq.organization_id = k.organization_id
     and avq.question_id = k.question_id
     and avq.test_version_id = v_v2_id
     and avq.archived_at is null
    where k.organization_id = v_org_id
  ) <> 30 then
    raise exception 'FASE6A_POST: esperado 30 gabaritos privados na v2.';
  end if;

  if exists (
    select 1
    from private.assessment_question_keys k
    join public.assessment_version_questions avq
      on avq.organization_id = k.organization_id
     and avq.question_id = k.question_id
     and avq.test_version_id = v_v2_id
     and avq.archived_at is null
    where k.organization_id = v_org_id
      and k.is_critical = true
  ) then
    raise exception 'FASE6A_POST: item critico apareceu sem autorizacao.';
  end if;

  select
    count(*) filter (where c.is_legal = true),
    count(*) filter (where c.is_legal = false)
  into v_legal, v_commercial
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
    and avq.test_version_id = v_v2_id
    and avq.archived_at is null;

  if v_legal <> 20 or v_commercial <> 10 then
    raise exception
      'FASE6A_POST: classificacao legal/comercial deveria ser 20/10; encontrado %/%.',
      v_legal, v_commercial;
  end if;

  if (
    select count(*)
    from public.competency_domains c
    where c.organization_id = v_org_id
      and c.sequence_no between 59 and 62
      and c.is_legal = false
      and c.status = 'draft'
      and c.archived_at is null
  ) <> 4 then
    raise exception 'FASE6A_POST: esperado 4 competencias comerciais nao legais.';
  end if;

  if (
    select count(*)
    from public.assessment_version_sources avs
    where avs.organization_id = v_org_id
      and avs.test_version_id = v_v2_id
      and avs.relation_type = 'primary'
      and avs.is_required = true
      and avs.archived_at is null
      and avs.source_material_version_id in (
        'aca73af3-6ded-5461-88c9-acbd17064862'::uuid,
        '766c970d-f0f3-5b0a-b4ef-32263adf99a1'::uuid
      )
  ) <> 2 then
    raise exception 'FASE6A_POST: esperado vinculo das 2 fontes primarias obrigatorias.';
  end if;

  if exists (
    select 1
    from private.assessment_test_access_grants g
    where g.organization_id = v_org_id
      and g.test_id = v_test_id
      and g.status = 'active'
      and g.archived_at is null
  ) then
    raise exception 'FASE6A_POST: grant ativo indevido no Teste 11.';
  end if;

  if exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.test_version_id = v_v2_id
      and a.archived_at is null
  ) then
    raise exception 'FASE6A_POST: tentativa indevida criada para a v2.';
  end if;

  -- Fiat continua intocado.
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
      and t.status = 'draft'
      and t.archived_at is null
      and v.version_code = 'fiat-v3-v1'
      and v.status = 'draft'
      and v.passing_score = 90
      and v.legal_min_score = 90
      and v.published_at is null
  ) then
    raise exception 'FASE6A_POST: Teste 12 Fiat foi alterado.';
  end if;
end
$postcheck$;

commit;
