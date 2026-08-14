begin;

do $cleanup$
declare
  v_organization_id constant uuid :=
    '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;

  v_attempt_id constant uuid :=
    '00d82e8a-bb59-4070-9e33-7babb82283c5'::uuid;

  v_member_id constant uuid :=
    '860bbe25-34fa-4e62-8106-500f14e19d46'::uuid;

  v_test_id constant uuid :=
    '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid;

  v_test_version_id constant uuid :=
    'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid;

  v_count integer;
begin
  -- --------------------------------------------------------------------------
  -- Preflight: a tentativa deve ser exatamente a criada nesta homologação.
  -- --------------------------------------------------------------------------

  select count(*)
  into v_count
  from public.assessment_attempts a
  where a.id = v_attempt_id
    and a.organization_id = v_organization_id
    and a.organization_member_id = v_member_id
    and a.test_id = v_test_id
    and a.test_version_id = v_test_version_id
    and a.status = 'in_progress'
    and a.archived_at is null;

  if v_count <> 1 then
    raise exception
      'ADMIN_RELEASE_CLEANUP_PREFLIGHT_FAILED: expected exactly 1 in_progress target attempt, found %',
      v_count;
  end if;

  select count(*)
  into v_count
  from public.assessment_attempt_answers aa
  where aa.organization_id = v_organization_id
    and aa.attempt_id = v_attempt_id;

  if v_count <> 0 then
    raise exception
      'ADMIN_RELEASE_CLEANUP_PREFLIGHT_FAILED: target attempt has % answer(s)',
      v_count;
  end if;

  select count(*)
  into v_count
  from public.assessment_attempt_items ai
  where ai.organization_id = v_organization_id
    and ai.attempt_id = v_attempt_id;

  if v_count <> 30 then
    raise exception
      'ADMIN_RELEASE_CLEANUP_PREFLIGHT_FAILED: expected 30 attempt items, found %',
      v_count;
  end if;

  select count(*)
  into v_count
  from public.assessment_competency_scores cs
  where cs.organization_id = v_organization_id
    and cs.attempt_id = v_attempt_id;

  if v_count <> 0 then
    raise exception
      'ADMIN_RELEASE_CLEANUP_PREFLIGHT_FAILED: competency scores unexpectedly exist';
  end if;

  select count(*)
  into v_count
  from private.assessment_attempt_grades ag
  where ag.organization_id = v_organization_id
    and ag.attempt_id = v_attempt_id;

  if v_count <> 0 then
    raise exception
      'ADMIN_RELEASE_CLEANUP_PREFLIGHT_FAILED: grades unexpectedly exist';
  end if;

  select count(*)
  into v_count
  from public.member_certifications mc
  where mc.organization_id = v_organization_id
    and mc.source_attempt_id = v_attempt_id;

  if v_count <> 0 then
    raise exception
      'ADMIN_RELEASE_CLEANUP_PREFLIGHT_FAILED: certification unexpectedly exists';
  end if;

  -- O grant utilizado no teste já deve ter sido revogado pela interface.
  if exists (
    select 1
    from private.assessment_test_access_grants g
    where g.organization_id = v_organization_id
      and g.test_id = v_test_id
      and g.test_version_id = v_test_version_id
      and g.access_scope = 'member'
      and g.organization_member_id = v_member_id
      and g.status = 'active'
      and g.archived_at is null
      and g.metadata ->> 'source' = 'assessment_admin_ui'
  ) then
    raise exception
      'ADMIN_RELEASE_CLEANUP_PREFLIGHT_FAILED: target admin grant is still active';
  end if;

  select count(*)
  into v_count
  from private.assessment_test_access_grants g
  where g.organization_id = v_organization_id
    and g.test_id = v_test_id
    and g.test_version_id = v_test_version_id
    and g.access_scope = 'member'
    and g.organization_member_id = v_member_id
    and g.status = 'revoked'
    and g.archived_at is null
    and g.metadata ->> 'source' = 'assessment_admin_ui';

  if v_count <> 1 then
    raise exception
      'ADMIN_RELEASE_CLEANUP_PREFLIGHT_FAILED: expected exactly 1 revoked admin grant, found %',
      v_count;
  end if;

  -- --------------------------------------------------------------------------
  -- Limpeza controlada.
  -- Mesma ordem de dependências usada na limpeza de homologação anterior.
  -- --------------------------------------------------------------------------

  delete from public.assessment_attempt_answers
  where organization_id = v_organization_id
    and attempt_id = v_attempt_id;

  delete from public.assessment_competency_scores
  where organization_id = v_organization_id
    and attempt_id = v_attempt_id;

  delete from private.assessment_attempt_grades
  where organization_id = v_organization_id
    and attempt_id = v_attempt_id;

  delete from public.member_certifications
  where organization_id = v_organization_id
    and source_attempt_id = v_attempt_id;

  delete from public.assessment_attempt_items
  where organization_id = v_organization_id
    and attempt_id = v_attempt_id;

  delete from public.assessment_attempts
  where organization_id = v_organization_id
    and id = v_attempt_id;

  delete from private.assessment_test_access_grants g
  where g.organization_id = v_organization_id
    and g.test_id = v_test_id
    and g.test_version_id = v_test_version_id
    and g.access_scope = 'member'
    and g.organization_member_id = v_member_id
    and g.status = 'revoked'
    and g.archived_at is null
    and g.metadata ->> 'source' = 'assessment_admin_ui';

  -- --------------------------------------------------------------------------
  -- Pós-condições.
  -- --------------------------------------------------------------------------

  if exists (
    select 1
    from public.assessment_attempts a
    where a.id = v_attempt_id
  ) then
    raise exception
      'ADMIN_RELEASE_CLEANUP_POSTCONDITION_FAILED: target attempt remained';
  end if;

  if exists (
    select 1
    from public.assessment_attempt_items ai
    where ai.attempt_id = v_attempt_id
  ) then
    raise exception
      'ADMIN_RELEASE_CLEANUP_POSTCONDITION_FAILED: target items remained';
  end if;

  if exists (
    select 1
    from private.assessment_test_access_grants g
    where g.organization_id = v_organization_id
      and g.test_id = v_test_id
      and g.test_version_id = v_test_version_id
      and g.access_scope = 'member'
      and g.organization_member_id = v_member_id
      and g.metadata ->> 'source' = 'assessment_admin_ui'
  ) then
    raise exception
      'ADMIN_RELEASE_CLEANUP_POSTCONDITION_FAILED: target admin grant remained';
  end if;
end;
$cleanup$;

commit;