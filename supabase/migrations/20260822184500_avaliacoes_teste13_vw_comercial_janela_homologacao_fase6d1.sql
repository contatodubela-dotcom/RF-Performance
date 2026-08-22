begin;

do $$
declare
  v_org_id constant uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654';

  v_test13_id constant uuid := '4f97740e-3f9e-559e-b120-cd043a42c755';
  v_test13_version_id constant uuid := '58b09fe5-2bc5-5803-ab0a-2a8834c85607';

  v_test11_id constant uuid := 'dd671e5f-39ec-5018-9263-78613361a7db';
  v_test11_version_id constant uuid := 'fcf8f979-c44e-5993-beef-d023312ab5b7';

  v_count bigint;
begin
  -- Guarda 1: identidade e estado atual do Teste 13.
  if not exists (
    select 1
    from public.assessment_tests t
    where t.id = v_test13_id
      and t.organization_id = v_org_id
      and t.code = 'consorcio_vw_comercial_v1'
      and t.title = 'Avaliação Comercial — Consórcio Volkswagen'
      and t.status = 'draft'
  ) then
    raise exception
      'FASE6D1_ABORT: Teste 13 ausente, identidade divergente ou status diferente de draft.';
  end if;

  -- Guarda 2: versão comercial correta, ainda draft, com política 85/90.
  if not exists (
    select 1
    from public.assessment_test_versions v
    where v.id = v_test13_version_id
      and v.organization_id = v_org_id
      and v.test_id = v_test13_id
      and v.version_code = 'cnvw-v3.0-comercial-v2'
      and v.version_no = 2
      and v.status = 'draft'
      and v.passing_score = 85.00
      and v.legal_min_score = 90.00
  ) then
    raise exception
      'FASE6D1_ABORT: versão do Teste 13 divergente do baseline draft 85/90.';
  end if;

  -- Guarda 3: exatamente 30 questões ativas vinculadas à versão.
  select count(*)
    into v_count
  from public.assessment_version_questions avq
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_test13_version_id
    and avq.archived_at is null;

  if v_count <> 30 then
    raise exception
      'FASE6D1_ABORT: Teste 13 deveria ter 30 questões ativas; encontrado %.', v_count;
  end if;

  -- Guarda 4: exatamente 2 fontes ativas e ambas obrigatórias.
  select count(*)
    into v_count
  from public.assessment_version_sources avs
  where avs.organization_id = v_org_id
    and avs.test_version_id = v_test13_version_id
    and avs.archived_at is null
    and avs.is_required = true;

  if v_count <> 2 then
    raise exception
      'FASE6D1_ABORT: Teste 13 deveria ter 2 fontes obrigatórias ativas; encontrado %.', v_count;
  end if;

  select count(*)
    into v_count
  from public.assessment_version_sources avs
  where avs.organization_id = v_org_id
    and avs.test_version_id = v_test13_version_id
    and avs.archived_at is null;

  if v_count <> 2 then
    raise exception
      'FASE6D1_ABORT: Teste 13 deveria ter exatamente 2 fontes ativas no total; encontrado %.', v_count;
  end if;

  -- Guarda 5: o Teste 11 regulatório histórico deve permanecer fechado e inalterado.
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
      'FASE6D1_ABORT: Teste 11 regulatório não está no baseline protegido esperado.';
  end if;

  -- Abertura temporária: somente Teste 13.
  update public.assessment_tests
  set
    status = 'active',
    metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
      'homologation_phase', '6D1',
      'homologation_window', true,
      'homologation_opened_at', now(),
      'homologation_scope', 'teste13_vw_comercial'
    )
  where id = v_test13_id
    and organization_id = v_org_id
    and status = 'draft';

  if not found then
    raise exception
      'FASE6D1_ABORT: falha ao ativar temporariamente o Teste 13.';
  end if;

  update public.assessment_test_versions
  set
    status = 'published',
    metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
      'homologation_phase', '6D1',
      'homologation_window', true,
      'homologation_opened_at', now(),
      'homologation_scope', 'teste13_vw_comercial'
    )
  where id = v_test13_version_id
    and organization_id = v_org_id
    and test_id = v_test13_id
    and status = 'draft'
    and passing_score = 85.00
    and legal_min_score = 90.00;

  if not found then
    raise exception
      'FASE6D1_ABORT: falha ao publicar temporariamente a versão do Teste 13.';
  end if;

  -- Pós-condição: Teste 13 aberto somente para a etapa controlada de homologação.
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.test_id = t.id
    where t.id = v_test13_id
      and t.organization_id = v_org_id
      and t.status = 'active'
      and v.id = v_test13_version_id
      and v.organization_id = v_org_id
      and v.status = 'published'
      and v.passing_score = 85.00
      and v.legal_min_score = 90.00
  ) then
    raise exception
      'FASE6D1_ABORT: pós-condição de abertura do Teste 13 não foi satisfeita.';
  end if;

  -- Pós-condição de proteção: Teste 11 continua draft/draft 90/90.
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
      'FASE6D1_ABORT: proteção do Teste 11 falhou; transação será revertida.';
  end if;
end
$$;

commit;
