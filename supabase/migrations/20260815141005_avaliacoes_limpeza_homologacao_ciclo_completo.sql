begin;

-- ============================================================
-- RF Performance
-- Limpeza controlada da homologação do ciclo completo
-- de avaliações.
--
-- Tentativa homologada:
--   2af775cf-3002-45ea-9425-2c131aa3baa0
--
-- Escopo:
--   Organização: 414a2e84-bc62-4c64-99ee-76db1cbc4654
--   Teste:       4bbd0f10-5444-5826-860b-aed020cb6acc
--   Versão:      fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4
--   Membro:      49239d09-0f85-471f-8f46-5c240cd98600
--
-- Esta migration remove exclusivamente dados gerados durante
-- a homologação controlada realizada em 15/08/2026.
-- ============================================================


-- ============================================================
-- 1. PRECONDIÇÕES
-- Aborta a transação se o banco não estiver exatamente no
-- estado esperado antes da limpeza.
-- ============================================================

do $$
declare
  v_attempts integer;
  v_attempt_items integer;
  v_answers integer;
  v_grades integer;
  v_competency_scores integer;
  v_certifications integer;
  v_active_grants integer;
  v_revoked_grants integer;
begin
  select count(*)
    into v_attempts
  from public.assessment_attempts a
  where a.id = '2af775cf-3002-45ea-9425-2c131aa3baa0'::uuid
    and a.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and a.organization_member_id = '49239d09-0f85-471f-8f46-5c240cd98600'::uuid
    and a.test_version_id = 'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
    and a.status = 'graded'
    and a.archived_at is null;

  select count(*)
    into v_attempt_items
  from public.assessment_attempt_items
  where attempt_id = '2af775cf-3002-45ea-9425-2c131aa3baa0'::uuid;

  select count(*)
    into v_answers
  from public.assessment_attempt_answers
  where attempt_id = '2af775cf-3002-45ea-9425-2c131aa3baa0'::uuid;

  select count(*)
    into v_grades
  from private.assessment_attempt_grades
  where attempt_id = '2af775cf-3002-45ea-9425-2c131aa3baa0'::uuid;

  select count(*)
    into v_competency_scores
  from public.assessment_competency_scores
  where attempt_id = '2af775cf-3002-45ea-9425-2c131aa3baa0'::uuid;

  select count(*)
    into v_certifications
  from public.member_certifications
  where source_attempt_id = '2af775cf-3002-45ea-9425-2c131aa3baa0'::uuid;

  select count(*)
    into v_active_grants
  from private.assessment_test_access_grants g
  where g.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and g.test_id = '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
    and g.test_version_id = 'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
    and g.organization_member_id = '49239d09-0f85-471f-8f46-5c240cd98600'::uuid
    and g.access_scope = 'member'
    and g.status = 'active'
    and g.archived_at is null;

  select count(*)
    into v_revoked_grants
  from private.assessment_test_access_grants g
  where g.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and g.test_id = '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
    and g.test_version_id = 'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
    and g.organization_member_id = '49239d09-0f85-471f-8f46-5c240cd98600'::uuid
    and g.access_scope = 'member'
    and g.status = 'revoked'
    and g.archived_at is null;

  if v_attempts <> 1 then
    raise exception
      'CLEANUP_ABORTED: expected 1 graded homologation attempt, found %',
      v_attempts;
  end if;

  if v_attempt_items <> 30 then
    raise exception
      'CLEANUP_ABORTED: expected 30 attempt items, found %',
      v_attempt_items;
  end if;

  if v_answers <> 30 then
    raise exception
      'CLEANUP_ABORTED: expected 30 answers, found %',
      v_answers;
  end if;

  if v_grades <> 30 then
    raise exception
      'CLEANUP_ABORTED: expected 30 grade records, found %',
      v_grades;
  end if;

  if v_competency_scores <> 5 then
    raise exception
      'CLEANUP_ABORTED: expected 5 competency scores, found %',
      v_competency_scores;
  end if;

  if v_certifications <> 0 then
    raise exception
      'CLEANUP_ABORTED: expected 0 certifications for diagnostic test, found %',
      v_certifications;
  end if;

  if v_active_grants <> 0 then
    raise exception
      'CLEANUP_ABORTED: expected 0 active grants, found %',
      v_active_grants;
  end if;

  if v_revoked_grants <> 1 then
    raise exception
      'CLEANUP_ABORTED: expected exactly 1 revoked homologation grant, found %',
      v_revoked_grants;
  end if;
end;
$$;


-- ============================================================
-- 2. LIMPEZA DAS DEPENDÊNCIAS DA TENTATIVA
-- Ordem deliberadamente explícita.
-- ============================================================

delete from public.member_certifications
where source_attempt_id =
  '2af775cf-3002-45ea-9425-2c131aa3baa0'::uuid;


delete from public.assessment_competency_scores
where attempt_id =
  '2af775cf-3002-45ea-9425-2c131aa3baa0'::uuid;


delete from private.assessment_attempt_grades
where attempt_id =
  '2af775cf-3002-45ea-9425-2c131aa3baa0'::uuid;


delete from public.assessment_attempt_answers
where attempt_id =
  '2af775cf-3002-45ea-9425-2c131aa3baa0'::uuid;


delete from public.assessment_attempt_items
where attempt_id =
  '2af775cf-3002-45ea-9425-2c131aa3baa0'::uuid;


delete from public.assessment_attempts
where id =
  '2af775cf-3002-45ea-9425-2c131aa3baa0'::uuid
  and organization_id =
    '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and organization_member_id =
    '49239d09-0f85-471f-8f46-5c240cd98600'::uuid
  and test_version_id =
    'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid;


-- ============================================================
-- 3. REMOVE SOMENTE O GRANT REVOGADO DESTA HOMOLOGAÇÃO
-- ============================================================

delete from private.assessment_test_access_grants
where organization_id =
    '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and test_id =
    '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
  and test_version_id =
    'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
  and organization_member_id =
    '49239d09-0f85-471f-8f46-5c240cd98600'::uuid
  and access_scope = 'member'
  and status = 'revoked'
  and archived_at is null;


-- ============================================================
-- 4. PÓS-CONDIÇÕES
-- Nada pertencente à homologação pode permanecer.
-- ============================================================

do $$
declare
  v_attempts integer;
  v_attempt_items integer;
  v_answers integer;
  v_grades integer;
  v_competency_scores integer;
  v_certifications integer;
  v_matching_grants integer;
begin
  select count(*)
    into v_attempts
  from public.assessment_attempts
  where id = '2af775cf-3002-45ea-9425-2c131aa3baa0'::uuid;

  select count(*)
    into v_attempt_items
  from public.assessment_attempt_items
  where attempt_id = '2af775cf-3002-45ea-9425-2c131aa3baa0'::uuid;

  select count(*)
    into v_answers
  from public.assessment_attempt_answers
  where attempt_id = '2af775cf-3002-45ea-9425-2c131aa3baa0'::uuid;

  select count(*)
    into v_grades
  from private.assessment_attempt_grades
  where attempt_id = '2af775cf-3002-45ea-9425-2c131aa3baa0'::uuid;

  select count(*)
    into v_competency_scores
  from public.assessment_competency_scores
  where attempt_id = '2af775cf-3002-45ea-9425-2c131aa3baa0'::uuid;

  select count(*)
    into v_certifications
  from public.member_certifications
  where source_attempt_id = '2af775cf-3002-45ea-9425-2c131aa3baa0'::uuid;

  select count(*)
    into v_matching_grants
  from private.assessment_test_access_grants g
  where g.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and g.test_id = '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
    and g.test_version_id = 'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
    and g.organization_member_id = '49239d09-0f85-471f-8f46-5c240cd98600'::uuid
    and g.access_scope = 'member'
    and g.status in ('active', 'revoked')
    and g.archived_at is null;

  if v_attempts <> 0
     or v_attempt_items <> 0
     or v_answers <> 0
     or v_grades <> 0
     or v_competency_scores <> 0
     or v_certifications <> 0
     or v_matching_grants <> 0
  then
    raise exception
      'CLEANUP_POSTCONDITION_FAILED: attempts=%, items=%, answers=%, grades=%, competency_scores=%, certifications=%, matching_grants=%',
      v_attempts,
      v_attempt_items,
      v_answers,
      v_grades,
      v_competency_scores,
      v_certifications,
      v_matching_grants;
  end if;
end;
$$;

commit;