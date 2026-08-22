begin;

-- ============================================================================
-- RF Performance
-- Fase 5F — Política definitiva de aprovação dos Testes Regulatórios 11 e 12
--
-- Teste 11 — Volkswagen / CNVW
--   passing_score   = 90
--   legal_min_score = 90
--
-- Teste 12 — Fiat
--   passing_score   = 90
--   legal_min_score = 90
--
-- Regras desta fase:
--   - ambos permanecem draft;
--   - nenhuma publicação;
--   - nenhum grant;
--   - nenhuma tentativa;
--   - nenhuma alteração em questões, opções, gabaritos ou fontes;
--   - substitui apenas o fail-closed temporário 100/100 pela política 90/90.
-- ============================================================================

do $$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;

  v_vw_test_id uuid := 'dd671e5f-39ec-5018-9263-78613361a7db'::uuid;
  v_vw_version_id uuid := 'fcf8f979-c44e-5993-beef-d023312ab5b7'::uuid;

  v_fiat_test_id uuid := '61d013e4-3b4b-5676-b39c-6d340f87b046'::uuid;
  v_fiat_version_id uuid := '74243315-ea1e-5178-83b8-d6077ab9dc59'::uuid;

  v_count bigint;
begin
  -- --------------------------------------------------------------------------
  -- 1) Guardas fail-closed — Volkswagen
  -- --------------------------------------------------------------------------
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
    and t.code = 'regulamento_vw_cnvw_v1'
    and t.status = 'draft'
    and t.archived_at is null
    and v.version_code = 'cnvw-v3.0-v1'
    and v.status = 'draft'
    and v.passing_score = 100
    and v.legal_min_score = 100
    and v.published_at is null;

  if v_count <> 1 then
    raise exception
      'FASE5F_ABORT: estado esperado do Teste 11 / cnvw-v3.0-v1 nao encontrado.';
  end if;

  select count(*)
    into v_count
  from public.assessment_version_questions avq
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_vw_version_id
    and avq.archived_at is null;

  if v_count <> 30 then
    raise exception
      'FASE5F_ABORT: Teste 11 deveria possuir 30 questoes vinculadas; encontrado %.',
      v_count;
  end if;

  select count(*)
    into v_count
  from private.assessment_test_access_grants g
  where g.organization_id = v_org_id
    and g.test_id = v_vw_test_id
    and g.status = 'active'
    and g.archived_at is null;

  if v_count <> 0 then
    raise exception
      'FASE5F_ABORT: Teste 11 possui grant ativo.';
  end if;

  select count(*)
    into v_count
  from public.assessment_attempts a
  where a.organization_id = v_org_id
    and a.test_id = v_vw_test_id
    and a.archived_at is null;

  if v_count <> 0 then
    raise exception
      'FASE5F_ABORT: Teste 11 possui tentativa registrada.';
  end if;

  -- --------------------------------------------------------------------------
  -- 2) Guardas fail-closed — Fiat
  -- --------------------------------------------------------------------------
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
    and t.code = 'regulamento_fiat_v1'
    and t.status = 'draft'
    and t.archived_at is null
    and v.version_code = 'fiat-v3-v1'
    and v.status = 'draft'
    and v.passing_score = 100
    and v.legal_min_score = 100
    and v.published_at is null
    and v.metadata->>'external_currency_verified' = 'true'
    and v.metadata->>'source_consistency_review_status' = 'approved'
    and v.metadata->>'source_governance_status' = 'accepted'
    and v.metadata->>'source_governance_phase' = '5E';

  if v_count <> 1 then
    raise exception
      'FASE5F_ABORT: estado esperado do Teste 12 / fiat-v3-v1 nao encontrado.';
  end if;

  select count(*)
    into v_count
  from public.assessment_version_questions avq
  where avq.organization_id = v_org_id
    and avq.test_version_id = v_fiat_version_id
    and avq.archived_at is null;

  if v_count <> 30 then
    raise exception
      'FASE5F_ABORT: Teste 12 deveria possuir 30 questoes vinculadas; encontrado %.',
      v_count;
  end if;

  select count(*)
    into v_count
  from private.assessment_test_access_grants g
  where g.organization_id = v_org_id
    and g.test_id = v_fiat_test_id
    and g.status = 'active'
    and g.archived_at is null;

  if v_count <> 0 then
    raise exception
      'FASE5F_ABORT: Teste 12 possui grant ativo.';
  end if;

  select count(*)
    into v_count
  from public.assessment_attempts a
  where a.organization_id = v_org_id
    and a.test_id = v_fiat_test_id
    and a.archived_at is null;

  if v_count <> 0 then
    raise exception
      'FASE5F_ABORT: Teste 12 possui tentativa registrada.';
  end if;

  -- --------------------------------------------------------------------------
  -- 3) Aplicação da política 90/90 — Volkswagen
  -- --------------------------------------------------------------------------
  update public.assessment_test_versions
  set
    passing_score = 90,
    legal_min_score = 90,
    metadata =
      coalesce(metadata, '{}'::jsonb)
      || jsonb_build_object(
           'approval_policy_status', 'approved',
           'approval_policy_phase', '5F',
           'approval_policy_passing_score', 90,
           'approval_policy_legal_min_score', 90,
           'approval_policy_min_correct_answers_out_of_30', 27,
           'previous_fail_closed_passing_score', 100,
           'previous_fail_closed_legal_min_score', 100
         )
  where organization_id = v_org_id
    and id = v_vw_version_id
    and test_id = v_vw_test_id
    and version_code = 'cnvw-v3.0-v1'
    and status = 'draft'
    and passing_score = 100
    and legal_min_score = 100
    and published_at is null
    and archived_at is null;

  if not found then
    raise exception
      'FASE5F_ABORT: politica do Teste 11 nao foi aplicada.';
  end if;

  -- --------------------------------------------------------------------------
  -- 4) Aplicação da política 90/90 — Fiat
  -- --------------------------------------------------------------------------
  update public.assessment_test_versions
  set
    passing_score = 90,
    legal_min_score = 90,
    metadata =
      coalesce(metadata, '{}'::jsonb)
      || jsonb_build_object(
           'approval_policy_status', 'approved',
           'approval_policy_phase', '5F',
           'approval_policy_passing_score', 90,
           'approval_policy_legal_min_score', 90,
           'approval_policy_min_correct_answers_out_of_30', 27,
           'previous_fail_closed_passing_score', 100,
           'previous_fail_closed_legal_min_score', 100
         )
  where organization_id = v_org_id
    and id = v_fiat_version_id
    and test_id = v_fiat_test_id
    and version_code = 'fiat-v3-v1'
    and status = 'draft'
    and passing_score = 100
    and legal_min_score = 100
    and published_at is null
    and archived_at is null;

  if not found then
    raise exception
      'FASE5F_ABORT: politica do Teste 12 nao foi aplicada.';
  end if;

  -- --------------------------------------------------------------------------
  -- 5) Pós-condições — ambos continuam draft, inéditos e sem acesso.
  -- --------------------------------------------------------------------------
  select count(*)
    into v_count
  from public.assessment_tests t
  join public.assessment_test_versions v
    on v.organization_id = t.organization_id
   and v.test_id = t.id
   and v.archived_at is null
  where t.organization_id = v_org_id
    and t.archived_at is null
    and t.status = 'draft'
    and v.status = 'draft'
    and v.passing_score = 90
    and v.legal_min_score = 90
    and v.published_at is null
    and v.metadata->>'approval_policy_status' = 'approved'
    and v.metadata->>'approval_policy_phase' = '5F'
    and (
      (t.id = v_vw_test_id
       and t.code = 'regulamento_vw_cnvw_v1'
       and v.id = v_vw_version_id
       and v.version_code = 'cnvw-v3.0-v1')
      or
      (t.id = v_fiat_test_id
       and t.code = 'regulamento_fiat_v1'
       and v.id = v_fiat_version_id
       and v.version_code = 'fiat-v3-v1')
    );

  if v_count <> 2 then
    raise exception
      'FASE5F_ABORT: pos-condicao 90/90 dos Testes 11 e 12 falhou; encontrados %.',
      v_count;
  end if;

  select count(*)
    into v_count
  from private.assessment_test_access_grants g
  where g.organization_id = v_org_id
    and g.test_id in (v_vw_test_id, v_fiat_test_id)
    and g.status = 'active'
    and g.archived_at is null;

  if v_count <> 0 then
    raise exception
      'FASE5F_ABORT: pos-condicao detectou grant ativo inesperado.';
  end if;

  select count(*)
    into v_count
  from public.assessment_attempts a
  where a.organization_id = v_org_id
    and a.test_id in (v_vw_test_id, v_fiat_test_id)
    and a.archived_at is null;

  if v_count <> 0 then
    raise exception
      'FASE5F_ABORT: pos-condicao detectou tentativa inesperada.';
  end if;
end
$$;

commit;
