-- ============================================================================
-- RF Performance — Avaliações e Certificações — Fase 1E
-- Homologação individual e progressiva dos Testes 2 a 5
--
-- Objetivos:
--   1. publicar as versões 2026.08-v1 dos Testes 2, 3, 4 e 5;
--   2. conceder acesso individual somente ao Usuário Teste RF;
--   3. preservar o bloqueio progressivo por pré-requisitos;
--   4. manter o acesso organizacional geral desativado;
--   5. preservar integralmente a tentativa concluída do Teste 1;
--   6. não criar tentativas, respostas, notas ou certificações.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- Preflight estrito
-- ----------------------------------------------------------------------------

do $preflight$
declare
  v_target_count integer;
  v_active_tests integer;
  v_published_versions integer;
  v_target_attempts integer;
  v_target_grants integer;
  v_pilot_answers integer;
  v_pilot_grades integer;
  target record;
begin
  if to_regclass('private.assessment_test_access_grants') is null then
    raise exception 'ASSESSMENT_ACCESS_GRANTS_TABLE_NOT_FOUND';
  end if;

  if to_regprocedure(
    'private.assessment_test_access_allowed(uuid,uuid,uuid,uuid)'
  ) is null then
    raise exception 'ASSESSMENT_ACCESS_HELPER_NOT_FOUND';
  end if;

  if to_regprocedure(
    'private.assessment_prerequisites_met(uuid,uuid,uuid)'
  ) is null then
    raise exception 'ASSESSMENT_PREREQUISITES_HELPER_NOT_FOUND';
  end if;

  if not exists (
    select 1
    from public.organizations o
    where o.id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and o.status = 'active'
  ) then
    raise exception 'PILOT_ORGANIZATION_NOT_ACTIVE';
  end if;

  if not exists (
    select 1
    from public.organization_members om
    join public.profiles p
      on p.id = om.user_id
     and p.status = 'active'
     and p.archived_at is null
    where om.id = '49239d09-0f85-471f-8f46-5c240cd98600'::uuid
      and om.organization_id =
          '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and om.user_id = 'e88242b6-e44e-4de7-97cf-dbefc0605eaf'::uuid
      and om.role = 'salesperson'
      and om.status = 'active'
      and om.archived_at is null
  ) then
    raise exception 'PILOT_MEMBER_NOT_ACTIVE_OR_MISMATCHED';
  end if;

  -- O Teste 1 e sua versão devem continuar publicados.
  if not exists (
    select 1
    from public.assessment_tests t
    join public.assessment_test_versions tv
      on tv.organization_id = t.organization_id
     and tv.test_id = t.id
     and tv.id = 'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
     and tv.status = 'published'
     and tv.published_at is not null
     and tv.valid_from is not null
     and tv.valid_from <= now()
     and tv.archived_at is null
    where t.id = '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
      and t.organization_id =
          '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and t.code = 'teste_1_diagnostico'
      and t.status = 'active'
      and t.archived_at is null
  ) then
    raise exception 'PILOT_DIAGNOSTIC_PUBLICATION_NOT_PRESERVED';
  end if;

  if not private.assessment_test_access_allowed(
    '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
    '49239d09-0f85-471f-8f46-5c240cd98600'::uuid,
    '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid,
    'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
  ) then
    raise exception 'PILOT_DIAGNOSTIC_ACCESS_NOT_PRESERVED';
  end if;

  -- A tentativa piloto concluída deve permanecer exatamente como validada.
  if not exists (
    select 1
    from public.assessment_attempts a
    where a.id = '72e1c6e0-2d62-47e3-85ec-6de2f4eaddbe'::uuid
      and a.organization_id =
          '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and a.organization_member_id =
          '49239d09-0f85-471f-8f46-5c240cd98600'::uuid
      and a.test_id = '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
      and a.test_version_id =
          'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
      and a.status = 'graded'
      and a.attempt_no = 1
      and a.total_questions = 30
      and a.answered_questions = 30
      and a.correct_answers = 29
      and a.overall_score = 96.67
      and a.legal_score = 100.00
      and a.archived_at is null
  ) then
    raise exception 'PILOT_DIAGNOSTIC_ATTEMPT_NOT_PRESERVED';
  end if;

  select count(*)::integer
  into v_pilot_answers
  from public.assessment_attempt_answers answer
  where answer.organization_id =
        '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and answer.attempt_id =
        '72e1c6e0-2d62-47e3-85ec-6de2f4eaddbe'::uuid
    and answer.archived_at is null;

  if v_pilot_answers <> 30 then
    raise exception 'PILOT_DIAGNOSTIC_ANSWER_COUNT_INVALID: %',
      v_pilot_answers;
  end if;

  select count(*)::integer
  into v_pilot_grades
  from private.assessment_attempt_grades grade
  where grade.organization_id =
        '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and grade.attempt_id =
        '72e1c6e0-2d62-47e3-85ec-6de2f4eaddbe'::uuid;

  if v_pilot_grades <> 30 then
    raise exception 'PILOT_DIAGNOSTIC_GRADE_COUNT_INVALID: %',
      v_pilot_grades;
  end if;

  select count(*)::integer
  into v_active_tests
  from public.assessment_tests t
  where t.organization_id =
        '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and t.status = 'active'
    and t.archived_at is null;

  if v_active_tests <> 1 then
    raise exception 'UNEXPECTED_ACTIVE_TEST_COUNT_BEFORE_PUBLICATION: %',
      v_active_tests;
  end if;

  select count(*)::integer
  into v_published_versions
  from public.assessment_test_versions tv
  where tv.organization_id =
        '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and tv.status = 'published'
    and tv.archived_at is null;

  if v_published_versions <> 1 then
    raise exception 'UNEXPECTED_PUBLISHED_VERSION_COUNT_BEFORE_PUBLICATION: %',
      v_published_versions;
  end if;

  select count(*)::integer
  into v_target_count
  from (
    values
      (
        2,
        '99f4b9fe-66c2-591e-a670-064675a64650'::uuid,
        'd608e0c6-efc6-500c-9258-64a774b4b169'::uuid,
        'teste_2_nivel_1'::text,
        'teste_1_diagnostico'::text,
        'graded'::text,
        70.00::numeric,
        80.00::numeric
      ),
      (
        3,
        '8a7754bc-7777-503c-a6aa-213b48f03f28'::uuid,
        'a68e7ffa-2c6e-5e95-9ab9-a0b3d9b307ef'::uuid,
        'teste_3_intermediario'::text,
        'teste_2_nivel_1'::text,
        'passed'::text,
        75.00::numeric,
        80.00::numeric
      ),
      (
        4,
        'c57f65fc-5084-501d-bbc1-b371d7fb5f02'::uuid,
        '22d2e41e-b5fc-5765-a1a8-edfde5c698ed'::uuid,
        'teste_4_nivel_2'::text,
        'teste_3_intermediario'::text,
        'passed'::text,
        80.00::numeric,
        85.00::numeric
      ),
      (
        5,
        'abe87462-d06b-5a84-8bc5-a4841bb17cb2'::uuid,
        '7004fc3c-a1e7-5e28-a66b-143d3bffb869'::uuid,
        'teste_5_nivel_3'::text,
        'teste_4_nivel_2'::text,
        'passed'::text,
        88.00::numeric,
        90.00::numeric
      )
  ) as expected(
    sequence_no,
    test_id,
    version_id,
    test_code,
    prerequisite_test_code,
    prerequisite_result,
    passing_score,
    legal_min_score
  )
  join public.assessment_tests t
    on t.id = expected.test_id
   and t.organization_id =
       '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
   and t.sequence_no = expected.sequence_no
   and t.code = expected.test_code
   and t.status = 'draft'
   and t.max_attempts = 2
   and t.cooldown_hours = 24
   and t.metadata ->> 'prerequisite_test_code' =
       expected.prerequisite_test_code
   and t.metadata ->> 'prerequisite_result' =
       expected.prerequisite_result
   and t.archived_at is null
  join public.assessment_test_versions tv
    on tv.id = expected.version_id
   and tv.organization_id = t.organization_id
   and tv.test_id = t.id
   and tv.version_code = '2026.08-v1'
   and tv.version_no = 1
   and tv.status = 'draft'
   and tv.question_count = 30
   and tv.passing_score = expected.passing_score
   and tv.legal_min_score = expected.legal_min_score
   and tv.randomize_questions = false
   and tv.randomize_options = true
   and tv.show_review_after_submit = true
   and tv.published_at is null
   and tv.valid_from is null
   and tv.archived_at is null;

  if v_target_count <> 4 then
    raise exception 'TARGET_TEST_OR_VERSION_PREFLIGHT_FAILED: %',
      v_target_count;
  end if;

  for target in
    select *
    from (
      values
        (
          2,
          '99f4b9fe-66c2-591e-a670-064675a64650'::uuid,
          'd608e0c6-efc6-500c-9258-64a774b4b169'::uuid,
          true
        ),
        (
          3,
          '8a7754bc-7777-503c-a6aa-213b48f03f28'::uuid,
          'a68e7ffa-2c6e-5e95-9ab9-a0b3d9b307ef'::uuid,
          false
        ),
        (
          4,
          'c57f65fc-5084-501d-bbc1-b371d7fb5f02'::uuid,
          '22d2e41e-b5fc-5765-a1a8-edfde5c698ed'::uuid,
          false
        ),
        (
          5,
          'abe87462-d06b-5a84-8bc5-a4841bb17cb2'::uuid,
          '7004fc3c-a1e7-5e28-a66b-143d3bffb869'::uuid,
          false
        )
    ) as x(sequence_no, test_id, version_id, prerequisite_expected)
  loop
    if (
      select count(*)
      from public.assessment_version_questions avq
      where avq.organization_id =
            '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
        and avq.test_version_id = target.version_id
        and avq.archived_at is null
    ) <> 30 then
      raise exception 'TARGET_LINKED_QUESTION_COUNT_INVALID_TEST_%',
        target.sequence_no;
    end if;

    if (
      select count(distinct q.id)
      from public.assessment_version_questions avq
      join public.assessment_questions q
        on q.organization_id = avq.organization_id
       and q.id = avq.question_id
       and q.status = 'reviewed'
       and q.archived_at is null
      where avq.organization_id =
            '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
        and avq.test_version_id = target.version_id
        and avq.archived_at is null
    ) <> 30 then
      raise exception 'TARGET_REVIEWED_QUESTION_COUNT_INVALID_TEST_%',
        target.sequence_no;
    end if;

    if (
      select count(distinct qo.id)
      from public.assessment_version_questions avq
      join public.assessment_question_options qo
        on qo.organization_id = avq.organization_id
       and qo.question_id = avq.question_id
       and qo.archived_at is null
      where avq.organization_id =
            '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
        and avq.test_version_id = target.version_id
        and avq.archived_at is null
    ) <> 120 then
      raise exception 'TARGET_OPTION_COUNT_INVALID_TEST_%',
        target.sequence_no;
    end if;

    if (
      select count(distinct qk.question_id)
      from public.assessment_version_questions avq
      join private.assessment_question_keys qk
        on qk.organization_id = avq.organization_id
       and qk.question_id = avq.question_id
      where avq.organization_id =
            '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
        and avq.test_version_id = target.version_id
        and avq.archived_at is null
    ) <> 30 then
      raise exception 'TARGET_PRIVATE_KEY_COUNT_INVALID_TEST_%',
        target.sequence_no;
    end if;

    if exists (
      select 1
      from (
        select
          count(distinct avq.sequence_no) as positions,
          min(avq.sequence_no) as first_position,
          max(avq.sequence_no) as last_position
        from public.assessment_version_questions avq
        where avq.organization_id =
              '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
          and avq.test_version_id = target.version_id
          and avq.archived_at is null
      ) positions
      where positions.positions <> 30
         or positions.first_position <> 1
         or positions.last_position <> 30
    ) then
      raise exception 'TARGET_POSITION_SEQUENCE_INVALID_TEST_%',
        target.sequence_no;
    end if;

    if private.assessment_test_access_allowed(
      '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
      '49239d09-0f85-471f-8f46-5c240cd98600'::uuid,
      target.test_id,
      target.version_id
    ) then
      raise exception 'TARGET_ACCESS_ALREADY_ALLOWED_TEST_%',
        target.sequence_no;
    end if;

    if private.assessment_prerequisites_met(
      '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
      '49239d09-0f85-471f-8f46-5c240cd98600'::uuid,
      target.test_id
    ) is distinct from target.prerequisite_expected then
      raise exception 'TARGET_PREREQUISITE_STATE_INVALID_TEST_%',
        target.sequence_no;
    end if;
  end loop;

  select count(*)::integer
  into v_target_attempts
  from public.assessment_attempts a
  where a.organization_id =
        '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and a.test_id = any (
      array[
        '99f4b9fe-66c2-591e-a670-064675a64650'::uuid,
        '8a7754bc-7777-503c-a6aa-213b48f03f28'::uuid,
        'c57f65fc-5084-501d-bbc1-b371d7fb5f02'::uuid,
        'abe87462-d06b-5a84-8bc5-a4841bb17cb2'::uuid
      ]
    )
    and a.archived_at is null;

  if v_target_attempts <> 0 then
    raise exception 'TARGET_TESTS_ALREADY_HAVE_ATTEMPTS: %',
      v_target_attempts;
  end if;

  select count(*)::integer
  into v_target_grants
  from private.assessment_test_access_grants access_grant
  where access_grant.organization_id =
        '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and access_grant.test_version_id = any (
      array[
        'd608e0c6-efc6-500c-9258-64a774b4b169'::uuid,
        'a68e7ffa-2c6e-5e95-9ab9-a0b3d9b307ef'::uuid,
        '22d2e41e-b5fc-5765-a1a8-edfde5c698ed'::uuid,
        '7004fc3c-a1e7-5e28-a66b-143d3bffb869'::uuid
      ]
    )
    and access_grant.status = 'active'
    and access_grant.archived_at is null;

  if v_target_grants <> 0 then
    raise exception 'TARGET_ACTIVE_GRANTS_ALREADY_EXIST: %',
      v_target_grants;
  end if;
end;
$preflight$;

-- ----------------------------------------------------------------------------
-- Grants individuais de homologação
-- ----------------------------------------------------------------------------

insert into private.assessment_test_access_grants (
  id,
  organization_id,
  test_id,
  test_version_id,
  access_scope,
  organization_member_id,
  status,
  valid_from,
  valid_until,
  reason,
  created_by,
  updated_by,
  metadata
)
values
  (
    '2c37c3a3-5a01-57c5-8312-40c7bc5eadea'::uuid,
    '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
    '99f4b9fe-66c2-591e-a670-064675a64650'::uuid,
    'd608e0c6-efc6-500c-9258-64a774b4b169'::uuid,
    'member',
    '49239d09-0f85-471f-8f46-5c240cd98600'::uuid,
    'active',
    now(),
    null,
    'Homologação individual e progressiva do Teste 2.',
    null,
    null,
    jsonb_build_object(
      'phase', '1E',
      'pilot', true,
      'test_number', 2,
      'pilot_user_id', 'e88242b6-e44e-4de7-97cf-dbefc0605eaf',
      'pilot_email', 'empilhaplus@gmail.com',
      'migration',
        '20260806184500_avaliacoes_certificacao_testes2a5_homologacao_piloto'
    )
  ),
  (
    'ba3eeeeb-3a67-5599-a229-453b6b8f004f'::uuid,
    '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
    '8a7754bc-7777-503c-a6aa-213b48f03f28'::uuid,
    'a68e7ffa-2c6e-5e95-9ab9-a0b3d9b307ef'::uuid,
    'member',
    '49239d09-0f85-471f-8f46-5c240cd98600'::uuid,
    'active',
    now(),
    null,
    'Homologação individual e progressiva do Teste 3.',
    null,
    null,
    jsonb_build_object(
      'phase', '1E',
      'pilot', true,
      'test_number', 3,
      'pilot_user_id', 'e88242b6-e44e-4de7-97cf-dbefc0605eaf',
      'pilot_email', 'empilhaplus@gmail.com',
      'migration',
        '20260806184500_avaliacoes_certificacao_testes2a5_homologacao_piloto'
    )
  ),
  (
    '14bd3682-b4d3-57ac-8c6d-80bef00261e3'::uuid,
    '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
    'c57f65fc-5084-501d-bbc1-b371d7fb5f02'::uuid,
    '22d2e41e-b5fc-5765-a1a8-edfde5c698ed'::uuid,
    'member',
    '49239d09-0f85-471f-8f46-5c240cd98600'::uuid,
    'active',
    now(),
    null,
    'Homologação individual e progressiva do Teste 4.',
    null,
    null,
    jsonb_build_object(
      'phase', '1E',
      'pilot', true,
      'test_number', 4,
      'pilot_user_id', 'e88242b6-e44e-4de7-97cf-dbefc0605eaf',
      'pilot_email', 'empilhaplus@gmail.com',
      'migration',
        '20260806184500_avaliacoes_certificacao_testes2a5_homologacao_piloto'
    )
  ),
  (
    '7bc7b693-46fa-5fda-956e-eb7e7a951a7c'::uuid,
    '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
    'abe87462-d06b-5a84-8bc5-a4841bb17cb2'::uuid,
    '7004fc3c-a1e7-5e28-a66b-143d3bffb869'::uuid,
    'member',
    '49239d09-0f85-471f-8f46-5c240cd98600'::uuid,
    'active',
    now(),
    null,
    'Homologação individual e progressiva do Teste 5.',
    null,
    null,
    jsonb_build_object(
      'phase', '1E',
      'pilot', true,
      'test_number', 5,
      'pilot_user_id', 'e88242b6-e44e-4de7-97cf-dbefc0605eaf',
      'pilot_email', 'empilhaplus@gmail.com',
      'migration',
        '20260806184500_avaliacoes_certificacao_testes2a5_homologacao_piloto'
    )
  );

-- ----------------------------------------------------------------------------
-- Publicação das quatro avaliações
-- ----------------------------------------------------------------------------

update public.assessment_tests
set status = 'active',
    updated_at = now(),
    updated_by = null,
    metadata = metadata || jsonb_build_object(
      'publication_phase', '1E',
      'publication_mode', 'individual_pilot_progressive',
      'pilot_organization_member_id',
        '49239d09-0f85-471f-8f46-5c240cd98600',
      'published_by_migration',
        '20260806184500_avaliacoes_certificacao_testes2a5_homologacao_piloto'
    )
where organization_id =
      '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and id = any (
    array[
      '99f4b9fe-66c2-591e-a670-064675a64650'::uuid,
      '8a7754bc-7777-503c-a6aa-213b48f03f28'::uuid,
      'c57f65fc-5084-501d-bbc1-b371d7fb5f02'::uuid,
      'abe87462-d06b-5a84-8bc5-a4841bb17cb2'::uuid
    ]
  )
  and status = 'draft'
  and archived_at is null;

update public.assessment_test_versions
set status = 'published',
    valid_from = coalesce(valid_from, now()),
    published_at = coalesce(published_at, now()),
    updated_at = now(),
    updated_by = null,
    metadata = metadata || jsonb_build_object(
      'publication_status', 'homologation_published',
      'publication_phase', '1E',
      'publication_mode', 'individual_pilot_progressive',
      'pilot_organization_member_id',
        '49239d09-0f85-471f-8f46-5c240cd98600',
      'published_by_migration',
        '20260806184500_avaliacoes_certificacao_testes2a5_homologacao_piloto'
    )
where organization_id =
      '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and id = any (
    array[
      'd608e0c6-efc6-500c-9258-64a774b4b169'::uuid,
      'a68e7ffa-2c6e-5e95-9ab9-a0b3d9b307ef'::uuid,
      '22d2e41e-b5fc-5765-a1a8-edfde5c698ed'::uuid,
      '7004fc3c-a1e7-5e28-a66b-143d3bffb869'::uuid
    ]
  )
  and status = 'draft'
  and archived_at is null;

-- ----------------------------------------------------------------------------
-- Pós-condições estritas
-- ----------------------------------------------------------------------------

do $postconditions$
declare
  v_active_tests integer;
  v_published_versions integer;
  v_target_grants integer;
  v_organization_grants integer;
  v_target_attempts integer;
  v_pilot_answers integer;
  v_pilot_grades integer;
  target_row record;
begin
  select count(*)::integer
  into v_active_tests
  from public.assessment_tests t
  where t.organization_id =
        '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and t.status = 'active'
    and t.archived_at is null;

  if v_active_tests <> 5 then
    raise exception 'UNEXPECTED_ACTIVE_TEST_COUNT_AFTER_PUBLICATION: %',
      v_active_tests;
  end if;

  select count(*)::integer
  into v_published_versions
  from public.assessment_test_versions tv
  where tv.organization_id =
        '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and tv.status = 'published'
    and tv.archived_at is null;

  if v_published_versions <> 5 then
    raise exception 'UNEXPECTED_PUBLISHED_VERSION_COUNT_AFTER_PUBLICATION: %',
      v_published_versions;
  end if;

  select count(*)::integer
  into v_target_grants
  from private.assessment_test_access_grants access_grant
  where access_grant.organization_id =
        '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and access_grant.test_version_id = any (
      array[
        'd608e0c6-efc6-500c-9258-64a774b4b169'::uuid,
        'a68e7ffa-2c6e-5e95-9ab9-a0b3d9b307ef'::uuid,
        '22d2e41e-b5fc-5765-a1a8-edfde5c698ed'::uuid,
        '7004fc3c-a1e7-5e28-a66b-143d3bffb869'::uuid
      ]
    )
    and access_grant.access_scope = 'member'
    and access_grant.organization_member_id =
        '49239d09-0f85-471f-8f46-5c240cd98600'::uuid
    and access_grant.status = 'active'
    and access_grant.archived_at is null
    and access_grant.valid_from <= now()
    and (
      access_grant.valid_until is null
      or access_grant.valid_until > now()
    );

  if v_target_grants <> 4 then
    raise exception 'TARGET_PILOT_GRANT_COUNT_INVALID: %',
      v_target_grants;
  end if;

  select count(*)::integer
  into v_organization_grants
  from private.assessment_test_access_grants access_grant
  where access_grant.organization_id =
        '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and access_grant.test_version_id = any (
      array[
        'd608e0c6-efc6-500c-9258-64a774b4b169'::uuid,
        'a68e7ffa-2c6e-5e95-9ab9-a0b3d9b307ef'::uuid,
        '22d2e41e-b5fc-5765-a1a8-edfde5c698ed'::uuid,
        '7004fc3c-a1e7-5e28-a66b-143d3bffb869'::uuid
      ]
    )
    and access_grant.access_scope = 'organization'
    and access_grant.status = 'active'
    and access_grant.archived_at is null;

  if v_organization_grants <> 0 then
    raise exception 'TARGET_ORGANIZATION_GRANTS_MUST_REMAIN_ZERO: %',
      v_organization_grants;
  end if;

  for target_row in
    select *
    from (
      values
        (
          2,
          '99f4b9fe-66c2-591e-a670-064675a64650'::uuid,
          'd608e0c6-efc6-500c-9258-64a774b4b169'::uuid,
          true
        ),
        (
          3,
          '8a7754bc-7777-503c-a6aa-213b48f03f28'::uuid,
          'a68e7ffa-2c6e-5e95-9ab9-a0b3d9b307ef'::uuid,
          false
        ),
        (
          4,
          'c57f65fc-5084-501d-bbc1-b371d7fb5f02'::uuid,
          '22d2e41e-b5fc-5765-a1a8-edfde5c698ed'::uuid,
          false
        ),
        (
          5,
          'abe87462-d06b-5a84-8bc5-a4841bb17cb2'::uuid,
          '7004fc3c-a1e7-5e28-a66b-143d3bffb869'::uuid,
          false
        )
    ) as x(sequence_no, test_id, version_id, prerequisite_expected)
  loop
    if not exists (
      select 1
      from public.assessment_tests t
      join public.assessment_test_versions tv
        on tv.organization_id = t.organization_id
       and tv.test_id = t.id
       and tv.id = target_row.version_id
       and tv.status = 'published'
       and tv.published_at is not null
       and tv.valid_from is not null
       and tv.valid_from <= now()
       and tv.metadata ->> 'publication_phase' = '1E'
       and tv.archived_at is null
      where t.id = target_row.test_id
        and t.organization_id =
            '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
        and t.status = 'active'
        and t.metadata ->> 'publication_phase' = '1E'
        and t.archived_at is null
    ) then
      raise exception 'TARGET_PUBLICATION_FAILED_TEST_%',
        target_row.sequence_no;
    end if;

    if not private.assessment_test_access_allowed(
      '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
      '49239d09-0f85-471f-8f46-5c240cd98600'::uuid,
      target_row.test_id,
      target_row.version_id
    ) then
      raise exception 'TARGET_PILOT_ACCESS_NOT_ALLOWED_TEST_%',
        target_row.sequence_no;
    end if;

    if private.assessment_prerequisites_met(
      '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
      '49239d09-0f85-471f-8f46-5c240cd98600'::uuid,
      target_row.test_id
    ) is distinct from target_row.prerequisite_expected then
      raise exception 'TARGET_PREREQUISITE_STATE_CHANGED_TEST_%',
        target_row.sequence_no;
    end if;
  end loop;

  if exists (
    select 1
    from public.organization_members om
    cross join (
      values
        (
          '99f4b9fe-66c2-591e-a670-064675a64650'::uuid,
          'd608e0c6-efc6-500c-9258-64a774b4b169'::uuid
        ),
        (
          '8a7754bc-7777-503c-a6aa-213b48f03f28'::uuid,
          'a68e7ffa-2c6e-5e95-9ab9-a0b3d9b307ef'::uuid
        ),
        (
          'c57f65fc-5084-501d-bbc1-b371d7fb5f02'::uuid,
          '22d2e41e-b5fc-5765-a1a8-edfde5c698ed'::uuid
        ),
        (
          'abe87462-d06b-5a84-8bc5-a4841bb17cb2'::uuid,
          '7004fc3c-a1e7-5e28-a66b-143d3bffb869'::uuid
        )
    ) access_target(test_id, version_id)
    where om.organization_id =
          '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and om.id <>
          '49239d09-0f85-471f-8f46-5c240cd98600'::uuid
      and om.status = 'active'
      and om.archived_at is null
      and private.assessment_test_access_allowed(
        om.organization_id,
        om.id,
        access_target.test_id,
        access_target.version_id
      )
  ) then
    raise exception 'NON_PILOT_MEMBER_HAS_TARGET_ACCESS';
  end if;

  select count(*)::integer
  into v_target_attempts
  from public.assessment_attempts a
  where a.organization_id =
        '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and a.test_id = any (
      array[
        '99f4b9fe-66c2-591e-a670-064675a64650'::uuid,
        '8a7754bc-7777-503c-a6aa-213b48f03f28'::uuid,
        'c57f65fc-5084-501d-bbc1-b371d7fb5f02'::uuid,
        'abe87462-d06b-5a84-8bc5-a4841bb17cb2'::uuid
      ]
    )
    and a.archived_at is null;

  if v_target_attempts <> 0 then
    raise exception 'TARGET_ATTEMPTS_CREATED_UNEXPECTEDLY: %',
      v_target_attempts;
  end if;

  if not exists (
    select 1
    from public.assessment_attempts a
    where a.id = '72e1c6e0-2d62-47e3-85ec-6de2f4eaddbe'::uuid
      and a.organization_id =
          '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and a.organization_member_id =
          '49239d09-0f85-471f-8f46-5c240cd98600'::uuid
      and a.test_id = '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
      and a.test_version_id =
          'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
      and a.status = 'graded'
      and a.attempt_no = 1
      and a.total_questions = 30
      and a.answered_questions = 30
      and a.correct_answers = 29
      and a.overall_score = 96.67
      and a.legal_score = 100.00
      and a.archived_at is null
  ) then
    raise exception 'PILOT_DIAGNOSTIC_ATTEMPT_CHANGED';
  end if;

  select count(*)::integer
  into v_pilot_answers
  from public.assessment_attempt_answers answer
  where answer.organization_id =
        '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and answer.attempt_id =
        '72e1c6e0-2d62-47e3-85ec-6de2f4eaddbe'::uuid
    and answer.archived_at is null;

  if v_pilot_answers <> 30 then
    raise exception 'PILOT_DIAGNOSTIC_ANSWERS_CHANGED: %',
      v_pilot_answers;
  end if;

  select count(*)::integer
  into v_pilot_grades
  from private.assessment_attempt_grades grade
  where grade.organization_id =
        '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and grade.attempt_id =
        '72e1c6e0-2d62-47e3-85ec-6de2f4eaddbe'::uuid;

  if v_pilot_grades <> 30 then
    raise exception 'PILOT_DIAGNOSTIC_GRADES_CHANGED: %',
      v_pilot_grades;
  end if;

  if exists (
    select 1
    from public.member_certifications certification
    where certification.organization_id =
          '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and certification.organization_member_id =
          '49239d09-0f85-471f-8f46-5c240cd98600'::uuid
      and certification.archived_at is null
  ) then
    raise exception 'CERTIFICATION_CREATED_UNEXPECTEDLY';
  end if;
end;
$postconditions$;

commit;
