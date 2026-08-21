-- ============================================================================
-- RF Performance — Avaliações e Certificações
-- Homologação do Catálogo Ampliado
-- Fase 4D — Publicação definitiva dos Testes VAP 6 a 10
--
-- Objetivo:
--   Publicar definitivamente os Testes VAP 6 a 10 após:
--   - auditoria estrutural do catálogo;
--   - definição e homologação dos cortes de aprovação;
--   - smoke funcional representativo de ponta a ponta no Teste 6.
--
-- ESCOPO / SEGURANÇA
--   - Publica somente os Testes VAP 6 a 10 e suas versões 2026.08-v1.
--   - NÃO cria grants de acesso.
--   - NÃO cria tentativas.
--   - Preserva integralmente o histórico do smoke do Teste 6.
--   - Mantém Testes 11 e 12 (Volkswagen e Fiat) em draft 100/100.
--   - Não altera questões, alternativas, gabaritos, fontes ou competências.
-- ============================================================================

begin;

do $guard$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
  v_expected integer;
  v_actual integer;
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
    raise exception 'Publicação VAP 6-10 abortada: organização RF esperada não localizada/ativa.';
  end if;

  -- Devem existir exatamente os cinco testes VAP alvo, todos em draft,
  -- cada um com uma única versão 2026.08-v1 também em draft.
  select count(*)
  into v_actual
  from public.assessment_tests t
  join public.assessment_test_versions tv
    on tv.test_id = t.id
   and tv.organization_id = t.organization_id
   and tv.archived_at is null
  where t.organization_id = v_org_id
    and t.sequence_no between 6 and 10
    and t.archived_at is null
    and t.status = 'draft'
    and tv.version_code = '2026.08-v1'
    and tv.status = 'draft';

  if v_actual <> 5 then
    raise exception 'Publicação VAP 6-10 abortada: esperado 5 testes/versões alvo em draft; encontrado %.', v_actual;
  end if;

  -- Identidades e cortes aprovados.
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions tv
      on tv.test_id = t.id
     and tv.organization_id = t.organization_id
     and tv.archived_at is null
    where t.organization_id = v_org_id
      and t.sequence_no = 6
      and t.id = '77c2984e-c0e8-5829-94ba-fcb0076ce8b6'::uuid
      and t.code = 'teste_6_vap_fundamentos_mentalidade_valor'
      and t.status = 'draft'
      and tv.id = '07ed48aa-b1ac-547f-8fa5-a93c1441cc3c'::uuid
      and tv.version_code = '2026.08-v1'
      and tv.status = 'draft'
      and tv.passing_score = 75
      and tv.legal_min_score = 80
      and tv.question_count = 30
      and tv.valid_from is null
      and tv.valid_until is null
      and tv.published_at is null
      and tv.metadata ->> 'approval_threshold_strategy' = 'approved_catalog_policy'
      and tv.metadata ->> 'homologation_smoke_test_status' = 'passed'
  ) then
    raise exception 'Publicação VAP 6-10 abortada: Teste 6 não confere com o estado homologado.';
  end if;

  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions tv
      on tv.test_id = t.id
     and tv.organization_id = t.organization_id
     and tv.archived_at is null
    where t.organization_id = v_org_id
      and t.sequence_no = 7
      and t.id = '41106d9b-7db0-5ea3-9693-f625c58f5936'::uuid
      and t.code = 'teste_7_vap_lideranca_disc'
      and t.status = 'draft'
      and tv.id = '3cd020ca-68ce-5b6c-8e2f-9bbc228ef18e'::uuid
      and tv.version_code = '2026.08-v1'
      and tv.status = 'draft'
      and tv.passing_score = 80
      and tv.legal_min_score = 85
      and tv.question_count = 30
      and tv.valid_from is null
      and tv.valid_until is null
      and tv.published_at is null
      and tv.metadata ->> 'approval_threshold_strategy' = 'approved_catalog_policy'
  ) then
    raise exception 'Publicação VAP 6-10 abortada: Teste 7 não confere com a política aprovada.';
  end if;

  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions tv
      on tv.test_id = t.id
     and tv.organization_id = t.organization_id
     and tv.archived_at is null
    where t.organization_id = v_org_id
      and t.sequence_no = 8
      and t.id = '596353c9-73e3-59c6-81a3-796ac376f7aa'::uuid
      and t.code = 'teste_8_vap_neurovendas_copywriting'
      and t.status = 'draft'
      and tv.id = '34b181a4-c718-555e-8909-754d58bbccf2'::uuid
      and tv.version_code = '2026.08-v1'
      and tv.status = 'draft'
      and tv.passing_score = 80
      and tv.legal_min_score = 85
      and tv.question_count = 30
      and tv.valid_from is null
      and tv.valid_until is null
      and tv.published_at is null
      and tv.metadata ->> 'approval_threshold_strategy' = 'approved_catalog_policy'
  ) then
    raise exception 'Publicação VAP 6-10 abortada: Teste 8 não confere com a política aprovada.';
  end if;

  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions tv
      on tv.test_id = t.id
     and tv.organization_id = t.organization_id
     and tv.archived_at is null
    where t.organization_id = v_org_id
      and t.sequence_no = 9
      and t.id = 'de4e5063-786f-54e9-b9b0-257eccd982d3'::uuid
      and t.code = 'teste_9_vap_etapas_venda_objecoes'
      and t.status = 'draft'
      and tv.id = '0b76646a-faa0-582f-8c9f-95ddac016717'::uuid
      and tv.version_code = '2026.08-v1'
      and tv.status = 'draft'
      and tv.passing_score = 85
      and tv.legal_min_score = 90
      and tv.question_count = 30
      and tv.valid_from is null
      and tv.valid_until is null
      and tv.published_at is null
      and tv.metadata ->> 'approval_threshold_strategy' = 'approved_catalog_policy'
  ) then
    raise exception 'Publicação VAP 6-10 abortada: Teste 9 não confere com a política aprovada.';
  end if;

  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions tv
      on tv.test_id = t.id
     and tv.organization_id = t.organization_id
     and tv.archived_at is null
    where t.organization_id = v_org_id
      and t.sequence_no = 10
      and t.id = 'c2933dbe-62c7-57f8-9b87-3db4d194bde0'::uuid
      and t.code = 'teste_10_vap_ia_vendas_persuasao'
      and t.status = 'draft'
      and tv.id = '867c9840-67c2-5424-a79a-e847886938b2'::uuid
      and tv.version_code = '2026.08-v1'
      and tv.status = 'draft'
      and tv.passing_score = 88
      and tv.legal_min_score = 90
      and tv.question_count = 30
      and tv.valid_from is null
      and tv.valid_until is null
      and tv.published_at is null
      and tv.metadata ->> 'approval_threshold_strategy' = 'approved_catalog_policy'
  ) then
    raise exception 'Publicação VAP 6-10 abortada: Teste 10 não confere com a política aprovada.';
  end if;

  -- Integridade mínima consolidada dos cinco testes.
  select count(*)
  into v_actual
  from public.assessment_version_questions avq
  join public.assessment_test_versions tv
    on tv.id = avq.test_version_id
   and tv.organization_id = avq.organization_id
   and tv.archived_at is null
  join public.assessment_tests t
    on t.id = tv.test_id
   and t.organization_id = tv.organization_id
   and t.archived_at is null
  join public.assessment_questions q
    on q.id = avq.question_id
   and q.organization_id = avq.organization_id
   and q.archived_at is null
  where t.organization_id = v_org_id
    and t.sequence_no between 6 and 10
    and avq.archived_at is null
    and q.status = 'reviewed';

  if v_actual <> 150 then
    raise exception 'Publicação VAP 6-10 abortada: esperado 150 vínculos com questões reviewed; encontrado %.', v_actual;
  end if;

  select count(*)
  into v_actual
  from public.assessment_question_options o
  join public.assessment_version_questions avq
    on avq.question_id = o.question_id
   and avq.organization_id = o.organization_id
   and avq.archived_at is null
  join public.assessment_test_versions tv
    on tv.id = avq.test_version_id
   and tv.organization_id = avq.organization_id
   and tv.archived_at is null
  join public.assessment_tests t
    on t.id = tv.test_id
   and t.organization_id = tv.organization_id
   and t.archived_at is null
  where t.organization_id = v_org_id
    and t.sequence_no between 6 and 10
    and o.archived_at is null;

  if v_actual <> 600 then
    raise exception 'Publicação VAP 6-10 abortada: esperado 600 alternativas; encontrado %.', v_actual;
  end if;

  select count(*)
  into v_actual
  from private.assessment_question_keys k
  join public.assessment_version_questions avq
    on avq.question_id = k.question_id
   and avq.organization_id = k.organization_id
   and avq.archived_at is null
  join public.assessment_test_versions tv
    on tv.id = avq.test_version_id
   and tv.organization_id = avq.organization_id
   and tv.archived_at is null
  join public.assessment_tests t
    on t.id = tv.test_id
   and t.organization_id = tv.organization_id
   and t.archived_at is null
  where t.organization_id = v_org_id
    and t.sequence_no between 6 and 10;

  if v_actual <> 150 then
    raise exception 'Publicação VAP 6-10 abortada: esperado 150 gabaritos privados; encontrado %.', v_actual;
  end if;

  -- Não pode existir grant ativo para os testes alvo antes da publicação.
  if exists (
    select 1
    from private.assessment_test_access_grants g
    join public.assessment_tests t
      on t.id = g.test_id
     and t.organization_id = g.organization_id
     and t.archived_at is null
    where g.organization_id = v_org_id
      and t.sequence_no between 6 and 10
      and g.status = 'active'
      and g.archived_at is null
  ) then
    raise exception 'Publicação VAP 6-10 abortada: existe grant ativo inesperado.';
  end if;

  -- Histórico esperado: somente o Teste 6 possui a tentativa do smoke.
  if (
    select count(*)
    from public.assessment_attempts a
    join public.assessment_tests t
      on t.id = a.test_id
     and t.organization_id = a.organization_id
    where a.organization_id = v_org_id
      and t.sequence_no between 6 and 10
      and a.archived_at is null
  ) <> 1 then
    raise exception 'Publicação VAP 6-10 abortada: histórico de tentativas alvo diferente do esperado.';
  end if;

  if not exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.id = '1b59ead6-5380-41cc-94ea-ee7d0158143e'::uuid
      and a.test_id = '77c2984e-c0e8-5829-94ba-fcb0076ce8b6'::uuid
      and a.test_version_id = '07ed48aa-b1ac-547f-8fa5-a93c1441cc3c'::uuid
      and a.status = 'graded'
      and a.passed is true
      and a.archived_at is null
  ) then
    raise exception 'Publicação VAP 6-10 abortada: tentativa homologada do Teste 6 não localizada.';
  end if;

  -- Regulamentares permanecem intocados em draft 100/100.
  if (
    select count(*)
    from public.assessment_tests t
    join public.assessment_test_versions tv
      on tv.test_id = t.id
     and tv.organization_id = t.organization_id
     and tv.archived_at is null
    where t.organization_id = v_org_id
      and t.sequence_no in (11, 12)
      and t.archived_at is null
      and t.status = 'draft'
      and tv.status = 'draft'
      and tv.passing_score = 100
      and tv.legal_min_score = 100
      and tv.published_at is null
  ) <> 2 then
    raise exception 'Publicação VAP 6-10 abortada: Testes regulamentares 11/12 não estão preservados em draft 100/100.';
  end if;
end
$guard$;

-- Ativa somente os Testes VAP 6 a 10.
update public.assessment_tests
set
  status = 'active',
  metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
    'catalog_homologation_status', 'passed',
    'catalog_publication_status', 'published',
    'catalog_published_on', '2026-08-21',
    'functional_smoke_coverage', 'representative_test_6'
  )
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and sequence_no between 6 and 10
  and status = 'draft'
  and archived_at is null;

-- Publica definitivamente somente as versões VAP 6 a 10.
update public.assessment_test_versions tv
set
  status = 'published',
  valid_from = now(),
  valid_until = null,
  published_at = now(),
  metadata = coalesce(tv.metadata, '{}'::jsonb) || jsonb_build_object(
    'catalog_homologation_status', 'passed',
    'catalog_publication_status', 'published',
    'catalog_publication_type', 'definitive',
    'catalog_published_on', '2026-08-21',
    'functional_smoke_coverage', 'representative_test_6'
  )
from public.assessment_tests t
where t.id = tv.test_id
  and t.organization_id = tv.organization_id
  and t.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and t.sequence_no between 6 and 10
  and t.archived_at is null
  and tv.version_code = '2026.08-v1'
  and tv.status = 'draft'
  and tv.archived_at is null;

do $postcheck$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
  v_actual integer;
begin
  -- Cinco VAP publicados e válidos.
  select count(*)
  into v_actual
  from public.assessment_tests t
  join public.assessment_test_versions tv
    on tv.test_id = t.id
   and tv.organization_id = t.organization_id
   and tv.archived_at is null
  where t.organization_id = v_org_id
    and t.sequence_no between 6 and 10
    and t.archived_at is null
    and t.status = 'active'
    and tv.version_code = '2026.08-v1'
    and tv.status = 'published'
    and tv.valid_from is not null
    and tv.valid_from <= now()
    and tv.valid_until is null
    and tv.published_at is not null
    and tv.metadata ->> 'catalog_homologation_status' = 'passed'
    and tv.metadata ->> 'catalog_publication_status' = 'published'
    and tv.metadata ->> 'catalog_publication_type' = 'definitive';

  if v_actual <> 5 then
    raise exception 'Publicação VAP 6-10 inválida: esperado 5 testes/versões publicados; encontrado %.', v_actual;
  end if;

  -- Cortes continuam exatamente os aprovados.
  if (
    select count(*)
    from public.assessment_tests t
    join public.assessment_test_versions tv
      on tv.test_id = t.id
     and tv.organization_id = t.organization_id
     and tv.archived_at is null
    where t.organization_id = v_org_id
      and (
        (t.sequence_no = 6 and tv.passing_score = 75 and tv.legal_min_score = 80)
        or
        (t.sequence_no = 7 and tv.passing_score = 80 and tv.legal_min_score = 85)
        or
        (t.sequence_no = 8 and tv.passing_score = 80 and tv.legal_min_score = 85)
        or
        (t.sequence_no = 9 and tv.passing_score = 85 and tv.legal_min_score = 90)
        or
        (t.sequence_no = 10 and tv.passing_score = 88 and tv.legal_min_score = 90)
      )
  ) <> 5 then
    raise exception 'Publicação VAP 6-10 inválida: cortes foram alterados.';
  end if;

  -- Publicação não pode criar grants.
  if exists (
    select 1
    from private.assessment_test_access_grants g
    join public.assessment_tests t
      on t.id = g.test_id
     and t.organization_id = g.organization_id
     and t.archived_at is null
    where g.organization_id = v_org_id
      and t.sequence_no between 6 and 10
      and g.status = 'active'
      and g.archived_at is null
  ) then
    raise exception 'Publicação VAP 6-10 inválida: grant ativo foi criado.';
  end if;

  -- O único histórico permanece sendo o smoke aprovado do Teste 6.
  if (
    select count(*)
    from public.assessment_attempts a
    join public.assessment_tests t
      on t.id = a.test_id
     and t.organization_id = a.organization_id
    where a.organization_id = v_org_id
      and t.sequence_no between 6 and 10
      and a.archived_at is null
  ) <> 1 then
    raise exception 'Publicação VAP 6-10 inválida: histórico de tentativas foi alterado.';
  end if;

  if not exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.id = '1b59ead6-5380-41cc-94ea-ee7d0158143e'::uuid
      and a.status = 'graded'
      and a.passed is true
      and a.archived_at is null
  ) then
    raise exception 'Publicação VAP 6-10 inválida: smoke aprovado do Teste 6 foi alterado.';
  end if;

  -- Regulamentares continuam intocados.
  if (
    select count(*)
    from public.assessment_tests t
    join public.assessment_test_versions tv
      on tv.test_id = t.id
     and tv.organization_id = t.organization_id
     and tv.archived_at is null
    where t.organization_id = v_org_id
      and t.sequence_no in (11, 12)
      and t.archived_at is null
      and t.status = 'draft'
      and tv.status = 'draft'
      and tv.passing_score = 100
      and tv.legal_min_score = 100
      and tv.published_at is null
  ) <> 2 then
    raise exception 'Publicação VAP 6-10 inválida: Testes regulamentares 11/12 foram alterados.';
  end if;
end
$postcheck$;

commit;
