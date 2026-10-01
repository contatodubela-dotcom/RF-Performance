-- ============================================================================
-- RF Performance
-- Avaliações — liberação administrativa de tentativa extraordinária
-- Fase 2 — motor
--
-- Objetivos:
--   1. reconhecer crédito extraordinário na disponibilidade da avaliação;
--   2. permitir iniciar uma tentativa além do limite normal somente com crédito;
--   3. consumir o crédito de forma transacional e auditável;
--   4. preservar integralmente todas as tentativas anteriores;
--   5. permitir que a liberação administrativa extraordinária ignore cooldown;
--   6. proteger o gabarito das certificações reprovadas, pois uma nova tentativa
--      pode ser concedida posteriormente pelo administrador.
-- ============================================================================

begin;

-- ============================================================================
-- 1. Política segura de revisão
--
-- Diagnóstico:
--   continua permitindo revisão após correção.
--
-- Certificação:
--   gabarito detalhado somente após aprovação.
--
-- Motivo:
--   enquanto existir a possibilidade administrativa de conceder uma tentativa
--   extraordinária futura, uma reprovação não pode revelar resposta correta,
--   justificativa e fonte e depois permitir nova realização da mesma avaliação.
-- ============================================================================

create or replace function private.assessment_review_available(
  p_attempt_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $function$
  select coalesce(
    tv.show_review_after_submit
    and a.status = 'graded'
    and (
      t.purpose = 'diagnostic'
      or a.passed is true
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
$function$;

comment on function private.assessment_review_available(uuid) is
  'Política segura de revisão: diagnóstico pode exibir revisão após correção; certificação somente após aprovação. Reprovação não revela gabarito porque uma tentativa extraordinária pode ser concedida posteriormente.';

revoke all on function private.assessment_review_available(uuid)
  from public, anon, authenticated;

-- ============================================================================
-- 2. Catálogo do participante reconhece tentativas extraordinárias
-- ============================================================================

create or replace function public.get_available_assessments_unchecked_20260814220311(
  p_organization_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $function$
declare
  v_user_id uuid := auth.uid();
  v_member_id uuid;
  v_tests jsonb;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED'
      using errcode = '42501';
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
    raise exception 'ACTIVE_MEMBERSHIP_REQUIRED'
      using errcode = '42501';
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

        -- Mantido por compatibilidade: limite normal configurado no teste.
        'max_attempts', t.max_attempts,

        -- Novos campos explícitos para a política extraordinária.
        'base_max_attempts', t.max_attempts,
        'extra_attempts_available',
          coalesce(extra_summary.active_grants, 0),
        'extra_attempts_granted_total',
          coalesce(extra_summary.total_grants, 0),
        'effective_max_attempts',
          t.max_attempts + coalesce(extra_summary.total_grants, 0),

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
        'in_progress_attempt_id',
          attempt_summary.in_progress_attempt_id,
        'last_graded_attempt_id',
          attempt_summary.last_graded_attempt_id,
        'last_attempt_status',
          attempt_summary.last_attempt_status,
        'last_attempt_passed',
          attempt_summary.last_attempt_passed,
        'next_attempt_at',
          attempt_summary.next_attempt_at,

        'availability', case
          when not private.assessment_prerequisites_met(
            p_organization_id,
            v_member_id,
            t.id
          ) then
            'locked_prerequisite'

          when attempt_summary.in_progress_attempt_id is not null then
            'in_progress'

          -- Depois de esgotar o limite normal, um crédito ativo reabre
          -- imediatamente a avaliação e representa exatamente uma nova chance.
          when coalesce(attempt_summary.attempts_used, 0) >= t.max_attempts
               and coalesce(extra_summary.active_grants, 0) > 0 then
            'available'

          when coalesce(attempt_summary.attempts_used, 0) >= t.max_attempts then
            'attempts_exhausted'

          when attempt_summary.next_attempt_at is not null
               and attempt_summary.next_attempt_at > now() then
            'cooldown'

          else
            'available'
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
      count(*) filter (
        where a.status <> 'cancelled'
      )::integer as attempts_used,

      (
        array_agg(
          a.id
          order by a.started_at desc
        ) filter (
          where a.status = 'in_progress'
            and (
              a.expires_at is null
              or a.expires_at > now()
            )
        )
      )[1] as in_progress_attempt_id,

      (
        array_agg(
          a.id
          order by
            a.attempt_no desc,
            a.started_at desc,
            a.id desc
        ) filter (
          where a.status = 'graded'
        )
      )[1] as last_graded_attempt_id,

      (
        array_agg(
          a.status
          order by a.started_at desc
        )
      )[1] as last_attempt_status,

      (
        array_agg(
          a.passed
          order by a.started_at desc
        )
      )[1] as last_attempt_passed,

      max(
        coalesce(
          a.graded_at,
          a.submitted_at,
          a.started_at
        )
      ) filter (
        where a.status in (
          'graded',
          'submitted',
          'expired'
        )
      ) + make_interval(
        hours => t.cooldown_hours
      ) as next_attempt_at

    from public.assessment_attempts a
    where a.organization_id = p_organization_id
      and a.organization_member_id = v_member_id
      and a.test_version_id = tv.id
      and a.archived_at is null
  ) attempt_summary
    on true

  left join lateral (
    select
      count(*) filter (
        where g.status = 'active'
      )::integer as active_grants,

      count(*) filter (
        where g.status in ('active', 'consumed')
      )::integer as total_grants

    from private.assessment_extra_attempt_grants g
    where g.organization_id = p_organization_id
      and g.organization_member_id = v_member_id
      and g.test_version_id = tv.id
      and g.archived_at is null
  ) extra_summary
    on true

  where t.organization_id = p_organization_id
    and t.status = 'active'
    and t.archived_at is null
    and private.assessment_test_access_allowed(
      p_organization_id,
      v_member_id,
      t.id,
      tv.id
    );

  return jsonb_build_object(
    'organization_id', p_organization_id,
    'organization_member_id', v_member_id,
    'tests', v_tests
  );
end;
$function$;

revoke all on function public.get_available_assessments_unchecked_20260814220311(
  uuid
) from public, anon, authenticated;

-- ============================================================================
-- 3. Motor de início da avaliação
--
-- Regras:
--   - dentro do limite normal: comportamento atual;
--   - limite normal esgotado: exige exatamente um crédito ativo;
--   - o crédito extraordinário ignora o cooldown;
--   - o crédito somente é marcado como consumido depois que a nova tentativa
--     existe;
--   - qualquer erro posterior na mesma transação desfaz tentativa e consumo.
-- ============================================================================

create or replace function public.start_assessment_attempt_unchecked_20260814220311(
  p_organization_id uuid,
  p_test_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $function$
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

  v_extra_grant_id uuid;
  v_using_extra_attempt boolean := false;
  v_consumed_grants integer := 0;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED'
      using errcode = '42501';
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
    raise exception 'ACTIVE_MEMBERSHIP_REQUIRED'
      using errcode = '42501';
  end if;

  -- A mesma chave é utilizada pela RPC administrativa de concessão.
  -- Isso impede corrida entre "liberar" e "iniciar".
  perform pg_advisory_xact_lock(
    hashtextextended(
      p_organization_id::text
        || ':'
        || v_member_id::text
        || ':'
        || p_test_id::text,
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
    raise exception 'ASSESSMENT_NOT_PUBLISHED'
      using errcode = 'P0001';
  end if;

  if not private.assessment_test_access_allowed(
    p_organization_id,
    v_member_id,
    v_test_id,
    v_version_id
  ) then
    raise exception 'ASSESSMENT_ACCESS_NOT_GRANTED'
      using errcode = '42501';
  end if;

  if not private.assessment_prerequisites_met(
    p_organization_id,
    v_member_id,
    v_test_id
  ) then
    raise exception 'ASSESSMENT_PREREQUISITE_NOT_MET'
      using errcode = 'P0001';
  end if;

  -- Expira tentativas antigas que ficaram abertas além do limite.
  update public.assessment_attempts
  set
    status = 'expired',
    updated_by = v_user_id,
    metadata = metadata || jsonb_build_object(
      'expired_before_restart_at',
      now()
    )
  where organization_id = p_organization_id
    and organization_member_id = v_member_id
    and test_version_id = v_version_id
    and status = 'in_progress'
    and expires_at is not null
    and expires_at <= now()
    and archived_at is null;

  -- Se já existe tentativa válida em andamento, continua nela.
  select a.id
  into v_existing_attempt_id
  from public.assessment_attempts a
  where a.organization_id = p_organization_id
    and a.organization_member_id = v_member_id
    and a.test_version_id = v_version_id
    and a.status = 'in_progress'
    and (
      a.expires_at is null
      or a.expires_at > now()
    )
    and a.archived_at is null
  order by a.started_at desc
  limit 1;

  if v_existing_attempt_id is not null then
    return public.get_assessment_attempt(
      v_existing_attempt_id
    );
  end if;

  select
    count(*) filter (
      where a.status <> 'cancelled'
    )::integer,

    max(
      coalesce(
        a.graded_at,
        a.submitted_at,
        a.started_at
      )
    ) filter (
      where a.status in (
        'graded',
        'submitted',
        'expired'
      )
    ),

    coalesce(
      max(a.attempt_no),
      0
    ) + 1

  into
    v_attempts_used,
    v_last_terminal_at,
    v_attempt_no

  from public.assessment_attempts a
  where a.organization_id = p_organization_id
    and a.organization_member_id = v_member_id
    and a.test_version_id = v_version_id
    and a.archived_at is null;

  -- --------------------------------------------------------------------------
  -- Limite normal esgotado:
  -- procura e bloqueia um crédito extraordinário ativo.
  -- --------------------------------------------------------------------------

  if coalesce(v_attempts_used, 0) >= v_max_attempts then
    select g.id
    into v_extra_grant_id
    from private.assessment_extra_attempt_grants g
    where g.organization_id = p_organization_id
      and g.organization_member_id = v_member_id
      and g.test_version_id = v_version_id
      and g.status = 'active'
      and g.archived_at is null
    order by g.created_at, g.id
    limit 1
    for update;

    if v_extra_grant_id is null then
      raise exception 'ASSESSMENT_ATTEMPTS_EXHAUSTED'
        using errcode = 'P0001';
    end if;

    v_using_extra_attempt := true;
  end if;

  -- O cooldown continua valendo para as tentativas normais.
  -- Uma liberação extraordinária administrativa representa autorização
  -- explícita para uma nova tentativa imediata.
  if not v_using_extra_attempt
     and v_last_terminal_at is not null
     and v_last_terminal_at
       + make_interval(hours => v_cooldown_hours) > now() then
    raise exception 'ASSESSMENT_COOLDOWN_ACTIVE'
      using errcode = 'P0001';
  end if;

  -- --------------------------------------------------------------------------
  -- Integridade do catálogo
  -- --------------------------------------------------------------------------

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

  if v_catalog_questions <> v_question_count
     or v_private_keys <> v_question_count then
    raise exception 'ASSESSMENT_CATALOG_INTEGRITY_ERROR'
      using errcode = 'P0001';
  end if;

  -- --------------------------------------------------------------------------
  -- Criação da nova tentativa
  -- --------------------------------------------------------------------------

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
  )
  values (
    p_organization_id,
    v_test_id,
    v_version_id,
    v_member_id,
    v_user_id,
    v_attempt_no,
    'in_progress',
    now(),

    case
      when v_time_limit_minutes is null then
        null
      else
        now() + make_interval(
          mins => v_time_limit_minutes
        )
    end,

    0,
    0,
    v_user_id,
    v_user_id,

    case
      when v_using_extra_attempt then
        jsonb_build_object(
          'created_by_rpc',
          'start_assessment_attempt',
          'attempt_kind',
          'extra',
          'extra_attempt_grant_id',
          v_extra_grant_id
        )
      else
        jsonb_build_object(
          'created_by_rpc',
          'start_assessment_attempt',
          'attempt_kind',
          'standard'
        )
    end
  )
  returning id
  into v_attempt_id;

  -- --------------------------------------------------------------------------
  -- Consumo transacional do crédito
  --
  -- A tentativa já existe neste ponto.
  -- Se qualquer etapa seguinte falhar, toda a transação será revertida.
  -- --------------------------------------------------------------------------

  if v_using_extra_attempt then
    update private.assessment_extra_attempt_grants
    set
      status = 'consumed',
      consumed_at = now(),
      consumed_attempt_id = v_attempt_id,
      updated_at = now(),
      updated_by = v_user_id,
      metadata = metadata || jsonb_build_object(
        'consumed_by_rpc',
        'start_assessment_attempt',
        'consumed_attempt_no',
        v_attempt_no
      )
    where id = v_extra_grant_id
      and organization_id = p_organization_id
      and organization_member_id = v_member_id
      and test_version_id = v_version_id
      and status = 'active'
      and archived_at is null;

    get diagnostics
      v_consumed_grants = row_count;

    if v_consumed_grants <> 1 then
      raise exception 'ASSESSMENT_EXTRA_ATTEMPT_CONSUME_FAILED'
        using errcode = 'P0001';
    end if;
  end if;

  -- --------------------------------------------------------------------------
  -- Snapshot das questões
  -- --------------------------------------------------------------------------

  with question_pool as (
    select
      vq.question_id,
      q.competency_id,
      q.block_code,
      q.prompt,
      vq.points,
      vq.sequence_no,

      case
        when v_randomize_questions then
          random()
        else
          vq.sequence_no::double precision
      end as question_sort

    from public.assessment_version_questions vq
    join public.assessment_questions q
      on q.id = vq.question_id
     and q.organization_id = vq.organization_id
     and q.archived_at is null

    where vq.organization_id = p_organization_id
      and vq.test_version_id = v_version_id
      and vq.archived_at is null

    order by
      question_sort,
      vq.sequence_no

    limit v_question_count
  ),

  numbered_questions as (
    select
      question_pool.*,
      row_number() over (
        order by
          question_sort,
          sequence_no
      )::integer as position_no
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
    jsonb_build_object(
      'snapshot_version_id',
      v_version_id
    )

  from numbered_questions nq

  cross join lateral (
    select
      jsonb_object_agg(
        option_rows.option_code,
        option_rows.option_text
        order by option_rows.option_code
      ) as options_snapshot,

      jsonb_agg(
        option_rows.option_code
        order by
          option_rows.option_sort,
          option_rows.option_code
      ) as option_order

    from (
      select
        o.option_code,
        o.option_text,

        case
          when v_randomize_options then
            random()
          else
            case o.option_code
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

  get diagnostics
    v_inserted_items = row_count;

  if v_inserted_items <> v_question_count then
    raise exception 'ASSESSMENT_SNAPSHOT_INTEGRITY_ERROR'
      using errcode = 'P0001';
  end if;

  update public.assessment_attempts
  set
    total_questions = v_inserted_items,
    updated_by = v_user_id
  where id = v_attempt_id;

  return public.get_assessment_attempt(
    v_attempt_id
  );
end;
$function$;

comment on function public.start_assessment_attempt_unchecked_20260814220311(
  uuid,
  uuid
) is
  'Implementação interna do início de avaliação. Mantém limite normal e cooldown; após esgotamento, exige e consome atomicamente um crédito extraordinário ativo.';

revoke all on function public.start_assessment_attempt_unchecked_20260814220311(
  uuid,
  uuid
) from public, anon, authenticated;

commit;