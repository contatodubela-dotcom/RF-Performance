begin;

do $$
declare
  v_org_id constant uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654';

  -- Teste 12 — Fiat regulatório
  v_test12_id constant uuid := '61d013e4-3b4b-5676-b39c-6d340f87b046';
  v_test12_version_id constant uuid := '74243315-ea1e-5178-83b8-d6077ab9dc59';

  -- Controle de isolamento — Teste 11 VW regulatório
  v_test11_id constant uuid := 'dd671e5f-39ec-5018-9263-78613361a7db';
  v_test11_version_id constant uuid := 'fcf8f979-c44e-5993-beef-d023312ab5b7';

  -- Controle de isolamento — Teste 13 VW comercial
  v_test13_id constant uuid := '4f97740e-3f9e-559e-b120-cd043a42c755';
  v_test13_version_id constant uuid := '58b09fe5-2bc5-5803-ab0a-2a8834c85607';

  v_count bigint;
begin
  -- Guarda 1: identidade e estado atual do Teste 12.
  if not exists (
    select 1
    from public.assessment_tests t
    where t.id = v_test12_id
      and t.organization_id = v_org_id
      and t.code = 'regulamento_fiat_v1'
      and t.status = 'draft'
  ) then
    raise exception
      'FASE7A1_ABORT: Teste 12 Fiat ausente, identidade divergente ou status diferente de draft.';
  end if;

  -- Guarda 2: versão Fiat correta, ainda draft, com política 90/90.
  if not exists (
    select 1
    from public.assessment_test_versions v
    where v.id = v_test12_version_id
      and v.organization_id = v_org_id
      and v.test_id = v_test12_id
      and v.version_code = 'fiat-v3-v1'
      and v.version_no = 1
      and v.status = 'draft'
      and v.passing_score = 90.00
      and v.legal_min_score = 90.00
  ) then
    raise exception
      'FASE7A1_ABORT: versão do Teste 12 Fiat divergiu do baseline draft 90/90.';
  end if;

  -- Guarda 3: exatamente 30 questões ativas vinculadas à versão Fiat.
  select count(*)
    into v_count
  from public.assessment_version_questions avq
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_test12_version_id
    and avq.archived_at is null;

  if v_count <> 30 then
    raise exception
      'FASE7A1_ABORT: Teste 12 Fiat deveria ter 30 questões ativas; encontrado %.', v_count;
  end if;

  -- Guarda 4: exatamente 1 fonte ativa e obrigatória.
  select count(*)
    into v_count
  from public.assessment_version_sources avs
  where avs.organization_id = v_org_id
    and avs.test_version_id = v_test12_version_id
    and avs.archived_at is null
    and avs.is_required = true;

  if v_count <> 1 then
    raise exception
      'FASE7A1_ABORT: Teste 12 Fiat deveria ter 1 fonte obrigatória ativa; encontrado %.', v_count;
  end if;

  select count(*)
    into v_count
  from public.assessment_version_sources avs
  where avs.organization_id = v_org_id
    and avs.test_version_id = v_test12_version_id
    and avs.archived_at is null;

  if v_count <> 1 then
    raise exception
      'FASE7A1_ABORT: Teste 12 Fiat deveria ter exatamente 1 fonte ativa no total; encontrado %.', v_count;
  end if;

  -- Guarda 5: Teste 11 VW regulatório deve permanecer fechado e intocado.
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.test_id = t.id
    where t.id = v_test11_id
      and t.organization_id = v_org_id
      and t.code = 'regulamento_vw_cnvw_v1'
      and t.status = 'draft'
      and v.id = v_test11_version_id
      and v.organization_id = v_org_id
      and v.version_code = 'cnvw-v3.0-v1'
      and v.version_no = 1
      and v.status = 'draft'
      and v.passing_score = 90.00
      and v.legal_min_score = 90.00
  ) then
    raise exception
      'FASE7A1_ABORT: Teste 11 VW regulatório não está no baseline protegido esperado.';
  end if;

  -- Guarda 6: Teste 13 VW comercial deve continuar fechado após a homologação 6D2.
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.test_id = t.id
    where t.id = v_test13_id
      and t.organization_id = v_org_id
      and t.code = 'consorcio_vw_comercial_v1'
      and t.status = 'draft'
      and v.id = v_test13_version_id
      and v.organization_id = v_org_id
      and v.version_code = 'cnvw-v3.0-comercial-v2'
      and v.version_no = 2
      and v.status = 'draft'
      and v.passing_score = 85.00
      and v.legal_min_score = 90.00
  ) then
    raise exception
      'FASE7A1_ABORT: Teste 13 VW comercial não está no baseline protegido esperado.';
  end if;

  -- Abertura temporária: somente Teste 12 Fiat.
  update public.assessment_tests
  set
    status = 'active',
    metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
      'homologation_phase', '7A1',
      'homologation_window', true,
      'homologation_opened_at', now(),
      'homologation_scope', 'teste12_fiat_regulatorio'
    )
  where id = v_test12_id
    and organization_id = v_org_id
    and status = 'draft';

  if not found then
    raise exception
      'FASE7A1_ABORT: falha ao ativar temporariamente o Teste 12 Fiat.';
  end if;

  update public.assessment_test_versions
  set
    status = 'published',
    metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
      'homologation_phase', '7A1',
      'homologation_window', true,
      'homologation_opened_at', now(),
      'homologation_scope', 'teste12_fiat_regulatorio'
    )
  where id = v_test12_version_id
    and organization_id = v_org_id
    and test_id = v_test12_id
    and status = 'draft'
    and passing_score = 90.00
    and legal_min_score = 90.00;

  if not found then
    raise exception
      'FASE7A1_ABORT: falha ao publicar temporariamente a versão do Teste 12 Fiat.';
  end if;

  -- Pós-condição 1: Teste 12 aberto somente para homologação.
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.test_id = t.id
    where t.id = v_test12_id
      and t.organization_id = v_org_id
      and t.status = 'active'
      and t.metadata ->> 'homologation_phase' = '7A1'
      and coalesce((t.metadata ->> 'homologation_window')::boolean, false) = true
      and v.id = v_test12_version_id
      and v.organization_id = v_org_id
      and v.status = 'published'
      and v.passing_score = 90.00
      and v.legal_min_score = 90.00
      and v.metadata ->> 'homologation_phase' = '7A1'
      and coalesce((v.metadata ->> 'homologation_window')::boolean, false) = true
  ) then
    raise exception
      'FASE7A1_ABORT: pós-condição de abertura do Teste 12 Fiat não foi satisfeita.';
  end if;

  -- Pós-condição 2: Teste 11 continua fechado.
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.test_id = t.id
    where t.id = v_test11_id
      and t.organization_id = v_org_id
      and t.status = 'draft'
      and v.id = v_test11_version_id
      and v.organization_id = v_org_id
      and v.status = 'draft'
      and v.passing_score = 90.00
      and v.legal_min_score = 90.00
  ) then
    raise exception
      'FASE7A1_ABORT: proteção do Teste 11 VW falhou; transação será revertida.';
  end if;

  -- Pós-condição 3: Teste 13 continua fechado.
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.test_id = t.id
    where t.id = v_test13_id
      and t.organization_id = v_org_id
      and t.status = 'draft'
      and v.id = v_test13_version_id
      and v.organization_id = v_org_id
      and v.status = 'draft'
      and v.passing_score = 85.00
      and v.legal_min_score = 90.00
  ) then
    raise exception
      'FASE7A1_ABORT: proteção do Teste 13 VW comercial falhou; transação será revertida.';
  end if;
end
$$;

commit;
