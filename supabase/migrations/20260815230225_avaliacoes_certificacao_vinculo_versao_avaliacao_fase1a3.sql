begin;

-- ============================================================
-- Avaliações e Certificações
-- Arquitetura escalável — Fase 1A.3
--
-- Vincula requisitos baseados em avaliações à versão exata
-- do teste exigida pela versão do programa de certificação.
--
-- Nenhum dado é criado, removido ou transformado.
-- ============================================================


-- ============================================================
-- 0. PREFLIGHT
-- ============================================================

do $$
declare
  v_existing_column integer;
  v_existing_assessment_requirements integer;
  v_expected_unique integer;
begin
  if to_regclass('public.certification_requirements') is null then
    raise exception
      'PRECONDITION_FAILED: public.certification_requirements missing';
  end if;

  if to_regclass('public.assessment_test_versions') is null then
    raise exception
      'PRECONDITION_FAILED: public.assessment_test_versions missing';
  end if;

  select count(*)
    into v_existing_column
  from information_schema.columns
  where table_schema = 'public'
    and table_name = 'certification_requirements'
    and column_name = 'assessment_test_version_id';

  if v_existing_column <> 0 then
    raise exception
      'PRECONDITION_FAILED: assessment_test_version_id already exists';
  end if;

  select count(*)
    into v_existing_assessment_requirements
  from public.certification_requirements
  where requirement_type in (
    'assessment_passed',
    'assessment_graded'
  );

  if v_existing_assessment_requirements <> 0 then
    raise exception
      'PRECONDITION_FAILED: % existing assessment requirements require explicit migration',
      v_existing_assessment_requirements;
  end if;

  select count(*)
    into v_expected_unique
  from pg_constraint c
  where c.conrelid = 'public.assessment_test_versions'::regclass
    and c.conname = 'assessment_test_versions_id_org_test_key'
    and c.contype = 'u';

  if v_expected_unique <> 1 then
    raise exception
      'PRECONDITION_FAILED: assessment_test_versions_id_org_test_key missing';
  end if;
end;
$$;


-- ============================================================
-- 1. VERSÃO EXATA DA AVALIAÇÃO
-- ============================================================

alter table public.certification_requirements
  add column assessment_test_version_id uuid;


alter table public.certification_requirements
  add constraint certification_requirements_assessment_version_org_test_fkey
    foreign key (
      assessment_test_version_id,
      organization_id,
      assessment_test_id
    )
    references public.assessment_test_versions(
      id,
      organization_id,
      test_id
    )
    on delete restrict;


alter table public.certification_requirements
  add constraint certification_requirements_assessment_version_check
    check (
      (
        requirement_type in (
          'assessment_passed',
          'assessment_graded'
        )
        and assessment_test_id is not null
        and assessment_test_version_id is not null
      )
      or
      (
        requirement_type not in (
          'assessment_passed',
          'assessment_graded'
        )
        and assessment_test_version_id is null
      )
    );


create index certification_requirements_assessment_version_idx
  on public.certification_requirements(
    organization_id,
    assessment_test_version_id
  )
  where assessment_test_version_id is not null
    and archived_at is null;


comment on column public.certification_requirements.assessment_test_version_id is
  'Versão exata da avaliação exigida por esta versão do programa de certificação.';


-- ============================================================
-- 2. PÓS-CONDIÇÕES
-- ============================================================

do $$
declare
  v_column_count integer;
  v_fk_count integer;
  v_check_count integer;
  v_index_count integer;
begin
  select count(*)
    into v_column_count
  from information_schema.columns
  where table_schema = 'public'
    and table_name = 'certification_requirements'
    and column_name = 'assessment_test_version_id'
    and data_type = 'uuid';

  if v_column_count <> 1 then
    raise exception
      'POSTCONDITION_FAILED: assessment_test_version_id missing or unexpected type';
  end if;

  select count(*)
    into v_fk_count
  from pg_constraint c
  where c.conrelid = 'public.certification_requirements'::regclass
    and c.conname =
      'certification_requirements_assessment_version_org_test_fkey'
    and c.contype = 'f';

  if v_fk_count <> 1 then
    raise exception
      'POSTCONDITION_FAILED: assessment version FK missing';
  end if;

  select count(*)
    into v_check_count
  from pg_constraint c
  where c.conrelid = 'public.certification_requirements'::regclass
    and c.conname =
      'certification_requirements_assessment_version_check'
    and c.contype = 'c';

  if v_check_count <> 1 then
    raise exception
      'POSTCONDITION_FAILED: assessment version check missing';
  end if;

  select count(*)
    into v_index_count
  from pg_indexes
  where schemaname = 'public'
    and tablename = 'certification_requirements'
    and indexname =
      'certification_requirements_assessment_version_idx';

  if v_index_count <> 1 then
    raise exception
      'POSTCONDITION_FAILED: assessment version index missing';
  end if;
end;
$$;

commit;