-- ============================================================================
-- RF Performance — Avaliações e Certificações
-- Catálogo Ampliado — Avaliação Regulamentar — Consórcio Volkswagen
-- Fase 3A — CNVW / Embracon — cadastro em RASCUNHO para homologação
--
-- Base normativa fornecida:
--   Regulamento do Contrato de Consórcio CNVW com Embracon
--   Versão 2.1 — Circular 3432/09 e Resolução 285/23 do Banco Central do Brasil
--   SHA-256: a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a
--
-- Documento de autoria das questões:
--   Teste_06_Regulamento_CNVW_Embracon.md
--   SHA-256: a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f
--
-- ESCOPO / SEGURANÇA
--   - Não altera Testes 1 a 10.
--   - Cria a avaliação regulamentar como Teste de sequência 11.
--   - Cria 8 competências regulamentares conforme a estrutura temática declarada.
--   - Questões ficam em draft e exigem revisão legal antes da publicação.
--   - Não cria grant de acesso.
--   - Não publica a avaliação.
--   - Não cria tentativa.
--   - Gabarito permanece em private.assessment_question_keys.
--   - Nenhum item é marcado crítico, pois a fonte de autoria não declara criticidade.
--   - Corte 100/100 permanece fail-closed até definição da política de aprovação.
-- ============================================================================

begin;

do $guard$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
begin
  if not exists (
    select 1
    from public.organizations o
    where o.id = v_org_id
      and o.slug = 'rf-consorcios'
      and o.status = 'active'
      and o.archived_at is null
  ) then
    raise exception 'Regulamento VW abortado: organização RF esperada não localizada/ativa.';
  end if;

  if (
    select count(*)
    from public.assessment_tests t
    where t.organization_id = v_org_id
      and t.sequence_no between 1 and 10
      and t.archived_at is null
  ) <> 10 then
    raise exception 'Regulamento VW abortado: catálogo-base Testes 1 a 10 não está íntegro.';
  end if;

  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions tv
      on tv.test_id = t.id
     and tv.organization_id = t.organization_id
     and tv.archived_at is null
    where t.organization_id = v_org_id
      and t.sequence_no = 10
      and t.code = 'teste_10_vap_ia_vendas_persuasao'
      and t.status = 'draft'
      and tv.version_code = '2026.08-v1'
      and tv.status = 'draft'
      and t.archived_at is null
  ) then
    raise exception 'Regulamento VW abortado: Teste 10 VAP esperado não está presente em draft.';
  end if;

  if exists (
    select 1
    from public.assessment_tests t
    where t.organization_id = v_org_id
      and t.archived_at is null
      and (
        t.sequence_no = 11
        or t.code = 'regulamento_vw_cnvw_v1'
        or t.id = 'dd671e5f-39ec-5018-9263-78613361a7db'::uuid
      )
  ) then
    raise exception 'Regulamento VW abortado: já existe teste ocupando a identidade/seq. 11.';
  end if;

  if exists (
    select 1
    from public.source_materials sm
    where sm.organization_id = v_org_id
      and sm.archived_at is null
      and (
        sm.code = 'regulamento_cnvw_embracon_v2_1'
        or sm.id = '89fb9a5e-d493-5280-814d-abc03eaa05c9'::uuid
      )
  ) then
    raise exception 'Regulamento VW abortado: fonte CNVW v2.1 já existe com a identidade esperada.';
  end if;

  if exists (
    select 1
    from public.source_material_versions smv
    where smv.organization_id = v_org_id
      and smv.archived_at is null
      and lower(smv.content_sha256) = 'a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a'
  ) then
    raise exception 'Regulamento VW abortado: o mesmo SHA-256 normativo já está cadastrado em outra fonte.';
  end if;

  if exists (
    select 1
    from public.competency_domains c
    where c.organization_id = v_org_id
      and c.archived_at is null
      and (
        c.sequence_no between 43 and 50
        or c.code in (
          'reg_vw_definicoes_adesao',
          'reg_vw_planos',
          'reg_vw_contribuicoes_taxas',
          'reg_vw_constituicao_grupo',
          'reg_vw_assembleias',
          'reg_vw_contemplacao_lances',
          'reg_vw_credito_garantias',
          'reg_vw_cessao_exclusao_prescricao'
        )
      )
  ) then
    raise exception 'Regulamento VW abortado: sequência/código das competências 43..50 já está ocupado.';
  end if;

  if exists (
    select 1
    from public.assessment_questions q
    where q.organization_id = v_org_id
      and q.archived_at is null
      and q.code like 'reg_vw_cnvw_q%'
  ) then
    raise exception 'Regulamento VW abortado: já existem questões com o namespace reg_vw_cnvw_q.';
  end if;
end
$guard$;

-- --------------------------------------------------------------------------
-- 1. Fonte normativa oficial fornecida
-- --------------------------------------------------------------------------
insert into public.source_materials (
  id, organization_id, code, title, description, material_type,
  issuer, status, metadata
)
values (
  '89fb9a5e-d493-5280-814d-abc03eaa05c9'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'regulamento_cnvw_embracon_v2_1',
  'Regulamento do Contrato de Consórcio — CNVW com Embracon',
  'Regulamento do Contrato de Consórcio do Consórcio Nacional Volkswagen, com prestação de serviços de administração pela Embracon, identificado no documento como Versão 2.1.',
  'regulation',
  'Consórcio Nacional Volkswagen – Administradora de Consórcio Ltda. (CNVW)',
  'active',
  jsonb_build_object(
    'catalog_family', 'regulatory',
    'administrator', 'CNVW',
    'service_provider', 'Embracon',
    'document_version', '2.1',
    'normative_references', jsonb_build_array(
      'Circular 3432/09',
      'Resolução 285/23 do Banco Central do Brasil'
    ),
    'source_filename', 'regulamento cnvw com Embracon .pdf',
    'content_sha256', 'a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a',
    'external_currency_verified', false
  )
);

insert into public.source_material_versions (
  id, organization_id, source_material_id, version_code, version_no,
  status, effective_from, effective_until, published_at, source_date,
  content_sha256, source_locator, metadata
)
values (
  '2bffe092-f163-53c5-846d-284567e62595'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '89fb9a5e-d493-5280-814d-abc03eaa05c9'::uuid,
  'v2.1-circular3432-res285-23',
  1,
  'active',
  null,
  null,
  null,
  null,
  'a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a',
  jsonb_build_object(
    'file_name', 'regulamento cnvw com Embracon .pdf',
    'document_version', '2.1',
    'circular', '3432/09',
    'resolution', '285/23'
  ),
  jsonb_build_object(
    'catalog_family', 'regulatory',
    'administrator', 'CNVW',
    'version_identity_basis', 'document_version_and_sha256',
    'source_content_sha256', 'a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a',
    'external_currency_verified', false
  )
);

-- --------------------------------------------------------------------------
-- 2. Competências regulamentares — 8 blocos declarados no material
-- --------------------------------------------------------------------------
with payload as (
  select *
  from jsonb_to_recordset($vw_competencies$[{"id":"dfb721a3-7005-591e-af41-655027fa487b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_definicoes_adesao","sequence_no":43,"name":"Regulamento VW — Definições e Adesão","description":"Definições contratuais, condição de consorciado, adesão ao grupo e regras iniciais.","domain_type":"knowledge","is_legal":true,"default_weight":0,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"0cf51b7a-f52c-544d-a0ea-c32436d4a113","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_planos","sequence_no":44,"name":"Regulamento VW — Planos","description":"Regras dos planos Smart, Essencial e Essencial 50.","domain_type":"knowledge","is_legal":true,"default_weight":0,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"860b1e56-0438-536c-bb88-c213c1b9bfac","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_contribuicoes_taxas","sequence_no":45,"name":"Regulamento VW — Contribuições, Diferenças e Taxas","description":"Contribuições, diferenças de parcela, recomposição financeira e taxas previstas no regulamento.","domain_type":"knowledge","is_legal":true,"default_weight":0,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"9c4fdbc5-ed84-5b2f-ba18-0ba6f03b1330","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_constituicao_grupo","sequence_no":46,"name":"Regulamento VW — Constituição e Regras do Grupo","description":"Fundo de reserva, constituição e limites aplicáveis ao grupo de consórcio.","domain_type":"knowledge","is_legal":true,"default_weight":0,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"24e64406-c6c8-58d8-9e3e-1de6eea804d5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_assembleias","sequence_no":47,"name":"Regulamento VW — Assembleias","description":"Assembleias gerais ordinárias e extraordinárias, representação e competências.","domain_type":"knowledge","is_legal":true,"default_weight":0,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"976964de-40bf-5860-a663-93737500b1e5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_contemplacao_lances","sequence_no":48,"name":"Regulamento VW — Contemplação, Sorteio e Lance","description":"Regras de contemplação, sorteio, lance, cancelamento e alteração do crédito.","domain_type":"knowledge","is_legal":true,"default_weight":0,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"baa037cf-3f7f-581e-9d22-de5acfd02004","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_credito_garantias","sequence_no":49,"name":"Regulamento VW — Utilização do Crédito e Garantias","description":"Utilização do crédito após contemplação e garantias vinculadas ao bem adquirido.","domain_type":"knowledge","is_legal":true,"default_weight":0,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"9527c059-e9b5-53c7-a6dd-bc73aaf38a47","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cessao_exclusao_prescricao","sequence_no":50,"name":"Regulamento VW — Cessão, Exclusão e Prescrição","description":"Cessão contratual, penalidades de exclusão e prazo prescricional.","domain_type":"knowledge","is_legal":true,"default_weight":0,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}}]$vw_competencies$::jsonb) as x(
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

-- --------------------------------------------------------------------------
-- 3. Avaliação e versão — sempre em draft / fail-closed
-- --------------------------------------------------------------------------
insert into public.assessment_tests (
  id, organization_id, code, sequence_no, title, description, difficulty,
  purpose, target_level_id, question_count, time_limit_minutes,
  max_attempts, cooldown_hours, status, metadata
)
values (
  'dd671e5f-39ec-5018-9263-78613361a7db'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'regulamento_vw_cnvw_v1',
  11,
  'Avaliação Regulamentar — Consórcio Volkswagen',
  'Avaliação de conhecimento sobre o Regulamento do Contrato de Consórcio CNVW/Embracon, Versão 2.1, estruturada em oito blocos temáticos.',
  'intermediate_advanced',
  'certification',
  null,
  30,
  null,
  2,
  24,
  'draft',
  jsonb_build_object(
    'catalog_family', 'regulatory',
    'administrator', 'CNVW',
    'assessment_version_label', 'CNVW v2.1 — avaliação v1',
    'source_material_code', 'regulamento_cnvw_embracon_v2_1',
    'source_content_sha256', 'a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a',
    'authoring_document', 'Teste_06_Regulamento_CNVW_Embracon.md',
    'authoring_document_sha256', 'a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f',
    'declared_distribution', '{"definicoes_adesao":4,"planos":3,"contribuicoes_taxas":5,"constituicao_grupo":3,"assembleias":3,"contemplacao_lances":7,"credito_garantias":2,"cessao_exclusao_prescricao":3}'::jsonb,
    'legal_review_required_before_publication', true,
    'homologation_status', 'draft_catalog'
  )
);

insert into public.assessment_test_versions (
  id, organization_id, test_id, version_code, version_no, status,
  passing_score, legal_min_score, question_count, randomize_questions,
  randomize_options, show_review_after_submit, valid_from, valid_until,
  published_at, normative_basis, metadata
)
values (
  'fcf8f979-c44e-5993-beef-d023312ab5b7'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'dd671e5f-39ec-5018-9263-78613361a7db'::uuid,
  'cnvw-v2.1-v1',
  1,
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
      'version', '2.1',
      'references', jsonb_build_array('Circular 3432/09', 'Resolução 285/23')
    )
  ),
  jsonb_build_object(
    'catalog_family', 'regulatory',
    'administrator', 'CNVW',
    'source_content_sha256', 'a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a',
    'authoring_document_sha256', 'a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f',
    'approval_policy_defined', false,
    'approval_threshold_placeholder', 100,
    'legal_threshold_placeholder', 100,
    'approval_threshold_strategy', 'fail_closed_until_publication',
    'review_policy_defined', false,
    'legal_review_required_before_publication', true,
    'external_currency_verified', false,
    'homologation_status', 'draft_catalog'
  )
);

insert into public.assessment_version_sources (
  id, organization_id, test_version_id, source_material_version_id,
  relation_type, is_required, notes, metadata
)
values (
  '6a4dc110-1bc3-5d7b-a545-6397df9fb6b2'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'fcf8f979-c44e-5993-beef-d023312ab5b7'::uuid,
  '2bffe092-f163-53c5-846d-284567e62595'::uuid,
  'primary',
  true,
  'Fonte normativa primária da Avaliação Regulamentar — Consórcio Volkswagen.',
  jsonb_build_object(
    'catalog_family', 'regulatory',
    'administrator', 'CNVW',
    'source_content_sha256', 'a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a',
    'authoring_document_sha256', 'a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f'
  )
);

-- --------------------------------------------------------------------------
-- 4. Questões, alternativas, gabaritos privados e vínculo com a versão
-- --------------------------------------------------------------------------
with payload as (
  select *
  from jsonb_to_recordset($vw_questions$[{"id":"9a04c130-e959-5f7c-ad41-e2e56cd912dc","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q01","competency_id":"dfb721a3-7005-591e-af41-655027fa487b","block_code":"definicoes_adesao","prompt":"Segundo o Regulamento, qual empresa é a única responsável legal pela representação ativa e passiva dos grupos de consórcio?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":1,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"2e6d2845-4e97-544f-8002-f0e506ad6b4a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q02","competency_id":"dfb721a3-7005-591e-af41-655027fa487b","block_code":"definicoes_adesao","prompt":"De acordo com a definição de \"CONSORCIADO EXCLUÍDO\", esse status ocorre quando o participante deixa de pagar quantas parcelas de forma alternada ou sucessiva?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":2,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"7e1c74b1-fe4e-589c-a378-42e2a7574953","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q03","competency_id":"9c4fdbc5-ed84-5b2f-ba18-0ba6f03b1330","block_code":"constituicao_grupo","prompt":"O Fundo de Reserva, conforme a Cláusula 5.1, NÃO pode ser utilizado para:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":3,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"80f58936-3218-5093-95e0-4f5911b0e8b5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q04","competency_id":"dfb721a3-7005-591e-af41-655027fa487b","block_code":"definicoes_adesao","prompt":"Segundo a Cláusula 1.2 (Condições de Não Aceite), a renda ou remuneração mensal comprovada pelo consorciado deve ser igual ou superior a quantas vezes o valor da parcela?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":4,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"ed3f88a6-3b4a-54b2-9a9c-5632c8a95c7c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q05","competency_id":"0cf51b7a-f52c-544d-a0ea-c32436d4a113","block_code":"planos","prompt":"No PLANO SMART, o benefício de isenção da taxa de administração sobre cada parcela paga:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":5,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"93aa34a5-e908-5ab7-8986-9b61295c47c3","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q06","competency_id":"0cf51b7a-f52c-544d-a0ea-c32436d4a113","block_code":"planos","prompt":"No PLANO ESSENCIAL, o percentual de recolhimento mensal ao fundo comum e ao fundo de reserva é reduzido em qual percentual até a data da contemplação?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":6,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"41187937-0289-5fe3-9d41-5170173ebef6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q07","competency_id":"0cf51b7a-f52c-544d-a0ea-c32436d4a113","block_code":"planos","prompt":"No PLANO ESSENCIAL 50, para utilizar a integralidade do crédito contratado após a contemplação, o consorciado deve, obrigatoriamente:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":7,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"d32ef77b-7bb2-5384-9ab5-2326d782c27a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q08","competency_id":"dfb721a3-7005-591e-af41-655027fa487b","block_code":"definicoes_adesao","prompt":"Segundo a Cláusula 3.5, o consorciado que adere a um grupo já em andamento deve:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":8,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"c3071b53-094c-5c2b-8dc0-be1c3057767e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q09","competency_id":"860b1e56-0438-536c-bb88-c213c1b9bfac","block_code":"contribuicoes_taxas","prompt":"De acordo com a Cláusula 4ª (Diferença de Parcela), quando o valor do crédito contratado é alterado, o saldo do fundo comum deve ser ajustado e a diferença cobrada ou compensada em qual prazo?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":9,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"c6c4bbdb-6530-5620-8b6c-0a8b04520a4b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q10","competency_id":"860b1e56-0438-536c-bb88-c213c1b9bfac","block_code":"contribuicoes_taxas","prompt":"Na Recomposição da Perda Financeira do Grupo (Cláusula 4.1.1), qual é a ORDEM DE PREFERÊNCIA para cobrir a perda de poder aquisitivo?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":10,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"89fc7104-f0a1-5907-b2ec-ece5315a7068","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q11","competency_id":"860b1e56-0438-536c-bb88-c213c1b9bfac","block_code":"contribuicoes_taxas","prompt":"Segundo a Cláusula 6ª, um pagamento de contribuição feito por cheque somente será reconhecido se:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":11,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"38ff58c2-7a88-5bf4-a385-5991cd0df39a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q12","competency_id":"860b1e56-0438-536c-bb88-c213c1b9bfac","block_code":"contribuicoes_taxas","prompt":"A Taxa de Administração Antecipada, conforme a Cláusula 10, Parágrafo Segundo:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":12,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"6d816547-ce54-5217-904a-f95cb85bae54","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q13","competency_id":"9c4fdbc5-ed84-5b2f-ba18-0ba6f03b1330","block_code":"constituicao_grupo","prompt":"De acordo com a Cláusula 11, Parágrafo Quinto, em um grupo com créditos de valores diferenciados, o crédito de menor valor, na data da constituição do grupo, não pode ser inferior a que percentual do crédito de maior valor?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":13,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"bd5c9a8d-3fbd-52b5-a1dc-0b4f63ef2683","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q14","competency_id":"9c4fdbc5-ed84-5b2f-ba18-0ba6f03b1330","block_code":"constituicao_grupo","prompt":"Segundo a Cláusula 11, Parágrafo Sétimo, qual é o percentual máximo permitido de cotas que um mesmo consorciado pode possuir em relação ao número máximo de cotas ativas do grupo?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":14,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"e706aae6-5e18-5929-8a8e-94841b44a5e8","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q15","competency_id":"860b1e56-0438-536c-bb88-c213c1b9bfac","block_code":"contribuicoes_taxas","prompt":"Sobre a Taxa de Cadastro/Documentos de Garantia (Cláusula 12, \"i\"), qual é o percentual cobrado sobre o valor do crédito vigente na data da contemplação?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":15,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"1eb12daa-7c0c-5f83-a728-8b8574c7f69b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q16","competency_id":"24e64406-c6c8-58d8-9e3e-1de6eea804d5","block_code":"assembleias","prompt":"As Assembleias Gerais Ordinárias, conforme o Parágrafo Único da Cláusula 13, são realizadas:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":16,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"9087c288-2dcc-56ce-a092-0868cdc7cec7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q17","competency_id":"24e64406-c6c8-58d8-9e3e-1de6eea804d5","block_code":"assembleias","prompt":"Segundo a Cláusula 13.1, inciso IV, ao aderir ao contrato, o CONSORCIADO outorga à ADMINISTRADORA:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":17,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"606549a5-5e2e-5043-a434-6ff6bb736647","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q18","competency_id":"24e64406-c6c8-58d8-9e3e-1de6eea804d5","block_code":"assembleias","prompt":"Qual das alternativas a seguir NÃO é uma matéria de competência da Assembleia Geral Extraordinária, segundo a Cláusula 14?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":18,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"eefea76e-6785-5044-b188-b9da9ed67a85","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q19","competency_id":"976964de-40bf-5860-a663-93737500b1e5","block_code":"contemplacao_lances","prompt":"De acordo com a Cláusula 16, a ordem de contemplação nas assembleias ordinárias é:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":19,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"4f2fffcd-aa65-5437-9ef9-28e17eeadae9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q20","competency_id":"976964de-40bf-5860-a663-93737500b1e5","block_code":"contemplacao_lances","prompt":"Para grupos com até 1.000 (mil) participantes, segundo a Cláusula 18, Parágrafo Primeiro, \"a\", quantas centenas são formadas a partir da extração da Loteria Federal para fins de sorteio?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":20,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"3ce32820-51da-5355-b80d-b039f156a7cf","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q21","competency_id":"976964de-40bf-5860-a663-93737500b1e5","block_code":"contemplacao_lances","prompt":"Segundo a Cláusula 17, somente pode participar do sorteio e concorrer aos lances o CONSORCIADO ATIVO que esteja:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":21,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"a946fff4-49f5-53f5-8e91-e9eae6a632ce","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q22","competency_id":"976964de-40bf-5860-a663-93737500b1e5","block_code":"contemplacao_lances","prompt":"Conforme a Cláusula 19, \"a\", o valor do lance ofertado não pode ser inferior a qual percentual do saldo devedor do consorciado licitante?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":22,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"f4a51cc5-b355-515c-a6d1-5b33c0ca2dce","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q23","competency_id":"976964de-40bf-5860-a663-93737500b1e5","block_code":"contemplacao_lances","prompt":"Sobre o CANCELAMENTO DA CONTEMPLAÇÃO (Cláusula 18, Parágrafo Onze), a contemplação do CONSORCIADO ATIVO que não utilizou o crédito será cancelada após deixar de pagar quantas contribuições mensais, sucessivas ou alternadas?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":23,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"627d64b4-af72-576e-a923-129debfd0648","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q24","competency_id":"976964de-40bf-5860-a663-93737500b1e5","block_code":"contemplacao_lances","prompt":"De acordo com a Cláusula 21, qual é o prazo improrrogável para cobertura (pagamento) do lance vencedor, contado da Assembleia Geral Ordinária de contemplação?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":24,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"c698698d-611e-5815-8b52-d8e22d6573e4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q25","competency_id":"976964de-40bf-5860-a663-93737500b1e5","block_code":"contemplacao_lances","prompt":"Segundo a Cláusula 23, \"b\", a mudança do valor do crédito inicialmente contratado por outro dentro do mesmo grupo não pode ultrapassar qual diferença percentual (para maior ou para menor) em relação ao crédito atual?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":25,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"6dd5878b-78c4-5657-adf5-52a876c5f284","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q26","competency_id":"baa037cf-3f7f-581e-9d22-de5acfd02004","block_code":"credito_garantias","prompt":"Conforme a Cláusula 32, é facultado ao CONSORCIADO contemplado que não utilizar o crédito receber o valor em espécie após quantos dias da contemplação, mediante quitação total das obrigações?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":26,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"2436a67a-e538-5a72-9a77-8035ec6ba110","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q27","competency_id":"baa037cf-3f7f-581e-9d22-de5acfd02004","block_code":"credito_garantias","prompt":"Sobre a garantia principal do bem adquirido, conforme a Cláusula 33 e seu Parágrafo Único, qual é a modalidade de garantia utilizada?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":27,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"c57fb58d-70b5-5bce-bdca-d9823599a74f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q28","competency_id":"9527c059-e9b5-53c7-a6dd-bc73aaf38a47","block_code":"cessao_exclusao_prescricao","prompt":"Na CESSÃO DO CONTRATO (Cláusula 37), a taxa de transferência equivale a qual percentual do valor do crédito?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":28,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"7479f720-6e1b-515a-9269-2da008213178","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q29","competency_id":"9527c059-e9b5-53c7-a6dd-bc73aaf38a47","block_code":"cessao_exclusao_prescricao","prompt":"Segundo a Cláusula 42 (penalidade pela exclusão do consorciado), se o consorciado tiver integralizado mais de 50% ao fundo comum, qual é a consequência quanto à multa compensatória?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":29,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"2635face-976d-5708-8695-9d4d320fed53","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_vw_cnvw_q30","competency_id":"9527c059-e9b5-53c7-a6dd-bc73aaf38a47","block_code":"cessao_exclusao_prescricao","prompt":"Conforme a Cláusula 43.4, prescreve em quantos anos a pretensão do CONSORCIADO ATIVO e do CONSORCIADO EXCLUÍDO contra o Grupo de Consórcio e/ou contra a ADMINISTRADORA?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"cnvw-v2.1-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":30,"source_material_code":"regulamento_cnvw_embracon_v2_1","source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document":"Teste_06_Regulamento_CNVW_Embracon.md","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}}]$vw_questions$::jsonb) as x(
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

with payload as (
  select *
  from jsonb_to_recordset($vw_options$[{"id":"e1eee881-dcb3-5df4-8592-475ded95597b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9a04c130-e959-5f7c-ad41-e2e56cd912dc","option_code":"A","option_text":"Embracon Administradora de Consórcio Ltda.","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":1}},{"id":"274a538d-1c7c-53fa-95b6-36db0ac130dc","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9a04c130-e959-5f7c-ad41-e2e56cd912dc","option_code":"B","option_text":"Consórcio Nacional Volkswagen – Administradora de Consórcio Ltda. (CNVW)","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":1}},{"id":"656c44bf-ebdd-5e03-a04c-a961f8e0bdda","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9a04c130-e959-5f7c-ad41-e2e56cd912dc","option_code":"C","option_text":"Banco Central do Brasil","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":1}},{"id":"6e7ea3ec-d39f-521c-8385-35154f63ff70","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9a04c130-e959-5f7c-ad41-e2e56cd912dc","option_code":"D","option_text":"CADE – Conselho Administrativo de Defesa Econômica","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":1}},{"id":"777a508d-082b-51a6-aeac-0b50ff474428","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"2e6d2845-4e97-544f-8002-f0e506ad6b4a","option_code":"A","option_text":"1 (uma) parcela","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":2}},{"id":"32b4ab08-5029-5d7e-9073-d7fbc18b56e5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"2e6d2845-4e97-544f-8002-f0e506ad6b4a","option_code":"B","option_text":"2 (duas) parcelas","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":2}},{"id":"ece79e6d-f4e2-5aaa-a1c3-14231f52c29c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"2e6d2845-4e97-544f-8002-f0e506ad6b4a","option_code":"C","option_text":"3 (três) parcelas","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":2}},{"id":"33dc7004-1fb4-5724-ad2a-7aeb1fefbe6b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"2e6d2845-4e97-544f-8002-f0e506ad6b4a","option_code":"D","option_text":"4 (quatro) parcelas","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":2}},{"id":"82d896a9-50e8-5404-8f02-86c6cea87380","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"7e1c74b1-fe4e-589c-a378-42e2a7574953","option_code":"A","option_text":"Cobertura de eventual insuficiência de recursos do fundo comum","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":3}},{"id":"3d8a6574-6ee8-5e09-bee5-83780cfc3b74","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"7e1c74b1-fe4e-589c-a378-42e2a7574953","option_code":"B","option_text":"Pagamento de prêmio de seguro para cobertura de inadimplência de prestações de consorciados contemplados","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":3}},{"id":"22a5f63b-391c-5f3e-843d-f424b1bea815","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"7e1c74b1-fe4e-589c-a378-42e2a7574953","option_code":"C","option_text":"Pagamento de comissão de venda aos representantes comerciais","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":3}},{"id":"ceb74209-b2ca-5236-bbb5-93d814f9595b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"7e1c74b1-fe4e-589c-a378-42e2a7574953","option_code":"D","option_text":"Pagamento de despesas e custos de medidas judiciais ou extrajudiciais para recebimento de crédito do grupo","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":3}},{"id":"6bf43b4c-e0af-5436-af9c-e8d70dba5ccb","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"80f58936-3218-5093-95e0-4f5911b0e8b5","option_code":"A","option_text":"1 (uma) vez","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":4}},{"id":"872ad422-6a0f-5f9a-86dc-90a8d8dfd74e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"80f58936-3218-5093-95e0-4f5911b0e8b5","option_code":"B","option_text":"2 (duas) vezes","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":4}},{"id":"9d655242-9be4-5d1a-9dfa-6231d8901a98","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"80f58936-3218-5093-95e0-4f5911b0e8b5","option_code":"C","option_text":"3 (três) vezes","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":4}},{"id":"a350851c-4535-5202-a19c-9d7d2f84e611","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"80f58936-3218-5093-95e0-4f5911b0e8b5","option_code":"D","option_text":"5 (cinco) vezes","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":4}},{"id":"012679d3-40c7-578a-acdf-01043ba974e5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ed3f88a6-3b4a-54b2-9a9c-5632c8a95c7c","option_code":"A","option_text":"Persiste durante toda a vigência do contrato, mesmo após a contemplação","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":5}},{"id":"fbd94359-f2e6-5428-be58-e7f01e5b1671","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ed3f88a6-3b4a-54b2-9a9c-5632c8a95c7c","option_code":"B","option_text":"Vigora somente até a contemplação da cota, passando a incidir normalmente após esse evento","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":5}},{"id":"e2ff8c32-e6c0-5e46-984b-7bec2d5e6226","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ed3f88a6-3b4a-54b2-9a9c-5632c8a95c7c","option_code":"C","option_text":"Não se aplica em nenhuma hipótese, pois a taxa é sempre cobrada integralmente","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":5}},{"id":"a2b3102c-6a25-51da-ba66-0c425886a62d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ed3f88a6-3b4a-54b2-9a9c-5632c8a95c7c","option_code":"D","option_text":"Aplica-se apenas ao seguro de vida contratado","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":5}},{"id":"421be4d2-d19e-58ab-bff0-8560f5cc62ca","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"93aa34a5-e908-5ab7-8986-9b61295c47c3","option_code":"A","option_text":"10% (dez por cento)","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":6}},{"id":"417c11f8-37b7-5d8e-9205-4729129d804c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"93aa34a5-e908-5ab7-8986-9b61295c47c3","option_code":"B","option_text":"25% (vinte e cinco por cento)","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":6}},{"id":"1f05a953-2ede-5c90-9fc5-c19e28086edd","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"93aa34a5-e908-5ab7-8986-9b61295c47c3","option_code":"C","option_text":"50% (cinquenta por cento)","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":6}},{"id":"8f4deb15-b5b3-5182-926a-c5d4a8bde475","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"93aa34a5-e908-5ab7-8986-9b61295c47c3","option_code":"D","option_text":"75% (setenta e cinco por cento)","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":6}},{"id":"5968f084-9ec7-5c0f-809e-49400cb87f24","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"41187937-0289-5fe3-9d41-5170173ebef6","option_code":"A","option_text":"Renunciar a 50% do crédito contratado","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":7}},{"id":"001be81d-6cee-565c-becb-48494b7cd0f3","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"41187937-0289-5fe3-9d41-5170173ebef6","option_code":"B","option_text":"Quitar a diferença recolhida a menor correspondente a 50% do total do crédito, por uma das formas previstas no Regulamento","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":7}},{"id":"ad46931e-5213-500f-a937-6d2b00767d48","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"41187937-0289-5fe3-9d41-5170173ebef6","option_code":"C","option_text":"Aguardar o encerramento total do grupo sem nenhuma ação adicional","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":7}},{"id":"a2adbfc0-c764-531f-9c77-d947646371cd","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"41187937-0289-5fe3-9d41-5170173ebef6","option_code":"D","option_text":"Pagar apenas a taxa de administração antecipada","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":7}},{"id":"53cfd24d-e19f-5883-aeec-2b61067d05b6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d32ef77b-7bb2-5384-9ab5-2326d782c27a","option_code":"A","option_text":"Pagar apenas as parcelas remanescentes referentes ao seu próprio prazo contratual, ignorando o histórico do grupo","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":8}},{"id":"f2f56cbb-569b-5a6d-bd28-b5929feded42","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d32ef77b-7bb2-5384-9ab5-2326d782c27a","option_code":"B","option_text":"Integralizar, desde a primeira assembleia de participação, o percentual ideal mensal conforme o número de contribuições remanescentes até o encerramento do grupo","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":8}},{"id":"f53e48bf-b6ef-5bcc-b231-dba26e2fcb57","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d32ef77b-7bb2-5384-9ab5-2326d782c27a","option_code":"C","option_text":"Ser automaticamente contemplado na primeira assembleia","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":8}},{"id":"9ba64aaa-8423-5e84-a2a5-13bec357fb2a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d32ef77b-7bb2-5384-9ab5-2326d782c27a","option_code":"D","option_text":"Pagar valor fixo diferente dos demais integrantes do grupo, sem relação com o número de contribuições restantes","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":8}},{"id":"874cb3d1-107e-548e-a4fb-d9a899fdac00","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c3071b53-094c-5c2b-8dc0-be1c3057767e","option_code":"A","option_text":"Na mesma parcela em que ocorreu a alteração","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":9}},{"id":"290c74f9-b99b-5a32-81d3-4f0bf5e1316f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c3071b53-094c-5c2b-8dc0-be1c3057767e","option_code":"B","option_text":"Até a segunda prestação imediatamente seguinte à data da alteração do crédito","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":9}},{"id":"edca7e6e-8265-57ba-8338-1a0e2c7633f9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c3071b53-094c-5c2b-8dc0-be1c3057767e","option_code":"C","option_text":"Somente na assembleia de encerramento do grupo","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":9}},{"id":"d8d70748-cd02-52fe-8a38-347b164f5260","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c3071b53-094c-5c2b-8dc0-be1c3057767e","option_code":"D","option_text":"No prazo de 12 meses","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":9}},{"id":"010dc69f-b092-5253-a4b4-0aadf85e2c29","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c6c4bbdb-6530-5620-8b6c-0a8b04520a4b","option_code":"A","option_text":"Rateio entre consorciados; fundo de reserva; rendimentos de aplicação financeira","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":10}},{"id":"3e4d12f1-5ce4-59d6-b1ab-db3cef4d881a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c6c4bbdb-6530-5620-8b6c-0a8b04520a4b","option_code":"B","option_text":"Rendimentos de aplicação financeira/multas retidas; recurso do fundo de reserva; rateio entre os consorciados ativos","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":10}},{"id":"adf6336a-0d74-576e-9bb9-032bb7021769","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c6c4bbdb-6530-5620-8b6c-0a8b04520a4b","option_code":"C","option_text":"Apenas rateio entre os consorciados ativos, sem outras opções","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":10}},{"id":"9f2846f5-a51a-58ec-9f16-905166a1461b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c6c4bbdb-6530-5620-8b6c-0a8b04520a4b","option_code":"D","option_text":"Recursos próprios da ADMINISTRADORA, sem ônus ao grupo","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":10}},{"id":"7ddbf65a-0f2c-5fd9-b722-d8a3b7daa75f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"89fc7104-f0a1-5907-b2ec-ece5315a7068","option_code":"A","option_text":"For emitido ao portador","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":11}},{"id":"5b4784e5-1d6a-56d4-9641-4f30ad16e195","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"89fc7104-f0a1-5907-b2ec-ece5315a7068","option_code":"B","option_text":"For nominal à ADMINISTRADORA e cruzado em preto, mediante compensação","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":11}},{"id":"05947231-c68f-5f0d-ae46-0f9fd8741adc","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"89fc7104-f0a1-5907-b2ec-ece5315a7068","option_code":"C","option_text":"For pago em qualquer banco, independentemente de nominalidade","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":11}},{"id":"57aa8620-c13b-5123-9088-006287105f10","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"89fc7104-f0a1-5907-b2ec-ece5315a7068","option_code":"D","option_text":"For enviado por correio registrado","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":11}},{"id":"2014cbd0-869a-54df-ab96-47606c4be86e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"38ff58c2-7a88-5bf4-a385-5991cd0df39a","option_code":"A","option_text":"É cobrada em adição à taxa de administração total contratada","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":12}},{"id":"d2e24ca1-fc73-585e-a19e-e13774ba8444","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"38ff58c2-7a88-5bf4-a385-5991cd0df39a","option_code":"B","option_text":"É integralmente deduzida do valor total da taxa de administração contratada","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":12}},{"id":"9c088ccf-12a4-5db2-9082-b627a75500a4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"38ff58c2-7a88-5bf4-a385-5991cd0df39a","option_code":"C","option_text":"Só é aplicável a consorciados excluídos","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":12}},{"id":"c0df5039-8471-5552-abd0-2a47838dca2b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"38ff58c2-7a88-5bf4-a385-5991cd0df39a","option_code":"D","option_text":"É devolvida integralmente após a contemplação","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":12}},{"id":"36b99baf-e735-5755-8c76-6817323e5f47","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"6d816547-ce54-5217-904a-f95cb85bae54","option_code":"A","option_text":"30%","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":13}},{"id":"0c144e54-a5d3-59d7-91e2-cea739165e78","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"6d816547-ce54-5217-904a-f95cb85bae54","option_code":"B","option_text":"40%","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":13}},{"id":"0ab856e4-a039-57c6-8c82-3184a588dc8d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"6d816547-ce54-5217-904a-f95cb85bae54","option_code":"C","option_text":"50%","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":13}},{"id":"12ce01a5-dfb4-5f0b-9f83-015e7a6828ca","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"6d816547-ce54-5217-904a-f95cb85bae54","option_code":"D","option_text":"70%","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":13}},{"id":"669739a0-022e-5eff-8684-d5cbfbc19097","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"bd5c9a8d-3fbd-52b5-a1dc-0b4f63ef2683","option_code":"A","option_text":"5%","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":14}},{"id":"d48a9b7f-dca4-5fbb-a645-fbb737802cf6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"bd5c9a8d-3fbd-52b5-a1dc-0b4f63ef2683","option_code":"B","option_text":"10%","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":14}},{"id":"46b56993-4a2e-5f76-9bf7-33cdee83d75b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"bd5c9a8d-3fbd-52b5-a1dc-0b4f63ef2683","option_code":"C","option_text":"20%","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":14}},{"id":"f628ae44-77e1-5a7c-950d-c5225aa53022","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"bd5c9a8d-3fbd-52b5-a1dc-0b4f63ef2683","option_code":"D","option_text":"25%","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":14}},{"id":"d422744c-c4c8-523e-b630-5c8652fb57d5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"e706aae6-5e18-5929-8a8e-94841b44a5e8","option_code":"A","option_text":"0,5%","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":15}},{"id":"5737e2e0-5eaf-55ed-a54a-f88d0342e067","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"e706aae6-5e18-5929-8a8e-94841b44a5e8","option_code":"B","option_text":"1%","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":15}},{"id":"9ec383f0-6486-5e95-bc40-14cea8916f4c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"e706aae6-5e18-5929-8a8e-94841b44a5e8","option_code":"C","option_text":"2%","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":15}},{"id":"d3a62ff5-402c-5016-9434-12eaac3194aa","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"e706aae6-5e18-5929-8a8e-94841b44a5e8","option_code":"D","option_text":"5%","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":15}},{"id":"daae68a8-911f-50ef-b74b-9bb4787dac67","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1eb12daa-7c0c-5f83-a728-8b8574c7f69b","option_code":"A","option_text":"Trimestralmente, de forma presencial obrigatória","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":16}},{"id":"5dce10ef-7220-52a1-a37c-969d1f7d7fe7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1eb12daa-7c0c-5f83-a728-8b8574c7f69b","option_code":"B","option_text":"Mensalmente, de forma eletrônica, na sede da Prestadora de Serviços de Administração","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":16}},{"id":"0ede887f-5155-5304-9a81-12f3712db39b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1eb12daa-7c0c-5f83-a728-8b8574c7f69b","option_code":"C","option_text":"Anualmente, apenas quando solicitado por 50% dos consorciados","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":16}},{"id":"3254fa76-89c1-50a4-ae13-e58ff0159372","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1eb12daa-7c0c-5f83-a728-8b8574c7f69b","option_code":"D","option_text":"Somente quando há saldo suficiente para contemplação por sorteio","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":16}},{"id":"2e79755d-fc77-5b89-b892-115a50a7b4c3","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9087c288-2dcc-56ce-a092-0868cdc7cec7","option_code":"A","option_text":"Procuração para representá-lo apenas em juízo","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":17}},{"id":"870c2923-34bb-5f19-8665-62c0e5c26512","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9087c288-2dcc-56ce-a092-0868cdc7cec7","option_code":"B","option_text":"Procuração com poderes para representá-lo nas Assembleias Gerais Ordinárias em que estiver ausente e não tiver constituído outro procurador","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":17}},{"id":"ded4c3d9-9ad6-5495-ab07-4f330856b864","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9087c288-2dcc-56ce-a092-0868cdc7cec7","option_code":"C","option_text":"Autorização para vender sua cota a terceiros sem aviso prévio","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":17}},{"id":"e8e23d7a-4daa-55dd-a0dd-565c98a12f83","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9087c288-2dcc-56ce-a092-0868cdc7cec7","option_code":"D","option_text":"Poderes para alterar unilateralmente o valor do crédito contratado","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":17}},{"id":"6a209724-5f7a-54cd-baac-88cc9f4b50ce","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"606549a5-5e2e-5043-a434-6ff6bb736647","option_code":"A","option_text":"Fusão de grupos de consórcio administrados pela ADMINISTRADORA","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":18}},{"id":"9364df22-5d5b-57d6-b47c-c81bd1dff0a7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"606549a5-5e2e-5043-a434-6ff6bb736647","option_code":"B","option_text":"Substituição do bem ou crédito referencial optado no contrato","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":18}},{"id":"cec6ef94-2aae-531c-af33-a51f9b72863f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"606549a5-5e2e-5043-a434-6ff6bb736647","option_code":"C","option_text":"Contemplação mensal ordinária por sorteio ou lance","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":18}},{"id":"cfaca2c8-9d0d-5ff8-8c64-f19f578a9530","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"606549a5-5e2e-5043-a434-6ff6bb736647","option_code":"D","option_text":"Ampliação do prazo de duração do grupo","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":18}},{"id":"33413d44-2760-5799-955b-211a0f065902","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"eefea76e-6785-5044-b188-b9da9ed67a85","option_code":"A","option_text":"Primeiro lance, depois sorteio","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":19}},{"id":"62922340-a6f4-5ccf-b2d6-8ff44334e468","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"eefea76e-6785-5044-b188-b9da9ed67a85","option_code":"B","option_text":"Primeiro sorteio aos ATIVOS, depois contemplação aos EXCLUÍDOS, e em seguida contemplação por lance","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":19}},{"id":"f65b9dc8-d1d2-511a-8dca-22804a348426","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"eefea76e-6785-5044-b188-b9da9ed67a85","option_code":"C","option_text":"Somente sorteio, sem possibilidade de lance","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":19}},{"id":"73850f2d-6d5c-5a13-8500-3378ab996e44","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"eefea76e-6785-5044-b188-b9da9ed67a85","option_code":"D","option_text":"Somente lance, sem possibilidade de sorteio","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":19}},{"id":"0258f975-6a4e-55eb-b358-685d04f0aa81","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4f2fffcd-aa65-5437-9ef9-28e17eeadae9","option_code":"A","option_text":"5 centenas","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":20}},{"id":"eb9b5b59-f2c9-5cfc-b5af-5b0b1fbcdd56","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4f2fffcd-aa65-5437-9ef9-28e17eeadae9","option_code":"B","option_text":"10 centenas","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":20}},{"id":"3b689b94-de91-5f8a-88c6-22afc01cecf6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4f2fffcd-aa65-5437-9ef9-28e17eeadae9","option_code":"C","option_text":"15 centenas","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":20}},{"id":"b8a4992b-fdbf-5fb9-a70a-29ba7867b047","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4f2fffcd-aa65-5437-9ef9-28e17eeadae9","option_code":"D","option_text":"20 centenas","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":20}},{"id":"a8336e3f-8c6d-54c0-a113-b09f41f895a2","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"3ce32820-51da-5355-b80d-b039f156a7cf","option_code":"A","option_text":"Contemplado e com o crédito já utilizado","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":21}},{"id":"a7bf5753-da7b-5b62-b829-a813f923d285","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"3ce32820-51da-5355-b80d-b039f156a7cf","option_code":"B","option_text":"Não contemplado e em dia com suas contribuições até a data do vencimento da parcela, antes da Assembleia Geral Ordinária","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":21}},{"id":"f60f0054-35d0-5660-911c-60201a9259f5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"3ce32820-51da-5355-b80d-b039f156a7cf","option_code":"C","option_text":"Inadimplente há mais de 60 dias","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":21}},{"id":"58f71bb0-f361-543d-ab7b-e04ddd5cba9d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"3ce32820-51da-5355-b80d-b039f156a7cf","option_code":"D","option_text":"Excluído do grupo, desde que solicite formalmente","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":21}},{"id":"fa3f002b-859c-5bd6-accc-bb74c399f3c7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a946fff4-49f5-53f5-8e91-e9eae6a632ce","option_code":"A","option_text":"0,5%","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":22}},{"id":"df2e85e8-473c-5b34-90cb-dae87a954b7d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a946fff4-49f5-53f5-8e91-e9eae6a632ce","option_code":"B","option_text":"1%","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":22}},{"id":"a8ed963f-5f8d-5a75-8183-c74f957692ea","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a946fff4-49f5-53f5-8e91-e9eae6a632ce","option_code":"C","option_text":"2%","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":22}},{"id":"b6a38edc-461d-5300-9fb7-a905ed5fa64c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a946fff4-49f5-53f5-8e91-e9eae6a632ce","option_code":"D","option_text":"5%","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":22}},{"id":"d5f7c8c5-9936-5242-8736-40ae325f1f7d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f4a51cc5-b355-515c-a6d1-5b33c0ca2dce","option_code":"A","option_text":"1 (uma)","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":23}},{"id":"2f746cdd-047e-597c-94a5-8e59fe3c4010","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f4a51cc5-b355-515c-a6d1-5b33c0ca2dce","option_code":"B","option_text":"2 (duas)","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":23}},{"id":"9a4df073-2de9-57b5-a67c-7cd6f352f30d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f4a51cc5-b355-515c-a6d1-5b33c0ca2dce","option_code":"C","option_text":"3 (três)","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":23}},{"id":"cfd94627-9ea9-5843-848c-6de8c00cc532","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f4a51cc5-b355-515c-a6d1-5b33c0ca2dce","option_code":"D","option_text":"4 (quatro)","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":23}},{"id":"2f986265-63f7-5cf9-8b91-f06491177d09","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"627d64b4-af72-576e-a923-129debfd0648","option_code":"A","option_text":"2 (dois) dias úteis","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":24}},{"id":"77a7734a-31fb-5b04-97b9-05c7fa8cb898","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"627d64b4-af72-576e-a923-129debfd0648","option_code":"B","option_text":"5 (cinco) dias úteis","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":24}},{"id":"3cbe1486-ce88-5b78-ad0a-1729c17fc001","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"627d64b4-af72-576e-a923-129debfd0648","option_code":"C","option_text":"10 (dez) dias úteis","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":24}},{"id":"a02c708a-4324-561b-8a1d-fcfe5b75a117","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"627d64b4-af72-576e-a923-129debfd0648","option_code":"D","option_text":"30 (trinta) dias corridos","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":24}},{"id":"5c9b460a-8383-5611-b86b-5e19303fb8fc","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c698698d-611e-5815-8b52-d8e22d6573e4","option_code":"A","option_text":"10%","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":25}},{"id":"3385c1c9-caed-5e20-8551-c7a017680e75","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c698698d-611e-5815-8b52-d8e22d6573e4","option_code":"B","option_text":"20%","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":25}},{"id":"e03ce480-5758-5220-99ef-8536a5857163","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c698698d-611e-5815-8b52-d8e22d6573e4","option_code":"C","option_text":"30%","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":25}},{"id":"9490d8b7-a0a4-5e78-a314-50c418a2fe27","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c698698d-611e-5815-8b52-d8e22d6573e4","option_code":"D","option_text":"50%","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":25}},{"id":"dbeba5ff-7df3-5042-8739-63f856beceed","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"6dd5878b-78c4-5657-adf5-52a876c5f284","option_code":"A","option_text":"90 dias","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":26}},{"id":"1a034ffe-3978-5931-b02c-2efd0a2df084","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"6dd5878b-78c4-5657-adf5-52a876c5f284","option_code":"B","option_text":"120 dias","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":26}},{"id":"bafd5fec-5a33-5332-86b3-66054631f075","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"6dd5878b-78c4-5657-adf5-52a876c5f284","option_code":"C","option_text":"180 dias","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":26}},{"id":"bae18d1a-a434-595f-bd7d-d2aeccde9f72","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"6dd5878b-78c4-5657-adf5-52a876c5f284","option_code":"D","option_text":"365 dias","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":26}},{"id":"9c72d721-5d8d-5cfd-bf4d-aa36c675d242","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"2436a67a-e538-5a72-9a77-8035ec6ba110","option_code":"A","option_text":"Hipoteca","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":27}},{"id":"f51d0096-9e0a-5333-a26c-3ffdd7efd438","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"2436a67a-e538-5a72-9a77-8035ec6ba110","option_code":"B","option_text":"Penhor","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":27}},{"id":"c20dbb53-fc9b-50b5-86ce-78b358e8263b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"2436a67a-e538-5a72-9a77-8035ec6ba110","option_code":"C","option_text":"Alienação Fiduciária","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":27}},{"id":"c83ef524-d80b-5ea3-b2c6-95715fcc893f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"2436a67a-e538-5a72-9a77-8035ec6ba110","option_code":"D","option_text":"Fiança bancária","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":27}},{"id":"8c944db4-c4db-5edb-a279-c4eb3b47463e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c57fb58d-70b5-5bce-bdca-d9823599a74f","option_code":"A","option_text":"0,5%","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":28}},{"id":"7babb36a-6af6-5587-8f24-49fe0f832dea","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c57fb58d-70b5-5bce-bdca-d9823599a74f","option_code":"B","option_text":"1%","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":28}},{"id":"de336292-6817-5b46-b369-b8945e253955","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c57fb58d-70b5-5bce-bdca-d9823599a74f","option_code":"C","option_text":"2%","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":28}},{"id":"0f26686f-0503-51d5-841a-c1172c7aa0e2","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c57fb58d-70b5-5bce-bdca-d9823599a74f","option_code":"D","option_text":"3%","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":28}},{"id":"f61019b7-9b4f-5562-8ab4-7532061f775a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"7479f720-6e1b-515a-9269-2da008213178","option_code":"A","option_text":"Aplica-se multa de 20%","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":29}},{"id":"cb1b0baa-ef19-5a88-8b83-cc82ad42633e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"7479f720-6e1b-515a-9269-2da008213178","option_code":"B","option_text":"Aplica-se multa de 15%","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":29}},{"id":"b031a21d-b8cf-514c-bad4-7cfcd53c950c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"7479f720-6e1b-515a-9269-2da008213178","option_code":"C","option_text":"Aplica-se multa de 10%","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":29}},{"id":"b9b11906-568f-57cc-a48f-141b71e2a8ef","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"7479f720-6e1b-515a-9269-2da008213178","option_code":"D","option_text":"Fica isento da incidência da multa","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":29}},{"id":"73ce008d-57e2-5094-9672-613fd59958ac","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"2635face-976d-5708-8695-9d4d320fed53","option_code":"A","option_text":"1 (um) ano","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":30}},{"id":"b8f67ec7-26a0-5dae-a872-bc653a03115e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"2635face-976d-5708-8695-9d4d320fed53","option_code":"B","option_text":"2 (dois) anos","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":30}},{"id":"082f0c7e-3234-5e0e-8ec8-5f8f9168c27e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"2635face-976d-5708-8695-9d4d320fed53","option_code":"C","option_text":"3 (três) anos","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":30}},{"id":"c6d4c22c-c08b-568d-b462-ba4e890adc93","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"2635face-976d-5708-8695-9d4d320fed53","option_code":"D","option_text":"5 (cinco) anos","metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":30}}]$vw_options$::jsonb) as x(
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

with payload as (
  select *
  from jsonb_to_recordset($vw_keys$[{"question_id":"9a04c130-e959-5f7c-ad41-e2e56cd912dc","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"O Regulamento afirma expressamente: *\"O Consórcio Nacional Volkswagen é o único responsável legal, representando os grupos de consórcio de forma ativa e passiva\"*, mesmo com a Embracon atuando como prestadora de serviços de administração.","source_reference":"Regulamento do Contrato de Consórcio CNVW/Embracon — Versão 2.1","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":1,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"2e6d2845-4e97-544f-8002-f0e506ad6b4a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"A definição de CONSORCIADO EXCLUÍDO menciona a exclusão \"por desistência declarada, ou ainda por deixar de pagar duas parcelas de forma alternada ou sucessiva\".","source_reference":"Regulamento do Contrato de Consórcio CNVW/Embracon — Versão 2.1","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":2,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"7e1c74b1-fe4e-589c-a378-42e2a7574953","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"A Cláusula 5.1 lista taxativamente as finalidades do Fundo de Reserva (incisos I a V) e comissões de vendedores não constam entre elas — essas despesas são cobertas pela Taxa de Administração Antecipada (Cláusula 10).","source_reference":"Regulamento CNVW/Embracon — Cláusula 5.1, NÃO pode ser utilizado para","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":3,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"80f58936-3218-5093-95e0-4f5911b0e8b5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"A Cláusula 1.2 exige comprovação de renda/remuneração mensal igual ou superior a 3 (três) vezes o valor da parcela.","source_reference":"Regulamento CNVW/Embracon — Cláusula 1.2","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":4,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"ed3f88a6-3b4a-54b2-9a9c-5632c8a95c7c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"A Cláusula 3.3, Parágrafo Segundo, estabelece que, a partir da contemplação, o CONSORCIADO deixa de ter o benefício de isenção da taxa de administração.","source_reference":"Regulamento CNVW/Embracon — Cláusula 3.3, Parágrafo Segundo, estabelece que, a partir da contemplação, o CONSORCIADO deixa de ter o benefício de isenção da taxa de administração","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":5,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"93aa34a5-e908-5ab7-8986-9b61295c47c3","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"A Cláusula 3.4 estabelece contribuição de 75% do percentual ideal ao fundo comum até a contemplação, ou seja, redução de 25%.","source_reference":"Regulamento CNVW/Embracon — Cláusula 3.4","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":6,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"41187937-0289-5fe3-9d41-5170173ebef6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"A Cláusula 3.4.1, Parágrafo Primeiro, prevê as opções I a IV (renegociar, pagar com recursos próprios, utilizar parte do crédito ou renegociar antecipadamente).","source_reference":"Regulamento CNVW/Embracon — Cláusula 3.4.1, Parágrafo Primeiro, prevê as opções I a IV (renegociar, pagar com recursos próprios, utilizar parte do crédito ou renegociar antecipadamente)","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":7,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"d32ef77b-7bb2-5384-9ab5-2326d782c27a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Conforme a Cláusula 3.5, expressamente.","source_reference":"Regulamento CNVW/Embracon — Cláusula 3.5, o consorciado que adere a um grupo já em andamento deve","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":8,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"c3071b53-094c-5c2b-8dc0-be1c3057767e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Texto literal da Cláusula 4ª.","source_reference":"Regulamento CNVW/Embracon — Cláusula 4ª","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":9,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"c6c4bbdb-6530-5620-8b6c-0a8b04520a4b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"A Cláusula 4.1.1 estabelece essa ordem de preferência (incisos I, II e III).","source_reference":"Regulamento CNVW/Embracon — Cláusula 4.1.1","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":10,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"89fc7104-f0a1-5907-b2ec-ece5315a7068","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Texto literal da Cláusula 6ª.","source_reference":"Regulamento CNVW/Embracon — Cláusula 6ª, um pagamento de contribuição feito por cheque somente será reconhecido se","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":11,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"38ff58c2-7a88-5bf4-a385-5991cd0df39a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Conforme a Cláusula 10, Parágrafo Segundo, a antecipação é deduzida do total contratado, não somada a ele.","source_reference":"Regulamento CNVW/Embracon — Cláusula 10, Parágrafo Segundo","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":12,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"6d816547-ce54-5217-904a-f95cb85bae54","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"A Cláusula 11, Parágrafo Quinto, fixa esse limite mínimo de 50% em relação ao crédito de maior valor do grupo.","source_reference":"Regulamento CNVW/Embracon — Cláusula 11, Parágrafo Quinto, em um grupo com créditos de valores diferenciados, o crédito de menor valor, na data da constituição do grupo, não pode ser inferior a que percentual do crédito de maior valor? A Cláusula 11, Parágrafo Quinto, fixa esse limite mínimo de 50% em relação ao crédito de maior valor do grupo","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":13,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"bd5c9a8d-3fbd-52b5-a1dc-0b4f63ef2683","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Conforme a Cláusula 11, Parágrafo Sétimo, o consorciado pode ter mais de uma cota, limitado a 10% do número máximo de cotas de consorciados ativos do grupo.","source_reference":"Regulamento CNVW/Embracon — Cláusula 11, Parágrafo Sétimo, qual é o percentual máximo permitido de cotas que um mesmo consorciado pode possuir em relação ao número máximo de cotas ativas do grupo? Conforme a Cláusula 11, Parágrafo Sétimo, o consorciado pode ter mais de uma cota, limitado a 10% do número máximo de cotas de consorciados ativos do grupo","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":14,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"e706aae6-5e18-5929-8a8e-94841b44a5e8","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"A Cláusula 12, alínea \"i\", fixa a taxa de cadastro/documentos de garantia em 1% do crédito vigente na data da contemplação.","source_reference":"Regulamento CNVW/Embracon — Cláusula 12, \"i\"), qual é o percentual cobrado sobre o valor do crédito vigente na data da contemplação? A Cláusula 12, alínea \"i\", fixa a taxa de cadastro/documentos de garantia em 1% do crédito vigente na data da contemplação","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":15,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"1eb12daa-7c0c-5f83-a728-8b8574c7f69b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Conforme o Parágrafo Único da Cláusula 13.","source_reference":"Regulamento CNVW/Embracon — Cláusula 13, são realizadas","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":16,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"9087c288-2dcc-56ce-a092-0868cdc7cec7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Texto literal da Cláusula 13.1, IV.","source_reference":"Regulamento CNVW/Embracon — Cláusula 13.1, inciso IV, ao aderir ao contrato, o CONSORCIADO outorga à ADMINISTRADORA","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":17,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"606549a5-5e2e-5043-a434-6ff6bb736647","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"Essa é matéria típica da Assembleia Geral ORDINÁRIA (Cláusula 13), e não da Extraordinária (Cláusula 14), cujo rol trata de temas estruturais do grupo (fusão, dissolução, substituição de administradora etc.).","source_reference":"Regulamento CNVW/Embracon — Cláusula 14","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":18,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"eefea76e-6785-5044-b188-b9da9ed67a85","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Conforme a Cláusula 16: *\"primeiramente será contemplada a cota por meio de sorteio aos ATIVOS, posteriormente será contemplada a cota aos EXCLUÍDOS (...) e em seguida serão contempladas as cotas por meio de lance\"*.","source_reference":"Regulamento CNVW/Embracon — Cláusula 16, a ordem de contemplação nas assembleias ordinárias é","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":19,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"4f2fffcd-aa65-5437-9ef9-28e17eeadae9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"Conforme a Cláusula 18, Parágrafo Primeiro, \"a\": 5 prêmios × 3 centenas cada = 15 centenas, para grupos de até 1.000 participantes.","source_reference":"Regulamento CNVW/Embracon — Cláusula 18, Parágrafo Primeiro, \"a\", quantas centenas são formadas a partir da extração da Loteria Federal para fins de sorteio? Conforme a Cláusula 18, Parágrafo Primeiro, \"a\"","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":20,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"3ce32820-51da-5355-b80d-b039f156a7cf","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Texto literal da Cláusula 17.","source_reference":"Regulamento CNVW/Embracon — Cláusula 17, somente pode participar do sorteio e concorrer aos lances o CONSORCIADO ATIVO que esteja","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":21,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"a946fff4-49f5-53f5-8e91-e9eae6a632ce","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Conforme a Cláusula 19, alínea \"a\".","source_reference":"Regulamento CNVW/Embracon — Cláusula 19, \"a\", o valor do lance ofertado não pode ser inferior a qual percentual do saldo devedor do consorciado licitante? Conforme a Cláusula 19, alínea \"a\"","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":22,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"f4a51cc5-b355-515c-a6d1-5b33c0ca2dce","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Conforme a Cláusula 18, Parágrafo Onze, a contemplação é cancelada após deixar de pagar 2 (duas) contribuições mensais, sucessivas ou alternadas.","source_reference":"Regulamento CNVW/Embracon — Cláusula 18, Parágrafo Onze), a contemplação do CONSORCIADO ATIVO que não utilizou o crédito será cancelada após deixar de pagar quantas contribuições mensais, sucessivas ou alternadas? Conforme a Cláusula 18, Parágrafo Onze, a contemplação é cancelada após deixar de pagar 2 (duas) contribuições mensais, sucessivas ou alternadas","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":23,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"627d64b4-af72-576e-a923-129debfd0648","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Conforme a Cláusula 21, caput.","source_reference":"Regulamento CNVW/Embracon — Cláusula 21, qual é o prazo improrrogável para cobertura (pagamento) do lance vencedor, contado da Assembleia Geral Ordinária de contemplação? Conforme a Cláusula 21, caput","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":24,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"c698698d-611e-5815-8b52-d8e22d6573e4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"Conforme a Cláusula 23, alínea \"b\".","source_reference":"Regulamento CNVW/Embracon — Cláusula 23, \"b\", a mudança do valor do crédito inicialmente contratado por outro dentro do mesmo grupo não pode ultrapassar qual diferença percentual (para maior ou para menor) em relação ao crédito atual? Conforme a Cláusula 23, alínea \"b\"","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":25,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"6dd5878b-78c4-5657-adf5-52a876c5f284","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"Conforme a Cláusula 32 (e também o \"Resumo das Condições Gerais\"): 180 (cento e oitenta) dias após a contemplação.","source_reference":"Regulamento CNVW/Embracon — Cláusula 32, é facultado ao CONSORCIADO contemplado que não utilizar o crédito receber o valor em espécie após quantos dias da contemplação, mediante quitação total das obrigações? Conforme a Cláusula 32 (e também o \"Resumo das Condições Gerais\")","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":26,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"2436a67a-e538-5a72-9a77-8035ec6ba110","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"Texto literal do Parágrafo Único da Cláusula 33.","source_reference":"Regulamento CNVW/Embracon — Cláusula 33","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":27,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"c57fb58d-70b5-5bce-bdca-d9823599a74f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Conforme a Cláusula 37, caput: \"taxa de transferência equivalente a 1% (um por cento) do valor do crédito\".","source_reference":"Regulamento CNVW/Embracon — Cláusula 37","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":28,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"7479f720-6e1b-515a-9269-2da008213178","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"D","justification":"Conforme a Cláusula 42, alínea \"d\": contribuição de mais de 50% ao fundo comum isenta o consorciado da multa compensatória.","source_reference":"Regulamento CNVW/Embracon — Cláusula 42","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":29,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"2635face-976d-5708-8695-9d4d320fed53","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"D","justification":"Texto literal da Cláusula 43.4.","source_reference":"Regulamento CNVW/Embracon — Cláusula 43.4, prescreve em quantos anos a pretensão do CONSORCIADO ATIVO e do CONSORCIADO EXCLUÍDO contra o Grupo de Consórcio e/ou contra a ADMINISTRADORA? Texto literal da Cláusula 43","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","assessment_code":"regulamento_vw_cnvw_v1","question_number":30,"source_content_sha256":"a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a","authoring_document_sha256":"a3ffb229db1b5ce7abce2dbe813f696de9d6d6dc1a75aa2b8c67ae9e832ada2f","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}}]$vw_keys$::jsonb) as x(
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
  source_reference, is_critical, critical_reason, reviewed_by,
  reviewed_at, metadata
)
select
  question_id, organization_id, correct_option_code, justification,
  source_reference, is_critical, critical_reason, null, null, metadata
from payload;

with payload as (
  select *
  from jsonb_to_recordset($vw_version_questions$[{"id":"88172b51-2b13-5841-8bcb-e5ee91fbdf7a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"9a04c130-e959-5f7c-ad41-e2e56cd912dc","sequence_no":1,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":1}},{"id":"1d03bdcf-6f4d-58f7-96b2-bbff33a50f82","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"2e6d2845-4e97-544f-8002-f0e506ad6b4a","sequence_no":2,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":2}},{"id":"9345e69a-2bf5-5bbf-8130-3226e716fcf6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"7e1c74b1-fe4e-589c-a378-42e2a7574953","sequence_no":3,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":3}},{"id":"f9cc3e5b-6556-5ee0-b0f9-c54d6fadbc08","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"80f58936-3218-5093-95e0-4f5911b0e8b5","sequence_no":4,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":4}},{"id":"0d79aaae-9fc3-5963-9e79-225d5f9ecc88","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"ed3f88a6-3b4a-54b2-9a9c-5632c8a95c7c","sequence_no":5,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":5}},{"id":"de643533-0f72-5888-a7c4-44f8befce29b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"93aa34a5-e908-5ab7-8986-9b61295c47c3","sequence_no":6,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":6}},{"id":"2b84d490-c498-516f-a550-85385fcf84b1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"41187937-0289-5fe3-9d41-5170173ebef6","sequence_no":7,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":7}},{"id":"27e4495a-5b11-544f-b962-4cab672411df","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"d32ef77b-7bb2-5384-9ab5-2326d782c27a","sequence_no":8,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":8}},{"id":"36fcb619-3571-5cdd-9659-253614cfaf19","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"c3071b53-094c-5c2b-8dc0-be1c3057767e","sequence_no":9,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":9}},{"id":"47805178-2b4a-5106-9733-e8d2c8b130b2","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"c6c4bbdb-6530-5620-8b6c-0a8b04520a4b","sequence_no":10,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":10}},{"id":"389b0d20-d156-51f6-9082-5b752d6a0ae1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"89fc7104-f0a1-5907-b2ec-ece5315a7068","sequence_no":11,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":11}},{"id":"5659817f-9df4-59c2-a96a-ba33c865bc35","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"38ff58c2-7a88-5bf4-a385-5991cd0df39a","sequence_no":12,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":12}},{"id":"bcf11dd1-4556-57f0-97df-987de6bcc50b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"6d816547-ce54-5217-904a-f95cb85bae54","sequence_no":13,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":13}},{"id":"62e2d5ad-d179-5b54-bb48-cf5455f1a718","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"bd5c9a8d-3fbd-52b5-a1dc-0b4f63ef2683","sequence_no":14,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":14}},{"id":"95c39761-ce7a-5c59-b64b-c22973717a48","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"e706aae6-5e18-5929-8a8e-94841b44a5e8","sequence_no":15,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":15}},{"id":"28d9c514-89c4-58be-b5f7-61788a81ab16","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"1eb12daa-7c0c-5f83-a728-8b8574c7f69b","sequence_no":16,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":16}},{"id":"bad2b48e-d464-5378-8e1c-db4a7a1aa1d2","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"9087c288-2dcc-56ce-a092-0868cdc7cec7","sequence_no":17,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":17}},{"id":"8f2f46ec-8482-599b-9cbf-e4a183033d5b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"606549a5-5e2e-5043-a434-6ff6bb736647","sequence_no":18,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":18}},{"id":"32298b1f-e513-54fc-8a88-dfa3da57cd5b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"eefea76e-6785-5044-b188-b9da9ed67a85","sequence_no":19,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":19}},{"id":"56095a28-93ef-5af6-90ad-89b2df0e0a90","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"4f2fffcd-aa65-5437-9ef9-28e17eeadae9","sequence_no":20,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":20}},{"id":"965c7fa4-c695-50cc-8187-cc80068c7e38","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"3ce32820-51da-5355-b80d-b039f156a7cf","sequence_no":21,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":21}},{"id":"d8506412-7a3d-5d54-b5a3-402e913dec11","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"a946fff4-49f5-53f5-8e91-e9eae6a632ce","sequence_no":22,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":22}},{"id":"2bd3eb58-b122-5e62-a55f-7a5e4e9a9c9b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"f4a51cc5-b355-515c-a6d1-5b33c0ca2dce","sequence_no":23,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":23}},{"id":"16dd16ba-5ea9-54af-b864-b435a5ec4921","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"627d64b4-af72-576e-a923-129debfd0648","sequence_no":24,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":24}},{"id":"db3152ce-ac66-5bf9-886b-d2854dc3e31b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"c698698d-611e-5815-8b52-d8e22d6573e4","sequence_no":25,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":25}},{"id":"5923ac16-1b03-5c9f-84a4-419f92af2456","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"6dd5878b-78c4-5657-adf5-52a876c5f284","sequence_no":26,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":26}},{"id":"c3f77564-dc47-5e9b-998a-984b9b4e93c7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"2436a67a-e538-5a72-9a77-8035ec6ba110","sequence_no":27,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":27}},{"id":"ec6abbc1-f47a-5375-8bbd-d177d91e3e4c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"c57fb58d-70b5-5bce-bdca-d9823599a74f","sequence_no":28,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":28}},{"id":"28307b23-d9fc-5482-b892-38acd3148422","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"7479f720-6e1b-515a-9269-2da008213178","sequence_no":29,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":29}},{"id":"04b3d76d-a410-5c78-ba11-417698bad002","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"fcf8f979-c44e-5993-beef-d023312ab5b7","question_id":"2635face-976d-5708-8695-9d4d320fed53","sequence_no":30,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","administrator":"CNVW","question_number":30}}]$vw_version_questions$::jsonb) as x(
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

-- --------------------------------------------------------------------------
-- 5. Pós-condições fail-closed
-- --------------------------------------------------------------------------
do $post$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
  v_test_id uuid := 'dd671e5f-39ec-5018-9263-78613361a7db'::uuid;
  v_version_id uuid := 'fcf8f979-c44e-5993-beef-d023312ab5b7'::uuid;
begin
  if not exists (
    select 1
    from public.source_materials sm
    join public.source_material_versions smv
      on smv.source_material_id = sm.id
     and smv.organization_id = sm.organization_id
     and smv.archived_at is null
    where sm.id = '89fb9a5e-d493-5280-814d-abc03eaa05c9'::uuid
      and sm.organization_id = v_org_id
      and sm.code = 'regulamento_cnvw_embracon_v2_1'
      and sm.material_type = 'regulation'
      and sm.status = 'active'
      and sm.archived_at is null
      and smv.id = '2bffe092-f163-53c5-846d-284567e62595'::uuid
      and smv.version_code = 'v2.1-circular3432-res285-23'
      and smv.status = 'active'
      and lower(smv.content_sha256) = 'a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a'
  ) then
    raise exception 'Regulamento VW pós-condição: fonte normativa/versionamento não confere.';
  end if;

  if (
    select count(*)
    from public.competency_domains c
    where c.organization_id = v_org_id
      and c.sequence_no between 43 and 50
      and c.status = 'draft'
      and c.is_legal = true
      and c.archived_at is null
  ) <> 8 then
    raise exception 'Regulamento VW pós-condição: esperado 8 competências legais em draft.';
  end if;

  if not exists (
    select 1
    from public.assessment_tests t
    where t.id = v_test_id
      and t.organization_id = v_org_id
      and t.code = 'regulamento_vw_cnvw_v1'
      and t.sequence_no = 11
      and t.question_count = 30
      and t.status = 'draft'
      and t.archived_at is null
  ) then
    raise exception 'Regulamento VW pós-condição: identidade do teste não confere.';
  end if;

  if not exists (
    select 1
    from public.assessment_test_versions tv
    where tv.id = v_version_id
      and tv.organization_id = v_org_id
      and tv.test_id = v_test_id
      and tv.version_code = 'cnvw-v2.1-v1'
      and tv.version_no = 1
      and tv.status = 'draft'
      and tv.passing_score = 100
      and tv.legal_min_score = 100
      and tv.question_count = 30
      and tv.randomize_questions = true
      and tv.randomize_options = true
      and tv.show_review_after_submit = false
      and tv.published_at is null
      and tv.archived_at is null
  ) then
    raise exception 'Regulamento VW pós-condição: versão draft/fail-closed não confere.';
  end if;

  if (
    select count(*)
    from public.assessment_questions q
    where q.organization_id = v_org_id
      and q.code like 'reg_vw_cnvw_q%'
      and q.status = 'draft'
      and q.archived_at is null
  ) <> 30 then
    raise exception 'Regulamento VW pós-condição: esperado 30 questões em draft.';
  end if;

  if (
    select count(*)
    from public.assessment_version_questions avq
    where avq.organization_id = v_org_id
      and avq.test_version_id = v_version_id
      and avq.is_required = true
      and avq.archived_at is null
  ) <> 30 then
    raise exception 'Regulamento VW pós-condição: esperado 30 vínculos obrigatórios.';
  end if;

  if (
    select count(distinct avq.question_id)
    from public.assessment_version_questions avq
    where avq.organization_id = v_org_id
      and avq.test_version_id = v_version_id
      and avq.archived_at is null
  ) <> 30
  or (
    select count(distinct avq.sequence_no)
    from public.assessment_version_questions avq
    where avq.organization_id = v_org_id
      and avq.test_version_id = v_version_id
      and avq.archived_at is null
  ) <> 30
  or (
    select min(avq.sequence_no)
    from public.assessment_version_questions avq
    where avq.organization_id = v_org_id
      and avq.test_version_id = v_version_id
      and avq.archived_at is null
  ) <> 1
  or (
    select max(avq.sequence_no)
    from public.assessment_version_questions avq
    where avq.organization_id = v_org_id
      and avq.test_version_id = v_version_id
      and avq.archived_at is null
  ) <> 30 then
    raise exception 'Regulamento VW pós-condição: questões/sequência da versão não conferem.';
  end if;

  if (
    select count(*)
    from public.assessment_question_options o
    join public.assessment_version_questions avq
      on avq.question_id = o.question_id
     and avq.organization_id = o.organization_id
    where avq.organization_id = v_org_id
      and avq.test_version_id = v_version_id
      and avq.archived_at is null
      and o.archived_at is null
  ) <> 120 then
    raise exception 'Regulamento VW pós-condição: esperado 120 alternativas.';
  end if;

  if (
    select count(*)
    from private.assessment_question_keys k
    join public.assessment_version_questions avq
      on avq.question_id = k.question_id
     and avq.organization_id = k.organization_id
    where avq.organization_id = v_org_id
      and avq.test_version_id = v_version_id
      and avq.archived_at is null
  ) <> 30 then
    raise exception 'Regulamento VW pós-condição: esperado 30 gabaritos privados.';
  end if;

  if exists (
    select 1
    from private.assessment_question_keys k
    join public.assessment_version_questions avq
      on avq.question_id = k.question_id
     and avq.organization_id = k.organization_id
    where avq.organization_id = v_org_id
      and avq.test_version_id = v_version_id
      and avq.archived_at is null
      and k.is_critical = true
  ) then
    raise exception 'Regulamento VW pós-condição: criticidade criada sem declaração da fonte de autoria.';
  end if;

  if exists (
    select 1
    from (
      select q.id, count(o.id) as option_count
      from public.assessment_version_questions avq
      join public.assessment_questions q
        on q.id = avq.question_id
       and q.organization_id = avq.organization_id
      left join public.assessment_question_options o
        on o.question_id = q.id
       and o.organization_id = q.organization_id
       and o.archived_at is null
      where avq.organization_id = v_org_id
        and avq.test_version_id = v_version_id
        and avq.archived_at is null
        and q.archived_at is null
      group by q.id
    ) x
    where x.option_count <> 4
  ) then
    raise exception 'Regulamento VW pós-condição: alguma questão não possui exatamente 4 alternativas.';
  end if;

  if exists (
    select 1
    from private.assessment_question_keys k
    join public.assessment_version_questions avq
      on avq.question_id = k.question_id
     and avq.organization_id = k.organization_id
    left join public.assessment_question_options o
      on o.question_id = k.question_id
     and o.organization_id = k.organization_id
     and o.option_code = k.correct_option_code
     and o.archived_at is null
    where avq.organization_id = v_org_id
      and avq.test_version_id = v_version_id
      and avq.archived_at is null
      and o.id is null
  ) then
    raise exception 'Regulamento VW pós-condição: existe gabarito sem alternativa correspondente.';
  end if;

  if (
    select count(*)
    from public.assessment_questions q
    join public.assessment_version_questions avq
      on avq.question_id = q.id
     and avq.organization_id = q.organization_id
    where avq.organization_id = v_org_id
      and avq.test_version_id = v_version_id
      and avq.archived_at is null
      and q.archived_at is null
      and q.block_code = 'definicoes_adesao'
  ) <> 4 then
    raise exception 'Regulamento VW pós-condição: distribuição do bloco definicoes_adesao não confere.';
  end if;

  if (
    select count(*)
    from public.assessment_questions q
    join public.assessment_version_questions avq
      on avq.question_id = q.id
     and avq.organization_id = q.organization_id
    where avq.organization_id = v_org_id
      and avq.test_version_id = v_version_id
      and avq.archived_at is null
      and q.archived_at is null
      and q.block_code = 'planos'
  ) <> 3 then
    raise exception 'Regulamento VW pós-condição: distribuição do bloco planos não confere.';
  end if;

  if (
    select count(*)
    from public.assessment_questions q
    join public.assessment_version_questions avq
      on avq.question_id = q.id
     and avq.organization_id = q.organization_id
    where avq.organization_id = v_org_id
      and avq.test_version_id = v_version_id
      and avq.archived_at is null
      and q.archived_at is null
      and q.block_code = 'contribuicoes_taxas'
  ) <> 5 then
    raise exception 'Regulamento VW pós-condição: distribuição do bloco contribuicoes_taxas não confere.';
  end if;

  if (
    select count(*)
    from public.assessment_questions q
    join public.assessment_version_questions avq
      on avq.question_id = q.id
     and avq.organization_id = q.organization_id
    where avq.organization_id = v_org_id
      and avq.test_version_id = v_version_id
      and avq.archived_at is null
      and q.archived_at is null
      and q.block_code = 'constituicao_grupo'
  ) <> 3 then
    raise exception 'Regulamento VW pós-condição: distribuição do bloco constituicao_grupo não confere.';
  end if;

  if (
    select count(*)
    from public.assessment_questions q
    join public.assessment_version_questions avq
      on avq.question_id = q.id
     and avq.organization_id = q.organization_id
    where avq.organization_id = v_org_id
      and avq.test_version_id = v_version_id
      and avq.archived_at is null
      and q.archived_at is null
      and q.block_code = 'assembleias'
  ) <> 3 then
    raise exception 'Regulamento VW pós-condição: distribuição do bloco assembleias não confere.';
  end if;

  if (
    select count(*)
    from public.assessment_questions q
    join public.assessment_version_questions avq
      on avq.question_id = q.id
     and avq.organization_id = q.organization_id
    where avq.organization_id = v_org_id
      and avq.test_version_id = v_version_id
      and avq.archived_at is null
      and q.archived_at is null
      and q.block_code = 'contemplacao_lances'
  ) <> 7 then
    raise exception 'Regulamento VW pós-condição: distribuição do bloco contemplacao_lances não confere.';
  end if;

  if (
    select count(*)
    from public.assessment_questions q
    join public.assessment_version_questions avq
      on avq.question_id = q.id
     and avq.organization_id = q.organization_id
    where avq.organization_id = v_org_id
      and avq.test_version_id = v_version_id
      and avq.archived_at is null
      and q.archived_at is null
      and q.block_code = 'credito_garantias'
  ) <> 2 then
    raise exception 'Regulamento VW pós-condição: distribuição do bloco credito_garantias não confere.';
  end if;

  if (
    select count(*)
    from public.assessment_questions q
    join public.assessment_version_questions avq
      on avq.question_id = q.id
     and avq.organization_id = q.organization_id
    where avq.organization_id = v_org_id
      and avq.test_version_id = v_version_id
      and avq.archived_at is null
      and q.archived_at is null
      and q.block_code = 'cessao_exclusao_prescricao'
  ) <> 3 then
    raise exception 'Regulamento VW pós-condição: distribuição do bloco cessao_exclusao_prescricao não confere.';
  end if;

  if (
    select count(*)
    from public.assessment_version_sources avs
    where avs.organization_id = v_org_id
      and avs.test_version_id = v_version_id
      and avs.source_material_version_id = '2bffe092-f163-53c5-846d-284567e62595'::uuid
      and avs.relation_type = 'primary'
      and avs.is_required = true
      and avs.archived_at is null
  ) <> 1 then
    raise exception 'Regulamento VW pós-condição: vínculo com fonte normativa primária não confere.';
  end if;

  if exists (
    select 1
    from private.assessment_test_access_grants g
    where g.organization_id = v_org_id
      and g.test_id = v_test_id
      and g.archived_at is null
  ) then
    raise exception 'Regulamento VW pós-condição: nenhum grant deveria ter sido criado.';
  end if;

  if exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.test_id = v_test_id
      and a.archived_at is null
  ) then
    raise exception 'Regulamento VW pós-condição: nenhuma tentativa deveria existir.';
  end if;

  if (
    select count(*)
    from public.assessment_tests t
    where t.organization_id = v_org_id
      and t.sequence_no between 1 and 11
      and t.archived_at is null
  ) <> 11 then
    raise exception 'Regulamento VW pós-condição: catálogo 1..11 não está íntegro.';
  end if;
end
$post$;

commit;
