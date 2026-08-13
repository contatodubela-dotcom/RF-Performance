-- ============================================================================
-- RF PERFORMANCE
-- Avaliações e Certificação
-- Correção da criticidade do catálogo 2026.08-v1
--
-- Escopo:
--   organização: 414a2e84-bc62-4c64-99ee-76db1cbc4654
--   versão:       2026.08-v1
--   questões:     150
--   críticas:      96
--
-- Distribuição esperada:
--   Teste 1: 13
--   Teste 2: 18
--   Teste 3: 20
--   Teste 4: 21
--   Teste 5: 24
--
-- A migration altera EXCLUSIVAMENTE private.assessment_question_keys.is_critical.
-- O conjunto esperado é explicitado por teste + sequence_no.
-- Qualquer divergência de catálogo ou de estado aborta toda a transação.
-- ============================================================================

begin;

do $$
declare
  v_org_id constant uuid :=
    '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;

  v_version_code constant text := '2026.08-v1';

  v_total_questions integer;
  v_distinct_questions integer;
  v_test_count integer;
  v_bad_test_counts integer;

  v_private_key_count integer;
  v_option_count integer;

  v_expected_count integer;
  v_expected_true integer;
  v_expected_without_legal_review integer;

  v_legal_review_count integer;
  v_current_true integer;
  v_updated integer := 0;

  v_keys_fingerprint_before text;
  v_keys_fingerprint_after text;

  v_options_fingerprint_before text;
  v_options_fingerprint_after text;
begin
  -- --------------------------------------------------------------------------
  -- GUARDA 1
  -- Catálogo ativo precisa conter exatamente 5 testes x 30 questões.
  -- --------------------------------------------------------------------------

  select
    count(*)::integer,
    count(distinct q.id)::integer
  into
    v_total_questions,
    v_distinct_questions
  from public.assessment_version_questions avq
  join public.assessment_test_versions tv
    on tv.id = avq.test_version_id
   and tv.organization_id = avq.organization_id
  join public.assessment_tests t
    on t.id = tv.test_id
   and t.organization_id = tv.organization_id
  join public.assessment_questions q
    on q.id = avq.question_id
   and q.organization_id = avq.organization_id
  where avq.organization_id = v_org_id
    and tv.version_code = v_version_code
    and avq.archived_at is null
    and tv.archived_at is null
    and t.archived_at is null
    and q.archived_at is null;

  if v_total_questions <> 150
     or v_distinct_questions <> 150 then
    raise exception
      'CRITICALITY_PREFLIGHT_FAILED: catalog total=%, distinct=%; expected 150/150',
      v_total_questions,
      v_distinct_questions;
  end if;

  select count(distinct t.sequence_no)::integer
  into v_test_count
  from public.assessment_version_questions avq
  join public.assessment_test_versions tv
    on tv.id = avq.test_version_id
   and tv.organization_id = avq.organization_id
  join public.assessment_tests t
    on t.id = tv.test_id
   and t.organization_id = tv.organization_id
  where avq.organization_id = v_org_id
    and tv.version_code = v_version_code
    and avq.archived_at is null
    and tv.archived_at is null
    and t.archived_at is null;

  select count(*)::integer
  into v_bad_test_counts
  from (
    select
      t.sequence_no,
      count(*)::integer as question_count
    from public.assessment_version_questions avq
    join public.assessment_test_versions tv
      on tv.id = avq.test_version_id
     and tv.organization_id = avq.organization_id
    join public.assessment_tests t
      on t.id = tv.test_id
     and t.organization_id = tv.organization_id
    join public.assessment_questions q
      on q.id = avq.question_id
     and q.organization_id = avq.organization_id
    where avq.organization_id = v_org_id
      and tv.version_code = v_version_code
      and avq.archived_at is null
      and tv.archived_at is null
      and t.archived_at is null
      and q.archived_at is null
    group by t.sequence_no
  ) counts
  where counts.sequence_no not between 1 and 5
     or counts.question_count <> 30;

  if v_test_count <> 5 or v_bad_test_counts <> 0 then
    raise exception
      'CRITICALITY_PREFLIGHT_FAILED: tests=% bad_test_counts=%',
      v_test_count,
      v_bad_test_counts;
  end if;

  -- --------------------------------------------------------------------------
  -- GUARDA 2
  -- As 150 questões precisam possuir exatamente 150 gabaritos privados
  -- e 600 alternativas públicas ativas.
  -- --------------------------------------------------------------------------

  select count(*)::integer
  into v_private_key_count
  from private.assessment_question_keys qk
  join public.assessment_questions q
    on q.id = qk.question_id
   and q.organization_id = qk.organization_id
  join public.assessment_version_questions avq
    on avq.question_id = q.id
   and avq.organization_id = q.organization_id
  join public.assessment_test_versions tv
    on tv.id = avq.test_version_id
   and tv.organization_id = avq.organization_id
  where qk.organization_id = v_org_id
    and tv.version_code = v_version_code
    and avq.archived_at is null
    and tv.archived_at is null
    and q.archived_at is null;

  if v_private_key_count <> 150 then
    raise exception
      'CRITICALITY_PREFLIGHT_FAILED: private keys=%; expected 150',
      v_private_key_count;
  end if;

  select count(*)::integer
  into v_option_count
  from public.assessment_question_options o
  join public.assessment_questions q
    on q.id = o.question_id
   and q.organization_id = o.organization_id
  join public.assessment_version_questions avq
    on avq.question_id = q.id
   and avq.organization_id = q.organization_id
  join public.assessment_test_versions tv
    on tv.id = avq.test_version_id
   and tv.organization_id = avq.organization_id
  where o.organization_id = v_org_id
    and tv.version_code = v_version_code
    and o.archived_at is null
    and q.archived_at is null
    and avq.archived_at is null
    and tv.archived_at is null;

  if v_option_count <> 600 then
    raise exception
      'CRITICALITY_PREFLIGHT_FAILED: active options=%; expected 600',
      v_option_count;
  end if;

  -- --------------------------------------------------------------------------
  -- GUARDA 3
  -- Conjunto imutável esperado de questões críticas.
  -- Derivado da fonte 2026.08-v1 e validado previamente no banco.
  -- --------------------------------------------------------------------------

  with expected(test_no, question_no) as (
    select 1, x
      from unnest(array[
        5,7,8,9,10,11,12,13,14,15,16,17,18
      ]::integer[]) as x

    union all

    select 2, x
      from unnest(array[
        1,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,27
      ]::integer[]) as x

    union all

    select 3, x
      from unnest(array[
        1,2,3,4,6,9,10,11,12,13,14,15,16,17,18,19,21,22,24,30
      ]::integer[]) as x

    union all

    select 4, x
      from unnest(array[
        2,3,5,6,9,10,11,12,13,14,15,16,17,18,19,20,21,22,24,25,29
      ]::integer[]) as x

    union all

    select 5, x
      from unnest(array[
        1,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,26,30
      ]::integer[]) as x
  ),
  resolved as (
    select
      e.test_no,
      e.question_no,
      q.id as question_id,
      q.legal_review_date,
      qk.is_critical
    from expected e
    join public.assessment_tests t
      on t.organization_id = v_org_id
     and t.sequence_no = e.test_no
     and t.archived_at is null
    join public.assessment_test_versions tv
      on tv.organization_id = t.organization_id
     and tv.test_id = t.id
     and tv.version_code = v_version_code
     and tv.archived_at is null
    join public.assessment_version_questions avq
      on avq.organization_id = tv.organization_id
     and avq.test_version_id = tv.id
     and avq.sequence_no = e.question_no
     and avq.archived_at is null
    join public.assessment_questions q
      on q.id = avq.question_id
     and q.organization_id = avq.organization_id
     and q.archived_at is null
    join private.assessment_question_keys qk
      on qk.question_id = q.id
     and qk.organization_id = q.organization_id
  )
  select
    count(*)::integer,
    count(*) filter (where is_critical)::integer,
    count(*) filter (where legal_review_date is null)::integer
  into
    v_expected_count,
    v_expected_true,
    v_expected_without_legal_review
  from resolved;

  if v_expected_count <> 96 then
    raise exception
      'CRITICALITY_PREFLIGHT_FAILED: resolved expected critical questions=%; expected 96',
      v_expected_count;
  end if;

  if v_expected_without_legal_review <> 0 then
    raise exception
      'CRITICALITY_PREFLIGHT_FAILED: expected critical questions without legal review=%',
      v_expected_without_legal_review;
  end if;

  select count(*) filter (
    where q.legal_review_date is not null
  )::integer
  into v_legal_review_count
  from public.assessment_version_questions avq
  join public.assessment_test_versions tv
    on tv.id = avq.test_version_id
   and tv.organization_id = avq.organization_id
  join public.assessment_questions q
    on q.id = avq.question_id
   and q.organization_id = avq.organization_id
  where avq.organization_id = v_org_id
    and tv.version_code = v_version_code
    and avq.archived_at is null
    and tv.archived_at is null
    and q.archived_at is null;

  if v_legal_review_count <> 96 then
    raise exception
      'CRITICALITY_PREFLIGHT_FAILED: legal-review questions=%; expected 96',
      v_legal_review_count;
  end if;

  -- --------------------------------------------------------------------------
  -- GUARDA 4
  -- Estado permitido:
  --   A) pré-correção  -> 0 críticas no total / 0 das esperadas
  --   B) pós-correção -> 96 críticas no total / 96 das esperadas
  --
  -- Qualquer estado parcial ou inesperado aborta.
  -- --------------------------------------------------------------------------

  select count(*) filter (where qk.is_critical)::integer
  into v_current_true
  from private.assessment_question_keys qk
  join public.assessment_questions q
    on q.id = qk.question_id
   and q.organization_id = qk.organization_id
  join public.assessment_version_questions avq
    on avq.question_id = q.id
   and avq.organization_id = q.organization_id
  join public.assessment_test_versions tv
    on tv.id = avq.test_version_id
   and tv.organization_id = avq.organization_id
  where qk.organization_id = v_org_id
    and tv.version_code = v_version_code
    and avq.archived_at is null
    and tv.archived_at is null
    and q.archived_at is null;

  if not (
       (v_current_true = 0  and v_expected_true = 0)
    or (v_current_true = 96 and v_expected_true = 96)
  ) then
    raise exception
      'CRITICALITY_PREFLIGHT_FAILED: unexpected partial state total_true=% expected_true=%',
      v_current_true,
      v_expected_true;
  end if;

  -- --------------------------------------------------------------------------
  -- FINGERPRINTS
  -- Proteger campos privados de gabarito e alternativas.
  -- is_critical NÃO participa do fingerprint porque é o único alvo intencional.
  -- --------------------------------------------------------------------------

  select md5(coalesce(string_agg(
    concat_ws(
      '|',
      qk.question_id::text,
      qk.correct_option_code,
      qk.justification,
      qk.source_reference,
      coalesce(qk.critical_reason, '')
    ),
    E'\n'
    order by qk.question_id
  ), ''))
  into v_keys_fingerprint_before
  from private.assessment_question_keys qk
  join public.assessment_questions q
    on q.id = qk.question_id
   and q.organization_id = qk.organization_id
  join public.assessment_version_questions avq
    on avq.question_id = q.id
   and avq.organization_id = q.organization_id
  join public.assessment_test_versions tv
    on tv.id = avq.test_version_id
   and tv.organization_id = avq.organization_id
  where qk.organization_id = v_org_id
    and tv.version_code = v_version_code
    and avq.archived_at is null
    and tv.archived_at is null
    and q.archived_at is null;

  select md5(coalesce(string_agg(
    concat_ws(
      '|',
      o.question_id::text,
      o.option_code,
      o.option_text
    ),
    E'\n'
    order by o.question_id, o.option_code
  ), ''))
  into v_options_fingerprint_before
  from public.assessment_question_options o
  join public.assessment_questions q
    on q.id = o.question_id
   and q.organization_id = o.organization_id
  join public.assessment_version_questions avq
    on avq.question_id = q.id
   and avq.organization_id = q.organization_id
  join public.assessment_test_versions tv
    on tv.id = avq.test_version_id
   and tv.organization_id = avq.organization_id
  where o.organization_id = v_org_id
    and tv.version_code = v_version_code
    and o.archived_at is null
    and q.archived_at is null
    and avq.archived_at is null
    and tv.archived_at is null;

  -- --------------------------------------------------------------------------
  -- CORREÇÃO
  -- Executada somente no estado pré-correção integral.
  -- --------------------------------------------------------------------------

  if v_current_true = 0 and v_expected_true = 0 then

    with expected(test_no, question_no) as (
      select 1, x
        from unnest(array[
          5,7,8,9,10,11,12,13,14,15,16,17,18
        ]::integer[]) as x

      union all

      select 2, x
        from unnest(array[
          1,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,27
        ]::integer[]) as x

      union all

      select 3, x
        from unnest(array[
          1,2,3,4,6,9,10,11,12,13,14,15,16,17,18,19,21,22,24,30
        ]::integer[]) as x

      union all

      select 4, x
        from unnest(array[
          2,3,5,6,9,10,11,12,13,14,15,16,17,18,19,20,21,22,24,25,29
        ]::integer[]) as x

      union all

      select 5, x
        from unnest(array[
          1,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,26,30
        ]::integer[]) as x
    ),
    targets as (
      select q.id as question_id
      from expected e
      join public.assessment_tests t
        on t.organization_id = v_org_id
       and t.sequence_no = e.test_no
       and t.archived_at is null
      join public.assessment_test_versions tv
        on tv.organization_id = t.organization_id
       and tv.test_id = t.id
       and tv.version_code = v_version_code
       and tv.archived_at is null
      join public.assessment_version_questions avq
        on avq.organization_id = tv.organization_id
       and avq.test_version_id = tv.id
       and avq.sequence_no = e.question_no
       and avq.archived_at is null
      join public.assessment_questions q
        on q.id = avq.question_id
       and q.organization_id = avq.organization_id
       and q.archived_at is null
    )
    update private.assessment_question_keys qk
       set is_critical = true
      from targets target
     where qk.organization_id = v_org_id
       and qk.question_id = target.question_id
       and qk.is_critical = false;

    get diagnostics v_updated = row_count;

    if v_updated <> 96 then
      raise exception
        'CRITICALITY_UPDATE_FAILED: rows updated=%; expected 96',
        v_updated;
    end if;

  else
    raise notice
      'CRITICALITY_ALREADY_CORRECT: catalog already has 96 expected critical questions';
  end if;

  -- --------------------------------------------------------------------------
  -- PÓS-CONDIÇÃO
  -- Exatamente 96 questões precisam estar críticas.
  -- --------------------------------------------------------------------------

  select count(*) filter (where qk.is_critical)::integer
  into v_current_true
  from private.assessment_question_keys qk
  join public.assessment_questions q
    on q.id = qk.question_id
   and q.organization_id = qk.organization_id
  join public.assessment_version_questions avq
    on avq.question_id = q.id
   and avq.organization_id = q.organization_id
  join public.assessment_test_versions tv
    on tv.id = avq.test_version_id
   and tv.organization_id = avq.organization_id
  where qk.organization_id = v_org_id
    and tv.version_code = v_version_code
    and avq.archived_at is null
    and tv.archived_at is null
    and q.archived_at is null;

  with expected(test_no, question_no) as (
    select 1, x
      from unnest(array[
        5,7,8,9,10,11,12,13,14,15,16,17,18
      ]::integer[]) as x

    union all

    select 2, x
      from unnest(array[
        1,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,27
      ]::integer[]) as x

    union all

    select 3, x
      from unnest(array[
        1,2,3,4,6,9,10,11,12,13,14,15,16,17,18,19,21,22,24,30
      ]::integer[]) as x

    union all

    select 4, x
      from unnest(array[
        2,3,5,6,9,10,11,12,13,14,15,16,17,18,19,20,21,22,24,25,29
      ]::integer[]) as x

    union all

    select 5, x
      from unnest(array[
        1,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,26,30
      ]::integer[]) as x
  )
  select count(*) filter (where qk.is_critical)::integer
  into v_expected_true
  from expected e
  join public.assessment_tests t
    on t.organization_id = v_org_id
   and t.sequence_no = e.test_no
   and t.archived_at is null
  join public.assessment_test_versions tv
    on tv.organization_id = t.organization_id
   and tv.test_id = t.id
   and tv.version_code = v_version_code
   and tv.archived_at is null
  join public.assessment_version_questions avq
    on avq.organization_id = tv.organization_id
   and avq.test_version_id = tv.id
   and avq.sequence_no = e.question_no
   and avq.archived_at is null
  join public.assessment_questions q
    on q.id = avq.question_id
   and q.organization_id = avq.organization_id
   and q.archived_at is null
  join private.assessment_question_keys qk
    on qk.question_id = q.id
   and qk.organization_id = q.organization_id;

  if v_current_true <> 96 or v_expected_true <> 96 then
    raise exception
      'CRITICALITY_POSTCONDITION_FAILED: total_true=% expected_true=%; expected 96/96',
      v_current_true,
      v_expected_true;
  end if;

  -- --------------------------------------------------------------------------
  -- FINGERPRINTS PÓS-CORREÇÃO
  -- Nenhum gabarito textual/código nem alternativa pode ter mudado.
  -- --------------------------------------------------------------------------

  select md5(coalesce(string_agg(
    concat_ws(
      '|',
      qk.question_id::text,
      qk.correct_option_code,
      qk.justification,
      qk.source_reference,
      coalesce(qk.critical_reason, '')
    ),
    E'\n'
    order by qk.question_id
  ), ''))
  into v_keys_fingerprint_after
  from private.assessment_question_keys qk
  join public.assessment_questions q
    on q.id = qk.question_id
   and q.organization_id = qk.organization_id
  join public.assessment_version_questions avq
    on avq.question_id = q.id
   and avq.organization_id = q.organization_id
  join public.assessment_test_versions tv
    on tv.id = avq.test_version_id
   and tv.organization_id = avq.organization_id
  where qk.organization_id = v_org_id
    and tv.version_code = v_version_code
    and avq.archived_at is null
    and tv.archived_at is null
    and q.archived_at is null;

  select md5(coalesce(string_agg(
    concat_ws(
      '|',
      o.question_id::text,
      o.option_code,
      o.option_text
    ),
    E'\n'
    order by o.question_id, o.option_code
  ), ''))
  into v_options_fingerprint_after
  from public.assessment_question_options o
  join public.assessment_questions q
    on q.id = o.question_id
   and q.organization_id = o.organization_id
  join public.assessment_version_questions avq
    on avq.question_id = q.id
   and avq.organization_id = q.organization_id
  join public.assessment_test_versions tv
    on tv.id = avq.test_version_id
   and tv.organization_id = avq.organization_id
  where o.organization_id = v_org_id
    and tv.version_code = v_version_code
    and o.archived_at is null
    and q.archived_at is null
    and avq.archived_at is null
    and tv.archived_at is null;

  if v_keys_fingerprint_before is distinct from v_keys_fingerprint_after then
    raise exception
      'CRITICALITY_POSTCONDITION_FAILED: private answer-key fingerprint changed unexpectedly';
  end if;

  if v_options_fingerprint_before is distinct from v_options_fingerprint_after then
    raise exception
      'CRITICALITY_POSTCONDITION_FAILED: public option fingerprint changed unexpectedly';
  end if;

  raise notice
    'CRITICALITY_CORRECTION_OK: total=150 critical=96 updated=%',
    v_updated;
end
$$;

commit;