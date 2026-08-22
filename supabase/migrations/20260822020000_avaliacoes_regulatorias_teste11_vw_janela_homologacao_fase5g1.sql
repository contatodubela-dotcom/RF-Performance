-- ============================================================================
-- RF Performance — Avaliações e Certificações
-- Homologação Regulatória
-- Fase 5G1 — Janela controlada de homologação funcional do Teste 11 Volkswagen
--
-- Objetivo:
--   Abrir por 4 horas somente o Teste 11 — Volkswagen / CNVW para homologação
--   funcional real pela interface.
--
-- ESCOPO / SEGURANÇA
--   - Publica temporariamente somente o Teste 11 e a versão cnvw-v3.0-v1.
--   - Mantém o Teste 12 — Fiat integralmente em draft.
--   - Não cria grant de acesso; o grant será concedido pela interface
--     administrativa exclusivamente ao participante piloto.
--   - Não cria tentativa.
--   - Não altera questões, alternativas, gabaritos, fontes, competências ou cortes.
--   - Mantém a política aprovada 90/90 da Fase 5F.
--   - A versão expira automaticamente 4 horas após a aplicação desta migration.
--   - O fechamento da janela será feito em nova migration.
-- ============================================================================

begin;

do $guard$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;

  v_vw_test_id uuid := 'dd671e5f-39ec-5018-9263-78613361a7db'::uuid;
  v_vw_version_id uuid := 'fcf8f979-c44e-5993-beef-d023312ab5b7'::uuid;
  v_vw_source_version_id uuid := 'aca73af3-6ded-5461-88c9-acbd17064862'::uuid;

  v_fiat_test_id uuid := '61d013e4-3b4b-5676-b39c-6d340f87b046'::uuid;
  v_fiat_version_id uuid := '74243315-ea1e-5178-83b8-d6077ab9dc59'::uuid;

  v_pilot_member_id uuid := '49239d09-0f85-471f-8f46-5c240cd98600'::uuid;

  v_count bigint;
begin
  -- Organização esperada.
  if not exists (
    select 1
    from public.organizations o
    where o.id = v_org_id
      and o.slug = 'rf-consorcios'
      and o.status = 'active'
      and o.archived_at is null
  ) then
    raise exception
      'FASE5G1_ABORT: organizacao RF esperada nao localizada/ativa.';
  end if;

  -- Participante piloto deve existir e estar ativo.
  if not exists (
    select 1
    from public.organization_members om
    where om.organization_id = v_org_id
      and om.id = v_pilot_member_id
      and om.status = 'active'
      and om.archived_at is null
  ) then
    raise exception
      'FASE5G1_ABORT: participante piloto esperado nao localizado/ativo.';
  end if;

  -- Teste 11 deve estar exatamente no estado aprovado antes da janela.
  select count(*)
    into v_count
  from public.assessment_tests t
  join public.assessment_test_versions v
    on v.organization_id = t.organization_id
   and v.test_id = t.id
   and v.id = v_vw_version_id
   and v.archived_at is null
  where t.organization_id = v_org_id
    and t.id = v_vw_test_id
    and t.sequence_no = 11
    and t.code = 'regulamento_vw_cnvw_v1'
    and t.status = 'draft'
    and t.archived_at is null
    and v.version_code = 'cnvw-v3.0-v1'
    and v.status = 'draft'
    and v.passing_score = 90
    and v.legal_min_score = 90
    and v.question_count = 30
    and v.published_at is null
    and v.metadata->>'approval_policy_status' = 'approved'
    and v.metadata->>'approval_policy_phase' = '5F'
    and v.metadata->>'external_currency_verified' = 'true';

  if v_count <> 1 then
    raise exception
      'FASE5G1_ABORT: estado/politica esperados do Teste 11 nao conferem.';
  end if;

  -- Exatamente uma versão ativa no catálogo para o Teste 11.
  select count(*)
    into v_count
  from public.assessment_test_versions v
  where v.organization_id = v_org_id
    and v.test_id = v_vw_test_id
    and v.archived_at is null;

  if v_count <> 1 then
    raise exception
      'FASE5G1_ABORT: esperado exatamente 1 registro de versao nao arquivada para o Teste 11; encontrado %.',
      v_count;
  end if;

  -- Estrutura esperada do Teste 11.
  select count(*)
    into v_count
  from public.assessment_version_questions avq
  join public.assessment_questions q
    on q.organization_id = avq.organization_id
   and q.id = avq.question_id
   and q.archived_at is null
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_vw_version_id
    and avq.archived_at is null;

  if v_count <> 30 then
    raise exception
      'FASE5G1_ABORT: Teste 11 deveria possuir 30 questoes vinculadas; encontrado %.',
      v_count;
  end if;

  select count(*)
    into v_count
  from public.assessment_question_options o
  join public.assessment_version_questions avq
    on avq.organization_id = o.organization_id
   and avq.question_id = o.question_id
   and avq.archived_at is null
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_vw_version_id
    and o.archived_at is null;

  if v_count <> 120 then
    raise exception
      'FASE5G1_ABORT: Teste 11 deveria possuir 120 alternativas; encontrado %.',
      v_count;
  end if;

  select count(*)
    into v_count
  from private.assessment_question_keys k
  join public.assessment_version_questions avq
    on avq.organization_id = k.organization_id
   and avq.question_id = k.question_id
   and avq.archived_at is null
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_vw_version_id;

  if v_count <> 30 then
    raise exception
      'FASE5G1_ABORT: Teste 11 deveria possuir 30 gabaritos privados; encontrado %.',
      v_count;
  end if;

  -- Fonte Volkswagen V3.0 reconciliada deve continuar primária e obrigatória.
  select count(*)
    into v_count
  from public.assessment_version_sources avs
  join public.source_material_versions smv
    on smv.organization_id = avs.organization_id
   and smv.id = avs.source_material_version_id
   and smv.archived_at is null
  where avs.organization_id = v_org_id
    and avs.test_version_id = v_vw_version_id
    and avs.source_material_version_id = v_vw_source_version_id
    and avs.relation_type = 'primary'
    and avs.is_required = true
    and avs.archived_at is null
    and smv.version_code = 'v3.0-res285-23'
    and smv.status = 'active'
    and smv.content_sha256 =
        '530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09';

  if v_count <> 1 then
    raise exception
      'FASE5G1_ABORT: fonte Volkswagen V3.0 primaria/obrigatoria nao confere.';
  end if;

  -- Nenhum grant ativo ou tentativa prévia no Teste 11.
  if exists (
    select 1
    from private.assessment_test_access_grants g
    where g.organization_id = v_org_id
      and g.test_id = v_vw_test_id
      and g.status = 'active'
      and g.archived_at is null
  ) then
    raise exception
      'FASE5G1_ABORT: Teste 11 ja possui grant ativo.';
  end if;

  if exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.test_id = v_vw_test_id
      and a.archived_at is null
  ) then
    raise exception
      'FASE5G1_ABORT: Teste 11 ja possui tentativa.';
  end if;

  -- Teste 12 Fiat deve permanecer integralmente fechado.
  select count(*)
    into v_count
  from public.assessment_tests t
  join public.assessment_test_versions v
    on v.organization_id = t.organization_id
   and v.test_id = t.id
   and v.id = v_fiat_version_id
   and v.archived_at is null
  where t.organization_id = v_org_id
    and t.id = v_fiat_test_id
    and t.sequence_no = 12
    and t.code = 'regulamento_fiat_v1'
    and t.status = 'draft'
    and t.archived_at is null
    and v.version_code = 'fiat-v3-v1'
    and v.status = 'draft'
    and v.passing_score = 90
    and v.legal_min_score = 90
    and v.question_count = 30
    and v.published_at is null
    and v.metadata->>'approval_policy_status' = 'approved'
    and v.metadata->>'approval_policy_phase' = '5F'
    and v.metadata->>'source_governance_status' = 'accepted'
    and v.metadata->>'source_governance_phase' = '5E';

  if v_count <> 1 then
    raise exception
      'FASE5G1_ABORT: Teste 12 Fiat nao esta no estado fechado esperado.';
  end if;

  if exists (
    select 1
    from private.assessment_test_access_grants g
    where g.organization_id = v_org_id
      and g.test_id = v_fiat_test_id
      and g.status = 'active'
      and g.archived_at is null
  ) then
    raise exception
      'FASE5G1_ABORT: Teste 12 Fiat possui grant ativo inesperado.';
  end if;

  if exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.test_id = v_fiat_test_id
      and a.archived_at is null
  ) then
    raise exception
      'FASE5G1_ABORT: Teste 12 Fiat possui tentativa inesperada.';
  end if;
end
$guard$;

-- ============================================================================
-- Abertura temporária do Teste 11.
-- ============================================================================

update public.assessment_tests
set
  status = 'active',
  metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
    'homologation_window', true,
    'homologation_window_scope', 'functional_smoke_test',
    'homologation_window_phase', '5G1',
    'homologation_window_test_number', 11,
    'homologation_window_opened_on', '2026-08-21'
  )
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and id = 'dd671e5f-39ec-5018-9263-78613361a7db'::uuid
  and sequence_no = 11
  and code = 'regulamento_vw_cnvw_v1'
  and status = 'draft'
  and archived_at is null;

update public.assessment_test_versions
set
  status = 'published',
  valid_from = now(),
  valid_until = now() + interval '4 hours',
  published_at = now(),
  metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
    'homologation_window', true,
    'homologation_window_scope', 'functional_smoke_test',
    'homologation_window_phase', '5G1',
    'homologation_window_duration_hours', 4,
    'homologation_window_requires_member_grant', true,
    'homologation_window_publication', 'temporary'
  )
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and id = 'fcf8f979-c44e-5993-beef-d023312ab5b7'::uuid
  and test_id = 'dd671e5f-39ec-5018-9263-78613361a7db'::uuid
  and version_code = 'cnvw-v3.0-v1'
  and status = 'draft'
  and passing_score = 90
  and legal_min_score = 90
  and published_at is null
  and archived_at is null;

-- ============================================================================
-- Pós-check fail-closed.
-- ============================================================================

do $postcheck$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
  v_vw_test_id uuid := 'dd671e5f-39ec-5018-9263-78613361a7db'::uuid;
  v_vw_version_id uuid := 'fcf8f979-c44e-5993-beef-d023312ab5b7'::uuid;
  v_fiat_test_id uuid := '61d013e4-3b4b-5676-b39c-6d340f87b046'::uuid;
  v_fiat_version_id uuid := '74243315-ea1e-5178-83b8-d6077ab9dc59'::uuid;
begin
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.organization_id = t.organization_id
     and v.test_id = t.id
     and v.id = v_vw_version_id
     and v.archived_at is null
    where t.organization_id = v_org_id
      and t.id = v_vw_test_id
      and t.sequence_no = 11
      and t.code = 'regulamento_vw_cnvw_v1'
      and t.status = 'active'
      and t.archived_at is null
      and v.version_code = 'cnvw-v3.0-v1'
      and v.status = 'published'
      and v.passing_score = 90
      and v.legal_min_score = 90
      and v.valid_from is not null
      and v.valid_from <= now()
      and v.valid_until is not null
      and v.valid_until > now()
      and v.valid_until <= now() + interval '4 hours 1 minute'
      and v.published_at is not null
      and coalesce((v.metadata->>'homologation_window')::boolean, false) = true
      and v.metadata->>'homologation_window_phase' = '5G1'
      and v.metadata->>'homologation_window_publication' = 'temporary'
      and coalesce((v.metadata->>'homologation_window_requires_member_grant')::boolean, false) = true
  ) then
    raise exception
      'FASE5G1_ABORT: publicacao temporaria do Teste 11 nao conferiu.';
  end if;

  -- A migration não cria grant.
  if exists (
    select 1
    from private.assessment_test_access_grants g
    where g.organization_id = v_org_id
      and g.test_id = v_vw_test_id
      and g.status = 'active'
      and g.archived_at is null
  ) then
    raise exception
      'FASE5G1_ABORT: grant ativo foi criado indevidamente no Teste 11.';
  end if;

  -- A migration não cria tentativa.
  if exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.test_id = v_vw_test_id
      and a.archived_at is null
  ) then
    raise exception
      'FASE5G1_ABORT: tentativa foi criada indevidamente no Teste 11.';
  end if;

  -- Fiat permanece fechado e intocado.
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.organization_id = t.organization_id
     and v.test_id = t.id
     and v.id = v_fiat_version_id
     and v.archived_at is null
    where t.organization_id = v_org_id
      and t.id = v_fiat_test_id
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
    raise exception
      'FASE5G1_ABORT: Teste 12 Fiat foi alterado indevidamente.';
  end if;

  if exists (
    select 1
    from private.assessment_test_access_grants g
    where g.organization_id = v_org_id
      and g.test_id = v_fiat_test_id
      and g.status = 'active'
      and g.archived_at is null
  ) then
    raise exception
      'FASE5G1_ABORT: Teste 12 Fiat recebeu grant indevido.';
  end if;

  if exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.test_id = v_fiat_test_id
      and a.archived_at is null
  ) then
    raise exception
      'FASE5G1_ABORT: Teste 12 Fiat recebeu tentativa indevida.';
  end if;
end
$postcheck$;

commit;
