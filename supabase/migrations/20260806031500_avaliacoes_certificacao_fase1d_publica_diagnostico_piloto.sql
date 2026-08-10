-- ============================================================================
-- RF Performance — Avaliações e Certificações — Fase 1D
-- Publicação controlada do Teste 1 para homologação individual
--
-- Objetivos:
--   1. publicar somente o Teste 1 — Diagnóstico inicial;
--   2. manter o acesso restrito ao grant privado do Usuário Teste RF;
--   3. preservar os demais testes e versões em rascunho;
--   4. não criar tentativas, respostas, notas ou certificações.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- Preflight estrito
-- ----------------------------------------------------------------------------

do $preflight$
declare
  v_linked_questions integer;
  v_private_keys integer;
  v_critical_keys integer;
  v_attempts integer;
  v_active_member_grants integer;
  v_active_organization_grants integer;
begin
  if to_regclass('private.assessment_test_access_grants') is null then
    raise exception 'PILOT_ACCESS_TABLE_NOT_FOUND';
  end if;

  if to_regprocedure(
    'private.assessment_test_access_allowed(uuid,uuid,uuid,uuid)'
  ) is null then
    raise exception 'PILOT_ACCESS_HELPER_NOT_FOUND';
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
      and om.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and om.user_id = 'e88242b6-e44e-4de7-97cf-dbefc0605eaf'::uuid
      and om.role = 'salesperson'
      and om.status = 'active'
      and om.archived_at is null
  ) then
    raise exception 'PILOT_MEMBER_NOT_ACTIVE_OR_MISMATCHED';
  end if;

  if not exists (
    select 1
    from public.assessment_tests t
    where t.id = '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
      and t.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and t.sequence_no = 1
      and t.code = 'teste_1_diagnostico'
      and t.purpose = 'diagnostic'
      and t.status = 'draft'
      and t.max_attempts = 2
      and t.cooldown_hours = 24
      and t.archived_at is null
  ) then
    raise exception 'PILOT_TEST_PREFLIGHT_FAILED';
  end if;

  if not exists (
    select 1
    from public.assessment_test_versions tv
    where tv.id = 'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
      and tv.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and tv.test_id = '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
      and tv.version_code = '2026.08-v1'
      and tv.version_no = 1
      and tv.status = 'draft'
      and tv.question_count = 30
      and tv.passing_score = 60.00
      and tv.legal_min_score = 70.00
      and tv.randomize_questions = false
      and tv.randomize_options = true
      and tv.show_review_after_submit = true
      and tv.published_at is null
      and tv.archived_at is null
  ) then
    raise exception 'PILOT_VERSION_PREFLIGHT_FAILED';
  end if;

  select count(*)::integer
  into v_linked_questions
  from public.assessment_version_questions avq
  where avq.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and avq.test_version_id = 'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
    and avq.archived_at is null;

  if v_linked_questions <> 30 then
    raise exception 'PILOT_VERSION_QUESTION_COUNT_MISMATCH: %', v_linked_questions;
  end if;

  select
    count(*)::integer,
    count(*) filter (where aqk.is_critical)::integer
  into v_private_keys, v_critical_keys
  from public.assessment_version_questions avq
  join private.assessment_question_keys aqk
    on aqk.organization_id = avq.organization_id
   and aqk.question_id = avq.question_id
  where avq.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and avq.test_version_id = 'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
    and avq.archived_at is null;

  if v_private_keys <> 30 then
    raise exception 'PILOT_VERSION_PRIVATE_KEY_COUNT_MISMATCH: %', v_private_keys;
  end if;

  if v_critical_keys <> 0 then
    raise exception 'PILOT_CRITICAL_FAILURE_KEYS_MUST_REMAIN_DISABLED: %', v_critical_keys;
  end if;

  select count(*)::integer
  into v_attempts
  from public.assessment_attempts aa
  where aa.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and aa.test_id = '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
    and aa.archived_at is null;

  if v_attempts <> 0 then
    raise exception 'PILOT_TEST_ALREADY_HAS_ATTEMPTS: %', v_attempts;
  end if;

  select
    count(*) filter (
      where access_grant.access_scope = 'member'
        and access_grant.organization_member_id =
          '49239d09-0f85-471f-8f46-5c240cd98600'::uuid
    )::integer,
    count(*) filter (
      where access_grant.access_scope = 'organization'
    )::integer
  into v_active_member_grants, v_active_organization_grants
  from private.assessment_test_access_grants access_grant
  where access_grant.organization_id =
        '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and access_grant.test_id =
        '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
    and access_grant.test_version_id =
        'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
    and access_grant.status = 'active'
    and access_grant.archived_at is null
    and (access_grant.valid_from is null or access_grant.valid_from <= now())
    and (access_grant.valid_until is null or access_grant.valid_until > now());

  if v_active_member_grants <> 1 then
    raise exception 'PILOT_MEMBER_GRANT_COUNT_INVALID: %', v_active_member_grants;
  end if;

  if v_active_organization_grants <> 0 then
    raise exception 'PILOT_ORGANIZATION_GRANT_MUST_NOT_EXIST: %', v_active_organization_grants;
  end if;

  if not private.assessment_test_access_allowed(
    '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
    '49239d09-0f85-471f-8f46-5c240cd98600'::uuid,
    '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid,
    'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
  ) then
    raise exception 'PILOT_MEMBER_ACCESS_NOT_ALLOWED';
  end if;

  if exists (
    select 1
    from public.organization_members om
    where om.organization_id =
          '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and om.id <>
          '49239d09-0f85-471f-8f46-5c240cd98600'::uuid
      and om.status = 'active'
      and om.archived_at is null
      and private.assessment_test_access_allowed(
        om.organization_id,
        om.id,
        '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid,
        'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
      )
  ) then
    raise exception 'NON_PILOT_MEMBER_HAS_ACCESS';
  end if;
end;
$preflight$;

-- ----------------------------------------------------------------------------
-- Publicação controlada
-- ----------------------------------------------------------------------------

update public.assessment_tests
set status = 'active',
    updated_at = now(),
    updated_by = null,
    metadata = metadata || jsonb_build_object(
      'publication_phase', '1D',
      'publication_mode', 'individual_pilot',
      'pilot_organization_member_id',
        '49239d09-0f85-471f-8f46-5c240cd98600',
      'published_by_migration',
        '20260806031500_avaliacoes_certificacao_fase1d_publica_diagnostico_piloto'
    )
where id = '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and status = 'draft'
  and archived_at is null;

update public.assessment_test_versions
set status = 'published',
    valid_from = coalesce(valid_from, now()),
    published_at = coalesce(published_at, now()),
    updated_at = now(),
    updated_by = null,
    metadata = metadata || jsonb_build_object(
      'publication_status', 'pilot_published',
      'publication_phase', '1D',
      'publication_mode', 'individual_pilot',
      'pilot_organization_member_id',
        '49239d09-0f85-471f-8f46-5c240cd98600',
      'published_by_migration',
        '20260806031500_avaliacoes_certificacao_fase1d_publica_diagnostico_piloto'
    )
where id = 'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and test_id = '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
  and status = 'draft'
  and archived_at is null;

-- ----------------------------------------------------------------------------
-- Pós-condições
-- ----------------------------------------------------------------------------

do $postconditions$
declare
  v_published_tests integer;
  v_published_versions integer;
  v_attempts integer;
begin
  if not exists (
    select 1
    from public.assessment_tests t
    where t.id = '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
      and t.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and t.status = 'active'
      and t.archived_at is null
  ) then
    raise exception 'PILOT_TEST_PUBLICATION_FAILED';
  end if;

  if not exists (
    select 1
    from public.assessment_test_versions tv
    where tv.id = 'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
      and tv.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and tv.test_id = '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
      and tv.status = 'published'
      and tv.valid_from is not null
      and tv.valid_from <= now()
      and tv.published_at is not null
      and tv.archived_at is null
  ) then
    raise exception 'PILOT_VERSION_PUBLICATION_FAILED';
  end if;

  select count(*)::integer
  into v_published_tests
  from public.assessment_tests t
  where t.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and t.status = 'active'
    and t.archived_at is null;

  if v_published_tests <> 1 then
    raise exception 'UNEXPECTED_ACTIVE_TEST_COUNT: %', v_published_tests;
  end if;

  select count(*)::integer
  into v_published_versions
  from public.assessment_test_versions tv
  where tv.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and tv.status = 'published'
    and tv.archived_at is null;

  if v_published_versions <> 1 then
    raise exception 'UNEXPECTED_PUBLISHED_VERSION_COUNT: %', v_published_versions;
  end if;

  if exists (
    select 1
    from public.assessment_tests t
    where t.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and t.id <> '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
      and t.status <> 'draft'
      and t.archived_at is null
  ) then
    raise exception 'NON_PILOT_TEST_CHANGED_STATUS';
  end if;

  if exists (
    select 1
    from public.assessment_test_versions tv
    where tv.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and tv.id <> 'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
      and tv.status <> 'draft'
      and tv.archived_at is null
  ) then
    raise exception 'NON_PILOT_VERSION_CHANGED_STATUS';
  end if;

  if not private.assessment_test_access_allowed(
    '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
    '49239d09-0f85-471f-8f46-5c240cd98600'::uuid,
    '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid,
    'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
  ) then
    raise exception 'PILOT_ACCESS_LOST_AFTER_PUBLICATION';
  end if;

  if exists (
    select 1
    from public.organization_members om
    where om.organization_id =
          '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and om.id <>
          '49239d09-0f85-471f-8f46-5c240cd98600'::uuid
      and om.status = 'active'
      and om.archived_at is null
      and private.assessment_test_access_allowed(
        om.organization_id,
        om.id,
        '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid,
        'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
      )
  ) then
    raise exception 'NON_PILOT_ACCESS_ENABLED_AFTER_PUBLICATION';
  end if;

  select count(*)::integer
  into v_attempts
  from public.assessment_attempts aa
  where aa.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and aa.test_id = '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
    and aa.archived_at is null;

  if v_attempts <> 0 then
    raise exception 'PILOT_ATTEMPT_WAS_UNEXPECTEDLY_CREATED: %', v_attempts;
  end if;
end;
$postconditions$;

commit;
