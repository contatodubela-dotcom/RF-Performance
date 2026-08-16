begin;

-- ============================================================
-- Avaliações e Certificações
-- Arquitetura escalável — Fase 1B
--
-- Mapeia o catálogo inicial legado para programas genéricos
-- de certificação, sem alterar o fluxo homologado dos Testes 1–5.
--
-- Cria somente:
--   3 programas;
--   3 versões de programas;
--   1 grupo lógico ANY;
--   11 requisitos.
--
-- Tudo permanece em draft.
-- Nenhuma certificação é emitida.
-- ============================================================


-- ============================================================
-- 0. PREFLIGHT
-- ============================================================

do $$
declare
  v_org uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
  v_count integer;
begin
  -- ----------------------------------------------------------
  -- Estruturas obrigatórias
  -- ----------------------------------------------------------

  if to_regclass('public.certification_programs') is null then
    raise exception
      'PRECONDITION_FAILED: public.certification_programs missing';
  end if;

  if to_regclass('public.certification_program_versions') is null then
    raise exception
      'PRECONDITION_FAILED: public.certification_program_versions missing';
  end if;

  if to_regclass('public.certification_requirement_groups') is null then
    raise exception
      'PRECONDITION_FAILED: public.certification_requirement_groups missing';
  end if;

  if to_regclass('public.certification_requirements') is null then
    raise exception
      'PRECONDITION_FAILED: public.certification_requirements missing';
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'certification_requirements'
      and column_name = 'assessment_test_version_id'
      and data_type = 'uuid'
  ) then
    raise exception
      'PRECONDITION_FAILED: assessment_test_version_id missing';
  end if;


  -- ----------------------------------------------------------
  -- Organização
  -- ----------------------------------------------------------

  select count(*)
    into v_count
  from public.organizations
  where id = v_org;

  if v_count <> 1 then
    raise exception
      'PRECONDITION_FAILED: organization missing';
  end if;


  -- ----------------------------------------------------------
  -- Catálogo legado esperado: 3 níveis
  -- ----------------------------------------------------------

  select count(*)
    into v_count
  from public.certification_levels l
  join (
    values
      (
        '2810f0ff-107e-5e87-8da3-082a6b3208df'::uuid,
        'nivel_1_vendedor'::text,
        1,
        70::numeric,
        80::numeric,
        65::numeric,
        0,
        12
      ),
      (
        'f1e30767-00ad-5644-8f4a-cd80c1ac2d41'::uuid,
        'nivel_2_consultor'::text,
        2,
        80::numeric,
        85::numeric,
        80::numeric,
        0,
        12
      ),
      (
        '85a278b6-8579-5503-9d42-25436c62a6a9'::uuid,
        'nivel_3_especialista'::text,
        3,
        88::numeric,
        90::numeric,
        85::numeric,
        0,
        12
      )
  ) as expected(
    id,
    code,
    sequence_no,
    overall_min,
    legal_min,
    practical_min,
    critical_errors_allowed,
    validity_months
  )
    on expected.id = l.id
   and expected.code = l.code
   and expected.sequence_no = l.sequence_no
   and expected.overall_min = l.overall_min
   and expected.legal_min = l.legal_min
   and expected.practical_min = l.practical_min
   and expected.critical_errors_allowed = l.critical_errors_allowed
   and expected.validity_months = l.validity_months
  where l.organization_id = v_org
    and l.archived_at is null
    and l.status = 'draft';

  if v_count <> 3 then
    raise exception
      'PRECONDITION_FAILED: legacy certification catalog differs from expected state';
  end if;


  -- ----------------------------------------------------------
  -- Testes e versões exatas
  -- ----------------------------------------------------------

  select count(*)
    into v_count
  from (
    values
      (
        '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid,
        'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid,
        'teste_1_diagnostico'::text,
        60::numeric,
        70::numeric
      ),
      (
        '99f4b9fe-66c2-591e-a670-064675a64650'::uuid,
        'd608e0c6-efc6-500c-9258-64a774b4b169'::uuid,
        'teste_2_nivel_1'::text,
        70::numeric,
        80::numeric
      ),
      (
        '8a7754bc-7777-503c-a6aa-213b48f03f28'::uuid,
        'a68e7ffa-2c6e-5e95-9ab9-a0b3d9b307ef'::uuid,
        'teste_3_intermediario'::text,
        75::numeric,
        80::numeric
      ),
      (
        'c57f65fc-5084-501d-bbc1-b371d7fb5f02'::uuid,
        '22d2e41e-b5fc-5765-a1a8-edfde5c698ed'::uuid,
        'teste_4_nivel_2'::text,
        80::numeric,
        85::numeric
      ),
      (
        'abe87462-d06b-5a84-8bc5-a4841bb17cb2'::uuid,
        '7004fc3c-a1e7-5e28-a66b-143d3bffb869'::uuid,
        'teste_5_nivel_3'::text,
        88::numeric,
        90::numeric
      )
  ) as expected(
    test_id,
    version_id,
    test_code,
    passing_score,
    legal_min_score
  )
  join public.assessment_tests t
    on t.id = expected.test_id
   and t.organization_id = v_org
   and t.code = expected.test_code
   and t.archived_at is null
   and t.status = 'active'
  join public.assessment_test_versions v
    on v.id = expected.version_id
   and v.organization_id = v_org
   and v.test_id = expected.test_id
   and v.passing_score = expected.passing_score
   and v.legal_min_score = expected.legal_min_score
   and v.status = 'published'
   and v.archived_at is null;

  if v_count <> 5 then
    raise exception
      'PRECONDITION_FAILED: assessment catalog differs from expected state';
  end if;


  -- ----------------------------------------------------------
  -- Garantir que o mapeamento ainda não existe
  -- ----------------------------------------------------------

  select count(*)
    into v_count
  from public.certification_programs
  where organization_id = v_org
    and (
      id in (
        '5c512294-f6a9-4d8a-a67f-155aa6c3e8e1'::uuid,
        '219024ee-7a16-4180-b0c6-d64fcc58ed6a'::uuid,
        'd49489fd-4945-4e5d-830f-ad98354f79ba'::uuid
      )
      or code in (
        'nivel_1_vendedor',
        'nivel_2_consultor',
        'nivel_3_especialista'
      )
    );

  if v_count <> 0 then
    raise exception
      'PRECONDITION_FAILED: target certification programs already exist';
  end if;

  select count(*)
    into v_count
  from public.certification_program_versions
  where id in (
    '91b4a77b-6669-45f9-8fc6-041a6fae69fd'::uuid,
    'f7015d15-11d3-4a58-9421-82fa99fb47ec'::uuid,
    '5bd00a2d-a43e-426f-bb72-8d1d976a2148'::uuid
  );

  if v_count <> 0 then
    raise exception
      'PRECONDITION_FAILED: target program versions already exist';
  end if;
end;
$$;


-- ============================================================
-- 1. PROGRAMAS DE CERTIFICAÇÃO
-- ============================================================

insert into public.certification_programs (
  id,
  organization_id,
  code,
  name,
  description,
  category,
  display_order,
  status,
  metadata
)
values
(
  '5c512294-f6a9-4d8a-a67f-155aa6c3e8e1'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'nivel_1_vendedor',
  'Vendedor Nível 1 - Fundamentos de Consórcio',
  'Atendimento com acompanhamento do supervisor',
  'professional',
  1,
  'draft',
  jsonb_build_object(
    'mapping_phase', '1B',
    'catalog_version', '2026.08-v1',
    'legacy_certification_level_id',
      '2810f0ff-107e-5e87-8da3-082a6b3208df',
    'legacy_requirements',
      'Teste 1 diagnóstico + aprovação no Teste 2 + role-play básico',
    'scope_description',
      'Atendimento com acompanhamento do supervisor'
  )
),
(
  '219024ee-7a16-4180-b0c6-d64fcc58ed6a'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'nivel_2_consultor',
  'Consultor de Consórcio Nível 2',
  'Atendimento consultivo com autonomia',
  'professional',
  2,
  'draft',
  jsonb_build_object(
    'mapping_phase', '1B',
    'catalog_version', '2026.08-v1',
    'legacy_certification_level_id',
      'f1e30767-00ad-5644-8f4a-cd80c1ac2d41',
    'legacy_requirements',
      'Nível 1 vigente + aprovação nos Testes 3 e 4 + simulação completa',
    'scope_description',
      'Atendimento consultivo com autonomia'
  )
),
(
  'd49489fd-4945-4e5d-830f-ad98354f79ba'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'nivel_3_especialista',
  'Especialista em Consórcios Nível 3',
  'Referência técnica, apoio à equipe e revisão de discurso comercial',
  'professional',
  3,
  'draft',
  jsonb_build_object(
    'mapping_phase', '1B',
    'catalog_version', '2026.08-v1',
    'legacy_certification_level_id',
      '85a278b6-8579-5503-9d42-25436c62a6a9',
    'legacy_requirements',
      'Nível 2 vigente + aprovação no Teste 5 + caso prático ou microtreinamento',
    'scope_description',
      'Referência técnica, apoio à equipe e revisão de discurso comercial'
  )
);


-- ============================================================
-- 2. VERSÕES DOS PROGRAMAS
-- ============================================================

insert into public.certification_program_versions (
  id,
  organization_id,
  certification_program_id,
  version_code,
  version_no,
  name,
  description,
  requirements_mode,
  validity_months,
  auto_issue,
  status,
  metadata
)
values
(
  '91b4a77b-6669-45f9-8fc6-041a6fae69fd'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '5c512294-f6a9-4d8a-a67f-155aa6c3e8e1'::uuid,
  '2026.08-v1',
  1,
  'Vendedor Nível 1 - Fundamentos de Consórcio',
  'Versão inicial mapeada do catálogo legado.',
  'all',
  12,
  false,
  'draft',
  jsonb_build_object(
    'mapping_phase', '1B',
    'legacy_thresholds', jsonb_build_object(
      'overall_min', 70,
      'legal_min', 80,
      'practical_min', 65,
      'critical_errors_allowed', 0
    )
  )
),
(
  'f7015d15-11d3-4a58-9421-82fa99fb47ec'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '219024ee-7a16-4180-b0c6-d64fcc58ed6a'::uuid,
  '2026.08-v1',
  1,
  'Consultor de Consórcio Nível 2',
  'Versão inicial mapeada do catálogo legado.',
  'all',
  12,
  false,
  'draft',
  jsonb_build_object(
    'mapping_phase', '1B',
    'legacy_thresholds', jsonb_build_object(
      'overall_min', 80,
      'legal_min', 85,
      'practical_min', 80,
      'critical_errors_allowed', 0
    )
  )
),
(
  '5bd00a2d-a43e-426f-bb72-8d1d976a2148'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'd49489fd-4945-4e5d-830f-ad98354f79ba'::uuid,
  '2026.08-v1',
  1,
  'Especialista em Consórcios Nível 3',
  'Versão inicial mapeada do catálogo legado.',
  'all',
  12,
  false,
  'draft',
  jsonb_build_object(
    'mapping_phase', '1B',
    'legacy_thresholds', jsonb_build_object(
      'overall_min', 88,
      'legal_min', 90,
      'practical_min', 85,
      'critical_errors_allowed', 0
    )
  )
);


-- ============================================================
-- 3. GRUPO LÓGICO DO NÍVEL 3
--
-- O programa exige:
--   Nível 2 ativo
--   AND Teste 5 aprovado
--   AND (caso prático OR microtreinamento)
-- ============================================================

insert into public.certification_requirement_groups (
  id,
  organization_id,
  certification_program_version_id,
  sequence_no,
  code,
  name,
  description,
  group_mode,
  minimum_required,
  is_required,
  metadata
)
values (
  'e72eabd0-a765-4e49-bf91-40faed859633'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '5bd00a2d-a43e-426f-bb72-8d1d976a2148'::uuid,
  1,
  'practical_alternative',
  'Alternativa prática',
  'Cumprir caso prático ou microtreinamento.',
  'any',
  null,
  true,
  jsonb_build_object(
    'mapping_phase', '1B',
    'source_label', 'caso prático ou microtreinamento'
  )
);


-- ============================================================
-- 4. REQUISITOS
-- ============================================================

insert into public.certification_requirements (
  id,
  organization_id,
  certification_program_version_id,
  requirement_group_id,
  sequence_no,
  requirement_type,
  title,
  description,
  is_required,
  assessment_test_id,
  assessment_test_version_id,
  required_certification_program_id,
  minimum_score,
  minimum_legal_score,
  max_critical_errors,
  requirement_config,
  metadata
)
values

-- ------------------------------------------------------------
-- NÍVEL 1
-- ------------------------------------------------------------

(
  'beaae4a1-a1dd-4907-8060-c6e88ce4b3d9'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '91b4a77b-6669-45f9-8fc6-041a6fae69fd'::uuid,
  null,
  1,
  'assessment_graded',
  'Teste 1 — Diagnóstico inicial',
  'Realizar e concluir o diagnóstico inicial.',
  true,
  '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid,
  'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid,
  null,
  null,
  null,
  null,
  '{}'::jsonb,
  jsonb_build_object(
    'mapping_phase', '1B',
    'assessment_code', 'teste_1_diagnostico'
  )
),

(
  'b4996106-098e-47c1-b74e-8812097d384c'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '91b4a77b-6669-45f9-8fc6-041a6fae69fd'::uuid,
  null,
  2,
  'assessment_passed',
  'Teste 2 — Certificação Vendedor Nível 1',
  'Obter aprovação na versão vinculada do Teste 2.',
  true,
  '99f4b9fe-66c2-591e-a670-064675a64650'::uuid,
  'd608e0c6-efc6-500c-9258-64a774b4b169'::uuid,
  null,
  70,
  80,
  null,
  '{}'::jsonb,
  jsonb_build_object(
    'mapping_phase', '1B',
    'assessment_code', 'teste_2_nivel_1'
  )
),

(
  'eb3b8963-df29-464b-8dd3-ad3b737267d8'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '91b4a77b-6669-45f9-8fc6-041a6fae69fd'::uuid,
  null,
  3,
  'practical_assessment_passed',
  'Role-play básico',
  'Ser aprovado em role-play básico.',
  true,
  null,
  null,
  null,
  65,
  null,
  0,
  jsonb_build_object(
    'assessment_type', 'role_play',
    'variant', 'basic_role_play',
    'source_label', 'role-play básico'
  ),
  jsonb_build_object(
    'mapping_phase', '1B'
  )
),


-- ------------------------------------------------------------
-- NÍVEL 2
-- ------------------------------------------------------------

(
  'a6ac7e03-ddc5-4ff5-8c99-36ee168d3a81'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'f7015d15-11d3-4a58-9421-82fa99fb47ec'::uuid,
  null,
  1,
  'certification_active',
  'Certificação Nível 1 vigente',
  'Possuir certificação ativa do programa Nível 1.',
  true,
  null,
  null,
  '5c512294-f6a9-4d8a-a67f-155aa6c3e8e1'::uuid,
  null,
  null,
  null,
  '{}'::jsonb,
  jsonb_build_object(
    'mapping_phase', '1B'
  )
),

(
  '9ff441a0-b1a9-4820-ae40-04511ff797fd'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'f7015d15-11d3-4a58-9421-82fa99fb47ec'::uuid,
  null,
  2,
  'assessment_passed',
  'Teste 3 — Avaliação intermediária',
  'Obter aprovação na versão vinculada do Teste 3.',
  true,
  '8a7754bc-7777-503c-a6aa-213b48f03f28'::uuid,
  'a68e7ffa-2c6e-5e95-9ab9-a0b3d9b307ef'::uuid,
  null,
  75,
  80,
  null,
  '{}'::jsonb,
  jsonb_build_object(
    'mapping_phase', '1B',
    'assessment_code', 'teste_3_intermediario'
  )
),

(
  'fc7564a6-4820-4d94-ba83-6f54c4793cdc'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'f7015d15-11d3-4a58-9421-82fa99fb47ec'::uuid,
  null,
  3,
  'assessment_passed',
  'Teste 4 — Certificação Consultor Nível 2',
  'Obter aprovação na versão vinculada do Teste 4.',
  true,
  'c57f65fc-5084-501d-bbc1-b371d7fb5f02'::uuid,
  '22d2e41e-b5fc-5765-a1a8-edfde5c698ed'::uuid,
  null,
  80,
  85,
  null,
  '{}'::jsonb,
  jsonb_build_object(
    'mapping_phase', '1B',
    'assessment_code', 'teste_4_nivel_2'
  )
),

(
  '9744bb21-8ac7-4a0e-afaf-bc362ba0dfb6'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  'f7015d15-11d3-4a58-9421-82fa99fb47ec'::uuid,
  null,
  4,
  'practical_assessment_passed',
  'Simulação completa',
  'Ser aprovado em simulação completa do atendimento/processo.',
  true,
  null,
  null,
  null,
  80,
  null,
  0,
  jsonb_build_object(
    'assessment_type', 'full_simulation',
    'source_label', 'simulação completa'
  ),
  jsonb_build_object(
    'mapping_phase', '1B'
  )
),


-- ------------------------------------------------------------
-- NÍVEL 3
-- ------------------------------------------------------------

(
  'f7550574-2bb8-4077-b832-4c26f0096a03'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '5bd00a2d-a43e-426f-bb72-8d1d976a2148'::uuid,
  null,
  1,
  'certification_active',
  'Certificação Nível 2 vigente',
  'Possuir certificação ativa do programa Nível 2.',
  true,
  null,
  null,
  '219024ee-7a16-4180-b0c6-d64fcc58ed6a'::uuid,
  null,
  null,
  null,
  '{}'::jsonb,
  jsonb_build_object(
    'mapping_phase', '1B'
  )
),

(
  'e5dffd32-e08d-44e4-81bc-6e88b2b26c72'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '5bd00a2d-a43e-426f-bb72-8d1d976a2148'::uuid,
  null,
  2,
  'assessment_passed',
  'Teste 5 — Certificação Especialista Nível 3',
  'Obter aprovação na versão vinculada do Teste 5.',
  true,
  'abe87462-d06b-5a84-8bc5-a4841bb17cb2'::uuid,
  '7004fc3c-a1e7-5e28-a66b-143d3bffb869'::uuid,
  null,
  88,
  90,
  null,
  '{}'::jsonb,
  jsonb_build_object(
    'mapping_phase', '1B',
    'assessment_code', 'teste_5_nivel_3'
  )
),

(
  '5e9ed0b7-2437-4551-b3b8-7d10aea93f4b'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '5bd00a2d-a43e-426f-bb72-8d1d976a2148'::uuid,
  'e72eabd0-a765-4e49-bf91-40faed859633'::uuid,
  3,
  'practical_assessment_passed',
  'Caso prático',
  'Alternativa prática: aprovação em apresentação de caso.',
  false,
  null,
  null,
  null,
  85,
  null,
  0,
  jsonb_build_object(
    'assessment_type', 'case_presentation',
    'source_label', 'caso prático'
  ),
  jsonb_build_object(
    'mapping_phase', '1B',
    'alternative_group', 'practical_alternative'
  )
),

(
  '86a89b3f-9287-4c25-a469-48b9b3f515e8'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '5bd00a2d-a43e-426f-bb72-8d1d976a2148'::uuid,
  'e72eabd0-a765-4e49-bf91-40faed859633'::uuid,
  4,
  'practical_assessment_passed',
  'Microtreinamento',
  'Alternativa prática: aprovação em microtreinamento.',
  false,
  null,
  null,
  null,
  85,
  null,
  0,
  jsonb_build_object(
    'assessment_type', 'microtraining',
    'source_label', 'microtreinamento'
  ),
  jsonb_build_object(
    'mapping_phase', '1B',
    'alternative_group', 'practical_alternative'
  )
);


-- ============================================================
-- 5. PÓS-CONDIÇÕES
-- ============================================================

do $$
declare
  v_org uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
  v_count integer;
begin
  -- 3 programas em draft
  select count(*)
    into v_count
  from public.certification_programs
  where organization_id = v_org
    and id in (
      '5c512294-f6a9-4d8a-a67f-155aa6c3e8e1'::uuid,
      '219024ee-7a16-4180-b0c6-d64fcc58ed6a'::uuid,
      'd49489fd-4945-4e5d-830f-ad98354f79ba'::uuid
    )
    and status = 'draft'
    and archived_at is null;

  if v_count <> 3 then
    raise exception
      'POSTCONDITION_FAILED: expected 3 draft certification programs';
  end if;


  -- 3 versões, todas draft, all, validade 12, auto_issue false
  select count(*)
    into v_count
  from public.certification_program_versions
  where organization_id = v_org
    and id in (
      '91b4a77b-6669-45f9-8fc6-041a6fae69fd'::uuid,
      'f7015d15-11d3-4a58-9421-82fa99fb47ec'::uuid,
      '5bd00a2d-a43e-426f-bb72-8d1d976a2148'::uuid
    )
    and version_code = '2026.08-v1'
    and version_no = 1
    and requirements_mode = 'all'
    and validity_months = 12
    and auto_issue = false
    and status = 'draft'
    and published_at is null
    and archived_at is null;

  if v_count <> 3 then
    raise exception
      'POSTCONDITION_FAILED: expected 3 draft program versions';
  end if;


  -- Grupo ANY do Nível 3
  select count(*)
    into v_count
  from public.certification_requirement_groups
  where organization_id = v_org
    and id = 'e72eabd0-a765-4e49-bf91-40faed859633'::uuid
    and certification_program_version_id =
      '5bd00a2d-a43e-426f-bb72-8d1d976a2148'::uuid
    and group_mode = 'any'
    and minimum_required is null
    and is_required = true
    and archived_at is null;

  if v_count <> 1 then
    raise exception
      'POSTCONDITION_FAILED: N3 practical ANY group missing';
  end if;


  -- Total de 11 requisitos
  select count(*)
    into v_count
  from public.certification_requirements
  where organization_id = v_org
    and certification_program_version_id in (
      '91b4a77b-6669-45f9-8fc6-041a6fae69fd'::uuid,
      'f7015d15-11d3-4a58-9421-82fa99fb47ec'::uuid,
      '5bd00a2d-a43e-426f-bb72-8d1d976a2148'::uuid
    )
    and archived_at is null;

  if v_count <> 11 then
    raise exception
      'POSTCONDITION_FAILED: expected 11 certification requirements, found %',
      v_count;
  end if;


  -- 5 requisitos de avaliação, todos versionados
  select count(*)
    into v_count
  from public.certification_requirements
  where organization_id = v_org
    and certification_program_version_id in (
      '91b4a77b-6669-45f9-8fc6-041a6fae69fd'::uuid,
      'f7015d15-11d3-4a58-9421-82fa99fb47ec'::uuid,
      '5bd00a2d-a43e-426f-bb72-8d1d976a2148'::uuid
    )
    and requirement_type in (
      'assessment_passed',
      'assessment_graded'
    )
    and assessment_test_id is not null
    and assessment_test_version_id is not null
    and archived_at is null;

  if v_count <> 5 then
    raise exception
      'POSTCONDITION_FAILED: expected 5 versioned assessment requirements';
  end if;


  -- 2 pré-requisitos por certificação anterior
  select count(*)
    into v_count
  from public.certification_requirements
  where organization_id = v_org
    and certification_program_version_id in (
      'f7015d15-11d3-4a58-9421-82fa99fb47ec'::uuid,
      '5bd00a2d-a43e-426f-bb72-8d1d976a2148'::uuid
    )
    and requirement_type = 'certification_active'
    and required_certification_program_id is not null
    and archived_at is null;

  if v_count <> 2 then
    raise exception
      'POSTCONDITION_FAILED: expected 2 certification prerequisites';
  end if;


  -- 4 requisitos práticos
  select count(*)
    into v_count
  from public.certification_requirements
  where organization_id = v_org
    and certification_program_version_id in (
      '91b4a77b-6669-45f9-8fc6-041a6fae69fd'::uuid,
      'f7015d15-11d3-4a58-9421-82fa99fb47ec'::uuid,
      '5bd00a2d-a43e-426f-bb72-8d1d976a2148'::uuid
    )
    and requirement_type = 'practical_assessment_passed'
    and archived_at is null;

  if v_count <> 4 then
    raise exception
      'POSTCONDITION_FAILED: expected 4 practical requirements';
  end if;


  -- As duas alternativas do Nível 3 pertencem ao mesmo grupo ANY
  select count(*)
    into v_count
  from public.certification_requirements
  where organization_id = v_org
    and requirement_group_id =
      'e72eabd0-a765-4e49-bf91-40faed859633'::uuid
    and requirement_type = 'practical_assessment_passed'
    and is_required = false
    and archived_at is null;

  if v_count <> 2 then
    raise exception
      'POSTCONDITION_FAILED: expected 2 N3 practical alternatives';
  end if;
end;
$$;

commit;