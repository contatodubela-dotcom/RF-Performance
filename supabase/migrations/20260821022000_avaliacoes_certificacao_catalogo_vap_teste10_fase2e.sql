-- ============================================================================
-- RF Performance — Avaliações e Certificações
-- Catálogo Ampliado — Método VAP — Teste 10
-- Fase 2E — cadastro em RASCUNHO para homologação controlada
--
-- Teste 10:
--   IA em Vendas e Venda Persuasiva
--   Declaração editorial: 15 questões de IA em Vendas + 15 de Persuasão Ética,
--   comunicação não-verbal, storytelling e fechamento avançado.
--   Mapeamento semântico efetivo:
--     15 IA em Vendas + 14 Persuasão Ética + 1 Integração VAP.
--
-- Fonte primária já cadastrada na Fase 2A:
--   O Método VAP — Vendedor de Alta Performance
--   SHA-256: d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84
--
-- Documento de autoria das questões:
--   Sistema de Certificação Comercial — Método VAP — Testes 6 a 10
--   SHA-256: 8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820
--
-- SEGURANÇA / ESCOPO
--   - Não altera Testes 1 a 9.
--   - Não recria a fonte Método VAP.
--   - Cria apenas 2 novas competências e reutiliza vap_integracao na Q30.
--   - Não cria grant de acesso.
--   - Não publica o Teste 10.
--   - Não cria tentativa.
--   - Gabarito permanece em private.assessment_question_keys.
--   - Corte 100/100 propositalmente fail-closed até definição da política.
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
    raise exception 'VAP Teste 10 abortado: organização RF esperada não localizada/ativa.';
  end if;

  if (
    select count(*)
    from public.assessment_tests t
    where t.organization_id = v_org_id
      and t.archived_at is null
      and t.sequence_no between 1 and 9
  ) <> 9 then
    raise exception 'VAP Teste 10 abortado: catálogo-base Testes 1 a 9 não está íntegro.';
  end if;

  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions tv
      on tv.test_id = t.id
     and tv.organization_id = t.organization_id
     and tv.archived_at is null
    where t.organization_id = v_org_id
      and t.sequence_no = 9
      and t.code = 'teste_9_vap_etapas_venda_objecoes'
      and t.status = 'draft'
      and tv.version_code = '2026.08-v1'
      and tv.status = 'draft'
      and t.archived_at is null
  ) then
    raise exception 'VAP Teste 10 abortado: Teste 9 VAP esperado não está presente em draft.';
  end if;

  if not exists (
    select 1
    from public.source_material_versions smv
    join public.source_materials sm
      on sm.id = smv.source_material_id
     and sm.organization_id = smv.organization_id
    where sm.id = '2831b27b-035b-54fd-a3cc-d8a23a509a82'::uuid
      and smv.id = 'a20ad8ff-b3f8-5106-b96e-346fa342d098'::uuid
      and sm.organization_id = v_org_id
      and sm.code = 'metodo_vap_vendedor_alta_performance'
      and sm.material_type = 'book'
      and sm.status = 'active'
      and smv.version_code = '1a-edicao-2024'
      and smv.status = 'active'
      and lower(smv.content_sha256) = 'd28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84'
      and sm.archived_at is null
      and smv.archived_at is null
  ) then
    raise exception 'VAP Teste 10 abortado: fonte Método VAP/versionamento esperado não confere.';
  end if;

  if not exists (
    select 1
    from public.competency_domains c
    where c.id = '43ab5826-1867-50ec-9c1d-2d0b8f5f5fe0'::uuid
      and c.organization_id = v_org_id
      and c.code = 'vap_integracao'
      and c.archived_at is null
  ) then
    raise exception 'VAP Teste 10 abortado: competência vap_integracao esperada não existe.';
  end if;

  if exists (
    select 1
    from public.assessment_tests t
    where t.organization_id = v_org_id
      and t.archived_at is null
      and (
        t.sequence_no = 10
        or t.code = 'teste_10_vap_ia_vendas_persuasao'
        or t.id = 'c2933dbe-62c7-57f8-9b87-3db4d194bde0'::uuid
      )
  ) then
    raise exception 'VAP Teste 10 abortado: já existe teste ocupando a identidade/seq. 10.';
  end if;

  if exists (
    select 1
    from public.competency_domains c
    where c.organization_id = v_org_id
      and c.archived_at is null
      and (
        c.sequence_no between 41 and 42
        or c.code in ('vap_ia_vendas','vap_persuasao_etica')
        or c.id in (
          '2e08262a-4b2f-5cce-9376-ee2dfca94966'::uuid,
          '6e3e68d0-d429-5503-997a-199980de270c'::uuid
        )
      )
  ) then
    raise exception 'VAP Teste 10 abortado: identidade/sequência das novas competências já está ocupada.';
  end if;
end
$guard$;

with payload as (
  select *
  from jsonb_to_recordset($vap_competencies$[{"id":"2e08262a-4b2f-5cce-9376-ee2dfca94966","code":"vap_ia_vendas","sequence_no":41,"name":"VAP — IA em Vendas","description":"Uso de inteligência artificial, CRM inteligente, automação, chatbots, personalização e métricas no processo comercial VAP.","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","domain_type":"knowledge","is_legal":false,"default_weight":0,"status":"draft","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"draft_catalog"}},{"id":"6e3e68d0-d429-5503-997a-199980de270c","code":"vap_persuasao_etica","sequence_no":42,"name":"VAP — Persuasão Ética e Venda Avançada","description":"Persuasão ética, comunicação não-verbal, storytelling, fechamento avançado e follow-up estruturado no Método VAP.","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","domain_type":"knowledge","is_legal":false,"default_weight":0,"status":"draft","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"draft_catalog"}}]$vap_competencies$::jsonb) as x(
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

insert into public.assessment_tests (
  id, organization_id, code, sequence_no, title, description, difficulty,
  purpose, target_level_id, question_count, time_limit_minutes,
  max_attempts, cooldown_hours, status, metadata
)
values (
  'c2933dbe-62c7-57f8-9b87-3db4d194bde0'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'teste_10_vap_ia_vendas_persuasao',
  10,
  'Teste 10 — IA em Vendas e Venda Persuasiva',
  'Avaliação avançada e integrativa do Método VAP sobre IA aplicada a vendas, persuasão ética, presença, storytelling, fechamento e follow-up.',
  'advanced',
  'certification',
  null,
  30,
  null,
  2,
  24,
  'draft',
  jsonb_build_object(
    'catalog_family', 'vap',
    'catalog_version', '2026.08-v1',
    'source_level_label', 'Avançado / Integração',
    'source_material_code', 'metodo_vap_vendedor_alta_performance',
    'source_content_sha256', 'd28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84',
    'authoring_document', 'Sistema de Certificação Comercial — Método VAP — Testes 6 a 10',
    'authoring_document_sha256', '8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820',
    'authoring_document_date_label', 'Agosto de 2026',
    'declared_distribution', jsonb_build_object(
      'ia_vendas', 15,
      'persuasao_etica_comunicacao_storytelling_fechamento', 15
    ),
    'semantic_distribution', jsonb_build_object(
      'ia_vendas', 15,
      'persuasao_etica', 14,
      'integracao_vap', 1
    ),
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
  '867c9840-67c2-5424-a79a-e847886938b2'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'c2933dbe-62c7-57f8-9b87-3db4d194bde0'::uuid,
  '2026.08-v1',
  1,
  'draft',
  100,
  100,
  30,
  true,
  true,
  true,
  null,
  null,
  null,
  '[]'::jsonb,
  jsonb_build_object(
    'catalog_family', 'vap',
    'catalog_version', '2026.08-v1',
    'source_content_sha256', 'd28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84',
    'authoring_document_sha256', '8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820',
    'approval_policy_defined', false,
    'approval_threshold_placeholder', 100,
    'approval_threshold_strategy', 'fail_closed_until_publication',
    'has_legal_questions', false,
    'homologation_status', 'draft_catalog'
  )
);

insert into public.assessment_version_sources (
  id, organization_id, test_version_id, source_material_version_id,
  relation_type, is_required, notes, metadata
)
values (
  '514f0b35-200a-528a-a168-8697dd78d612'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '867c9840-67c2-5424-a79a-e847886938b2'::uuid,
  'a20ad8ff-b3f8-5106-b96e-346fa342d098'::uuid,
  'primary',
  true,
  'Fonte primária dos conteúdos avaliados no Teste 10 do Método VAP.',
  jsonb_build_object(
    'catalog_family', 'vap',
    'test_number', 10,
    'source_content_sha256', 'd28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84'
  )
);

with payload as (
  select *
  from jsonb_to_recordset($vap_questions$[{"id":"9ffe2f4e-a840-507e-a1d0-adbf68c23deb","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q01","competency_id":"2e08262a-4b2f-5cce-9376-ee2dfca94966","block_code":"ia_vendas","prompt":"Qual é a premissa central do Módulo 10 sobre o papel da IA em vendas?","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":1,"source_label":"IA em Vendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"c0c44efd-edee-5efa-a8c8-ed77e7e7bf69","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q02","competency_id":"2e08262a-4b2f-5cce-9376-ee2dfca94966","block_code":"ia_vendas","prompt":"Qual conjunto corresponde a categorias de ferramentas de IA citadas no VAP?","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":2,"source_label":"IA em Vendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"d37a9fe8-00de-5441-b448-a3e0090af2de","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q03","competency_id":"2e08262a-4b2f-5cce-9376-ee2dfca94966","block_code":"ia_vendas","prompt":"Qual é um uso típico de CRM inteligente descrito no material?","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":3,"source_label":"IA em Vendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"67782952-7920-5032-8035-4fe34a97b198","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q04","competency_id":"2e08262a-4b2f-5cce-9376-ee2dfca94966","block_code":"ia_vendas","prompt":"Ferramentas de análise de chamadas são usadas principalmente para:","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":4,"source_label":"IA em Vendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"741b0774-4bc5-5239-9d30-2c08e6696c8f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q05","competency_id":"2e08262a-4b2f-5cce-9376-ee2dfca94966","block_code":"ia_vendas","prompt":"Quais são os quatro níveis de personalização em escala citados no VAP?","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":5,"source_label":"IA em Vendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"c25716a3-e9c6-5891-bc87-535446beebcd","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q06","competency_id":"2e08262a-4b2f-5cce-9376-ee2dfca94966","block_code":"ia_vendas","prompt":"Qual exemplo representa personalização no nível “cargo”?","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":6,"source_label":"IA em Vendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"b2263f01-b48d-5114-acab-0cfae6aeab54","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q07","competency_id":"2e08262a-4b2f-5cce-9376-ee2dfca94966","block_code":"ia_vendas","prompt":"Quais são os quatro tipos de chatbot destacados no VAP?","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":7,"source_label":"IA em Vendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"5535b05f-8fe7-5e45-a518-dfd869602022","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q08","competency_id":"2e08262a-4b2f-5cce-9376-ee2dfca94966","block_code":"ia_vendas","prompt":"Qual é a melhor função de um chatbot de qualificação?","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":8,"source_label":"IA em Vendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"50c7572c-18f5-5adc-b610-e84d383189da","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q09","competency_id":"2e08262a-4b2f-5cce-9376-ee2dfca94966","block_code":"ia_vendas","prompt":"No roadmap de IA do VAP, qual é a prioridade dos primeiros 30 dias?","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":9,"source_label":"IA em Vendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"644fba9d-821f-5db9-8e77-302f479ff0df","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q10","competency_id":"2e08262a-4b2f-5cce-9376-ee2dfca94966","block_code":"ia_vendas","prompt":"Na fase de 60 dias do roadmap de IA, o material recomenda:","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":10,"source_label":"IA em Vendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"9735cfed-0fc6-5716-bb4a-517c39def408","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q11","competency_id":"2e08262a-4b2f-5cce-9376-ee2dfca94966","block_code":"ia_vendas","prompt":"Na fase de 90 dias do roadmap, a prioridade é:","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":11,"source_label":"IA em Vendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"162200e2-a2a9-5671-9d32-08babce30d52","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q12","competency_id":"2e08262a-4b2f-5cce-9376-ee2dfca94966","block_code":"ia_vendas","prompt":"Na maturidade de 180 dias, qual resultado é projetado pelo material?","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":12,"source_label":"IA em Vendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"8687f5ce-cc44-5c63-bd70-2bff2154ff49","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q13","competency_id":"2e08262a-4b2f-5cce-9376-ee2dfca94966","block_code":"ia_vendas","prompt":"Qual princípio deve orientar a escolha do stack de IA?","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":13,"source_label":"IA em Vendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"93690214-edcc-5044-8bdd-aff561cb6b41","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q14","competency_id":"2e08262a-4b2f-5cce-9376-ee2dfca94966","block_code":"ia_vendas","prompt":"Qual atividade o VAP considera especialmente humana mesmo em uma operação muito automatizada?","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":14,"source_label":"IA em Vendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"1feb61f3-dcc2-5050-88fa-ea652914f1ba","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q15","competency_id":"2e08262a-4b2f-5cce-9376-ee2dfca94966","block_code":"ia_vendas","prompt":"Uma empresa implementa IA, mas não mede produtividade nem conversão. Qual etapa do VAP está faltando?","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":15,"source_label":"IA em Vendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"f3444701-766d-5599-ad6d-afddef7757db","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q16","competency_id":"6e3e68d0-d429-5503-997a-199980de270c","block_code":"persuasao_etica","prompt":"No Módulo Extra, o que diferencia persuasão ética de manipulação?","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":16,"source_label":"Venda Persuasiva","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"80e56486-90d5-5d14-9744-ddd9e62b2536","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q17","competency_id":"6e3e68d0-d429-5503-997a-199980de270c","block_code":"persuasao_etica","prompt":"Quais seis princípios de persuasão são destacados no Módulo Extra?","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":17,"source_label":"Venda Persuasiva","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"a1c6f773-18d2-542f-a4b4-12bb134a5be2","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q18","competency_id":"6e3e68d0-d429-5503-997a-199980de270c","block_code":"persuasao_etica","prompt":"Qual exemplo representa reciprocidade de forma ética?","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":18,"source_label":"Venda Persuasiva","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"04b7cc3b-92b1-5e21-b118-373b883326f6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q19","competency_id":"6e3e68d0-d429-5503-997a-199980de270c","block_code":"persuasao_etica","prompt":"O princípio do Compromisso é aplicado de forma adequada quando o vendedor:","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":19,"source_label":"Venda Persuasiva","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"ae6b3ee3-30a1-57ac-acbc-7a91d7a4b975","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q20","competency_id":"6e3e68d0-d429-5503-997a-199980de270c","block_code":"persuasao_etica","prompt":"Como usar Autoridade sem cair em arrogância?","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":20,"source_label":"Venda Persuasiva","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"fc75bddd-167c-5415-8e3f-e9bc575a661e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q21","competency_id":"6e3e68d0-d429-5503-997a-199980de270c","block_code":"persuasao_etica","prompt":"Segundo o material, a comunicação não-verbal envolve especialmente:","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":21,"source_label":"Venda Persuasiva","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"7cac66f0-2da5-59df-b42f-0f344e549646","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q22","competency_id":"6e3e68d0-d429-5503-997a-199980de270c","block_code":"persuasao_etica","prompt":"Na regra 7-38-55 apresentada no VAP, o maior peso didático é atribuído a:","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":22,"source_label":"Venda Persuasiva","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"50f244eb-5e2f-5f00-9fc5-5b813b49e53c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q23","competency_id":"6e3e68d0-d429-5503-997a-199980de270c","block_code":"persuasao_etica","prompt":"Qual é a sequência de storytelling ensinada no resumo do Módulo Extra?","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":23,"source_label":"Venda Persuasiva","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"5db3a65d-cdf5-534a-83df-2ef6b8c98cd4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q24","competency_id":"6e3e68d0-d429-5503-997a-199980de270c","block_code":"persuasao_etica","prompt":"Quais são os três tipos de histórias sugeridos no Módulo Extra?","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":24,"source_label":"Venda Persuasiva","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"a78f17db-d823-566e-af8b-5025c7a2904f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q25","competency_id":"6e3e68d0-d429-5503-997a-199980de270c","block_code":"persuasao_etica","prompt":"Qual é uma técnica de fechamento avançado citada no VAP?","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":25,"source_label":"Venda Persuasiva","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"4b5ff332-29cf-56db-a495-e0cd7744cabd","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q26","competency_id":"6e3e68d0-d429-5503-997a-199980de270c","block_code":"persuasao_etica","prompt":"No fechamento por Alternativas, o vendedor deve:","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":26,"source_label":"Venda Persuasiva","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"b68744a2-bdb9-55f0-9c57-a0d540a33339","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q27","competency_id":"6e3e68d0-d429-5503-997a-199980de270c","block_code":"persuasao_etica","prompt":"Quando a técnica de Escassez é eticamente aceitável?","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":27,"source_label":"Venda Persuasiva","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"89e10146-4c42-5f59-8a95-1b479b0848e3","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q28","competency_id":"6e3e68d0-d429-5503-997a-199980de270c","block_code":"persuasao_etica","prompt":"Qual é a finalidade do Calendário de Follow-up bônus do Método VAP?","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":28,"source_label":"Venda Persuasiva","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"77b82f94-4f16-5d61-8335-f3f10d9bd92e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q29","competency_id":"6e3e68d0-d429-5503-997a-199980de270c","block_code":"persuasao_etica","prompt":"Para que serve o Checklist de Presença bônus?","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":29,"source_label":"Venda Persuasiva","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"03dd8c11-9d73-5abe-95a4-729835aae122","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t10_q30","competency_id":"43ab5826-1867-50ec-9c1d-2d0b8f5f5fe0","block_code":"integracao_vap","prompt":"Qual cenário representa a aplicação mais completa do VAP em nível avançado?","question_type":"single_choice","difficulty":"advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":30,"source_label":"Integração VAP","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}}]$vap_questions$::jsonb) as x(
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
  from jsonb_to_recordset($vap_options$[{"id":"9eef64f0-e3fe-5f3d-b097-629e3eed63c5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9ffe2f4e-a840-507e-a1d0-adbf68c23deb","option_code":"A","option_text":"A IA potencializa um processo comercial bem estruturado, mas não substitui as competências humanas de relacionamento e negociação complexa.","metadata":{"catalog_family":"vap","test_number":10,"question_number":1}},{"id":"810c5719-5d92-5e6f-a110-7fdafe84122e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9ffe2f4e-a840-507e-a1d0-adbf68c23deb","option_code":"B","option_text":"O principal uso da IA é reduzir o contato com clientes ao mínimo possível.","metadata":{"catalog_family":"vap","test_number":10,"question_number":1}},{"id":"c9ce54b5-6388-5d39-932c-d3eed9d18563","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9ffe2f4e-a840-507e-a1d0-adbf68c23deb","option_code":"C","option_text":"A IA elimina a necessidade de método, treinamento e processo.","metadata":{"catalog_family":"vap","test_number":10,"question_number":1}},{"id":"f97d16de-e31c-5061-a0c3-322a24be0abd","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9ffe2f4e-a840-507e-a1d0-adbf68c23deb","option_code":"D","option_text":"Toda negociação deve ser conduzida por chatbot sem supervisão.","metadata":{"catalog_family":"vap","test_number":10,"question_number":1}},{"id":"c8d1c205-b8ee-5e49-b5c2-4eda6fd5f54f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c0c44efd-edee-5efa-a8c8-ed77e7e7bf69","option_code":"A","option_text":"Recrutamento, jurídico e cobrança exclusivamente.","metadata":{"catalog_family":"vap","test_number":10,"question_number":2}},{"id":"14087dca-6c3f-5e46-aaa5-f4209bc36e3f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c0c44efd-edee-5efa-a8c8-ed77e7e7bf69","option_code":"B","option_text":"Folha de pagamento, contabilidade, estoque e logística apenas.","metadata":{"catalog_family":"vap","test_number":10,"question_number":2}},{"id":"3d4f7a27-6c2f-5417-8028-387336f5918b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c0c44efd-edee-5efa-a8c8-ed77e7e7bf69","option_code":"C","option_text":"Design gráfico, manutenção predial e segurança física apenas.","metadata":{"catalog_family":"vap","test_number":10,"question_number":2}},{"id":"c00ad8f3-3937-5f4d-955e-6a500143626e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c0c44efd-edee-5efa-a8c8-ed77e7e7bf69","option_code":"D","option_text":"CRM inteligente, prospecção, análise de chamadas, conteúdo, automação e atendimento.","metadata":{"catalog_family":"vap","test_number":10,"question_number":2}},{"id":"1af505ed-8ad1-57ef-b905-e47042fb61a5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d37a9fe8-00de-5441-b448-a3e0090af2de","option_code":"A","option_text":"Excluir leads automaticamente sem critérios.","metadata":{"catalog_family":"vap","test_number":10,"question_number":3}},{"id":"1d649103-9fe2-5b99-baf3-4dac4bad03b5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d37a9fe8-00de-5441-b448-a3e0090af2de","option_code":"B","option_text":"Criar promessas comerciais sem validação humana.","metadata":{"catalog_family":"vap","test_number":10,"question_number":3}},{"id":"7e5c99a6-d2f5-53f8-b862-62f8997fab4e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d37a9fe8-00de-5441-b448-a3e0090af2de","option_code":"C","option_text":"Priorizar leads, sugerir próximas ações e apoiar previsão de fechamento com base em dados.","metadata":{"catalog_family":"vap","test_number":10,"question_number":3}},{"id":"dbd5b4b5-8a69-5610-9cb9-3fe3b8cae7ca","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d37a9fe8-00de-5441-b448-a3e0090af2de","option_code":"D","option_text":"Substituir o registro de interações pelo improviso.","metadata":{"catalog_family":"vap","test_number":10,"question_number":3}},{"id":"5e37b84e-9ea7-599b-9d5d-ed38d66fecd7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"67782952-7920-5032-8035-4fe34a97b198","option_code":"A","option_text":"Alterar automaticamente contratos assinados.","metadata":{"catalog_family":"vap","test_number":10,"question_number":4}},{"id":"b5fca622-1258-5271-b952-73f52b13333e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"67782952-7920-5032-8035-4fe34a97b198","option_code":"B","option_text":"Definir salários de vendedores.","metadata":{"catalog_family":"vap","test_number":10,"question_number":4}},{"id":"f0ed1bbd-297e-5ec1-a12d-cf8b1f92ebb2","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"67782952-7920-5032-8035-4fe34a97b198","option_code":"C","option_text":"Gerar descontos sem regras comerciais.","metadata":{"catalog_family":"vap","test_number":10,"question_number":4}},{"id":"e44a3012-8be1-5bfc-9db3-882fe16a9cf5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"67782952-7920-5032-8035-4fe34a97b198","option_code":"D","option_text":"Transcrever e analisar reuniões, identificando palavras-chave, sentimentos e momentos de objeção.","metadata":{"catalog_family":"vap","test_number":10,"question_number":4}},{"id":"0711b51d-a533-57ca-84ba-9bc5c41aa531","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"741b0774-4bc5-5239-9d30-2c08e6696c8f","option_code":"A","option_text":"Produto, praça, preço e promoção.","metadata":{"catalog_family":"vap","test_number":10,"question_number":5}},{"id":"e418e791-7ddd-5983-b051-3517210b3fcb","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"741b0774-4bc5-5239-9d30-2c08e6696c8f","option_code":"B","option_text":"Lead, vendedor, supervisor e diretor.","metadata":{"catalog_family":"vap","test_number":10,"question_number":5}},{"id":"6da12aa5-0358-5e88-ad13-9eb13c814f0b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"741b0774-4bc5-5239-9d30-2c08e6696c8f","option_code":"C","option_text":"Atenção, interesse, desejo e ação.","metadata":{"catalog_family":"vap","test_number":10,"question_number":5}},{"id":"24bacab6-3c0d-5035-9449-cc353c9fee17","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"741b0774-4bc5-5239-9d30-2c08e6696c8f","option_code":"D","option_text":"Segmento, empresa, cargo e indivíduo.","metadata":{"catalog_family":"vap","test_number":10,"question_number":5}},{"id":"9db734c1-318a-53cd-8126-fc279f423d4a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c25716a3-e9c6-5891-bc87-535446beebcd","option_code":"A","option_text":"Adaptar a mensagem aos desafios típicos de um diretor financeiro, mesmo antes de conhecer preferências individuais específicas.","metadata":{"catalog_family":"vap","test_number":10,"question_number":6}},{"id":"78d8976a-d879-5454-a316-c7c97d6ab29f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c25716a3-e9c6-5891-bc87-535446beebcd","option_code":"B","option_text":"Personalizar apenas com o primeiro nome.","metadata":{"catalog_family":"vap","test_number":10,"question_number":6}},{"id":"c9d92ee5-381f-50fa-80b1-7f6125fef88d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c25716a3-e9c6-5891-bc87-535446beebcd","option_code":"C","option_text":"Alterar o texto de acordo somente com a cor da marca.","metadata":{"catalog_family":"vap","test_number":10,"question_number":6}},{"id":"4baa2077-d894-5432-b5a2-5403ed9e97c8","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c25716a3-e9c6-5891-bc87-535446beebcd","option_code":"D","option_text":"Enviar a mesma mensagem para todo o mercado.","metadata":{"catalog_family":"vap","test_number":10,"question_number":6}},{"id":"210316e3-c9af-509e-ad86-763c772c83df","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"b2263f01-b48d-5114-acab-0cfae6aeab54","option_code":"A","option_text":"Preço, desconto, pressão e cobrança.","metadata":{"catalog_family":"vap","test_number":10,"question_number":7}},{"id":"e0c3d93b-8bca-55e7-af55-8012b43c4479","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"b2263f01-b48d-5114-acab-0cfae6aeab54","option_code":"B","option_text":"FAQ, qualificação, agendamento e nurturing.","metadata":{"catalog_family":"vap","test_number":10,"question_number":7}},{"id":"f8295342-53e0-59fb-b3ae-87af686d3d72","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"b2263f01-b48d-5114-acab-0cfae6aeab54","option_code":"C","option_text":"Produto, estoque, logística e jurídico.","metadata":{"catalog_family":"vap","test_number":10,"question_number":7}},{"id":"ec1ac84b-52c1-52bc-87ea-7e2d8df9c0f0","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"b2263f01-b48d-5114-acab-0cfae6aeab54","option_code":"D","option_text":"SPIN, DISC, CALMA e Johari.","metadata":{"catalog_family":"vap","test_number":10,"question_number":7}},{"id":"9d83e5fe-5ebd-5bc5-b016-4e006669a53d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"5535b05f-8fe7-5e45-a518-dfd869602022","option_code":"A","option_text":"Impedir que o prospect fale com uma pessoa.","metadata":{"catalog_family":"vap","test_number":10,"question_number":8}},{"id":"56c64de4-e940-5c5d-ac8c-21e677c973ff","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"5535b05f-8fe7-5e45-a518-dfd869602022","option_code":"B","option_text":"Inventar respostas quando não possui informação.","metadata":{"catalog_family":"vap","test_number":10,"question_number":8}},{"id":"2b78eff5-ece9-5a25-8343-f916ae8215ff","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"5535b05f-8fe7-5e45-a518-dfd869602022","option_code":"C","option_text":"Fechar qualquer venda complexa sem contexto humano.","metadata":{"catalog_family":"vap","test_number":10,"question_number":8}},{"id":"acc108f5-a2b0-5770-aad8-a96c2751b35f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"5535b05f-8fe7-5e45-a518-dfd869602022","option_code":"D","option_text":"Coletar informações relevantes e encaminhar oportunidades adequadas para a próxima etapa comercial.","metadata":{"catalog_family":"vap","test_number":10,"question_number":8}},{"id":"3bf9c72d-1776-5463-b8ae-fc06d31e3853","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"50c7572c-18f5-5adc-b610-e84d383189da","option_code":"A","option_text":"Eliminar o CRM e trabalhar apenas com prompts.","metadata":{"catalog_family":"vap","test_number":10,"question_number":9}},{"id":"ceec5c6b-d4fb-5e8f-b2f0-8302addb503b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"50c7572c-18f5-5adc-b610-e84d383189da","option_code":"B","option_text":"Automatizar 100% do processo imediatamente.","metadata":{"catalog_family":"vap","test_number":10,"question_number":9}},{"id":"f4d25537-db47-5c79-a1d2-65b31d819fdd","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"50c7572c-18f5-5adc-b610-e84d383189da","option_code":"C","option_text":"Escolher uma ferramenta, integrá-la ao workflow, treinar a equipe e definir métricas de sucesso.","metadata":{"catalog_family":"vap","test_number":10,"question_number":9}},{"id":"8a955898-0709-5447-959a-12d84062b3dc","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"50c7572c-18f5-5adc-b610-e84d383189da","option_code":"D","option_text":"Comprar todas as ferramentas disponíveis antes de medir resultados.","metadata":{"catalog_family":"vap","test_number":10,"question_number":9}},{"id":"7f0e56ec-a07c-511e-a83c-3ac760093758","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"644fba9d-821f-5db9-8e77-302f479ff0df","option_code":"A","option_text":"Substituir toda a equipe comercial.","metadata":{"catalog_family":"vap","test_number":10,"question_number":10}},{"id":"49633a78-ec37-5c61-87c0-6897ad8a7958","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"644fba9d-821f-5db9-8e77-302f479ff0df","option_code":"B","option_text":"Parar de medir conversão até o sistema amadurecer.","metadata":{"catalog_family":"vap","test_number":10,"question_number":10}},{"id":"dba48ca2-63d9-5850-be67-f0645f21ebe6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"644fba9d-821f-5db9-8e77-302f479ff0df","option_code":"C","option_text":"Remover integrações e voltar a processos manuais.","metadata":{"catalog_family":"vap","test_number":10,"question_number":10}},{"id":"690310b2-93c4-5d9d-98b0-2b345a9fddfe","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"644fba9d-821f-5db9-8e77-302f479ff0df","option_code":"D","option_text":"Adicionar chatbot ou prospecção, automatizar alguns fluxos principais e coletar feedback para ajustes.","metadata":{"catalog_family":"vap","test_number":10,"question_number":10}},{"id":"1a3d6166-5a23-5600-bbcf-87a6df73dabd","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9735cfed-0fc6-5716-bb4a-517c39def408","option_code":"A","option_text":"Transferir toda decisão estratégica para a IA sem supervisão.","metadata":{"catalog_family":"vap","test_number":10,"question_number":11}},{"id":"bab880eb-7bf0-5cd5-b485-989ecc559dba","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9735cfed-0fc6-5716-bb4a-517c39def408","option_code":"B","option_text":"Evitar relatórios para não sobrecarregar a equipe.","metadata":{"catalog_family":"vap","test_number":10,"question_number":11}},{"id":"d1719c75-b8ee-5cf1-b02d-13596c9c93de","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9735cfed-0fc6-5716-bb4a-517c39def408","option_code":"C","option_text":"Integrar ferramentas, configurar análises e relatórios automáticos e refinar processos com base em dados.","metadata":{"catalog_family":"vap","test_number":10,"question_number":11}},{"id":"0a8d1f76-e0cf-5e6c-ba3c-86583ec3240c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9735cfed-0fc6-5716-bb4a-517c39def408","option_code":"D","option_text":"Aumentar número de ferramentas sem verificar integração.","metadata":{"catalog_family":"vap","test_number":10,"question_number":11}},{"id":"72780742-4fd2-54fd-ab0e-3e9fcb9c73b5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"162200e2-a2a9-5671-9d32-08babce30d52","option_code":"A","option_text":"Automação de grande parte das tarefas operacionais, com a equipe concentrada em atividades de alto valor.","metadata":{"catalog_family":"vap","test_number":10,"question_number":12}},{"id":"aa40d2ab-ca51-5cb0-ae6d-17fc7e66b41e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"162200e2-a2a9-5671-9d32-08babce30d52","option_code":"B","option_text":"Fim completo da participação humana em vendas.","metadata":{"catalog_family":"vap","test_number":10,"question_number":12}},{"id":"01b2957b-94b2-59d3-8995-0f3111813f70","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"162200e2-a2a9-5671-9d32-08babce30d52","option_code":"C","option_text":"Retorno integral a planilhas e tarefas manuais.","metadata":{"catalog_family":"vap","test_number":10,"question_number":12}},{"id":"71dd3c83-3516-5511-afc6-dc77883b0a02","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"162200e2-a2a9-5671-9d32-08babce30d52","option_code":"D","option_text":"Uso de IA somente para escrever e-mails.","metadata":{"catalog_family":"vap","test_number":10,"question_number":12}},{"id":"d99b1979-85c5-5f92-897a-a1c1a0bd7e45","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"8687f5ce-cc44-5c63-bd70-2bff2154ff49","option_code":"A","option_text":"Comprar a ferramenta mais conhecida independentemente do processo.","metadata":{"catalog_family":"vap","test_number":10,"question_number":13}},{"id":"a55c3ee1-426b-5263-a1f2-c164cdbcf428","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"8687f5ce-cc44-5c63-bd70-2bff2154ff49","option_code":"B","option_text":"Adequação ao porte, maturidade do processo, integração necessária e orçamento disponível.","metadata":{"catalog_family":"vap","test_number":10,"question_number":13}},{"id":"c662479e-8b1a-5c6b-a44f-e60a78a711d4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"8687f5ce-cc44-5c63-bd70-2bff2154ff49","option_code":"C","option_text":"Evitar integração para manter cada sistema isolado.","metadata":{"catalog_family":"vap","test_number":10,"question_number":13}},{"id":"fbe839fe-1553-5439-9215-76d72e131fab","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"8687f5ce-cc44-5c63-bd70-2bff2154ff49","option_code":"D","option_text":"Usar o máximo de ferramentas possível desde o primeiro dia.","metadata":{"catalog_family":"vap","test_number":10,"question_number":13}},{"id":"bd17d4b2-394e-55ba-bf1b-19b54dabdff4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"93690214-edcc-5044-8bdd-aff561cb6b41","option_code":"A","option_text":"Envio de lembretes rotineiros.","metadata":{"catalog_family":"vap","test_number":10,"question_number":14}},{"id":"c8c8dbca-1470-5603-b8ce-0fc2ca769e29","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"93690214-edcc-5044-8bdd-aff561cb6b41","option_code":"B","option_text":"Transcrição de chamadas.","metadata":{"catalog_family":"vap","test_number":10,"question_number":14}},{"id":"f242b5c5-bb55-598c-b2ed-70758be481a7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"93690214-edcc-5044-8bdd-aff561cb6b41","option_code":"C","option_text":"Atualização automática de campos de CRM.","metadata":{"catalog_family":"vap","test_number":10,"question_number":14}},{"id":"6631a9a7-4f6f-5aa4-a29c-6d82ac2015da","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"93690214-edcc-5044-8bdd-aff561cb6b41","option_code":"D","option_text":"Empatia, construção de relacionamento e negociação complexa.","metadata":{"catalog_family":"vap","test_number":10,"question_number":14}},{"id":"58da3759-794f-5232-b4ad-b6d1edb7ceda","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1feb61f3-dcc2-5050-88fa-ea652914f1ba","option_code":"A","option_text":"Apenas recrutamento.","metadata":{"catalog_family":"vap","test_number":10,"question_number":15}},{"id":"0e61ba9b-c64e-5cb2-83c7-6e162b9f00f5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1feb61f3-dcc2-5050-88fa-ea652914f1ba","option_code":"B","option_text":"Medição e ajuste com base em métricas reais.","metadata":{"catalog_family":"vap","test_number":10,"question_number":15}},{"id":"135258dc-a0f3-5dcb-b04b-3644a226b8d9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1feb61f3-dcc2-5050-88fa-ea652914f1ba","option_code":"C","option_text":"Comunicação não-verbal.","metadata":{"catalog_family":"vap","test_number":10,"question_number":15}},{"id":"c5aa727b-f290-5b8c-8460-77c55e9fd746","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1feb61f3-dcc2-5050-88fa-ea652914f1ba","option_code":"D","option_text":"Persuasão por escassez.","metadata":{"catalog_family":"vap","test_number":10,"question_number":15}},{"id":"8ded52a1-e495-5dbb-acf5-db8d97f68f7e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f3444701-766d-5599-ad6d-afddef7757db","option_code":"A","option_text":"Esconder condições relevantes se isso aumentar conversão.","metadata":{"catalog_family":"vap","test_number":10,"question_number":16}},{"id":"ad24e849-cec2-5b7f-b0e2-65fd73dcf3c6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f3444701-766d-5599-ad6d-afddef7757db","option_code":"B","option_text":"Usar autoridade para impedir perguntas.","metadata":{"catalog_family":"vap","test_number":10,"question_number":16}},{"id":"72b05232-0c3d-5ea8-af72-845e0bbdcf28","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f3444701-766d-5599-ad6d-afddef7757db","option_code":"C","option_text":"Uso transparente de princípios de influência, preservando informação verdadeira e autonomia do cliente.","metadata":{"catalog_family":"vap","test_number":10,"question_number":16}},{"id":"7b7437fc-25fb-52d2-824c-8c92aecc97df","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f3444701-766d-5599-ad6d-afddef7757db","option_code":"D","option_text":"Criar escassez fictícia para gerar medo.","metadata":{"catalog_family":"vap","test_number":10,"question_number":16}},{"id":"a169413d-8f90-5fd5-8efc-44f9495f4a1b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"80e56486-90d5-5d14-9744-ddd9e62b2536","option_code":"A","option_text":"Preço, Prazo, Produto, Pressão, Promoção e Punição.","metadata":{"catalog_family":"vap","test_number":10,"question_number":17}},{"id":"4c27fe67-f8c8-5ddb-8a61-3c474153a72c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"80e56486-90d5-5d14-9744-ddd9e62b2536","option_code":"B","option_text":"Reciprocidade, Compromisso, Prova Social, Autoridade, Afeição e Escassez.","metadata":{"catalog_family":"vap","test_number":10,"question_number":17}},{"id":"6113a65f-e082-59dc-baed-3206b3638e16","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"80e56486-90d5-5d14-9744-ddd9e62b2536","option_code":"C","option_text":"Atenção, Interesse, Desejo, Ação, Retenção e Indicação.","metadata":{"catalog_family":"vap","test_number":10,"question_number":17}},{"id":"9c3eddfb-b9a5-58da-b218-0061ee629eed","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"80e56486-90d5-5d14-9744-ddd9e62b2536","option_code":"D","option_text":"Situação, Problema, Implicação, Solução, Objeção e Fechamento.","metadata":{"catalog_family":"vap","test_number":10,"question_number":17}},{"id":"13c46c1a-eb54-532c-93da-6e46e8bfa767","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a1c6f773-18d2-542f-a4b4-12bb134a5be2","option_code":"A","option_text":"Entregar primeiro uma informação ou ajuda genuinamente útil, criando disposição natural para continuar a relação.","metadata":{"catalog_family":"vap","test_number":10,"question_number":18}},{"id":"b6956656-9590-5a88-b7a6-a0b0ef1bd591","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a1c6f773-18d2-542f-a4b4-12bb134a5be2","option_code":"B","option_text":"Pressionar o cliente a comprar porque recebeu uma amostra.","metadata":{"catalog_family":"vap","test_number":10,"question_number":18}},{"id":"9c21e109-dd64-5d7a-bc94-470fa92a6442","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a1c6f773-18d2-542f-a4b4-12bb134a5be2","option_code":"C","option_text":"Oferecer um “presente” e esconder que haverá cobrança obrigatória.","metadata":{"catalog_family":"vap","test_number":10,"question_number":18}},{"id":"b8d26f44-2a49-5ca0-97fa-43eeb125b7a8","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a1c6f773-18d2-542f-a4b4-12bb134a5be2","option_code":"D","option_text":"Inventar benefício para gerar dívida emocional.","metadata":{"catalog_family":"vap","test_number":10,"question_number":18}},{"id":"ecd9b2f9-7e23-530f-825b-b61e922a46ba","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"04b7cc3b-92b1-5e21-b118-373b883326f6","option_code":"A","option_text":"Conecta o próximo passo a algo que o próprio cliente já declarou como prioridade ou decisão.","metadata":{"catalog_family":"vap","test_number":10,"question_number":19}},{"id":"6660bd7d-cfaa-5354-96a3-97183da52cb9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"04b7cc3b-92b1-5e21-b118-373b883326f6","option_code":"B","option_text":"Inventa uma declaração que o cliente nunca fez.","metadata":{"catalog_family":"vap","test_number":10,"question_number":19}},{"id":"f77fcce4-97a2-5efd-a50f-fefbd288ff52","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"04b7cc3b-92b1-5e21-b118-373b883326f6","option_code":"C","option_text":"Faz o cliente assinar algo que não entendeu.","metadata":{"catalog_family":"vap","test_number":10,"question_number":19}},{"id":"65ec1ec9-30f1-5793-a1ad-f5b3b9ae0d6d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"04b7cc3b-92b1-5e21-b118-373b883326f6","option_code":"D","option_text":"Usa pressão para impedir mudança de opinião.","metadata":{"catalog_family":"vap","test_number":10,"question_number":19}},{"id":"88fc96a8-b12d-5683-aae8-b623c47acbbf","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ae6b3ee3-30a1-57ac-acbc-7a91d7a4b975","option_code":"A","option_text":"Afirmar que a experiência torna o contrato desnecessário.","metadata":{"catalog_family":"vap","test_number":10,"question_number":20}},{"id":"1d36c58c-eeb2-5fa1-a823-f56dd9518969","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ae6b3ee3-30a1-57ac-acbc-7a91d7a4b975","option_code":"B","option_text":"Falar continuamente sobre si mesmo e interromper o cliente.","metadata":{"catalog_family":"vap","test_number":10,"question_number":20}},{"id":"173b52bf-a7e6-5b73-b2b7-d8d5236ce767","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ae6b3ee3-30a1-57ac-acbc-7a91d7a4b975","option_code":"C","option_text":"Demonstrar experiência e evidências relevantes de forma breve, mantendo espaço para perguntas e diálogo.","metadata":{"catalog_family":"vap","test_number":10,"question_number":20}},{"id":"694013f7-678b-50ac-8312-309a57625ecd","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ae6b3ee3-30a1-57ac-acbc-7a91d7a4b975","option_code":"D","option_text":"Desqualificar qualquer dúvida do prospect.","metadata":{"catalog_family":"vap","test_number":10,"question_number":20}},{"id":"c089c829-b914-5766-86c0-d0daaf78d6e4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"fc75bddd-167c-5415-8e3f-e9bc575a661e","option_code":"A","option_text":"Postura, gestos, contato visual e voz.","metadata":{"catalog_family":"vap","test_number":10,"question_number":21}},{"id":"dcccb9f3-9ec1-540c-997c-d7ac2e1eee27","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"fc75bddd-167c-5415-8e3f-e9bc575a661e","option_code":"B","option_text":"Somente palavras escritas.","metadata":{"catalog_family":"vap","test_number":10,"question_number":21}},{"id":"326ae250-e7f8-5ab7-b22c-170ed0e20d47","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"fc75bddd-167c-5415-8e3f-e9bc575a661e","option_code":"C","option_text":"Apenas roupa e aparência física.","metadata":{"catalog_family":"vap","test_number":10,"question_number":21}},{"id":"d702a55d-9ac6-5789-a41b-4942495eee91","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"fc75bddd-167c-5415-8e3f-e9bc575a661e","option_code":"D","option_text":"Exclusivamente o conteúdo técnico da proposta.","metadata":{"catalog_family":"vap","test_number":10,"question_number":21}},{"id":"b258630e-f8ef-5f38-abb6-1f5169964010","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"7cac66f0-2da5-59df-b42f-0f344e549646","option_code":"A","option_text":"Palavras, depois preço e depois tom.","metadata":{"catalog_family":"vap","test_number":10,"question_number":22}},{"id":"ac956f09-a6d5-536c-b6ed-fbacd792775f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"7cac66f0-2da5-59df-b42f-0f344e549646","option_code":"B","option_text":"Tom de voz apenas, sem importância da postura.","metadata":{"catalog_family":"vap","test_number":10,"question_number":22}},{"id":"056a13e3-40ee-5036-860e-48eaa0e49e40","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"7cac66f0-2da5-59df-b42f-0f344e549646","option_code":"C","option_text":"Preço, produto e canal de venda.","metadata":{"catalog_family":"vap","test_number":10,"question_number":22}},{"id":"75a1bd7c-405a-5492-beed-f81669b978e1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"7cac66f0-2da5-59df-b42f-0f344e549646","option_code":"D","option_text":"Linguagem corporal, seguida do tom de voz e das palavras.","metadata":{"catalog_family":"vap","test_number":10,"question_number":22}},{"id":"33967962-10ea-56d5-b18f-9303729cc97d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"50f244eb-5e2f-5f00-9fc5-5b813b49e53c","option_code":"A","option_text":"Atenção, Interesse, Desejo e Ação.","metadata":{"catalog_family":"vap","test_number":10,"question_number":23}},{"id":"eb0627a1-40af-55eb-a6ae-5ed7aee38266","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"50f244eb-5e2f-5f00-9fc5-5b813b49e53c","option_code":"B","option_text":"Problema, Preço, Desconto e Compra.","metadata":{"catalog_family":"vap","test_number":10,"question_number":23}},{"id":"3f57ae8b-f1fb-5b32-b4b3-990f9e59300f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"50f244eb-5e2f-5f00-9fc5-5b813b49e53c","option_code":"C","option_text":"Contexto, Conflito, Virada e Resolução.","metadata":{"catalog_family":"vap","test_number":10,"question_number":23}},{"id":"c9e85754-30f3-504a-a424-faa6578bdd48","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"50f244eb-5e2f-5f00-9fc5-5b813b49e53c","option_code":"D","option_text":"Antes, Depois, Ponte e Push.","metadata":{"catalog_family":"vap","test_number":10,"question_number":23}},{"id":"24f1ec57-1e92-554e-b5b5-7afee810b363","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"5db3a65d-cdf5-534a-83df-2ef6b8c98cd4","option_code":"A","option_text":"História de concorrente, desconto e comissão.","metadata":{"catalog_family":"vap","test_number":10,"question_number":24}},{"id":"68c71eb5-0f7c-5727-b0a4-94520e666606","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"5db3a65d-cdf5-534a-83df-2ef6b8c98cd4","option_code":"B","option_text":"História de cliente, de produto e do vendedor.","metadata":{"catalog_family":"vap","test_number":10,"question_number":24}},{"id":"d034b460-7f3d-5bb1-836f-d0759b4141f6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"5db3a65d-cdf5-534a-83df-2ef6b8c98cd4","option_code":"C","option_text":"História de preço, prazo e contrato.","metadata":{"catalog_family":"vap","test_number":10,"question_number":24}},{"id":"e7bf9d5c-10ee-54c8-9a88-28e9e918cbc3","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"5db3a65d-cdf5-534a-83df-2ef6b8c98cd4","option_code":"D","option_text":"História financeira, jurídica e contábil.","metadata":{"catalog_family":"vap","test_number":10,"question_number":24}},{"id":"55d8373a-5440-5439-befa-53f6f99ad7cd","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a78f17db-d823-566e-af8b-5025c7a2904f","option_code":"A","option_text":"Silêncio Punitivo.","metadata":{"catalog_family":"vap","test_number":10,"question_number":25}},{"id":"dd13839b-fcf4-5927-a0ba-2a3c14e6c63e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a78f17db-d823-566e-af8b-5025c7a2904f","option_code":"B","option_text":"Pergunta Direta.","metadata":{"catalog_family":"vap","test_number":10,"question_number":25}},{"id":"a709e4cd-6f56-566a-bb51-8001d3e49114","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a78f17db-d823-566e-af8b-5025c7a2904f","option_code":"C","option_text":"Pressão Oculta.","metadata":{"catalog_family":"vap","test_number":10,"question_number":25}},{"id":"d3048c49-8ba6-515f-920c-29d9b8c6cb44","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a78f17db-d823-566e-af8b-5025c7a2904f","option_code":"D","option_text":"Ameaça de Perda Falsa.","metadata":{"catalog_family":"vap","test_number":10,"question_number":25}},{"id":"dc1a4a0b-8ade-5807-831e-1541acb12d21","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4b5ff332-29cf-56db-a495-e0cd7744cabd","option_code":"A","option_text":"Oferecer duas opções legítimas de próximo passo que façam sentido para o cliente.","metadata":{"catalog_family":"vap","test_number":10,"question_number":26}},{"id":"f5ec4328-c742-5815-9547-29acb8fa130f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4b5ff332-29cf-56db-a495-e0cd7744cabd","option_code":"B","option_text":"Evitar que o cliente diga não.","metadata":{"catalog_family":"vap","test_number":10,"question_number":26}},{"id":"862be613-cf91-5bc1-881a-43a95ce756bc","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4b5ff332-29cf-56db-a495-e0cd7744cabd","option_code":"C","option_text":"Apresentar duas opções falsas, sendo uma impossível.","metadata":{"catalog_family":"vap","test_number":10,"question_number":26}},{"id":"d87bb6cd-1ada-56bc-a1c9-fd25446bb357","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4b5ff332-29cf-56db-a495-e0cd7744cabd","option_code":"D","option_text":"Ocultar a existência de outras condições relevantes.","metadata":{"catalog_family":"vap","test_number":10,"question_number":26}},{"id":"18ec5149-fcd6-5c20-82a2-95a7d2787bb3","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"b68744a2-bdb9-55f0-9c57-a0d540a33339","option_code":"A","option_text":"Quando a condição pode ser criada depois para justificar a fala.","metadata":{"catalog_family":"vap","test_number":10,"question_number":27}},{"id":"6aa00d83-34e0-5e8a-b671-ba598e97185e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"b68744a2-bdb9-55f0-9c57-a0d540a33339","option_code":"B","option_text":"Sempre que o cliente pedir tempo para pensar.","metadata":{"catalog_family":"vap","test_number":10,"question_number":27}},{"id":"af76032f-58e3-5303-9ec5-05087ba169b9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"b68744a2-bdb9-55f0-9c57-a0d540a33339","option_code":"C","option_text":"Quando a limitação é verdadeira, verificável e comunicada sem exagero.","metadata":{"catalog_family":"vap","test_number":10,"question_number":27}},{"id":"22af91c7-8eb1-560f-b7fe-63c7422e3aa2","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"b68744a2-bdb9-55f0-9c57-a0d540a33339","option_code":"D","option_text":"Quando o vendedor inventa uma última vaga.","metadata":{"catalog_family":"vap","test_number":10,"question_number":27}},{"id":"b8a47a3d-3c49-5841-bed9-b681ee0aa6b4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"89e10146-4c42-5f59-8a95-1b479b0848e3","option_code":"A","option_text":"Limitar o relacionamento a sete dias.","metadata":{"catalog_family":"vap","test_number":10,"question_number":28}},{"id":"2e33127f-d734-5b4b-8bb0-ddbe4bda0b03","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"89e10146-4c42-5f59-8a95-1b479b0848e3","option_code":"B","option_text":"Substituir todos os contatos humanos por uma única mensagem.","metadata":{"catalog_family":"vap","test_number":10,"question_number":28}},{"id":"63e44a05-3d45-5668-aad2-6618b1055cc3","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"89e10146-4c42-5f59-8a95-1b479b0848e3","option_code":"C","option_text":"Planejar uma sequência de sete toques com timing e conteúdo para acompanhar oportunidades de forma estruturada.","metadata":{"catalog_family":"vap","test_number":10,"question_number":28}},{"id":"0ea0077a-d3e3-57e3-aaec-9c868741a817","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"89e10146-4c42-5f59-8a95-1b479b0848e3","option_code":"D","option_text":"Definir desconto progressivo obrigatório.","metadata":{"catalog_family":"vap","test_number":10,"question_number":28}},{"id":"f2839cbb-da73-51dd-b5a9-8fd7dd08ce0d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"77b82f94-4f16-5d61-8335-f3f10d9bd92e","option_code":"A","option_text":"Medir somente número de ligações.","metadata":{"catalog_family":"vap","test_number":10,"question_number":29}},{"id":"75e23564-d7a8-55f2-8484-394774fab62f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"77b82f94-4f16-5d61-8335-f3f10d9bd92e","option_code":"B","option_text":"Autoavaliar e receber feedback sobre elementos de comunicação não-verbal.","metadata":{"catalog_family":"vap","test_number":10,"question_number":29}},{"id":"4ab5212e-1091-593b-a3b6-f5958f9c228c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"77b82f94-4f16-5d61-8335-f3f10d9bd92e","option_code":"C","option_text":"Classificar objeções financeiras.","metadata":{"catalog_family":"vap","test_number":10,"question_number":29}},{"id":"115b161a-c7ef-5bde-ac71-fad46c8358c8","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"77b82f94-4f16-5d61-8335-f3f10d9bd92e","option_code":"D","option_text":"Calcular o preço mínimo da proposta.","metadata":{"catalog_family":"vap","test_number":10,"question_number":29}},{"id":"fb076572-6ba9-5db1-a05d-9b981c97dc98","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"03dd8c11-9d73-5abe-95a4-729835aae122","option_code":"A","option_text":"A IA envia mensagens genéricas; o vendedor pressiona por desconto e ignora objeções.","metadata":{"catalog_family":"vap","test_number":10,"question_number":30}},{"id":"da9bb328-a1b8-5264-a161-32fe2538950d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"03dd8c11-9d73-5abe-95a4-729835aae122","option_code":"B","option_text":"A IA organiza dados e follow-up; o vendedor adapta a comunicação ao perfil, constrói valor, trata objeções com escuta e usa persuasão ética para conduzir o próximo passo.","metadata":{"catalog_family":"vap","test_number":10,"question_number":30}},{"id":"41da281e-2c9e-5ab0-887a-b94af4fd47cb","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"03dd8c11-9d73-5abe-95a4-729835aae122","option_code":"C","option_text":"O vendedor usa apenas carisma e evita CRM para manter espontaneidade.","metadata":{"catalog_family":"vap","test_number":10,"question_number":30}},{"id":"2de5fc56-996d-5fd6-8713-da882ced610b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"03dd8c11-9d73-5abe-95a4-729835aae122","option_code":"D","option_text":"O processo se concentra em fechar rápido, mesmo que seja preciso criar urgência fictícia.","metadata":{"catalog_family":"vap","test_number":10,"question_number":30}}]$vap_options$::jsonb) as x(
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
  from jsonb_to_recordset($vap_keys$[{"question_id":"9ffe2f4e-a840-507e-a1d0-adbf68c23deb","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"A","justification":"O VAP posiciona IA como amplificadora de capacidade, preservando o papel humano em interação de alto valor.","source_reference":"Método VAP - Módulo 10","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":1,"source_label":"IA em Vendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"c0c44efd-edee-5efa-a8c8-ed77e7e7bf69","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"D","justification":"O módulo organiza o ecossistema em categorias diretamente ligadas ao processo comercial.","source_reference":"Método VAP - Módulo 10","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":2,"source_label":"IA em Vendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"d37a9fe8-00de-5441-b448-a3e0090af2de","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"CRMs com IA são apresentados como ferramentas para priorização, previsão e recomendação de ação.","source_reference":"Método VAP - Módulo 10","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":3,"source_label":"IA em Vendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"67782952-7920-5032-8035-4fe34a97b198","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"D","justification":"O módulo apresenta análise de chamadas como fonte de dados para coaching e melhoria contínua.","source_reference":"Método VAP - Módulo 10","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":4,"source_label":"IA em Vendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"741b0774-4bc5-5239-9d30-2c08e6696c8f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"D","justification":"A personalização evolui do agrupamento mais amplo até mensagens adaptadas ao indivíduo.","source_reference":"Método VAP - Módulo 10","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":5,"source_label":"IA em Vendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"c25716a3-e9c6-5891-bc87-535446beebcd","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"A","justification":"O nível cargo adapta a comunicação às responsabilidades e prioridades associadas à função do prospect.","source_reference":"Método VAP - Módulo 10","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":6,"source_label":"IA em Vendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"b2263f01-b48d-5114-acab-0cfae6aeab54","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"O módulo diferencia chatbots de FAQ, qualificação, agendamento e nutrição de leads.","source_reference":"Método VAP - Módulo 10","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":7,"source_label":"IA em Vendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"5535b05f-8fe7-5e45-a518-dfd869602022","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"D","justification":"Chatbots de qualificação apoiam triagem e coleta de dados, liberando humanos para etapas de maior valor.","source_reference":"Método VAP - Módulo 10","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":8,"source_label":"IA em Vendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"50c7572c-18f5-5adc-b610-e84d383189da","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"A fase Fundação recomenda começar pequeno, integrar e medir antes de expandir.","source_reference":"Método VAP - Módulo 10, Roadmap 180 Dias","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":9,"source_label":"IA em Vendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"644fba9d-821f-5db9-8e77-302f479ff0df","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"D","justification":"A segunda fase amplia a automação de forma controlada e orientada por feedback.","source_reference":"Método VAP - Módulo 10, Roadmap 180 Dias","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":10,"source_label":"IA em Vendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"9735cfed-0fc6-5716-bb4a-517c39def408","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"A etapa Otimização conecta o stack e usa dados para refinar o processo.","source_reference":"Método VAP - Módulo 10, Roadmap 180 Dias","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":11,"source_label":"IA em Vendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"162200e2-a2a9-5671-9d32-08babce30d52","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"A","justification":"A fase Maturidade prevê forte automação operacional, preservando relacionamento e negociação para pessoas.","source_reference":"Método VAP - Módulo 10, Roadmap 180 Dias","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":12,"source_label":"IA em Vendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"8687f5ce-cc44-5c63-bd70-2bff2154ff49","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"O material deixa claro que o stack ideal varia conforme contexto e maturidade da operação.","source_reference":"Método VAP - Módulo 10","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":13,"source_label":"IA em Vendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"93690214-edcc-5044-8bdd-aff561cb6b41","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"D","justification":"O módulo distingue tarefas de eficiência, adequadas à IA, de competências relacionais de alto valor.","source_reference":"Método VAP - Módulo 10","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":14,"source_label":"IA em Vendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"1feb61f3-dcc2-5050-88fa-ea652914f1ba","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"O roadmap recomenda definir métricas, medir e ajustar antes de ampliar o uso da tecnologia.","source_reference":"Método VAP - Módulos 1 e 10","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":15,"source_label":"IA em Vendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"f3444701-766d-5599-ad6d-afddef7757db","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"A persuasão do VAP é orientada por transparência e influência responsável.","source_reference":"Método VAP - Módulo Extra, Persuasão Ética","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":16,"source_label":"Venda Persuasiva","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"80e56486-90d5-5d14-9744-ddd9e62b2536","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"O resumo do Módulo Extra lista os seis princípios aplicados com transparência.","source_reference":"Método VAP - Módulo Extra","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":17,"source_label":"Venda Persuasiva","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"a1c6f773-18d2-542f-a4b4-12bb134a5be2","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"A","justification":"Reciprocidade ética parte de valor genuíno, sem transformar a oferta em obrigação escondida.","source_reference":"Método VAP - Módulo Extra","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":18,"source_label":"Venda Persuasiva","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"04b7cc3b-92b1-5e21-b118-373b883326f6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"A","justification":"Compromisso funciona melhor quando deriva de posições voluntariamente assumidas pelo próprio cliente.","source_reference":"Método VAP - Módulo Extra","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":19,"source_label":"Venda Persuasiva","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"ae6b3ee3-30a1-57ac-acbc-7a91d7a4b975","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"Autoridade persuasiva se apoia em credibilidade e evidência, não em imposição.","source_reference":"Método VAP - Módulo Extra","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":20,"source_label":"Venda Persuasiva","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"fc75bddd-167c-5415-8e3f-e9bc575a661e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"A","justification":"O módulo trata presença persuasiva por meio de postura, gestos, olhar e voz.","source_reference":"Método VAP - Módulo Extra","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":21,"source_label":"Venda Persuasiva","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"7cac66f0-2da5-59df-b42f-0f344e549646","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"D","justification":"O material apresenta 7% palavras, 38% tom de voz e 55% linguagem corporal para enfatizar coerência não-verbal.","source_reference":"Método VAP - Módulo Extra e Módulo 8","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":22,"source_label":"Venda Persuasiva","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"50f244eb-5e2f-5f00-9fc5-5b813b49e53c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"O modelo de história em quatro etapas conduz da situação inicial à transformação final.","source_reference":"Método VAP - Módulo Extra, Storytelling","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":23,"source_label":"Venda Persuasiva","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"5db3a65d-cdf5-534a-83df-2ef6b8c98cd4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"O resumo organiza o repertório em histórias de cliente, produto e vendedor.","source_reference":"Método VAP - Módulo Extra","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":24,"source_label":"Venda Persuasiva","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"a78f17db-d823-566e-af8b-5025c7a2904f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"O material lista Pergunta Direta entre seis técnicas de fechamento avançado.","source_reference":"Método VAP - Módulo Extra","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":25,"source_label":"Venda Persuasiva","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"4b5ff332-29cf-56db-a495-e0cd7744cabd","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"A","justification":"A técnica de alternativas simplifica a decisão entre caminhos reais, sem retirar a autonomia do cliente.","source_reference":"Método VAP - Módulo Extra","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":26,"source_label":"Venda Persuasiva","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"b68744a2-bdb9-55f0-9c57-a0d540a33339","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"Escassez só deve apoiar persuasão quando corresponde a uma condição real.","source_reference":"Método VAP - Módulos 6 e Extra","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":27,"source_label":"Venda Persuasiva","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"89e10146-4c42-5f59-8a95-1b479b0848e3","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"O material bônus apresenta um calendário de sete toques para estruturar acompanhamento comercial.","source_reference":"Método VAP - Materiais Bônus","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":28,"source_label":"Venda Persuasiva","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"77b82f94-4f16-5d61-8335-f3f10d9bd92e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"O checklist reúne itens de postura e presença para autoavaliação ou feedback de colegas.","source_reference":"Método VAP - Materiais Bônus","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":29,"source_label":"Venda Persuasiva","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}},{"question_id":"03dd8c11-9d73-5abe-95a4-729835aae122","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"A aplicação avançada integra processo, dados, IA, comportamento, valor, objeções e persuasão ética em um único sistema.","source_reference":"Método VAP - Integração dos Módulos 1 a 10 + Extra","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":30,"source_label":"Integração VAP","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 10"}}]$vap_keys$::jsonb) as x(
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
  from jsonb_to_recordset($vap_version_questions$[{"id":"f63cb424-aa2e-54bc-ac72-132bbc15da44","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"9ffe2f4e-a840-507e-a1d0-adbf68c23deb","sequence_no":1,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":1}},{"id":"f3c87caa-0da5-5eb2-9cbc-3d31e2426246","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"c0c44efd-edee-5efa-a8c8-ed77e7e7bf69","sequence_no":2,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":2}},{"id":"a0258c6f-1972-5101-b5be-b7923d9511f5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"d37a9fe8-00de-5441-b448-a3e0090af2de","sequence_no":3,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":3}},{"id":"9b5919f8-aa07-5cee-9227-e5ece36bbb93","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"67782952-7920-5032-8035-4fe34a97b198","sequence_no":4,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":4}},{"id":"4e965ce0-5113-5de0-8c02-151b09a514eb","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"741b0774-4bc5-5239-9d30-2c08e6696c8f","sequence_no":5,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":5}},{"id":"d19778db-24e7-5065-a1e3-3331cc012a43","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"c25716a3-e9c6-5891-bc87-535446beebcd","sequence_no":6,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":6}},{"id":"e3522baf-bb04-5b38-86b2-c6fc49579a69","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"b2263f01-b48d-5114-acab-0cfae6aeab54","sequence_no":7,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":7}},{"id":"e01405ff-acfb-5742-a738-10db435c279e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"5535b05f-8fe7-5e45-a518-dfd869602022","sequence_no":8,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":8}},{"id":"109e03e1-f455-5baf-bec8-f3ded383fa77","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"50c7572c-18f5-5adc-b610-e84d383189da","sequence_no":9,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":9}},{"id":"17f94daf-2996-553c-9dc9-b587e67862ab","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"644fba9d-821f-5db9-8e77-302f479ff0df","sequence_no":10,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":10}},{"id":"c7a39366-1d51-5a8d-8ce5-f6aa30df1a56","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"9735cfed-0fc6-5716-bb4a-517c39def408","sequence_no":11,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":11}},{"id":"c9b4ec56-3c51-5488-ae91-1bfb7bfeeb2f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"162200e2-a2a9-5671-9d32-08babce30d52","sequence_no":12,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":12}},{"id":"726decc7-afc4-5ba1-b90a-1e0a00466a7e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"8687f5ce-cc44-5c63-bd70-2bff2154ff49","sequence_no":13,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":13}},{"id":"e7b6f168-28ee-5759-b4ed-8d46168b34a3","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"93690214-edcc-5044-8bdd-aff561cb6b41","sequence_no":14,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":14}},{"id":"5d58d0ef-8acb-5a11-a8dd-ed3282475bd4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"1feb61f3-dcc2-5050-88fa-ea652914f1ba","sequence_no":15,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":15}},{"id":"23be2b4d-0ef1-5c94-804d-e6ce5d998aca","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"f3444701-766d-5599-ad6d-afddef7757db","sequence_no":16,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":16}},{"id":"f6e175bd-2541-59bd-9bd4-c0a53c4a4509","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"80e56486-90d5-5d14-9744-ddd9e62b2536","sequence_no":17,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":17}},{"id":"f5c64a96-354d-5851-8ec1-9620b341fe2e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"a1c6f773-18d2-542f-a4b4-12bb134a5be2","sequence_no":18,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":18}},{"id":"df5b30a4-24ca-5419-93fd-5dbd0275a1cd","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"04b7cc3b-92b1-5e21-b118-373b883326f6","sequence_no":19,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":19}},{"id":"253966bf-6e4c-50b8-9f7b-2bbfcc4fff83","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"ae6b3ee3-30a1-57ac-acbc-7a91d7a4b975","sequence_no":20,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":20}},{"id":"4efc2aae-3a1d-5e53-b150-8f01840c37df","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"fc75bddd-167c-5415-8e3f-e9bc575a661e","sequence_no":21,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":21}},{"id":"48510bb4-13df-5d35-bb19-c77b80200e69","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"7cac66f0-2da5-59df-b42f-0f344e549646","sequence_no":22,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":22}},{"id":"e009aba1-4c23-594c-ae49-f53644ab5f37","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"50f244eb-5e2f-5f00-9fc5-5b813b49e53c","sequence_no":23,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":23}},{"id":"f0d152ea-f984-58b9-a74b-74b03d66c316","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"5db3a65d-cdf5-534a-83df-2ef6b8c98cd4","sequence_no":24,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":24}},{"id":"4177c435-a303-5f6e-bd8d-afcecb0cecf4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"a78f17db-d823-566e-af8b-5025c7a2904f","sequence_no":25,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":25}},{"id":"a75b9abf-4d02-501f-a24e-31183a7a193e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"4b5ff332-29cf-56db-a495-e0cd7744cabd","sequence_no":26,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":26}},{"id":"0e4f1a93-97b9-5cd5-be05-0691ee12ab74","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"b68744a2-bdb9-55f0-9c57-a0d540a33339","sequence_no":27,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":27}},{"id":"aed88b13-cca8-5178-88ec-bcb87fbdac52","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"89e10146-4c42-5f59-8a95-1b479b0848e3","sequence_no":28,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":28}},{"id":"1f9390e3-6a51-57f6-bc32-a5472a57661b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"77b82f94-4f16-5d61-8335-f3f10d9bd92e","sequence_no":29,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":29}},{"id":"c9e627d6-997a-54b4-bc00-1ba26167046f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"867c9840-67c2-5424-a79a-e847886938b2","question_id":"03dd8c11-9d73-5abe-95a4-729835aae122","sequence_no":30,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":10,"question_number":30}}]$vap_version_questions$::jsonb) as x(
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

do $post$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
  v_test_id uuid := 'c2933dbe-62c7-57f8-9b87-3db4d194bde0'::uuid;
  v_version_id uuid := '867c9840-67c2-5424-a79a-e847886938b2'::uuid;
begin
  if (
    select count(*)
    from public.competency_domains c
    where c.organization_id = v_org_id
      and c.code in ('vap_ia_vendas','vap_persuasao_etica')
      and c.status = 'draft'
      and c.is_legal = false
      and c.archived_at is null
  ) <> 2 then
    raise exception 'VAP Teste 10 pós-condição: esperado 2 novas competências VAP em draft.';
  end if;

  if not exists (
    select 1
    from public.competency_domains c
    where c.id = '43ab5826-1867-50ec-9c1d-2d0b8f5f5fe0'::uuid
      and c.organization_id = v_org_id
      and c.code = 'vap_integracao'
      and c.archived_at is null
  ) then
    raise exception 'VAP Teste 10 pós-condição: competência vap_integracao não foi preservada.';
  end if;

  if not exists (
    select 1
    from public.assessment_tests t
    where t.id = v_test_id
      and t.organization_id = v_org_id
      and t.code = 'teste_10_vap_ia_vendas_persuasao'
      and t.sequence_no = 10
      and t.question_count = 30
      and t.status = 'draft'
      and t.archived_at is null
  ) then
    raise exception 'VAP Teste 10 pós-condição: identidade do teste não confere.';
  end if;

  if not exists (
    select 1
    from public.assessment_test_versions tv
    where tv.id = v_version_id
      and tv.organization_id = v_org_id
      and tv.test_id = v_test_id
      and tv.version_code = '2026.08-v1'
      and tv.version_no = 1
      and tv.status = 'draft'
      and tv.passing_score = 100
      and tv.legal_min_score = 100
      and tv.question_count = 30
      and tv.randomize_questions = true
      and tv.randomize_options = true
      and tv.published_at is null
      and tv.archived_at is null
  ) then
    raise exception 'VAP Teste 10 pós-condição: versão draft/fail-closed não confere.';
  end if;

  if (
    select count(*)
    from public.assessment_questions q
    where q.organization_id = v_org_id
      and q.code like 'vap_t10_q%'
      and q.status = 'reviewed'
      and q.archived_at is null
  ) <> 30 then
    raise exception 'VAP Teste 10 pós-condição: esperado 30 questões reviewed.';
  end if;

  if (
    select count(*)
    from public.assessment_version_questions avq
    where avq.organization_id = v_org_id
      and avq.test_version_id = v_version_id
      and avq.is_required = true
      and avq.archived_at is null
  ) <> 30 then
    raise exception 'VAP Teste 10 pós-condição: esperado 30 vínculos obrigatórios.';
  end if;

  if (
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
    raise exception 'VAP Teste 10 pós-condição: sequência de questões não é 1..30.';
  end if;

  if (
    select count(*)
    from public.assessment_question_options o
    join public.assessment_questions q
      on q.id = o.question_id
     and q.organization_id = o.organization_id
    where o.organization_id = v_org_id
      and q.code like 'vap_t10_q%'
      and q.archived_at is null
      and o.archived_at is null
  ) <> 120 then
    raise exception 'VAP Teste 10 pós-condição: esperado 120 alternativas.';
  end if;

  if exists (
    select 1
    from (
      select q.id, count(o.id) as option_count
      from public.assessment_questions q
      left join public.assessment_question_options o
        on o.question_id = q.id
       and o.organization_id = q.organization_id
       and o.archived_at is null
      where q.organization_id = v_org_id
        and q.code like 'vap_t10_q%'
        and q.archived_at is null
      group by q.id
    ) x
    where x.option_count <> 4
  ) then
    raise exception 'VAP Teste 10 pós-condição: alguma questão não possui exatamente 4 alternativas.';
  end if;

  if (
    select count(*)
    from private.assessment_question_keys k
    join public.assessment_questions q
      on q.id = k.question_id
     and q.organization_id = k.organization_id
    where k.organization_id = v_org_id
      and q.code like 'vap_t10_q%'
      and q.archived_at is null
  ) <> 30 then
    raise exception 'VAP Teste 10 pós-condição: esperado 30 gabaritos privados.';
  end if;

  if exists (
    select 1
    from private.assessment_question_keys k
    join public.assessment_questions q
      on q.id = k.question_id
     and q.organization_id = k.organization_id
    left join public.assessment_question_options o
      on o.question_id = k.question_id
     and o.organization_id = k.organization_id
     and o.option_code = k.correct_option_code
     and o.archived_at is null
    where k.organization_id = v_org_id
      and q.code like 'vap_t10_q%'
      and q.archived_at is null
      and o.id is null
  ) then
    raise exception 'VAP Teste 10 pós-condição: existe gabarito sem alternativa correspondente.';
  end if;

  if exists (
    select 1
    from private.assessment_question_keys k
    join public.assessment_questions q
      on q.id = k.question_id
     and q.organization_id = k.organization_id
    where k.organization_id = v_org_id
      and q.code like 'vap_t10_q%'
      and q.archived_at is null
      and k.is_critical = true
  ) then
    raise exception 'VAP Teste 10 pós-condição: criticidade foi criada sem base no material.';
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
      and q.block_code = 'ia_vendas'
  ) <> 15 then
    raise exception 'VAP Teste 10 pós-condição: esperado 15 questões IA em Vendas.';
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
      and q.block_code = 'persuasao_etica'
  ) <> 14 then
    raise exception 'VAP Teste 10 pós-condição: esperado 14 questões de Persuasão Ética.';
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
      and q.block_code = 'integracao_vap'
      and q.competency_id = '43ab5826-1867-50ec-9c1d-2d0b8f5f5fe0'::uuid
  ) <> 1 then
    raise exception 'VAP Teste 10 pós-condição: esperado 1 item de Integração VAP reutilizando a competência existente.';
  end if;

  if (
    select count(*)
    from public.assessment_version_sources avs
    where avs.organization_id = v_org_id
      and avs.test_version_id = v_version_id
      and avs.source_material_version_id = 'a20ad8ff-b3f8-5106-b96e-346fa342d098'::uuid
      and avs.relation_type = 'primary'
      and avs.is_required = true
      and avs.archived_at is null
  ) <> 1 then
    raise exception 'VAP Teste 10 pós-condição: vínculo com fonte primária não confere.';
  end if;

  if exists (
    select 1
    from private.assessment_test_access_grants g
    where g.organization_id = v_org_id
      and g.test_id = v_test_id
      and g.archived_at is null
  ) then
    raise exception 'VAP Teste 10 pós-condição: nenhum grant deveria ter sido criado.';
  end if;

  if exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.test_id = v_test_id
      and a.archived_at is null
  ) then
    raise exception 'VAP Teste 10 pós-condição: nenhuma tentativa deveria existir.';
  end if;

  if (
    select count(*)
    from public.assessment_tests t
    where t.organization_id = v_org_id
      and t.sequence_no between 1 and 9
      and t.archived_at is null
  ) <> 9 then
    raise exception 'VAP Teste 10 pós-condição: catálogo-base 1..9 foi alterado.';
  end if;
end
$post$;

commit;
