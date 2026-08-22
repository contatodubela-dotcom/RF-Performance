-- ============================================================================
-- RF Performance — Avaliações e Certificações
-- Fase 5C — Reconciliação regulatória CNVW / Volkswagen com fonte oficial V3.0
--
-- Fonte oficial atual verificada em 21/08/2026:
--   Regulamento do Contrato de Consórcio — CNVW com Embracon
--   Versão 3.0 — Resolução 285 — C.E. 07/24
--   Endpoint oficial Embracon:
--   https://api.embraconnet.com.br/newcon_wbs/eb/documento-venda/R0d2VTZOeTljVHRUVHArZWdSTHo1QT09
--   SHA-256 dos bytes obtidos em duas leituras idênticas:
--   530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09
--
-- Objetivos:
--   - manter Teste 11 e sua versão em draft;
--   - preservar a versão normativa V2.1 já cadastrada como histórico;
--   - tornar o source_material genérico e cadastrar a V3.0 como nova versão;
--   - reatar a versão do Teste 11 à fonte V3.0;
--   - reconciliar metadados das 30 questões/8 competências com a V3.0;
--   - substituir Q2 e Q23, removendo conteúdo afetado por inconsistência/desatualização;
--   - Q2 passa a tratar do cômputo cumulativo de cotas de cônjuge/companheiro
--     (Cláusula 11, Parágrafo Sétimo);
--   - Q23 passa a tratar da análise da capacidade de pagamento do cessionário
--     antes da transferência (Cláusula 37, Parágrafo Sétimo);
--   - não criar grants, tentativas ou publicação.
--
-- IMPORTANTE
--   - Esta migration NÃO altera a migration Fase 3A já aplicada.
--   - Esta migration NÃO altera o Teste 12 Fiat.
-- ============================================================================

begin;

-- --------------------------------------------------------------------------
-- 0. Guardas fail-closed — estado exato observado no preflight da Fase 5C
-- --------------------------------------------------------------------------
do $guard$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
  v_test_id uuid := 'dd671e5f-39ec-5018-9263-78613361a7db'::uuid;
  v_version_id uuid := 'fcf8f979-c44e-5993-beef-d023312ab5b7'::uuid;
  v_source_material_id uuid := '89fb9a5e-d493-5280-814d-abc03eaa05c9'::uuid;
  v_source_v21_id uuid := '2bffe092-f163-53c5-846d-284567e62595'::uuid;
  v_source_v30_id uuid := 'aca73af3-6ded-5461-88c9-acbd17064862'::uuid;
  v_link_id uuid := '6a4dc110-1bc3-5d7b-a545-6397df9fb6b2'::uuid;
  v_q2 uuid := '2e6d2845-4e97-544f-8002-f0e506ad6b4a'::uuid;
  v_q23 uuid := 'f4a51cc5-b355-515c-a6d1-5b33c0ca2dce'::uuid;
begin
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.organization_id = t.organization_id
     and v.test_id = t.id
     and v.id = v_version_id
     and v.archived_at is null
    where t.organization_id = v_org_id
      and t.id = v_test_id
      and t.sequence_no = 11
      and t.code = 'regulamento_vw_cnvw_v1'
      and t.status = 'draft'
      and t.archived_at is null
      and v.version_code = 'cnvw-v2.1-v1'
      and v.version_no = 1
      and v.status = 'draft'
      and v.passing_score = 100
      and v.legal_min_score = 100
      and v.published_at is null
  ) then
    raise exception 'Fase 5C abortada: Teste 11 / versão CNVW V2.1 não está no estado draft esperado.';
  end if;

  if exists (
    select 1
    from private.assessment_test_access_grants g
    where g.organization_id = v_org_id
      and g.test_id = v_test_id
      and g.status = 'active'
      and g.archived_at is null
  ) then
    raise exception 'Fase 5C abortada: Teste 11 possui grant ativo.';
  end if;

  if exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.test_id = v_test_id
      and a.archived_at is null
  ) then
    raise exception 'Fase 5C abortada: Teste 11 possui tentativa; reconciliação in-place não é permitida.';
  end if;

  if not exists (
    select 1
    from public.source_materials sm
    where sm.organization_id = v_org_id
      and sm.id = v_source_material_id
      and sm.code = 'regulamento_cnvw_embracon_v2_1'
      and sm.status = 'active'
      and sm.archived_at is null
      and sm.metadata->>'document_version' = '2.1'
      and lower(sm.metadata->>'content_sha256') =
          'a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a'
  ) then
    raise exception 'Fase 5C abortada: source_material CNVW V2.1 não corresponde ao preflight.';
  end if;

  if exists (
    select 1
    from public.source_materials sm
    where sm.organization_id = v_org_id
      and sm.code = 'regulamento_cnvw_embracon'
      and sm.id <> v_source_material_id
      and sm.archived_at is null
  ) then
    raise exception 'Fase 5C abortada: já existe outro source_material com o código canônico pretendido.';
  end if;

  if not exists (
    select 1
    from public.source_material_versions smv
    where smv.organization_id = v_org_id
      and smv.id = v_source_v21_id
      and smv.source_material_id = v_source_material_id
      and smv.version_code = 'v2.1-circular3432-res285-23'
      and smv.version_no = 1
      and lower(smv.content_sha256) =
          'a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a'
      and smv.archived_at is null
  ) then
    raise exception 'Fase 5C abortada: versão histórica normativa V2.1 não está íntegra.';
  end if;

  if exists (
    select 1
    from public.source_material_versions smv
    where smv.organization_id = v_org_id
      and smv.archived_at is null
      and (
        smv.id = v_source_v30_id
        or lower(smv.content_sha256) =
           '530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09'
      )
  ) then
    raise exception 'Fase 5C abortada: fonte CNVW V3.0 já está cadastrada.';
  end if;

  if not exists (
    select 1
    from public.assessment_version_sources avs
    where avs.organization_id = v_org_id
      and avs.id = v_link_id
      and avs.test_version_id = v_version_id
      and avs.source_material_version_id = v_source_v21_id
      and avs.relation_type = 'primary'
      and avs.is_required = true
      and avs.archived_at is null
  ) then
    raise exception 'Fase 5C abortada: vínculo primário Teste 11 -> fonte V2.1 divergiu do preflight.';
  end if;

  if not exists (
    select 1
    from public.assessment_questions q
    join private.assessment_question_keys k
      on k.organization_id = q.organization_id
     and k.question_id = q.id
    where q.organization_id = v_org_id
      and q.id = v_q2
      and q.code = 'reg_vw_cnvw_q02'
      and q.status = 'draft'
      and q.competency_id = 'dfb721a3-7005-591e-af41-655027fa487b'::uuid
      and q.block_code = 'definicoes_adesao'
      and q.prompt = 'De acordo com a definição de "CONSORCIADO EXCLUÍDO", esse status ocorre quando o participante deixa de pagar quantas parcelas de forma alternada ou sucessiva?'
      and k.correct_option_code = 'B'
      and k.justification = 'A definição de CONSORCIADO EXCLUÍDO menciona a exclusão "por desistência declarada, ou ainda por deixar de pagar duas parcelas de forma alternada ou sucessiva".'
      and q.archived_at is null
  ) then
    raise exception 'Fase 5C abortada: Q2 divergiu do estado observado no preflight.';
  end if;

  if (
    select jsonb_agg(
      jsonb_build_object('code', x.option_code, 'text', x.option_text)
      order by x.option_code
    )
    from (
      select o.option_code, o.option_text
      from public.assessment_question_options o
      where o.organization_id = v_org_id
        and o.question_id = v_q2
        and o.archived_at is null
    ) x
  ) <> '[{"code":"A","text":"1 (uma) parcela"},{"code":"B","text":"2 (duas) parcelas"},{"code":"C","text":"3 (três) parcelas"},{"code":"D","text":"4 (quatro) parcelas"}]'::jsonb then
    raise exception 'Fase 5C abortada: alternativas atuais da Q2 divergiram do preflight.';
  end if;

  if not exists (
    select 1
    from public.assessment_questions q
    join private.assessment_question_keys k
      on k.organization_id = q.organization_id
     and k.question_id = q.id
    where q.organization_id = v_org_id
      and q.id = v_q23
      and q.code = 'reg_vw_cnvw_q23'
      and q.status = 'draft'
      and q.competency_id = '976964de-40bf-5860-a663-93737500b1e5'::uuid
      and q.block_code = 'contemplacao_lances'
      and q.prompt = 'Sobre o CANCELAMENTO DA CONTEMPLAÇÃO (Cláusula 18, Parágrafo Onze), a contemplação do CONSORCIADO ATIVO que não utilizou o crédito será cancelada após deixar de pagar quantas contribuições mensais, sucessivas ou alternadas?'
      and k.correct_option_code = 'B'
      and k.justification = 'Conforme a Cláusula 18, Parágrafo Onze, a contemplação é cancelada após deixar de pagar 2 (duas) contribuições mensais, sucessivas ou alternadas.'
      and q.archived_at is null
  ) then
    raise exception 'Fase 5C abortada: Q23 divergiu do estado observado no preflight.';
  end if;

  if (
    select jsonb_agg(
      jsonb_build_object('code', x.option_code, 'text', x.option_text)
      order by x.option_code
    )
    from (
      select o.option_code, o.option_text
      from public.assessment_question_options o
      where o.organization_id = v_org_id
        and o.question_id = v_q23
        and o.archived_at is null
    ) x
  ) <> '[{"code":"A","text":"1 (uma)"},{"code":"B","text":"2 (duas)"},{"code":"C","text":"3 (três)"},{"code":"D","text":"4 (quatro)"}]'::jsonb then
    raise exception 'Fase 5C abortada: alternativas atuais da Q23 divergiram do preflight.';
  end if;
end
$guard$;

-- --------------------------------------------------------------------------
-- 1. Normaliza a identidade do material e preserva a V2.1 como versão histórica
-- --------------------------------------------------------------------------
update public.source_materials
set
  code = 'regulamento_cnvw_embracon',
  description = 'Regulamento do Contrato de Consórcio do Consórcio Nacional Volkswagen, com prestação de serviços de administração pela Embracon. As edições do documento são controladas em source_material_versions.',
  metadata =
    (
      coalesce(metadata, '{}'::jsonb)
      - 'document_version'
      - 'content_sha256'
      - 'source_filename'
      - 'external_currency_verified'
    )
    || jsonb_build_object(
      'catalog_family', 'regulatory',
      'administrator', 'CNVW',
      'service_provider', 'Embracon',
      'canonical_material_code', 'regulamento_cnvw_embracon',
      'legacy_material_code', 'regulamento_cnvw_embracon_v2_1',
      'current_document_version', '3.0',
      'current_content_sha256', '530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09',
      'external_currency_verified', true,
      'external_currency_verified_on', '2026-08-21',
      'official_source_url', 'https://api.embraconnet.com.br/newcon_wbs/eb/documento-venda/R0d2VTZOeTljVHRUVHArZWdSTHo1QT09',
      'normative_references', jsonb_build_array(
        'Resolução 285/23 do Banco Central do Brasil'
      )
    )
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and id = '89fb9a5e-d493-5280-814d-abc03eaa05c9'::uuid
  and archived_at is null;

insert into public.source_material_versions (
  id, organization_id, source_material_id, version_code, version_no,
  status, effective_from, effective_until, published_at, source_date,
  content_sha256, source_locator, metadata
)
values (
  'aca73af3-6ded-5461-88c9-acbd17064862'::uuid,
  '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
  '89fb9a5e-d493-5280-814d-abc03eaa05c9'::uuid,
  'v3.0-res285-23',
  2,
  'active',
  null,
  null,
  null,
  null,
  '530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09',
  jsonb_build_object(
    'document_version', '3.0',
    'resolution', '285/23',
    'commercial_edition', '07/24',
    'source_url', 'https://api.embraconnet.com.br/newcon_wbs/eb/documento-venda/R0d2VTZOeTljVHRUVHArZWdSTHo1QT09',
    'retrieved_on', '2026-08-21'
  ),
  jsonb_build_object(
    'catalog_family', 'regulatory',
    'administrator', 'CNVW',
    'service_provider', 'Embracon',
    'source_content_sha256', '530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09',
    'version_identity_basis', 'official_document_version_and_sha256',
    'external_currency_verified', true,
    'external_currency_verified_on', '2026-08-21',
    'verification_basis', 'official_embracon_endpoint'
  )
);

-- --------------------------------------------------------------------------
-- 2. Reata o Teste 11 à fonte V3.0
-- --------------------------------------------------------------------------
update public.assessment_version_sources
set
  source_material_version_id = 'aca73af3-6ded-5461-88c9-acbd17064862'::uuid,
  notes = 'Fonte normativa primária da Avaliação Regulamentar — Consórcio Volkswagen, reconciliada com a Versão 3.0 oficial.',
  metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
    'catalog_family', 'regulatory',
    'administrator', 'CNVW',
    'source_document_version', '3.0',
    'source_content_sha256', '530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09',
    'external_currency_verified', true,
    'external_currency_verified_on', '2026-08-21',
    'reconciliation_phase', 'fase5c',
    'previous_source_material_version_id', '2bffe092-f163-53c5-846d-284567e62595'
  )
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and id = '6a4dc110-1bc3-5d7b-a545-6397df9fb6b2'::uuid
  and test_version_id = 'fcf8f979-c44e-5993-beef-d023312ab5b7'::uuid
  and archived_at is null;

-- --------------------------------------------------------------------------
-- 3. Atualiza a identidade da versão de avaliação enquanto ainda é draft
-- --------------------------------------------------------------------------
update public.assessment_test_versions
set
  version_code = 'cnvw-v3.0-v1',
  normative_basis = jsonb_build_array(
    jsonb_build_object(
      'instrument', 'Regulamento do Contrato de Consórcio CNVW/Embracon',
      'version', '3.0',
      'references', jsonb_build_array('Resolução 285/23')
    )
  ),
  metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
    'catalog_family', 'regulatory',
    'administrator', 'CNVW',
    'source_material_code', 'regulamento_cnvw_embracon',
    'source_material_version_id', 'aca73af3-6ded-5461-88c9-acbd17064862',
    'source_document_version', '3.0',
    'source_content_sha256', '530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09',
    'external_currency_verified', true,
    'external_currency_verified_on', '2026-08-21',
    'official_source_url', 'https://api.embraconnet.com.br/newcon_wbs/eb/documento-venda/R0d2VTZOeTljVHRUVHArZWdSTHo1QT09',
    'reconciliation_phase', 'fase5c',
    'previous_version_code', 'cnvw-v2.1-v1',
    'homologation_status', 'draft_catalog'
  )
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and id = 'fcf8f979-c44e-5993-beef-d023312ab5b7'::uuid
  and test_id = 'dd671e5f-39ec-5018-9263-78613361a7db'::uuid
  and archived_at is null;

update public.assessment_tests
set
  metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
    'assessment_version_label', 'CNVW v3.0 — avaliação v1',
    'source_material_code', 'regulamento_cnvw_embracon',
    'source_document_version', '3.0',
    'source_content_sha256', '530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09',
    'external_currency_verified', true,
    'external_currency_verified_on', '2026-08-21',
    'reconciliation_phase', 'fase5c',
    'declared_distribution',
      '{"definicoes_adesao":3,"planos":3,"contribuicoes_taxas":5,"constituicao_grupo":4,"assembleias":3,"contemplacao_lances":6,"credito_garantias":2,"cessao_exclusao_prescricao":4}'::jsonb
  )
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and id = 'dd671e5f-39ec-5018-9263-78613361a7db'::uuid
  and archived_at is null;

-- --------------------------------------------------------------------------
-- 4. Reconcilição de metadados das 8 competências e das 30 questões
-- --------------------------------------------------------------------------
update public.competency_domains c
set metadata = coalesce(c.metadata, '{}'::jsonb) || jsonb_build_object(
  'source_material_code', 'regulamento_cnvw_embracon',
  'source_document_version', '3.0',
  'source_content_sha256', '530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09',
  'external_currency_verified', true,
  'external_currency_verified_on', '2026-08-21',
  'reconciliation_phase', 'fase5c'
)
where c.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and c.code in (
    'reg_vw_definicoes_adesao',
    'reg_vw_planos',
    'reg_vw_contribuicoes_taxas',
    'reg_vw_constituicao_grupo',
    'reg_vw_assembleias',
    'reg_vw_contemplacao_lances',
    'reg_vw_credito_garantias',
    'reg_vw_cessao_exclusao_prescricao'
  )
  and c.archived_at is null;

update public.assessment_questions q
set
  content_version = 'cnvw-v3.0-v1',
  metadata = coalesce(q.metadata, '{}'::jsonb) || jsonb_build_object(
    'source_material_code', 'regulamento_cnvw_embracon',
    'source_document_version', '3.0',
    'source_content_sha256', '530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09',
    'external_currency_verified', true,
    'external_currency_verified_on', '2026-08-21',
    'reconciliation_phase', 'fase5c',
    'reconciled_against_current_source', true
  )
where q.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and q.archived_at is null
  and exists (
    select 1
    from public.assessment_version_questions avq
    where avq.organization_id = q.organization_id
      and avq.test_version_id = 'fcf8f979-c44e-5993-beef-d023312ab5b7'::uuid
      and avq.question_id = q.id
      and avq.archived_at is null
  );

update private.assessment_question_keys k
set metadata = coalesce(k.metadata, '{}'::jsonb) || jsonb_build_object(
  'source_document_version', '3.0',
  'source_content_sha256', '530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09',
  'external_currency_verified', true,
  'external_currency_verified_on', '2026-08-21',
  'reconciliation_phase', 'fase5c',
  'reconciled_against_current_source', true
)
where k.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and exists (
    select 1
    from public.assessment_version_questions avq
    where avq.organization_id = k.organization_id
      and avq.test_version_id = 'fcf8f979-c44e-5993-beef-d023312ab5b7'::uuid
      and avq.question_id = k.question_id
      and avq.archived_at is null
  );

-- --------------------------------------------------------------------------
-- 5. Substitui Q2 — Cláusula 11, Parágrafo Sétimo
-- --------------------------------------------------------------------------
update public.assessment_questions
set
  competency_id = '9c4fdbc5-ed84-5b2f-ba18-0ba6f03b1330'::uuid,
  block_code = 'constituicao_grupo',
  prompt = 'Segundo a Cláusula 11, Parágrafo Sétimo, para o cálculo do limite máximo de cotas que um CONSORCIADO pode adquirir em um mesmo grupo, como devem ser consideradas as cotas adquiridas por seu cônjuge ou companheiro?',
  metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
    'replacement_question', true,
    'replacement_reason', 'substitui_item_baseado_em_trecho_internamente_inconsistente_da_fonte',
    'replacement_source_reference', 'Cláusula 11, Parágrafo Sétimo',
    'previous_competency_id', 'dfb721a3-7005-591e-af41-655027fa487b',
    'previous_block_code', 'definicoes_adesao'
  )
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and id = '2e6d2845-4e97-544f-8002-f0e506ad6b4a'::uuid
  and archived_at is null;

update public.assessment_question_options
set option_text = case option_code
  when 'A' then 'Devem ser desconsideradas, pois possuem titularidade distinta.'
  when 'B' then 'Devem ser consideradas apenas quando houver coobrigação financeira entre os titulares.'
  when 'C' then 'Devem ser consideradas cumulativamente para o cálculo do percentual máximo permitido.'
  when 'D' then 'Devem ser consideradas somente depois da contemplação de uma das cotas.'
end
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and question_id = '2e6d2845-4e97-544f-8002-f0e506ad6b4a'::uuid
  and option_code in ('A','B','C','D')
  and archived_at is null;

update private.assessment_question_keys
set
  correct_option_code = 'C',
  justification = 'A Cláusula 11, Parágrafo Sétimo, estabelece que o percentual máximo permitido deve ser calculado considerando cumulativamente as cotas adquiridas pelo cônjuge ou companheiro do CONSORCIADO.',
  source_reference = 'Regulamento CNVW/Embracon — Versão 3.0 — Cláusula 11, Parágrafo Sétimo',
  metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
    'replacement_question', true,
    'replacement_source_reference', 'Cláusula 11, Parágrafo Sétimo'
  )
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and question_id = '2e6d2845-4e97-544f-8002-f0e506ad6b4a'::uuid;

-- --------------------------------------------------------------------------
-- 6. Substitui Q23 — Cláusula 37, Parágrafo Sétimo
-- --------------------------------------------------------------------------
update public.assessment_questions
set
  competency_id = '9527c059-e9b5-53c7-a6dd-bc73aaf38a47'::uuid,
  block_code = 'cessao_exclusao_prescricao',
  prompt = 'Segundo a Cláusula 37, Parágrafo Sétimo, antes da efetivação da transferência de uma cota, qual procedimento a ADMINISTRADORA deve realizar em relação ao CESSIONÁRIO?',
  metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
    'replacement_question', true,
    'replacement_reason', 'substitui_item_desatualizado_da_versao_2_1',
    'replacement_source_reference', 'Cláusula 37, Parágrafo Sétimo',
    'previous_competency_id', '976964de-40bf-5860-a663-93737500b1e5',
    'previous_block_code', 'contemplacao_lances'
  )
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and id = 'f4a51cc5-b355-515c-a6d1-5b33c0ca2dce'::uuid
  and archived_at is null;

update public.assessment_question_options
set option_text = case option_code
  when 'A' then 'Aprovar automaticamente a transferência quando a taxa correspondente estiver paga.'
  when 'B' then 'Analisar a capacidade de pagamento do CESSIONÁRIO, incluindo comprovação de renda e condições de crédito.'
  when 'C' then 'Exigir somente a autorização do CONSORCIADO cedente, sem análise do novo titular.'
  when 'D' then 'Dispensar a análise financeira sempre que a cota ainda não tiver sido contemplada.'
end
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and question_id = 'f4a51cc5-b355-515c-a6d1-5b33c0ca2dce'::uuid
  and option_code in ('A','B','C','D')
  and archived_at is null;

update private.assessment_question_keys
set
  correct_option_code = 'B',
  justification = 'A Cláusula 37, Parágrafo Sétimo, determina que, antes da transferência, a ADMINISTRADORA analise a capacidade de pagamento do CESSIONÁRIO, com comprovação de renda/remuneração e verificação das condições de crédito.',
  source_reference = 'Regulamento CNVW/Embracon — Versão 3.0 — Cláusula 37, Parágrafo Sétimo',
  metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
    'replacement_question', true,
    'replacement_source_reference', 'Cláusula 37, Parágrafo Sétimo'
  )
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and question_id = 'f4a51cc5-b355-515c-a6d1-5b33c0ca2dce'::uuid;

-- --------------------------------------------------------------------------
-- 7. Pós-condições
-- --------------------------------------------------------------------------
do $post$
declare
  v_org_id uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
  v_test_id uuid := 'dd671e5f-39ec-5018-9263-78613361a7db'::uuid;
  v_version_id uuid := 'fcf8f979-c44e-5993-beef-d023312ab5b7'::uuid;
  v_source_material_id uuid := '89fb9a5e-d493-5280-814d-abc03eaa05c9'::uuid;
  v_source_v21_id uuid := '2bffe092-f163-53c5-846d-284567e62595'::uuid;
  v_source_v30_id uuid := 'aca73af3-6ded-5461-88c9-acbd17064862'::uuid;
begin
  if not exists (
    select 1
    from public.source_materials sm
    where sm.organization_id = v_org_id
      and sm.id = v_source_material_id
      and sm.code = 'regulamento_cnvw_embracon'
      and sm.status = 'active'
      and sm.metadata->>'current_document_version' = '3.0'
      and lower(sm.metadata->>'current_content_sha256') =
          '530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09'
      and sm.archived_at is null
  ) then
    raise exception 'Fase 5C pós-condição: source_material canônico não confere.';
  end if;

  if not exists (
    select 1
    from public.source_material_versions smv
    where smv.organization_id = v_org_id
      and smv.id = v_source_v21_id
      and smv.source_material_id = v_source_material_id
      and smv.version_code = 'v2.1-circular3432-res285-23'
      and smv.version_no = 1
      and lower(smv.content_sha256) =
          'a76ffe2e35bc74e937de07128516389e8aa0261ec617e8639d25f2fa504d9c5a'
      and smv.archived_at is null
  ) then
    raise exception 'Fase 5C pós-condição: histórico V2.1 foi alterado indevidamente.';
  end if;

  if not exists (
    select 1
    from public.source_material_versions smv
    where smv.organization_id = v_org_id
      and smv.id = v_source_v30_id
      and smv.source_material_id = v_source_material_id
      and smv.version_code = 'v3.0-res285-23'
      and smv.version_no = 2
      and smv.status = 'active'
      and lower(smv.content_sha256) =
          '530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09'
      and smv.archived_at is null
  ) then
    raise exception 'Fase 5C pós-condição: versão normativa V3.0 não confere.';
  end if;

  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.organization_id = t.organization_id
     and v.test_id = t.id
     and v.id = v_version_id
     and v.archived_at is null
    where t.organization_id = v_org_id
      and t.id = v_test_id
      and t.sequence_no = 11
      and t.code = 'regulamento_vw_cnvw_v1'
      and t.status = 'draft'
      and t.archived_at is null
      and v.version_code = 'cnvw-v3.0-v1'
      and v.version_no = 1
      and v.status = 'draft'
      and v.passing_score = 100
      and v.legal_min_score = 100
      and v.published_at is null
      and v.metadata->>'external_currency_verified' = 'true'
      and lower(v.metadata->>'source_content_sha256') =
          '530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09'
  ) then
    raise exception 'Fase 5C pós-condição: Teste 11 / versão V3.0 não confere.';
  end if;

  if (
    select count(*)
    from public.assessment_version_sources avs
    where avs.organization_id = v_org_id
      and avs.test_version_id = v_version_id
      and avs.source_material_version_id = v_source_v30_id
      and avs.relation_type = 'primary'
      and avs.is_required = true
      and avs.archived_at is null
  ) <> 1 then
    raise exception 'Fase 5C pós-condição: vínculo primário com a V3.0 não confere.';
  end if;

  if exists (
    select 1
    from public.assessment_version_sources avs
    where avs.organization_id = v_org_id
      and avs.test_version_id = v_version_id
      and avs.source_material_version_id = v_source_v21_id
      and avs.archived_at is null
  ) then
    raise exception 'Fase 5C pós-condição: versão do Teste 11 ainda possui vínculo ativo com V2.1.';
  end if;

  if (
    select count(*)
    from public.assessment_version_questions avq
    where avq.organization_id = v_org_id
      and avq.test_version_id = v_version_id
      and avq.archived_at is null
  ) <> 30 then
    raise exception 'Fase 5C pós-condição: Teste 11 deixou de possuir 30 questões.';
  end if;

  if (
    select count(*)
    from public.assessment_questions q
    join public.assessment_version_questions avq
      on avq.organization_id = q.organization_id
     and avq.question_id = q.id
     and avq.test_version_id = v_version_id
     and avq.archived_at is null
    where q.organization_id = v_org_id
      and q.archived_at is null
      and q.status = 'draft'
      and q.content_version = 'cnvw-v3.0-v1'
      and lower(q.metadata->>'source_content_sha256') =
          '530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09'
  ) <> 30 then
    raise exception 'Fase 5C pós-condição: metadados das 30 questões não foram reconciliados com V3.0.';
  end if;

  if (
    select count(*)
    from private.assessment_question_keys k
    join public.assessment_version_questions avq
      on avq.organization_id = k.organization_id
     and avq.question_id = k.question_id
     and avq.test_version_id = v_version_id
     and avq.archived_at is null
    where k.organization_id = v_org_id
      and lower(k.metadata->>'source_content_sha256') =
          '530c8b947fa1732d5032c597af663e67ecba03b9a17b5d78dd7a0b11c6173e09'
  ) <> 30 then
    raise exception 'Fase 5C pós-condição: metadados dos 30 gabaritos não foram reconciliados com V3.0.';
  end if;

  if not exists (
    select 1
    from public.assessment_questions q
    join private.assessment_question_keys k
      on k.organization_id = q.organization_id
     and k.question_id = q.id
    where q.organization_id = v_org_id
      and q.id = '2e6d2845-4e97-544f-8002-f0e506ad6b4a'::uuid
      and q.competency_id = '9c4fdbc5-ed84-5b2f-ba18-0ba6f03b1330'::uuid
      and q.block_code = 'constituicao_grupo'
      and q.prompt = 'Segundo a Cláusula 11, Parágrafo Sétimo, para o cálculo do limite máximo de cotas que um CONSORCIADO pode adquirir em um mesmo grupo, como devem ser consideradas as cotas adquiridas por seu cônjuge ou companheiro?'
      and k.correct_option_code = 'C'
      and k.source_reference = 'Regulamento CNVW/Embracon — Versão 3.0 — Cláusula 11, Parágrafo Sétimo'
      and q.archived_at is null
  ) then
    raise exception 'Fase 5C pós-condição: Q2 reconciliada não confere.';
  end if;

  if (
    select count(*)
    from public.assessment_question_options o
    where o.organization_id = v_org_id
      and o.question_id = '2e6d2845-4e97-544f-8002-f0e506ad6b4a'::uuid
      and o.archived_at is null
      and (
        (o.option_code = 'A' and o.option_text = 'Devem ser desconsideradas, pois possuem titularidade distinta.')
        or
        (o.option_code = 'B' and o.option_text = 'Devem ser consideradas apenas quando houver coobrigação financeira entre os titulares.')
        or
        (o.option_code = 'C' and o.option_text = 'Devem ser consideradas cumulativamente para o cálculo do percentual máximo permitido.')
        or
        (o.option_code = 'D' and o.option_text = 'Devem ser consideradas somente depois da contemplação de uma das cotas.')
      )
  ) <> 4 then
    raise exception 'Fase 5C pós-condição: alternativas reconciliadas da Q2 não conferem.';
  end if;

  if not exists (
    select 1
    from public.assessment_questions q
    join private.assessment_question_keys k
      on k.organization_id = q.organization_id
     and k.question_id = q.id
    where q.organization_id = v_org_id
      and q.id = 'f4a51cc5-b355-515c-a6d1-5b33c0ca2dce'::uuid
      and q.competency_id = '9527c059-e9b5-53c7-a6dd-bc73aaf38a47'::uuid
      and q.block_code = 'cessao_exclusao_prescricao'
      and q.prompt = 'Segundo a Cláusula 37, Parágrafo Sétimo, antes da efetivação da transferência de uma cota, qual procedimento a ADMINISTRADORA deve realizar em relação ao CESSIONÁRIO?'
      and k.correct_option_code = 'B'
      and k.source_reference = 'Regulamento CNVW/Embracon — Versão 3.0 — Cláusula 37, Parágrafo Sétimo'
      and q.archived_at is null
  ) then
    raise exception 'Fase 5C pós-condição: Q23 reconciliada não confere.';
  end if;

  if (
    select count(*)
    from public.assessment_question_options o
    where o.organization_id = v_org_id
      and o.question_id = 'f4a51cc5-b355-515c-a6d1-5b33c0ca2dce'::uuid
      and o.archived_at is null
      and (
        (o.option_code = 'A' and o.option_text = 'Aprovar automaticamente a transferência quando a taxa correspondente estiver paga.')
        or
        (o.option_code = 'B' and o.option_text = 'Analisar a capacidade de pagamento do CESSIONÁRIO, incluindo comprovação de renda e condições de crédito.')
        or
        (o.option_code = 'C' and o.option_text = 'Exigir somente a autorização do CONSORCIADO cedente, sem análise do novo titular.')
        or
        (o.option_code = 'D' and o.option_text = 'Dispensar a análise financeira sempre que a cota ainda não tiver sido contemplada.')
      )
  ) <> 4 then
    raise exception 'Fase 5C pós-condição: alternativas reconciliadas da Q23 não conferem.';
  end if;

  if (
    select count(*)
    from public.assessment_questions q
    join public.assessment_version_questions avq
      on avq.organization_id = q.organization_id
     and avq.question_id = q.id
     and avq.test_version_id = v_version_id
     and avq.archived_at is null
    where q.organization_id = v_org_id
      and q.archived_at is null
      and q.block_code = 'definicoes_adesao'
  ) <> 3 then
    raise exception 'Fase 5C pós-condição: distribuição definicoes_adesao deveria ser 3.';
  end if;

  if (
    select count(*)
    from public.assessment_questions q
    join public.assessment_version_questions avq
      on avq.organization_id = q.organization_id
     and avq.question_id = q.id
     and avq.test_version_id = v_version_id
     and avq.archived_at is null
    where q.organization_id = v_org_id
      and q.archived_at is null
      and q.block_code = 'constituicao_grupo'
  ) <> 4 then
    raise exception 'Fase 5C pós-condição: distribuição constituicao_grupo deveria ser 4.';
  end if;

  if (
    select count(*)
    from public.assessment_questions q
    join public.assessment_version_questions avq
      on avq.organization_id = q.organization_id
     and avq.question_id = q.id
     and avq.test_version_id = v_version_id
     and avq.archived_at is null
    where q.organization_id = v_org_id
      and q.archived_at is null
      and q.block_code = 'contemplacao_lances'
  ) <> 6 then
    raise exception 'Fase 5C pós-condição: distribuição contemplacao_lances deveria ser 6.';
  end if;

  if (
    select count(*)
    from public.assessment_questions q
    join public.assessment_version_questions avq
      on avq.organization_id = q.organization_id
     and avq.question_id = q.id
     and avq.test_version_id = v_version_id
     and avq.archived_at is null
    where q.organization_id = v_org_id
      and q.archived_at is null
      and q.block_code = 'cessao_exclusao_prescricao'
  ) <> 4 then
    raise exception 'Fase 5C pós-condição: distribuição cessao_exclusao_prescricao deveria ser 4.';
  end if;

  if exists (
    select 1
    from private.assessment_test_access_grants g
    where g.organization_id = v_org_id
      and g.test_id = v_test_id
      and g.status = 'active'
      and g.archived_at is null
  ) then
    raise exception 'Fase 5C pós-condição: nenhum grant ativo deveria existir.';
  end if;

  if exists (
    select 1
    from public.assessment_attempts a
    where a.organization_id = v_org_id
      and a.test_id = v_test_id
      and a.archived_at is null
  ) then
    raise exception 'Fase 5C pós-condição: nenhuma tentativa deveria existir.';
  end if;

  -- Fiat precisa permanecer fora do escopo desta migration.
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions v
      on v.organization_id = t.organization_id
     and v.test_id = t.id
     and v.archived_at is null
    where t.organization_id = v_org_id
      and t.sequence_no = 12
      and t.code = 'regulamento_fiat_v1'
      and t.status = 'draft'
      and v.version_code = 'fiat-v3-v1'
      and v.status = 'draft'
      and v.passing_score = 100
      and v.legal_min_score = 100
      and v.published_at is null
      and t.archived_at is null
  ) then
    raise exception 'Fase 5C pós-condição: Teste 12 Fiat deixou de estar no estado draft esperado.';
  end if;
end
$post$;

commit;
