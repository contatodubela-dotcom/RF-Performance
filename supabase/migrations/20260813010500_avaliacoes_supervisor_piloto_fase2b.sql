-- ============================================================================
-- RF Performance
-- Fase 2B — libera avaliações próprias para o Supervisor teste (piloto)
--
-- Escopo:
--   - somente RF Consórcios
--   - somente membership do Supervisor teste
--   - somente versões 2026.08-v1 dos Testes 1 a 5
--
-- Não altera tentativas, notas, respostas, gabaritos, equipes ou RLS.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- Preflight: estrutura esperada
-- ----------------------------------------------------------------------------

do $preflight$
declare
  v_org_id constant uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
  v_supervisor_member_id constant uuid := '698c805e-c594-42ff-9ee5-f042d3c0f75c'::uuid;
  v_supervisor_user_id constant uuid := 'df51101f-34cd-4edb-bfde-373c25d83bc2'::uuid;
  v_target_count integer;
  v_existing_grants integer;
  v_existing_ids integer;
  v_existing_attempts integer;
begin
  if to_regclass('private.assessment_test_access_grants') is null then
    raise exception 'PHASE2B_PREFLIGHT_FAILED: private.assessment_test_access_grants missing';
  end if;

  if not exists (
    select 1
    from public.organizations o
    where o.id = v_org_id
      and o.status = 'active'
      and o.archived_at is null
  ) then
    raise exception 'PHASE2B_PREFLIGHT_FAILED: target organization is not active';
  end if;

  if not exists (
    select 1
    from public.organization_members om
    join public.profiles p
      on p.id = om.user_id
     and p.status = 'active'
     and p.archived_at is null
    where om.id = v_supervisor_member_id
      and om.organization_id = v_org_id
      and om.user_id = v_supervisor_user_id
      and om.role = 'supervisor'
      and om.status = 'active'
      and om.archived_at is null
  ) then
    raise exception 'PHASE2B_PREFLIGHT_FAILED: Supervisor teste membership mismatch/inactive';
  end if;

  with targets(sequence_no, test_id, version_id) as (
    values
      (1, '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid, 'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid),
      (2, '99f4b9fe-66c2-591e-a670-064675a64650'::uuid, 'd608e0c6-efc6-500c-9258-64a774b4b169'::uuid),
      (3, '8a7754bc-7777-503c-a6aa-213b48f03f28'::uuid, 'a68e7ffa-2c6e-5e95-9ab9-a0b3d9b307ef'::uuid),
      (4, 'c57f65fc-5084-501d-bbc1-b371d7fb5f02'::uuid, '22d2e41e-b5fc-5765-a1a8-edfde5c698ed'::uuid),
      (5, 'abe87462-d06b-5a84-8bc5-a4841bb17cb2'::uuid, '7004fc3c-a1e7-5e28-a66b-143d3bffb869'::uuid)
  )
  select count(*)::integer
    into v_target_count
  from targets x
  join public.assessment_tests t
    on t.id = x.test_id
   and t.organization_id = v_org_id
   and t.sequence_no = x.sequence_no
   and t.status = 'active'
   and t.archived_at is null
  join public.assessment_test_versions tv
    on tv.id = x.version_id
   and tv.organization_id = v_org_id
   and tv.test_id = t.id
   and tv.version_code = '2026.08-v1'
   and tv.status = 'published'
   and tv.archived_at is null
   and (tv.valid_from is null or tv.valid_from <= now())
   and (tv.valid_until is null or tv.valid_until >= now());

  if v_target_count <> 5 then
    raise exception 'PHASE2B_PREFLIGHT_FAILED: expected 5 active/published target tests, got %', v_target_count;
  end if;

  with target_versions(version_id) as (
    values
      ('fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid),
      ('d608e0c6-efc6-500c-9258-64a774b4b169'::uuid),
      ('a68e7ffa-2c6e-5e95-9ab9-a0b3d9b307ef'::uuid),
      ('22d2e41e-b5fc-5765-a1a8-edfde5c698ed'::uuid),
      ('7004fc3c-a1e7-5e28-a66b-143d3bffb869'::uuid)
  )
  select count(*)::integer
    into v_existing_grants
  from private.assessment_test_access_grants g
  join target_versions x
    on x.version_id = g.test_version_id
  where g.organization_id = v_org_id
    and g.access_scope = 'member'
    and g.organization_member_id = v_supervisor_member_id
    and g.status = 'active'
    and g.archived_at is null;

  if v_existing_grants <> 0 then
    raise exception 'PHASE2B_PREFLIGHT_FAILED: supervisor already has % active target grant(s)', v_existing_grants;
  end if;

  select count(*)::integer
    into v_existing_ids
  from private.assessment_test_access_grants g
  where g.id = any(array[
    '8f2553ac-9710-52e5-96d1-817cf836134b'::uuid,
    'c5df038b-6e54-5250-ad77-94837ff7486d'::uuid,
    '0ce84a28-aeb3-5cbb-a560-2e5ca295378e'::uuid,
    'e266716c-b90e-5526-a9cb-03a714823bd3'::uuid,
    '98cd8c18-108c-522c-b8db-6e167003ce45'::uuid
  ]);

  if v_existing_ids <> 0 then
    raise exception 'PHASE2B_PREFLIGHT_FAILED: reserved grant ids already exist: %', v_existing_ids;
  end if;

  select count(*)::integer
    into v_existing_attempts
  from public.assessment_attempts a
  where a.organization_id = v_org_id
    and a.organization_member_id = v_supervisor_member_id
    and a.test_version_id = any(array[
      'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid,
      'd608e0c6-efc6-500c-9258-64a774b4b169'::uuid,
      'a68e7ffa-2c6e-5e95-9ab9-a0b3d9b307ef'::uuid,
      '22d2e41e-b5fc-5765-a1a8-edfde5c698ed'::uuid,
      '7004fc3c-a1e7-5e28-a66b-143d3bffb869'::uuid
    ])
    and a.archived_at is null;

  if v_existing_attempts <> 0 then
    raise exception 'PHASE2B_PREFLIGHT_FAILED: supervisor unexpectedly already has % target attempt(s)', v_existing_attempts;
  end if;
end;
$preflight$;

-- ----------------------------------------------------------------------------
-- Grants individuais do piloto do supervisor
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
    '8f2553ac-9710-52e5-96d1-817cf836134b'::uuid,
    '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
    '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid,
    'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid,
    'member',
    '698c805e-c594-42ff-9ee5-f042d3c0f75c'::uuid,
    'active',
    now(),
    null,
    'Piloto Fase 2B: avaliação própria do Supervisor teste — Teste 1.',
    null,
    null,
    jsonb_build_object(
      'phase', '2B',
      'pilot', true,
      'participant_role', 'supervisor',
      'test_number', 1,
      'pilot_user_id', 'df51101f-34cd-4edb-bfde-373c25d83bc2',
      'pilot_email', 'ometodovap@gmail.com',
      'migration', '20260813010500_avaliacoes_supervisor_piloto_fase2b'
    )
  ),
  (
    'c5df038b-6e54-5250-ad77-94837ff7486d'::uuid,
    '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
    '99f4b9fe-66c2-591e-a670-064675a64650'::uuid,
    'd608e0c6-efc6-500c-9258-64a774b4b169'::uuid,
    'member',
    '698c805e-c594-42ff-9ee5-f042d3c0f75c'::uuid,
    'active',
    now(),
    null,
    'Piloto Fase 2B: avaliação própria do Supervisor teste — Teste 2.',
    null,
    null,
    jsonb_build_object(
      'phase', '2B',
      'pilot', true,
      'participant_role', 'supervisor',
      'test_number', 2,
      'pilot_user_id', 'df51101f-34cd-4edb-bfde-373c25d83bc2',
      'pilot_email', 'ometodovap@gmail.com',
      'migration', '20260813010500_avaliacoes_supervisor_piloto_fase2b'
    )
  ),
  (
    '0ce84a28-aeb3-5cbb-a560-2e5ca295378e'::uuid,
    '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
    '8a7754bc-7777-503c-a6aa-213b48f03f28'::uuid,
    'a68e7ffa-2c6e-5e95-9ab9-a0b3d9b307ef'::uuid,
    'member',
    '698c805e-c594-42ff-9ee5-f042d3c0f75c'::uuid,
    'active',
    now(),
    null,
    'Piloto Fase 2B: avaliação própria do Supervisor teste — Teste 3.',
    null,
    null,
    jsonb_build_object(
      'phase', '2B',
      'pilot', true,
      'participant_role', 'supervisor',
      'test_number', 3,
      'pilot_user_id', 'df51101f-34cd-4edb-bfde-373c25d83bc2',
      'pilot_email', 'ometodovap@gmail.com',
      'migration', '20260813010500_avaliacoes_supervisor_piloto_fase2b'
    )
  ),
  (
    'e266716c-b90e-5526-a9cb-03a714823bd3'::uuid,
    '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
    'c57f65fc-5084-501d-bbc1-b371d7fb5f02'::uuid,
    '22d2e41e-b5fc-5765-a1a8-edfde5c698ed'::uuid,
    'member',
    '698c805e-c594-42ff-9ee5-f042d3c0f75c'::uuid,
    'active',
    now(),
    null,
    'Piloto Fase 2B: avaliação própria do Supervisor teste — Teste 4.',
    null,
    null,
    jsonb_build_object(
      'phase', '2B',
      'pilot', true,
      'participant_role', 'supervisor',
      'test_number', 4,
      'pilot_user_id', 'df51101f-34cd-4edb-bfde-373c25d83bc2',
      'pilot_email', 'ometodovap@gmail.com',
      'migration', '20260813010500_avaliacoes_supervisor_piloto_fase2b'
    )
  ),
  (
    '98cd8c18-108c-522c-b8db-6e167003ce45'::uuid,
    '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
    'abe87462-d06b-5a84-8bc5-a4841bb17cb2'::uuid,
    '7004fc3c-a1e7-5e28-a66b-143d3bffb869'::uuid,
    'member',
    '698c805e-c594-42ff-9ee5-f042d3c0f75c'::uuid,
    'active',
    now(),
    null,
    'Piloto Fase 2B: avaliação própria do Supervisor teste — Teste 5.',
    null,
    null,
    jsonb_build_object(
      'phase', '2B',
      'pilot', true,
      'participant_role', 'supervisor',
      'test_number', 5,
      'pilot_user_id', 'df51101f-34cd-4edb-bfde-373c25d83bc2',
      'pilot_email', 'ometodovap@gmail.com',
      'migration', '20260813010500_avaliacoes_supervisor_piloto_fase2b'
    )
  );

-- ----------------------------------------------------------------------------
-- Pós-condições
-- ----------------------------------------------------------------------------

do $postconditions$
declare
  v_org_id constant uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
  v_supervisor_member_id constant uuid := '698c805e-c594-42ff-9ee5-f042d3c0f75c'::uuid;
  v_active_grants integer;
  v_allowed integer;
  v_attempts integer;
begin
  with target_versions(version_id) as (
    values
      ('fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid),
      ('d608e0c6-efc6-500c-9258-64a774b4b169'::uuid),
      ('a68e7ffa-2c6e-5e95-9ab9-a0b3d9b307ef'::uuid),
      ('22d2e41e-b5fc-5765-a1a8-edfde5c698ed'::uuid),
      ('7004fc3c-a1e7-5e28-a66b-143d3bffb869'::uuid)
  )
  select count(*)::integer
    into v_active_grants
  from private.assessment_test_access_grants g
  join target_versions x
    on x.version_id = g.test_version_id
  where g.organization_id = v_org_id
    and g.access_scope = 'member'
    and g.organization_member_id = v_supervisor_member_id
    and g.status = 'active'
    and g.archived_at is null;

  if v_active_grants <> 5 then
    raise exception 'PHASE2B_POSTCONDITION_FAILED: expected 5 active supervisor grants, got %', v_active_grants;
  end if;

  with targets(test_id, version_id) as (
    values
      ('4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid, 'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid),
      ('99f4b9fe-66c2-591e-a670-064675a64650'::uuid, 'd608e0c6-efc6-500c-9258-64a774b4b169'::uuid),
      ('8a7754bc-7777-503c-a6aa-213b48f03f28'::uuid, 'a68e7ffa-2c6e-5e95-9ab9-a0b3d9b307ef'::uuid),
      ('c57f65fc-5084-501d-bbc1-b371d7fb5f02'::uuid, '22d2e41e-b5fc-5765-a1a8-edfde5c698ed'::uuid),
      ('abe87462-d06b-5a84-8bc5-a4841bb17cb2'::uuid, '7004fc3c-a1e7-5e28-a66b-143d3bffb869'::uuid)
  )
  select count(*)::integer
    into v_allowed
  from targets x
  where private.assessment_test_access_allowed(
    v_org_id,
    v_supervisor_member_id,
    x.test_id,
    x.version_id
  );

  if v_allowed <> 5 then
    raise exception 'PHASE2B_POSTCONDITION_FAILED: access helper allowed % of 5 target tests', v_allowed;
  end if;

  select count(*)::integer
    into v_attempts
  from public.assessment_attempts a
  where a.organization_id = v_org_id
    and a.organization_member_id = v_supervisor_member_id
    and a.test_version_id = any(array[
      'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid,
      'd608e0c6-efc6-500c-9258-64a774b4b169'::uuid,
      'a68e7ffa-2c6e-5e95-9ab9-a0b3d9b307ef'::uuid,
      '22d2e41e-b5fc-5765-a1a8-edfde5c698ed'::uuid,
      '7004fc3c-a1e7-5e28-a66b-143d3bffb869'::uuid
    ])
    and a.archived_at is null;

  if v_attempts <> 0 then
    raise exception 'PHASE2B_POSTCONDITION_FAILED: migration unexpectedly created attempt(s): %', v_attempts;
  end if;
end;
$postconditions$;

commit;
