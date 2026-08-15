begin;

-- ============================================================
-- RF Performance
-- Avaliações e Certificações
-- Arquitetura escalável — Fase 1A
--
-- Objetivo:
--   criar fundação aditiva e versionada para:
--   1. materiais-fonte;
--   2. vínculo material <-> versão de avaliação;
--   3. programas de certificação;
--   4. versões de programas;
--   5. múltiplos requisitos por certificação;
--   6. evidências futuras de cumprimento dos requisitos.
--
-- Esta migration NÃO:
--   - altera os 5 testes existentes;
--   - altera certification_levels;
--   - altera member_certifications;
--   - altera practical_assessments;
--   - remove prerequisite_test_code;
--   - altera RPCs;
--   - cria certificados;
--   - publica avaliações.
-- ============================================================


-- ============================================================
-- 0. PREFLIGHT
-- ============================================================

do $$
begin
  if to_regclass('public.organizations') is null then
    raise exception 'PRECONDITION_FAILED: public.organizations missing';
  end if;

  if to_regclass('public.profiles') is null then
    raise exception 'PRECONDITION_FAILED: public.profiles missing';
  end if;

  if to_regclass('public.assessment_tests') is null then
    raise exception 'PRECONDITION_FAILED: public.assessment_tests missing';
  end if;

  if to_regclass('public.assessment_test_versions') is null then
    raise exception 'PRECONDITION_FAILED: public.assessment_test_versions missing';
  end if;

  if to_regclass('public.member_certifications') is null then
    raise exception 'PRECONDITION_FAILED: public.member_certifications missing';
  end if;

  if to_regclass('public.practical_assessments') is null then
    raise exception 'PRECONDITION_FAILED: public.practical_assessments missing';
  end if;
end;
$$;


-- ============================================================
-- 1. MATERIAL-FONTE
-- ============================================================

create table public.source_materials (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,

  code text not null,
  title text not null,
  description text,

  material_type text not null,
  issuer text,

  status text not null default 'draft',

  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,

  metadata jsonb not null default '{}'::jsonb,

  constraint source_materials_organization_id_fkey
    foreign key (organization_id)
    references public.organizations(id)
    on delete restrict,

  constraint source_materials_created_by_fkey
    foreign key (created_by)
    references public.profiles(id)
    on delete set null,

  constraint source_materials_updated_by_fkey
    foreign key (updated_by)
    references public.profiles(id)
    on delete set null,

  constraint source_materials_code_key
    unique (organization_id, code),

  constraint source_materials_id_org_key
    unique (id, organization_id),

  constraint source_materials_code_not_blank
    check (btrim(code) <> ''),

  constraint source_materials_title_not_blank
    check (btrim(title) <> ''),

  constraint source_materials_type_check
    check (
      material_type in (
        'regulation',
        'manual',
        'course',
        'training',
        'policy',
        'book',
        'presentation',
        'article',
        'internal_content',
        'other'
      )
    ),

  constraint source_materials_status_check
    check (status in ('draft', 'active', 'archived')),

  constraint source_materials_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);


-- ============================================================
-- 2. VERSÕES DOS MATERIAIS
-- ============================================================

create table public.source_material_versions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  source_material_id uuid not null,

  version_code text not null,
  version_no integer not null,

  status text not null default 'draft',

  effective_from timestamptz,
  effective_until timestamptz,
  published_at timestamptz,

  source_date date,
  content_sha256 text,
  source_locator jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,

  metadata jsonb not null default '{}'::jsonb,

  constraint source_material_versions_material_org_fkey
    foreign key (source_material_id, organization_id)
    references public.source_materials(id, organization_id)
    on delete restrict,

  constraint source_material_versions_created_by_fkey
    foreign key (created_by)
    references public.profiles(id)
    on delete set null,

  constraint source_material_versions_updated_by_fkey
    foreign key (updated_by)
    references public.profiles(id)
    on delete set null,

  constraint source_material_versions_code_key
    unique (organization_id, source_material_id, version_code),

  constraint source_material_versions_number_key
    unique (organization_id, source_material_id, version_no),

  constraint source_material_versions_id_org_key
    unique (id, organization_id),

  constraint source_material_versions_id_org_material_key
    unique (id, organization_id, source_material_id),

  constraint source_material_versions_code_not_blank
    check (btrim(version_code) <> ''),

  constraint source_material_versions_number_check
    check (version_no > 0),

  constraint source_material_versions_status_check
    check (status in ('draft', 'active', 'superseded', 'archived')),

  constraint source_material_versions_dates_check
    check (
      effective_until is null
      or effective_from is null
      or effective_until > effective_from
    ),

  constraint source_material_versions_sha256_check
    check (
      content_sha256 is null
      or content_sha256 ~ '^[0-9a-fA-F]{64}$'
    ),

  constraint source_material_versions_locator_object_check
    check (jsonb_typeof(source_locator) = 'object'),

  constraint source_material_versions_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);


-- ============================================================
-- 3. FONTES DE CADA VERSÃO DE AVALIAÇÃO
-- ============================================================

create table public.assessment_version_sources (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,

  test_version_id uuid not null,
  source_material_version_id uuid not null,

  relation_type text not null default 'supporting',
  is_required boolean not null default true,
  notes text,

  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,

  metadata jsonb not null default '{}'::jsonb,

  constraint assessment_version_sources_test_version_org_fkey
    foreign key (test_version_id, organization_id)
    references public.assessment_test_versions(id, organization_id)
    on delete restrict,

  constraint assessment_version_sources_material_version_org_fkey
    foreign key (source_material_version_id, organization_id)
    references public.source_material_versions(id, organization_id)
    on delete restrict,

  constraint assessment_version_sources_created_by_fkey
    foreign key (created_by)
    references public.profiles(id)
    on delete set null,

  constraint assessment_version_sources_updated_by_fkey
    foreign key (updated_by)
    references public.profiles(id)
    on delete set null,

  constraint assessment_version_sources_unique_key
    unique (
      organization_id,
      test_version_id,
      source_material_version_id
    ),

  constraint assessment_version_sources_id_org_key
    unique (id, organization_id),

  constraint assessment_version_sources_relation_check
    check (
      relation_type in (
        'primary',
        'normative',
        'supporting',
        'reference'
      )
    ),

  constraint assessment_version_sources_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);


-- ============================================================
-- 4. PROGRAMAS DE CERTIFICAÇÃO
-- ============================================================

create table public.certification_programs (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,

  code text not null,
  name text not null,
  description text,

  category text not null default 'professional',
  display_order integer,

  status text not null default 'draft',

  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,

  metadata jsonb not null default '{}'::jsonb,

  constraint certification_programs_organization_id_fkey
    foreign key (organization_id)
    references public.organizations(id)
    on delete restrict,

  constraint certification_programs_created_by_fkey
    foreign key (created_by)
    references public.profiles(id)
    on delete set null,

  constraint certification_programs_updated_by_fkey
    foreign key (updated_by)
    references public.profiles(id)
    on delete set null,

  constraint certification_programs_code_key
    unique (organization_id, code),

  constraint certification_programs_id_org_key
    unique (id, organization_id),

  constraint certification_programs_code_not_blank
    check (btrim(code) <> ''),

  constraint certification_programs_name_not_blank
    check (btrim(name) <> ''),

  constraint certification_programs_category_check
    check (
      category in (
        'professional',
        'technical',
        'regulatory',
        'product',
        'methodology',
        'leadership',
        'internal',
        'other'
      )
    ),

  constraint certification_programs_display_order_check
    check (display_order is null or display_order > 0),

  constraint certification_programs_status_check
    check (status in ('draft', 'active', 'archived')),

  constraint certification_programs_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);


-- ============================================================
-- 5. VERSÕES DOS PROGRAMAS
-- ============================================================

create table public.certification_program_versions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  certification_program_id uuid not null,

  version_code text not null,
  version_no integer not null,

  name text,
  description text,

  requirements_mode text not null default 'all',
  validity_months integer,
  auto_issue boolean not null default false,

  status text not null default 'draft',

  valid_from timestamptz,
  valid_until timestamptz,
  published_at timestamptz,

  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,

  metadata jsonb not null default '{}'::jsonb,

  constraint certification_program_versions_program_org_fkey
    foreign key (certification_program_id, organization_id)
    references public.certification_programs(id, organization_id)
    on delete restrict,

  constraint certification_program_versions_created_by_fkey
    foreign key (created_by)
    references public.profiles(id)
    on delete set null,

  constraint certification_program_versions_updated_by_fkey
    foreign key (updated_by)
    references public.profiles(id)
    on delete set null,

  constraint certification_program_versions_code_key
    unique (
      organization_id,
      certification_program_id,
      version_code
    ),

  constraint certification_program_versions_number_key
    unique (
      organization_id,
      certification_program_id,
      version_no
    ),

  constraint certification_program_versions_id_org_key
    unique (id, organization_id),

  constraint certification_program_versions_id_org_program_key
    unique (
      id,
      organization_id,
      certification_program_id
    ),

  constraint certification_program_versions_code_not_blank
    check (btrim(version_code) <> ''),

  constraint certification_program_versions_number_check
    check (version_no > 0),

  constraint certification_program_versions_mode_check
    check (requirements_mode in ('all', 'any')),

  constraint certification_program_versions_validity_check
    check (
      validity_months is null
      or validity_months between 1 and 120
    ),

  constraint certification_program_versions_status_check
    check (
      status in (
        'draft',
        'active',
        'superseded',
        'archived'
      )
    ),

  constraint certification_program_versions_dates_check
    check (
      valid_until is null
      or valid_from is null
      or valid_until > valid_from
    ),

  constraint certification_program_versions_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);


-- ============================================================
-- 6. REQUISITOS DAS CERTIFICAÇÕES
--
-- A estrutura já permite múltiplas avaliações e certificações
-- como requisitos.
--
-- training_completed e manual_validation ficam preparados para
-- fases posteriores através de requirement_config, sem criar FK
-- fraca para entidades ainda não integradas.
-- ============================================================

create table public.certification_requirements (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  certification_program_version_id uuid not null,

  sequence_no integer not null,
  requirement_type text not null,
  title text,
  description text,

  is_required boolean not null default true,

  assessment_test_id uuid,
  required_certification_program_id uuid,

  minimum_score numeric(5,2),
  minimum_legal_score numeric(5,2),
  max_critical_errors integer,

  requirement_config jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,

  metadata jsonb not null default '{}'::jsonb,

  constraint certification_requirements_version_org_fkey
    foreign key (
      certification_program_version_id,
      organization_id
    )
    references public.certification_program_versions(
      id,
      organization_id
    )
    on delete restrict,

  constraint certification_requirements_assessment_org_fkey
    foreign key (assessment_test_id, organization_id)
    references public.assessment_tests(id, organization_id)
    on delete restrict,

  constraint certification_requirements_program_org_fkey
    foreign key (
      required_certification_program_id,
      organization_id
    )
    references public.certification_programs(id, organization_id)
    on delete restrict,

  constraint certification_requirements_created_by_fkey
    foreign key (created_by)
    references public.profiles(id)
    on delete set null,

  constraint certification_requirements_updated_by_fkey
    foreign key (updated_by)
    references public.profiles(id)
    on delete set null,

  constraint certification_requirements_sequence_key
    unique (
      organization_id,
      certification_program_version_id,
      sequence_no
    ),

  constraint certification_requirements_id_org_key
    unique (id, organization_id),

  constraint certification_requirements_sequence_check
    check (sequence_no > 0),

  constraint certification_requirements_type_check
    check (
      requirement_type in (
        'assessment_passed',
        'assessment_graded',
        'certification_active',
        'practical_assessment_passed',
        'training_completed',
        'manual_validation'
      )
    ),

  constraint certification_requirements_score_check
    check (
      minimum_score is null
      or minimum_score between 0 and 100
    ),

  constraint certification_requirements_legal_score_check
    check (
      minimum_legal_score is null
      or minimum_legal_score between 0 and 100
    ),

  constraint certification_requirements_critical_errors_check
    check (
      max_critical_errors is null
      or max_critical_errors >= 0
    ),

  constraint certification_requirements_target_check
    check (
      (
        requirement_type in (
          'assessment_passed',
          'assessment_graded'
        )
        and assessment_test_id is not null
        and required_certification_program_id is null
      )
      or
      (
        requirement_type = 'certification_active'
        and assessment_test_id is null
        and required_certification_program_id is not null
      )
      or
      (
        requirement_type in (
          'practical_assessment_passed',
          'training_completed',
          'manual_validation'
        )
        and assessment_test_id is null
        and required_certification_program_id is null
      )
    ),

  constraint certification_requirements_config_object_check
    check (jsonb_typeof(requirement_config) = 'object'),

  constraint certification_requirements_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);


-- ============================================================
-- 7. EVIDÊNCIAS DE CUMPRIMENTO
--
-- A tabela fica vazia nesta fase.
-- Ela permitirá rastrear exatamente qual tentativa, avaliação
-- prática ou certificação anterior satisfez um requisito.
-- ============================================================

create table public.member_certification_evidence (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,

  member_certification_id uuid not null,
  certification_requirement_id uuid not null,

  evidence_type text not null,

  assessment_attempt_id uuid,
  practical_assessment_id uuid,
  source_member_certification_id uuid,

  status text not null default 'pending',
  satisfied_at timestamptz,
  validated_by uuid,

  evidence_data jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,

  metadata jsonb not null default '{}'::jsonb,

  constraint member_certification_evidence_member_cert_org_fkey
    foreign key (member_certification_id, organization_id)
    references public.member_certifications(id, organization_id)
    on delete restrict,

  constraint member_certification_evidence_requirement_org_fkey
    foreign key (certification_requirement_id, organization_id)
    references public.certification_requirements(id, organization_id)
    on delete restrict,

  constraint member_certification_evidence_attempt_org_fkey
    foreign key (assessment_attempt_id, organization_id)
    references public.assessment_attempts(id, organization_id)
    on delete restrict,

  constraint member_certification_evidence_practical_org_fkey
    foreign key (practical_assessment_id, organization_id)
    references public.practical_assessments(id, organization_id)
    on delete restrict,

  constraint member_certification_evidence_source_cert_org_fkey
    foreign key (source_member_certification_id, organization_id)
    references public.member_certifications(id, organization_id)
    on delete restrict,

  constraint member_certification_evidence_validated_by_fkey
    foreign key (validated_by)
    references public.profiles(id)
    on delete set null,

  constraint member_certification_evidence_created_by_fkey
    foreign key (created_by)
    references public.profiles(id)
    on delete set null,

  constraint member_certification_evidence_updated_by_fkey
    foreign key (updated_by)
    references public.profiles(id)
    on delete set null,

  constraint member_certification_evidence_unique_key
    unique (
      organization_id,
      member_certification_id,
      certification_requirement_id
    ),

  constraint member_certification_evidence_id_org_key
    unique (id, organization_id),

  constraint member_certification_evidence_type_check
    check (
      evidence_type in (
        'assessment_attempt',
        'practical_assessment',
        'certification',
        'training',
        'manual_validation'
      )
    ),

  constraint member_certification_evidence_status_check
    check (
      status in (
        'pending',
        'satisfied',
        'rejected',
        'revoked'
      )
    ),

  constraint member_certification_evidence_reference_check
    check (
      num_nonnulls(
        assessment_attempt_id,
        practical_assessment_id,
        source_member_certification_id
      ) <= 1
    ),

  constraint member_certification_evidence_data_object_check
    check (jsonb_typeof(evidence_data) = 'object'),

  constraint member_certification_evidence_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);


-- ============================================================
-- 8. ÍNDICES
-- ============================================================

create index source_materials_org_status_idx
  on public.source_materials(
    organization_id,
    status,
    code
  );

create index source_material_versions_material_status_idx
  on public.source_material_versions(
    organization_id,
    source_material_id,
    status,
    version_no
  );

create index assessment_version_sources_test_version_idx
  on public.assessment_version_sources(
    organization_id,
    test_version_id
  );

create index assessment_version_sources_material_version_idx
  on public.assessment_version_sources(
    organization_id,
    source_material_version_id
  );

create index certification_programs_org_status_idx
  on public.certification_programs(
    organization_id,
    status,
    display_order
  );

create index certification_program_versions_program_status_idx
  on public.certification_program_versions(
    organization_id,
    certification_program_id,
    status,
    version_no
  );

create index certification_requirements_version_idx
  on public.certification_requirements(
    organization_id,
    certification_program_version_id,
    sequence_no
  );

create index certification_requirements_assessment_idx
  on public.certification_requirements(
    organization_id,
    assessment_test_id
  )
  where assessment_test_id is not null;

create index certification_requirements_program_idx
  on public.certification_requirements(
    organization_id,
    required_certification_program_id
  )
  where required_certification_program_id is not null;

create index member_certification_evidence_certification_idx
  on public.member_certification_evidence(
    organization_id,
    member_certification_id,
    status
  );

create index member_certification_evidence_requirement_idx
  on public.member_certification_evidence(
    organization_id,
    certification_requirement_id
  );


-- ============================================================
-- 9. SEGURANÇA
--
-- Mesmo padrão observado nas estruturas atuais:
-- RLS habilitado + forçado e sem acesso direto para
-- public / anon / authenticated.
-- ============================================================

alter table public.source_materials
  enable row level security;

alter table public.source_materials
  force row level security;

alter table public.source_material_versions
  enable row level security;

alter table public.source_material_versions
  force row level security;

alter table public.assessment_version_sources
  enable row level security;

alter table public.assessment_version_sources
  force row level security;

alter table public.certification_programs
  enable row level security;

alter table public.certification_programs
  force row level security;

alter table public.certification_program_versions
  enable row level security;

alter table public.certification_program_versions
  force row level security;

alter table public.certification_requirements
  enable row level security;

alter table public.certification_requirements
  force row level security;

alter table public.member_certification_evidence
  enable row level security;

alter table public.member_certification_evidence
  force row level security;


revoke all on table public.source_materials
  from public, anon, authenticated;

revoke all on table public.source_material_versions
  from public, anon, authenticated;

revoke all on table public.assessment_version_sources
  from public, anon, authenticated;

revoke all on table public.certification_programs
  from public, anon, authenticated;

revoke all on table public.certification_program_versions
  from public, anon, authenticated;

revoke all on table public.certification_requirements
  from public, anon, authenticated;

revoke all on table public.member_certification_evidence
  from public, anon, authenticated;


-- ============================================================
-- 10. COMENTÁRIOS
-- ============================================================

comment on table public.source_materials is
  'Catálogo organizacional de materiais-fonte utilizados em avaliações, treinamentos e certificações.';

comment on table public.source_material_versions is
  'Versões imutavelmente identificáveis dos materiais-fonte.';

comment on table public.assessment_version_sources is
  'Relaciona versões de avaliações às versões exatas dos materiais que as fundamentam.';

comment on table public.certification_programs is
  'Programas genéricos de certificação, independentes dos cinco testes iniciais.';

comment on table public.certification_program_versions is
  'Versões dos programas de certificação e suas regras gerais de vigência.';

comment on table public.certification_requirements is
  'Requisitos múltiplos e versionados necessários para obtenção de uma certificação.';

comment on table public.member_certification_evidence is
  'Evidências auditáveis de cumprimento dos requisitos de uma certificação por um membro.';


-- ============================================================
-- 11. PÓS-CONDIÇÕES
-- ============================================================

do $$
declare
  v_missing integer;
  v_rls_invalid integer;
  v_direct_grants integer;
begin
  select count(*)
    into v_missing
  from (
    values
      ('source_materials'),
      ('source_material_versions'),
      ('assessment_version_sources'),
      ('certification_programs'),
      ('certification_program_versions'),
      ('certification_requirements'),
      ('member_certification_evidence')
  ) as expected(table_name)
  where to_regclass('public.' || expected.table_name) is null;

  if v_missing <> 0 then
    raise exception
      'POSTCONDITION_FAILED: % expected tables missing',
      v_missing;
  end if;


  select count(*)
    into v_rls_invalid
  from pg_class c
  join pg_namespace n
    on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname in (
      'source_materials',
      'source_material_versions',
      'assessment_version_sources',
      'certification_programs',
      'certification_program_versions',
      'certification_requirements',
      'member_certification_evidence'
    )
    and (
      c.relrowsecurity is not true
      or c.relforcerowsecurity is not true
    );

  if v_rls_invalid <> 0 then
    raise exception
      'POSTCONDITION_FAILED: % tables without ENABLE+FORCE RLS',
      v_rls_invalid;
  end if;


  select count(*)
    into v_direct_grants
  from information_schema.role_table_grants
  where table_schema = 'public'
    and table_name in (
      'source_materials',
      'source_material_versions',
      'assessment_version_sources',
      'certification_programs',
      'certification_program_versions',
      'certification_requirements',
      'member_certification_evidence'
    )
    and grantee in ('PUBLIC', 'anon', 'authenticated');

  if v_direct_grants <> 0 then
    raise exception
      'POSTCONDITION_FAILED: unexpected direct grants found: %',
      v_direct_grants;
  end if;
end;
$$;

commit;