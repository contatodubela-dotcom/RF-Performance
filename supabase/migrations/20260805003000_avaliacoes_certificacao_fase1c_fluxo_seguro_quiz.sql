-- RF Performance — Avaliações e Certificações — Fase 1C
-- Fluxo seguro de aplicação do quiz por RPC.
-- Não publica testes, não altera o frontend e não cria tentativas automaticamente.

begin;

-- -----------------------------------------------------------------------------
-- Preflight defensivo
-- -----------------------------------------------------------------------------

do $$
declare
  v_tests integer;
  v_versions integer;
  v_questions integer;
  v_keys integer;
  v_source_critical_flags integer;
  v_automatic_critical_flags integer;
  v_attempts integer;
begin
  if not exists (
    select 1
    from public.organizations o
    where o.id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
      and o.slug = 'rf-consorcios'
      and o.status = 'active'
      and o.archived_at is null
  ) then
    raise exception 'Fase 1C abortada: organização RF ativa não localizada.';
  end if;

  select count(*) into v_tests
  from public.assessment_tests
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and status = 'draft'
    and archived_at is null;

  select count(*) into v_versions
  from public.assessment_test_versions
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and status = 'draft'
    and archived_at is null;

  select count(*) into v_questions
  from public.assessment_questions
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and archived_at is null;

  select
    count(*),
    count(*) filter (where metadata ->> 'source_critical_flag' = 'true'),
    count(*) filter (where is_critical)
  into v_keys, v_source_critical_flags, v_automatic_critical_flags
  from private.assessment_question_keys
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid;

  select count(*) into v_attempts
  from public.assessment_attempts
  where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and archived_at is null;

  if v_tests <> 5 or v_versions <> 5 or v_questions <> 150 or v_keys <> 150 then
    raise exception 'Fase 1C abortada: catálogo esperado (5 testes, 5 versões, 150 questões e 150 gabaritos) não confere.';
  end if;

  if v_source_critical_flags <> 96 or v_automatic_critical_flags <> 0 then
    raise exception 'Fase 1C abortada: estado das marcações críticas não confere.';
  end if;

  if v_attempts <> 0 then
    raise exception 'Fase 1C abortada: já existem tentativas; a implantação exige catálogo ainda não utilizado.';
  end if;
end $$;

-- -----------------------------------------------------------------------------
-- Metadados explícitos de progressão e revisão
-- -----------------------------------------------------------------------------

update public.assessment_tests
set metadata = metadata || jsonb_build_object(
  'prerequisite_test_code', null,
  'prerequisite_result', null,
  'review_policy', 'immediate_after_grading',
  'flow_phase', '1C'
)
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and code = 'teste_1_diagnostico'
  and archived_at is null;

update public.assessment_tests
set metadata = metadata || jsonb_build_object(
  'prerequisite_test_code', 'teste_1_diagnostico',
  'prerequisite_result', 'graded',
  'review_policy', 'after_pass_or_final_attempt',
  'flow_phase', '1C'
)
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and code = 'teste_2_nivel_1'
  and archived_at is null;

update public.assessment_tests
set metadata = metadata || jsonb_build_object(
  'prerequisite_test_code', 'teste_2_nivel_1',
  'prerequisite_result', 'passed',
  'review_policy', 'after_pass_or_final_attempt',
  'flow_phase', '1C'
)
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and code = 'teste_3_intermediario'
  and archived_at is null;

update public.assessment_tests
set metadata = metadata || jsonb_build_object(
  'prerequisite_test_code', 'teste_3_intermediario',
  'prerequisite_result', 'passed',
  'review_policy', 'after_pass_or_final_attempt',
  'flow_phase', '1C'
)
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and code = 'teste_4_nivel_2'
  and archived_at is null;

update public.assessment_tests
set metadata = metadata || jsonb_build_object(
  'prerequisite_test_code', 'teste_4_nivel_2',
  'prerequisite_result', 'passed',
  'review_policy', 'after_pass_or_final_attempt',
  'flow_phase', '1C'
)
where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
  and code = 'teste_5_nivel_3'
  and archived_at is null;

-- -----------------------------------------------------------------------------
-- Funções privadas de apoio
-- -----------------------------------------------------------------------------

create or replace function private.assessment_prerequisites_met(
  p_organization_id uuid,
  p_organization_member_id uuid,
  p_test_id uuid
)
returns boolean
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $$
declare
  v_prerequisite_code text;
  v_prerequisite_result text;
  v_met boolean;
begin
  select
    nullif(t.metadata ->> 'prerequisite_test_code', ''),
    nullif(t.metadata ->> 'prerequisite_result', '')
  into v_prerequisite_code, v_prerequisite_result
  from public.assessment_tests t
  where t.id = p_test_id
    and t.organization_id = p_organization_id
    and t.archived_at is null;

  if v_prerequisite_code is null then
    return true;
  end if;

  select exists (
    select 1
    from public.assessment_attempts a
    join public.assessment_tests prerequisite_test
      on prerequisite_test.id = a.test_id
     and prerequisite_test.organization_id = a.organization_id
     and prerequisite_test.archived_at is null
    where a.organization_id = p_organization_id
      and a.organization_member_id = p_organization_member_id
      and a.archived_at is null
      and a.status = 'graded'
      and prerequisite_test.code = v_prerequisite_code
      and (
        v_prerequisite_result = 'graded'
        or (v_prerequisite_result = 'passed' and a.passed is true)
      )
  ) into v_met;

  return coalesce(v_met, false);
end;
$$;

create or replace function private.assessment_review_available(
  p_attempt_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select coalesce(
    tv.show_review_after_submit
    and a.status = 'graded'
    and (
      t.purpose = 'diagnostic'
      or a.passed is true
      or a.attempt_no >= t.max_attempts
    ),
    false
  )
  from public.assessment_attempts a
  join public.assessment_tests t
    on t.id = a.test_id
   and t.organization_id = a.organization_id
  join public.assessment_test_versions tv
    on tv.id = a.test_version_id
   and tv.organization_id = a.organization_id
   and tv.test_id = a.test_id
  where a.id = p_attempt_id
    and a.archived_at is null;
$$;

revoke all on function private.assessment_prerequisites_met(uuid, uuid, uuid) from public, anon, authenticated;
revoke all on function private.assessment_review_available(uuid) from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Catálogo disponível ao usuário atual
-- -----------------------------------------------------------------------------

create or replace function public.get_available_assessments(
  p_organization_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $$
declare
  v_user_id uuid := auth.uid();
  v_member_id uuid;
  v_tests jsonb;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  select om.id
  into v_member_id
  from public.organization_members om
  join public.profiles p
    on p.id = om.user_id
   and p.status = 'active'
   and p.archived_at is null
  where om.organization_id = p_organization_id
    and om.user_id = v_user_id
    and om.status = 'active'
    and om.archived_at is null;

  if v_member_id is null then
    raise exception 'ACTIVE_MEMBERSHIP_REQUIRED' using errcode = '42501';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'test_id', t.id,
        'test_code', t.code,
        'sequence_no', t.sequence_no,
        'title', t.title,
        'description', t.description,
        'purpose', t.purpose,
        'difficulty', t.difficulty,
        'question_count', tv.question_count,
        'time_limit_minutes', t.time_limit_minutes,
        'max_attempts', t.max_attempts,
        'cooldown_hours', t.cooldown_hours,
        'version_id', tv.id,
        'version_code', tv.version_code,
        'passing_score', tv.passing_score,
        'legal_min_score', tv.legal_min_score,
        'prerequisites_met', private.assessment_prerequisites_met(
          p_organization_id,
          v_member_id,
          t.id
        ),
        'attempts_used', coalesce(attempt_summary.attempts_used, 0),
        'in_progress_attempt_id', attempt_summary.in_progress_attempt_id,
        'last_attempt_status', attempt_summary.last_attempt_status,
        'last_attempt_passed', attempt_summary.last_attempt_passed,
        'next_attempt_at', attempt_summary.next_attempt_at,
        'availability', case
          when not private.assessment_prerequisites_met(
            p_organization_id,
            v_member_id,
            t.id
          ) then 'locked_prerequisite'
          when attempt_summary.in_progress_attempt_id is not null then 'in_progress'
          when coalesce(attempt_summary.attempts_used, 0) >= t.max_attempts then 'attempts_exhausted'
          when attempt_summary.next_attempt_at is not null
               and attempt_summary.next_attempt_at > now() then 'cooldown'
          else 'available'
        end
      )
      order by t.sequence_no
    ),
    '[]'::jsonb
  )
  into v_tests
  from public.assessment_tests t
  join public.assessment_test_versions tv
    on tv.test_id = t.id
   and tv.organization_id = t.organization_id
   and tv.status = 'published'
   and tv.archived_at is null
   and (tv.valid_from is null or tv.valid_from <= now())
   and (tv.valid_until is null or tv.valid_until >= now())
  left join lateral (
    select
      count(*) filter (where a.status <> 'cancelled')::integer as attempts_used,
      (
        array_agg(a.id order by a.started_at desc) filter (
          where a.status = 'in_progress'
            and (a.expires_at is null or a.expires_at > now())
        )
      )[1] as in_progress_attempt_id,
      (array_agg(a.status order by a.started_at desc))[1] as last_attempt_status,
      (array_agg(a.passed order by a.started_at desc))[1] as last_attempt_passed,
      max(coalesce(a.graded_at, a.submitted_at, a.started_at)) filter (
        where a.status in ('graded', 'submitted', 'expired')
      ) + make_interval(hours => t.cooldown_hours) as next_attempt_at
    from public.assessment_attempts a
    where a.organization_id = p_organization_id
      and a.organization_member_id = v_member_id
      and a.test_version_id = tv.id
      and a.archived_at is null
  ) attempt_summary on true
  where t.organization_id = p_organization_id
    and t.status = 'active'
    and t.archived_at is null;

  return jsonb_build_object(
    'organization_id', p_organization_id,
    'organization_member_id', v_member_id,
    'tests', v_tests
  );
end;
$$;

-- -----------------------------------------------------------------------------
-- Leitura segura da tentativa do próprio usuário
-- -----------------------------------------------------------------------------

create or replace function public.get_assessment_attempt(
  p_attempt_id uuid
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = pg_catalog, public, private
as $$
declare
  v_user_id uuid := auth.uid();
  v_attempt record;
  v_items jsonb;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  update public.assessment_attempts
  set status = 'expired',
      updated_by = v_user_id,
      metadata = metadata || jsonb_build_object('expired_by_rpc_at', now())
  where id = p_attempt_id
    and user_id = v_user_id
    and status = 'in_progress'
    and expires_at is not null
    and expires_at <= now()
    and archived_at is null;

  select
    a.*,
    t.code as test_code,
    t.title as test_title,
    t.purpose as test_purpose,
    t.time_limit_minutes,
    tv.version_code,
    tv.passing_score,
    tv.legal_min_score
  into v_attempt
  from public.assessment_attempts a
  join public.assessment_tests t
    on t.id = a.test_id
   and t.organization_id = a.organization_id
  join public.assessment_test_versions tv
    on tv.id = a.test_version_id
   and tv.organization_id = a.organization_id
   and tv.test_id = a.test_id
  where a.id = p_attempt_id
    and a.user_id = v_user_id
    and a.archived_at is null;

  if not found then
    raise exception 'ATTEMPT_NOT_FOUND' using errcode = 'P0002';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'attempt_item_id', ai.id,
        'position_no', ai.position_no,
        'block_code', ai.block_code,
        'prompt', ai.prompt_snapshot,
        'options', (
          select coalesce(
            jsonb_agg(
              jsonb_build_object(
                'code', ordered_options.option_code,
                'text', ai.options_snapshot ->> ordered_options.option_code
              )
              order by ordered_options.ordinality
            ),
            '[]'::jsonb
          )
          from jsonb_array_elements_text(ai.option_order)
            with ordinality as ordered_options(option_code, ordinality)
        ),
        'selected_option_code', answer.selected_option_code,
        'answered_at', answer.answered_at
      )
      order by ai.position_no
    ),
    '[]'::jsonb
  )
  into v_items
  from public.assessment_attempt_items ai
  left join public.assessment_attempt_answers answer
    on answer.attempt_item_id = ai.id
   and answer.attempt_id = ai.attempt_id
   and answer.organization_id = ai.organization_id
   and answer.archived_at is null
  where ai.attempt_id = p_attempt_id
    and ai.organization_id = v_attempt.organization_id
    and ai.archived_at is null;

  return jsonb_build_object(
    'attempt_id', v_attempt.id,
    'organization_id', v_attempt.organization_id,
    'test_id', v_attempt.test_id,
    'test_code', v_attempt.test_code,
    'test_title', v_attempt.test_title,
    'test_purpose', v_attempt.test_purpose,
    'version_id', v_attempt.test_version_id,
    'version_code', v_attempt.version_code,
    'attempt_no', v_attempt.attempt_no,
    'status', v_attempt.status,
    'started_at', v_attempt.started_at,
    'expires_at', v_attempt.expires_at,
    'submitted_at', v_attempt.submitted_at,
    'graded_at', v_attempt.graded_at,
    'total_questions', v_attempt.total_questions,
    'answered_questions', v_attempt.answered_questions,
    'passing_score', v_attempt.passing_score,
    'legal_min_score', v_attempt.legal_min_score,
    'items', v_items
  );
end;
$$;

-- -----------------------------------------------------------------------------
-- Início ou retomada de tentativa
-- -----------------------------------------------------------------------------

create or replace function public.start_assessment_attempt(
  p_organization_id uuid,
  p_test_id uuid
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = pg_catalog, public, private
as $$
declare
  v_user_id uuid := auth.uid();
  v_member_id uuid;
  v_test_id uuid;
  v_version_id uuid;
  v_question_count integer;
  v_time_limit_minutes integer;
  v_max_attempts integer;
  v_cooldown_hours integer;
  v_randomize_questions boolean;
  v_randomize_options boolean;
  v_existing_attempt_id uuid;
  v_attempts_used integer;
  v_last_terminal_at timestamptz;
  v_attempt_no integer;
  v_attempt_id uuid;
  v_inserted_items integer;
  v_catalog_questions integer;
  v_private_keys integer;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  select om.id
  into v_member_id
  from public.organization_members om
  join public.profiles p
    on p.id = om.user_id
   and p.status = 'active'
   and p.archived_at is null
  where om.organization_id = p_organization_id
    and om.user_id = v_user_id
    and om.status = 'active'
    and om.archived_at is null;

  if v_member_id is null then
    raise exception 'ACTIVE_MEMBERSHIP_REQUIRED' using errcode = '42501';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(
      p_organization_id::text || ':' || v_member_id::text || ':' || p_test_id::text,
      0
    )
  );

  select
    t.id,
    tv.id,
    tv.question_count,
    t.time_limit_minutes,
    t.max_attempts,
    t.cooldown_hours,
    tv.randomize_questions,
    tv.randomize_options
  into
    v_test_id,
    v_version_id,
    v_question_count,
    v_time_limit_minutes,
    v_max_attempts,
    v_cooldown_hours,
    v_randomize_questions,
    v_randomize_options
  from public.assessment_tests t
  join public.assessment_test_versions tv
    on tv.test_id = t.id
   and tv.organization_id = t.organization_id
   and tv.status = 'published'
   and tv.archived_at is null
   and (tv.valid_from is null or tv.valid_from <= now())
   and (tv.valid_until is null or tv.valid_until >= now())
  where t.id = p_test_id
    and t.organization_id = p_organization_id
    and t.status = 'active'
    and t.archived_at is null;

  if v_version_id is null then
    raise exception 'ASSESSMENT_NOT_PUBLISHED' using errcode = 'P0001';
  end if;

  if not private.assessment_prerequisites_met(
    p_organization_id,
    v_member_id,
    v_test_id
  ) then
    raise exception 'ASSESSMENT_PREREQUISITE_NOT_MET' using errcode = 'P0001';
  end if;

  update public.assessment_attempts
  set status = 'expired',
      updated_by = v_user_id,
      metadata = metadata || jsonb_build_object('expired_before_restart_at', now())
  where organization_id = p_organization_id
    and organization_member_id = v_member_id
    and test_version_id = v_version_id
    and status = 'in_progress'
    and expires_at is not null
    and expires_at <= now()
    and archived_at is null;

  select a.id
  into v_existing_attempt_id
  from public.assessment_attempts a
  where a.organization_id = p_organization_id
    and a.organization_member_id = v_member_id
    and a.test_version_id = v_version_id
    and a.status = 'in_progress'
    and (a.expires_at is null or a.expires_at > now())
    and a.archived_at is null
  order by a.started_at desc
  limit 1;

  if v_existing_attempt_id is not null then
    return public.get_assessment_attempt(v_existing_attempt_id);
  end if;

  select
    count(*) filter (where a.status <> 'cancelled')::integer,
    max(coalesce(a.graded_at, a.submitted_at, a.started_at)) filter (
      where a.status in ('graded', 'submitted', 'expired')
    ),
    coalesce(max(a.attempt_no), 0) + 1
  into v_attempts_used, v_last_terminal_at, v_attempt_no
  from public.assessment_attempts a
  where a.organization_id = p_organization_id
    and a.organization_member_id = v_member_id
    and a.test_version_id = v_version_id
    and a.archived_at is null;

  if coalesce(v_attempts_used, 0) >= v_max_attempts then
    raise exception 'ASSESSMENT_ATTEMPTS_EXHAUSTED' using errcode = 'P0001';
  end if;

  if v_last_terminal_at is not null
     and v_last_terminal_at + make_interval(hours => v_cooldown_hours) > now() then
    raise exception 'ASSESSMENT_COOLDOWN_ACTIVE' using errcode = 'P0001';
  end if;

  select count(*)
  into v_catalog_questions
  from public.assessment_version_questions vq
  join public.assessment_questions q
    on q.id = vq.question_id
   and q.organization_id = vq.organization_id
   and q.archived_at is null
  where vq.organization_id = p_organization_id
    and vq.test_version_id = v_version_id
    and vq.archived_at is null;

  select count(*)
  into v_private_keys
  from public.assessment_version_questions vq
  join private.assessment_question_keys qk
    on qk.question_id = vq.question_id
   and qk.organization_id = vq.organization_id
  where vq.organization_id = p_organization_id
    and vq.test_version_id = v_version_id
    and vq.archived_at is null;

  if v_catalog_questions <> v_question_count or v_private_keys <> v_question_count then
    raise exception 'ASSESSMENT_CATALOG_INTEGRITY_ERROR' using errcode = 'P0001';
  end if;

  insert into public.assessment_attempts (
    organization_id,
    test_id,
    test_version_id,
    organization_member_id,
    user_id,
    attempt_no,
    status,
    started_at,
    expires_at,
    total_questions,
    answered_questions,
    created_by,
    updated_by,
    metadata
  ) values (
    p_organization_id,
    v_test_id,
    v_version_id,
    v_member_id,
    v_user_id,
    v_attempt_no,
    'in_progress',
    now(),
    case
      when v_time_limit_minutes is null then null
      else now() + make_interval(mins => v_time_limit_minutes)
    end,
    0,
    0,
    v_user_id,
    v_user_id,
    jsonb_build_object('created_by_rpc', 'start_assessment_attempt')
  )
  returning id into v_attempt_id;

  with question_pool as (
    select
      vq.question_id,
      q.competency_id,
      q.block_code,
      q.prompt,
      vq.points,
      vq.sequence_no,
      case
        when v_randomize_questions then random()
        else vq.sequence_no::double precision
      end as question_sort
    from public.assessment_version_questions vq
    join public.assessment_questions q
      on q.id = vq.question_id
     and q.organization_id = vq.organization_id
     and q.archived_at is null
    where vq.organization_id = p_organization_id
      and vq.test_version_id = v_version_id
      and vq.archived_at is null
    order by question_sort, vq.sequence_no
    limit v_question_count
  ), numbered_questions as (
    select
      question_pool.*,
      row_number() over (order by question_sort, sequence_no)::integer as position_no
    from question_pool
  )
  insert into public.assessment_attempt_items (
    organization_id,
    attempt_id,
    question_id,
    competency_id,
    block_code,
    position_no,
    points,
    prompt_snapshot,
    options_snapshot,
    option_order,
    created_by,
    updated_by,
    metadata
  )
  select
    p_organization_id,
    v_attempt_id,
    nq.question_id,
    nq.competency_id,
    nq.block_code,
    nq.position_no,
    nq.points,
    nq.prompt,
    option_data.options_snapshot,
    option_data.option_order,
    v_user_id,
    v_user_id,
    jsonb_build_object('snapshot_version_id', v_version_id)
  from numbered_questions nq
  cross join lateral (
    select
      jsonb_object_agg(option_rows.option_code, option_rows.option_text order by option_rows.option_code)
        as options_snapshot,
      jsonb_agg(option_rows.option_code order by option_rows.option_sort, option_rows.option_code)
        as option_order
    from (
      select
        o.option_code,
        o.option_text,
        case
          when v_randomize_options then random()
          else case o.option_code
            when 'A' then 1::double precision
            when 'B' then 2::double precision
            when 'C' then 3::double precision
            when 'D' then 4::double precision
          end
        end as option_sort
      from public.assessment_question_options o
      where o.organization_id = p_organization_id
        and o.question_id = nq.question_id
        and o.archived_at is null
    ) option_rows
  ) option_data;

  get diagnostics v_inserted_items = row_count;

  if v_inserted_items <> v_question_count then
    raise exception 'ASSESSMENT_SNAPSHOT_INTEGRITY_ERROR' using errcode = 'P0001';
  end if;

  update public.assessment_attempts
  set total_questions = v_inserted_items,
      updated_by = v_user_id
  where id = v_attempt_id;

  return public.get_assessment_attempt(v_attempt_id);
end;
$$;

-- -----------------------------------------------------------------------------
-- Salvamento de resposta
-- -----------------------------------------------------------------------------

create or replace function public.save_assessment_answer(
  p_attempt_id uuid,
  p_attempt_item_id uuid,
  p_selected_option_code text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = pg_catalog, public, private
as $$
declare
  v_user_id uuid := auth.uid();
  v_attempt record;
  v_option_code text := upper(trim(p_selected_option_code));
  v_answered_questions integer;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if v_option_code not in ('A', 'B', 'C', 'D') then
    raise exception 'INVALID_OPTION_CODE' using errcode = '22023';
  end if;

  select a.*
  into v_attempt
  from public.assessment_attempts a
  where a.id = p_attempt_id
    and a.user_id = v_user_id
    and a.archived_at is null
  for update;

  if not found then
    raise exception 'ATTEMPT_NOT_FOUND' using errcode = 'P0002';
  end if;

  if v_attempt.status <> 'in_progress' then
    raise exception 'ATTEMPT_NOT_EDITABLE' using errcode = 'P0001';
  end if;

  if v_attempt.expires_at is not null and v_attempt.expires_at <= now() then
    update public.assessment_attempts
    set status = 'expired',
        updated_by = v_user_id,
        metadata = metadata || jsonb_build_object('expired_while_saving_at', now())
    where id = p_attempt_id;

    return jsonb_build_object(
      'attempt_id', p_attempt_id,
      'status', 'expired',
      'error_code', 'ATTEMPT_EXPIRED'
    );
  end if;

  if not exists (
    select 1
    from public.assessment_attempt_items ai
    where ai.id = p_attempt_item_id
      and ai.attempt_id = p_attempt_id
      and ai.organization_id = v_attempt.organization_id
      and ai.archived_at is null
      and ai.options_snapshot ? v_option_code
  ) then
    raise exception 'ATTEMPT_ITEM_OR_OPTION_NOT_FOUND' using errcode = 'P0002';
  end if;

  insert into public.assessment_attempt_answers (
    organization_id,
    attempt_id,
    attempt_item_id,
    selected_option_code,
    answered_at,
    created_by,
    updated_by,
    metadata
  ) values (
    v_attempt.organization_id,
    p_attempt_id,
    p_attempt_item_id,
    v_option_code,
    now(),
    v_user_id,
    v_user_id,
    jsonb_build_object('saved_by_rpc', 'save_assessment_answer')
  )
  on conflict (attempt_item_id)
  do update set
    selected_option_code = excluded.selected_option_code,
    answered_at = excluded.answered_at,
    updated_by = v_user_id,
    archived_at = null,
    metadata = assessment_attempt_answers.metadata
      || jsonb_build_object('last_saved_by_rpc', 'save_assessment_answer');

  select count(*)::integer
  into v_answered_questions
  from public.assessment_attempt_answers answer
  where answer.attempt_id = p_attempt_id
    and answer.organization_id = v_attempt.organization_id
    and answer.archived_at is null;

  update public.assessment_attempts
  set answered_questions = v_answered_questions,
      updated_by = v_user_id
  where id = p_attempt_id;

  return jsonb_build_object(
    'attempt_id', p_attempt_id,
    'attempt_item_id', p_attempt_item_id,
    'selected_option_code', v_option_code,
    'answered_questions', v_answered_questions,
    'total_questions', v_attempt.total_questions,
    'saved_at', now()
  );
end;
$$;

-- -----------------------------------------------------------------------------
-- Resultado seguro do próprio usuário
-- -----------------------------------------------------------------------------

create or replace function public.get_assessment_attempt_result(
  p_attempt_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $$
declare
  v_user_id uuid := auth.uid();
  v_attempt record;
  v_competencies jsonb;
  v_review_available boolean;
  v_review jsonb;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  select
    a.*,
    t.code as test_code,
    t.title as test_title,
    t.purpose as test_purpose,
    t.max_attempts,
    tv.version_code,
    tv.passing_score,
    tv.legal_min_score,
    tv.show_review_after_submit
  into v_attempt
  from public.assessment_attempts a
  join public.assessment_tests t
    on t.id = a.test_id
   and t.organization_id = a.organization_id
  join public.assessment_test_versions tv
    on tv.id = a.test_version_id
   and tv.organization_id = a.organization_id
   and tv.test_id = a.test_id
  where a.id = p_attempt_id
    and a.user_id = v_user_id
    and a.archived_at is null;

  if not found then
    raise exception 'ATTEMPT_NOT_FOUND' using errcode = 'P0002';
  end if;

  if v_attempt.status <> 'graded' then
    raise exception 'ATTEMPT_NOT_GRADED' using errcode = 'P0001';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'competency_id', score.competency_id,
        'competency_code', competency.code,
        'competency_name', competency.name,
        'is_legal', competency.is_legal,
        'questions_count', score.questions_count,
        'correct_count', score.correct_count,
        'score', score.score,
        'passed', score.passed
      )
      order by competency.sequence_no
    ),
    '[]'::jsonb
  )
  into v_competencies
  from public.assessment_competency_scores score
  join public.competency_domains competency
    on competency.id = score.competency_id
   and competency.organization_id = score.organization_id
  where score.attempt_id = p_attempt_id
    and score.organization_id = v_attempt.organization_id
    and score.archived_at is null;

  v_review_available := private.assessment_review_available(p_attempt_id);

  if v_review_available then
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'position_no', ai.position_no,
          'block_code', ai.block_code,
          'prompt', ai.prompt_snapshot,
          'options', (
            select coalesce(
              jsonb_agg(
                jsonb_build_object(
                  'code', ordered_options.option_code,
                  'text', ai.options_snapshot ->> ordered_options.option_code
                )
                order by ordered_options.ordinality
              ),
              '[]'::jsonb
            )
            from jsonb_array_elements_text(ai.option_order)
              with ordinality as ordered_options(option_code, ordinality)
          ),
          'selected_option_code', answer.selected_option_code,
          'correct_option_code', question_key.correct_option_code,
          'is_correct', grade.is_correct,
          'is_critical_error', grade.is_critical_error,
          'justification', question_key.justification,
          'source_reference', question_key.source_reference
        )
        order by ai.position_no
      ),
      '[]'::jsonb
    )
    into v_review
    from public.assessment_attempt_items ai
    join public.assessment_attempt_answers answer
      on answer.attempt_item_id = ai.id
     and answer.attempt_id = ai.attempt_id
     and answer.organization_id = ai.organization_id
     and answer.archived_at is null
    join private.assessment_attempt_grades grade
      on grade.attempt_item_id = ai.id
     and grade.attempt_id = ai.attempt_id
     and grade.organization_id = ai.organization_id
    join private.assessment_question_keys question_key
      on question_key.question_id = ai.question_id
     and question_key.organization_id = ai.organization_id
    where ai.attempt_id = p_attempt_id
      and ai.organization_id = v_attempt.organization_id
      and ai.archived_at is null;
  else
    v_review := '[]'::jsonb;
  end if;

  return jsonb_build_object(
    'attempt_id', v_attempt.id,
    'test_id', v_attempt.test_id,
    'test_code', v_attempt.test_code,
    'test_title', v_attempt.test_title,
    'test_purpose', v_attempt.test_purpose,
    'version_code', v_attempt.version_code,
    'attempt_no', v_attempt.attempt_no,
    'status', v_attempt.status,
    'submitted_at', v_attempt.submitted_at,
    'graded_at', v_attempt.graded_at,
    'total_questions', v_attempt.total_questions,
    'answered_questions', v_attempt.answered_questions,
    'correct_answers', v_attempt.correct_answers,
    'overall_score', v_attempt.overall_score,
    'legal_score', v_attempt.legal_score,
    'passing_score', v_attempt.passing_score,
    'legal_min_score', v_attempt.legal_min_score,
    'critical_errors', v_attempt.critical_errors,
    'passed', v_attempt.passed,
    'result_reason', v_attempt.result_reason,
    'competency_scores', v_competencies,
    'review_available', v_review_available,
    'review_policy', case
      when v_attempt.test_purpose = 'diagnostic' then 'immediate_after_grading'
      else 'after_pass_or_final_attempt'
    end,
    'review', v_review
  );
end;
$$;

-- -----------------------------------------------------------------------------
-- Entrega e correção transacional no servidor
-- -----------------------------------------------------------------------------

create or replace function public.submit_assessment_attempt(
  p_attempt_id uuid
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = pg_catalog, public, private
as $$
declare
  v_user_id uuid := auth.uid();
  v_attempt record;
  v_answered_questions integer;
  v_key_count integer;
  v_correct_answers integer;
  v_overall_score numeric(5,2);
  v_legal_score numeric(5,2);
  v_critical_errors integer;
  v_passing_score numeric(5,2);
  v_legal_min_score numeric(5,2);
  v_critical_errors_allowed integer;
  v_test_purpose text;
  v_passed boolean;
  v_result_reason text;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  select a.*
  into v_attempt
  from public.assessment_attempts a
  where a.id = p_attempt_id
    and a.user_id = v_user_id
    and a.archived_at is null
  for update;

  if not found then
    raise exception 'ATTEMPT_NOT_FOUND' using errcode = 'P0002';
  end if;

  if v_attempt.status = 'graded' then
    return public.get_assessment_attempt_result(p_attempt_id);
  end if;

  if v_attempt.status <> 'in_progress' then
    raise exception 'ATTEMPT_NOT_SUBMITTABLE' using errcode = 'P0001';
  end if;

  if v_attempt.expires_at is not null and v_attempt.expires_at <= now() then
    update public.assessment_attempts
    set status = 'expired',
        updated_by = v_user_id,
        metadata = metadata || jsonb_build_object('expired_while_submitting_at', now())
    where id = p_attempt_id;

    return jsonb_build_object(
      'attempt_id', p_attempt_id,
      'status', 'expired',
      'error_code', 'ATTEMPT_EXPIRED'
    );
  end if;

  select count(*)::integer
  into v_answered_questions
  from public.assessment_attempt_answers answer
  where answer.attempt_id = p_attempt_id
    and answer.organization_id = v_attempt.organization_id
    and answer.archived_at is null;

  if v_answered_questions <> v_attempt.total_questions then
    raise exception 'ALL_QUESTIONS_MUST_BE_ANSWERED' using errcode = 'P0001';
  end if;

  select count(*)::integer
  into v_key_count
  from public.assessment_attempt_items ai
  join private.assessment_question_keys question_key
    on question_key.question_id = ai.question_id
   and question_key.organization_id = ai.organization_id
  where ai.attempt_id = p_attempt_id
    and ai.organization_id = v_attempt.organization_id
    and ai.archived_at is null;

  if v_key_count <> v_attempt.total_questions then
    raise exception 'ASSESSMENT_KEY_INTEGRITY_ERROR' using errcode = 'P0001';
  end if;

  select
    tv.passing_score,
    tv.legal_min_score,
    coalesce(level.critical_errors_allowed, 0),
    t.purpose
  into
    v_passing_score,
    v_legal_min_score,
    v_critical_errors_allowed,
    v_test_purpose
  from public.assessment_tests t
  join public.assessment_test_versions tv
    on tv.id = v_attempt.test_version_id
   and tv.organization_id = v_attempt.organization_id
   and tv.test_id = t.id
  left join public.certification_levels level
    on level.id = t.target_level_id
   and level.organization_id = t.organization_id
  where t.id = v_attempt.test_id
    and t.organization_id = v_attempt.organization_id;

  insert into private.assessment_attempt_grades (
    attempt_item_id,
    organization_id,
    attempt_id,
    question_id,
    is_correct,
    points_awarded,
    is_critical_error,
    graded_at,
    metadata
  )
  select
    ai.id,
    ai.organization_id,
    ai.attempt_id,
    ai.question_id,
    answer.selected_option_code = question_key.correct_option_code,
    case
      when answer.selected_option_code = question_key.correct_option_code then ai.points
      else 0
    end,
    answer.selected_option_code <> question_key.correct_option_code
      and question_key.is_critical,
    now(),
    jsonb_build_object('graded_by_rpc', 'submit_assessment_attempt')
  from public.assessment_attempt_items ai
  join public.assessment_attempt_answers answer
    on answer.attempt_item_id = ai.id
   and answer.attempt_id = ai.attempt_id
   and answer.organization_id = ai.organization_id
   and answer.archived_at is null
  join private.assessment_question_keys question_key
    on question_key.question_id = ai.question_id
   and question_key.organization_id = ai.organization_id
  where ai.attempt_id = p_attempt_id
    and ai.organization_id = v_attempt.organization_id
    and ai.archived_at is null;

  select
    count(*) filter (where grade.is_correct)::integer,
    round(
      100 * sum(grade.points_awarded) / nullif(sum(ai.points), 0),
      2
    )::numeric(5,2),
    coalesce(
      round(
        100 * sum(grade.points_awarded) filter (where competency.is_legal)
          / nullif(sum(ai.points) filter (where competency.is_legal), 0),
        2
      ),
      100
    )::numeric(5,2),
    count(*) filter (where grade.is_critical_error)::integer
  into
    v_correct_answers,
    v_overall_score,
    v_legal_score,
    v_critical_errors
  from private.assessment_attempt_grades grade
  join public.assessment_attempt_items ai
    on ai.id = grade.attempt_item_id
   and ai.organization_id = grade.organization_id
   and ai.attempt_id = grade.attempt_id
  join public.competency_domains competency
    on competency.id = ai.competency_id
   and competency.organization_id = ai.organization_id
  where grade.attempt_id = p_attempt_id
    and grade.organization_id = v_attempt.organization_id;

  insert into public.assessment_competency_scores (
    organization_id,
    attempt_id,
    competency_id,
    questions_count,
    correct_count,
    score,
    passed,
    created_by,
    updated_by,
    metadata
  )
  select
    ai.organization_id,
    ai.attempt_id,
    ai.competency_id,
    count(*)::integer,
    count(*) filter (where grade.is_correct)::integer,
    round(
      100 * sum(grade.points_awarded) / nullif(sum(ai.points), 0),
      2
    )::numeric(5,2),
    round(
      100 * sum(grade.points_awarded) / nullif(sum(ai.points), 0),
      2
    ) >= case
      when competency.is_legal then v_legal_min_score
      else v_passing_score
    end,
    v_user_id,
    v_user_id,
    jsonb_build_object('calculated_by_rpc', 'submit_assessment_attempt')
  from public.assessment_attempt_items ai
  join private.assessment_attempt_grades grade
    on grade.attempt_item_id = ai.id
   and grade.organization_id = ai.organization_id
   and grade.attempt_id = ai.attempt_id
  join public.competency_domains competency
    on competency.id = ai.competency_id
   and competency.organization_id = ai.organization_id
  where ai.attempt_id = p_attempt_id
    and ai.organization_id = v_attempt.organization_id
    and ai.archived_at is null
  group by
    ai.organization_id,
    ai.attempt_id,
    ai.competency_id,
    competency.is_legal;

  v_passed :=
    v_overall_score >= v_passing_score
    and v_legal_score >= v_legal_min_score
    and v_critical_errors <= v_critical_errors_allowed;

  v_result_reason := case
    when v_critical_errors > v_critical_errors_allowed then 'critical_error'
    when v_overall_score < v_passing_score then 'overall_score_below_minimum'
    when v_legal_score < v_legal_min_score then 'legal_score_below_minimum'
    when v_test_purpose = 'diagnostic' then 'diagnostic_completed'
    else 'approved'
  end;

  update public.assessment_attempts
  set status = 'graded',
      submitted_at = now(),
      graded_at = now(),
      answered_questions = v_answered_questions,
      correct_answers = v_correct_answers,
      overall_score = v_overall_score,
      legal_score = v_legal_score,
      critical_errors = v_critical_errors,
      passed = v_passed,
      result_reason = v_result_reason,
      updated_by = v_user_id,
      metadata = metadata || jsonb_build_object(
        'submitted_by_rpc', 'submit_assessment_attempt',
        'critical_errors_detected', v_critical_errors
      )
  where id = p_attempt_id;

  return public.get_assessment_attempt_result(p_attempt_id);
end;
$$;

-- -----------------------------------------------------------------------------
-- Grants mínimos: somente usuários autenticados chamam as RPCs públicas
-- -----------------------------------------------------------------------------

revoke all on function public.get_available_assessments(uuid) from public, anon, authenticated;
revoke all on function public.get_assessment_attempt(uuid) from public, anon, authenticated;
revoke all on function public.start_assessment_attempt(uuid, uuid) from public, anon, authenticated;
revoke all on function public.save_assessment_answer(uuid, uuid, text) from public, anon, authenticated;
revoke all on function public.get_assessment_attempt_result(uuid) from public, anon, authenticated;
revoke all on function public.submit_assessment_attempt(uuid) from public, anon, authenticated;

grant execute on function public.get_available_assessments(uuid) to authenticated;
grant execute on function public.get_assessment_attempt(uuid) to authenticated;
grant execute on function public.start_assessment_attempt(uuid, uuid) to authenticated;
grant execute on function public.save_assessment_answer(uuid, uuid, text) to authenticated;
grant execute on function public.get_assessment_attempt_result(uuid) to authenticated;
grant execute on function public.submit_assessment_attempt(uuid) to authenticated;

comment on function public.get_available_assessments(uuid) is
  'Lista somente testes ativos e versões publicadas disponíveis ao próprio membro autenticado.';
comment on function public.get_assessment_attempt(uuid) is
  'Entrega o snapshot da tentativa do próprio usuário sem consultar ou expor gabaritos.';
comment on function public.start_assessment_attempt(uuid, uuid) is
  'Inicia ou retoma tentativa própria; exige teste ativo, versão publicada, pré-requisitos, limite e cooldown.';
comment on function public.save_assessment_answer(uuid, uuid, text) is
  'Salva uma resposta da tentativa própria enquanto estiver em andamento e dentro do prazo.';
comment on function public.submit_assessment_attempt(uuid) is
  'Entrega e corrige a tentativa em transação no servidor; grava notas privadas e resultados públicos.';
comment on function public.get_assessment_attempt_result(uuid) is
  'Retorna resultado próprio; revisão detalhada apenas para diagnóstico, aprovação ou última tentativa.';

commit;
