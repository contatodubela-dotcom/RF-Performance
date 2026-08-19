-- ============================================================
-- RF Performance — Avaliações e Certificações
-- Fase 1I-A — Registro de fonte versionada do catálogo 2026.08-v1
--
-- Objetivo:
--   1. Registrar, na arquitetura nova de fontes, a fonte identificada
--      no cabeçalho da migration histórica da Fase 1B:
--      "Sistema de Certificação Comercial - Consórcio de Veículos"
--   2. Registrar sua versão 2026.08-v1 com o SHA-256 histórico.
--   3. Vincular essa versão-fonte às versões 2026.08-v1 dos Testes 1 a 5.
--
-- Importante:
--   - NÃO altera questões, alternativas, gabaritos ou tentativas.
--   - NÃO altera assessment_tests nem assessment_test_versions.
--   - NÃO transforma as referências normativas existentes em fontes
--     versionadas individuais.
--   - O SHA abaixo identifica a fonte/catálogo histórico da Fase 1B,
--     e não cada lei, resolução, FAQ ou outro material normativo.
-- ============================================================

begin;

do $$
declare
  v_organization_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;

  v_source_seed_id uuid := '75cf4205-2748-4c65-a102-b6a3e11287e9'::uuid;
  v_source_version_seed_id uuid := '2b0d90e6-accb-4fe8-bc78-073a7e32869f'::uuid;

  v_source_id uuid;
  v_source_version_id uuid;

  v_source_code text := 'sistema_certificacao_comercial_consorcio_veiculos';
  v_source_title text := 'Sistema de Certificação Comercial - Consórcio de Veículos';
  v_version_code text := '2026.08-v1';
  v_source_sha256 text := 'e3ba2f891bf274be34439dc3e0007f0d9d3768b91c45f1a44aecae5197c852ab';

  v_expected_test_versions integer;
  v_link_count integer;
begin
  -- ------------------------------------------------------------
  -- Guarda 1: organização esperada.
  -- ------------------------------------------------------------
  if not exists (
    select 1
    from public.organizations o
    where o.id = v_organization_id
      and o.slug = 'rf-consorcios'
      and o.status = 'active'
  ) then
    raise exception
      'Fase 1I-A abortada: organização RF esperada não foi localizada ou não está ativa.';
  end if;

  -- ------------------------------------------------------------
  -- Guarda 2: as cinco versões de avaliação esperadas precisam
  -- existir e conservar o mesmo SHA histórico da fonte 2026.08-v1.
  -- ------------------------------------------------------------
  select count(*)
  into v_expected_test_versions
  from (
    values
      (
        '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid,
        'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
      ),
      (
        '99f4b9fe-66c2-591e-a670-064675a64650'::uuid,
        'd608e0c6-efc6-500c-9258-64a774b4b169'::uuid
      ),
      (
        '8a7754bc-7777-503c-a6aa-213b48f03f28'::uuid,
        'a68e7ffa-2c6e-5e95-9ab9-a0b3d9b307ef'::uuid
      ),
      (
        'c57f65fc-5084-501d-bbc1-b371d7fb5f02'::uuid,
        '22d2e41e-b5fc-5765-a1a8-edfde5c698ed'::uuid
      ),
      (
        'abe87462-d06b-5a84-8bc5-a4841bb17cb2'::uuid,
        '7004fc3c-a1e7-5e28-a66b-143d3bffb869'::uuid
      )
  ) as expected(test_id, test_version_id)
  join public.assessment_tests t
    on t.id = expected.test_id
   and t.organization_id = v_organization_id
   and t.archived_at is null
  join public.assessment_test_versions tv
    on tv.id = expected.test_version_id
   and tv.test_id = expected.test_id
   and tv.organization_id = v_organization_id
   and tv.archived_at is null
  where tv.version_code = v_version_code
    and tv.metadata ->> 'source_sha256' = v_source_sha256;

  if v_expected_test_versions <> 5 then
    raise exception
      'Fase 1I-A abortada: esperado encontrar 5 versões 2026.08-v1 compatíveis com o SHA histórico; encontrado %.',
      v_expected_test_versions;
  end if;

  -- ------------------------------------------------------------
  -- 1. Material-fonte.
  -- ------------------------------------------------------------
  insert into public.source_materials (
    id,
    organization_id,
    code,
    title,
    description,
    material_type,
    issuer,
    status,
    created_at,
    updated_at,
    metadata
  )
  values (
    v_source_seed_id,
    v_organization_id,
    v_source_code,
    v_source_title,
    'Fonte interna identificada no cabeçalho do catálogo público versionado da Fase 1B.',
    'internal_content',
    null,
    'active',
    now(),
    now(),
    jsonb_build_object(
      'architecture_phase', '1I-A',
      'provenance_kind', 'legacy_catalog_source',
      'source_header_name', 'Sistema de Certificação Comercial - Consórcio de Veículos | versão 2026.08-v1',
      'evidence_migration', '20260804233000_avaliacoes_certificacao_fase1b_catalogo_publico.sql',
      'legacy_commercial_plan_id', 'baa2bbd9-7688-4fcc-92a8-16a96ca969db',
      'legacy_commercial_plan_title', 'Plano de Aceleração Comercial — 90 Dias',
      'normative_sources_individually_versioned', false
    )
  )
  on conflict (organization_id, code) do nothing;

  select sm.id
  into v_source_id
  from public.source_materials sm
  where sm.organization_id = v_organization_id
    and sm.code = v_source_code
    and sm.archived_at is null;

  if v_source_id is null then
    raise exception
      'Fase 1I-A abortada: material-fonte não pôde ser localizado após o cadastro.';
  end if;

  if not exists (
    select 1
    from public.source_materials sm
    where sm.id = v_source_id
      and sm.organization_id = v_organization_id
      and sm.code = v_source_code
      and sm.title = v_source_title
      and sm.material_type = 'internal_content'
      and sm.status = 'active'
      and sm.archived_at is null
  ) then
    raise exception
      'Fase 1I-A abortada: já existe material com o mesmo código, mas com identidade estrutural incompatível.';
  end if;

  -- ------------------------------------------------------------
  -- 2. Versão exata da fonte.
  --
  -- Datas de publicação/eficácia da fonte original não são
  -- inferidas: permanecem nulas. O SHA-256 é o valor histórico
  -- registrado no cabeçalho da Fase 1B.
  -- ------------------------------------------------------------
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
    created_at,
    updated_at,
    metadata
  )
  values (
    v_source_version_seed_id,
    v_organization_id,
    v_source_id,
    v_version_code,
    1,
    'active',
    null,
    null,
    null,
    null,
    v_source_sha256,
    '{}'::jsonb,
    now(),
    now(),
    jsonb_build_object(
      'architecture_phase', '1I-A',
      'provenance_kind', 'legacy_catalog_source_version',
      'source_review_date', '2026-08-03',
      'evidence_migration', '20260804233000_avaliacoes_certificacao_fase1b_catalogo_publico.sql',
      'catalog_version', v_version_code,
      'normative_sources_individually_versioned', false
    )
  )
  on conflict (organization_id, source_material_id, version_code) do nothing;

  select smv.id
  into v_source_version_id
  from public.source_material_versions smv
  where smv.organization_id = v_organization_id
    and smv.source_material_id = v_source_id
    and smv.version_code = v_version_code
    and smv.archived_at is null;

  if v_source_version_id is null then
    raise exception
      'Fase 1I-A abortada: versão da fonte não pôde ser localizada após o cadastro.';
  end if;

  if not exists (
    select 1
    from public.source_material_versions smv
    where smv.id = v_source_version_id
      and smv.organization_id = v_organization_id
      and smv.source_material_id = v_source_id
      and smv.version_code = v_version_code
      and smv.version_no = 1
      and smv.status = 'active'
      and lower(smv.content_sha256) = lower(v_source_sha256)
      and smv.archived_at is null
  ) then
    raise exception
      'Fase 1I-A abortada: já existe versão 2026.08-v1 incompatível com o SHA histórico esperado.';
  end if;

  -- ------------------------------------------------------------
  -- 3. Vínculo da fonte às versões 2026.08-v1 dos Testes 1 a 5.
  --
  -- relation_type = primary:
  -- a fonte registrada é a proveniência primária do catálogo
  -- importado. As normas listadas em normative_basis permanecem
  -- referências normativas legadas e não são convertidas aqui.
  -- ------------------------------------------------------------
  insert into public.assessment_version_sources (
    id,
    organization_id,
    test_version_id,
    source_material_version_id,
    relation_type,
    is_required,
    notes,
    created_at,
    updated_at,
    metadata
  )
  values
    (
      'd46b3c6c-e1ef-4694-8207-39668395cb50'::uuid,
      v_organization_id,
      'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid,
      v_source_version_id,
      'primary',
      true,
      'Proveniência primária do catálogo público 2026.08-v1. Não substitui o versionamento individual das fontes normativas.',
      now(),
      now(),
      jsonb_build_object('architecture_phase', '1I-A', 'test_code', 'teste_1_diagnostico')
    ),
    (
      'd03a0776-b128-4ee6-afa1-ae7501c42961'::uuid,
      v_organization_id,
      'd608e0c6-efc6-500c-9258-64a774b4b169'::uuid,
      v_source_version_id,
      'primary',
      true,
      'Proveniência primária do catálogo público 2026.08-v1. Não substitui o versionamento individual das fontes normativas.',
      now(),
      now(),
      jsonb_build_object('architecture_phase', '1I-A', 'test_code', 'teste_2_nivel_1')
    ),
    (
      'b8b8712a-896f-41bc-adc9-eb78e9046a1a'::uuid,
      v_organization_id,
      'a68e7ffa-2c6e-5e95-9ab9-a0b3d9b307ef'::uuid,
      v_source_version_id,
      'primary',
      true,
      'Proveniência primária do catálogo público 2026.08-v1. Não substitui o versionamento individual das fontes normativas.',
      now(),
      now(),
      jsonb_build_object('architecture_phase', '1I-A', 'test_code', 'teste_3_intermediario')
    ),
    (
      '42963816-6ac6-4e6a-8973-19a8816f0d07'::uuid,
      v_organization_id,
      '22d2e41e-b5fc-5765-a1a8-edfde5c698ed'::uuid,
      v_source_version_id,
      'primary',
      true,
      'Proveniência primária do catálogo público 2026.08-v1. Não substitui o versionamento individual das fontes normativas.',
      now(),
      now(),
      jsonb_build_object('architecture_phase', '1I-A', 'test_code', 'teste_4_nivel_2')
    ),
    (
      '0fe74128-5df9-44f5-9a06-3175870dfff1'::uuid,
      v_organization_id,
      '7004fc3c-a1e7-5e28-a66b-143d3bffb869'::uuid,
      v_source_version_id,
      'primary',
      true,
      'Proveniência primária do catálogo público 2026.08-v1. Não substitui o versionamento individual das fontes normativas.',
      now(),
      now(),
      jsonb_build_object('architecture_phase', '1I-A', 'test_code', 'teste_5_nivel_3')
    )
  on conflict (
    organization_id,
    test_version_id,
    source_material_version_id
  ) do nothing;

  -- ------------------------------------------------------------
  -- Guarda final: exatamente cinco vínculos ativos esperados.
  -- ------------------------------------------------------------
  select count(*)
  into v_link_count
  from public.assessment_version_sources avs
  where avs.organization_id = v_organization_id
    and avs.source_material_version_id = v_source_version_id
    and avs.test_version_id = any (
      array[
        'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid,
        'd608e0c6-efc6-500c-9258-64a774b4b169'::uuid,
        'a68e7ffa-2c6e-5e95-9ab9-a0b3d9b307ef'::uuid,
        '22d2e41e-b5fc-5765-a1a8-edfde5c698ed'::uuid,
        '7004fc3c-a1e7-5e28-a66b-143d3bffb869'::uuid
      ]
    )
    and avs.relation_type = 'primary'
    and avs.is_required is true
    and avs.archived_at is null;

  if v_link_count <> 5 then
    raise exception
      'Fase 1I-A abortada: esperado encontrar 5 vínculos ativos de fonte primária; encontrado %.',
      v_link_count;
  end if;
end $$;

commit;
