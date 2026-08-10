-- ============================================================================
-- RF Performance — Avaliações e Certificações — Fase 1D
-- Expõe ao participante o identificador da última tentativa corrigida
-- para permitir acesso seguro ao resultado já existente.
--
-- Escopo:
--   - altera somente public.get_available_assessments(uuid);
--   - não cria, altera ou exclui tentativas, respostas, notas ou certificados;
--   - mantém o portão de acesso individual e os grants existentes;
--   - o resultado continua protegido por get_assessment_attempt_result(uuid).
-- ============================================================================

begin;

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
        'last_graded_attempt_id', attempt_summary.last_graded_attempt_id,
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
      (
        array_agg(
          a.id
          order by a.attempt_no desc, a.started_at desc, a.id desc
        ) filter (where a.status = 'graded')
      )[1] as last_graded_attempt_id,
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
$$;

revoke all on function public.get_available_assessments(uuid)
from public, anon, authenticated;

grant execute on function public.get_available_assessments(uuid)
to authenticated;

comment on function public.get_available_assessments(uuid) is
  'Lista avaliações liberadas ao membro autenticado e inclui o ID da última tentativa corrigida para navegação segura ao resultado.';

commit;
