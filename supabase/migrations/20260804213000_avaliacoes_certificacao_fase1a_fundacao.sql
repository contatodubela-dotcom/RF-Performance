-- RF Performance Comercial
-- Fase 1A - Fundação de Avaliações e Certificação Comercial
-- Data: 2026-08-04
-- Escopo: schema, integridade, isolamento de gabaritos e RLS defensiva.
-- Não importa questões e não ativa telas do frontend.

begin;

create schema if not exists private;

-- -----------------------------------------------------------------------------
-- Funções auxiliares exclusivas do módulo
-- -----------------------------------------------------------------------------

create or replace function private.set_assessment_row_metadata()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog, public, private
as $$
begin
  if tg_op = 'INSERT' then
    new.created_at := coalesce(new.created_at, now());
    new.created_by := coalesce(new.created_by, auth.uid());
  end if;

  new.updated_at := now();
  new.updated_by := coalesce(auth.uid(), new.updated_by);
  return new;
end;
$$;

create or replace function private.guard_assessment_organization_scope()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog, public, private
as $$
begin
  if new.organization_id is distinct from old.organization_id then
    raise exception 'organization_id não pode ser alterado após a criação do registro';
  end if;
  return new;
end;
$$;

create or replace function private.can_view_assessment_member(
  p_organization_id uuid,
  p_organization_member_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select
    private.is_platform_admin()
    or private.has_org_role(p_organization_id, array['director'])
    or p_organization_member_id = private.current_member_id(p_organization_id)
    or exists (
      select 1
      from public.team_members tm
      where tm.organization_id = p_organization_id
        and tm.organization_member_id = p_organization_member_id
        and tm.status = 'active'
        and tm.archived_at is null
        and tm.team_id in (select private.managed_team_ids())
    );
$$;

create or replace function private.can_manage_assessment_member(
  p_organization_id uuid,
  p_organization_member_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select
    private.is_platform_admin()
    or private.has_org_role(p_organization_id, array['director'])
    or exists (
      select 1
      from public.team_members tm
      where tm.organization_id = p_organization_id
        and tm.organization_member_id = p_organization_member_id
        and tm.status = 'active'
        and tm.archived_at is null
        and tm.team_id in (select private.managed_team_ids())
    );
$$;

revoke all on function private.set_assessment_row_metadata() from public;
revoke all on function private.guard_assessment_organization_scope() from public;
revoke all on function private.can_view_assessment_member(uuid, uuid) from public;
revoke all on function private.can_manage_assessment_member(uuid, uuid) from public;
revoke all on function private.set_assessment_row_metadata() from anon, authenticated;
revoke all on function private.guard_assessment_organization_scope() from anon, authenticated;
revoke all on function private.can_view_assessment_member(uuid, uuid) from anon, authenticated;
revoke all on function private.can_manage_assessment_member(uuid, uuid) from anon, authenticated;

-- -----------------------------------------------------------------------------
-- Catálogo de certificação e competências
-- -----------------------------------------------------------------------------

create table public.certification_levels (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  code text not null,
  sequence_no integer not null,
  name text not null,
  description text,
  requirements text,
  overall_min numeric(5,2) not null,
  legal_min numeric(5,2) not null,
  practical_min numeric(5,2) not null,
  critical_errors_allowed integer not null default 0,
  validity_months integer not null default 12,
  scope_description text,
  status text not null default 'draft',
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint certification_levels_organization_id_fkey
    foreign key (organization_id) references public.organizations(id) on delete restrict,
  constraint certification_levels_created_by_fkey
    foreign key (created_by) references public.profiles(id) on delete set null,
  constraint certification_levels_updated_by_fkey
    foreign key (updated_by) references public.profiles(id) on delete set null,
  constraint certification_levels_code_key unique (organization_id, code),
  constraint certification_levels_sequence_key unique (organization_id, sequence_no),
  constraint certification_levels_id_org_key unique (id, organization_id),
  constraint certification_levels_scores_check check (
    overall_min between 0 and 100
    and legal_min between 0 and 100
    and practical_min between 0 and 100
  ),
  constraint certification_levels_critical_errors_check check (critical_errors_allowed >= 0),
  constraint certification_levels_validity_check check (validity_months between 1 and 60),
  constraint certification_levels_status_check check (status in ('draft', 'active', 'archived')),
  constraint certification_levels_metadata_object_check check (jsonb_typeof(metadata) = 'object')
);

create table public.competency_domains (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  code text not null,
  sequence_no integer not null,
  name text not null,
  description text,
  domain_type text not null default 'knowledge',
  is_legal boolean not null default false,
  default_weight numeric(5,2) not null default 0,
  status text not null default 'draft',
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint competency_domains_organization_id_fkey
    foreign key (organization_id) references public.organizations(id) on delete restrict,
  constraint competency_domains_created_by_fkey
    foreign key (created_by) references public.profiles(id) on delete set null,
  constraint competency_domains_updated_by_fkey
    foreign key (updated_by) references public.profiles(id) on delete set null,
  constraint competency_domains_code_key unique (organization_id, code),
  constraint competency_domains_sequence_key unique (organization_id, sequence_no),
  constraint competency_domains_id_org_key unique (id, organization_id),
  constraint competency_domains_type_check check (domain_type in ('knowledge', 'practical')),
  constraint competency_domains_weight_check check (default_weight between 0 and 100),
  constraint competency_domains_status_check check (status in ('draft', 'active', 'archived')),
  constraint competency_domains_metadata_object_check check (jsonb_typeof(metadata) = 'object')
);

-- -----------------------------------------------------------------------------
-- Testes, versões, questões e alternativas
-- -----------------------------------------------------------------------------

create table public.assessment_tests (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  code text not null,
  sequence_no integer not null,
  title text not null,
  description text,
  difficulty text not null,
  purpose text not null default 'certification',
  target_level_id uuid,
  question_count integer not null default 30,
  time_limit_minutes integer,
  max_attempts integer not null default 2,
  cooldown_hours integer not null default 24,
  status text not null default 'draft',
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint assessment_tests_organization_id_fkey
    foreign key (organization_id) references public.organizations(id) on delete restrict,
  constraint assessment_tests_target_level_org_fkey
    foreign key (target_level_id, organization_id)
    references public.certification_levels(id, organization_id) on delete restrict,
  constraint assessment_tests_created_by_fkey
    foreign key (created_by) references public.profiles(id) on delete set null,
  constraint assessment_tests_updated_by_fkey
    foreign key (updated_by) references public.profiles(id) on delete set null,
  constraint assessment_tests_code_key unique (organization_id, code),
  constraint assessment_tests_sequence_key unique (organization_id, sequence_no),
  constraint assessment_tests_id_org_key unique (id, organization_id),
  constraint assessment_tests_difficulty_check check (
    difficulty in ('diagnostic', 'beginner', 'beginner_intermediate', 'intermediate', 'intermediate_advanced', 'advanced')
  ),
  constraint assessment_tests_purpose_check check (purpose in ('diagnostic', 'certification', 'reinforcement')),
  constraint assessment_tests_question_count_check check (question_count between 1 and 200),
  constraint assessment_tests_time_limit_check check (time_limit_minutes is null or time_limit_minutes between 5 and 480),
  constraint assessment_tests_attempts_check check (max_attempts between 1 and 20),
  constraint assessment_tests_cooldown_check check (cooldown_hours between 0 and 8760),
  constraint assessment_tests_status_check check (status in ('draft', 'active', 'archived')),
  constraint assessment_tests_metadata_object_check check (jsonb_typeof(metadata) = 'object')
);

create table public.assessment_test_versions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  test_id uuid not null,
  version_code text not null,
  version_no integer not null,
  status text not null default 'draft',
  passing_score numeric(5,2) not null,
  legal_min_score numeric(5,2) not null,
  question_count integer not null default 30,
  randomize_questions boolean not null default false,
  randomize_options boolean not null default true,
  show_review_after_submit boolean not null default true,
  valid_from timestamptz,
  valid_until timestamptz,
  published_at timestamptz,
  normative_basis jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint assessment_test_versions_test_org_fkey
    foreign key (test_id, organization_id)
    references public.assessment_tests(id, organization_id) on delete restrict,
  constraint assessment_test_versions_created_by_fkey
    foreign key (created_by) references public.profiles(id) on delete set null,
  constraint assessment_test_versions_updated_by_fkey
    foreign key (updated_by) references public.profiles(id) on delete set null,
  constraint assessment_test_versions_code_key unique (test_id, version_code),
  constraint assessment_test_versions_number_key unique (test_id, version_no),
  constraint assessment_test_versions_id_org_key unique (id, organization_id),
  constraint assessment_test_versions_id_org_test_key unique (id, organization_id, test_id),
  constraint assessment_test_versions_scores_check check (
    passing_score between 0 and 100 and legal_min_score between 0 and 100
  ),
  constraint assessment_test_versions_question_count_check check (question_count between 1 and 200),
  constraint assessment_test_versions_dates_check check (
    valid_until is null or valid_from is null or valid_until >= valid_from
  ),
  constraint assessment_test_versions_status_check check (status in ('draft', 'published', 'retired')),
  constraint assessment_test_versions_normative_basis_array_check check (jsonb_typeof(normative_basis) = 'array'),
  constraint assessment_test_versions_metadata_object_check check (jsonb_typeof(metadata) = 'object')
);

create unique index assessment_test_versions_one_published_per_test_idx
  on public.assessment_test_versions(test_id)
  where status = 'published' and archived_at is null;

create table public.assessment_questions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  code text not null,
  competency_id uuid not null,
  block_code text not null,
  prompt text not null,
  question_type text not null default 'single_choice',
  difficulty text not null,
  content_version text not null,
  legal_review_date date,
  status text not null default 'draft',
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint assessment_questions_organization_id_fkey
    foreign key (organization_id) references public.organizations(id) on delete restrict,
  constraint assessment_questions_competency_org_fkey
    foreign key (competency_id, organization_id)
    references public.competency_domains(id, organization_id) on delete restrict,
  constraint assessment_questions_created_by_fkey
    foreign key (created_by) references public.profiles(id) on delete set null,
  constraint assessment_questions_updated_by_fkey
    foreign key (updated_by) references public.profiles(id) on delete set null,
  constraint assessment_questions_code_key unique (organization_id, code),
  constraint assessment_questions_id_org_key unique (id, organization_id),
  constraint assessment_questions_type_check check (question_type = 'single_choice'),
  constraint assessment_questions_difficulty_check check (
    difficulty in ('beginner', 'beginner_intermediate', 'intermediate', 'intermediate_advanced', 'advanced')
  ),
  constraint assessment_questions_status_check check (status in ('draft', 'reviewed', 'published', 'archived')),
  constraint assessment_questions_metadata_object_check check (jsonb_typeof(metadata) = 'object')
);

create table public.assessment_question_options (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  question_id uuid not null,
  option_code text not null,
  option_text text not null,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint assessment_question_options_question_org_fkey
    foreign key (question_id, organization_id)
    references public.assessment_questions(id, organization_id) on delete restrict,
  constraint assessment_question_options_created_by_fkey
    foreign key (created_by) references public.profiles(id) on delete set null,
  constraint assessment_question_options_updated_by_fkey
    foreign key (updated_by) references public.profiles(id) on delete set null,
  constraint assessment_question_options_code_key unique (question_id, option_code),
  constraint assessment_question_options_id_org_key unique (id, organization_id),
  constraint assessment_question_options_option_code_check check (option_code in ('A', 'B', 'C', 'D')),
  constraint assessment_question_options_metadata_object_check check (jsonb_typeof(metadata) = 'object')
);

create table private.assessment_question_keys (
  question_id uuid primary key,
  organization_id uuid not null,
  correct_option_code text not null,
  justification text not null,
  source_reference text not null,
  is_critical boolean not null default false,
  critical_reason text,
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  metadata jsonb not null default '{}'::jsonb,
  constraint assessment_question_keys_question_org_fkey
    foreign key (question_id, organization_id)
    references public.assessment_questions(id, organization_id) on delete restrict,
  constraint assessment_question_keys_reviewed_by_fkey
    foreign key (reviewed_by) references public.profiles(id) on delete set null,
  constraint assessment_question_keys_created_by_fkey
    foreign key (created_by) references public.profiles(id) on delete set null,
  constraint assessment_question_keys_updated_by_fkey
    foreign key (updated_by) references public.profiles(id) on delete set null,
  constraint assessment_question_keys_option_check check (correct_option_code in ('A', 'B', 'C', 'D')),
  constraint assessment_question_keys_metadata_object_check check (jsonb_typeof(metadata) = 'object')
);

create table public.assessment_version_questions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  test_version_id uuid not null,
  question_id uuid not null,
  sequence_no integer not null,
  points numeric(7,2) not null default 1,
  is_required boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint assessment_version_questions_version_org_fkey
    foreign key (test_version_id, organization_id)
    references public.assessment_test_versions(id, organization_id) on delete restrict,
  constraint assessment_version_questions_question_org_fkey
    foreign key (question_id, organization_id)
    references public.assessment_questions(id, organization_id) on delete restrict,
  constraint assessment_version_questions_created_by_fkey
    foreign key (created_by) references public.profiles(id) on delete set null,
  constraint assessment_version_questions_updated_by_fkey
    foreign key (updated_by) references public.profiles(id) on delete set null,
  constraint assessment_version_questions_question_key unique (test_version_id, question_id),
  constraint assessment_version_questions_sequence_key unique (test_version_id, sequence_no),
  constraint assessment_version_questions_id_org_key unique (id, organization_id),
  constraint assessment_version_questions_points_check check (points > 0),
  constraint assessment_version_questions_metadata_object_check check (jsonb_typeof(metadata) = 'object')
);

-- -----------------------------------------------------------------------------
-- Tentativas, respostas e correção isolada
-- -----------------------------------------------------------------------------

create table public.assessment_attempts (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  test_id uuid not null,
  test_version_id uuid not null,
  organization_member_id uuid not null,
  user_id uuid not null,
  attempt_no integer not null,
  status text not null default 'in_progress',
  started_at timestamptz not null default now(),
  submitted_at timestamptz,
  graded_at timestamptz,
  expires_at timestamptz,
  total_questions integer not null default 0,
  answered_questions integer not null default 0,
  correct_answers integer,
  overall_score numeric(5,2),
  legal_score numeric(5,2),
  critical_errors integer not null default 0,
  passed boolean,
  result_reason text,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint assessment_attempts_test_org_fkey
    foreign key (test_id, organization_id)
    references public.assessment_tests(id, organization_id) on delete restrict,
  constraint assessment_attempts_version_org_test_fkey
    foreign key (test_version_id, organization_id, test_id)
    references public.assessment_test_versions(id, organization_id, test_id) on delete restrict,
  constraint assessment_attempts_member_org_fkey
    foreign key (organization_member_id, organization_id)
    references public.organization_members(id, organization_id) on delete restrict,
  constraint assessment_attempts_user_id_fkey
    foreign key (user_id) references public.profiles(id) on delete restrict,
  constraint assessment_attempts_created_by_fkey
    foreign key (created_by) references public.profiles(id) on delete set null,
  constraint assessment_attempts_updated_by_fkey
    foreign key (updated_by) references public.profiles(id) on delete set null,
  constraint assessment_attempts_number_key unique (organization_member_id, test_version_id, attempt_no),
  constraint assessment_attempts_id_org_key unique (id, organization_id),
  constraint assessment_attempts_attempt_no_check check (attempt_no > 0),
  constraint assessment_attempts_status_check check (
    status in ('in_progress', 'submitted', 'graded', 'cancelled', 'expired')
  ),
  constraint assessment_attempts_counts_check check (
    total_questions >= 0
    and answered_questions >= 0
    and answered_questions <= total_questions
    and (correct_answers is null or (correct_answers >= 0 and correct_answers <= total_questions))
  ),
  constraint assessment_attempts_scores_check check (
    (overall_score is null or overall_score between 0 and 100)
    and (legal_score is null or legal_score between 0 and 100)
  ),
  constraint assessment_attempts_critical_errors_check check (critical_errors >= 0),
  constraint assessment_attempts_dates_check check (
    (submitted_at is null or submitted_at >= started_at)
    and (graded_at is null or submitted_at is null or graded_at >= submitted_at)
    and (expires_at is null or expires_at >= started_at)
  ),
  constraint assessment_attempts_metadata_object_check check (jsonb_typeof(metadata) = 'object')
);

create table public.assessment_attempt_items (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  attempt_id uuid not null,
  question_id uuid not null,
  competency_id uuid not null,
  block_code text not null,
  position_no integer not null,
  points numeric(7,2) not null default 1,
  prompt_snapshot text not null,
  options_snapshot jsonb not null,
  option_order jsonb not null,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint assessment_attempt_items_attempt_org_fkey
    foreign key (attempt_id, organization_id)
    references public.assessment_attempts(id, organization_id) on delete restrict,
  constraint assessment_attempt_items_question_org_fkey
    foreign key (question_id, organization_id)
    references public.assessment_questions(id, organization_id) on delete restrict,
  constraint assessment_attempt_items_competency_org_fkey
    foreign key (competency_id, organization_id)
    references public.competency_domains(id, organization_id) on delete restrict,
  constraint assessment_attempt_items_created_by_fkey
    foreign key (created_by) references public.profiles(id) on delete set null,
  constraint assessment_attempt_items_updated_by_fkey
    foreign key (updated_by) references public.profiles(id) on delete set null,
  constraint assessment_attempt_items_question_key unique (attempt_id, question_id),
  constraint assessment_attempt_items_position_key unique (attempt_id, position_no),
  constraint assessment_attempt_items_id_org_key unique (id, organization_id),
  constraint assessment_attempt_items_position_check check (position_no > 0),
  constraint assessment_attempt_items_points_check check (points > 0),
  constraint assessment_attempt_items_options_object_check check (jsonb_typeof(options_snapshot) = 'object'),
  constraint assessment_attempt_items_option_order_array_check check (jsonb_typeof(option_order) = 'array'),
  constraint assessment_attempt_items_metadata_object_check check (jsonb_typeof(metadata) = 'object')
);

create table public.assessment_attempt_answers (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  attempt_id uuid not null,
  attempt_item_id uuid not null,
  selected_option_code text not null,
  answered_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint assessment_attempt_answers_attempt_org_fkey
    foreign key (attempt_id, organization_id)
    references public.assessment_attempts(id, organization_id) on delete restrict,
  constraint assessment_attempt_answers_item_org_fkey
    foreign key (attempt_item_id, organization_id)
    references public.assessment_attempt_items(id, organization_id) on delete restrict,
  constraint assessment_attempt_answers_created_by_fkey
    foreign key (created_by) references public.profiles(id) on delete set null,
  constraint assessment_attempt_answers_updated_by_fkey
    foreign key (updated_by) references public.profiles(id) on delete set null,
  constraint assessment_attempt_answers_item_key unique (attempt_item_id),
  constraint assessment_attempt_answers_id_org_key unique (id, organization_id),
  constraint assessment_attempt_answers_option_check check (selected_option_code in ('A', 'B', 'C', 'D')),
  constraint assessment_attempt_answers_metadata_object_check check (jsonb_typeof(metadata) = 'object')
);

create table private.assessment_attempt_grades (
  attempt_item_id uuid primary key,
  organization_id uuid not null,
  attempt_id uuid not null,
  question_id uuid not null,
  is_correct boolean not null,
  points_awarded numeric(7,2) not null default 0,
  is_critical_error boolean not null default false,
  graded_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb,
  constraint assessment_attempt_grades_item_org_fkey
    foreign key (attempt_item_id, organization_id)
    references public.assessment_attempt_items(id, organization_id) on delete restrict,
  constraint assessment_attempt_grades_attempt_org_fkey
    foreign key (attempt_id, organization_id)
    references public.assessment_attempts(id, organization_id) on delete restrict,
  constraint assessment_attempt_grades_question_org_fkey
    foreign key (question_id, organization_id)
    references public.assessment_questions(id, organization_id) on delete restrict,
  constraint assessment_attempt_grades_points_check check (points_awarded >= 0),
  constraint assessment_attempt_grades_metadata_object_check check (jsonb_typeof(metadata) = 'object')
);

create table public.assessment_competency_scores (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  attempt_id uuid not null,
  competency_id uuid not null,
  questions_count integer not null,
  correct_count integer not null,
  score numeric(5,2) not null,
  passed boolean not null,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint assessment_competency_scores_attempt_org_fkey
    foreign key (attempt_id, organization_id)
    references public.assessment_attempts(id, organization_id) on delete restrict,
  constraint assessment_competency_scores_competency_org_fkey
    foreign key (competency_id, organization_id)
    references public.competency_domains(id, organization_id) on delete restrict,
  constraint assessment_competency_scores_created_by_fkey
    foreign key (created_by) references public.profiles(id) on delete set null,
  constraint assessment_competency_scores_updated_by_fkey
    foreign key (updated_by) references public.profiles(id) on delete set null,
  constraint assessment_competency_scores_attempt_competency_key unique (attempt_id, competency_id),
  constraint assessment_competency_scores_id_org_key unique (id, organization_id),
  constraint assessment_competency_scores_counts_check check (
    questions_count > 0 and correct_count >= 0 and correct_count <= questions_count
  ),
  constraint assessment_competency_scores_score_check check (score between 0 and 100),
  constraint assessment_competency_scores_metadata_object_check check (jsonb_typeof(metadata) = 'object')
);

-- -----------------------------------------------------------------------------
-- Avaliação prática e certificações emitidas
-- -----------------------------------------------------------------------------

create table public.practical_assessments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  organization_member_id uuid not null,
  user_id uuid not null,
  evaluator_member_id uuid not null,
  certification_level_id uuid not null,
  assessment_type text not null,
  status text not null default 'scheduled',
  score numeric(5,2),
  critical_errors integer not null default 0,
  passed boolean,
  criteria_scores jsonb not null default '{}'::jsonb,
  notes text,
  evidence jsonb not null default '[]'::jsonb,
  scheduled_at timestamptz,
  assessed_at timestamptz,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint practical_assessments_member_org_fkey
    foreign key (organization_member_id, organization_id)
    references public.organization_members(id, organization_id) on delete restrict,
  constraint practical_assessments_evaluator_org_fkey
    foreign key (evaluator_member_id, organization_id)
    references public.organization_members(id, organization_id) on delete restrict,
  constraint practical_assessments_level_org_fkey
    foreign key (certification_level_id, organization_id)
    references public.certification_levels(id, organization_id) on delete restrict,
  constraint practical_assessments_user_id_fkey
    foreign key (user_id) references public.profiles(id) on delete restrict,
  constraint practical_assessments_created_by_fkey
    foreign key (created_by) references public.profiles(id) on delete set null,
  constraint practical_assessments_updated_by_fkey
    foreign key (updated_by) references public.profiles(id) on delete set null,
  constraint practical_assessments_id_org_key unique (id, organization_id),
  constraint practical_assessments_type_check check (
    assessment_type in ('role_play', 'case_presentation', 'microtraining')
  ),
  constraint practical_assessments_status_check check (
    status in ('scheduled', 'in_progress', 'completed', 'cancelled')
  ),
  constraint practical_assessments_score_check check (score is null or score between 0 and 100),
  constraint practical_assessments_critical_errors_check check (critical_errors >= 0),
  constraint practical_assessments_dates_check check (
    assessed_at is null or scheduled_at is null or assessed_at >= scheduled_at
  ),
  constraint practical_assessments_criteria_object_check check (jsonb_typeof(criteria_scores) = 'object'),
  constraint practical_assessments_evidence_array_check check (jsonb_typeof(evidence) = 'array'),
  constraint practical_assessments_metadata_object_check check (jsonb_typeof(metadata) = 'object')
);

create table public.member_certifications (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  organization_member_id uuid not null,
  user_id uuid not null,
  certification_level_id uuid not null,
  source_attempt_id uuid,
  source_practical_assessment_id uuid,
  certificate_number text not null,
  status text not null default 'pending',
  issued_at timestamptz,
  valid_until timestamptz,
  revoked_at timestamptz,
  revocation_reason text,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  constraint member_certifications_member_org_fkey
    foreign key (organization_member_id, organization_id)
    references public.organization_members(id, organization_id) on delete restrict,
  constraint member_certifications_level_org_fkey
    foreign key (certification_level_id, organization_id)
    references public.certification_levels(id, organization_id) on delete restrict,
  constraint member_certifications_attempt_org_fkey
    foreign key (source_attempt_id, organization_id)
    references public.assessment_attempts(id, organization_id) on delete restrict,
  constraint member_certifications_practical_org_fkey
    foreign key (source_practical_assessment_id, organization_id)
    references public.practical_assessments(id, organization_id) on delete restrict,
  constraint member_certifications_user_id_fkey
    foreign key (user_id) references public.profiles(id) on delete restrict,
  constraint member_certifications_created_by_fkey
    foreign key (created_by) references public.profiles(id) on delete set null,
  constraint member_certifications_updated_by_fkey
    foreign key (updated_by) references public.profiles(id) on delete set null,
  constraint member_certifications_certificate_number_key unique (certificate_number),
  constraint member_certifications_id_org_key unique (id, organization_id),
  constraint member_certifications_status_check check (
    status in ('pending', 'active', 'expired', 'revoked')
  ),
  constraint member_certifications_dates_check check (
    (valid_until is null or issued_at is null or valid_until >= issued_at)
    and (revoked_at is null or issued_at is null or revoked_at >= issued_at)
  ),
  constraint member_certifications_metadata_object_check check (jsonb_typeof(metadata) = 'object')
);

create unique index member_certifications_one_active_level_idx
  on public.member_certifications(organization_member_id, certification_level_id)
  where status = 'active' and archived_at is null;

-- -----------------------------------------------------------------------------
-- Índices operacionais
-- -----------------------------------------------------------------------------

create index certification_levels_org_status_idx
  on public.certification_levels(organization_id, status, sequence_no);
create index competency_domains_org_status_idx
  on public.competency_domains(organization_id, status, sequence_no);
create index assessment_tests_org_status_idx
  on public.assessment_tests(organization_id, status, sequence_no);
create index assessment_test_versions_test_status_idx
  on public.assessment_test_versions(test_id, status, version_no desc);
create index assessment_questions_org_competency_idx
  on public.assessment_questions(organization_id, competency_id, status);
create index assessment_question_options_question_idx
  on public.assessment_question_options(question_id, option_code);
create index assessment_version_questions_version_idx
  on public.assessment_version_questions(test_version_id, sequence_no);
create index assessment_attempts_member_started_idx
  on public.assessment_attempts(organization_member_id, started_at desc);
create index assessment_attempts_org_status_idx
  on public.assessment_attempts(organization_id, status, started_at desc);
create index assessment_attempt_items_attempt_idx
  on public.assessment_attempt_items(attempt_id, position_no);
create index assessment_attempt_answers_attempt_idx
  on public.assessment_attempt_answers(attempt_id, answered_at);
create index assessment_competency_scores_attempt_idx
  on public.assessment_competency_scores(attempt_id, competency_id);
create index practical_assessments_member_idx
  on public.practical_assessments(organization_member_id, assessed_at desc);
create index member_certifications_member_idx
  on public.member_certifications(organization_member_id, status, valid_until);

-- -----------------------------------------------------------------------------
-- Metadados e proteção de escopo
-- -----------------------------------------------------------------------------

do $$
declare
  v_table text;
begin
  foreach v_table in array array[
    'certification_levels',
    'competency_domains',
    'assessment_tests',
    'assessment_test_versions',
    'assessment_questions',
    'assessment_question_options',
    'assessment_version_questions',
    'assessment_attempts',
    'assessment_attempt_items',
    'assessment_attempt_answers',
    'assessment_competency_scores',
    'practical_assessments',
    'member_certifications'
  ] loop
    execute format(
      'create trigger %I before insert or update on public.%I for each row execute function private.set_assessment_row_metadata()',
      v_table || '_set_row_metadata',
      v_table
    );

    execute format(
      'create trigger %I before update on public.%I for each row execute function private.guard_assessment_organization_scope()',
      v_table || '_guard_organization_scope',
      v_table
    );
  end loop;
end;
$$;

-- -----------------------------------------------------------------------------
-- RLS defensiva: nenhum acesso direto nesta fase
-- O frontend será atendido por RPCs seguras na Fase 1B.
-- -----------------------------------------------------------------------------

do $$
declare
  v_table text;
begin
  foreach v_table in array array[
    'certification_levels',
    'competency_domains',
    'assessment_tests',
    'assessment_test_versions',
    'assessment_questions',
    'assessment_question_options',
    'assessment_version_questions',
    'assessment_attempts',
    'assessment_attempt_items',
    'assessment_attempt_answers',
    'assessment_competency_scores',
    'practical_assessments',
    'member_certifications'
  ] loop
    execute format('alter table public.%I enable row level security', v_table);
    execute format('alter table public.%I force row level security', v_table);
    execute format('revoke all on table public.%I from public, anon, authenticated', v_table);
  end loop;
end;
$$;

revoke all on table private.assessment_question_keys from public, anon, authenticated;
revoke all on table private.assessment_attempt_grades from public, anon, authenticated;

comment on table private.assessment_question_keys is
  'Gabaritos, justificativas, fontes e indicadores críticos. Nunca expor por SELECT direto ao cliente.';
comment on table private.assessment_attempt_grades is
  'Correção por questão. Mantida fora do schema público para impedir vazamento durante a tentativa.';
comment on table public.assessment_attempt_items is
  'Snapshot imutável do enunciado e das alternativas usadas em cada tentativa.';

commit;
