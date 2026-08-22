begin;

-- ============================================================================
-- RF Performance
-- Fase 5E — Governança da fonte regulatória Fiat
--
-- Objetivo:
--   Registrar formalmente a decisão de governança de aceitar como referência
--   controlada atual o Regulamento do Consórcio Fiat:
--     Versão 3 — Resolução 285/23 — C.E. 07/24
--
-- Evidência de proveniência declarada pelo responsável do projeto:
--   - documento enviado diretamente pela administradora;
--   - mesma versão disponibilizada no aplicativo oficial do Consórcio Fiat.
--
-- Importante:
--   - não publica o Teste 12;
--   - não altera questões, opções ou gabaritos;
--   - não altera os thresholds 100/100;
--   - não concede acesso;
--   - não cria tentativa;
--   - mantém o requisito de revisão legal antes da publicação;
--   - apenas fecha o gate de consistência/proveniência da fonte V3.
-- ============================================================================

do $$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
  v_test_id uuid := '61d013e4-3b4b-5676-b39c-6d340f87b046'::uuid;
  v_version_id uuid := '74243315-ea1e-5178-83b8-d6077ab9dc59'::uuid;
  v_material_id uuid := '417f7c60-3169-552d-9846-608e00809741'::uuid;
  v_source_version_id uuid := 'dadf433e-5d7c-5373-b926-ed299332598f'::uuid;
  v_expected_sha text := '74ed3efacb7ee931839c51666c7617018d5f42afa6d06a1473adb7ac226f173a';
  v_count bigint;
begin
  -- --------------------------------------------------------------------------
  -- Guardas fail-closed: Teste 12 e sua versão continuam inéditos.
  -- --------------------------------------------------------------------------
  select count(*)
    into v_count
  from public.assessment_tests t
  join public.assessment_test_versions v
    on v.organization_id = t.organization_id
   and v.test_id = t.id
   and v.id = v_version_id
   and v.archived_at is null
  where t.organization_id = v_org_id
    and t.id = v_test_id
    and t.code = 'regulamento_fiat_v1'
    and t.status = 'draft'
    and t.archived_at is null
    and v.version_code = 'fiat-v3-v1'
    and v.status = 'draft'
    and v.passing_score = 100
    and v.legal_min_score = 100
    and v.published_at is null;

  if v_count <> 1 then
    raise exception
      'FASE5E_ABORT: estado esperado do Teste 12/fiat-v3-v1 nao encontrado.';
  end if;

  select count(*)
    into v_count
  from private.assessment_test_access_grants g
  where g.organization_id = v_org_id
    and g.test_id = v_test_id
    and g.status = 'active'
    and g.archived_at is null;

  if v_count <> 0 then
    raise exception
      'FASE5E_ABORT: Teste 12 possui grant ativo.';
  end if;

  select count(*)
    into v_count
  from public.assessment_attempts a
  where a.organization_id = v_org_id
    and a.test_id = v_test_id
    and a.archived_at is null;

  if v_count <> 0 then
    raise exception
      'FASE5E_ABORT: Teste 12 possui tentativa registrada.';
  end if;

  select count(*)
    into v_count
  from public.assessment_version_questions avq
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_version_id
    and avq.archived_at is null;

  if v_count <> 30 then
    raise exception
      'FASE5E_ABORT: Teste 12 deveria possuir 30 questoes vinculadas; encontrado %.',
      v_count;
  end if;

  -- --------------------------------------------------------------------------
  -- Guardas da fonte V3 já catalogada.
  -- --------------------------------------------------------------------------
  select count(*)
    into v_count
  from public.source_materials sm
  join public.source_material_versions smv
    on smv.organization_id = sm.organization_id
   and smv.source_material_id = sm.id
   and smv.id = v_source_version_id
   and smv.archived_at is null
  where sm.organization_id = v_org_id
    and sm.id = v_material_id
    and sm.code = 'regulamento_fiat_embracon_v3'
    and sm.status = 'active'
    and sm.archived_at is null
    and smv.version_code = 'v3-res285-23-ce07-24'
    and smv.version_no = 1
    and smv.status = 'active'
    and smv.content_sha256 = v_expected_sha;

  if v_count <> 1 then
    raise exception
      'FASE5E_ABORT: fonte Fiat V3 controlada nao corresponde ao estado esperado.';
  end if;

  select count(*)
    into v_count
  from public.assessment_version_sources avs
  where avs.organization_id = v_org_id
    and avs.test_version_id = v_version_id
    and avs.source_material_version_id = v_source_version_id
    and avs.relation_type = 'primary'
    and avs.is_required = true
    and avs.archived_at is null;

  if v_count <> 1 then
    raise exception
      'FASE5E_ABORT: vinculo primario/obrigatorio da fonte Fiat V3 nao encontrado.';
  end if;

  -- --------------------------------------------------------------------------
  -- Decisão de governança da fonte.
  --
  -- external_currency_verified passa a TRUE com base em proveniência externa
  -- controlada (entrega direta pela administradora + disponibilidade no app
  -- oficial), e não por comparação com o PDF público do site.
  -- --------------------------------------------------------------------------
  update public.source_materials
  set metadata =
      coalesce(metadata, '{}'::jsonb)
      || jsonb_build_object(
           'external_currency_verified', true,
           'external_currency_verified_at', '2026-08-21',
           'external_currency_verification_basis',
             'administrator_direct_delivery_and_official_app_availability',
           'source_governance_status', 'accepted',
           'source_governance_phase', '5E',
           'source_governance_decision',
             'accept_latest_administrator_supplied_document_as_controlled_current_reference',
           'source_provenance_channels',
             jsonb_build_array(
               'administrator_direct_delivery',
               'consorcio_fiat_official_app'
             )
         )
  where organization_id = v_org_id
    and id = v_material_id
    and code = 'regulamento_fiat_embracon_v3'
    and archived_at is null;

  if not found then
    raise exception
      'FASE5E_ABORT: source_material Fiat nao atualizado.';
  end if;

  update public.source_material_versions
  set metadata =
      coalesce(metadata, '{}'::jsonb)
      || jsonb_build_object(
           'external_currency_verified', true,
           'external_currency_verified_at', '2026-08-21',
           'external_currency_verification_basis',
             'administrator_direct_delivery_and_official_app_availability',
           'source_governance_status', 'accepted',
           'source_governance_phase', '5E',
           'source_governance_decision',
             'accept_latest_administrator_supplied_document_as_controlled_current_reference',
           'source_provenance_channels',
             jsonb_build_array(
               'administrator_direct_delivery',
               'consorcio_fiat_official_app'
             )
         )
  where organization_id = v_org_id
    and id = v_source_version_id
    and source_material_id = v_material_id
    and version_code = 'v3-res285-23-ce07-24'
    and content_sha256 = v_expected_sha
    and archived_at is null;

  if not found then
    raise exception
      'FASE5E_ABORT: source_material_version Fiat nao atualizado.';
  end if;

  update public.assessment_version_sources
  set
    metadata =
      coalesce(metadata, '{}'::jsonb)
      || jsonb_build_object(
           'source_governance_status', 'accepted',
           'source_governance_phase', '5E',
           'source_governance_basis',
             'administrator_direct_delivery_and_official_app_availability',
           'source_content_sha256', v_expected_sha
         ),
    notes =
      case
        when coalesce(notes, '') = '' then
          'Fase 5E: fonte V3 aceita por governanca com base em envio direto da administradora e disponibilidade no aplicativo oficial do Consorcio Fiat.'
        when notes like '%Fase 5E:%' then notes
        else
          notes || E'\nFase 5E: fonte V3 aceita por governanca com base em envio direto da administradora e disponibilidade no aplicativo oficial do Consorcio Fiat.'
      end
  where organization_id = v_org_id
    and test_version_id = v_version_id
    and source_material_version_id = v_source_version_id
    and relation_type = 'primary'
    and is_required = true
    and archived_at is null;

  if not found then
    raise exception
      'FASE5E_ABORT: assessment_version_sources Fiat nao atualizado.';
  end if;

  update public.assessment_test_versions
  set metadata =
      coalesce(metadata, '{}'::jsonb)
      || jsonb_build_object(
           'external_currency_verified', true,
           'external_currency_verified_at', '2026-08-21',
           'external_currency_verification_basis',
             'administrator_direct_delivery_and_official_app_availability',
           'source_consistency_review_required', false,
           'source_consistency_review_status', 'approved',
           'source_governance_status', 'accepted',
           'source_governance_phase', '5E',
           'source_governance_decision',
             'accept_latest_administrator_supplied_document_as_controlled_current_reference',
           'source_content_sha256', v_expected_sha
         )
  where organization_id = v_org_id
    and id = v_version_id
    and test_id = v_test_id
    and version_code = 'fiat-v3-v1'
    and status = 'draft'
    and published_at is null
    and archived_at is null;

  if not found then
    raise exception
      'FASE5E_ABORT: assessment_test_version Fiat nao atualizado.';
  end if;

  -- --------------------------------------------------------------------------
  -- Pós-condições.
  -- --------------------------------------------------------------------------
  select count(*)
    into v_count
  from public.assessment_tests t
  join public.assessment_test_versions v
    on v.organization_id = t.organization_id
   and v.test_id = t.id
   and v.id = v_version_id
   and v.archived_at is null
  where t.organization_id = v_org_id
    and t.id = v_test_id
    and t.code = 'regulamento_fiat_v1'
    and t.status = 'draft'
    and t.archived_at is null
    and v.version_code = 'fiat-v3-v1'
    and v.status = 'draft'
    and v.passing_score = 100
    and v.legal_min_score = 100
    and v.published_at is null
    and v.metadata->>'external_currency_verified' = 'true'
    and v.metadata->>'source_consistency_review_required' = 'false'
    and v.metadata->>'source_consistency_review_status' = 'approved'
    and v.metadata->>'source_governance_status' = 'accepted'
    and v.metadata->>'source_governance_phase' = '5E'
    and v.metadata->>'source_content_sha256' = v_expected_sha;

  if v_count <> 1 then
    raise exception
      'FASE5E_ABORT: pos-condicao da versao do Teste 12 falhou.';
  end if;

  select count(*)
    into v_count
  from public.source_materials sm
  join public.source_material_versions smv
    on smv.organization_id = sm.organization_id
   and smv.source_material_id = sm.id
   and smv.id = v_source_version_id
   and smv.archived_at is null
  where sm.organization_id = v_org_id
    and sm.id = v_material_id
    and sm.archived_at is null
    and sm.metadata->>'external_currency_verified' = 'true'
    and sm.metadata->>'source_governance_status' = 'accepted'
    and smv.content_sha256 = v_expected_sha
    and smv.metadata->>'external_currency_verified' = 'true'
    and smv.metadata->>'source_governance_status' = 'accepted';

  if v_count <> 1 then
    raise exception
      'FASE5E_ABORT: pos-condicao da fonte Fiat V3 falhou.';
  end if;

  select count(*)
    into v_count
  from private.assessment_test_access_grants g
  where g.organization_id = v_org_id
    and g.test_id = v_test_id
    and g.status = 'active'
    and g.archived_at is null;

  if v_count <> 0 then
    raise exception
      'FASE5E_ABORT: pos-condicao detectou grant ativo inesperado.';
  end if;

  select count(*)
    into v_count
  from public.assessment_attempts a
  where a.organization_id = v_org_id
    and a.test_id = v_test_id
    and a.archived_at is null;

  if v_count <> 0 then
    raise exception
      'FASE5E_ABORT: pos-condicao detectou tentativa inesperada.';
  end if;
end
$$;

commit;
