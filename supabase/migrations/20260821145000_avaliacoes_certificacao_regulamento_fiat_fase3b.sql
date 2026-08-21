-- ============================================================================
-- RF Performance — Avaliações e Certificações
-- Catálogo Ampliado — Avaliação Regulamentar — Consórcio Fiat
-- Fase 3B — Fiat / Embracon — cadastro em RASCUNHO para homologação
--
-- Base normativa fornecida:
--   Regulamento do Contrato de Consórcio — Consórcio Fiat / Embracon
--   Versão 3 — Resolução 285/23 — C.E. 07/24
--   SHA-256: 74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a
--
-- Documento de autoria das questões:
--   Teste_07_Regulamento_Consorcio_Fiat.md
--   SHA-256: 7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200
--
-- ESCOPO / SEGURANÇA
--   - Não altera Testes 1 a 11.
--   - Cria a avaliação regulamentar como Teste de sequência 12.
--   - Cria 8 competências regulamentares por agrupamento interno do catálogo.
--   - Questões ficam em draft e exigem revisão legal antes da publicação.
--   - Não cria grant de acesso.
--   - Não publica a avaliação.
--   - Não cria tentativa.
--   - Gabarito permanece em private.assessment_question_keys.
--   - Nenhum item é marcado crítico, pois a fonte de autoria não declara criticidade.
--   - Corte 100/100 permanece fail-closed até definição da política de aprovação.
--   - A questão 28 permanece sinalizada para revisão de consistência da fonte antes da publicação.
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
    raise exception 'Regulamento Fiat abortado: organização RF esperada não localizada/ativa.';
  end if;

  if (
    select count(*)
    from public.assessment_tests t
    where t.organization_id = v_org_id
      and t.sequence_no between 1 and 11
      and t.archived_at is null
  ) <> 11 then
    raise exception 'Regulamento Fiat abortado: catálogo-base Testes 1 a 11 não está íntegro.';
  end if;

  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions tv
      on tv.test_id = t.id
     and tv.organization_id = t.organization_id
     and tv.archived_at is null
    where t.organization_id = v_org_id
      and t.sequence_no = 11
      and t.code = 'regulamento_vw_cnvw_v1'
      and t.status = 'draft'
      and tv.version_code = 'cnvw-v2.1-v1'
      and tv.status = 'draft'
      and t.archived_at is null
  ) then
    raise exception 'Regulamento Fiat abortado: Teste 11 Volkswagen esperado não está presente em draft.';
  end if;

  if exists (
    select 1
    from public.assessment_tests t
    where t.organization_id = v_org_id
      and t.archived_at is null
      and (
        t.sequence_no = 12
        or t.code = 'regulamento_fiat_v1'
        or t.id = '61d013e4-3b4b-5676-b39c-6d340f87b046'::uuid
      )
  ) then
    raise exception 'Regulamento Fiat abortado: já existe teste ocupando a identidade/seq. 12.';
  end if;

  if exists (
    select 1
    from public.source_materials sm
    where sm.organization_id = v_org_id
      and sm.archived_at is null
      and (
        sm.code = 'regulamento_fiat_embracon_v3'
        or sm.id = '417f7c60-3169-552d-9846-608e00809741'::uuid
      )
  ) then
    raise exception 'Regulamento Fiat abortado: fonte Fiat v3 já existe com a identidade esperada.';
  end if;

  if exists (
    select 1
    from public.source_material_versions smv
    where smv.organization_id = v_org_id
      and smv.archived_at is null
      and lower(smv.content_sha256) = '74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a'
  ) then
    raise exception 'Regulamento Fiat abortado: o mesmo SHA-256 normativo já está cadastrado em outra fonte.';
  end if;

  if exists (
    select 1
    from public.competency_domains c
    where c.organization_id = v_org_id
      and c.archived_at is null
      and (
        c.sequence_no between 51 and 58
        or c.code in (
          'reg_fiat_definicoes_fundamentos',
          'reg_fiat_planos',
          'reg_fiat_contribuicoes_taxas',
          'reg_fiat_constituicao_grupo',
          'reg_fiat_assembleias',
          'reg_fiat_contemplacao_lances',
          'reg_fiat_credito_garantias',
          'reg_fiat_cessao_exclusao_prescricao'
        )
      )
  ) then
    raise exception 'Regulamento Fiat abortado: sequência/código das competências 51..58 já está ocupado.';
  end if;

  if exists (
    select 1
    from public.assessment_questions q
    where q.organization_id = v_org_id
      and q.archived_at is null
      and q.code like 'reg_fiat_q%'
  ) then
    raise exception 'Regulamento Fiat abortado: já existem questões com o namespace reg_fiat_q.';
  end if;
end
$guard$;

-- --------------------------------------------------------------------------
-- 1. Fonte normativa fornecida
-- --------------------------------------------------------------------------
insert into public.source_materials (
  id, organization_id, code, title, description, material_type,
  issuer, status, metadata
)
values (
  '417f7c60-3169-552d-9846-608e00809741'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'regulamento_fiat_embracon_v3',
  'Regulamento do Contrato de Consórcio — Consórcio Fiat / Embracon',
  'Regulamento do Contrato de Consórcio associado à marca Consórcio Fiat, administrado pela Embracon, identificado no documento fornecido como Versão 3 — Resolução 285/23 — C.E. 07/24.',
  'regulation',
  'Embracon Administradora de Consórcio Ltda.',
  'active',
  jsonb_build_object(
    'catalog_family', 'regulatory',
    'brand', 'Consórcio Fiat',
    'administrator', 'Embracon',
    'document_version', '3',
    'edition_reference', 'C.E. 07/24',
    'normative_references', jsonb_build_array(
      'Lei 11.795/2008',
      'Circular 3432/09',
      'Resolução 285/23 do Banco Central do Brasil',
      'Código de Defesa do Consumidor',
      'Código Civil'
    ),
    'source_filename', 'REGULAMENTO FIAT.pdf',
    'content_sha256', '74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a',
    'external_currency_verified', false
  )
);

insert into public.source_material_versions (
  id, organization_id, source_material_id, version_code, version_no,
  status, effective_from, effective_until, published_at, source_date,
  content_sha256, source_locator, metadata
)
values (
  'dadf433e-5d7c-5373-b926-ed299332598f'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '417f7c60-3169-552d-9846-608e00809741'::uuid,
  'v3-res285-23-ce07-24',
  1,
  'active',
  null,
  null,
  null,
  null,
  '74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a',
  jsonb_build_object(
    'file_name', 'REGULAMENTO FIAT.pdf',
    'document_version', '3',
    'resolution', '285/23',
    'edition_reference', 'C.E. 07/24'
  ),
  jsonb_build_object(
    'catalog_family', 'regulatory',
    'brand', 'Consórcio Fiat',
    'administrator', 'Embracon',
    'version_identity_basis', 'document_version_and_sha256',
    'source_content_sha256', '74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a',
    'external_currency_verified', false
  )
);

-- --------------------------------------------------------------------------
-- 2. Competências regulamentares — agrupamento interno do catálogo
-- --------------------------------------------------------------------------
with payload as (
  select *
  from jsonb_to_recordset($fiat_competencies$[{"id":"c6ee4867-0fb4-55fa-a6e7-9160d44f43cb","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_definicoes_fundamentos","sequence_no":51,"name":"Regulamento Fiat — Definições e Fundamentos","description":"Definições do sistema de consórcio, fundo comum e taxa de administração.","domain_type":"knowledge","is_legal":true,"default_weight":0,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","grouping_basis":"internal_catalog_grouping_from_authoring_content","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"5a7038d1-5e51-57f4-8f2f-d00eb192d5af","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_planos","sequence_no":52,"name":"Regulamento Fiat — Planos","description":"Regras dos planos Justo®, Mais por Menos® 50 e Plano Justo Mais por Menos.","domain_type":"knowledge","is_legal":true,"default_weight":0,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","grouping_basis":"internal_catalog_grouping_from_authoring_content","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"dd860ec5-86b1-53cc-be5f-6ba5158f371a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_contribuicoes_taxas","sequence_no":53,"name":"Regulamento Fiat — Contribuições e Taxas","description":"Cálculo das contribuições, taxa de administração antecipada e encargos por atraso.","domain_type":"knowledge","is_legal":true,"default_weight":0,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","grouping_basis":"internal_catalog_grouping_from_authoring_content","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"4fcf7be5-4739-5de8-b52e-f19164f7e6c6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_constituicao_grupo","sequence_no":54,"name":"Regulamento Fiat — Constituição e Regras do Grupo","description":"Constituição do grupo, limites entre créditos e concentração de cotas.","domain_type":"knowledge","is_legal":true,"default_weight":0,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","grouping_basis":"internal_catalog_grouping_from_authoring_content","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"e7591bfd-4ff5-5e36-8661-b3a072cd9dff","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_assembleias","sequence_no":55,"name":"Regulamento Fiat — Assembleias","description":"Assembleias gerais ordinárias e extraordinárias, convocação e quórum de solicitação.","domain_type":"knowledge","is_legal":true,"default_weight":0,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","grouping_basis":"internal_catalog_grouping_from_authoring_content","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"c0534141-ebbf-5ff9-9bdd-ae8a91a48c01","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_contemplacao_lances","sequence_no":56,"name":"Regulamento Fiat — Contemplação, Sorteio e Lance","description":"Ordem de contemplação, elegibilidade, sorteio, lance e cobertura do lance vencedor.","domain_type":"knowledge","is_legal":true,"default_weight":0,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","grouping_basis":"internal_catalog_grouping_from_authoring_content","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"87ba9d19-2195-5fb2-96d3-99a53cb7fb88","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_credito_garantias","sequence_no":57,"name":"Regulamento Fiat — Crédito e Garantias","description":"Disponibilização e utilização do crédito, conversão em espécie e garantias.","domain_type":"knowledge","is_legal":true,"default_weight":0,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","grouping_basis":"internal_catalog_grouping_from_authoring_content","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"a31ceaeb-4651-592f-8fbf-f86a8d786a0c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_cessao_exclusao_prescricao","sequence_no":58,"name":"Regulamento Fiat — Cessão, Exclusão e Prescrição","description":"Cessão contratual, exclusão, restituição e prazo prescricional.","domain_type":"knowledge","is_legal":true,"default_weight":0,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","grouping_basis":"internal_catalog_grouping_from_authoring_content","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}}]$fiat_competencies$::jsonb) as x(
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
  '61d013e4-3b4b-5676-b39c-6d340f87b046'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'regulamento_fiat_v1',
  12,
  'Avaliação Regulamentar — Consórcio Fiat',
  'Avaliação de conhecimento sobre o Regulamento do Contrato de Consórcio Fiat/Embracon, Versão 3, estruturada em oito blocos internos do catálogo.',
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
    'brand', 'Consórcio Fiat',
    'administrator', 'Embracon',
    'assessment_version_label', 'Fiat/Embracon v3 — avaliação v1',
    'source_material_code', 'regulamento_fiat_embracon_v3',
    'source_content_sha256', '74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a',
    'authoring_document', 'Teste_07_Regulamento_Consorcio_Fiat.md',
    'authoring_document_sha256', '7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200',
    'distribution', '{"definicoes_fundamentos":3,"planos":3,"contribuicoes_taxas":3,"constituicao_grupo":3,"assembleias":3,"contemplacao_lances":5,"credito_garantias":5,"cessao_exclusao_prescricao":5}'::jsonb,
    'distribution_basis', 'internal_catalog_grouping_from_authoring_content',
    'source_consistency_review_required', true,
    'source_consistency_review_note', 'Revisar antes da publicação menções divergentes no documento normativo fornecido sobre quantidade de parcelas para exclusão; o item 28 do material de autoria cita a Cláusula 39.',
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
  '74243315-ea1e-5178-83b8-d6077ab9dc59'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '61d013e4-3b4b-5676-b39c-6d340f87b046'::uuid,
  'fiat-v3-v1',
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
      'instrument', 'Regulamento do Contrato de Consórcio Fiat/Embracon',
      'version', '3',
      'references', jsonb_build_array(
        'Lei 11.795/2008',
        'Circular 3432/09',
        'Resolução 285/23',
        'C.E. 07/24'
      )
    )
  ),
  jsonb_build_object(
    'catalog_family', 'regulatory',
    'brand', 'Consórcio Fiat',
    'administrator', 'Embracon',
    'source_content_sha256', '74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a',
    'authoring_document_sha256', '7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200',
    'approval_policy_defined', false,
    'approval_threshold_placeholder', 100,
    'legal_threshold_placeholder', 100,
    'approval_threshold_strategy', 'fail_closed_until_publication',
    'review_policy_defined', false,
    'legal_review_required_before_publication', true,
    'source_consistency_review_required', true,
    'external_currency_verified', false,
    'homologation_status', 'draft_catalog'
  )
);

insert into public.assessment_version_sources (
  id, organization_id, test_version_id, source_material_version_id,
  relation_type, is_required, notes, metadata
)
values (
  '3687644e-b67e-5e53-8a8f-cc5af4e390a0'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '74243315-ea1e-5178-83b8-d6077ab9dc59'::uuid,
  'dadf433e-5d7c-5373-b926-ed299332598f'::uuid,
  'primary',
  true,
  'Fonte normativa primária da Avaliação Regulamentar — Consórcio Fiat.',
  jsonb_build_object(
    'catalog_family', 'regulatory',
    'brand', 'Consórcio Fiat',
    'administrator', 'Embracon',
    'source_content_sha256', '74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a',
    'authoring_document_sha256', '7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200'
  )
);

-- --------------------------------------------------------------------------
-- 4. Questões, alternativas, gabaritos privados e vínculo com a versão
-- --------------------------------------------------------------------------
with payload as (
  select *
  from jsonb_to_recordset($fiat_questions$[{"id":"4e67f62d-7459-5156-b454-e5c5e81fe996","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q01","competency_id":"c6ee4867-0fb4-55fa-a6e7-9160d44f43cb","block_code":"definicoes_fundamentos","prompt":"Segundo as definições do Regulamento, o que é \"Consórcio\"?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":1,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"66b5e359-9c13-5785-886f-31ff7315bf25","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q02","competency_id":"c6ee4867-0fb4-55fa-a6e7-9160d44f43cb","block_code":"definicoes_fundamentos","prompt":"O \"Fundo Comum\" é definido no Regulamento como:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":2,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"46816946-acc6-596d-9785-1df2fe7eab68","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q03","competency_id":"c6ee4867-0fb4-55fa-a6e7-9160d44f43cb","block_code":"definicoes_fundamentos","prompt":"Conforme as definições do Regulamento, a \"Taxa de Administração\" corresponde a:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":3,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"bdc9d758-b2ec-5b85-8abc-315c6c038b92","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q04","competency_id":"5a7038d1-5e51-57f4-8f2f-d00eb192d5af","block_code":"planos","prompt":"No **Plano Justo®**, o benefício de isenção da taxa de administração aplica-se:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":4,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"7ccc05c5-513e-5e90-8cbb-e7440df65ab8","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q05","competency_id":"5a7038d1-5e51-57f4-8f2f-d00eb192d5af","block_code":"planos","prompt":"No plano **MAIS POR MENOS® 50**, o percentual de recolhimento mensal ao fundo comum e ao fundo de reserva é reduzido, até a contemplação, em:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":5,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"a543cb70-afba-5091-823d-5768a26ac85a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q06","competency_id":"5a7038d1-5e51-57f4-8f2f-d00eb192d5af","block_code":"planos","prompt":"O plano **PLANO JUSTO MAIS POR MENOS** combina, cumulativamente, quais características?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":6,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"1f008d0d-40aa-5b34-9453-1274c2d9411e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q07","competency_id":"dd860ec5-86b1-53cc-be5f-6ba5158f371a","block_code":"contribuicoes_taxas","prompt":"A contribuição mensal do consorciado, para efeito de aquisição do bem, deve ser calculada com base:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":7,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"5ea76c9d-cf5e-5129-9e53-e819d2415369","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q08","competency_id":"dd860ec5-86b1-53cc-be5f-6ba5158f371a","block_code":"contribuicoes_taxas","prompt":"Em relação à Taxa de Administração Antecipada, é correto afirmar que:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":8,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"6fa7b94a-6dc3-50d0-8a60-405cbfe5f218","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q09","competency_id":"dd860ec5-86b1-53cc-be5f-6ba5158f371a","block_code":"contribuicoes_taxas","prompt":"Sobre as contribuições em atraso, o Regulamento estabelece juros e multa moratória, respectivamente, de:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":9,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"cc675715-cf8b-5e50-af51-0e92ad4697fd","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q10","competency_id":"4fcf7be5-4739-5de8-b52e-f19164f7e6c6","block_code":"constituicao_grupo","prompt":"O grupo de consórcio é considerado formado a partir de qual marco?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":10,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"ea4399af-8f79-5f59-aa4b-49b195b320ba","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q11","competency_id":"4fcf7be5-4739-5de8-b52e-f19164f7e6c6","block_code":"constituicao_grupo","prompt":"Em grupo com créditos de valores diferenciados, o crédito de menor valor, vigente na data de constituição do grupo, não poderá ser inferior a:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":11,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"67e0aed3-956d-5a6a-955c-85676ea64b4b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q12","competency_id":"4fcf7be5-4739-5de8-b52e-f19164f7e6c6","block_code":"constituicao_grupo","prompt":"É permitido ao consorciado ter mais de uma cota em um mesmo grupo, desde que limitado a qual percentual máximo em relação ao número de cotas ativas do grupo, no ato da venda?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":12,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"acb88d41-7a74-5cbf-8cf9-654f18c0f0f1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q13","competency_id":"e7591bfd-4ff5-5e36-8661-b3a072cd9dff","block_code":"assembleias","prompt":"As Assembleias Gerais Ordinárias, destinadas à contemplação, serão realizadas:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":13,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"09c5d469-2e80-5598-89a3-ab5f0dcd11be","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q14","competency_id":"e7591bfd-4ff5-5e36-8661-b3a072cd9dff","block_code":"assembleias","prompt":"A Assembleia Geral Extraordinária pode ser convocada pela Administradora por sua iniciativa ou por solicitação de, no mínimo:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":14,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"8e5638d3-b0a9-566d-8661-c969ceac8b09","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q15","competency_id":"e7591bfd-4ff5-5e36-8661-b3a072cd9dff","block_code":"assembleias","prompt":"A convocação da Assembleia Geral Extraordinária pela Administradora deve ser efetuada com qual antecedência mínima?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":15,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"75309399-dc53-505c-84fb-153cecd895f5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q16","competency_id":"c0534141-ebbf-5ff9-9bdd-ae8a91a48c01","block_code":"contemplacao_lances","prompt":"Qual é a ordem de contemplação estabelecida para a Assembleia Geral Ordinária?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":16,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"1a5991f9-bcf7-507b-b2e5-25f752322d8b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q17","competency_id":"c0534141-ebbf-5ff9-9bdd-ae8a91a48c01","block_code":"contemplacao_lances","prompt":"Para participar do sorteio e concorrer aos lances, o consorciado ativo deve estar:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":17,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"edeb145c-5f79-5f48-b7bc-f67452c22f34","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q18","competency_id":"c0534141-ebbf-5ff9-9bdd-ae8a91a48c01","block_code":"contemplacao_lances","prompt":"A apuração do resultado do sorteio nas Assembleias Gerais Ordinárias tem como referência:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":18,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"e2efcdde-2bef-508d-befb-a53fd824ac2c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q19","competency_id":"c0534141-ebbf-5ff9-9bdd-ae8a91a48c01","block_code":"contemplacao_lances","prompt":"O valor de um lance ofertado não pode ser inferior a qual percentual do saldo devedor do consorciado licitante?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":19,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"ae6eecb6-a986-5aca-9437-68dc7be5b9b3","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q20","competency_id":"c0534141-ebbf-5ff9-9bdd-ae8a91a48c01","block_code":"contemplacao_lances","prompt":"Após a Assembleia Geral Ordinária de contemplação por lance, qual é o prazo improrrogável para cobertura (pagamento) do lance vencedor?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":20,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"cd184f1f-19da-57a1-981a-1be6ae73fb18","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q21","competency_id":"87ba9d19-2195-5fb2-96d3-99a53cb7fb88","block_code":"credito_garantias","prompt":"A Administradora deve colocar à disposição do consorciado contemplado o respectivo crédito em qual prazo?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":21,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"a0a3b8b7-ad56-5e9b-aeab-7802ce9b832e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q22","competency_id":"87ba9d19-2195-5fb2-96d3-99a53cb7fb88","block_code":"credito_garantias","prompt":"Quanto à utilização do crédito, o Regulamento estabelece que:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":22,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"68fe3ce6-a83c-5c63-ac7f-d87215e19e20","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q23","competency_id":"87ba9d19-2195-5fb2-96d3-99a53cb7fb88","block_code":"credito_garantias","prompt":"Caso o consorciado contemplado não utilize o crédito disponibilizado, ele poderá solicitar a conversão em espécie após transcorrido qual prazo da contemplação?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":23,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"0b223319-73aa-507e-b83f-20ad3ee46867","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q24","competency_id":"87ba9d19-2195-5fb2-96d3-99a53cb7fb88","block_code":"credito_garantias","prompt":"Qual é a modalidade de garantia principal utilizada nos contratos, conforme o Regulamento?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":24,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"c8025657-bd66-5bc4-bba9-584ad61e7390","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q25","competency_id":"87ba9d19-2195-5fb2-96d3-99a53cb7fb88","block_code":"credito_garantias","prompt":"A Administradora dispõe de qual prazo para apreciar a documentação relativa às garantias oferecidas, contado do recebimento?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":25,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"1eec9eef-2e61-50da-9424-f9b7e2036fc9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q26","competency_id":"a31ceaeb-4651-592f-8fbf-f86a8d786a0c","block_code":"cessao_exclusao_prescricao","prompt":"Na cessão do contrato a terceiros, a taxa de transferência devida à Administradora equivale a:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":26,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"884c16a1-87a3-5b8b-b587-0c81a8d0b44a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q27","competency_id":"a31ceaeb-4651-592f-8fbf-f86a8d786a0c","block_code":"cessao_exclusao_prescricao","prompt":"Sobre a cessão de direitos e obrigações do contrato, é correto afirmar que:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":27,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"ab0550ec-263b-526e-8808-75fa558d2546","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q28","competency_id":"a31ceaeb-4651-592f-8fbf-f86a8d786a0c","block_code":"cessao_exclusao_prescricao","prompt":"O consorciado não contemplado que deixar de realizar suas contribuições mensais por quantas vezes, consecutivas ou alternadas, será excluído do grupo, independentemente de aviso ou notificação?","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":28,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog","source_consistency_review_note":"Revisar antes da publicação: o material de autoria fundamenta o item na Cláusula 39; a fonte normativa fornecida apresenta menções divergentes sobre a quantidade de parcelas em outros trechos."}},{"id":"79c645af-6c5a-5565-bfa9-e8bb7fa3381c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q29","competency_id":"a31ceaeb-4651-592f-8fbf-f86a8d786a0c","block_code":"cessao_exclusao_prescricao","prompt":"A restituição de valores ao consorciado excluído é considerada:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":29,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}},{"id":"b651784d-aacf-50a9-91ad-cd92523f12c1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","code":"reg_fiat_q30","competency_id":"a31ceaeb-4651-592f-8fbf-f86a8d786a0c","block_code":"cessao_exclusao_prescricao","prompt":"Segundo o Regulamento, a pretensão do consorciado ativo e do consorciado excluído contra o grupo e/ou contra a Administradora prescreve em:","question_type":"single_choice","difficulty":"intermediate_advanced","content_version":"fiat-v3-v1","legal_review_date":null,"status":"draft","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":30,"source_material_code":"regulamento_fiat_embracon_v3","source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document":"Teste_07_Regulamento_Consorcio_Fiat.md","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","legal_review_required_before_publication":true,"homologation_status":"draft_catalog"}}]$fiat_questions$::jsonb) as x(
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
  from jsonb_to_recordset($fiat_options$[{"id":"479e0746-4087-5921-bc5b-c53d6fe5cf81","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4e67f62d-7459-5156-b454-e5c5e81fe996","option_code":"A","option_text":"Um contrato de financiamento bancário tradicional","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":1}},{"id":"51ccf87d-9810-50ff-adc3-ecb0b18e637a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4e67f62d-7459-5156-b454-e5c5e81fe996","option_code":"B","option_text":"A reunião de pessoas para atingirem um objetivo comum por meio do Grupo de Consórcio, visando à aquisição de bens pelo autofinanciamento","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":1}},{"id":"2a71d27a-ad85-561a-9112-00b66235e710","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4e67f62d-7459-5156-b454-e5c5e81fe996","option_code":"C","option_text":"Um seguro de proteção patrimonial coletivo","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":1}},{"id":"a0a84670-a741-571d-86ad-ac3e458afe84","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"4e67f62d-7459-5156-b454-e5c5e81fe996","option_code":"D","option_text":"Uma modalidade de investimento em renda fixa","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":1}},{"id":"4eddefec-05bd-59a0-b250-727d4c1246c6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"66b5e359-9c13-5785-886f-31ff7315bf25","option_code":"A","option_text":"O recurso destinado exclusivamente ao pagamento da taxa de administração","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":2}},{"id":"c680217b-6884-54a5-8a32-a20270deb847","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"66b5e359-9c13-5785-886f-31ff7315bf25","option_code":"B","option_text":"A arrecadação do grupo de consórcio destinada ao pagamento dos créditos devidos aos consorciados ativos e excluídos, após a contemplação, e demais pagamentos previstos","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":2}},{"id":"c226c71e-e15c-55d6-b3fd-85901806d80f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"66b5e359-9c13-5785-886f-31ff7315bf25","option_code":"C","option_text":"O valor pago apenas pelos consorciados contemplados","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":2}},{"id":"8fa9f66b-0d68-593b-8440-9af9bffab612","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"66b5e359-9c13-5785-886f-31ff7315bf25","option_code":"D","option_text":"A reserva técnica exigida pela Susep para seguros vinculados","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":2}},{"id":"cdb2b9fd-b11b-526b-b13c-c43c1780a732","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"46816946-acc6-596d-9785-1df2fe7eab68","option_code":"A","option_text":"Um encargo cobrado apenas em caso de inadimplência","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":3}},{"id":"170a9e1a-ed77-597e-9e52-662fe218dede","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"46816946-acc6-596d-9785-1df2fe7eab68","option_code":"B","option_text":"O valor pago exclusivamente para custear o seguro de vida em grupo","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":3}},{"id":"2c8c6bf0-e888-5d4c-bab9-b392c680f125","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"46816946-acc6-596d-9785-1df2fe7eab68","option_code":"C","option_text":"A remuneração da Administradora paga pelo consorciado, visando à prestação de serviços de formação, organização e gestão do grupo","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":3}},{"id":"bfe64eec-3126-5fbc-bcd1-bd1f35fa350e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"46816946-acc6-596d-9785-1df2fe7eab68","option_code":"D","option_text":"O rendimento da aplicação financeira do fundo comum","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":3}},{"id":"62bbe17a-d077-55b8-91a1-04012786ec7d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"bdc9d758-b2ec-5b85-8abc-315c6c038b92","option_code":"A","option_text":"Sobre todas as parcelas, inclusive após a contemplação","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":4}},{"id":"dee524f6-75d8-52ec-aa20-11cf78a05d14","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"bdc9d758-b2ec-5b85-8abc-315c6c038b92","option_code":"B","option_text":"Apenas à taxa de administração antecipada","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":4}},{"id":"dddc8c39-c5bc-542f-afdd-cd9a40662e80","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"bdc9d758-b2ec-5b85-8abc-315c6c038b92","option_code":"C","option_text":"Sobre cada parcela paga até a contemplação da cota, excetuando-se a taxa de administração antecipada, que incide nas primeiras parcelas","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":4}},{"id":"65d5f7bf-a22c-5644-84be-0caf3210ed5c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"bdc9d758-b2ec-5b85-8abc-315c6c038b92","option_code":"D","option_text":"Somente aos consorciados excluídos","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":4}},{"id":"1cefab45-789d-53a9-b73b-a946e782a21c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"7ccc05c5-513e-5e90-8cbb-e7440df65ab8","option_code":"A","option_text":"25% (vinte e cinco por cento)","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":5}},{"id":"92ddfd16-2a3a-5e3a-b0c9-443187b698f4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"7ccc05c5-513e-5e90-8cbb-e7440df65ab8","option_code":"B","option_text":"50% (cinquenta por cento)","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":5}},{"id":"aa9813d3-24e3-53ef-9611-36eb68b768ba","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"7ccc05c5-513e-5e90-8cbb-e7440df65ab8","option_code":"C","option_text":"75% (setenta e cinco por cento)","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":5}},{"id":"023afacb-40cc-5daa-82fb-1c2c6088aa5a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"7ccc05c5-513e-5e90-8cbb-e7440df65ab8","option_code":"D","option_text":"10% (dez por cento)","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":5}},{"id":"ea39663d-bb26-598a-b1c4-e0d18e2fa4db","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a543cb70-afba-5091-823d-5768a26ac85a","option_code":"A","option_text":"Isenção da taxa de administração até a contemplação (exceto a antecipada) + redução de 25% no recolhimento ao fundo comum até a contemplação","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":6}},{"id":"e9a05fd7-2f60-55b1-872c-7dcb0b9d0ba4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a543cb70-afba-5091-823d-5768a26ac85a","option_code":"B","option_text":"Redução de 50% no fundo comum + isenção total da taxa de administração","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":6}},{"id":"fb952546-434a-5cbd-9dfc-9c09932325d0","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a543cb70-afba-5091-823d-5768a26ac85a","option_code":"C","option_text":"Apenas a isenção da taxa de administração antecipada","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":6}},{"id":"c3f2bc4a-a0fa-5cce-82ed-70a8e9a7fa3c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a543cb70-afba-5091-823d-5768a26ac85a","option_code":"D","option_text":"Redução de 25% no fundo comum sem qualquer isenção de taxa de administração","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":6}},{"id":"7acb383f-b168-5d82-bfa7-49bed873d75f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1f008d0d-40aa-5b34-9453-1274c2d9411e","option_code":"A","option_text":"No valor do crédito na data da assinatura do contrato, sem qualquer atualização","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":7}},{"id":"d7bfd2b3-420d-52f0-bc91-f65fd1291c99","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1f008d0d-40aa-5b34-9453-1274c2d9411e","option_code":"B","option_text":"No valor do crédito vigente na data da assembleia ordinária do mês de pagamento","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":7}},{"id":"03a18090-fcca-5010-86d8-a37758e04e3f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1f008d0d-40aa-5b34-9453-1274c2d9411e","option_code":"C","option_text":"Exclusivamente na tabela FIPE do mês anterior","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":7}},{"id":"c22ba5ba-7037-5e1b-915a-a823a15dfdc8","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1f008d0d-40aa-5b34-9453-1274c2d9411e","option_code":"D","option_text":"No valor médio do crédito nos últimos 12 meses","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":7}},{"id":"82284d7a-e9d3-5e12-9c31-eb7e900fb387","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"5ea76c9d-cf5e-5129-9e53-e819d2415369","option_code":"A","option_text":"É cobrada além do percentual total da taxa de administração contratada","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":8}},{"id":"fecaef13-38f2-53a6-b5d5-e720016525eb","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"5ea76c9d-cf5e-5129-9e53-e819d2415369","option_code":"B","option_text":"É integralmente deduzida do valor total da taxa de administração contratada","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":8}},{"id":"c6d5d645-685b-59b4-a330-d2274956bfd4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"5ea76c9d-cf5e-5129-9e53-e819d2415369","option_code":"C","option_text":"Somente incide após a contemplação da cota","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":8}},{"id":"28ca7521-6ab8-5ad0-98e0-a993909dfe6c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"5ea76c9d-cf5e-5129-9e53-e819d2415369","option_code":"D","option_text":"É restituída ao consorciado ao final do grupo, independentemente da contemplação","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":8}},{"id":"0791e8ec-abdc-5de3-9b57-edb1f3463a1e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"6fa7b94a-6dc3-50d0-8a60-405cbfe5f218","option_code":"A","option_text":"Juros de 2% ao mês e multa de 1%","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":9}},{"id":"6542caed-fb66-5b09-aa00-8f15fba2274b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"6fa7b94a-6dc3-50d0-8a60-405cbfe5f218","option_code":"B","option_text":"Juros de 1% ao mês e multa moratória de 2%, calculados sobre o valor atualizado das contribuições em atraso","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":9}},{"id":"a4632058-182d-55be-ac9c-46afd0f362e0","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"6fa7b94a-6dc3-50d0-8a60-405cbfe5f218","option_code":"C","option_text":"Juros de 0,5% ao mês, sem incidência de multa","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":9}},{"id":"018fa8d1-b780-57a7-8506-7729c61a61bc","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"6fa7b94a-6dc3-50d0-8a60-405cbfe5f218","option_code":"D","option_text":"Juros e multa livremente fixados pela Administradora, sem limite","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":9}},{"id":"8b6bfb13-a27e-5847-bb89-f9add1c68248","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"cc675715-cf8b-5e50-af51-0e92ad4697fd","option_code":"A","option_text":"Da assinatura do contrato pelo primeiro consorciado","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":10}},{"id":"d413ac77-4f72-56ee-916c-591b4e2a86fd","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"cc675715-cf8b-5e50-af51-0e92ad4697fd","option_code":"B","option_text":"Da realização da primeira Assembleia Geral Ordinária, cujo prazo de duração é contado a partir dessa data","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":10}},{"id":"33ee44aa-5d9a-55c4-95a8-3d406104ffdf","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"cc675715-cf8b-5e50-af51-0e92ad4697fd","option_code":"C","option_text":"Do pagamento da última parcela do plano","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":10}},{"id":"c3c0b419-f329-5d99-accb-a79324ad2155","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"cc675715-cf8b-5e50-af51-0e92ad4697fd","option_code":"D","option_text":"Do registro do grupo em cartório de títulos e documentos","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":10}},{"id":"11556f19-a73f-57d0-a16a-b311700f03ad","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ea4399af-8f79-5f59-aa4b-49b195b320ba","option_code":"A","option_text":"30% do crédito de maior valor do grupo","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":11}},{"id":"ec14ce16-f2de-50d0-89c1-41c99231f6b2","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ea4399af-8f79-5f59-aa4b-49b195b320ba","option_code":"B","option_text":"50% do crédito de maior valor do grupo","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":11}},{"id":"7fc19d20-4f03-5253-aef2-a6740a068381","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ea4399af-8f79-5f59-aa4b-49b195b320ba","option_code":"C","option_text":"70% do crédito de maior valor do grupo","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":11}},{"id":"2a8ae9d4-8bae-535e-a990-cb101e31a1ce","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ea4399af-8f79-5f59-aa4b-49b195b320ba","option_code":"D","option_text":"Não há limite mínimo estabelecido","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":11}},{"id":"b3468544-02c8-594c-aa4c-e75a231b32c2","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"67e0aed3-956d-5a6a-955c-85676ea64b4b","option_code":"A","option_text":"5% (cinco por cento)","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":12}},{"id":"73424b3b-4927-5e3c-b7e1-3c1935ed6218","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"67e0aed3-956d-5a6a-955c-85676ea64b4b","option_code":"B","option_text":"10% (dez por cento)","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":12}},{"id":"288deaa9-b83e-5f16-afe5-ffef6af890e7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"67e0aed3-956d-5a6a-955c-85676ea64b4b","option_code":"C","option_text":"15% (quinze por cento)","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":12}},{"id":"3462e00b-47a7-5ae3-870e-91df1b408ed3","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"67e0aed3-956d-5a6a-955c-85676ea64b4b","option_code":"D","option_text":"20% (vinte por cento)","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":12}},{"id":"11da5fae-a423-5da3-a67d-17930adf5153","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"acb88d41-7a74-5cbf-8cf9-654f18c0f0f1","option_code":"A","option_text":"Trimestralmente, na sede da Administradora","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":13}},{"id":"32566782-6934-58d9-809f-dc3ce9847fe4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"acb88d41-7a74-5cbf-8cf9-654f18c0f0f1","option_code":"B","option_text":"Mensalmente, de forma eletrônica, na sede da Prestadora de Serviços de Administração","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":13}},{"id":"d8929778-9093-5bed-89a2-0dc20d400c2d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"acb88d41-7a74-5cbf-8cf9-654f18c0f0f1","option_code":"C","option_text":"Somente quando solicitadas por 30% dos consorciados","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":13}},{"id":"631f5364-6fcf-524a-96c5-2d604a8999f7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"acb88d41-7a74-5cbf-8cf9-654f18c0f0f1","option_code":"D","option_text":"Anualmente, coincidindo com a data de aniversário do grupo","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":13}},{"id":"7e62bd21-96a9-5a7e-91a1-b14aefd569c6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"09c5d469-2e80-5598-89a3-ab5f0dcd11be","option_code":"A","option_text":"10% dos consorciados","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":14}},{"id":"7ec75724-4c8a-5b13-85b2-87e407d7f9ed","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"09c5d469-2e80-5598-89a3-ab5f0dcd11be","option_code":"B","option_text":"20% dos consorciados","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":14}},{"id":"ca1debfd-8631-5136-8a58-271f00a1a02a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"09c5d469-2e80-5598-89a3-ab5f0dcd11be","option_code":"C","option_text":"30% dos consorciados","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":14}},{"id":"0ee37a4b-a16b-5ea4-b4e1-7e92972db23b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"09c5d469-2e80-5598-89a3-ab5f0dcd11be","option_code":"D","option_text":"50% dos consorciados","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":14}},{"id":"feb832b5-3800-5805-b662-f5a1c3b1eedd","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"8e5638d3-b0a9-566d-8661-c969ceac8b09","option_code":"A","option_text":"3 dias úteis","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":15}},{"id":"88226e5c-acd5-50ec-9aa9-8c7e2eb5ea6e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"8e5638d3-b0a9-566d-8661-c969ceac8b09","option_code":"B","option_text":"5 dias úteis","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":15}},{"id":"e9befb00-e116-59d7-bdaa-ba68444e9f60","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"8e5638d3-b0a9-566d-8661-c969ceac8b09","option_code":"C","option_text":"8 dias úteis","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":15}},{"id":"e4f59d31-30a2-5471-8008-b93810b35da7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"8e5638d3-b0a9-566d-8661-c969ceac8b09","option_code":"D","option_text":"15 dias úteis","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":15}},{"id":"d412c08f-9c57-5e58-baab-d6ba0caef692","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"75309399-dc53-505c-84fb-153cecd895f5","option_code":"A","option_text":"Primeiro os lances, depois os sorteios aos ativos e, por fim, aos excluídos","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":16}},{"id":"b686ee96-d9df-55ce-9920-cb6e92e962c2","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"75309399-dc53-505c-84fb-153cecd895f5","option_code":"B","option_text":"Primeiro sorteio aos consorciados ativos, depois sorteio aos excluídos (se houver saldo) e, em seguida, contemplação por lance","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":16}},{"id":"6e4ddfd0-6fa9-5f2e-99e2-0b18bfee1561","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"75309399-dc53-505c-84fb-153cecd895f5","option_code":"C","option_text":"Somente por lance, sendo o sorteio uma modalidade extraordinária","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":16}},{"id":"ec8f1d1e-1d5f-54da-b3aa-cd9957e3b7f0","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"75309399-dc53-505c-84fb-153cecd895f5","option_code":"D","option_text":"Alternância aleatória definida a cada assembleia pela Administradora","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":16}},{"id":"95892490-92a2-5361-9247-4dffd25d24c7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1a5991f9-bcf7-507b-b2e5-25f752322d8b","option_code":"A","option_text":"Contemplado em assembleia anterior","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":17}},{"id":"ccd4c8b3-4161-5421-9df7-6f89c0c013ac","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1a5991f9-bcf7-507b-b2e5-25f752322d8b","option_code":"B","option_text":"Em dia com suas contribuições até a data do vencimento de sua parcela, anterior à assembleia de contemplação","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":17}},{"id":"73c01d8b-4223-5aad-b46e-acf90501d8e4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1a5991f9-bcf7-507b-b2e5-25f752322d8b","option_code":"C","option_text":"Com todas as parcelas do plano já quitadas","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":17}},{"id":"c28c73a0-9b12-5894-9501-c789afdda19b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1a5991f9-bcf7-507b-b2e5-25f752322d8b","option_code":"D","option_text":"Inscrito previamente em lista de espera junto à Administradora","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":17}},{"id":"44326e11-c498-5777-b2b4-4b61e4ab923b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"edeb145c-5f79-5f48-b7bc-f67452c22f34","option_code":"A","option_text":"O resultado da Mega-Sena do sábado anterior","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":18}},{"id":"ea42dd21-2bb9-5ea7-8be7-8dce2f5ea2ab","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"edeb145c-5f79-5f48-b7bc-f67452c22f34","option_code":"B","option_text":"Sorteio interno realizado eletronicamente pela Administradora","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":18}},{"id":"f420c90b-351d-526d-82c6-87f9680d2e68","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"edeb145c-5f79-5f48-b7bc-f67452c22f34","option_code":"C","option_text":"O resultado da extração da Loteria Federal imediatamente anterior à data da assembleia","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":18}},{"id":"d892714b-69f0-5135-8e1e-58fdff69b123","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"edeb145c-5f79-5f48-b7bc-f67452c22f34","option_code":"D","option_text":"A ordem cronológica de adesão dos consorciados ao grupo","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":18}},{"id":"07c92ab3-2e72-5434-8109-c4602a4bdcae","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"e2efcdde-2bef-508d-befb-a53fd824ac2c","option_code":"A","option_text":"0,5%","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":19}},{"id":"8bcc2ac9-26d7-568f-99f6-d41188090c93","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"e2efcdde-2bef-508d-befb-a53fd824ac2c","option_code":"B","option_text":"1%","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":19}},{"id":"b4b0f9b5-dd15-588d-b3e0-decf3f9d6d42","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"e2efcdde-2bef-508d-befb-a53fd824ac2c","option_code":"C","option_text":"2%","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":19}},{"id":"42044ab8-ac75-544f-8ea7-30610e940e23","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"e2efcdde-2bef-508d-befb-a53fd824ac2c","option_code":"D","option_text":"5%","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":19}},{"id":"377ddeff-ec1f-5f53-855f-70ab107138b1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ae6eecb6-a986-5aca-9437-68dc7be5b9b3","option_code":"A","option_text":"48 horas","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":20}},{"id":"1b9915ca-0091-52d9-a325-3ef40f2a3c2a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ae6eecb6-a986-5aca-9437-68dc7be5b9b3","option_code":"B","option_text":"3 dias úteis","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":20}},{"id":"ef8802ca-5265-5505-a7bd-84b52288bed2","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ae6eecb6-a986-5aca-9437-68dc7be5b9b3","option_code":"C","option_text":"5 dias úteis","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":20}},{"id":"1c8baa9f-0584-5d6a-93c6-d1add8130694","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ae6eecb6-a986-5aca-9437-68dc7be5b9b3","option_code":"D","option_text":"10 dias úteis","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":20}},{"id":"6590aae6-8a87-54cf-8455-b07258a96e03","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"cd184f1f-19da-57a1-981a-1be6ae73fb18","option_code":"A","option_text":"Imediatamente na data da assembleia","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":21}},{"id":"624a7909-233c-5b96-a1ac-f51ccf4a62f4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"cd184f1f-19da-57a1-981a-1be6ae73fb18","option_code":"B","option_text":"Até o 3º (terceiro) dia útil após a contemplação","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":21}},{"id":"d9999747-45b6-595c-a532-2f854e0d674b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"cd184f1f-19da-57a1-981a-1be6ae73fb18","option_code":"C","option_text":"Até 30 dias após a contemplação","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":21}},{"id":"5d25e367-bc38-51e8-86df-c756cab67c6b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"cd184f1f-19da-57a1-981a-1be6ae73fb18","option_code":"D","option_text":"Até 90 dias após a contemplação","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":21}},{"id":"889d07d1-2e2a-5c9e-b7cd-62e1c1792d9e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a0a3b8b7-ad56-5e9b-aeab-7802ce9b832e","option_code":"A","option_text":"O consorciado pode adquirir qualquer bem, independentemente do segmento contratado","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":22}},{"id":"8a6067f5-50b6-5eda-af70-3af87f46b996","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a0a3b8b7-ad56-5e9b-aeab-7802ce9b832e","option_code":"B","option_text":"É vedada a aquisição de bem de natureza, categoria e espécie diversa do referenciado como Básico do Plano","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":22}},{"id":"6feac809-e664-568d-a434-d7a2b1c88e5f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a0a3b8b7-ad56-5e9b-aeab-7802ce9b832e","option_code":"C","option_text":"A aquisição de bem de outro segmento é livre, desde que autorizada verbalmente pela Administradora","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":22}},{"id":"fceaa636-5917-5d58-b78f-47393cb6ed0a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"a0a3b8b7-ad56-5e9b-aeab-7802ce9b832e","option_code":"D","option_text":"O crédito só pode ser usado para quitação de dívidas bancárias do consorciado","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":22}},{"id":"0344e27f-fc5b-5cb8-81fb-99357853cd4b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"68fe3ce6-a83c-5c63-ac7f-d87215e19e20","option_code":"A","option_text":"90 dias","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":23}},{"id":"badc6578-1ebd-5c00-8def-d36531997fb4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"68fe3ce6-a83c-5c63-ac7f-d87215e19e20","option_code":"B","option_text":"120 dias","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":23}},{"id":"02ed8fc3-ee06-5e94-9718-95c708dbb267","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"68fe3ce6-a83c-5c63-ac7f-d87215e19e20","option_code":"C","option_text":"180 dias","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":23}},{"id":"bdfc1565-eeb9-5b16-a4e7-9a88eaad5ff4","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"68fe3ce6-a83c-5c63-ac7f-d87215e19e20","option_code":"D","option_text":"360 dias","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":23}},{"id":"3e704081-6ef0-5b9f-84c3-88bd7b1d4004","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"0b223319-73aa-507e-b83f-20ad3ee46867","option_code":"A","option_text":"Hipoteca","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":24}},{"id":"2285c667-0fc0-5d95-aa2c-80b9a8639923","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"0b223319-73aa-507e-b83f-20ad3ee46867","option_code":"B","option_text":"Penhor mercantil","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":24}},{"id":"e8f565f9-9681-5391-8553-1f190367c7ab","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"0b223319-73aa-507e-b83f-20ad3ee46867","option_code":"C","option_text":"Alienação Fiduciária","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":24}},{"id":"64441e64-6c83-5c45-b4be-57cf524bde4f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"0b223319-73aa-507e-b83f-20ad3ee46867","option_code":"D","option_text":"Fiança bancária","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":24}},{"id":"4e13dcc1-7f20-5d22-9448-10223ea88c03","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c8025657-bd66-5bc4-bba9-584ad61e7390","option_code":"A","option_text":"3 dias úteis","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":25}},{"id":"024fbb78-2183-5ca4-9068-d934dde6b37f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c8025657-bd66-5bc4-bba9-584ad61e7390","option_code":"B","option_text":"5 dias úteis","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":25}},{"id":"d2b76568-34c8-5216-8102-045818dbb5a0","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c8025657-bd66-5bc4-bba9-584ad61e7390","option_code":"C","option_text":"10 dias úteis","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":25}},{"id":"e89b55bf-84e9-5891-a74b-9c7b27744d4c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"c8025657-bd66-5bc4-bba9-584ad61e7390","option_code":"D","option_text":"15 dias úteis","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":25}},{"id":"9905c36c-5c06-56e3-8e21-fc227866a449","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1eec9eef-2e61-50da-9424-f9b7e2036fc9","option_code":"A","option_text":"0,5% do valor do crédito","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":26}},{"id":"597189da-2044-5679-9ee6-fb61ae2b9ab9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1eec9eef-2e61-50da-9424-f9b7e2036fc9","option_code":"B","option_text":"1% do valor atualizado do crédito","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":26}},{"id":"10e3a343-68f4-5efc-9da6-787cd40fe7f6","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1eec9eef-2e61-50da-9424-f9b7e2036fc9","option_code":"C","option_text":"2% do valor atualizado do crédito","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":26}},{"id":"06cfef73-8f16-50b6-85f1-7afa5de77253","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"1eec9eef-2e61-50da-9424-f9b7e2036fc9","option_code":"D","option_text":"5% do valor da cota já amortizada","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":26}},{"id":"2e88c276-f722-512b-8d07-2afe277678cb","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"884c16a1-87a3-5b8b-b587-0c81a8d0b44a","option_code":"A","option_text":"É permitida a simples cessão de direitos, bastando cientificar a Administradora","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":27}},{"id":"df245326-01b2-517a-9a50-2ebc65fc0b32","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"884c16a1-87a3-5b8b-b587-0c81a8d0b44a","option_code":"B","option_text":"É vedada a simples cessão; toda cessão deve se dar por meio da efetiva transferência da titularidade da cota, mediante Termo de Transferência e anuência da Administradora","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":27}},{"id":"ea87551e-fb99-50fa-900b-02fa38a64a39","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"884c16a1-87a3-5b8b-b587-0c81a8d0b44a","option_code":"C","option_text":"A cessão independe de qualquer análise de capacidade financeira do cessionário","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":27}},{"id":"58d91458-cf36-537c-b71e-fa2c4b48dfb2","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"884c16a1-87a3-5b8b-b587-0c81a8d0b44a","option_code":"D","option_text":"A cessão só pode ocorrer após o encerramento do grupo","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":27}},{"id":"12187015-b331-5d21-a451-d3674043d255","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ab0550ec-263b-526e-8808-75fa558d2546","option_code":"A","option_text":"2 (duas) vezes","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":28}},{"id":"855cd57d-5d4d-5e8f-a9ce-afb5607f9382","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ab0550ec-263b-526e-8808-75fa558d2546","option_code":"B","option_text":"3 (três) vezes","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":28}},{"id":"4eafac08-781f-5140-a099-3ceb74c0aa48","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ab0550ec-263b-526e-8808-75fa558d2546","option_code":"C","option_text":"4 (quatro) vezes","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":28}},{"id":"c8f8def9-2fc5-5aaf-aee0-512a64e9e70f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"ab0550ec-263b-526e-8808-75fa558d2546","option_code":"D","option_text":"5 (cinco) vezes","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":28}},{"id":"f4ef0c45-cafe-53ac-b370-b311cf8157df","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"79c645af-6c5a-5565-bfa9-e8bb7fa3381c","option_code":"A","option_text":"Crédito integral, correspondente a 100% do valor do bem","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":29}},{"id":"c956a891-6921-519b-8dd3-b14586a736c2","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"79c645af-6c5a-5565-bfa9-e8bb7fa3381c","option_code":"B","option_text":"Crédito parcial, calculado com base no percentual amortizado do crédito vigente na data da assembleia de contemplação","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":29}},{"id":"eb43713f-e637-5916-a1e2-8cedac077024","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"79c645af-6c5a-5565-bfa9-e8bb7fa3381c","option_code":"C","option_text":"Isenta de qualquer dedução, incluindo taxa de administração","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":29}},{"id":"6724fbc8-b0de-52b3-91a0-9e0af33d0500","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"79c645af-6c5a-5565-bfa9-e8bb7fa3381c","option_code":"D","option_text":"Realizada apenas mediante decisão judicial","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":29}},{"id":"89a1489b-5539-5f1d-85cf-ba51107e9374","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"b651784d-aacf-50a9-91ad-cd92523f12c1","option_code":"A","option_text":"1 (um) ano","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":30}},{"id":"d01715c3-98e8-5330-9c5f-4cc85be0c1e2","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"b651784d-aacf-50a9-91ad-cd92523f12c1","option_code":"B","option_text":"2 (dois) anos","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":30}},{"id":"c409164f-e15d-5ffb-8b1d-321cfa19dc73","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"b651784d-aacf-50a9-91ad-cd92523f12c1","option_code":"C","option_text":"3 (três) anos","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":30}},{"id":"9c06a9fe-5365-5a38-91b4-615881ff9658","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","question_id":"b651784d-aacf-50a9-91ad-cd92523f12c1","option_code":"D","option_text":"5 (cinco) anos","metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":30}}]$fiat_options$::jsonb) as x(
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
  from jsonb_to_recordset($fiat_keys$[{"question_id":"4e67f62d-7459-5156-b454-e5c5e81fe996","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Gabarito de autoria: alternativa B. Fundamento indicado: Definições — \"CONSÓRCIO\".","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Definições — \"CONSÓRCIO\"","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":1,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"66b5e359-9c13-5785-886f-31ff7315bf25","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Gabarito de autoria: alternativa B. Fundamento indicado: Definições — \"FUNDO COMUM\".","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Definições — \"FUNDO COMUM\"","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":2,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"46816946-acc6-596d-9785-1df2fe7eab68","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"Gabarito de autoria: alternativa C. Fundamento indicado: Definições — \"TAXA DE ADMINISTRAÇÃO E TAXA DE ADMINISTRAÇÃO ANTECIPADA\".","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Definições — \"TAXA DE ADMINISTRAÇÃO E TAXA DE ADMINISTRAÇÃO ANTECIPADA\"","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":3,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"bdc9d758-b2ec-5b85-8abc-315c6c038b92","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"Gabarito de autoria: alternativa C. Fundamento indicado: Cláusula 3.3 (Plano Justo®).","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 3.3 (Plano Justo®)","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":4,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"7ccc05c5-513e-5e90-8cbb-e7440df65ab8","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Gabarito de autoria: alternativa B. Fundamento indicado: Cláusula 3.4.1 (Plano Mais por Menos® 50).","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 3.4.1 (Plano Mais por Menos® 50)","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":5,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"a543cb70-afba-5091-823d-5768a26ac85a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"A","justification":"Gabarito de autoria: alternativa A. Fundamento indicado: Cláusula 3.4.2 (Plano Justo Mais por Menos).","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 3.4.2 (Plano Justo Mais por Menos)","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":6,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"1f008d0d-40aa-5b34-9453-1274c2d9411e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Gabarito de autoria: alternativa B. Fundamento indicado: Cláusula 3ª.","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 3ª","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":7,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"5ea76c9d-cf5e-5129-9e53-e819d2415369","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Gabarito de autoria: alternativa B. Fundamento indicado: Cláusula 10, Parágrafo Segundo.","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 10, Parágrafo Segundo","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":8,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"6fa7b94a-6dc3-50d0-8a60-405cbfe5f218","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Gabarito de autoria: alternativa B. Fundamento indicado: Cláusula 12, alínea \"b\".","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 12, alínea \"b\"","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":9,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"cc675715-cf8b-5e50-af51-0e92ad4697fd","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Gabarito de autoria: alternativa B. Fundamento indicado: Cláusula 11.","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 11","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":10,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"ea4399af-8f79-5f59-aa4b-49b195b320ba","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Gabarito de autoria: alternativa B. Fundamento indicado: Cláusula 11, Parágrafo Quinto.","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 11, Parágrafo Quinto","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":11,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"67e0aed3-956d-5a6a-955c-85676ea64b4b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Gabarito de autoria: alternativa B. Fundamento indicado: Cláusula 11, Parágrafo Sétimo.","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 11, Parágrafo Sétimo","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":12,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"acb88d41-7a74-5cbf-8cf9-654f18c0f0f1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Gabarito de autoria: alternativa B. Fundamento indicado: Cláusula 13, Parágrafo Único.","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 13, Parágrafo Único","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":13,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"09c5d469-2e80-5598-89a3-ab5f0dcd11be","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"Gabarito de autoria: alternativa C. Fundamento indicado: Cláusula 14, Parágrafo Terceiro.","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 14, Parágrafo Terceiro","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":14,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"8e5638d3-b0a9-566d-8661-c969ceac8b09","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"Gabarito de autoria: alternativa C. Fundamento indicado: Cláusula 14, Parágrafo Quinto.","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 14, Parágrafo Quinto","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":15,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"75309399-dc53-505c-84fb-153cecd895f5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Gabarito de autoria: alternativa B. Fundamento indicado: Cláusula 16.","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 16","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":16,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"1a5991f9-bcf7-507b-b2e5-25f752322d8b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Gabarito de autoria: alternativa B. Fundamento indicado: Cláusula 17.","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 17","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":17,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"edeb145c-5f79-5f48-b7bc-f67452c22f34","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"Gabarito de autoria: alternativa C. Fundamento indicado: Cláusula 18.","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 18","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":18,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"e2efcdde-2bef-508d-befb-a53fd824ac2c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Gabarito de autoria: alternativa B. Fundamento indicado: Cláusula 19, alínea \"a\".","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 19, alínea \"a\"","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":19,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"ae6eecb6-a986-5aca-9437-68dc7be5b9b3","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"Gabarito de autoria: alternativa C. Fundamento indicado: Cláusula 21.","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 21","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":20,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"cd184f1f-19da-57a1-981a-1be6ae73fb18","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Gabarito de autoria: alternativa B. Fundamento indicado: Cláusula 24.","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 24","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":21,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"a0a3b8b7-ad56-5e9b-aeab-7802ce9b832e","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Gabarito de autoria: alternativa B. Fundamento indicado: Cláusula 25.","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 25","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":22,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"68fe3ce6-a83c-5c63-ac7f-d87215e19e20","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"Gabarito de autoria: alternativa C. Fundamento indicado: Cláusula 32.","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 32","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":23,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"0b223319-73aa-507e-b83f-20ad3ee46867","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"C","justification":"Gabarito de autoria: alternativa C. Fundamento indicado: Cláusula 33, Parágrafo Único.","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 33, Parágrafo Único","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":24,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"c8025657-bd66-5bc4-bba9-584ad61e7390","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Gabarito de autoria: alternativa B. Fundamento indicado: Cláusula 34.","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 34","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":25,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"1eec9eef-2e61-50da-9424-f9b7e2036fc9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Gabarito de autoria: alternativa B. Fundamento indicado: Cláusula 37, *caput*.","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 37, *caput*","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":26,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"884c16a1-87a3-5b8b-b587-0c81a8d0b44a","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Gabarito de autoria: alternativa B. Fundamento indicado: Cláusula 37, Parágrafo Sexto.","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 37, Parágrafo Sexto","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":27,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"ab0550ec-263b-526e-8808-75fa558d2546","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Gabarito de autoria: alternativa B. Fundamento indicado: Cláusula 39.","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 39","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":28,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true,"source_consistency_review_required":true}},{"question_id":"79c645af-6c5a-5565-bfa9-e8bb7fa3381c","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"B","justification":"Gabarito de autoria: alternativa B. Fundamento indicado: Cláusula 40.","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 40","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":29,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}},{"question_id":"b651784d-aacf-50a9-91ad-cd92523f12c1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","correct_option_code":"D","justification":"Gabarito de autoria: alternativa D. Fundamento indicado: Cláusula 43.4.","source_reference":"Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 43.4","is_critical":false,"critical_reason":null,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","assessment_code":"regulamento_fiat_v1","question_number":30,"source_content_sha256":"74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a","authoring_document_sha256":"7ae8fdee110b3360ae9f3a832899056132b27b219014c48850b655ed92a19200","criticality_basis":"no_critical_items_declared_by_authoring_source","legal_review_required_before_publication":true}}]$fiat_keys$::jsonb) as x(
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

with payload as (
  select *
  from jsonb_to_recordset($fiat_version_questions$[{"id":"c3f9a2c2-cd43-5b4a-bc01-fdc46fdfd276","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"4e67f62d-7459-5156-b454-e5c5e81fe996","sequence_no":1,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":1}},{"id":"60eb7bd0-9617-5e27-b12f-7ca28c3cf639","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"66b5e359-9c13-5785-886f-31ff7315bf25","sequence_no":2,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":2}},{"id":"c1b376bf-2ba5-5e89-9859-2a821048a096","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"46816946-acc6-596d-9785-1df2fe7eab68","sequence_no":3,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":3}},{"id":"96ecaebd-11de-5d71-b42c-ec0cc398eda7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"bdc9d758-b2ec-5b85-8abc-315c6c038b92","sequence_no":4,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":4}},{"id":"479f699e-e98a-509a-8037-e28508f858ab","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"7ccc05c5-513e-5e90-8cbb-e7440df65ab8","sequence_no":5,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":5}},{"id":"7d20178b-dcd4-592a-b41f-7dd9176facb7","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"a543cb70-afba-5091-823d-5768a26ac85a","sequence_no":6,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":6}},{"id":"d0846360-aae2-5caa-b6d4-6f4d814509a1","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"1f008d0d-40aa-5b34-9453-1274c2d9411e","sequence_no":7,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":7}},{"id":"ebd63b89-5b0b-52b0-a599-65049ab5f776","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"5ea76c9d-cf5e-5129-9e53-e819d2415369","sequence_no":8,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":8}},{"id":"802c9115-83dc-57fc-9056-f45ebce90a71","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"6fa7b94a-6dc3-50d0-8a60-405cbfe5f218","sequence_no":9,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":9}},{"id":"d1c22991-6303-5cd2-8cb0-0c0856538c21","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"cc675715-cf8b-5e50-af51-0e92ad4697fd","sequence_no":10,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":10}},{"id":"0d92203b-1376-5a00-9f62-f4016702b9a9","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"ea4399af-8f79-5f59-aa4b-49b195b320ba","sequence_no":11,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":11}},{"id":"016b50d9-9af1-52e6-85b8-d09fbbf7df7b","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"67e0aed3-956d-5a6a-955c-85676ea64b4b","sequence_no":12,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":12}},{"id":"cea0a9a0-d2a9-5501-951b-29ab53562169","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"acb88d41-7a74-5cbf-8cf9-654f18c0f0f1","sequence_no":13,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":13}},{"id":"661f07a0-eaef-5735-b018-f456786ad240","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"09c5d469-2e80-5598-89a3-ab5f0dcd11be","sequence_no":14,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":14}},{"id":"29f124f4-1b45-5308-9898-238cb6da652d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"8e5638d3-b0a9-566d-8661-c969ceac8b09","sequence_no":15,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":15}},{"id":"594c72f6-0387-5379-9404-a7c976484729","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"75309399-dc53-505c-84fb-153cecd895f5","sequence_no":16,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":16}},{"id":"97c14a96-7820-5e9d-9b96-4e26236ca043","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"1a5991f9-bcf7-507b-b2e5-25f752322d8b","sequence_no":17,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":17}},{"id":"d8e5fda4-1584-5386-a2b7-7660a9c7bb14","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"edeb145c-5f79-5f48-b7bc-f67452c22f34","sequence_no":18,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":18}},{"id":"ddf9bac3-8c3a-5312-80a0-212faacff826","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"e2efcdde-2bef-508d-befb-a53fd824ac2c","sequence_no":19,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":19}},{"id":"50b85b32-2461-5bfd-b900-fd6ed89c264f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"ae6eecb6-a986-5aca-9437-68dc7be5b9b3","sequence_no":20,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":20}},{"id":"41926c53-ecee-520d-928f-3c80e3628e85","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"cd184f1f-19da-57a1-981a-1be6ae73fb18","sequence_no":21,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":21}},{"id":"5bdaa616-3849-592f-b57b-f5deb429fe7d","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"a0a3b8b7-ad56-5e9b-aeab-7802ce9b832e","sequence_no":22,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":22}},{"id":"debae717-0fef-54f3-8037-596c168769de","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"68fe3ce6-a83c-5c63-ac7f-d87215e19e20","sequence_no":23,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":23}},{"id":"44812eee-f077-51de-aceb-064ff7a34216","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"0b223319-73aa-507e-b83f-20ad3ee46867","sequence_no":24,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":24}},{"id":"a6b498df-96c4-5f48-9c90-dae4e5767b08","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"c8025657-bd66-5bc4-bba9-584ad61e7390","sequence_no":25,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":25}},{"id":"01e2db16-eb1e-580a-a144-709a10489a70","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"1eec9eef-2e61-50da-9424-f9b7e2036fc9","sequence_no":26,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":26}},{"id":"7566d8b2-ab46-5e1b-b501-8310f2169db5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"884c16a1-87a3-5b8b-b587-0c81a8d0b44a","sequence_no":27,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":27}},{"id":"2982bf91-1be1-512c-993d-70daa3dc23a5","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"ab0550ec-263b-526e-8808-75fa558d2546","sequence_no":28,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":28}},{"id":"f7200280-4bcd-53a9-b48e-86a7ac6b1f92","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"79c645af-6c5a-5565-bfa9-e8bb7fa3381c","sequence_no":29,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":29}},{"id":"026be933-0029-592f-928f-c6c112d1190f","organization_id":"414a2e84-bc62-4c64-99ee-76db1cbc4654","test_version_id":"74243315-ea1e-5178-83b8-d6077ab9dc59","question_id":"b651784d-aacf-50a9-91ad-cd92523f12c1","sequence_no":30,"points":1,"is_required":true,"metadata":{"catalog_family":"regulatory","brand":"Consórcio Fiat","administrator":"Embracon","question_number":30}}]$fiat_version_questions$::jsonb) as x(
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
  v_test_id uuid := '61d013e4-3b4b-5676-b39c-6d340f87b046'::uuid;
  v_version_id uuid := '74243315-ea1e-5178-83b8-d6077ab9dc59'::uuid;
begin
  if not exists (
    select 1
    from public.source_materials sm
    join public.source_material_versions smv
      on smv.source_material_id = sm.id
     and smv.organization_id = sm.organization_id
     and smv.archived_at is null
    where sm.id = '417f7c60-3169-552d-9846-608e00809741'::uuid
      and sm.organization_id = v_org_id
      and sm.code = 'regulamento_fiat_embracon_v3'
      and sm.material_type = 'regulation'
      and sm.status = 'active'
      and sm.archived_at is null
      and smv.id = 'dadf433e-5d7c-5373-b926-ed299332598f'::uuid
      and smv.version_code = 'v3-res285-23-ce07-24'
      and smv.status = 'active'
      and lower(smv.content_sha256) = '74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a'
  ) then
    raise exception 'Regulamento Fiat pós-condição: fonte normativa/versionamento não confere.';
  end if;

  if (
    select count(*)
    from public.competency_domains c
    where c.organization_id = v_org_id
      and c.sequence_no between 51 and 58
      and c.status = 'draft'
      and c.is_legal = true
      and c.archived_at is null
  ) <> 8 then
    raise exception 'Regulamento Fiat pós-condição: esperado 8 competências legais em draft.';
  end if;

  if not exists (
    select 1
    from public.assessment_tests t
    where t.id = v_test_id
      and t.organization_id = v_org_id
      and t.code = 'regulamento_fiat_v1'
      and t.sequence_no = 12
      and t.question_count = 30
      and t.status = 'draft'
      and t.archived_at is null
  ) then
    raise exception 'Regulamento Fiat pós-condição: identidade do teste não confere.';
  end if;

  if not exists (
    select 1
    from public.assessment_test_versions tv
    where tv.id = v_version_id
      and tv.organization_id = v_org_id
      and tv.test_id = v_test_id
      and tv.version_code = 'fiat-v3-v1'
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
    raise exception 'Regulamento Fiat pós-condição: versão draft/fail-closed não confere.';
  end if;

  if (
    select count(*)
    from public.assessment_questions q
    where q.organization_id = v_org_id
      and q.code like 'reg_fiat_q%'
      and q.status = 'draft'
      and q.legal_review_date is null
      and q.archived_at is null
  ) <> 30 then
    raise exception 'Regulamento Fiat pós-condição: esperado 30 questões em draft sem revisão legal.';
  end if;

  if (
    select count(*)
    from public.assessment_version_questions avq
    where avq.organization_id = v_org_id
      and avq.test_version_id = v_version_id
      and avq.is_required = true
      and avq.archived_at is null
  ) <> 30 then
    raise exception 'Regulamento Fiat pós-condição: esperado 30 vínculos obrigatórios.';
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
    raise exception 'Regulamento Fiat pós-condição: questões/sequência da versão não conferem.';
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
    raise exception 'Regulamento Fiat pós-condição: esperado 120 alternativas.';
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
    raise exception 'Regulamento Fiat pós-condição: esperado 30 gabaritos privados.';
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
    raise exception 'Regulamento Fiat pós-condição: criticidade criada sem declaração da fonte de autoria.';
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
    raise exception 'Regulamento Fiat pós-condição: alguma questão não possui exatamente 4 alternativas.';
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
    raise exception 'Regulamento Fiat pós-condição: existe gabarito sem alternativa correspondente.';
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
      and q.block_code = 'definicoes_fundamentos'
  ) <> 3 then
    raise exception 'Regulamento Fiat pós-condição: distribuição do bloco definicoes_fundamentos não confere.';
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
    raise exception 'Regulamento Fiat pós-condição: distribuição do bloco planos não confere.';
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
  ) <> 3 then
    raise exception 'Regulamento Fiat pós-condição: distribuição do bloco contribuicoes_taxas não confere.';
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
    raise exception 'Regulamento Fiat pós-condição: distribuição do bloco constituicao_grupo não confere.';
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
    raise exception 'Regulamento Fiat pós-condição: distribuição do bloco assembleias não confere.';
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
  ) <> 5 then
    raise exception 'Regulamento Fiat pós-condição: distribuição do bloco contemplacao_lances não confere.';
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
  ) <> 5 then
    raise exception 'Regulamento Fiat pós-condição: distribuição do bloco credito_garantias não confere.';
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
  ) <> 5 then
    raise exception 'Regulamento Fiat pós-condição: distribuição do bloco cessao_exclusao_prescricao não confere.';
  end if;

  if (
    select count(*)
    from public.assessment_version_sources avs
    where avs.organization_id = v_org_id
      and avs.test_version_id = v_version_id
      and avs.source_material_version_id = 'dadf433e-5d7c-5373-b926-ed299332598f'::uuid
      and avs.relation_type = 'primary'
      and avs.is_required = true
      and avs.archived_at is null
  ) <> 1 then
    raise exception 'Regulamento Fiat pós-condição: vínculo com fonte normativa primária não confere.';
  end if;

  if exists (
    select 1
    from private.assessment_test_access_grants g
    where g.organization_id = v_org_id
      and g.test_id = v_test_id
      and g.archived_at is null
  ) then
    raise exception 'Regulamento Fiat pós-condição: nenhum grant deveria ter sido criado.';
  end if;

  if exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.test_id = v_test_id
      and a.archived_at is null
  ) then
    raise exception 'Regulamento Fiat pós-condição: nenhuma tentativa deveria existir.';
  end if;

  if (
    select count(*)
    from public.assessment_tests t
    where t.organization_id = v_org_id
      and t.sequence_no between 1 and 12
      and t.archived_at is null
  ) <> 12 then
    raise exception 'Regulamento Fiat pós-condição: catálogo 1..12 não está íntegro.';
  end if;
end
$post$;

commit;
