-- ============================================================================
-- RF Performance — Avaliações e Certificações
-- Catálogo Ampliado — Método VAP — Teste 6
-- Fase 2A — cadastro em RASCUNHO para homologação controlada
--
-- Fonte primária:
--   O Método VAP — Vendedor de Alta Performance
--   1ª edição em português · Rio de Janeiro, 2024
--   ISBN 978-65-01-07964-6
--   SHA-256: d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84
--
-- Documento de autoria das questões:
--   Sistema de Certificação Comercial — Método VAP
--   Testes 6 a 10 · versão para homologação interna · Agosto de 2026
--   SHA-256: 8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820
--
-- SEGURANÇA / ESCOPO
--   - Não altera Testes 1 a 5.
--   - Não cria grant de acesso.
--   - Não publica o Teste 6.
--   - Não cria tentativa.
--   - Gabarito permanece em private.assessment_question_keys.
--   - O corte 100/100 nesta versão é propositalmente fail-closed enquanto
--     a política de aprovação do novo catálogo não for definida.
-- ============================================================================

begin;

-- --------------------------------------------------------------------------
-- 0. Guardas fail-closed
-- --------------------------------------------------------------------------
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
    raise exception 'VAP Teste 6 abortado: organização RF esperada não localizada/ativa.';
  end if;

  if (
    select count(*)
    from public.assessment_tests t
    where t.organization_id = v_org_id
      and t.archived_at is null
      and t.sequence_no between 1 and 5
  ) <> 5 then
    raise exception 'VAP Teste 6 abortado: catálogo-base Testes 1 a 5 não está íntegro.';
  end if;

  if exists (
    select 1
    from public.assessment_tests t
    where t.organization_id = v_org_id
      and t.archived_at is null
      and (
        t.sequence_no = 6
        or t.code = 'teste_6_vap_fundamentos_mentalidade_valor'
        or t.id = '77c2984e-c0e8-5829-94ba-fcb0076ce8b6'::uuid
      )
  ) then
    raise exception 'VAP Teste 6 abortado: já existe teste ocupando a identidade/seq. 6.';
  end if;

  if exists (
    select 1
    from public.competency_domains c
    where c.organization_id = v_org_id
      and c.archived_at is null
      and (
        c.sequence_no between 31 and 34
        or c.code in ('vap_fundamentos','vap_mentalidade','vap_valor_venda','vap_integracao')
        or c.id in (
          '3651c23e-cc6c-5643-810a-81da8ecc8e0a'::uuid,
          'a20218e4-59bc-5f9d-b77b-3e04a6962991'::uuid,
          '968d1a3e-1f83-5498-a9e2-7e943a59b2e6'::uuid,
          '43ab5826-1867-50ec-9c1d-2d0b8f5f5fe0'::uuid
        )
      )
  ) then
    raise exception 'VAP Teste 6 abortado: identidade/sequência das competências VAP já está ocupada.';
  end if;

  if exists (
    select 1
    from public.source_materials sm
    where sm.organization_id = v_org_id
      and sm.archived_at is null
      and (
        sm.code = 'metodo_vap_vendedor_alta_performance'
        or sm.id = '2831b27b-035b-54fd-a3cc-d8a23a509a82'::uuid
      )
  ) then
    raise exception 'VAP Teste 6 abortado: fonte Método VAP já está cadastrada; revisar antes de prosseguir.';
  end if;
end
$guard$;

-- --------------------------------------------------------------------------
-- 1. Fonte versionada — Método VAP
-- --------------------------------------------------------------------------
insert into public.source_materials (
  id,
  organization_id,
  code,
  title,
  description,
  material_type,
  issuer,
  status,
  metadata
)
values (
  '2831b27b-035b-54fd-a3cc-d8a23a509a82'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'metodo_vap_vendedor_alta_performance',
  'O Método VAP — Vendedor de Alta Performance',
  'Treinamento completo com 10 módulos + 1 extra e 55 aulas. 1ª edição em português, Rio de Janeiro, 2024. ISBN 978-65-01-07964-6.',
  'book',
  'Cleverson Eduardo da Costa',
  'active',
  jsonb_build_object(
    'catalog_family', 'vap',
    'edition', '1ª edição em português',
    'publication_place', 'Rio de Janeiro',
    'publication_year', 2024,
    'isbn', '978-65-01-07964-6',
    'source_filename', 'MÉTODO VAP.pdf',
    'content_sha256', 'd28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84'
  )
);

insert into public.source_material_versions (
  id,
  organization_id,
  source_material_id,
  version_code,
  version_no,
  status,
  effective_from,
  effective_until,
  published_at,
  source_date,
  content_sha256,
  source_locator,
  metadata
)
values (
  'a20ad8ff-b3f8-5106-b96e-346fa342d098'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '2831b27b-035b-54fd-a3cc-d8a23a509a82'::uuid,
  '1a-edicao-2024',
  1,
  'active',
  null,
  null,
  null,
  null,
  'd28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84',
  jsonb_build_object(
    'file_name', 'MÉTODO VAP.pdf',
    'edition', '1ª edição em português',
    'publication_place', 'Rio de Janeiro',
    'publication_year', 2024,
    'isbn', '978-65-01-07964-6'
  ),
  jsonb_build_object(
    'catalog_family', 'vap',
    'version_identity_basis', 'edition_year_and_sha256',
    'source_content_sha256', 'd28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84'
  )
);

-- --------------------------------------------------------------------------
-- 2. Competências específicas do catálogo VAP
--
-- O documento declara 10 Fundamentos + 10 Mentalidade + 10 Valor e Venda.
-- O próprio gabarito, porém, rotula a questão 30 como "Integração VAP".
-- A modelagem preserva ambos:
--   q1-10  -> VAP Fundamentos
--   q11-20 -> VAP Mentalidade
--   q21-29 -> VAP Valor e Venda
--   q30    -> VAP Integração
-- --------------------------------------------------------------------------
with payload as (
  select *
  from jsonb_to_recordset($vap_competencies$[{"id":"3651c23e-cc6c-5643-810a-81da8ecc8e0a","code":"vap_fundamentos","sequence_no":31,"name":"VAP — Fundamentos","description":"Fundamentos, aplicação e processo do Método VAP.","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","domain_type":"knowledge","is_legal":false,"default_weight":0,"status":"draft","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"draft_catalog"}},{"id":"a20218e4-59bc-5f9d-b77b-3e04a6962991","code":"vap_mentalidade","sequence_no":32,"name":"VAP — Mentalidade","description":"Mentalidade, disciplina, resiliência e aprendizagem no Método VAP.","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","domain_type":"knowledge","is_legal":false,"default_weight":0,"status":"draft","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"draft_catalog"}},{"id":"968d1a3e-1f83-5498-a9e2-7e943a59b2e6","code":"vap_valor_venda","sequence_no":33,"name":"VAP — Valor e Venda","description":"Construção, comunicação e ampliação do valor percebido no Método VAP.","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","domain_type":"knowledge","is_legal":false,"default_weight":0,"status":"draft","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"draft_catalog"}},{"id":"43ab5826-1867-50ec-9c1d-2d0b8f5f5fe0","code":"vap_integracao","sequence_no":34,"name":"VAP — Integração","description":"Integração entre processo, mentalidade e construção de valor no Método VAP.","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","domain_type":"knowledge","is_legal":false,"default_weight":0,"status":"draft","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"draft_catalog"}}]$vap_competencies$::jsonb) as x(
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
  id,
  organization_id,
  code,
  sequence_no,
  name,
  description,
  domain_type,
  is_legal,
  default_weight,
  status,
  metadata
)
select
  id,
  organization_id,
  code,
  sequence_no,
  name,
  description,
  domain_type,
  is_legal,
  default_weight,
  status,
  metadata
from payload;

-- --------------------------------------------------------------------------
-- 3. Teste 6 e versão 2026.08-v1 em RASCUNHO
-- --------------------------------------------------------------------------
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
  '77c2984e-c0e8-5829-94ba-fcb0076ce8b6'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'teste_6_vap_fundamentos_mentalidade_valor',
  6,
  'Teste 6 — Fundamentos, Mentalidade e Valor',
  'Avaliação do Método VAP sobre fundamentos e aplicação, mentalidade, valor e venda, com integração dos Módulos 1 a 3.',
  'beginner_intermediate',
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
    'source_level_label', 'Fundamental / Intermediário',
    'source_material_code', 'metodo_vap_vendedor_alta_performance',
    'source_content_sha256', 'd28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84',
    'authoring_document', 'Sistema de Certificação Comercial — Método VAP — Testes 6 a 10',
    'authoring_document_sha256', '8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820',
    'authoring_document_date_label', 'Agosto de 2026',
    'declared_distribution', jsonb_build_object(
      'fundamentos', 10,
      'mentalidade', 10,
      'valor_e_venda', 10
    ),
    'actual_gabarito_labels', jsonb_build_object(
      'fundamentos_e_aplicacao', 10,
      'mentalidade', 10,
      'valor_e_venda', 9,
      'integracao_vap', 1
    ),
    'homologation_status', 'draft_catalog'
  )
);

insert into public.assessment_test_versions (
  id,
  organization_id,
  test_id,
  version_code,
  version_no,
  status,
  passing_score,
  legal_min_score,
  question_count,
  randomize_questions,
  randomize_options,
  show_review_after_submit,
  valid_from,
  valid_until,
  published_at,
  normative_basis,
  metadata
)
values (
  '07ed48aa-b1ac-547f-8fa5-a93c1441cc3c'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '77c2984e-c0e8-5829-94ba-fcb0076ce8b6'::uuid,
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

-- --------------------------------------------------------------------------
-- 4. Vínculo da versão à fonte primária
-- --------------------------------------------------------------------------
insert into public.assessment_version_sources (
  id,
  organization_id,
  test_version_id,
  source_material_version_id,
  relation_type,
  is_required,
  notes,
  metadata
)
values (
  '5ee9d361-29b9-5bad-9a96-50c9536b652c'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '07ed48aa-b1ac-547f-8fa5-a93c1441cc3c'::uuid,
  'a20ad8ff-b3f8-5106-b96e-346fa342d098'::uuid,
  'primary',
  true,
  'Fonte primária dos conteúdos avaliados no Teste 6 do Método VAP.',
  jsonb_build_object(
    'catalog_family', 'vap',
    'test_number', 6,
    'source_content_sha256', 'd28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84'
  )
);

-- --------------------------------------------------------------------------
-- 5. Questões públicas
-- --------------------------------------------------------------------------
with payload as (
  select *
  from jsonb_to_recordset($vap_questions$[{"id":"5ad9c1bd-bc8e-593f-aa82-50eb965e5c16","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q01","competency_id":"3651c23e-cc6c-5643-810a-81da8ecc8e0a","block_code":"fundamentos_vap","prompt":"No Método VAP, o que as letras V, A e P representam?","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":1,"source_label":"Fundamentos do VAP","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"59715a0a-0a92-5cd5-b43a-7a622e48aa75","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q02","competency_id":"3651c23e-cc6c-5643-810a-81da8ecc8e0a","block_code":"fundamentos_vap","prompt":"Qual afirmação traduz melhor a ideia central de que o VAP é um processo replicável?","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":2,"source_label":"Fundamentos do VAP","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"822062ce-558a-598e-80d9-da972ef24dd7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q03","competency_id":"3651c23e-cc6c-5643-810a-81da8ecc8e0a","block_code":"fundamentos_vap","prompt":"Qual alternativa contém os cinco pilares interdependentes apresentados pelo Método VAP?","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":3,"source_label":"Fundamentos do VAP","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"b8b566d4-6545-5975-a7de-7654c55d8294","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q04","competency_id":"3651c23e-cc6c-5643-810a-81da8ecc8e0a","block_code":"fundamentos_vap","prompt":"No Framework VAP de cinco passos, a sequência V-A-P-P-F corresponde a:","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":4,"source_label":"Fundamentos do VAP","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"1c94f4c9-ad1d-5e6f-b444-f2a7319a92fa","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q05","competency_id":"3651c23e-cc6c-5643-810a-81da8ecc8e0a","block_code":"fundamentos_vap","prompt":"Por que o VAP é descrito como um método sistêmico?","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":5,"source_label":"Fundamentos do VAP","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"1b61b8b1-98d1-597c-ac28-0755ae81ffa3","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q06","competency_id":"3651c23e-cc6c-5643-810a-81da8ecc8e0a","block_code":"aplicacao_vap","prompt":"Um vendedor quer aplicar tudo o que aprendeu no mesmo dia, alterando simultaneamente abordagem, SPIN, objeções, DISC e IA. Segundo a aplicação prática do VAP, qual conduta é mais adequada?","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":6,"source_label":"Aplicação do VAP","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"12631282-2533-5f14-ac99-2d87c6e5acd0","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q07","competency_id":"3651c23e-cc6c-5643-810a-81da8ecc8e0a","block_code":"aplicacao_vap","prompt":"Quais são os quatro níveis da aplicação prática do Método VAP?","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":7,"source_label":"Aplicação do VAP","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"4c0e1ef6-3f2f-5f36-8d4e-7cfdbbb390a1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q08","competency_id":"3651c23e-cc6c-5643-810a-81da8ecc8e0a","block_code":"aplicacao_vap","prompt":"Na fase de Diagnóstico da aplicação do VAP, o vendedor deve primeiro:","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":8,"source_label":"Aplicação do VAP","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"990d7fc7-cf7c-5c6f-acaf-0278dd53af68","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q09","competency_id":"3651c23e-cc6c-5643-810a-81da8ecc8e0a","block_code":"fundamentos_vap","prompt":"No aprofundamento do Framework VAP, qual comportamento representa melhor a etapa Processo?","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":9,"source_label":"Fundamentos do VAP","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"bd596ca3-66d2-5b32-8405-a00a09bc428f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q10","competency_id":"3651c23e-cc6c-5643-810a-81da8ecc8e0a","block_code":"fundamentos_vap","prompt":"Qual é a principal lição dos cases apresentados no primeiro módulo do VAP?","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":10,"source_label":"Fundamentos do VAP","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"83ece62c-d948-5342-b3fc-76bd53e5be9e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q11","competency_id":"a20218e4-59bc-5f9d-b77b-3e04a6962991","block_code":"mentalidade_vap","prompt":"O que significa “responsabilidade radical” na mentalidade VAP?","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":11,"source_label":"Mentalidade VAP","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"e64356e8-84a2-5f0d-897b-549e45cb05ad","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q12","competency_id":"a20218e4-59bc-5f9d-b77b-3e04a6962991","block_code":"mentalidade_vap","prompt":"Por que o VAP orienta foco em processo, e não obsessão exclusiva pelo resultado?","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":12,"source_label":"Mentalidade VAP","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"4bc5f909-6d6e-5a9d-8c6b-08e01e04dfe9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q13","competency_id":"a20218e4-59bc-5f9d-b77b-3e04a6962991","block_code":"mentalidade_vap","prompt":"Na mentalidade VAP, como uma rejeição deve ser interpretada?","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":13,"source_label":"Mentalidade VAP","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"d8a26e4f-bfc1-562a-900f-5cd48b8b41ea","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q14","competency_id":"a20218e4-59bc-5f9d-b77b-3e04a6962991","block_code":"mentalidade_vap","prompt":"Qual afirmação está alinhada ao pilar “tolerância à incerteza”?","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":14,"source_label":"Mentalidade VAP","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"9838a846-d255-59bd-a921-f9377fd410cd","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q15","competency_id":"a20218e4-59bc-5f9d-b77b-3e04a6962991","block_code":"mentalidade_vap","prompt":"No Método ABCDE usado para trabalhar crenças, o que representa a letra D?","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":15,"source_label":"Mentalidade VAP","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"512d7c21-fd10-5ee4-82ff-584167f301aa","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q16","competency_id":"a20218e4-59bc-5f9d-b77b-3e04a6962991","block_code":"mentalidade_vap","prompt":"Qual é a ordem correta do Método ABCDE apresentado no VAP?","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":16,"source_label":"Mentalidade VAP","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"93e6dc7a-4137-595e-b5bf-ac77ee11c335","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q17","competency_id":"a20218e4-59bc-5f9d-b77b-3e04a6962991","block_code":"mentalidade_vap","prompt":"Segundo o VAP, o que caracteriza uma mentalidade “inabalável”?","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":17,"source_label":"Mentalidade VAP","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"250e481d-198e-5a43-a0c5-150f1c9c5dd1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q18","competency_id":"a20218e4-59bc-5f9d-b77b-3e04a6962991","block_code":"mentalidade_vap","prompt":"Qual prática faz parte da rotina de estado sugerida no VAP?","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":18,"source_label":"Mentalidade VAP","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"9293e359-d7d1-5f6c-8a12-45f4b3fd19b5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q19","competency_id":"a20218e4-59bc-5f9d-b77b-3e04a6962991","block_code":"mentalidade_vap","prompt":"O diário de vendas sugerido pelo VAP deve registrar, ao final do dia:","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":19,"source_label":"Mentalidade VAP","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"1b693f45-8309-5d23-956c-6758998a8961","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q20","competency_id":"a20218e4-59bc-5f9d-b77b-3e04a6962991","block_code":"mentalidade_vap","prompt":"Como o Método VAP relaciona disciplina, resiliência e motivação?","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":20,"source_label":"Mentalidade VAP","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"f2d7f9d5-2157-5b7f-935b-f787a0c7c316","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q21","competency_id":"968d1a3e-1f83-5498-a9e2-7e943a59b2e6","block_code":"valor_venda","prompt":"No VAP, qual princípio deve orientar a conversa antes de entrar em preço?","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":21,"source_label":"Valor e Venda","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"528f9266-812e-5405-a675-18de28cd0462","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q22","competency_id":"968d1a3e-1f83-5498-a9e2-7e943a59b2e6","block_code":"valor_venda","prompt":"O modelo BRIDGE é utilizado para:","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":22,"source_label":"Valor e Venda","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"56e780f9-ea7f-5293-9432-0b6613b24f7c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q23","competency_id":"968d1a3e-1f83-5498-a9e2-7e943a59b2e6","block_code":"valor_venda","prompt":"Qual item NÃO pertence ao modelo BRIDGE?","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":23,"source_label":"Valor e Venda","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"422c6e5a-624d-5f01-bdb2-2410088863d9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q24","competency_id":"968d1a3e-1f83-5498-a9e2-7e943a59b2e6","block_code":"valor_venda","prompt":"Um cliente diz “está caro” logo após ouvir a proposta. Qual reação é mais coerente com o Método VAP?","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":24,"source_label":"Valor e Venda","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"9f350a7b-e50b-5013-85bb-08732c6f3155","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q25","competency_id":"968d1a3e-1f83-5498-a9e2-7e943a59b2e6","block_code":"valor_venda","prompt":"Quais são as seis estratégias de aumento de valor percebido destacadas no VAP?","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":25,"source_label":"Valor e Venda","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"17a7a758-f268-5726-a0bc-fdfc05661437","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q26","competency_id":"968d1a3e-1f83-5498-a9e2-7e943a59b2e6","block_code":"valor_venda","prompt":"Na Pirâmide de Valor do VAP, qual é a sequência dos quatro níveis?","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":26,"source_label":"Valor e Venda","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"3f88a7ea-2730-5f37-80a6-7cbf49739dcb","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q27","competency_id":"968d1a3e-1f83-5498-a9e2-7e943a59b2e6","block_code":"valor_venda","prompt":"Qual exemplo representa melhor a estratégia de prova social?","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":27,"source_label":"Valor e Venda","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"caefa532-20b4-5fd7-bff9-7385358cc6a4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q28","competency_id":"968d1a3e-1f83-5498-a9e2-7e943a59b2e6","block_code":"valor_venda","prompt":"Na lógica do VAP, o ROI é usado principalmente para:","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":28,"source_label":"Valor e Venda","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"104c1a6f-40ec-519f-b218-81a16b6ffa6f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q29","competency_id":"968d1a3e-1f83-5498-a9e2-7e943a59b2e6","block_code":"valor_venda","prompt":"O que significa subir do nível “Esperado” para “Ampliado” na Pirâmide de Valor?","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":29,"source_label":"Valor e Venda","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}},{"id":"170242de-b9cc-546d-b816-53664f13bc2b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"vap_t6_q30","competency_id":"43ab5826-1867-50ec-9c1d-2d0b8f5f5fe0","block_code":"integracao_vap","prompt":"Qual conduta sintetiza melhor a integração entre os Módulos 1, 2 e 3?","question_type":"single_choice","difficulty":"beginner_intermediate","content_version":"2026.08-v1","legal_review_date":null,"status":"reviewed","metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":30,"source_label":"Integração VAP","source_material_code":"metodo_vap_vendedor_alta_performance","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document":"Sistema de Certificação Comercial — Método VAP — Testes 6 a 10","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","homologation_status":"internal_review"}}]$vap_questions$::jsonb) as x(
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
  id,
  organization_id,
  code,
  competency_id,
  block_code,
  prompt,
  question_type,
  difficulty,
  content_version,
  legal_review_date,
  status,
  metadata
)
select
  id,
  organization_id,
  code,
  competency_id,
  block_code,
  prompt,
  question_type,
  difficulty,
  content_version,
  legal_review_date,
  status,
  metadata
from payload;

-- --------------------------------------------------------------------------
-- 6. Alternativas públicas — sem marcação de resposta correta
-- --------------------------------------------------------------------------
with payload as (
  select *
  from jsonb_to_recordset($vap_options$[{"id":"c4fdc2a4-4a7f-5556-82df-da897c44110d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"5ad9c1bd-bc8e-593f-aa82-50eb965e5c16","option_code":"A","option_text":"Valor, Autoridade e Planejamento.","metadata":{"catalog_family":"vap","test_number":6,"question_number":1}},{"id":"f48ac44f-3c4a-5477-b5a0-f65ea87ef586","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"5ad9c1bd-bc8e-593f-aa82-50eb965e5c16","option_code":"B","option_text":"Valor, Abordagem e Performance.","metadata":{"catalog_family":"vap","test_number":6,"question_number":1}},{"id":"ec68aa1e-61d4-589a-9b69-64fd48aff11e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"5ad9c1bd-bc8e-593f-aa82-50eb965e5c16","option_code":"C","option_text":"Visão, Atitude e Produtividade.","metadata":{"catalog_family":"vap","test_number":6,"question_number":1}},{"id":"0a5ef585-61da-5f1d-8cd5-8ea86211e0fe","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"5ad9c1bd-bc8e-593f-aa82-50eb965e5c16","option_code":"D","option_text":"Venda, Análise e Persuasão.","metadata":{"catalog_family":"vap","test_number":6,"question_number":1}},{"id":"7ad03b02-818f-536c-a32c-3f7f3b1a36e4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"59715a0a-0a92-5cd5-b43a-7a622e48aa75","option_code":"A","option_text":"O método dispensa medição porque a experiência individual é suficiente.","metadata":{"catalog_family":"vap","test_number":6,"question_number":2}},{"id":"8a711b6f-e923-5b2c-aa50-bc2c9f887f9c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"59715a0a-0a92-5cd5-b43a-7a622e48aa75","option_code":"B","option_text":"Resultados consistentes podem ser construídos pela execução disciplinada de etapas, e não apenas por talento ou carisma.","metadata":{"catalog_family":"vap","test_number":6,"question_number":2}},{"id":"6a7d7690-6aff-5f39-a481-7428f03a4fff","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"59715a0a-0a92-5cd5-b43a-7a622e48aa75","option_code":"C","option_text":"Cada vendedor deve improvisar um processo completamente diferente a cada cliente.","metadata":{"catalog_family":"vap","test_number":6,"question_number":2}},{"id":"74d7e69d-0738-5bea-aa22-0e1acfbcecea","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"59715a0a-0a92-5cd5-b43a-7a622e48aa75","option_code":"D","option_text":"Somente vendedores naturalmente carismáticos conseguem aplicar o método.","metadata":{"catalog_family":"vap","test_number":6,"question_number":2}},{"id":"a05d60f7-5cde-5bc3-a3de-ebfd47d12f89","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"822062ce-558a-598e-80d9-da972ef24dd7","option_code":"A","option_text":"Prospecção, Preço, Produto, Pressão e Pós-venda.","metadata":{"catalog_family":"vap","test_number":6,"question_number":3}},{"id":"969b55b7-8c0b-5474-bdbb-1b477a0b2bf5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"822062ce-558a-598e-80d9-da972ef24dd7","option_code":"B","option_text":"Meta, Comissão, Script, Tecnologia e Concorrência.","metadata":{"catalog_family":"vap","test_number":6,"question_number":3}},{"id":"d31dc5f8-d1a8-5ae3-9cb8-a67bde37561a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"822062ce-558a-598e-80d9-da972ef24dd7","option_code":"C","option_text":"Mentalidade, Conhecimento do Cliente, Processo Estruturado, Comunicação Persuasiva e Melhoria Contínua.","metadata":{"catalog_family":"vap","test_number":6,"question_number":3}},{"id":"ea53b4ba-8f37-5682-9dc1-446b864fda71","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"822062ce-558a-598e-80d9-da972ef24dd7","option_code":"D","option_text":"Carisma, Improviso, Desconto, Urgência e Fechamento.","metadata":{"catalog_family":"vap","test_number":6,"question_number":3}},{"id":"3f813d3f-ecc2-5946-9163-87c07cf879ff","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"b8b566d4-6545-5975-a7de-7654c55d8294","option_code":"A","option_text":"Valor, Abordagem, Processo, Persuasão e Feedback.","metadata":{"catalog_family":"vap","test_number":6,"question_number":4}},{"id":"aa2aad5f-5b4e-56b9-a38d-3f381fac7077","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"b8b566d4-6545-5975-a7de-7654c55d8294","option_code":"B","option_text":"Visão, Ação, Produto, Preço e Fechamento.","metadata":{"catalog_family":"vap","test_number":6,"question_number":4}},{"id":"b874775f-7714-5e12-9897-6c9e0ccf37dd","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"b8b566d4-6545-5975-a7de-7654c55d8294","option_code":"C","option_text":"Valor, Análise, Proposta, Pressão e Follow-up.","metadata":{"catalog_family":"vap","test_number":6,"question_number":4}},{"id":"e5a983c5-49b0-5ee9-8f34-97c4b4496862","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"b8b566d4-6545-5975-a7de-7654c55d8294","option_code":"D","option_text":"Venda, Abordagem, Performance, Planejamento e Fidelização.","metadata":{"catalog_family":"vap","test_number":6,"question_number":4}},{"id":"81cb679c-bc84-5477-a014-14a0bb6e6311","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1c94f4c9-ad1d-5e6f-b444-f2a7319a92fa","option_code":"A","option_text":"Porque se concentra exclusivamente em metas financeiras.","metadata":{"catalog_family":"vap","test_number":6,"question_number":5}},{"id":"1a027e96-d9a9-584c-b50e-ee4f0a820dd7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1c94f4c9-ad1d-5e6f-b444-f2a7319a92fa","option_code":"B","option_text":"Porque substitui a comunicação humana por automação.","metadata":{"catalog_family":"vap","test_number":6,"question_number":5}},{"id":"13f9ec04-6779-5f38-990e-0daf715a8eef","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1c94f4c9-ad1d-5e6f-b444-f2a7319a92fa","option_code":"C","option_text":"Porque cobre o processo de venda de ponta a ponta, e não apenas técnicas isoladas de fechamento ou objeção.","metadata":{"catalog_family":"vap","test_number":6,"question_number":5}},{"id":"6abf87d8-c7d0-574b-a30d-9892c55ef124","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1c94f4c9-ad1d-5e6f-b444-f2a7319a92fa","option_code":"D","option_text":"Porque se limita à etapa de prospecção digital.","metadata":{"catalog_family":"vap","test_number":6,"question_number":5}},{"id":"dbf1d96c-78a3-5965-9ba2-fabb7117b5e5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1b61b8b1-98d1-597c-ac28-0755ae81ffa3","option_code":"A","option_text":"Ignorar o diagnóstico inicial e começar pelas ferramentas de IA.","metadata":{"catalog_family":"vap","test_number":6,"question_number":6}},{"id":"d57e640f-730a-5e69-a0f4-2d92b4f088c2","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1b61b8b1-98d1-597c-ac28-0755ae81ffa3","option_code":"B","option_text":"Implementar de forma modular, consolidando um módulo por vez antes de avançar.","metadata":{"catalog_family":"vap","test_number":6,"question_number":6}},{"id":"7aed4ba2-3e23-590d-a75b-d82845b1181b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1b61b8b1-98d1-597c-ac28-0755ae81ffa3","option_code":"C","option_text":"Esperar dominar todos os módulos teoricamente antes de aplicar qualquer um.","metadata":{"catalog_family":"vap","test_number":6,"question_number":6}},{"id":"f3146d87-e344-5920-b04a-89d31e3b98bc","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1b61b8b1-98d1-597c-ac28-0755ae81ffa3","option_code":"D","option_text":"Trocar todo o processo de uma vez para acelerar resultados.","metadata":{"catalog_family":"vap","test_number":6,"question_number":6}},{"id":"6c69656f-34cd-5a89-bd42-84986a216ec8","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"12631282-2533-5f14-ac99-2d87c6e5acd0","option_code":"A","option_text":"Diagnóstico, Implementação Modular, Medição e Ajuste.","metadata":{"catalog_family":"vap","test_number":6,"question_number":7}},{"id":"98060d9f-125e-597c-b3f2-5fc46e659835","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"12631282-2533-5f14-ac99-2d87c6e5acd0","option_code":"B","option_text":"Prospecção, Cotação, Negociação e Comissão.","metadata":{"catalog_family":"vap","test_number":6,"question_number":7}},{"id":"d82b32d9-1b98-5cb0-98fb-b164b6f87906","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"12631282-2533-5f14-ac99-2d87c6e5acd0","option_code":"C","option_text":"Planejamento, Motivação, Improviso e Premiação.","metadata":{"catalog_family":"vap","test_number":6,"question_number":7}},{"id":"92678cd5-22e7-5be7-8c44-6a954e0a5721","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"12631282-2533-5f14-ac99-2d87c6e5acd0","option_code":"D","option_text":"Abordagem, Desconto, Fechamento e Cobrança.","metadata":{"catalog_family":"vap","test_number":6,"question_number":7}},{"id":"05e6f387-d993-5699-a8fb-51982916290e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4c0e1ef6-3f2f-5f36-8d4e-7cfdbbb390a1","option_code":"A","option_text":"Avaliar taxas de conversão, gargalos do processo e perfis de cliente que geram maior dificuldade.","metadata":{"catalog_family":"vap","test_number":6,"question_number":8}},{"id":"9bfcfbda-1689-5dd0-90f5-338e18cc6c33","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4c0e1ef6-3f2f-5f36-8d4e-7cfdbbb390a1","option_code":"B","option_text":"Reescrever todos os scripts sem observar o funil existente.","metadata":{"catalog_family":"vap","test_number":6,"question_number":8}},{"id":"0a3d59b6-25ee-59bf-961b-b5990bfe548e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4c0e1ef6-3f2f-5f36-8d4e-7cfdbbb390a1","option_code":"C","option_text":"Aumentar a meta sem verificar os números atuais.","metadata":{"catalog_family":"vap","test_number":6,"question_number":8}},{"id":"b9587e8b-064f-519a-939e-e573168bfcc1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4c0e1ef6-3f2f-5f36-8d4e-7cfdbbb390a1","option_code":"D","option_text":"Escolher a ferramenta de IA mais cara do mercado.","metadata":{"catalog_family":"vap","test_number":6,"question_number":8}},{"id":"40144166-16d2-5eb2-b063-54a5a3f7dd1e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"990d7fc7-cf7c-5c6f-acaf-0278dd53af68","option_code":"A","option_text":"Usar apenas histórias emocionais e dispensar documentação.","metadata":{"catalog_family":"vap","test_number":6,"question_number":9}},{"id":"ed611733-8423-5163-b91d-0aeca30409a7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"990d7fc7-cf7c-5c6f-acaf-0278dd53af68","option_code":"B","option_text":"Apresentar uma promoção antes de descobrir a necessidade.","metadata":{"catalog_family":"vap","test_number":6,"question_number":9}},{"id":"33a16be6-098c-5ba2-8c37-eea968674c85","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"990d7fc7-cf7c-5c6f-acaf-0278dd53af68","option_code":"C","option_text":"Evitar registrar oportunidades para manter liberdade de improvisação.","metadata":{"catalog_family":"vap","test_number":6,"question_number":9}},{"id":"5690509f-f51a-5491-b4d7-8a6dd23a2336","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"990d7fc7-cf7c-5c6f-acaf-0278dd53af68","option_code":"D","option_text":"Registrar cada interação no CRM e deixar o próximo passo definido.","metadata":{"catalog_family":"vap","test_number":6,"question_number":9}},{"id":"3fd024b3-bdce-5252-8d69-5a25cc627520","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"bd596ca3-66d2-5b32-8405-a00a09bc428f","option_code":"A","option_text":"O método funciona apenas no mercado em que foi criado.","metadata":{"catalog_family":"vap","test_number":6,"question_number":10}},{"id":"327d19bf-aa51-5927-8c2f-0e745ff4449c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"bd596ca3-66d2-5b32-8405-a00a09bc428f","option_code":"B","option_text":"Resultados dependem principalmente de contratar vendedores já experientes.","metadata":{"catalog_family":"vap","test_number":6,"question_number":10}},{"id":"b8224d4f-9add-5f8a-b4d0-c49829330782","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"bd596ca3-66d2-5b32-8405-a00a09bc428f","option_code":"C","option_text":"Pressionar por produção desde o primeiro dia é indispensável.","metadata":{"catalog_family":"vap","test_number":6,"question_number":10}},{"id":"455b0d86-68a4-5142-b4de-95805c7b12f3","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"bd596ca3-66d2-5b32-8405-a00a09bc428f","option_code":"D","option_text":"O processo correto, aplicado com disciplina, supera o talento isolado e pode ser replicado em equipes.","metadata":{"catalog_family":"vap","test_number":6,"question_number":10}},{"id":"489bca22-7f4d-5110-abc2-33e1029b2764","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"83ece62c-d948-5342-b3fc-76bd53e5be9e","option_code":"A","option_text":"Considerar que todo resultado depende exclusivamente da sorte.","metadata":{"catalog_family":"vap","test_number":6,"question_number":11}},{"id":"fed73d24-f495-5c41-b91f-198f98d6ae62","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"83ece62c-d948-5342-b3fc-76bd53e5be9e","option_code":"B","option_text":"Aceitar qualquer exigência do cliente para não perder a venda.","metadata":{"catalog_family":"vap","test_number":6,"question_number":11}},{"id":"b0e8e2f9-db46-57ff-9a50-b67196afbfb4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"83ece62c-d948-5342-b3fc-76bd53e5be9e","option_code":"C","option_text":"Assumir responsabilidade pelos próprios resultados, evitando culpar mercado, produto ou cliente.","metadata":{"catalog_family":"vap","test_number":6,"question_number":11}},{"id":"fc20a0a7-4849-5ca5-92a5-51a1f5b7ac49","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"83ece62c-d948-5342-b3fc-76bd53e5be9e","option_code":"D","option_text":"Trabalhar sozinho e evitar pedir feedback.","metadata":{"catalog_family":"vap","test_number":6,"question_number":11}},{"id":"280e6d4a-1801-529a-820e-78235f63308a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"e64356e8-84a2-5f0d-897b-549e45cb05ad","option_code":"A","option_text":"Porque resultados não têm relação com disciplina.","metadata":{"catalog_family":"vap","test_number":6,"question_number":12}},{"id":"2754b1a8-46f7-50d2-9e7b-e6bdab8f68c1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"e64356e8-84a2-5f0d-897b-549e45cb05ad","option_code":"B","option_text":"Porque metas comerciais não devem ser medidas.","metadata":{"catalog_family":"vap","test_number":6,"question_number":12}},{"id":"ab9890a4-f47f-5885-90c5-76ee97544215","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"e64356e8-84a2-5f0d-897b-549e45cb05ad","option_code":"C","option_text":"Porque o resultado é consequência da execução diária de atividades e comportamentos controláveis.","metadata":{"catalog_family":"vap","test_number":6,"question_number":12}},{"id":"a9a0f8f1-ec1e-54b1-a71d-0a043d95fc49","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"e64356e8-84a2-5f0d-897b-549e45cb05ad","option_code":"D","option_text":"Porque o processo deve permanecer igual mesmo quando os dados mostram falhas.","metadata":{"catalog_family":"vap","test_number":6,"question_number":12}},{"id":"bfbc9b4d-3d72-5116-b768-e3ec373181a4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4bc5f909-6d6e-5a9d-8c6b-08e01e04dfe9","option_code":"A","option_text":"Como dado e oportunidade de aprendizado para melhorar o processo.","metadata":{"catalog_family":"vap","test_number":6,"question_number":13}},{"id":"44b6312c-dbf4-5fe1-961c-6ce12e9766b7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4bc5f909-6d6e-5a9d-8c6b-08e01e04dfe9","option_code":"B","option_text":"Como motivo para abandonar a prospecção daquele mês.","metadata":{"catalog_family":"vap","test_number":6,"question_number":13}},{"id":"09cf1e6d-8cd1-5085-aff5-5534d9fb3a5e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4bc5f909-6d6e-5a9d-8c6b-08e01e04dfe9","option_code":"C","option_text":"Como prova definitiva de incapacidade para vender.","metadata":{"catalog_family":"vap","test_number":6,"question_number":13}},{"id":"8bc3d4a8-b891-59bb-aa47-38581e748abc","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4bc5f909-6d6e-5a9d-8c6b-08e01e04dfe9","option_code":"D","option_text":"Como algo que deve ser ignorado, sem análise.","metadata":{"catalog_family":"vap","test_number":6,"question_number":13}},{"id":"18a98b1f-d314-574e-b6ff-653f02fbe5c4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d8a26e4f-bfc1-562a-900f-5cd48b8b41ea","option_code":"A","option_text":"Toda negociação deve produzir uma resposta positiva imediata.","metadata":{"catalog_family":"vap","test_number":6,"question_number":14}},{"id":"cd52303d-5083-5a13-b14e-9622132b0e04","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d8a26e4f-bfc1-562a-900f-5cd48b8b41ea","option_code":"B","option_text":"O vendedor só prospecta quando tem garantia de fechamento.","metadata":{"catalog_family":"vap","test_number":6,"question_number":14}},{"id":"debcb134-2f0c-5219-b174-c3d134c726b8","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d8a26e4f-bfc1-562a-900f-5cd48b8b41ea","option_code":"C","option_text":"O vendedor evita clientes difíceis para proteger a motivação.","metadata":{"catalog_family":"vap","test_number":6,"question_number":14}},{"id":"1c4d01cd-566c-5270-83be-9bfebead298c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"d8a26e4f-bfc1-562a-900f-5cd48b8b41ea","option_code":"D","option_text":"O vendedor aceita que rejeição e imprevisibilidade fazem parte da venda e continua executando o processo.","metadata":{"catalog_family":"vap","test_number":6,"question_number":14}},{"id":"e57f84cb-23bf-524c-9fdb-483f4fb970b1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9838a846-d255-59bd-a921-f9377fd410cd","option_code":"A","option_text":"Disciplina: repetir a crença até aceitá-la.","metadata":{"catalog_family":"vap","test_number":6,"question_number":15}},{"id":"287bff41-56a8-5b2d-a436-9c4b6498e2b6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9838a846-d255-59bd-a921-f9377fd410cd","option_code":"B","option_text":"Decisão: escolher imediatamente uma nova meta.","metadata":{"catalog_family":"vap","test_number":6,"question_number":15}},{"id":"b140a81c-5eaf-52a2-ae48-3af13456ece5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9838a846-d255-59bd-a921-f9377fd410cd","option_code":"C","option_text":"Desejo: imaginar apenas o resultado final.","metadata":{"catalog_family":"vap","test_number":6,"question_number":15}},{"id":"6d6d719c-a60e-5831-a82e-a64d0543d6df","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9838a846-d255-59bd-a921-f9377fd410cd","option_code":"D","option_text":"Disputa: questionar e confrontar racionalmente a crença limitante.","metadata":{"catalog_family":"vap","test_number":6,"question_number":15}},{"id":"786c29b0-d34c-54fc-ad15-ff32f468f871","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"512d7c21-fd10-5ee4-82ff-584167f301aa","option_code":"A","option_text":"Atitude, Bloqueio, Causa, Desconto e Empatia.","metadata":{"catalog_family":"vap","test_number":6,"question_number":16}},{"id":"c040e88a-4d73-5083-8e0c-cd43ae21ef8f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"512d7c21-fd10-5ee4-82ff-584167f301aa","option_code":"B","option_text":"Adversidade, Crença, Consequência, Disputa e Energização.","metadata":{"catalog_family":"vap","test_number":6,"question_number":16}},{"id":"ceb2380e-10b4-52f7-a228-9e42e95ab28e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"512d7c21-fd10-5ee4-82ff-584167f301aa","option_code":"C","option_text":"Ação, Benefício, Conversão, Disciplina e Execução.","metadata":{"catalog_family":"vap","test_number":6,"question_number":16}},{"id":"a69d3e91-ae00-5a9f-b82f-43ce84bed440","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"512d7c21-fd10-5ee4-82ff-584167f301aa","option_code":"D","option_text":"Análise, Crença, Controle, Decisão e Entrega.","metadata":{"catalog_family":"vap","test_number":6,"question_number":16}},{"id":"cd484987-95ab-5c58-ae21-569a5c1ed9fd","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"93e6dc7a-4137-595e-b5bf-ac77ee11c335","option_code":"A","option_text":"Manter a capacidade de executar e aprender mesmo diante de dificuldade, em vez de esperar ausência de adversidade.","metadata":{"catalog_family":"vap","test_number":6,"question_number":17}},{"id":"5731f452-3103-5a28-bcd1-fdf644f5e0b6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"93e6dc7a-4137-595e-b5bf-ac77ee11c335","option_code":"B","option_text":"Nunca sentir frustração ou dúvida durante a carreira.","metadata":{"catalog_family":"vap","test_number":6,"question_number":17}},{"id":"224a30c7-1eda-5cc0-a76f-d65a041b77e4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"93e6dc7a-4137-595e-b5bf-ac77ee11c335","option_code":"C","option_text":"Acreditar que pensamento positivo sozinho substitui processo.","metadata":{"catalog_family":"vap","test_number":6,"question_number":17}},{"id":"28e610f0-84a7-576b-b03d-950247962556","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"93e6dc7a-4137-595e-b5bf-ac77ee11c335","option_code":"D","option_text":"Evitar situações que possam gerar rejeição.","metadata":{"catalog_family":"vap","test_number":6,"question_number":17}},{"id":"695388ae-c45b-57ce-8c98-1c70adad84fb","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"250e481d-198e-5a43-a0c5-150f1c9c5dd1","option_code":"A","option_text":"Começar o dia verificando somente o ranking dos colegas.","metadata":{"catalog_family":"vap","test_number":6,"question_number":18}},{"id":"daf652fd-eee0-5c45-8bf1-0a23f39fd214","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"250e481d-198e-5a43-a0c5-150f1c9c5dd1","option_code":"B","option_text":"Alterar as metas diariamente conforme o humor.","metadata":{"catalog_family":"vap","test_number":6,"question_number":18}},{"id":"69c782ff-79a1-5179-bf3f-e04efed3a2fc","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"250e481d-198e-5a43-a0c5-150f1c9c5dd1","option_code":"C","option_text":"Revisar metas, respirar conscientemente e reler o próprio “porquê” antes de iniciar o dia de vendas.","metadata":{"catalog_family":"vap","test_number":6,"question_number":18}},{"id":"93bec1a1-870c-573f-adc3-695cf04e733f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"250e481d-198e-5a43-a0c5-150f1c9c5dd1","option_code":"D","option_text":"Esperar a motivação aparecer antes da primeira prospecção.","metadata":{"catalog_family":"vap","test_number":6,"question_number":18}},{"id":"854e69a2-5385-5c88-a2bf-f9cca938113e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9293e359-d7d1-5f6c-8a12-45f4b3fd19b5","option_code":"A","option_text":"Uma vitória, um aprendizado e um ajuste para o dia seguinte.","metadata":{"catalog_family":"vap","test_number":6,"question_number":19}},{"id":"971c52dc-d01c-5c98-b713-fe1a90d521df","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9293e359-d7d1-5f6c-8a12-45f4b3fd19b5","option_code":"B","option_text":"Todos os concorrentes encontrados, sem reflexão sobre o próprio processo.","metadata":{"catalog_family":"vap","test_number":6,"question_number":19}},{"id":"4a4b6bc4-366e-56a9-90b4-92c46d147033","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9293e359-d7d1-5f6c-8a12-45f4b3fd19b5","option_code":"C","option_text":"Apenas reclamações sobre clientes que não compraram.","metadata":{"catalog_family":"vap","test_number":6,"question_number":19}},{"id":"c4367026-08d3-5066-a957-41769da3eac1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9293e359-d7d1-5f6c-8a12-45f4b3fd19b5","option_code":"D","option_text":"Somente o número de vendas fechadas.","metadata":{"catalog_family":"vap","test_number":6,"question_number":19}},{"id":"1dca9ed5-4c00-5d2c-9425-cb75446ad2c9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1b693f45-8309-5d23-956c-6758998a8961","option_code":"A","option_text":"Resiliência significa não sentir impacto diante de qualquer rejeição.","metadata":{"catalog_family":"vap","test_number":6,"question_number":20}},{"id":"a7ff5699-902a-51c3-8cff-d2593bd751b6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1b693f45-8309-5d23-956c-6758998a8961","option_code":"B","option_text":"Disciplina é necessária apenas quando a meta está próxima de ser atingida.","metadata":{"catalog_family":"vap","test_number":6,"question_number":20}},{"id":"629787a1-290f-541e-8300-a808a701b102","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1b693f45-8309-5d23-956c-6758998a8961","option_code":"C","option_text":"Disciplina sustenta a ação, resiliência acelera a recuperação e motivação tende a surgir do movimento e dos primeiros resultados.","metadata":{"catalog_family":"vap","test_number":6,"question_number":20}},{"id":"0dbfb9a7-a367-54f6-b7f4-5cdadf2eb809","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1b693f45-8309-5d23-956c-6758998a8961","option_code":"D","option_text":"Motivação deve vir primeiro; sem ela não existe ação possível.","metadata":{"catalog_family":"vap","test_number":6,"question_number":20}},{"id":"3aebaa43-d823-5717-b33f-cad255b8c9ed","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f2d7f9d5-2157-5b7f-935b-f787a0c7c316","option_code":"A","option_text":"Apresentar o menor preço disponível antes de entender o problema.","metadata":{"catalog_family":"vap","test_number":6,"question_number":21}},{"id":"a0ea7439-abc7-52d4-be5b-ff4df627730a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f2d7f9d5-2157-5b7f-935b-f787a0c7c316","option_code":"B","option_text":"Evitar qualquer pergunta e partir para características técnicas.","metadata":{"catalog_family":"vap","test_number":6,"question_number":21}},{"id":"27f4cc5a-6a67-5023-a4cf-aa46966e2a1a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f2d7f9d5-2157-5b7f-935b-f787a0c7c316","option_code":"C","option_text":"Usar desconto como primeira estratégia de diferenciação.","metadata":{"catalog_family":"vap","test_number":6,"question_number":21}},{"id":"cee6f572-5f2a-55f5-a34f-5da2bfc716b2","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"f2d7f9d5-2157-5b7f-935b-f787a0c7c316","option_code":"D","option_text":"Construir e comunicar valor suficiente para que o cliente compreenda o resultado e o impacto da solução.","metadata":{"catalog_family":"vap","test_number":6,"question_number":21}},{"id":"7595d22c-b55e-5877-9688-7b2d08aad817","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"528f9266-812e-5405-a675-18de28cd0462","option_code":"A","option_text":"Classificar o cliente nos quatro perfis DISC.","metadata":{"catalog_family":"vap","test_number":6,"question_number":22}},{"id":"ce84bbc0-d0ce-590f-94db-f9a9a0b7789f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"528f9266-812e-5405-a675-18de28cd0462","option_code":"B","option_text":"Mapear dimensões de valor: Benefício, Resultado, Impacto, Diferenciação, Garantia e Experiência.","metadata":{"catalog_family":"vap","test_number":6,"question_number":22}},{"id":"4a216f85-ffa5-51bc-8289-bf32f1c5742a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"528f9266-812e-5405-a675-18de28cd0462","option_code":"C","option_text":"Escolher ferramentas de IA para cada etapa do funil.","metadata":{"catalog_family":"vap","test_number":6,"question_number":22}},{"id":"776cd4a8-f3b8-51dd-bb22-55f5cebbbc21","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"528f9266-812e-5405-a675-18de28cd0462","option_code":"D","option_text":"Definir a sequência das perguntas SPIN.","metadata":{"catalog_family":"vap","test_number":6,"question_number":22}},{"id":"2a80e2aa-96cf-5fa5-ad1a-eb7eaa974f66","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"56e780f9-ea7f-5293-9432-0b6613b24f7c","option_code":"A","option_text":"Benefício.","metadata":{"catalog_family":"vap","test_number":6,"question_number":23}},{"id":"6b609fa0-ecf4-55a8-8337-bb2ff31c55c9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"56e780f9-ea7f-5293-9432-0b6613b24f7c","option_code":"B","option_text":"Experiência.","metadata":{"catalog_family":"vap","test_number":6,"question_number":23}},{"id":"8e1fcb45-7dae-57d7-b967-9cb9e384ca72","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"56e780f9-ea7f-5293-9432-0b6613b24f7c","option_code":"C","option_text":"Urgência artificial.","metadata":{"catalog_family":"vap","test_number":6,"question_number":23}},{"id":"b6a84946-2c5e-53f2-b2ff-eb32936c817e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"56e780f9-ea7f-5293-9432-0b6613b24f7c","option_code":"D","option_text":"Diferenciação.","metadata":{"catalog_family":"vap","test_number":6,"question_number":23}},{"id":"84d18106-b997-53e3-8e90-8037462611d0","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"422c6e5a-624d-5f01-bdb2-2410088863d9","option_code":"A","option_text":"Encerrar a conversa porque objeção de preço não pode ser trabalhada.","metadata":{"catalog_family":"vap","test_number":6,"question_number":24}},{"id":"5ba7d44a-1e20-5ed4-aed6-8ceea03b632a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"422c6e5a-624d-5f01-bdb2-2410088863d9","option_code":"B","option_text":"Retomar a construção de valor e investigar se o cliente compreendeu benefícios, impacto e retorno antes de simplesmente conceder desconto.","metadata":{"catalog_family":"vap","test_number":6,"question_number":24}},{"id":"045dc1c4-58b8-5ee2-9de5-92cc04b72116","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"422c6e5a-624d-5f01-bdb2-2410088863d9","option_code":"C","option_text":"Criar uma falsa promoção com prazo inexistente.","metadata":{"catalog_family":"vap","test_number":6,"question_number":24}},{"id":"4ce1334f-fb3a-58db-8a85-43715fee312c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"422c6e5a-624d-5f01-bdb2-2410088863d9","option_code":"D","option_text":"Reduzir imediatamente o preço sem fazer perguntas.","metadata":{"catalog_family":"vap","test_number":6,"question_number":24}},{"id":"82e171dc-99f5-535f-bb35-7bca9a35e98c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9f350a7b-e50b-5013-85bb-08732c6f3155","option_code":"A","option_text":"Atenção, interesse, desejo, ação, retenção e indicação.","metadata":{"catalog_family":"vap","test_number":6,"question_number":25}},{"id":"10c83cbd-99b1-5d50-bd66-e094525eacce","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9f350a7b-e50b-5013-85bb-08732c6f3155","option_code":"B","option_text":"Ancoragem, prova social, especificidade, comparação, ROI e embalagem.","metadata":{"catalog_family":"vap","test_number":6,"question_number":25}},{"id":"a570f035-dd80-5202-a81f-ebc31df5078b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9f350a7b-e50b-5013-85bb-08732c6f3155","option_code":"C","option_text":"Desconto, pressão, surpresa, improviso, comissão e urgência falsa.","metadata":{"catalog_family":"vap","test_number":6,"question_number":25}},{"id":"5d500225-a88a-50b7-959f-bfef17ff8378","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"9f350a7b-e50b-5013-85bb-08732c6f3155","option_code":"D","option_text":"Produto, preço, praça, promoção, pessoas e processo.","metadata":{"catalog_family":"vap","test_number":6,"question_number":25}},{"id":"2dae6b54-2cec-5851-b974-1927491bf800","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"17a7a758-f268-5726-a0bc-fdfc05661437","option_code":"A","option_text":"Produto Básico, Esperado, Ampliado e Potencial.","metadata":{"catalog_family":"vap","test_number":6,"question_number":26}},{"id":"d69150c1-e11b-53cd-a338-d7f060e8170b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"17a7a758-f268-5726-a0bc-fdfc05661437","option_code":"B","option_text":"Produto, Campanha, Objeção e Pós-venda.","metadata":{"catalog_family":"vap","test_number":6,"question_number":26}},{"id":"3d009ca7-ff3c-5668-838e-df2a65090130","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"17a7a758-f268-5726-a0bc-fdfc05661437","option_code":"C","option_text":"Preço, Desconto, Bônus e Fechamento.","metadata":{"catalog_family":"vap","test_number":6,"question_number":26}},{"id":"42fc9ae7-9769-5246-93b6-4ac0f1a9930c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"17a7a758-f268-5726-a0bc-fdfc05661437","option_code":"D","option_text":"Necessidade, Desejo, Compra e Indicação.","metadata":{"catalog_family":"vap","test_number":6,"question_number":26}},{"id":"647c11a7-dbf8-5c91-99de-5a48e346e46b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"3f88a7ea-2730-5f37-80a6-7cbf49739dcb","option_code":"A","option_text":"Criar depoimento fictício para acelerar a decisão.","metadata":{"catalog_family":"vap","test_number":6,"question_number":27}},{"id":"532d1544-e4fa-56ea-98c6-d2f546a3ecb2","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"3f88a7ea-2730-5f37-80a6-7cbf49739dcb","option_code":"B","option_text":"Apresentar um caso real semelhante ao contexto do prospect, com resultado verificável.","metadata":{"catalog_family":"vap","test_number":6,"question_number":27}},{"id":"263e8074-5c53-5cc9-9cc9-ff77b39e93cf","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"3f88a7ea-2730-5f37-80a6-7cbf49739dcb","option_code":"C","option_text":"Afirmar que “todo mundo compra” sem evidência.","metadata":{"catalog_family":"vap","test_number":6,"question_number":27}},{"id":"476a7b23-517a-548e-b6b5-0521d272dcc9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"3f88a7ea-2730-5f37-80a6-7cbf49739dcb","option_code":"D","option_text":"Mudar o preço durante a reunião para testar reação.","metadata":{"catalog_family":"vap","test_number":6,"question_number":27}},{"id":"b139adf1-97ff-50a4-83b4-d9689965949a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"caefa532-20b4-5fd7-bff9-7385358cc6a4","option_code":"A","option_text":"Relacionar o investimento ao retorno ou impacto gerado, ajudando o cliente a avaliar valor de forma concreta.","metadata":{"catalog_family":"vap","test_number":6,"question_number":28}},{"id":"1dfb541a-6601-5f98-adde-902960a9b241","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"caefa532-20b4-5fd7-bff9-7385358cc6a4","option_code":"B","option_text":"Comprovar que o menor preço é sempre a melhor escolha.","metadata":{"catalog_family":"vap","test_number":6,"question_number":28}},{"id":"85772d88-332f-53bf-9338-a90fa0572d17","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"caefa532-20b4-5fd7-bff9-7385358cc6a4","option_code":"C","option_text":"Substituir todas as perguntas de diagnóstico.","metadata":{"catalog_family":"vap","test_number":6,"question_number":28}},{"id":"ac90e887-2aee-55cd-81db-1fca2e2db352","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"caefa532-20b4-5fd7-bff9-7385358cc6a4","option_code":"D","option_text":"Eliminar a necessidade de entender o objetivo do cliente.","metadata":{"catalog_family":"vap","test_number":6,"question_number":28}},{"id":"dc79bf51-0795-5ec2-bd7f-4cae717a00b7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"104c1a6f-40ec-519f-b218-81a16b6ffa6f","option_code":"A","option_text":"Manter exatamente a mesma entrega dos concorrentes.","metadata":{"catalog_family":"vap","test_number":6,"question_number":29}},{"id":"bfd77c89-8f05-5b87-abeb-4776212a2271","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"104c1a6f-40ec-519f-b218-81a16b6ffa6f","option_code":"B","option_text":"Trocar o processo consultivo por uma abordagem genérica.","metadata":{"catalog_family":"vap","test_number":6,"question_number":29}},{"id":"eca3ab1d-25a8-5d40-afd5-626223620032","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"104c1a6f-40ec-519f-b218-81a16b6ffa6f","option_code":"C","option_text":"Retirar benefícios para reduzir o preço.","metadata":{"catalog_family":"vap","test_number":6,"question_number":29}},{"id":"e78813b4-a884-5662-a1db-03b3f55326b1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"104c1a6f-40ec-519f-b218-81a16b6ffa6f","option_code":"D","option_text":"Adicionar elementos que superem o que o cliente considera padrão, como suporte, experiência ou diferenciais relevantes.","metadata":{"catalog_family":"vap","test_number":6,"question_number":29}},{"id":"9e266699-8bfb-51ec-8e44-44febb2fe497","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"170242de-b9cc-546d-b816-53664f13bc2b","option_code":"A","option_text":"Focar apenas em produto, sem adaptar comunicação ou revisar resultados.","metadata":{"catalog_family":"vap","test_number":6,"question_number":30}},{"id":"61894053-4cf3-5447-b6f8-5fd44d8d209f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"170242de-b9cc-546d-b816-53664f13bc2b","option_code":"B","option_text":"Evitar medir performance para preservar espontaneidade.","metadata":{"catalog_family":"vap","test_number":6,"question_number":30}},{"id":"269484ca-2c13-5c06-8a30-f25f5fddae05","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"170242de-b9cc-546d-b816-53664f13bc2b","option_code":"C","option_text":"Depender de carisma, falar mais que o cliente e conceder desconto rápido.","metadata":{"catalog_family":"vap","test_number":6,"question_number":30}},{"id":"0c620f18-1c7d-5dd3-a19d-8d200c7a8ef4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"170242de-b9cc-546d-b816-53664f13bc2b","option_code":"D","option_text":"Executar um processo mensurável com mentalidade disciplinada e comunicar valor a partir do impacto relevante para o cliente.","metadata":{"catalog_family":"vap","test_number":6,"question_number":30}}]$vap_options$::jsonb) as x(
    id uuid,
    organization_id uuid,
    question_id uuid,
    option_code text,
    option_text text,
    metadata jsonb
  )
)
insert into public.assessment_question_options (
  id,
  organization_id,
  question_id,
  option_code,
  option_text,
  metadata
)
select
  id,
  organization_id,
  question_id,
  option_code,
  option_text,
  metadata
from payload;

-- --------------------------------------------------------------------------
-- 7. Gabarito privado — não exposto ao participante
-- --------------------------------------------------------------------------
with payload as (
  select *
  from jsonb_to_recordset($vap_keys$[{"question_id":"5ad9c1bd-bc8e-593f-aa82-50eb965e5c16","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"O nome do método é construído sobre os três eixos Valor, Abordagem e Performance.","source_reference":"Método VAP - Módulo 1, Aula 1","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":1,"source_label":"Fundamentos do VAP","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"59715a0a-0a92-5cd5-b43a-7a622e48aa75","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"O VAP se diferencia de abordagens dependentes de talento ao propor um sistema estruturado e repetível.","source_reference":"Método VAP - Módulo 1, Aulas 1 e 3","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":2,"source_label":"Fundamentos do VAP","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"822062ce-558a-598e-80d9-da972ef24dd7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"Esses cinco pilares formam a estrutura que sustenta o sistema VAP; a ausência de um deles compromete o conjunto.","source_reference":"Método VAP - Módulo 1, Aula 2","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":3,"source_label":"Fundamentos do VAP","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"b8b566d4-6545-5975-a7de-7654c55d8294","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"A","justification":"O framework é apresentado como um roteiro de execução: Valor, Abordagem, Processo, Persuasão e Feedback.","source_reference":"Método VAP - Módulo 1, Aula 2 e aprofundamento do framework","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":4,"source_label":"Fundamentos do VAP","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"1c94f4c9-ad1d-5e6f-b444-f2a7319a92fa","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"A dimensão sistêmica do VAP decorre de integrar todas as etapas da venda em um processo completo.","source_reference":"Método VAP - Módulo 1, Aula 3","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":5,"source_label":"Fundamentos do VAP","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"1b61b8b1-98d1-597c-ac28-0755ae81ffa3","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"O VAP recomenda implementação modular para que cada competência seja praticada e consolidada antes da próxima.","source_reference":"Método VAP - Módulo 1, Aula 4","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":6,"source_label":"Aplicação do VAP","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"12631282-2533-5f14-ac99-2d87c6e5acd0","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"A","justification":"A implementação é organizada em quatro níveis sucessivos: diagnosticar, implementar, medir e ajustar.","source_reference":"Método VAP - Módulo 1, Aula 4","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":7,"source_label":"Aplicação do VAP","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"4c0e1ef6-3f2f-5f36-8d4e-7cfdbbb390a1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"A","justification":"O diagnóstico parte do estado atual da performance para identificar onde o processo realmente trava.","source_reference":"Método VAP - Módulo 1, Aula 4","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":8,"source_label":"Aplicação do VAP","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"990d7fc7-cf7c-5c6f-acaf-0278dd53af68","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"D","justification":"Processo significa executar as etapas com consistência e documentação, sem oportunidades sem próxima ação.","source_reference":"Método VAP - Módulo 1, Framework V-A-P-P-F","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":9,"source_label":"Fundamentos do VAP","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"bd596ca3-66d2-5b32-8405-a00a09bc428f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"D","justification":"Os cases enfatizam a replicabilidade do processo e a formação estruturada de vendedores como fatores centrais de desempenho.","source_reference":"Método VAP - Módulo 1, Aula 5","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":10,"source_label":"Fundamentos do VAP","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"83ece62c-d948-5342-b3fc-76bd53e5be9e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"Responsabilidade radical é o primeiro dos sete pilares e desloca o foco da culpa para aquilo que o vendedor pode executar e melhorar.","source_reference":"Método VAP - Módulo 2, Aula 1","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":11,"source_label":"Mentalidade VAP","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"e64356e8-84a2-5f0d-897b-549e45cb05ad","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"O método separa aquilo que o vendedor controla diariamente dos resultados que surgem como consequência dessa execução.","source_reference":"Método VAP - Módulo 2, Aula 1","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":12,"source_label":"Mentalidade VAP","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"4bc5f909-6d6e-5a9d-8c6b-08e01e04dfe9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"A","justification":"O pilar de aprendizado contínuo transforma rejeições e objeções em informação utilizável para melhoria.","source_reference":"Método VAP - Módulo 2, Aula 1","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":13,"source_label":"Mentalidade VAP","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"d8a26e4f-bfc1-562a-900f-5cd48b8b41ea","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"D","justification":"A tolerância à incerteza permite permanecer funcional mesmo diante do “não” e da falta de garantia de resultado.","source_reference":"Método VAP - Módulo 2, Aula 1","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":14,"source_label":"Mentalidade VAP","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"9838a846-d255-59bd-a921-f9377fd410cd","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"D","justification":"No inventário de crenças, ABCDE significa Adversidade, Crença, Consequência, Disputa e Energização.","source_reference":"Método VAP - Módulo 2, exercício ABCDE","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":15,"source_label":"Mentalidade VAP","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"512d7c21-fd10-5ee4-82ff-584167f301aa","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Essa é a sequência indicada pelo exercício para reconhecer e substituir crenças limitantes.","source_reference":"Método VAP - Módulo 2, exercício ABCDE","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":16,"source_label":"Mentalidade VAP","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"93e6dc7a-4137-595e-b5bf-ac77ee11c335","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"A","justification":"O material define mentalidade inabalável como capacidade de sustentar desempenho em meio às dificuldades.","source_reference":"Método VAP - Módulo 2, Aula 4","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":17,"source_label":"Mentalidade VAP","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"250e481d-198e-5a43-a0c5-150f1c9c5dd1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"A rotina de estado de aproximadamente dez minutos é apresentada como mecanismo para preparar o vendedor antes da execução.","source_reference":"Método VAP - Módulo 2, Aula 4","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":18,"source_label":"Mentalidade VAP","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"9293e359-d7d1-5f6c-8a12-45f4b3fd19b5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"A","justification":"O diário transforma a experiência diária em um ciclo curto de feedback e desenvolvimento.","source_reference":"Método VAP - Módulo 2, Aula 4","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":19,"source_label":"Mentalidade VAP","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"1b693f45-8309-5d23-956c-6758998a8961","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"A tríade do desempenho atribui funções distintas e complementares à disciplina, resiliência e motivação.","source_reference":"Método VAP - Módulo 2, Aula 5","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":20,"source_label":"Mentalidade VAP","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"f2d7f9d5-2157-5b7f-935b-f787a0c7c316","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"D","justification":"O Módulo Valor e Venda coloca valor antes de preço e orienta o vendedor pelo resultado que a solução proporciona.","source_reference":"Método VAP - Módulo 3","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":21,"source_label":"Valor e Venda","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"528f9266-812e-5405-a675-18de28cd0462","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"BRIDGE organiza o mapeamento de valor em seis dimensões antes da comunicação comercial.","source_reference":"Método VAP - Módulo 3, Modelo BRIDGE","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":22,"source_label":"Valor e Venda","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"56e780f9-ea7f-5293-9432-0b6613b24f7c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"O modelo reúne Benefício, Resultado, Impacto, Diferenciação, Garantia e Experiência; urgência artificial não integra o framework.","source_reference":"Método VAP - Módulo 3, Modelo BRIDGE","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":23,"source_label":"Valor e Venda","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"422c6e5a-624d-5f01-bdb2-2410088863d9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"O VAP interpreta objeção de preço como sinal para revisar valor percebido e educar o cliente sobre retorno e diferenciação.","source_reference":"Método VAP - Módulo 3, Valor x Preço","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":24,"source_label":"Valor e Venda","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"9f350a7b-e50b-5013-85bb-08732c6f3155","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"O material apresenta essas seis estratégias como recursos sequenciais para ampliar percepção de valor.","source_reference":"Método VAP - Módulo 3","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":25,"source_label":"Valor e Venda","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"17a7a758-f268-5726-a0bc-fdfc05661437","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"A","justification":"A pirâmide organiza a diferenciação do nível básico ao potencial, acrescentando elementos de valor superior.","source_reference":"Método VAP - Módulo 3","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":26,"source_label":"Valor e Venda","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"3f88a7ea-2730-5f37-80a6-7cbf49739dcb","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Prova social aumenta valor percebido quando usa evidência real e relevante de clientes ou situações comparáveis.","source_reference":"Método VAP - Módulo 3","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":27,"source_label":"Valor e Venda","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"caefa532-20b4-5fd7-bff9-7385358cc6a4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"A","justification":"ROI é uma das estratégias de valor e permite traduzir a proposta em impacto e retorno mensurável.","source_reference":"Método VAP - Módulo 3","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":28,"source_label":"Valor e Venda","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"104c1a6f-40ec-519f-b218-81a16b6ffa6f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"D","justification":"O nível ampliado adiciona valor acima do básico e do que já é esperado, aumentando diferenciação percebida.","source_reference":"Método VAP - Módulo 3","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":29,"source_label":"Valor e Venda","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}},{"question_id":"170242de-b9cc-546d-b816-53664f13bc2b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"D","justification":"Os três módulos conectam processo replicável, mentalidade de execução e construção sistemática de valor.","source_reference":"Método VAP - Módulos 1 a 3","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":30,"source_label":"Integração VAP","source_content_sha256":"d28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84","authoring_document_sha256":"8b8744e0779fce01a2f505d22a700e4e88878c7848a9845968e2b2e66a263820","review_basis":"Gabarito comentado — Teste 6"}}]$vap_keys$::jsonb) as x(
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
  question_id,
  organization_id,
  correct_option_code,
  justification,
  source_reference,
  is_critical,
  critical_reason,
  reviewed_by,
  reviewed_at,
  metadata
)
select
  question_id,
  organization_id,
  correct_option_code,
  justification,
  source_reference,
  is_critical,
  critical_reason,
  null,
  null,
  metadata
from payload;

-- --------------------------------------------------------------------------
-- 8. Composição da versão — 30 questões / sequência 1..30
-- --------------------------------------------------------------------------
with payload as (
  select *
  from jsonb_to_recordset($vap_version_questions$[{"id":"559e897f-6508-581d-8ac2-44563f04e6b5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"5ad9c1bd-bc8e-593f-aa82-50eb965e5c16","sequence_no":1,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":1}},{"id":"5ad4e63b-9ab8-5d4e-bd81-42758523af53","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"59715a0a-0a92-5cd5-b43a-7a622e48aa75","sequence_no":2,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":2}},{"id":"a13692f6-a75a-55c9-89d8-b10498c2ff2d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"822062ce-558a-598e-80d9-da972ef24dd7","sequence_no":3,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":3}},{"id":"f5f06319-b631-5b31-abdb-93af77a1a8ee","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"b8b566d4-6545-5975-a7de-7654c55d8294","sequence_no":4,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":4}},{"id":"644ecdd7-cee6-595c-a2ef-88dd5c604ab0","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"1c94f4c9-ad1d-5e6f-b444-f2a7319a92fa","sequence_no":5,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":5}},{"id":"f41e2ee7-6f74-5428-8d47-2d75dbfb9871","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"1b61b8b1-98d1-597c-ac28-0755ae81ffa3","sequence_no":6,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":6}},{"id":"6ab34860-76da-5b82-a50d-fb00d9c08e2d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"12631282-2533-5f14-ac99-2d87c6e5acd0","sequence_no":7,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":7}},{"id":"7003da99-7fec-50ae-9c6d-654027ed4e69","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"4c0e1ef6-3f2f-5f36-8d4e-7cfdbbb390a1","sequence_no":8,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":8}},{"id":"a243bd62-8fcb-5c78-9f00-80aca98fa1de","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"990d7fc7-cf7c-5c6f-acaf-0278dd53af68","sequence_no":9,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":9}},{"id":"51e268b4-90bc-5362-9384-ed8385f31115","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"bd596ca3-66d2-5b32-8405-a00a09bc428f","sequence_no":10,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":10}},{"id":"d130c1c2-dad6-5810-a7cd-4c4be4520508","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"83ece62c-d948-5342-b3fc-76bd53e5be9e","sequence_no":11,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":11}},{"id":"ed9e19c4-317c-501f-8f83-e95279002d0c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"e64356e8-84a2-5f0d-897b-549e45cb05ad","sequence_no":12,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":12}},{"id":"b27f7486-918a-5e2b-bd23-d93a6f73af75","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"4bc5f909-6d6e-5a9d-8c6b-08e01e04dfe9","sequence_no":13,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":13}},{"id":"524fa6b8-8459-59cd-a1af-0c3baca72b9d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"d8a26e4f-bfc1-562a-900f-5cd48b8b41ea","sequence_no":14,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":14}},{"id":"ec56b395-f433-54b2-9333-7d5d35b3e036","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"9838a846-d255-59bd-a921-f9377fd410cd","sequence_no":15,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":15}},{"id":"268c7087-eec1-5bd1-a634-362c8242db1b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"512d7c21-fd10-5ee4-82ff-584167f301aa","sequence_no":16,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":16}},{"id":"954f61bd-adda-5d36-9bd9-b3206caf30fb","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"93e6dc7a-4137-595e-b5bf-ac77ee11c335","sequence_no":17,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":17}},{"id":"33fb6cd4-0c83-57a7-8dc8-3b9560763181","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"250e481d-198e-5a43-a0c5-150f1c9c5dd1","sequence_no":18,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":18}},{"id":"693907ae-f097-5f34-8448-0f13af84cceb","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"9293e359-d7d1-5f6c-8a12-45f4b3fd19b5","sequence_no":19,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":19}},{"id":"edf4132f-42f2-5e1a-9929-56b7ac6b86ba","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"1b693f45-8309-5d23-956c-6758998a8961","sequence_no":20,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":20}},{"id":"08dc06b2-62ba-54c9-b4ec-3430bb4034df","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"f2d7f9d5-2157-5b7f-935b-f787a0c7c316","sequence_no":21,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":21}},{"id":"55051239-fb5e-56ca-8cf4-e0206f3c2e0a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"528f9266-812e-5405-a675-18de28cd0462","sequence_no":22,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":22}},{"id":"50ba53dc-76b7-5b97-b714-f08e62dc3c70","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"56e780f9-ea7f-5293-9432-0b6613b24f7c","sequence_no":23,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":23}},{"id":"606e4a2c-0e6f-5dc0-aa19-fb7689327e8f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"422c6e5a-624d-5f01-bdb2-2410088863d9","sequence_no":24,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":24}},{"id":"c845e10f-47fc-5e70-a6b6-058eba33532a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"9f350a7b-e50b-5013-85bb-08732c6f3155","sequence_no":25,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":25}},{"id":"85aed39e-93a8-5572-b077-93c01e63026c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"17a7a758-f268-5726-a0bc-fdfc05661437","sequence_no":26,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":26}},{"id":"351ddc84-fd39-57f4-b6a6-2e6b680affb1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"3f88a7ea-2730-5f37-80a6-7cbf49739dcb","sequence_no":27,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":27}},{"id":"2774093e-d492-5c5e-942b-8bf5fe32db43","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"caefa532-20b4-5fd7-bff9-7385358cc6a4","sequence_no":28,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":28}},{"id":"0f13ea70-030a-51ed-9d90-0ef815635af2","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"104c1a6f-40ec-519f-b218-81a16b6ffa6f","sequence_no":29,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":29}},{"id":"426ffbc6-b8d5-50ea-b211-48f4cad0ab08","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"07ed48aa-b1ac-547f-8fa5-a93c1441cc3c","question_id":"170242de-b9cc-546d-b816-53664f13bc2b","sequence_no":30,"points":1,"is_required":true,"metadata":{"catalog_family":"vap","catalog_version":"2026.08-v1","test_number":6,"question_number":30}}]$vap_version_questions$::jsonb) as x(
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
  id,
  organization_id,
  test_version_id,
  question_id,
  sequence_no,
  points,
  is_required,
  metadata
)
select
  id,
  organization_id,
  test_version_id,
  question_id,
  sequence_no,
  points,
  is_required,
  metadata
from payload;

-- --------------------------------------------------------------------------
-- 9. Pós-condições
-- --------------------------------------------------------------------------
do $post$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
  v_test_id uuid := '77c2984e-c0e8-5829-94ba-fcb0076ce8b6'::uuid;
  v_version_id uuid := '07ed48aa-b1ac-547f-8fa5-a93c1441cc3c'::uuid;
begin
  if not exists (
    select 1
    from public.source_material_versions smv
    join public.source_materials sm
      on sm.id = smv.source_material_id
     and sm.organization_id = smv.organization_id
    where smv.id = 'a20ad8ff-b3f8-5106-b96e-346fa342d098'::uuid
      and smv.organization_id = v_org_id
      and sm.code = 'metodo_vap_vendedor_alta_performance'
      and sm.material_type = 'book'
      and sm.status = 'active'
      and smv.version_code = '1a-edicao-2024'
      and smv.status = 'active'
      and lower(smv.content_sha256) = 'd28448b0b2e377af5233b939543bafb165d75d865547ef1627335f5a8b912b84'
      and sm.archived_at is null
      and smv.archived_at is null
  ) then
    raise exception 'VAP Teste 6 pós-condição: fonte/versionamento não confere.';
  end if;

  if (
    select count(*)
    from public.competency_domains c
    where c.organization_id = v_org_id
      and c.code in ('vap_fundamentos','vap_mentalidade','vap_valor_venda','vap_integracao')
      and c.status = 'draft'
      and c.is_legal = false
      and c.archived_at is null
  ) <> 4 then
    raise exception 'VAP Teste 6 pós-condição: esperado 4 competências VAP em draft.';
  end if;

  if not exists (
    select 1
    from public.assessment_tests t
    where t.id = v_test_id
      and t.organization_id = v_org_id
      and t.code = 'teste_6_vap_fundamentos_mentalidade_valor'
      and t.sequence_no = 6
      and t.question_count = 30
      and t.status = 'draft'
      and t.archived_at is null
  ) then
    raise exception 'VAP Teste 6 pós-condição: identidade do teste não confere.';
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
    raise exception 'VAP Teste 6 pós-condição: versão draft/fail-closed não confere.';
  end if;

  if (
    select count(*)
    from public.assessment_questions q
    where q.organization_id = v_org_id
      and q.code like 'vap_t6_q%'
      and q.status = 'reviewed'
      and q.archived_at is null
  ) <> 30 then
    raise exception 'VAP Teste 6 pós-condição: esperado 30 questões reviewed.';
  end if;

  if (
    select count(*)
    from public.assessment_version_questions avq
    where avq.organization_id = v_org_id
      and avq.test_version_id = v_version_id
      and avq.is_required = true
      and avq.archived_at is null
  ) <> 30 then
    raise exception 'VAP Teste 6 pós-condição: esperado 30 vínculos obrigatórios.';
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
    raise exception 'VAP Teste 6 pós-condição: sequência de questões não é 1..30.';
  end if;

  if (
    select count(*)
    from public.assessment_question_options o
    join public.assessment_questions q
      on q.id = o.question_id
     and q.organization_id = o.organization_id
    where o.organization_id = v_org_id
      and q.code like 'vap_t6_q%'
      and q.archived_at is null
      and o.archived_at is null
  ) <> 120 then
    raise exception 'VAP Teste 6 pós-condição: esperado 120 alternativas.';
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
        and q.code like 'vap_t6_q%'
        and q.archived_at is null
      group by q.id
    ) x
    where x.option_count <> 4
  ) then
    raise exception 'VAP Teste 6 pós-condição: alguma questão não possui exatamente 4 alternativas.';
  end if;

  if (
    select count(*)
    from private.assessment_question_keys k
    join public.assessment_questions q
      on q.id = k.question_id
     and q.organization_id = k.organization_id
    where k.organization_id = v_org_id
      and q.code like 'vap_t6_q%'
      and q.archived_at is null
  ) <> 30 then
    raise exception 'VAP Teste 6 pós-condição: esperado 30 gabaritos privados.';
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
      and q.code like 'vap_t6_q%'
      and q.archived_at is null
      and o.id is null
  ) then
    raise exception 'VAP Teste 6 pós-condição: existe gabarito sem alternativa correspondente.';
  end if;

  if exists (
    select 1
    from private.assessment_question_keys k
    join public.assessment_questions q
      on q.id = k.question_id
     and q.organization_id = k.organization_id
    where k.organization_id = v_org_id
      and q.code like 'vap_t6_q%'
      and q.archived_at is null
      and k.is_critical = true
  ) then
    raise exception 'VAP Teste 6 pós-condição: criticidade foi criada sem base no material.';
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
    raise exception 'VAP Teste 6 pós-condição: vínculo com fonte primária não confere.';
  end if;

  if exists (
    select 1
    from private.assessment_test_access_grants g
    where g.organization_id = v_org_id
      and g.test_id = v_test_id
      and g.archived_at is null
  ) then
    raise exception 'VAP Teste 6 pós-condição: nenhum grant deveria ter sido criado.';
  end if;

  if exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.test_id = v_test_id
      and a.archived_at is null
  ) then
    raise exception 'VAP Teste 6 pós-condição: nenhuma tentativa deveria existir.';
  end if;

  if (
    select count(*)
    from public.assessment_tests t
    where t.organization_id = v_org_id
      and t.sequence_no between 1 and 5
      and t.archived_at is null
  ) <> 5 then
    raise exception 'VAP Teste 6 pós-condição: catálogo-base 1..5 foi alterado.';
  end if;
end
$post$;

commit;
