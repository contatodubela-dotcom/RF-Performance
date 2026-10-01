-- ============================================================================
-- RF Performance
-- Avaliações — liberação administrativa de tentativa extraordinária
-- Fase 3 — estado administrativo
--
-- Objetivos:
--   1. fornecer à UI administrativa o estado das tentativas extraordinárias;
--   2. não alterar a assinatura de get_managed_assessment_progress;
--   3. manter a leitura restrita ao Platform Admin;
--   4. permitir identificar:
--        - tentativas normais utilizadas;
--        - limite normal;
--        - créditos extras ativos e já consumidos;
--        - limite efetivo;
--        - crédito ativo existente;
--        - possibilidade de conceder uma nova tentativa;
--        - risco histórico de gabarito anteriormente liberável.
-- ============================================================================

begin;

create or replace function public.get_assessment_extra_attempt_admin_state(
  p_organization_id uuid
)
returns table (
  organization_member_id uuid,
  test_id uuid,
  test_version_id uuid,

  base_max_attempts integer,
  attempts_used integer,

  extra_attempts_available integer,
  extra_attempts_granted_total integer,
  effective_max_attempts integer,

  active_grant_id uuid,
  active_grant_created_at timestamptz,
  active_grant_reason text,

  blocking_attempt_exists boolean,
  passed_in_version boolean,

  last_graded_attempt_id uuid,
  last_graded_attempt_no integer,
  last_graded_passed boolean,

  historical_review_eligible boolean,
  can_grant_extra_attempt boolean
)
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $function$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED'
      using errcode = '42501';
  end if;

  if not private.is_platform_admin() then
    raise exception 'ASSESSMENT_EXTRA_ATTEMPT_MANAGEMENT_FORBIDDEN'
      using errcode = '42501';
  end if;

  return query
  with current_tests as (
    select
      t.id as test_id,
      t.organization_id,
      t.purpose,
      t.max_attempts,
      tv.id as test_version_id,
      tv.show_review_after_submit
    from public.assessment_tests t
    join public.assessment_test_versions tv
      on tv.test_id = t.id
     and tv.organization_id = t.organization_id
     and tv.status = 'published'
     and tv.archived_at is null
     and (
       tv.valid_from is null
       or tv.valid_from <= now()
     )
     and (
       tv.valid_until is null
       or tv.valid_until >= now()
     )
    where t.organization_id = p_organization_id
      and t.status = 'active'
      and t.archived_at is null
  ),

  eligible_members as (
    select
      om.id as organization_member_id
    from public.organization_members om
    join public.profiles p
      on p.id = om.user_id
     and p.status = 'active'
     and p.archived_at is null
    where om.organization_id = p_organization_id
      and om.status = 'active'
      and om.archived_at is null
      and om.role in (
        'salesperson',
        'supervisor',
        'director'
      )
  )

  select
    em.organization_member_id,
    ct.test_id,
    ct.test_version_id,

    ct.max_attempts::integer
      as base_max_attempts,

    coalesce(
      attempt_summary.attempts_used,
      0
    )::integer
      as attempts_used,

    coalesce(
      extra_summary.active_grants,
      0
    )::integer
      as extra_attempts_available,

    coalesce(
      extra_summary.total_grants,
      0
    )::integer
      as extra_attempts_granted_total,

    (
      ct.max_attempts
      + coalesce(
          extra_summary.total_grants,
          0
        )
    )::integer
      as effective_max_attempts,

    extra_summary.active_grant_id,
    extra_summary.active_grant_created_at,
    extra_summary.active_grant_reason,

    coalesce(
      attempt_summary.blocking_attempt_exists,
      false
    )
      as blocking_attempt_exists,

    coalesce(
      attempt_summary.passed_in_version,
      false
    )
      as passed_in_version,

    attempt_summary.last_graded_attempt_id,
    attempt_summary.last_graded_attempt_no,
    attempt_summary.last_graded_passed,

    coalesce(
      ct.show_review_after_submit
      and attempt_summary.last_graded_attempt_id is not null
      and (
        ct.purpose = 'diagnostic'
        or attempt_summary.last_graded_passed is true
        or attempt_summary.last_graded_attempt_no >= ct.max_attempts
      ),
      false
    )
      as historical_review_eligible,

    (
      coalesce(
        attempt_summary.attempts_used,
        0
      ) >= ct.max_attempts

      and coalesce(
        extra_summary.active_grants,
        0
      ) = 0

      and not coalesce(
        attempt_summary.blocking_attempt_exists,
        false
      )

      and not coalesce(
        attempt_summary.passed_in_version,
        false
      )
    )
      as can_grant_extra_attempt

  from eligible_members em

  cross join current_tests ct

  left join lateral (
    select
      count(*) filter (
        where a.status <> 'cancelled'
      )::integer
        as attempts_used,

      bool_or(
        a.status = 'submitted'
        or (
          a.status = 'in_progress'
          and (
            a.expires_at is null
            or a.expires_at > now()
          )
        )
      )
        as blocking_attempt_exists,

      bool_or(
        a.status = 'graded'
        and a.passed is true
      )
        as passed_in_version,

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
      )[1]
        as last_graded_attempt_id,

      (
        array_agg(
          a.attempt_no
          order by
            a.attempt_no desc,
            a.started_at desc,
            a.id desc
        ) filter (
          where a.status = 'graded'
        )
      )[1]
        as last_graded_attempt_no,

      (
        array_agg(
          a.passed
          order by
            a.attempt_no desc,
            a.started_at desc,
            a.id desc
        ) filter (
          where a.status = 'graded'
        )
      )[1]
        as last_graded_passed

    from public.assessment_attempts a
    where a.organization_id = p_organization_id
      and a.organization_member_id =
        em.organization_member_id
      and a.test_version_id =
        ct.test_version_id
      and a.archived_at is null
  ) attempt_summary
    on true

  left join lateral (
    select
      count(*) filter (
        where g.status = 'active'
      )::integer
        as active_grants,

      count(*) filter (
        where g.status in (
          'active',
          'consumed'
        )
      )::integer
        as total_grants,

      (
        array_agg(
          g.id
          order by
            g.created_at desc,
            g.id desc
        ) filter (
          where g.status = 'active'
        )
      )[1]
        as active_grant_id,

      (
        array_agg(
          g.created_at
          order by
            g.created_at desc,
            g.id desc
        ) filter (
          where g.status = 'active'
        )
      )[1]
        as active_grant_created_at,

      (
        array_agg(
          g.reason
          order by
            g.created_at desc,
            g.id desc
        ) filter (
          where g.status = 'active'
        )
      )[1]
        as active_grant_reason

    from private.assessment_extra_attempt_grants g
    where g.organization_id = p_organization_id
      and g.organization_member_id =
        em.organization_member_id
      and g.test_version_id =
        ct.test_version_id
      and g.archived_at is null
  ) extra_summary
    on true

  where private.assessment_test_access_allowed(
    p_organization_id,
    em.organization_member_id,
    ct.test_id,
    ct.test_version_id
  )

    -- Para manter a resposta pequena, só devolve avaliações que já atingiram
    -- o limite normal ou que possuem crédito extraordinário ativo.
    and (
      coalesce(
        attempt_summary.attempts_used,
        0
      ) >= ct.max_attempts

      or coalesce(
        extra_summary.active_grants,
        0
      ) > 0
    )

  order by
    em.organization_member_id,
    ct.test_id;
end;
$function$;

comment on function public.get_assessment_extra_attempt_admin_state(
  uuid
) is
  'Estado administrativo das tentativas extraordinárias por participante e versão. Restrito ao Platform Admin; não expõe respostas nem gabaritos.';

revoke all on function public.get_assessment_extra_attempt_admin_state(
  uuid
) from public, anon;

grant execute on function public.get_assessment_extra_attempt_admin_state(
  uuid
) to authenticated;

commit;