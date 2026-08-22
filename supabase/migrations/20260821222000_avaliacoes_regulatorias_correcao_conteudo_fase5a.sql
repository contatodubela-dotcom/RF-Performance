-- ============================================================================
-- RF Performance — Avaliações Regulatórias
-- Homologação Regulatória — Fase 5A
-- Correções conteudistas: VW Q20, Fiat Q15 e substituição Fiat Q28
--
-- Objetivo
--   Corrigir três pontos identificados na auditoria contra os regulamentos-fonte:
--
--   1) Volkswagen/CNVW — Questão 20
--      Precisar a faixa de participantes: acima de 100 até 1.000.
--
--   2) Fiat — Questão 15
--      Remover a expressão "antecedência mínima" e aderir ao texto:
--      "com até 8 dias úteis de antecedência".
--
--   3) Fiat — Questão 28
--      Substituir a questão sobre quantidade de parcelas para exclusão, pois o
--      próprio PDF fornecido contém redações conflitantes sobre 2 e 3 parcelas.
--      Nova questão baseada na Cláusula 41.1, regra inequívoca de 10%.
--
-- Segurança
--   - NÃO edita migrations anteriores.
--   - Mantém Testes 11 e 12 e respectivas versões em draft.
--   - NÃO publica avaliações.
--   - NÃO cria grants.
--   - NÃO cria tentativas.
--   - NÃO altera competências, fontes, vínculos, quantidade de questões
--     ou critérios 100/100.
-- ============================================================================

begin;

do $guard$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
begin
  -- --------------------------------------------------------------------------
  -- Estado global dos dois testes regulatórios
  -- --------------------------------------------------------------------------
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.organization_id = t.organization_id
     and v.test_id = t.id
     and v.archived_at is null
    where t.organization_id = v_org_id
      and t.id = 'dd671e5f-39ec-5018-9263-78613361a7db'::uuid
      and t.sequence_no = 11
      and t.code = 'regulamento_vw_cnvw_v1'
      and t.status = 'draft'
      and t.archived_at is null
      and v.id = 'fcf8f979-c44e-5993-beef-d023312ab5b7'::uuid
      and v.version_code = 'cnvw-v2.1-v1'
      and v.status = 'draft'
      and v.passing_score = 100
      and v.legal_min_score = 100
      and v.published_at is null
  ) then
    raise exception 'Correção regulatória abortada: Teste 11 VW não está no estado esperado.';
  end if;

  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.organization_id = t.organization_id
     and v.test_id = t.id
     and v.archived_at is null
    where t.organization_id = v_org_id
      and t.id = '61d013e4-3b4b-5676-b39c-6d340f87b046'::uuid
      and t.sequence_no = 12
      and t.code = 'regulamento_fiat_v1'
      and t.status = 'draft'
      and t.archived_at is null
      and v.id = '74243315-ea1e-5178-83b8-d6077ab9dc59'::uuid
      and v.version_code = 'fiat-v3-v1'
      and v.status = 'draft'
      and v.passing_score = 100
      and v.legal_min_score = 100
      and v.published_at is null
  ) then
    raise exception 'Correção regulatória abortada: Teste 12 Fiat não está no estado esperado.';
  end if;

  if exists (
    select 1
    from private.assessment_test_access_grants g
    where g.organization_id = v_org_id
      and g.test_id in (
        'dd671e5f-39ec-5018-9263-78613361a7db'::uuid,
        '61d013e4-3b4b-5676-b39c-6d340f87b046'::uuid
      )
      and g.status = 'active'
      and g.archived_at is null
  ) then
    raise exception 'Correção regulatória abortada: existe grant ativo nos Testes 11/12.';
  end if;

  if exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.test_id in (
        'dd671e5f-39ec-5018-9263-78613361a7db'::uuid,
        '61d013e4-3b4b-5676-b39c-6d340f87b046'::uuid
      )
      and a.archived_at is null
  ) then
    raise exception 'Correção regulatória abortada: existem tentativas nos Testes 11/12.';
  end if;

  -- --------------------------------------------------------------------------
  -- VW Q20 — guarda exata do conteúdo anterior
  -- --------------------------------------------------------------------------
  if not exists (
    select 1
    from public.assessment_version_questions avq
    join public.assessment_questions q
      on q.organization_id = avq.organization_id
     and q.id = avq.question_id
     and q.archived_at is null
    join private.assessment_question_keys k
      on k.organization_id = q.organization_id
     and k.question_id = q.id
    where avq.organization_id = v_org_id
      and avq.test_version_id = 'fcf8f979-c44e-5993-beef-d023312ab5b7'::uuid
      and avq.sequence_no = 20
      and avq.archived_at is null
      and q.id = '4f2fffcd-aa65-5437-9ef9-28e17eeadae9'::uuid
      and q.status = 'draft'
      and q.prompt =
        'Para grupos com até 1.000 (mil) participantes, segundo a Cláusula 18, Parágrafo Primeiro, "a", quantas centenas são formadas a partir da extração da Loteria Federal para fins de sorteio?'
      and k.correct_option_code = 'C'
      and k.is_critical is false
  ) then
    raise exception 'Correção regulatória abortada: conteúdo anterior de VW Q20 não confere.';
  end if;

  -- --------------------------------------------------------------------------
  -- Fiat Q15 — guarda exata do conteúdo anterior
  -- --------------------------------------------------------------------------
  if not exists (
    select 1
    from public.assessment_version_questions avq
    join public.assessment_questions q
      on q.organization_id = avq.organization_id
     and q.id = avq.question_id
     and q.archived_at is null
    join private.assessment_question_keys k
      on k.organization_id = q.organization_id
     and k.question_id = q.id
    where avq.organization_id = v_org_id
      and avq.test_version_id = '74243315-ea1e-5178-83b8-d6077ab9dc59'::uuid
      and avq.sequence_no = 15
      and avq.archived_at is null
      and q.id = '8e5638d3-b0a9-566d-8661-c969ceac8b09'::uuid
      and q.status = 'draft'
      and q.prompt =
        'A convocação da Assembleia Geral Extraordinária pela Administradora deve ser efetuada com qual antecedência mínima?'
      and k.correct_option_code = 'C'
      and k.is_critical is false
  ) then
    raise exception 'Correção regulatória abortada: conteúdo anterior de Fiat Q15 não confere.';
  end if;

  -- --------------------------------------------------------------------------
  -- Fiat Q28 — guarda exata do conteúdo anterior + alternativas
  -- --------------------------------------------------------------------------
  if not exists (
    select 1
    from public.assessment_version_questions avq
    join public.assessment_questions q
      on q.organization_id = avq.organization_id
     and q.id = avq.question_id
     and q.archived_at is null
    join private.assessment_question_keys k
      on k.organization_id = q.organization_id
     and k.question_id = q.id
    where avq.organization_id = v_org_id
      and avq.test_version_id = '74243315-ea1e-5178-83b8-d6077ab9dc59'::uuid
      and avq.sequence_no = 28
      and avq.archived_at is null
      and q.id = 'ab0550ec-263b-526e-8808-75fa558d2546'::uuid
      and q.status = 'draft'
      and q.prompt =
        'O consorciado não contemplado que deixar de realizar suas contribuições mensais por quantas vezes, consecutivas ou alternadas, será excluído do grupo, independentemente de aviso ou notificação?'
      and k.correct_option_code = 'B'
      and k.is_critical is false
  ) then
    raise exception 'Correção regulatória abortada: conteúdo anterior de Fiat Q28 não confere.';
  end if;

  if (
    select count(*)
    from public.assessment_question_options o
    where o.organization_id = v_org_id
      and o.question_id = 'ab0550ec-263b-526e-8808-75fa558d2546'::uuid
      and o.archived_at is null
      and (
        (o.option_code = 'A' and o.option_text = '2 (duas) vezes')
        or (o.option_code = 'B' and o.option_text = '3 (três) vezes')
        or (o.option_code = 'C' and o.option_text = '4 (quatro) vezes')
        or (o.option_code = 'D' and o.option_text = '5 (cinco) vezes')
      )
  ) <> 4 then
    raise exception 'Correção regulatória abortada: alternativas anteriores de Fiat Q28 não conferem.';
  end if;
end
$guard$;

-- ============================================================================
-- 1) Volkswagen/CNVW — Q20
-- ============================================================================

update public.assessment_questions
set prompt =
  'Para grupos acima de 100 (cem) e até 1.000 (mil) participantes, segundo a Cláusula 18, Parágrafo Primeiro, "a", quantas centenas são formadas a partir da extração da Loteria Federal para fins de sorteio?'
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and id = '4f2fffcd-aa65-5437-9ef9-28e17eeadae9'::uuid
  and status = 'draft'
  and archived_at is null;

update private.assessment_question_keys
set
  justification =
    'Conforme a Cláusula 18, Parágrafo Primeiro, "a": para grupos acima de 100 e até 1.000 participantes, são formadas 3 centenas para cada um dos 5 prêmios da Loteria Federal, totalizando 15 centenas.',
  source_reference =
    'Regulamento CNVW/Embracon — Versão 2.1 — Cláusula 18, Parágrafo Primeiro, alínea "a"'
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and question_id = '4f2fffcd-aa65-5437-9ef9-28e17eeadae9'::uuid;

-- ============================================================================
-- 2) Fiat — Q15
-- ============================================================================

update public.assessment_questions
set prompt =
  'Segundo a Cláusula 14, Parágrafo Quinto, a convocação da Assembleia Geral Extraordinária pela Administradora será efetuada com até quantos dias úteis de antecedência de sua realização?'
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and id = '8e5638d3-b0a9-566d-8661-c969ceac8b09'::uuid
  and status = 'draft'
  and archived_at is null;

update private.assessment_question_keys
set
  justification =
    'A Cláusula 14, Parágrafo Quinto, estabelece que a convocação da Assembleia Geral Extraordinária pela Administradora será efetuada com até 8 (oito) dias úteis de antecedência de sua realização.',
  source_reference =
    'Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 14, Parágrafo Quinto'
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and question_id = '8e5638d3-b0a9-566d-8661-c969ceac8b09'::uuid;

-- ============================================================================
-- 3) Fiat — Q28
-- Substituição integral por regra inequívoca da Cláusula 41.1
-- ============================================================================

update public.assessment_questions
set prompt =
  'Segundo a Cláusula 41.1, qual percentual é deduzido do valor integralizado pelo consorciado excluído, a título de prejuízos causados ao grupo de consórcio?'
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and id = 'ab0550ec-263b-526e-8808-75fa558d2546'::uuid
  and status = 'draft'
  and archived_at is null;

update public.assessment_question_options
set option_text = case option_code
  when 'A' then '5% (cinco por cento)'
  when 'B' then '10% (dez por cento)'
  when 'C' then '15% (quinze por cento)'
  when 'D' then '20% (vinte por cento)'
  else option_text
end
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and question_id = 'ab0550ec-263b-526e-8808-75fa558d2546'::uuid
  and option_code in ('A', 'B', 'C', 'D')
  and archived_at is null;

update private.assessment_question_keys
set
  correct_option_code = 'B',
  justification =
    'A Cláusula 41.1 estabelece a dedução de 10% (dez por cento) sobre o valor até então integralizado, atualizado na forma da Cláusula 40, a título de prejuízos causados ao grupo de consórcio.',
  source_reference =
    'Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 41.1'
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and question_id = 'ab0550ec-263b-526e-8808-75fa558d2546'::uuid;

-- ============================================================================
-- Postcheck
-- ============================================================================

do $postcheck$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
begin
  -- VW Q20 corrigida
  if not exists (
    select 1
    from public.assessment_questions q
    join private.assessment_question_keys k
      on k.organization_id = q.organization_id
     and k.question_id = q.id
    where q.organization_id = v_org_id
      and q.id = '4f2fffcd-aa65-5437-9ef9-28e17eeadae9'::uuid
      and q.status = 'draft'
      and q.prompt =
        'Para grupos acima de 100 (cem) e até 1.000 (mil) participantes, segundo a Cláusula 18, Parágrafo Primeiro, "a", quantas centenas são formadas a partir da extração da Loteria Federal para fins de sorteio?'
      and k.correct_option_code = 'C'
      and k.source_reference =
        'Regulamento CNVW/Embracon — Versão 2.1 — Cláusula 18, Parágrafo Primeiro, alínea "a"'
      and k.is_critical is false
  ) then
    raise exception 'Postcheck falhou: VW Q20 não ficou conforme esperado.';
  end if;

  -- Fiat Q15 corrigida
  if not exists (
    select 1
    from public.assessment_questions q
    join private.assessment_question_keys k
      on k.organization_id = q.organization_id
     and k.question_id = q.id
    where q.organization_id = v_org_id
      and q.id = '8e5638d3-b0a9-566d-8661-c969ceac8b09'::uuid
      and q.status = 'draft'
      and q.prompt =
        'Segundo a Cláusula 14, Parágrafo Quinto, a convocação da Assembleia Geral Extraordinária pela Administradora será efetuada com até quantos dias úteis de antecedência de sua realização?'
      and k.correct_option_code = 'C'
      and k.source_reference =
        'Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 14, Parágrafo Quinto'
      and k.is_critical is false
  ) then
    raise exception 'Postcheck falhou: Fiat Q15 não ficou conforme esperado.';
  end if;

  -- Fiat Q28 substituída
  if not exists (
    select 1
    from public.assessment_questions q
    join private.assessment_question_keys k
      on k.organization_id = q.organization_id
     and k.question_id = q.id
    where q.organization_id = v_org_id
      and q.id = 'ab0550ec-263b-526e-8808-75fa558d2546'::uuid
      and q.status = 'draft'
      and q.prompt =
        'Segundo a Cláusula 41.1, qual percentual é deduzido do valor integralizado pelo consorciado excluído, a título de prejuízos causados ao grupo de consórcio?'
      and k.correct_option_code = 'B'
      and k.source_reference =
        'Regulamento do Contrato de Consórcio Fiat/Embracon — Versão 3 — Cláusula 41.1'
      and k.is_critical is false
  ) then
    raise exception 'Postcheck falhou: Fiat Q28 não ficou conforme esperado.';
  end if;

  if (
    select count(*)
    from public.assessment_question_options o
    where o.organization_id = v_org_id
      and o.question_id = 'ab0550ec-263b-526e-8808-75fa558d2546'::uuid
      and o.archived_at is null
      and (
        (o.option_code = 'A' and o.option_text = '5% (cinco por cento)')
        or (o.option_code = 'B' and o.option_text = '10% (dez por cento)')
        or (o.option_code = 'C' and o.option_text = '15% (quinze por cento)')
        or (o.option_code = 'D' and o.option_text = '20% (vinte por cento)')
      )
  ) <> 4 then
    raise exception 'Postcheck falhou: alternativas da nova Fiat Q28 não conferem.';
  end if;

  -- Estrutura dos dois testes permanece intacta
  if (
    select count(*)
    from public.assessment_version_questions avq
    where avq.organization_id = v_org_id
      and avq.test_version_id = 'fcf8f979-c44e-5993-beef-d023312ab5b7'::uuid
      and avq.archived_at is null
  ) <> 30 then
    raise exception 'Postcheck falhou: Teste 11 não possui 30 questões vinculadas.';
  end if;

  if (
    select count(*)
    from public.assessment_version_questions avq
    where avq.organization_id = v_org_id
      and avq.test_version_id = '74243315-ea1e-5178-83b8-d6077ab9dc59'::uuid
      and avq.archived_at is null
  ) <> 30 then
    raise exception 'Postcheck falhou: Teste 12 não possui 30 questões vinculadas.';
  end if;

  -- Ambos seguem draft 100/100, sem grants e sem tentativas
  if (
    select count(*)
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.organization_id = t.organization_id
     and v.test_id = t.id
     and v.archived_at is null
    where t.organization_id = v_org_id
      and t.sequence_no in (11, 12)
      and t.status = 'draft'
      and t.archived_at is null
      and v.status = 'draft'
      and v.passing_score = 100
      and v.legal_min_score = 100
      and v.published_at is null
  ) <> 2 then
    raise exception 'Postcheck falhou: Testes 11/12 não permaneceram em draft 100/100.';
  end if;

  if exists (
    select 1
    from private.assessment_test_access_grants g
    where g.organization_id = v_org_id
      and g.test_id in (
        'dd671e5f-39ec-5018-9263-78613361a7db'::uuid,
        '61d013e4-3b4b-5676-b39c-6d340f87b046'::uuid
      )
      and g.status = 'active'
      and g.archived_at is null
  ) then
    raise exception 'Postcheck falhou: grant ativo apareceu nos Testes 11/12.';
  end if;

  if exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.test_id in (
        'dd671e5f-39ec-5018-9263-78613361a7db'::uuid,
        '61d013e4-3b4b-5676-b39c-6d340f87b046'::uuid
      )
      and a.archived_at is null
  ) then
    raise exception 'Postcheck falhou: tentativa apareceu nos Testes 11/12.';
  end if;
end
$postcheck$;

commit;
