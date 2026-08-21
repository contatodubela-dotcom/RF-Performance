-- ============================================================================
-- RF Performance — Avaliações e Certificações
-- Homologação do Catálogo Ampliado — Política de aprovação VAP
-- Fase 4A — Testes 6 a 10
--
-- Política aprovada em 21/08/2026:
--   Teste 6  -> passing_score 75 / legal_min_score 80
--   Teste 7  -> passing_score 80 / legal_min_score 85
--   Teste 8  -> passing_score 80 / legal_min_score 85
--   Teste 9  -> passing_score 85 / legal_min_score 90
--   Teste 10 -> passing_score 88 / legal_min_score 90
--
-- ESCOPO / SEGURANÇA
--   - Altera somente as versões 2026.08-v1 dos Testes VAP 6 a 10.
--   - Mantém testes e versões em draft.
--   - Não publica avaliações.
--   - Não cria grants.
--   - Não cria tentativas.
--   - Não altera questões, alternativas, gabaritos, fontes ou competências.
--   - Não altera Testes 1 a 5.
--   - Não altera avaliações regulamentares Volkswagen e Fiat (Testes 11 e 12).
--   - Exige estado fail-closed 100/100 como precondição.
-- ============================================================================

begin;

do $guard$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
  v_expected integer;
begin
  if not exists (
    select 1
    from public.organizations o
    where o.id = v_org_id
      and o.slug = 'rf-consorcios'
      and o.status = 'active'
      and o.archived_at is null
  ) then
    raise exception 'Política VAP abortada: organização RF esperada não localizada/ativa.';
  end if;

  select count(*)
    into v_expected
  from public.assessment_tests t
  join public.assessment_test_versions tv
    on tv.test_id = t.id
   and tv.organization_id = t.organization_id
   and tv.archived_at is null
  where t.organization_id = v_org_id
    and t.archived_at is null
    and t.sequence_no between 6 and 10
    and t.status = 'draft'
    and tv.version_code = '2026.08-v1'
    and tv.status = 'draft'
    and tv.passing_score = 100
    and tv.legal_min_score = 100
    and tv.question_count = 30
    and (
      (t.sequence_no = 6  and t.code = 'teste_6_vap_fundamentos_mentalidade_valor')
      or
      (t.sequence_no = 7  and t.code = 'teste_7_vap_lideranca_disc')
      or
      (t.sequence_no = 8  and t.code = 'teste_8_vap_neurovendas_copywriting')
      or
      (t.sequence_no = 9  and t.code = 'teste_9_vap_etapas_venda_objecoes')
      or
      (t.sequence_no = 10 and t.code = 'teste_10_vap_ia_vendas_persuasao')
    );

  if v_expected <> 5 then
    raise exception
      'Política VAP abortada: esperado exatamente 5 testes VAP (6..10) em draft, versão 2026.08-v1 e corte fail-closed 100/100; encontrados %.',
      v_expected;
  end if;

  if exists (
    select 1
    from public.assessment_tests t
    join private.assessment_test_access_grants g
      on g.test_id = t.id
     and g.organization_id = t.organization_id
     and g.archived_at is null
    where t.organization_id = v_org_id
      and t.sequence_no between 6 and 10
      and t.archived_at is null
  ) then
    raise exception 'Política VAP abortada: há grant ativo em pelo menos um dos Testes 6 a 10.';
  end if;

  if exists (
    select 1
    from public.assessment_tests t
    join public.assessment_attempts a
      on a.test_id = t.id
     and a.organization_id = t.organization_id
     and a.archived_at is null
    where t.organization_id = v_org_id
      and t.sequence_no between 6 and 10
      and t.archived_at is null
  ) then
    raise exception 'Política VAP abortada: há tentativa existente em pelo menos um dos Testes 6 a 10.';
  end if;

  if (
    select count(*)
    from public.assessment_tests t
    join public.assessment_test_versions tv
      on tv.test_id = t.id
     and tv.organization_id = t.organization_id
     and tv.archived_at is null
    where t.organization_id = v_org_id
      and t.archived_at is null
      and t.sequence_no in (11, 12)
      and t.status = 'draft'
      and tv.status = 'draft'
      and tv.passing_score = 100
      and tv.legal_min_score = 100
  ) <> 2 then
    raise exception 'Política VAP abortada: VW/Fiat (Testes 11 e 12) não estão preservados em draft e 100/100.';
  end if;
end
$guard$;

with policy(sequence_no, test_code, passing_score, legal_min_score) as (
  values
    (6,  'teste_6_vap_fundamentos_mentalidade_valor', 75::numeric, 80::numeric),
    (7,  'teste_7_vap_lideranca_disc',                 80::numeric, 85::numeric),
    (8,  'teste_8_vap_neurovendas_copywriting',       80::numeric, 85::numeric),
    (9,  'teste_9_vap_etapas_venda_objecoes',         85::numeric, 90::numeric),
    (10, 'teste_10_vap_ia_vendas_persuasao',          88::numeric, 90::numeric)
)
update public.assessment_test_versions tv
set
  passing_score = p.passing_score,
  legal_min_score = p.legal_min_score,
  metadata = coalesce(tv.metadata, '{}'::jsonb)
    || jsonb_build_object(
      'approval_policy_defined', true,
      'approval_threshold_placeholder', null,
      'approval_threshold_strategy', 'approved_catalog_policy',
      'homologation_policy_status', 'approved_for_smoke_test',
      'homologation_policy_approved_on', '2026-08-21',
      'approved_passing_score', p.passing_score,
      'approved_legal_min_score', p.legal_min_score
    )
from public.assessment_tests t
join policy p
  on p.sequence_no = t.sequence_no
 and p.test_code = t.code
where tv.test_id = t.id
  and tv.organization_id = t.organization_id
  and t.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and t.archived_at is null
  and tv.archived_at is null
  and t.status = 'draft'
  and tv.status = 'draft'
  and tv.version_code = '2026.08-v1'
  and tv.passing_score = 100
  and tv.legal_min_score = 100;

do $postcheck$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
  v_ok integer;
begin
  select count(*)
    into v_ok
  from public.assessment_tests t
  join public.assessment_test_versions tv
    on tv.test_id = t.id
   and tv.organization_id = t.organization_id
   and tv.archived_at is null
  where t.organization_id = v_org_id
    and t.archived_at is null
    and t.status = 'draft'
    and tv.status = 'draft'
    and tv.version_code = '2026.08-v1'
    and (
      (t.sequence_no = 6
        and t.code = 'teste_6_vap_fundamentos_mentalidade_valor'
        and tv.passing_score = 75
        and tv.legal_min_score = 80)
      or
      (t.sequence_no = 7
        and t.code = 'teste_7_vap_lideranca_disc'
        and tv.passing_score = 80
        and tv.legal_min_score = 85)
      or
      (t.sequence_no = 8
        and t.code = 'teste_8_vap_neurovendas_copywriting'
        and tv.passing_score = 80
        and tv.legal_min_score = 85)
      or
      (t.sequence_no = 9
        and t.code = 'teste_9_vap_etapas_venda_objecoes'
        and tv.passing_score = 85
        and tv.legal_min_score = 90)
      or
      (t.sequence_no = 10
        and t.code = 'teste_10_vap_ia_vendas_persuasao'
        and tv.passing_score = 88
        and tv.legal_min_score = 90)
    )
    and coalesce((tv.metadata ->> 'approval_policy_defined')::boolean, false) = true
    and tv.metadata ->> 'approval_threshold_strategy' = 'approved_catalog_policy'
    and tv.metadata ->> 'homologation_policy_status' = 'approved_for_smoke_test';

  if v_ok <> 5 then
    raise exception 'Política VAP inválida após update: esperado 5 versões com cortes homologados; encontradas %.', v_ok;
  end if;

  if (
    select count(*)
    from public.assessment_tests t
    join public.assessment_test_versions tv
      on tv.test_id = t.id
     and tv.organization_id = t.organization_id
     and tv.archived_at is null
    where t.organization_id = v_org_id
      and t.archived_at is null
      and t.sequence_no in (11, 12)
      and t.status = 'draft'
      and tv.status = 'draft'
      and tv.passing_score = 100
      and tv.legal_min_score = 100
  ) <> 2 then
    raise exception 'Política VAP inválida após update: VW/Fiat deixaram de permanecer draft e 100/100.';
  end if;

  if exists (
    select 1
    from public.assessment_tests t
    join private.assessment_test_access_grants g
      on g.test_id = t.id
     and g.organization_id = t.organization_id
     and g.archived_at is null
    where t.organization_id = v_org_id
      and t.sequence_no between 6 and 12
      and t.archived_at is null
  ) then
    raise exception 'Política VAP inválida após update: grant ativo detectado nos Testes 6 a 12.';
  end if;

  if exists (
    select 1
    from public.assessment_tests t
    join public.assessment_attempts a
      on a.test_id = t.id
     and a.organization_id = t.organization_id
     and a.archived_at is null
    where t.organization_id = v_org_id
      and t.sequence_no between 6 and 12
      and t.archived_at is null
  ) then
    raise exception 'Política VAP inválida após update: tentativa detectada nos Testes 6 a 12.';
  end if;
end
$postcheck$;

commit;
