-- ============================================================================
-- RF Performance — Avaliações e Certificações
-- Homologação do Catálogo Ampliado
-- Fase 4B — Janela controlada de smoke test funcional do Teste 6 VAP
--
-- Objetivo:
--   Abrir por 4 horas apenas o Teste 6 para homologação funcional real.
--
-- ESCOPO / SEGURANÇA
--   - Publica temporariamente somente o Teste 6 e sua versão 2026.08-v1.
--   - Mantém Testes 7 a 12 em draft.
--   - Não cria grant de acesso: o grant será concedido pela interface administrativa
--     existente, exclusivamente ao participante piloto, preservando o fluxo real.
--   - Não cria tentativa.
--   - Não altera questões, alternativas, gabaritos, fontes, competências ou cortes.
--   - A versão expira automaticamente 4 horas após a aplicação desta migration.
--   - Qualquer publicação definitiva ou retorno a draft será feita em nova migration.
-- ============================================================================

begin;

do $guard$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
  v_test_id uuid := '77c2984e-c0e8-5829-94ba-fcb0076ce8b6'::uuid;
  v_version_id uuid := '07ed48aa-b1ac-547f-8fa5-a93c1441cc3c'::uuid;
begin
  if not exists (
    select 1
    from public.organizations o
    where o.id = v_org_id
      and o.slug = 'rf-consorcios'
      and o.status = 'active'
      and o.archived_at is null
  ) then
    raise exception 'Smoke Teste 6 abortado: organização RF esperada não localizada/ativa.';
  end if;

  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions tv
      on tv.test_id = t.id
     and tv.organization_id = t.organization_id
     and tv.archived_at is null
    where t.organization_id = v_org_id
      and t.id = v_test_id
      and t.sequence_no = 6
      and t.code = 'teste_6_vap_fundamentos_mentalidade_valor'
      and t.status = 'draft'
      and t.archived_at is null
      and tv.id = v_version_id
      and tv.version_code = '2026.08-v1'
      and tv.status = 'draft'
      and tv.passing_score = 75
      and tv.legal_min_score = 80
      and tv.question_count = 30
      and tv.published_at is null
      and coalesce((tv.metadata ->> 'approval_policy_defined')::boolean, false) = true
      and tv.metadata ->> 'approval_threshold_strategy' = 'approved_catalog_policy'
      and tv.metadata ->> 'homologation_policy_status' = 'approved_for_smoke_test'
  ) then
    raise exception 'Smoke Teste 6 abortado: identidade/estado/política esperados não conferem.';
  end if;

  if (
    select count(*)
    from public.assessment_test_versions tv
    where tv.organization_id = v_org_id
      and tv.test_id = v_test_id
      and tv.archived_at is null
  ) <> 1 then
    raise exception 'Smoke Teste 6 abortado: esperado exatamente 1 versão ativa no catálogo.';
  end if;

  if (
    select count(*)
    from public.assessment_version_questions avq
    join public.assessment_questions q
      on q.id = avq.question_id
     and q.organization_id = avq.organization_id
     and q.archived_at is null
    where avq.organization_id = v_org_id
      and avq.test_version_id = v_version_id
      and avq.archived_at is null
      and q.status = 'reviewed'
  ) <> 30 then
    raise exception 'Smoke Teste 6 abortado: esperado 30 questões reviewed.';
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
    raise exception 'Smoke Teste 6 abortado: esperado 120 alternativas.';
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
    raise exception 'Smoke Teste 6 abortado: esperado 30 gabaritos privados.';
  end if;

  if (
    select count(*)
    from public.assessment_version_sources avs
    where avs.organization_id = v_org_id
      and avs.test_version_id = v_version_id
      and avs.archived_at is null
  ) < 1 then
    raise exception 'Smoke Teste 6 abortado: fonte versionada obrigatória não localizada.';
  end if;

  if exists (
    select 1
    from private.assessment_test_access_grants g
    where g.organization_id = v_org_id
      and g.test_id = v_test_id
      and g.status = 'active'
      and g.archived_at is null
  ) then
    raise exception 'Smoke Teste 6 abortado: já existe grant ativo.';
  end if;

  if exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.test_id = v_test_id
      and a.archived_at is null
  ) then
    raise exception 'Smoke Teste 6 abortado: já existe tentativa.';
  end if;

  if (
    select count(*)
    from public.assessment_tests t
    join public.assessment_test_versions tv
      on tv.test_id = t.id
     and tv.organization_id = t.organization_id
     and tv.archived_at is null
    where t.organization_id = v_org_id
      and t.sequence_no between 7 and 12
      and t.archived_at is null
      and t.status = 'draft'
      and tv.status = 'draft'
  ) <> 6 then
    raise exception 'Smoke Teste 6 abortado: Testes 7 a 12 não estão integralmente preservados em draft.';
  end if;
end
$guard$;

update public.assessment_tests
set
  status = 'active',
  metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
    'homologation_window', true,
    'homologation_window_scope', 'functional_smoke_test',
    'homologation_window_test_number', 6,
    'homologation_window_opened_on', '2026-08-21'
  )
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and id = '77c2984e-c0e8-5829-94ba-fcb0076ce8b6'::uuid
  and sequence_no = 6
  and code = 'teste_6_vap_fundamentos_mentalidade_valor'
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
    'homologation_window_duration_hours', 4,
    'homologation_window_requires_member_grant', true,
    'homologation_window_publication', 'temporary'
  )
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and id = '07ed48aa-b1ac-547f-8fa5-a93c1441cc3c'::uuid
  and test_id = '77c2984e-c0e8-5829-94ba-fcb0076ce8b6'::uuid
  and version_code = '2026.08-v1'
  and status = 'draft'
  and passing_score = 75
  and legal_min_score = 80
  and archived_at is null;

do $postcheck$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
  v_test_id uuid := '77c2984e-c0e8-5829-94ba-fcb0076ce8b6'::uuid;
  v_version_id uuid := '07ed48aa-b1ac-547f-8fa5-a93c1441cc3c'::uuid;
begin
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions tv
      on tv.test_id = t.id
     and tv.organization_id = t.organization_id
     and tv.archived_at is null
    where t.organization_id = v_org_id
      and t.id = v_test_id
      and t.status = 'active'
      and t.archived_at is null
      and tv.id = v_version_id
      and tv.status = 'published'
      and tv.passing_score = 75
      and tv.legal_min_score = 80
      and tv.valid_from is not null
      and tv.valid_from <= now()
      and tv.valid_until is not null
      and tv.valid_until > now()
      and tv.valid_until <= now() + interval '4 hours 1 minute'
      and tv.published_at is not null
      and coalesce((tv.metadata ->> 'homologation_window')::boolean, false) = true
      and tv.metadata ->> 'homologation_window_publication' = 'temporary'
  ) then
    raise exception 'Smoke Teste 6 inválido após abertura: publicação temporária não conferiu.';
  end if;

  if exists (
    select 1
    from private.assessment_test_access_grants g
    where g.organization_id = v_org_id
      and g.test_id = v_test_id
      and g.status = 'active'
      and g.archived_at is null
  ) then
    raise exception 'Smoke Teste 6 inválido após abertura: grant foi criado indevidamente.';
  end if;

  if exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.test_id = v_test_id
      and a.archived_at is null
  ) then
    raise exception 'Smoke Teste 6 inválido após abertura: tentativa foi criada indevidamente.';
  end if;

  if (
    select count(*)
    from public.assessment_tests t
    join public.assessment_test_versions tv
      on tv.test_id = t.id
     and tv.organization_id = t.organization_id
     and tv.archived_at is null
    where t.organization_id = v_org_id
      and t.sequence_no between 7 and 12
      and t.archived_at is null
      and t.status = 'draft'
      and tv.status = 'draft'
  ) <> 6 then
    raise exception 'Smoke Teste 6 inválido após abertura: Testes 7 a 12 foram alterados.';
  end if;
end
$postcheck$;

commit;
