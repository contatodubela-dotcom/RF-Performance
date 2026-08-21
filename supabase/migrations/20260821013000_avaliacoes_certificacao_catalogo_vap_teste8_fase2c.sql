-- ============================================================================
-- RF Performance — Avaliações e Certificações
-- Catálogo Ampliado — Método VAP — Teste 8
-- Fase 2C — cadastro em RASCUNHO para homologação controlada
--
-- Teste 8:
--   Neurovendas e Copywriting
--   Declaração editorial: 15 questões de Neurovendas + 15 de Copywriting.
--   Mapeamento semântico efetivo: 15 Neurovendas + 14 Copywriting +
--   1 Integração VAP (questão 30, explicitamente rotulada assim no material).
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
--   - Não altera Testes 1 a 7.
--   - Não recria a fonte Método VAP.
--   - Reutiliza a competência genérica vap_integracao criada na Fase 2A.
--   - Não cria grant de acesso.
--   - Não publica o Teste 8.
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
    raise exception 'VAP Teste 8 abortado: organização RF esperada não localizada/ativa.';
  end if;

  if (
    select count(*)
    from public.assessment_tests t
    where t.organization_id = v_org_id
      and t.archived_at is null
      and t.sequence_no between 1 and 7
  ) <> 7 then
    raise exception 'VAP Teste 8 abortado: catálogo-base Testes 1 a 7 não está íntegro.';
  end if;

  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions tv
      on tv.test_id = t.id
     and tv.organization_id = t.organization_id
     and tv.archived_at is null
    where t.organization_id = v_org_id
      and t.sequence_no = 7
      and t.code = 'teste_7_vap_lideranca_disc'
      and t.status = 'draft'
      and tv.version_code = '2026.08-v1'
      and tv.status = 'draft'
      and t.archived_at is null
  ) then
    raise exception 'VAP Teste 8 abortado: Teste 7 VAP esperado não está presente em draft.';
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
    raise exception 'VAP Teste 8 abortado: fonte Método VAP/versionamento esperado não confere.';
  end if;

  if not exists (
    select 1
    from public.competency_domains c
    where c.id = '43ab5826-1867-50ec-9c1d-2d0b8f5f5fe0'::uuid
      and c.organization_id = v_org_id
      and c.code = 'vap_integracao'
      and c.sequence_no = 34
      and c.status = 'draft'
      and c.is_legal = false
      and c.archived_at is null
  ) then
    raise exception 'VAP Teste 8 abortado: competência vap_integracao esperada da Fase 2A não confere.';
  end if;

  if exists (
    select 1
    from public.assessment_tests t
    where t.organization_id = v_org_id
      and t.archived_at is null
      and (
        t.sequence_no = 8
        or t.code = 'teste_8_vap_neurovendas_copywriting'
        or t.id = '596353c9-73e3-59c6-81a3-796ac376f7aa'::uuid
      )
  ) then
    raise exception 'VAP Teste 8 abortado: já existe teste ocupando a identidade/seq. 8.';
  end if;

  if exists (
    select 1
    from public.competency_domains c
    where c.organization_id = v_org_id
      and c.archived_at is null
      and (
        c.sequence_no between 37 and 38
        or c.code in ('vap_neurovendas','vap_copywriting')
        or c.id in (
          '627144ab-ed29-57eb-bbb5-dfda0cb11a74'::uuid,
          '4a538414-d7b8-51aa-b33d-9bdaf3c306e6'::uuid
        )
      )
  ) then
    raise exception 'VAP Teste 8 abortado: identidade/sequência das novas competências já está ocupada.';
  end if;
end
$guard$;

with payload as (
  select *
  from jsonb_to_recordset($vap_competencies$[{"id":"627144ab-ed29-57eb-bbb5-dfda0cb11a74","code":"vap_neurovendas","sequence_no":37,"name":"VAP — Neurovendas","description":"Neurovendas, decisão de compra, gatilhos mentais e aplicação ética no Método VAP.","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","domain_type":"knowledge","is_legal":false,"default_weight":0,"status":"draft","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"draft_catalog"}},{"id":"4a538414-d7b8-51aa-b33d-9bdaf3c306e6","code":"vap_copywriting","sequence_no":38,"name":"VAP — Copywriting","description":"Copywriting, fórmulas persuasivas, storytelling, CTA e propostas de alto valor no Método VAP.","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","domain_type":"knowledge","is_legal":false,"default_weight":0,"status":"draft","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"draft_catalog"}}]$vap_competencies$::jsonb) as x(
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
  '596353c9-73e3-59c6-81a3-796ac376f7aa'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'teste_8_vap_neurovendas_copywriting',
  8,
  'Teste 8 — Neurovendas e Copywriting',
  'Avaliação do Método VAP sobre Neurovendas, Copywriting e integração ética entre emoção e racionalidade.',
  'intermediate_advanced',
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
    'source_level_label', 'Intermediário / Avançado',
    'source_material_code', 'metodo_vap_vendedor_alta_performance',
    'source_content_sha256', 'd28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84',
    'authoring_document', 'Sistema de Certificação Comercial — Método VAP — Testes 6 a 10',
    'authoring_document_sha256', '8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820',
    'authoring_document_date_label', 'Agosto de 2026',
    'declared_distribution', jsonb_build_object(
      'neurovendas', 15,
      'copywriting', 15
    ),
    'effective_competency_mapping', jsonb_build_object(
      'neurovendas', 15,
      'copywriting', 14,
      'integracao_vap', 1
    ),
    'mapping_note', 'A questão 30 é explicitamente rotulada como Integração VAP no documento-fonte.',
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
  '34b181a4-c718-555e-8909-754d58bbccf2'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '596353c9-73e3-59c6-81a3-796ac376f7aa'::uuid,
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
  '14133a11-e9ef-514c-a10d-5a9d6c2c54ee'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '34b181a4-c718-555e-8909-754d58bbccf2'::uuid,
  'a20ad8ff-b3f8-5106-b96e-346fa342d098'::uuid,
  'primary',
  true,
  'Fonte primária dos conteúdos avaliados no Teste 8 do Método VAP.',
  jsonb_build_object(
    'catalog_family', 'vap',
    'test_number', 8,
    'source_content_sha256', 'd28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84'
  )
);

with payload as (
  select *
  from jsonb_to_recordset($vap_questions$[{"id":"d2b60b0d-5072-54a8-8e1e-080881972333","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q01","competency_id":"627144ab-ed29-57eb-bbb5-dfda0cb11a74","block_code":"neurovendas","prompt":"Qual é o objetivo central da neurovendas no Método VAP?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":1,"source_label":"Neurovendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"4d16d5a7-7874-5a1e-bce9-8b5099b90e69","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q02","competency_id":"627144ab-ed29-57eb-bbb5-dfda0cb11a74","block_code":"neurovendas","prompt":"Segundo o material do VAP, qual é a função associada ao cérebro reptiliano no processo de compra?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":2,"source_label":"Neurovendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"97ceb997-6d61-5ee6-af20-9d4a598b88f3","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q03","competency_id":"627144ab-ed29-57eb-bbb5-dfda0cb11a74","block_code":"neurovendas","prompt":"No modelo apresentado, o sistema límbico está mais relacionado a:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":3,"source_label":"Neurovendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"de1d41ab-8ffd-5686-b0a0-e07c2985765e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q04","competency_id":"627144ab-ed29-57eb-bbb5-dfda0cb11a74","block_code":"neurovendas","prompt":"Qual papel é atribuído ao neocórtex no modelo de decisão do VAP?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":4,"source_label":"Neurovendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"8e0b2c58-7f20-5ac3-b642-59bcf0b71e6c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q05","competency_id":"627144ab-ed29-57eb-bbb5-dfda0cb11a74","block_code":"neurovendas","prompt":"Qual neurotransmissor é associado, no material, ao prazer antecipado e à expectativa de recompensa?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":5,"source_label":"Neurovendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"42527c63-1e8f-526c-b772-7648d8b69f20","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q06","competency_id":"627144ab-ed29-57eb-bbb5-dfda0cb11a74","block_code":"neurovendas","prompt":"Qual neurotransmissor é associado à confiança no material de Neurovendas?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":6,"source_label":"Neurovendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"8bdd5f98-a92a-5cff-8876-e05b2ccbe8dc","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q07","competency_id":"627144ab-ed29-57eb-bbb5-dfda0cb11a74","block_code":"neurovendas","prompt":"Qual neurotransmissor o VAP associa à autoridade e reconhecimento?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":7,"source_label":"Neurovendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"0d9d49aa-1cc0-579b-b9c7-16615167c861","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q08","competency_id":"627144ab-ed29-57eb-bbb5-dfda0cb11a74","block_code":"neurovendas","prompt":"No VAP, qual efeito comercial é associado ao excesso de cortisol?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":8,"source_label":"Neurovendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"5b57bc7d-cfe4-5aef-ad58-0c8374bdcbbd","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q09","competency_id":"627144ab-ed29-57eb-bbb5-dfda0cb11a74","block_code":"neurovendas","prompt":"No AIDA neurológico do VAP, a etapa Atenção é relacionada principalmente a:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":9,"source_label":"Neurovendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"8f7c1136-0798-5aaa-8d4d-21d69179e161","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q10","competency_id":"627144ab-ed29-57eb-bbb5-dfda0cb11a74","block_code":"neurovendas","prompt":"No AIDA neurológico, a etapa Desejo é associada especialmente a:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":10,"source_label":"Neurovendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"f0c61ec4-49eb-50b1-8040-71d25c83f090","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q11","competency_id":"627144ab-ed29-57eb-bbb5-dfda0cb11a74","block_code":"neurovendas","prompt":"Qual alternativa contém apenas gatilhos mentais citados no VAP?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":11,"source_label":"Neurovendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"d652a570-fc46-533b-abac-e03f77cc7d6c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q12","competency_id":"627144ab-ed29-57eb-bbb5-dfda0cb11a74","block_code":"neurovendas","prompt":"Como o VAP orienta o uso de escassez e urgência?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":12,"source_label":"Neurovendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"d50b1da6-6eef-5367-9087-b1a66ab75e6d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q13","competency_id":"627144ab-ed29-57eb-bbb5-dfda0cb11a74","block_code":"neurovendas","prompt":"Qual afirmação representa melhor a integração entre emoção e lógica na venda segundo o VAP?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":13,"source_label":"Neurovendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"94b1dcb3-fe85-519b-aaab-180dbdaefaa9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q14","competency_id":"627144ab-ed29-57eb-bbb5-dfda0cb11a74","block_code":"neurovendas","prompt":"Um vendedor usa um caso real de cliente semelhante para reduzir incerteza e demonstrar resultado. Qual gatilho está aplicando principalmente?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":14,"source_label":"Neurovendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"d0865b9e-cbd6-55fd-a3e6-f49541818ca9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q15","competency_id":"627144ab-ed29-57eb-bbb5-dfda0cb11a74","block_code":"neurovendas","prompt":"Qual conduta contraria a abordagem ética de neurovendas do VAP?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":15,"source_label":"Neurovendas","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"cacbda90-4f6c-5bee-a248-4303db220a1a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q16","competency_id":"4a538414-d7b8-51aa-b33d-9bdaf3c306e6","block_code":"copywriting","prompt":"Como o VAP define copywriting?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":16,"source_label":"Copywriting","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"5c1c8580-6939-5ffd-bb0c-583abb8db34c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q17","competency_id":"4a538414-d7b8-51aa-b33d-9bdaf3c306e6","block_code":"copywriting","prompt":"Qual é a diferença principal entre copy e conteúdo segundo o material?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":17,"source_label":"Copywriting","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"bff04171-6c85-5fbd-96ad-2eb427c500c3","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q18","competency_id":"4a538414-d7b8-51aa-b33d-9bdaf3c306e6","block_code":"copywriting","prompt":"Na fórmula AIDA, a letra I significa:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":18,"source_label":"Copywriting","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"dd1c631f-360d-54ac-90dc-6fdc64409af7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q19","competency_id":"4a538414-d7b8-51aa-b33d-9bdaf3c306e6","block_code":"copywriting","prompt":"Qual sequência representa corretamente a fórmula PAS?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":19,"source_label":"Copywriting","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"488cb106-bb8a-5885-846d-fe1a6a525e97","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q20","competency_id":"4a538414-d7b8-51aa-b33d-9bdaf3c306e6","block_code":"copywriting","prompt":"Na fórmula BAB, “Bridge” representa:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":20,"source_label":"Copywriting","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"6ea45bb3-3465-5130-abff-e745100468bf","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q21","competency_id":"4a538414-d7b8-51aa-b33d-9bdaf3c306e6","block_code":"copywriting","prompt":"Quais são os 4Ps de copywriting apresentados no VAP?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":21,"source_label":"Copywriting","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"bf90136d-e910-58f3-b278-72c3378b14a9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q22","competency_id":"4a538414-d7b8-51aa-b33d-9bdaf3c306e6","block_code":"copywriting","prompt":"Qual fórmula o material sugere especialmente para posts, anúncios e e-mails de abertura?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":22,"source_label":"Copywriting","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"433c216f-9e51-57c2-ada5-63ac710b5f97","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q23","competency_id":"4a538414-d7b8-51aa-b33d-9bdaf3c306e6","block_code":"copywriting","prompt":"Qual fórmula é indicada no material para vendas consultivas, apresentações e propostas?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":23,"source_label":"Copywriting","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"386c562f-1813-58cf-b906-5212fefd507f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q24","competency_id":"4a538414-d7b8-51aa-b33d-9bdaf3c306e6","block_code":"copywriting","prompt":"No modelo de post de vendas do VAP, o CTA deve:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":24,"source_label":"Copywriting","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"71de4dab-9b0b-51c3-8951-66ebbc6b7c0b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q25","competency_id":"4a538414-d7b8-51aa-b33d-9bdaf3c306e6","block_code":"copywriting","prompt":"Em uma proposta de alto valor, qual elemento é recomendado pelo VAP?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":25,"source_label":"Copywriting","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"ae7c7526-524f-5fc5-9d27-419235733d6d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q26","competency_id":"4a538414-d7b8-51aa-b33d-9bdaf3c306e6","block_code":"copywriting","prompt":"Segundo o VAP, qual é uma boa forma de usar storytelling em uma proposta?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":26,"source_label":"Copywriting","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"0b64671a-bd40-521f-ae8e-baef7058eabc","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q27","competency_id":"4a538414-d7b8-51aa-b33d-9bdaf3c306e6","block_code":"copywriting","prompt":"Qual prática ajuda a criar urgência legítima em uma proposta, segundo o material?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":27,"source_label":"Copywriting","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"1fd13c6b-23e5-5f8b-ad14-e4e50c52fb49","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q28","competency_id":"4a538414-d7b8-51aa-b33d-9bdaf3c306e6","block_code":"copywriting","prompt":"Um e-mail tem boa informação, mas não indica o que o leitor deve fazer em seguida. Qual elemento de copy está faltando?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":28,"source_label":"Copywriting","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"58243333-92bf-5610-9fc5-9a45d6dfe408","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q29","competency_id":"4a538414-d7b8-51aa-b33d-9bdaf3c306e6","block_code":"copywriting","prompt":"Qual combinação é mais coerente com vendas de alto valor no VAP?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":29,"source_label":"Copywriting","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"aef01740-6e01-5716-9b1f-0d38cb0c62de","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t8_q30","competency_id":"43ab5826-1867-50ec-9c1d-2d0b8f5f5fe0","block_code":"integracao_vap","prompt":"Qual princípio integra Neurovendas e Copywriting no Método VAP?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":30,"source_label":"Integração VAP","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}}]$vap_questions$::jsonb) as x(
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
  from jsonb_to_recordset($vap_options$[{"id":"49709675-d558-553d-9214-51c19f04d564","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d2b60b0d-5072-54a8-8e1e-080881972333","option_code":"A","option_text":"Controlar a decisão do cliente sem que ele perceba.","metadata":{"catalog_family":"vap","test_number":8,"question_number":1}},{"id":"7bb212c8-fe02-584b-84e8-633dfc3096dc","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d2b60b0d-5072-54a8-8e1e-080881972333","option_code":"B","option_text":"Substituir diagnóstico por gatilhos mentais.","metadata":{"catalog_family":"vap","test_number":8,"question_number":1}},{"id":"04c42171-5dc1-52c6-a2f6-d7af1beaf03f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d2b60b0d-5072-54a8-8e1e-080881972333","option_code":"C","option_text":"Compreender como o cérebro participa da decisão de compra para criar contextos de comunicação mais favoráveis e éticos.","metadata":{"catalog_family":"vap","test_number":8,"question_number":1}},{"id":"d9d6c0e0-ff20-58f6-b3cc-3ac8b4a2369f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d2b60b0d-5072-54a8-8e1e-080881972333","option_code":"D","option_text":"Eliminar a necessidade de clareza racional.","metadata":{"catalog_family":"vap","test_number":8,"question_number":1}},{"id":"f65efdf7-2181-5b5a-868e-76e80ebad4d0","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4d16d5a7-7874-5a1e-bce9-8b5099b90e69","option_code":"A","option_text":"Gerar exclusivamente conexão social.","metadata":{"catalog_family":"vap","test_number":8,"question_number":2}},{"id":"1bf684c4-6409-5d3a-a4f4-4b45bc4ba9ce","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4d16d5a7-7874-5a1e-bce9-8b5099b90e69","option_code":"B","option_text":"Buscar segurança e reagir a elementos básicos de proteção e risco.","metadata":{"catalog_family":"vap","test_number":8,"question_number":2}},{"id":"8a3adf49-44ed-5a82-96f8-4c54c0490cbb","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4d16d5a7-7874-5a1e-bce9-8b5099b90e69","option_code":"C","option_text":"Construir apenas justificativas lógicas detalhadas.","metadata":{"catalog_family":"vap","test_number":8,"question_number":2}},{"id":"458fe777-db90-55ee-8018-c47d09686953","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4d16d5a7-7874-5a1e-bce9-8b5099b90e69","option_code":"D","option_text":"Calcular ROI financeiro de longo prazo.","metadata":{"catalog_family":"vap","test_number":8,"question_number":2}},{"id":"4ff9b6ac-ce26-5aa0-9314-30492951eb70","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"97ceb997-6d61-5ee6-af20-9d4a598b88f3","option_code":"A","option_text":"Emoção e conexão afetiva na decisão.","metadata":{"catalog_family":"vap","test_number":8,"question_number":3}},{"id":"dd6018a0-94e9-5343-97dc-1b701cae3924","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"97ceb997-6d61-5ee6-af20-9d4a598b88f3","option_code":"B","option_text":"Memorização de especificações técnicas apenas.","metadata":{"catalog_family":"vap","test_number":8,"question_number":3}},{"id":"2b612af8-beb4-5f32-b415-783473ee2957","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"97ceb997-6d61-5ee6-af20-9d4a598b88f3","option_code":"C","option_text":"Controle jurídico do contrato.","metadata":{"catalog_family":"vap","test_number":8,"question_number":3}},{"id":"cbab3c61-9c85-5263-83ed-a88966acc615","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"97ceb997-6d61-5ee6-af20-9d4a598b88f3","option_code":"D","option_text":"Análise lógica de planilhas.","metadata":{"catalog_family":"vap","test_number":8,"question_number":3}},{"id":"2b6c7d5a-6bd7-5fd7-bdf1-6da19ac89923","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"de1d41ab-8ffd-5686-b0a0-e07c2985765e","option_code":"A","option_text":"Substituir a necessidade de comunicação clara.","metadata":{"catalog_family":"vap","test_number":8,"question_number":4}},{"id":"5b26f5e9-c556-5408-a29f-41d7c5f6aa26","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"de1d41ab-8ffd-5686-b0a0-e07c2985765e","option_code":"B","option_text":"Detectar ameaça imediata antes de qualquer emoção.","metadata":{"catalog_family":"vap","test_number":8,"question_number":4}},{"id":"b63366d0-6d6f-5bb6-8c94-b79abd7a48e0","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"de1d41ab-8ffd-5686-b0a0-e07c2985765e","option_code":"C","option_text":"Justificar e organizar racionalmente a decisão com lógica e análise.","metadata":{"catalog_family":"vap","test_number":8,"question_number":4}},{"id":"69c60e94-e934-5443-9c44-64bdff65d6bd","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"de1d41ab-8ffd-5686-b0a0-e07c2985765e","option_code":"D","option_text":"Produzir somente entusiasmo e empatia.","metadata":{"catalog_family":"vap","test_number":8,"question_number":4}},{"id":"7370314b-5bf6-559c-9512-6a11cf17e30a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"8e0b2c58-7f20-5ac3-b642-59bcf0b71e6c","option_code":"A","option_text":"Dopamina.","metadata":{"catalog_family":"vap","test_number":8,"question_number":5}},{"id":"32c74936-cce0-516c-8dd3-af4a68789d73","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"8e0b2c58-7f20-5ac3-b642-59bcf0b71e6c","option_code":"B","option_text":"Ocitocina.","metadata":{"catalog_family":"vap","test_number":8,"question_number":5}},{"id":"97807f1c-ad52-5f8e-813c-aefe2be4bda9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"8e0b2c58-7f20-5ac3-b642-59bcf0b71e6c","option_code":"C","option_text":"Serotonina.","metadata":{"catalog_family":"vap","test_number":8,"question_number":5}},{"id":"32b02adf-1a5e-5c98-a013-2df5dfa4ef4b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"8e0b2c58-7f20-5ac3-b642-59bcf0b71e6c","option_code":"D","option_text":"Cortisol.","metadata":{"catalog_family":"vap","test_number":8,"question_number":5}},{"id":"c3c17225-8756-58d7-98e7-d2c6bf78710c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"42527c63-1e8f-526c-b772-7648d8b69f20","option_code":"A","option_text":"Dopamina.","metadata":{"catalog_family":"vap","test_number":8,"question_number":6}},{"id":"4d059740-9c0a-5d5e-9452-2b13b1a5c32a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"42527c63-1e8f-526c-b772-7648d8b69f20","option_code":"B","option_text":"Ocitocina.","metadata":{"catalog_family":"vap","test_number":8,"question_number":6}},{"id":"640df253-eb36-5c15-9c13-3742fac0b054","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"42527c63-1e8f-526c-b772-7648d8b69f20","option_code":"C","option_text":"Cortisol.","metadata":{"catalog_family":"vap","test_number":8,"question_number":6}},{"id":"f446fcbc-a0b2-55b1-88fa-137a0f7be5fa","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"42527c63-1e8f-526c-b772-7648d8b69f20","option_code":"D","option_text":"Adrenalina.","metadata":{"catalog_family":"vap","test_number":8,"question_number":6}},{"id":"35a48b4a-6bef-5523-9558-29eafab866e7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"8bdd5f98-a92a-5cff-8876-e05b2ccbe8dc","option_code":"A","option_text":"Ocitocina.","metadata":{"catalog_family":"vap","test_number":8,"question_number":7}},{"id":"f56ad6ad-001d-5929-bdcc-a1faf7d422d9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"8bdd5f98-a92a-5cff-8876-e05b2ccbe8dc","option_code":"B","option_text":"Cortisol.","metadata":{"catalog_family":"vap","test_number":8,"question_number":7}},{"id":"7e3561b0-b3fa-5e61-a2fd-92a7a1d159bb","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"8bdd5f98-a92a-5cff-8876-e05b2ccbe8dc","option_code":"C","option_text":"Dopamina.","metadata":{"catalog_family":"vap","test_number":8,"question_number":7}},{"id":"6fcd936f-3f0c-59a3-acb3-ad8c3a226b45","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"8bdd5f98-a92a-5cff-8876-e05b2ccbe8dc","option_code":"D","option_text":"Serotonina.","metadata":{"catalog_family":"vap","test_number":8,"question_number":7}},{"id":"b68dcb9e-da56-5322-8494-f54db07bad8e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"0d9d49aa-1cc0-579b-b9c7-16615167c861","option_code":"A","option_text":"Garantir fechamento imediato.","metadata":{"catalog_family":"vap","test_number":8,"question_number":8}},{"id":"f400ac01-c049-5f39-97a8-7dbc95e73307","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"0d9d49aa-1cc0-579b-b9c7-16615167c861","option_code":"B","option_text":"Elevar estresse e dificultar um contexto favorável de decisão.","metadata":{"catalog_family":"vap","test_number":8,"question_number":8}},{"id":"d3512f0f-a7a6-5538-b2c9-74140e212c5c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"0d9d49aa-1cc0-579b-b9c7-16615167c861","option_code":"C","option_text":"Aumentar automaticamente confiança.","metadata":{"catalog_family":"vap","test_number":8,"question_number":8}},{"id":"423382da-e5b7-560f-9d29-505c9fac1f26","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"0d9d49aa-1cc0-579b-b9c7-16615167c861","option_code":"D","option_text":"Substituir a necessidade de prova social.","metadata":{"catalog_family":"vap","test_number":8,"question_number":8}},{"id":"8e860a09-a292-5bc0-9dda-4d5910959947","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"5b57bc7d-cfe4-5aef-ad58-0c8374bdcbbd","option_code":"A","option_text":"Sistema límbico exclusivamente.","metadata":{"catalog_family":"vap","test_number":8,"question_number":9}},{"id":"3a1f8e01-6198-538a-a1f4-9fdf39d8f610","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"5b57bc7d-cfe4-5aef-ad58-0c8374bdcbbd","option_code":"B","option_text":"Neocórtex exclusivamente.","metadata":{"catalog_family":"vap","test_number":8,"question_number":9}},{"id":"235e209c-6de8-5c62-aafc-2fdaf7be0f52","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"5b57bc7d-cfe4-5aef-ad58-0c8374bdcbbd","option_code":"C","option_text":"Cérebro reptiliano.","metadata":{"catalog_family":"vap","test_number":8,"question_number":9}},{"id":"b434814e-67a2-5595-9b23-f72865655ed6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"5b57bc7d-cfe4-5aef-ad58-0c8374bdcbbd","option_code":"D","option_text":"Memória de longo prazo apenas.","metadata":{"catalog_family":"vap","test_number":8,"question_number":9}},{"id":"9a833f54-8712-5c13-a96c-a96c84b36a48","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"8f7c1136-0798-5aaa-8d4d-21d69179e161","option_code":"A","option_text":"Apenas lógica financeira.","metadata":{"catalog_family":"vap","test_number":8,"question_number":10}},{"id":"417f8100-09f7-5e53-bfd4-54a7b69bc132","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"8f7c1136-0798-5aaa-8d4d-21d69179e161","option_code":"B","option_text":"Exclusivamente linguagem corporal.","metadata":{"catalog_family":"vap","test_number":8,"question_number":10}},{"id":"fdcc3e76-08a1-53a7-92d4-05511e6bde40","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"8f7c1136-0798-5aaa-8d4d-21d69179e161","option_code":"C","option_text":"Dopamina e ocitocina, combinando antecipação e confiança.","metadata":{"catalog_family":"vap","test_number":8,"question_number":10}},{"id":"958bc4b2-b2ad-5b63-9033-920d337b1fa3","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"8f7c1136-0798-5aaa-8d4d-21d69179e161","option_code":"D","option_text":"Somente cortisol.","metadata":{"catalog_family":"vap","test_number":8,"question_number":10}},{"id":"f0ede25c-cfcf-5a23-9420-9fcc7388da89","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f0c61ec4-49eb-50b1-8040-71d25c83f090","option_code":"A","option_text":"Reciprocidade, prova social, autoridade e pertencimento.","metadata":{"catalog_family":"vap","test_number":8,"question_number":11}},{"id":"444c643d-2688-55d2-af5b-4067ecc03a7f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f0c61ec4-49eb-50b1-8040-71d25c83f090","option_code":"B","option_text":"Improviso, punição, segredo e confronto.","metadata":{"catalog_family":"vap","test_number":8,"question_number":11}},{"id":"d65f0015-7ed2-5b29-bb09-852433bd64c5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f0c61ec4-49eb-50b1-8040-71d25c83f090","option_code":"C","option_text":"Pressão falsa, ameaça, ocultação e confusão.","metadata":{"catalog_family":"vap","test_number":8,"question_number":11}},{"id":"985da75a-2d10-555b-8c0a-184c72315041","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f0c61ec4-49eb-50b1-8040-71d25c83f090","option_code":"D","option_text":"Desconto automático, insistência, interrupção e culpa.","metadata":{"catalog_family":"vap","test_number":8,"question_number":11}},{"id":"08e831f2-125c-532b-9274-903f3ae2f2ff","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d652a570-fc46-533b-abac-e03f77cc7d6c","option_code":"A","option_text":"Usando qualquer ameaça que acelere a assinatura.","metadata":{"catalog_family":"vap","test_number":8,"question_number":12}},{"id":"af06c233-5107-5e87-b5a4-c48597782ddb","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d652a570-fc46-533b-abac-e03f77cc7d6c","option_code":"B","option_text":"Escondendo condições para gerar medo de perder.","metadata":{"catalog_family":"vap","test_number":8,"question_number":12}},{"id":"7c9700fa-38ef-5121-afdb-5acdcb4f1f7b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d652a570-fc46-533b-abac-e03f77cc7d6c","option_code":"C","option_text":"Somente quando forem reais, de forma transparente e ética.","metadata":{"catalog_family":"vap","test_number":8,"question_number":12}},{"id":"51455c5e-d361-5c38-ab92-29e22f63872d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d652a570-fc46-533b-abac-e03f77cc7d6c","option_code":"D","option_text":"Criando prazos fictícios sempre que o cliente hesitar.","metadata":{"catalog_family":"vap","test_number":8,"question_number":12}},{"id":"dc6b0695-1d18-56d6-82a4-efc40e8d0708","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d50b1da6-6eef-5367-9087-b1a66ab75e6d","option_code":"A","option_text":"O vendedor deve escolher entre emoção ou lógica e nunca usar ambas.","metadata":{"catalog_family":"vap","test_number":8,"question_number":13}},{"id":"9e2cb9bf-798f-56a1-a105-bf310d294544","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d50b1da6-6eef-5367-9087-b1a66ab75e6d","option_code":"B","option_text":"Emoção não influencia compra, portanto apenas dados importam.","metadata":{"catalog_family":"vap","test_number":8,"question_number":13}},{"id":"22433d32-c461-5aed-b0bd-caa49b906e4c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d50b1da6-6eef-5367-9087-b1a66ab75e6d","option_code":"C","option_text":"A lógica deve ser eliminada porque toda decisão é emocional.","metadata":{"catalog_family":"vap","test_number":8,"question_number":13}},{"id":"6c55e1e2-88be-5d17-a05a-1d7e0f0a9562","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d50b1da6-6eef-5367-9087-b1a66ab75e6d","option_code":"D","option_text":"A comunicação deve criar conexão e significado, mas também oferecer elementos racionais que sustentem a decisão.","metadata":{"catalog_family":"vap","test_number":8,"question_number":13}},{"id":"9889503f-a60d-594c-992a-0527474da671","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"94b1dcb3-fe85-519b-aaab-180dbdaefaa9","option_code":"A","option_text":"Novidade.","metadata":{"catalog_family":"vap","test_number":8,"question_number":14}},{"id":"220509a8-67ba-5ed9-81a5-4f1ddf970036","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"94b1dcb3-fe85-519b-aaab-180dbdaefaa9","option_code":"B","option_text":"Reciprocidade.","metadata":{"catalog_family":"vap","test_number":8,"question_number":14}},{"id":"a14d76c5-963c-5390-b262-cf5c15b67854","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"94b1dcb3-fe85-519b-aaab-180dbdaefaa9","option_code":"C","option_text":"Prova social.","metadata":{"catalog_family":"vap","test_number":8,"question_number":14}},{"id":"f4990d8a-03b4-5612-881d-e4937385358f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"94b1dcb3-fe85-519b-aaab-180dbdaefaa9","option_code":"D","option_text":"Escassez.","metadata":{"catalog_family":"vap","test_number":8,"question_number":14}},{"id":"07f99bac-b270-5d35-8646-b30bad0628e3","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d0865b9e-cbd6-55fd-a3e6-f49541818ca9","option_code":"A","option_text":"Usar prova social verdadeira.","metadata":{"catalog_family":"vap","test_number":8,"question_number":15}},{"id":"a98245ef-6534-561b-97dd-d41923d93672","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d0865b9e-cbd6-55fd-a3e6-f49541818ca9","option_code":"B","option_text":"Construir confiança antes da proposta.","metadata":{"catalog_family":"vap","test_number":8,"question_number":15}},{"id":"79540ff4-32b4-502a-9241-1e00d8c2a47c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d0865b9e-cbd6-55fd-a3e6-f49541818ca9","option_code":"C","option_text":"Simplificar uma explicação complexa.","metadata":{"catalog_family":"vap","test_number":8,"question_number":15}},{"id":"9394bf1d-62eb-5c29-9f04-62fc8c5bced9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d0865b9e-cbd6-55fd-a3e6-f49541818ca9","option_code":"D","option_text":"Inventar risco ou escassez para provocar medo e forçar decisão.","metadata":{"catalog_family":"vap","test_number":8,"question_number":15}},{"id":"5835a7df-18c3-526d-9946-98954b09e8c7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"cacbda90-4f6c-5bee-a248-4303db220a1a","option_code":"A","option_text":"Um recurso exclusivo de anúncios pagos.","metadata":{"catalog_family":"vap","test_number":8,"question_number":16}},{"id":"a7a67539-5af5-5466-b9e6-217089c2a0b4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"cacbda90-4f6c-5bee-a248-4303db220a1a","option_code":"B","option_text":"A arte e ciência de criar mensagens persuasivas orientadas a uma ação específica.","metadata":{"catalog_family":"vap","test_number":8,"question_number":16}},{"id":"8591ef2b-4f8b-55cd-9311-bbd66d91bc80","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"cacbda90-4f6c-5bee-a248-4303db220a1a","option_code":"C","option_text":"Qualquer texto longo usado para informar sem objetivo de ação.","metadata":{"catalog_family":"vap","test_number":8,"question_number":16}},{"id":"b76eb625-13f6-572e-9965-4a5f672e77f8","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"cacbda90-4f6c-5bee-a248-4303db220a1a","option_code":"D","option_text":"A substituição do vendedor por textos automáticos.","metadata":{"catalog_family":"vap","test_number":8,"question_number":16}},{"id":"542073d0-2b8c-5d4d-8320-de9a79d96fe6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"5c1c8580-6939-5ffd-bb0c-583abb8db34c","option_code":"A","option_text":"Não existe diferença de objetivo entre os dois.","metadata":{"catalog_family":"vap","test_number":8,"question_number":17}},{"id":"971308ba-5a9e-535e-b106-5e8b7ec99c68","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"5c1c8580-6939-5ffd-bb0c-583abb8db34c","option_code":"B","option_text":"Conteúdo sempre vende e copy nunca vende.","metadata":{"catalog_family":"vap","test_number":8,"question_number":17}},{"id":"da213b18-5a57-54c3-9756-133224dd1f1a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"5c1c8580-6939-5ffd-bb0c-583abb8db34c","option_code":"C","option_text":"Copy só pode ser usado em papel; conteúdo apenas em redes sociais.","metadata":{"catalog_family":"vap","test_number":8,"question_number":17}},{"id":"4159df72-6361-5df2-91a0-13f793ef8b09","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"5c1c8580-6939-5ffd-bb0c-583abb8db34c","option_code":"D","option_text":"Copy busca conversão com ação clara; conteúdo prioriza educação, informação e construção de autoridade.","metadata":{"catalog_family":"vap","test_number":8,"question_number":17}},{"id":"34ebb484-b974-5bb2-b455-339fa7656a27","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"bff04171-6c85-5fbd-96ad-2eb427c500c3","option_code":"A","option_text":"Interesse.","metadata":{"catalog_family":"vap","test_number":8,"question_number":18}},{"id":"b3ca557b-a036-5e84-9d0e-4e27d2bd34c1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"bff04171-6c85-5fbd-96ad-2eb427c500c3","option_code":"B","option_text":"Identificação.","metadata":{"catalog_family":"vap","test_number":8,"question_number":18}},{"id":"4c797bc9-0012-578d-a9a5-1989218d7dd1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"bff04171-6c85-5fbd-96ad-2eb427c500c3","option_code":"C","option_text":"Intenção.","metadata":{"catalog_family":"vap","test_number":8,"question_number":18}},{"id":"70d2ec17-7ba0-5add-be88-aa06c0a38d73","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"bff04171-6c85-5fbd-96ad-2eb427c500c3","option_code":"D","option_text":"Impacto.","metadata":{"catalog_family":"vap","test_number":8,"question_number":18}},{"id":"9747e792-a7dc-5750-a626-83ebc569cc69","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"dd1c631f-360d-54ac-90dc-6fdc64409af7","option_code":"A","option_text":"Proposta, Autoridade e Segurança.","metadata":{"catalog_family":"vap","test_number":8,"question_number":19}},{"id":"83c8b090-1753-5300-8f45-109e11baca6c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"dd1c631f-360d-54ac-90dc-6fdc64409af7","option_code":"B","option_text":"Problema, Agitação e Solução.","metadata":{"catalog_family":"vap","test_number":8,"question_number":19}},{"id":"78504e02-a5b5-50b8-ad0b-f21dc604a2e2","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"dd1c631f-360d-54ac-90dc-6fdc64409af7","option_code":"C","option_text":"Promessa, Atenção e Simplicidade.","metadata":{"catalog_family":"vap","test_number":8,"question_number":19}},{"id":"47d4c0f4-6741-56a4-9fac-50001fd04e56","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"dd1c631f-360d-54ac-90dc-6fdc64409af7","option_code":"D","option_text":"Produto, Ação e Storytelling.","metadata":{"catalog_family":"vap","test_number":8,"question_number":19}},{"id":"0eb698e4-7e27-58c7-b58b-5dfe19b065d7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"488cb106-bb8a-5885-846d-fe1a6a525e97","option_code":"A","option_text":"O desconto concedido após a objeção.","metadata":{"catalog_family":"vap","test_number":8,"question_number":20}},{"id":"df9680c1-f816-524c-92b8-b95f29289f00","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"488cb106-bb8a-5885-846d-fe1a6a525e97","option_code":"B","option_text":"A prova social usada no fechamento.","metadata":{"catalog_family":"vap","test_number":8,"question_number":20}},{"id":"834b66bd-8798-5966-acbd-e158212fd212","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"488cb106-bb8a-5885-846d-fe1a6a525e97","option_code":"C","option_text":"O problema inicial do cliente.","metadata":{"catalog_family":"vap","test_number":8,"question_number":20}},{"id":"3528e095-0357-5efe-91da-e8dae9570060","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"488cb106-bb8a-5885-846d-fe1a6a525e97","option_code":"D","option_text":"A ponte que conecta a situação atual ao estado desejado por meio da solução.","metadata":{"catalog_family":"vap","test_number":8,"question_number":20}},{"id":"4c3f9c51-7ee3-5992-b1ed-b897f2f01376","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"6ea45bb3-3465-5130-abff-e745100468bf","option_code":"A","option_text":"Produto, Preço, Praça e Promoção.","metadata":{"catalog_family":"vap","test_number":8,"question_number":21}},{"id":"c1260896-44df-57b8-b91e-4f2588334b2d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"6ea45bb3-3465-5130-abff-e745100468bf","option_code":"B","option_text":"Promessa, Prova, Proposta e Push.","metadata":{"catalog_family":"vap","test_number":8,"question_number":21}},{"id":"f05c61e3-8b81-55e3-9dd2-9fa9b8ca0d13","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"6ea45bb3-3465-5130-abff-e745100468bf","option_code":"C","option_text":"Pesquisa, Planejamento, Processo e Performance.","metadata":{"catalog_family":"vap","test_number":8,"question_number":21}},{"id":"08df137d-f961-58ca-b55b-01f8952c5123","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"6ea45bb3-3465-5130-abff-e745100468bf","option_code":"D","option_text":"Pergunta, Problema, Persuasão e Pós-venda.","metadata":{"catalog_family":"vap","test_number":8,"question_number":21}},{"id":"ba75d2db-b0fe-511b-b8da-cb01f5db85de","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"bf90136d-e910-58f3-b278-72c3378b14a9","option_code":"A","option_text":"AIDA.","metadata":{"catalog_family":"vap","test_number":8,"question_number":22}},{"id":"8adc3b28-60f9-5afb-a78c-baa8cf2fff6a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"bf90136d-e910-58f3-b278-72c3378b14a9","option_code":"B","option_text":"4P Equipes.","metadata":{"catalog_family":"vap","test_number":8,"question_number":22}},{"id":"da96bd83-3823-5fe9-bc95-6cc2c4fbcfb3","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"bf90136d-e910-58f3-b278-72c3378b14a9","option_code":"C","option_text":"DECIDE+.","metadata":{"catalog_family":"vap","test_number":8,"question_number":22}},{"id":"68c499c9-ebe4-52ea-b91e-ad7c8ea25759","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"bf90136d-e910-58f3-b278-72c3378b14a9","option_code":"D","option_text":"CALMA.","metadata":{"catalog_family":"vap","test_number":8,"question_number":22}},{"id":"a839d44b-51ca-5568-8d0d-6922c05d15c9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"433c216f-9e51-57c2-ada5-63ac710b5f97","option_code":"A","option_text":"DISC.","metadata":{"catalog_family":"vap","test_number":8,"question_number":23}},{"id":"b33d2015-f2ef-5399-8c43-d3452e9a4979","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"433c216f-9e51-57c2-ada5-63ac710b5f97","option_code":"B","option_text":"PAS.","metadata":{"catalog_family":"vap","test_number":8,"question_number":23}},{"id":"a3dfe432-9c18-5d13-af61-c1d3832332cb","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"433c216f-9e51-57c2-ada5-63ac710b5f97","option_code":"C","option_text":"DECIDE+.","metadata":{"catalog_family":"vap","test_number":8,"question_number":23}},{"id":"d9265536-e1bf-5b29-8d17-651e4594fe1f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"433c216f-9e51-57c2-ada5-63ac710b5f97","option_code":"D","option_text":"ABCDE.","metadata":{"catalog_family":"vap","test_number":8,"question_number":23}},{"id":"b213ad5f-f0a0-517f-8b90-ad27c9f5de88","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"386c562f-1813-58cf-b906-5212fefd507f","option_code":"A","option_text":"Ser omitido para não parecer comercial.","metadata":{"catalog_family":"vap","test_number":8,"question_number":24}},{"id":"39290255-75d4-537a-87c5-23be3549fede","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"386c562f-1813-58cf-b906-5212fefd507f","option_code":"B","option_text":"Aparecer antes de qualquer contexto e benefício.","metadata":{"catalog_family":"vap","test_number":8,"question_number":24}},{"id":"8d8ebbff-5919-5586-b699-0dc6b064a482","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"386c562f-1813-58cf-b906-5212fefd507f","option_code":"C","option_text":"Indicar claramente a próxima ação esperada do leitor.","metadata":{"catalog_family":"vap","test_number":8,"question_number":24}},{"id":"7b500fb2-240c-5fc9-afe2-e5155c906bcd","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"386c562f-1813-58cf-b906-5212fefd507f","option_code":"D","option_text":"Ser substituído por uma explicação técnica longa.","metadata":{"catalog_family":"vap","test_number":8,"question_number":24}},{"id":"df6bfb1a-3543-5955-958a-6b3ed6bcabb2","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"71de4dab-9b0b-51c3-8951-66ebbc6b7c0b","option_code":"A","option_text":"Compreensão profunda do problema e solução customizada com escopo claro.","metadata":{"catalog_family":"vap","test_number":8,"question_number":25}},{"id":"987498f5-13c2-55a6-9437-4fb142796a61","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"71de4dab-9b0b-51c3-8951-66ebbc6b7c0b","option_code":"B","option_text":"Urgência fictícia sem justificativa.","metadata":{"catalog_family":"vap","test_number":8,"question_number":25}},{"id":"71b9d732-d078-554a-acdd-7a62cd2cf181","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"71de4dab-9b0b-51c3-8951-66ebbc6b7c0b","option_code":"C","option_text":"Somente uma tabela de preços sem contexto.","metadata":{"catalog_family":"vap","test_number":8,"question_number":25}},{"id":"bc781c4a-0825-50e5-b824-954896c8534a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"71de4dab-9b0b-51c3-8951-66ebbc6b7c0b","option_code":"D","option_text":"Proposta genérica idêntica para todos os clientes.","metadata":{"catalog_family":"vap","test_number":8,"question_number":25}},{"id":"13b5fc3b-f9e9-581d-9b6a-239709f034df","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ae7c7526-524f-5fc5-9d27-419235733d6d","option_code":"A","option_text":"Substituir toda evidência por emoção.","metadata":{"catalog_family":"vap","test_number":8,"question_number":26}},{"id":"51a69be3-3c99-555f-a536-16274f1f4ee4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ae7c7526-524f-5fc5-9d27-419235733d6d","option_code":"B","option_text":"Inventar resultados extraordinários para causar impacto.","metadata":{"catalog_family":"vap","test_number":8,"question_number":26}},{"id":"ddf12c40-d3df-52bd-b0b5-2743fdda639b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ae7c7526-524f-5fc5-9d27-419235733d6d","option_code":"C","option_text":"Usar histórias sem relação com o problema do prospect.","metadata":{"catalog_family":"vap","test_number":8,"question_number":26}},{"id":"e2a269c2-4d77-50cb-8042-528b05112bb0","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ae7c7526-524f-5fc5-9d27-419235733d6d","option_code":"D","option_text":"Narrar contexto, dor, busca, descoberta da solução e transformação, permitindo ao prospect se reconhecer na história.","metadata":{"catalog_family":"vap","test_number":8,"question_number":26}},{"id":"3323c2b7-4225-5cf0-8b6c-227e85732374","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"0b64671a-bd40-521f-ae8e-baef7058eabc","option_code":"A","option_text":"Definir próximo passo claro e, quando real, informar a validade da oferta.","metadata":{"catalog_family":"vap","test_number":8,"question_number":27}},{"id":"d287a949-9627-5bec-9490-7dcf3bf446ae","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"0b64671a-bd40-521f-ae8e-baef7058eabc","option_code":"B","option_text":"Criar prazo inexistente e dizer que “acaba hoje”.","metadata":{"catalog_family":"vap","test_number":8,"question_number":27}},{"id":"f8ce9e62-7d03-58ec-8554-ef792e4683f1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"0b64671a-bd40-521f-ae8e-baef7058eabc","option_code":"C","option_text":"Ocultar condições importantes até a assinatura.","metadata":{"catalog_family":"vap","test_number":8,"question_number":27}},{"id":"ec4b7dd4-61fb-54f1-beca-39563d365887","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"0b64671a-bd40-521f-ae8e-baef7058eabc","option_code":"D","option_text":"Afirmar que a concorrência já comprou sem evidência.","metadata":{"catalog_family":"vap","test_number":8,"question_number":27}},{"id":"c766f0c4-45a1-5b89-b6fd-91951b0435b0","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1fd13c6b-23e5-5f8b-ad14-e4e50c52fb49","option_code":"A","option_text":"Modelo 4P de equipes.","metadata":{"catalog_family":"vap","test_number":8,"question_number":28}},{"id":"bced2277-6838-5f96-acc0-f3f3f87f53e6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1fd13c6b-23e5-5f8b-ad14-e4e50c52fb49","option_code":"B","option_text":"Perfil DISC.","metadata":{"catalog_family":"vap","test_number":8,"question_number":28}},{"id":"b95f8c8c-140e-52ae-9aad-e0c7895601d6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1fd13c6b-23e5-5f8b-ad14-e4e50c52fb49","option_code":"C","option_text":"Janela de Johari.","metadata":{"catalog_family":"vap","test_number":8,"question_number":28}},{"id":"68aa18fd-ca5f-5f3e-9c18-d4a60ffc8a9a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1fd13c6b-23e5-5f8b-ad14-e4e50c52fb49","option_code":"D","option_text":"CTA claro.","metadata":{"catalog_family":"vap","test_number":8,"question_number":28}},{"id":"b8a9a8c5-d275-5e1b-9919-0948515290ac","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"58243333-92bf-5610-9fc5-9a45d6dfe408","option_code":"A","option_text":"Somente especificações técnicas e nenhuma história.","metadata":{"catalog_family":"vap","test_number":8,"question_number":29}},{"id":"a401ac04-2560-5997-9bfa-d92993a67ac3","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"58243333-92bf-5610-9fc5-9a45d6dfe408","option_code":"B","option_text":"Storytelling relevante, prova social robusta e follow-up estratégico.","metadata":{"catalog_family":"vap","test_number":8,"question_number":29}},{"id":"a6ca999a-3f49-5a53-b47f-c71fd6121c16","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"58243333-92bf-5610-9fc5-9a45d6dfe408","option_code":"C","option_text":"Desconto automático, pressão e proposta genérica.","metadata":{"catalog_family":"vap","test_number":8,"question_number":29}},{"id":"6272cdf3-a4e8-598b-b57c-aba021d5dedb","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"58243333-92bf-5610-9fc5-9a45d6dfe408","option_code":"D","option_text":"Uma única mensagem e ausência de acompanhamento.","metadata":{"catalog_family":"vap","test_number":8,"question_number":29}},{"id":"afcd7d20-dab3-5f7c-b1b1-4bce8340f99e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"aef01740-6e01-5716-9b1f-0d38cb0c62de","option_code":"A","option_text":"Automatizar toda interação sem revisão humana.","metadata":{"catalog_family":"vap","test_number":8,"question_number":30}},{"id":"8be829ed-1083-5d01-8917-84fcc7a23e7a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"aef01740-6e01-5716-9b1f-0d38cb0c62de","option_code":"B","option_text":"Usar gatilhos para substituir informação verdadeira.","metadata":{"catalog_family":"vap","test_number":8,"question_number":30}},{"id":"e08d35af-d9c2-5538-ba77-8b779a9fa7e1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"aef01740-6e01-5716-9b1f-0d38cb0c62de","option_code":"C","option_text":"Ocultar riscos para reduzir cortisol.","metadata":{"catalog_family":"vap","test_number":8,"question_number":30}},{"id":"ee5a9ed5-9bb6-5d1f-84e7-a60f77a7aa18","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"aef01740-6e01-5716-9b1f-0d38cb0c62de","option_code":"D","option_text":"Usar linguagem que gere conexão emocional e clareza lógica, respeitando a inteligência e a autonomia do cliente.","metadata":{"catalog_family":"vap","test_number":8,"question_number":30}}]$vap_options$::jsonb) as x(
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
  from jsonb_to_recordset($vap_keys$[{"question_id":"d2b60b0d-5072-54a8-8e1e-080881972333","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"O módulo usa neurociência para melhorar a jornada decisória preservando a autonomia do cliente.","source_reference":"Método VAP - Módulo 6","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":1,"source_label":"Neurovendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"4d16d5a7-7874-5a1e-bce9-8b5099b90e69","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"O modelo didático do VAP associa o cérebro reptiliano à segurança e às respostas mais básicas.","source_reference":"Método VAP - Módulo 6","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":2,"source_label":"Neurovendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"97ceb997-6d61-5ee6-af20-9d4a598b88f3","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"A","justification":"O VAP associa o sistema límbico à dimensão emocional da decisão de compra.","source_reference":"Método VAP - Módulo 6","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":3,"source_label":"Neurovendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"de1d41ab-8ffd-5686-b0a0-e07c2985765e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"O neocórtex aparece como camada de racionalização e análise lógica da decisão.","source_reference":"Método VAP - Módulo 6","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":4,"source_label":"Neurovendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"8e0b2c58-7f20-5ac3-b642-59bcf0b71e6c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"A","justification":"O VAP relaciona dopamina à antecipação de prazer e recompensa.","source_reference":"Método VAP - Módulo 6","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":5,"source_label":"Neurovendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"42527c63-1e8f-526c-b772-7648d8b69f20","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"A ocitocina é apresentada como relacionada à confiança e conexão.","source_reference":"Método VAP - Módulo 6","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":6,"source_label":"Neurovendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"8bdd5f98-a92a-5cff-8876-e05b2ccbe8dc","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"D","justification":"O material utiliza serotonina como referência didática para autoridade e status.","source_reference":"Método VAP - Módulo 6","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":7,"source_label":"Neurovendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"0d9d49aa-1cc0-579b-b9c7-16615167c861","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"O módulo orienta reduzir estresse e evitar pressão indevida, pois cortisol é associado a tensão.","source_reference":"Método VAP - Módulo 6","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":8,"source_label":"Neurovendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"5b57bc7d-cfe4-5aef-ad58-0c8374bdcbbd","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"O modelo associa Atenção ao reptiliano, Interesse ao límbico, Desejo a dopamina/ocitocina e Ação ao neocórtex.","source_reference":"Método VAP - Módulo 6","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":9,"source_label":"Neurovendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"8f7c1136-0798-5aaa-8d4d-21d69179e161","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"O VAP liga Desejo ao contexto emocional de recompensa antecipada e confiança.","source_reference":"Método VAP - Módulo 6","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":10,"source_label":"Neurovendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"f0c61ec4-49eb-50b1-8040-71d25c83f090","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"A","justification":"O material lista 12 gatilhos, entre eles reciprocidade, prova social, autoridade e pertencimento.","source_reference":"Método VAP - Módulo 6","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":11,"source_label":"Neurovendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"d652a570-fc46-533b-abac-e03f77cc7d6c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"O módulo faz distinção explícita entre escassez/urgência reais e manipulação.","source_reference":"Método VAP - Módulo 6","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":12,"source_label":"Neurovendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"d50b1da6-6eef-5367-9087-b1a66ab75e6d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"D","justification":"O modelo dos três cérebros enfatiza que diferentes sistemas participam simultaneamente da decisão.","source_reference":"Método VAP - Módulo 6","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":13,"source_label":"Neurovendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"94b1dcb3-fe85-519b-aaab-180dbdaefaa9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"Casos reais semelhantes funcionam como prova social ao mostrar que outras pessoas alcançaram resultado.","source_reference":"Método VAP - Módulo 6","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":14,"source_label":"Neurovendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"d0865b9e-cbd6-55fd-a3e6-f49541818ca9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"D","justification":"Neurovendas deve facilitar decisão consciente, não criar pressão baseada em informações falsas.","source_reference":"Método VAP - Módulo 6","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":15,"source_label":"Neurovendas","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"cacbda90-4f6c-5bee-a248-4303db220a1a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Copywriting é apresentado como comunicação estratégica que busca conversão e ação.","source_reference":"Método VAP - Módulo 7","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":16,"source_label":"Copywriting","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"5c1c8580-6939-5ffd-bb0c-583abb8db34c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"D","justification":"O VAP distingue copy orientado à ação de conteúdo predominantemente educativo/informativo.","source_reference":"Método VAP - Módulo 7","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":17,"source_label":"Copywriting","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"bff04171-6c85-5fbd-96ad-2eb427c500c3","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"A","justification":"AIDA corresponde a Atenção, Interesse, Desejo e Ação.","source_reference":"Método VAP - Módulo 7, Fórmulas de Copywriting","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":18,"source_label":"Copywriting","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"dd1c631f-360d-54ac-90dc-6fdc64409af7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"PAS nomeia a dor, amplia as consequências relevantes e apresenta a solução.","source_reference":"Método VAP - Módulo 7","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":19,"source_label":"Copywriting","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"488cb106-bb8a-5885-846d-fe1a6a525e97","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"D","justification":"BAB significa Before, After, Bridge: situação atual, futuro desejado e caminho entre ambos.","source_reference":"Método VAP - Módulo 7","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":20,"source_label":"Copywriting","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"6ea45bb3-3465-5130-abff-e745100468bf","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"O módulo apresenta 4Ps como Promessa, Prova, Proposta e Push.","source_reference":"Método VAP - Módulo 7","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":21,"source_label":"Copywriting","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"bf90136d-e910-58f3-b278-72c3378b14a9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"A","justification":"AIDA é indicada para capturar atenção e conduzir o leitor até uma ação em comunicações de abertura.","source_reference":"Método VAP - Módulo 7","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":22,"source_label":"Copywriting","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"433c216f-9e51-57c2-ada5-63ac710b5f97","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"PAS é indicada quando é útil explicitar problema, suas consequências e a solução.","source_reference":"Método VAP - Módulo 7","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":23,"source_label":"Copywriting","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"386c562f-1813-58cf-b906-5212fefd507f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"O modelo de post inclui hook, contexto, benefício, prova e CTA explícito.","source_reference":"Método VAP - Módulo 7","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":24,"source_label":"Copywriting","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"71de4dab-9b0b-51c3-8951-66ebbc6b7c0b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"A","justification":"A estrutura proposta conecta problema, solução, investimento, retorno, casos e pós-venda.","source_reference":"Método VAP - Módulo 7","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":25,"source_label":"Copywriting","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"ae7c7526-524f-5fc5-9d27-419235733d6d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"D","justification":"Storytelling de alto valor deve conectar a jornada de transformação a uma situação relevante e crível.","source_reference":"Método VAP - Módulo 7","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":26,"source_label":"Copywriting","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"0b64671a-bd40-521f-ae8e-baef7058eabc","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"A","justification":"O VAP recomenda urgência legítima baseada em condições reais, não em manipulação.","source_reference":"Método VAP - Módulo 7","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":27,"source_label":"Copywriting","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"1fd13c6b-23e5-5f8b-ad14-e4e50c52fb49","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"D","justification":"Copy eficaz orienta uma ação específica; sem CTA, a mensagem perde direção de conversão.","source_reference":"Método VAP - Módulo 7","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":28,"source_label":"Copywriting","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"58243333-92bf-5610-9fc5-9a45d6dfe408","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"O módulo associa vendas de alto valor a narrativa, evidência e sequência de acompanhamento.","source_reference":"Método VAP - Módulo 7","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":29,"source_label":"Copywriting","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}},{"question_id":"aef01740-6e01-5716-9b1f-0d38cb0c62de","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"D","justification":"A integração busca comunicar valor de forma persuasiva, natural e ética, combinando emoção e racionalidade.","source_reference":"Método VAP - Módulos 6 e 7","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":30,"source_label":"Integração VAP","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 8"}}]$vap_keys$::jsonb) as x(
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
  from jsonb_to_recordset($vap_version_questions$[{"id":"76701878-90c7-5433-a88e-dfb35aef28cf","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"d2b60b0d-5072-54a8-8e1e-080881972333","sequence_no":1,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":1}},{"id":"5e6d7733-4745-5320-9fb7-2b669b1f0a2f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"4d16d5a7-7874-5a1e-bce9-8b5099b90e69","sequence_no":2,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":2}},{"id":"8036ac65-d026-52ad-971f-c95e728bef71","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"97ceb997-6d61-5ee6-af20-9d4a598b88f3","sequence_no":3,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":3}},{"id":"e3201d2a-a728-520c-ac74-e3a5f85d0547","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"de1d41ab-8ffd-5686-b0a0-e07c2985765e","sequence_no":4,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":4}},{"id":"5ca94cbb-0d7c-5b7c-a8ad-c3d32a3a1e06","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"8e0b2c58-7f20-5ac3-b642-59bcf0b71e6c","sequence_no":5,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":5}},{"id":"00e1a3d2-e08a-5c32-ad9c-8cd36a7a2343","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"42527c63-1e8f-526c-b772-7648d8b69f20","sequence_no":6,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":6}},{"id":"4f2f1aec-e74b-5672-bea1-8cddebf78c55","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"8bdd5f98-a92a-5cff-8876-e05b2ccbe8dc","sequence_no":7,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":7}},{"id":"d9c501d3-3423-5fc5-bc97-4df8d2f6b2a2","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"0d9d49aa-1cc0-579b-b9c7-16615167c861","sequence_no":8,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":8}},{"id":"cdca10e3-591d-529c-b9c2-82bc6fd5b820","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"5b57bc7d-cfe4-5aef-ad58-0c8374bdcbbd","sequence_no":9,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":9}},{"id":"bae90799-de87-58f6-8749-4ac2563a98fc","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"8f7c1136-0798-5aaa-8d4d-21d69179e161","sequence_no":10,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":10}},{"id":"ea20bda5-7d00-5593-8f5c-bbfa6bd50682","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"f0c61ec4-49eb-50b1-8040-71d25c83f090","sequence_no":11,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":11}},{"id":"5d287b1a-2735-50f6-b85c-f399ccc7c206","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"d652a570-fc46-533b-abac-e03f77cc7d6c","sequence_no":12,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":12}},{"id":"7de5695a-63a3-5de0-9135-700f6b5ec75e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"d50b1da6-6eef-5367-9087-b1a66ab75e6d","sequence_no":13,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":13}},{"id":"18e53160-97e9-503d-9e43-e86e629b1933","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"94b1dcb3-fe85-519b-aaab-180dbdaefaa9","sequence_no":14,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":14}},{"id":"035bbf0d-c858-5bc4-8f28-43cbcf5ddc47","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"d0865b9e-cbd6-55fd-a3e6-f49541818ca9","sequence_no":15,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":15}},{"id":"08af1d31-3cb2-5f77-b2da-294dcbb0703f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"cacbda90-4f6c-5bee-a248-4303db220a1a","sequence_no":16,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":16}},{"id":"fa856d9e-2ac5-5a04-a45b-d8921fbd4252","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"5c1c8580-6939-5ffd-bb0c-583abb8db34c","sequence_no":17,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":17}},{"id":"0bf2a6d2-3072-5dd2-85d9-7be0b3fd4187","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"bff04171-6c85-5fbd-96ad-2eb427c500c3","sequence_no":18,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":18}},{"id":"64b833fe-4d54-5716-b261-ad012bd20418","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"dd1c631f-360d-54ac-90dc-6fdc64409af7","sequence_no":19,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":19}},{"id":"edd8ed58-9208-5f93-9a90-a62c1b77cea2","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"488cb106-bb8a-5885-846d-fe1a6a525e97","sequence_no":20,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":20}},{"id":"617ed15d-0e63-52c3-ae39-f364bd5096fa","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"6ea45bb3-3465-5130-abff-e745100468bf","sequence_no":21,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":21}},{"id":"a65fdd33-01fe-589b-882a-e4220c850334","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"bf90136d-e910-58f3-b278-72c3378b14a9","sequence_no":22,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":22}},{"id":"f7923b3a-1a20-554c-b9a8-bd40f6a77b44","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"433c216f-9e51-57c2-ada5-63ac710b5f97","sequence_no":23,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":23}},{"id":"5735a311-bc9a-539e-8b32-7e5f0f15f82e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"386c562f-1813-58cf-b906-5212fefd507f","sequence_no":24,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":24}},{"id":"5909d062-c20b-5231-8a6b-824e5f85f1ee","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"71de4dab-9b0b-51c3-8951-66ebbc6b7c0b","sequence_no":25,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":25}},{"id":"72d017dd-4a8a-5340-9440-9ac41e08da84","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"ae7c7526-524f-5fc5-9d27-419235733d6d","sequence_no":26,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":26}},{"id":"d4240da3-c4e7-5d7b-8de9-c431736f32ac","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"0b64671a-bd40-521f-ae8e-baef7058eabc","sequence_no":27,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":27}},{"id":"71851381-8a87-5000-9762-668d3c1bd1d2","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"1fd13c6b-23e5-5f8b-ad14-e4e50c52fb49","sequence_no":28,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":28}},{"id":"bc95ed20-e36c-598c-90ef-2d75812fc076","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"58243333-92bf-5610-9fc5-9a45d6dfe408","sequence_no":29,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":29}},{"id":"2b81c3cb-bee3-5162-bb06-8e3bac0ad5bf","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"34b181a4-c718-555e-8909-754d58bbccf2","question_id":"aef01740-6e01-5716-9b1f-0d38cb0c62de","sequence_no":30,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":8,"question_number":30}}]$vap_version_questions$::jsonb) as x(
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
  v_test_id uuid := '596353c9-73e3-59c6-81a3-796ac376f7aa'::uuid;
  v_version_id uuid := '34b181a4-c718-555e-8909-754d58bbccf2'::uuid;
begin
  if (
    select count(*)
    from public.competency_domains c
    where c.organization_id = v_org_id
      and c.code in ('vap_neurovendas','vap_copywriting')
      and c.status = 'draft'
      and c.is_legal = false
      and c.archived_at is null
  ) <> 2 then
    raise exception 'VAP Teste 8 pós-condição: esperado 2 novas competências VAP em draft.';
  end if;

  if not exists (
    select 1
    from public.competency_domains c
    where c.id = '43ab5826-1867-50ec-9c1d-2d0b8f5f5fe0'::uuid
      and c.organization_id = v_org_id
      and c.code = 'vap_integracao'
      and c.archived_at is null
  ) then
    raise exception 'VAP Teste 8 pós-condição: competência de integração reutilizada não está disponível.';
  end if;

  if not exists (
    select 1
    from public.assessment_tests t
    where t.id = v_test_id
      and t.organization_id = v_org_id
      and t.code = 'teste_8_vap_neurovendas_copywriting'
      and t.sequence_no = 8
      and t.question_count = 30
      and t.status = 'draft'
      and t.archived_at is null
  ) then
    raise exception 'VAP Teste 8 pós-condição: identidade do teste não confere.';
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
    raise exception 'VAP Teste 8 pós-condição: versão draft/fail-closed não confere.';
  end if;

  if (
    select count(*)
    from public.assessment_questions q
    where q.organization_id = v_org_id
      and q.code like 'vap_t8_q%'
      and q.status = 'reviewed'
      and q.archived_at is null
  ) <> 30 then
    raise exception 'VAP Teste 8 pós-condição: esperado 30 questões reviewed.';
  end if;

  if (
    select count(*)
    from public.assessment_version_questions avq
    where avq.organization_id = v_org_id
      and avq.test_version_id = v_version_id
      and avq.is_required = true
      and avq.archived_at is null
  ) <> 30 then
    raise exception 'VAP Teste 8 pós-condição: esperado 30 vínculos obrigatórios.';
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
    raise exception 'VAP Teste 8 pós-condição: sequência de questões não é 1..30.';
  end if;

  if (
    select count(*)
    from public.assessment_questions q
    join public.assessment_version_questions avq
      on avq.question_id = q.id
     and avq.organization_id = q.organization_id
    where avq.test_version_id = v_version_id
      and q.block_code = 'neurovendas'
      and q.archived_at is null
      and avq.archived_at is null
  ) <> 15
  or (
    select count(*)
    from public.assessment_questions q
    join public.assessment_version_questions avq
      on avq.question_id = q.id
     and avq.organization_id = q.organization_id
    where avq.test_version_id = v_version_id
      and q.block_code = 'copywriting'
      and q.archived_at is null
      and avq.archived_at is null
  ) <> 14
  or (
    select count(*)
    from public.assessment_questions q
    join public.assessment_version_questions avq
      on avq.question_id = q.id
     and avq.organization_id = q.organization_id
    where avq.test_version_id = v_version_id
      and q.block_code = 'integracao_vap'
      and q.archived_at is null
      and avq.archived_at is null
  ) <> 1 then
    raise exception 'VAP Teste 8 pós-condição: mapeamento 15/14/1 não confere.';
  end if;

  if (
    select count(*)
    from public.assessment_question_options o
    join public.assessment_version_questions avq
      on avq.question_id = o.question_id
     and avq.organization_id = o.organization_id
    where avq.test_version_id = v_version_id
      and avq.archived_at is null
      and o.archived_at is null
  ) <> 120 then
    raise exception 'VAP Teste 8 pós-condição: esperado 120 alternativas.';
  end if;

  if exists (
    select 1
    from (
      select avq.question_id, count(o.id) as option_count
      from public.assessment_version_questions avq
      left join public.assessment_question_options o
        on o.question_id = avq.question_id
       and o.organization_id = avq.organization_id
       and o.archived_at is null
      where avq.organization_id = v_org_id
        and avq.test_version_id = v_version_id
        and avq.archived_at is null
      group by avq.question_id
    ) x
    where x.option_count <> 4
  ) then
    raise exception 'VAP Teste 8 pós-condição: alguma questão não possui exatamente 4 alternativas.';
  end if;

  if (
    select count(*)
    from private.assessment_question_keys k
    join public.assessment_version_questions avq
      on avq.question_id = k.question_id
     and avq.organization_id = k.organization_id
    where avq.test_version_id = v_version_id
      and avq.archived_at is null
  ) <> 30 then
    raise exception 'VAP Teste 8 pós-condição: esperado 30 gabaritos privados.';
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
    where avq.test_version_id = v_version_id
      and avq.archived_at is null
      and o.id is null
  ) then
    raise exception 'VAP Teste 8 pós-condição: existe gabarito sem alternativa correspondente.';
  end if;

  if exists (
    select 1
    from private.assessment_question_keys k
    join public.assessment_version_questions avq
      on avq.question_id = k.question_id
     and avq.organization_id = k.organization_id
    where avq.test_version_id = v_version_id
      and avq.archived_at is null
      and k.is_critical = true
  ) then
    raise exception 'VAP Teste 8 pós-condição: criticidade foi criada sem base no material.';
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
    raise exception 'VAP Teste 8 pós-condição: vínculo com fonte primária não confere.';
  end if;

  if exists (
    select 1
    from private.assessment_test_access_grants g
    where g.organization_id = v_org_id
      and g.test_id = v_test_id
      and g.archived_at is null
  ) then
    raise exception 'VAP Teste 8 pós-condição: nenhum grant deveria ter sido criado.';
  end if;

  if exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.test_id = v_test_id
      and a.archived_at is null
  ) then
    raise exception 'VAP Teste 8 pós-condição: nenhuma tentativa deveria existir.';
  end if;

  if (
    select count(*)
    from public.assessment_tests t
    where t.organization_id = v_org_id
      and t.sequence_no between 1 and 7
      and t.archived_at is null
  ) <> 7 then
    raise exception 'VAP Teste 8 pós-condição: catálogo-base 1..7 foi alterado.';
  end if;
end
$post$;

commit;
