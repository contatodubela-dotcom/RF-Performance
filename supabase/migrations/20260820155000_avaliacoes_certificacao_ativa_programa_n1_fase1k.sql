-- RF Performance
-- Fase 1K — Ativação controlada do programa de certificação Nível 1
--
-- Objetivo:
--   Ativar SOMENTE o programa "Vendedor Nível 1 - Fundamentos de Consórcio"
--   e sua versão 2026.08-v1, preservando auto_issue = false.
--
-- Motivo:
--   O motor genérico de certificações separa requisitos_satisfied de
--   eligible_for_issuance. A emissão só é elegível quando programa e versão
--   estão ativos. Os requisitos e a emissão autorizada já existem; esta
--   migration não emite certificação e não altera Nível 2/Nível 3.

begin;

-- ============================================================================
-- 1. Guardas / preflight fail-closed
-- ============================================================================

do $preflight$
declare
  v_org_id constant uuid := '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;
  v_program_id constant uuid := '5c512294-f6a9-4d8a-a67f-155aa6c3e8e1'::uuid;
  v_version_id constant uuid := '91b4a77b-6669-45f9-8fc6-041a6fae69fd'::uuid;

  v_program public.certification_programs%rowtype;
  v_version public.certification_program_versions%rowtype;
  v_required_count integer;
begin
  select p.*
    into v_program
  from public.certification_programs p
  where p.id = v_program_id
    and p.organization_id = v_org_id;

  if not found then
    raise exception 'N1_ACTIVATION_PRECONDITION_FAILED: certification program not found';
  end if;

  if v_program.code <> 'nivel_1_vendedor'
     or v_program.archived_at is not null
     or v_program.status not in ('draft', 'active') then
    raise exception
      'N1_ACTIVATION_PRECONDITION_FAILED: unexpected program state (code=%, status=%, archived_at=%)',
      v_program.code,
      v_program.status,
      v_program.archived_at;
  end if;

  select pv.*
    into v_version
  from public.certification_program_versions pv
  where pv.id = v_version_id
    and pv.organization_id = v_org_id
    and pv.certification_program_id = v_program_id;

  if not found then
    raise exception 'N1_ACTIVATION_PRECONDITION_FAILED: certification program version not found';
  end if;

  if v_version.version_code <> '2026.08-v1'
     or v_version.archived_at is not null
     or v_version.status not in ('draft', 'active')
     or v_version.auto_issue is not false then
    raise exception
      'N1_ACTIVATION_PRECONDITION_FAILED: unexpected version state (version_code=%, status=%, auto_issue=%, archived_at=%)',
      v_version.version_code,
      v_version.status,
      v_version.auto_issue,
      v_version.archived_at;
  end if;

  select count(*)::integer
    into v_required_count
  from public.certification_requirements r
  where r.organization_id = v_org_id
    and r.certification_program_version_id = v_version_id
    and r.is_required = true
    and r.archived_at is null;

  if v_required_count <> 3 then
    raise exception
      'N1_ACTIVATION_PRECONDITION_FAILED: expected 3 required N1 requirements, found %',
      v_required_count;
  end if;

  if not exists (
    select 1
    from public.certification_requirements r
    where r.id = 'beaae4a1-a1dd-4907-8060-c6e88ce4b3d9'::uuid
      and r.organization_id = v_org_id
      and r.certification_program_version_id = v_version_id
      and r.requirement_type = 'assessment_graded'
      and r.assessment_test_version_id = 'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
      and r.is_required = true
      and r.archived_at is null
  ) then
    raise exception 'N1_ACTIVATION_PRECONDITION_FAILED: Teste 1 requirement mismatch';
  end if;

  if not exists (
    select 1
    from public.certification_requirements r
    where r.id = 'b4996106-098e-47c1-b74e-8812097d384c'::uuid
      and r.organization_id = v_org_id
      and r.certification_program_version_id = v_version_id
      and r.requirement_type = 'assessment_passed'
      and r.assessment_test_version_id = 'd608e0c6-efc6-500c-9258-64a774b4b169'::uuid
      and r.minimum_score = 70
      and r.minimum_legal_score = 80
      and r.is_required = true
      and r.archived_at is null
  ) then
    raise exception 'N1_ACTIVATION_PRECONDITION_FAILED: Teste 2 requirement mismatch';
  end if;

  if not exists (
    select 1
    from public.certification_requirements r
    where r.id = 'eb3b8963-df29-464b-8dd3-ad3b737267d8'::uuid
      and r.organization_id = v_org_id
      and r.certification_program_version_id = v_version_id
      and r.requirement_type = 'practical_assessment_passed'
      and r.minimum_score = 65
      and r.max_critical_errors = 0
      and r.requirement_config ->> 'assessment_type' = 'role_play'
      and r.is_required = true
      and r.archived_at is null
  ) then
    raise exception 'N1_ACTIVATION_PRECONDITION_FAILED: role-play requirement mismatch';
  end if;
end;
$preflight$;

-- ============================================================================
-- 2. Ativação do programa N1
-- ============================================================================

update public.certification_programs
set
  status = 'active',
  updated_at = now(),
  metadata = coalesce(metadata, '{}'::jsonb)
    || jsonb_build_object(
         'activation_phase', '1K',
         'activation_reason', 'homologacao_operacional_n1'
       )
where id = '5c512294-f6a9-4d8a-a67f-155aa6c3e8e1'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and status = 'draft'
  and archived_at is null;

-- ============================================================================
-- 3. Ativação da versão N1, SEM emissão automática
-- ============================================================================

update public.certification_program_versions
set
  status = 'active',
  auto_issue = false,
  published_at = coalesce(published_at, now()),
  valid_from = coalesce(valid_from, now()),
  updated_at = now(),
  metadata = coalesce(metadata, '{}'::jsonb)
    || jsonb_build_object(
         'activation_phase', '1K',
         'activation_reason', 'homologacao_operacional_n1'
       )
where id = '91b4a77b-6669-45f9-8fc6-041a6fae69fd'::uuid
  and organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and certification_program_id = '5c512294-f6a9-4d8a-a67f-155aa6c3e8e1'::uuid
  and status = 'draft'
  and archived_at is null;

-- ============================================================================
-- 4. Pós-condições
-- ============================================================================

do $postcondition$
declare
  v_program_status text;
  v_version_status text;
  v_auto_issue boolean;
  v_published_at timestamptz;
  v_valid_from timestamptz;
begin
  select p.status
    into v_program_status
  from public.certification_programs p
  where p.id = '5c512294-f6a9-4d8a-a67f-155aa6c3e8e1'::uuid
    and p.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and p.archived_at is null;

  select pv.status, pv.auto_issue, pv.published_at, pv.valid_from
    into v_version_status, v_auto_issue, v_published_at, v_valid_from
  from public.certification_program_versions pv
  where pv.id = '91b4a77b-6669-45f9-8fc6-041a6fae69fd'::uuid
    and pv.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and pv.certification_program_id = '5c512294-f6a9-4d8a-a67f-155aa6c3e8e1'::uuid
    and pv.archived_at is null;

  if v_program_status <> 'active' then
    raise exception
      'N1_ACTIVATION_POSTCONDITION_FAILED: program status is %',
      coalesce(v_program_status, '<missing>');
  end if;

  if v_version_status <> 'active' then
    raise exception
      'N1_ACTIVATION_POSTCONDITION_FAILED: version status is %',
      coalesce(v_version_status, '<missing>');
  end if;

  if v_auto_issue is not false then
    raise exception
      'N1_ACTIVATION_POSTCONDITION_FAILED: auto_issue must remain false';
  end if;

  if v_published_at is null or v_valid_from is null then
    raise exception
      'N1_ACTIVATION_POSTCONDITION_FAILED: published_at/valid_from must be populated';
  end if;

  -- N2 e N3 permanecem draft nesta fase.
  if exists (
    select 1
    from public.certification_programs p
    where p.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and p.id in (
        '219024ee-7a16-4180-b0c6-d64fcc58ed6a'::uuid,
        'd49489fd-4945-4e5d-830f-ad98354f79ba'::uuid
      )
      and p.status <> 'draft'
  ) then
    raise exception
      'N1_ACTIVATION_POSTCONDITION_FAILED: N2/N3 program status changed unexpectedly';
  end if;
end;
$postcondition$;

commit;
