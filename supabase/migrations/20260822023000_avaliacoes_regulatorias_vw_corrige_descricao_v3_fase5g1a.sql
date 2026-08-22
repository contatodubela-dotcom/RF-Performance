-- ============================================================================
-- RF Performance — Avaliações e Certificações
-- Homologação Regulatória
-- Fase 5G1A — Correção mínima da descrição do Teste 11 Volkswagen
--
-- Objetivo:
--   Corrigir exclusivamente a descrição pública do Teste 11 para refletir
--   a fonte já reconciliada e homologada: CNVW/Embracon Versão 3.0.
--
-- ESCOPO / SEGURANÇA
--   - Não altera questões, alternativas, gabaritos, competências ou fontes.
--   - Não altera política 90/90.
--   - Não altera grant, tentativa, status, published_at, valid_from ou valid_until.
--   - Mantém a janela temporária Fase 5G1 exatamente como está.
--   - Mantém o Teste 12 Fiat intocado.
-- ============================================================================

begin;

do $guard$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
  v_vw_test_id uuid := 'dd671e5f-39ec-5018-9263-78613361a7db'::uuid;
  v_vw_version_id uuid := 'fcf8f979-c44e-5993-beef-d023312ab5b7'::uuid;
  v_fiat_test_id uuid := '61d013e4-3b4b-5676-b39c-6d340f87b046'::uuid;
  v_fiat_version_id uuid := '74243315-ea1e-5178-83b8-d6077ab9dc59'::uuid;
begin
  -- Teste 11 deve estar na janela controlada correta e ainda sem tentativa.
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
      and t.title = 'Avaliação Regulamentar — Consórcio Volkswagen'
      and t.description =
          'Avaliação de conhecimento sobre o Regulamento do Contrato de Consórcio CNVW/Embracon, Versão 2.1, estruturada em oito blocos temáticos.'
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
      and v.published_at is not null
      and v.metadata->>'approval_policy_status' = 'approved'
      and v.metadata->>'approval_policy_phase' = '5F'
      and v.metadata->>'homologation_window_phase' = '5G1'
      and v.metadata->>'homologation_window_publication' = 'temporary'
  ) then
    raise exception
      'FASE5G1A_ABORT: identidade, descricao antiga ou estado da janela do Teste 11 nao conferem.';
  end if;

  if exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.test_id = v_vw_test_id
      and a.archived_at is null
  ) then
    raise exception
      'FASE5G1A_ABORT: Teste 11 ja possui tentativa; correcao abortada.';
  end if;

  -- Fiat deve permanecer fechado e inalterado.
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
      'FASE5G1A_ABORT: Teste 12 Fiat nao esta no estado fechado esperado.';
  end if;
end
$guard$;

update public.assessment_tests
set description =
  'Avaliação de conhecimento sobre o Regulamento do Contrato de Consórcio CNVW/Embracon, Versão 3.0, estruturada em oito blocos temáticos.'
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and id = 'dd671e5f-39ec-5018-9263-78613361a7db'::uuid
  and sequence_no = 11
  and code = 'regulamento_vw_cnvw_v1'
  and description =
      'Avaliação de conhecimento sobre o Regulamento do Contrato de Consórcio CNVW/Embracon, Versão 2.1, estruturada em oito blocos temáticos.'
  and status = 'active'
  and archived_at is null;

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
      and t.description =
          'Avaliação de conhecimento sobre o Regulamento do Contrato de Consórcio CNVW/Embracon, Versão 3.0, estruturada em oito blocos temáticos.'
      and t.status = 'active'
      and t.archived_at is null
      and v.version_code = 'cnvw-v3.0-v1'
      and v.status = 'published'
      and v.passing_score = 90
      and v.legal_min_score = 90
      and v.valid_from is not null
      and v.valid_until is not null
      and v.published_at is not null
      and v.metadata->>'approval_policy_status' = 'approved'
      and v.metadata->>'approval_policy_phase' = '5F'
      and v.metadata->>'homologation_window_phase' = '5G1'
      and v.metadata->>'homologation_window_publication' = 'temporary'
  ) then
    raise exception
      'FASE5G1A_ABORT: descricao corrigida ou estado do Teste 11 nao conferem no pos-check.';
  end if;

  if exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.test_id = v_vw_test_id
      and a.archived_at is null
  ) then
    raise exception
      'FASE5G1A_ABORT: tentativa foi criada indevidamente.';
  end if;

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
      'FASE5G1A_ABORT: Teste 12 Fiat foi alterado indevidamente.';
  end if;
end
$postcheck$;

commit;
