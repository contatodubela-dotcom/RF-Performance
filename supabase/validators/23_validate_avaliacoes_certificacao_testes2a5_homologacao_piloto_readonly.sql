-- ============================================================================
-- RF Performance — Avaliações e Certificações — Fase 1E
-- Validador somente leitura da homologação individual dos Testes 2 a 5
--
-- Resultado esperado: todas as linhas com status = PASS.
-- Não altera nenhum registro.
-- ============================================================================

with constants as (
  select
    '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid as organization_id,
    '49239d09-0f85-471f-8f46-5c240cd98600'::uuid as pilot_member_id,
    'e88242b6-e44e-4de7-97cf-dbefc0605eaf'::uuid as pilot_user_id,
    '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid as diagnostic_test_id,
    'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid as diagnostic_version_id,
    '72e1c6e0-2d62-47e3-85ec-6de2f4eaddbe'::uuid as pilot_attempt_id
),
targets as (
  select *
  from (
    values
      (
        2,
        '99f4b9fe-66c2-591e-a670-064675a64650'::uuid,
        'd608e0c6-efc6-500c-9258-64a774b4b169'::uuid,
        'teste_2_nivel_1'::text,
        'teste_1_diagnostico'::text,
        'graded'::text,
        70.00::numeric,
        80.00::numeric,
        true
      ),
      (
        3,
        '8a7754bc-7777-503c-a6aa-213b48f03f28'::uuid,
        'a68e7ffa-2c6e-5e95-9ab9-a0b3d9b307ef'::uuid,
        'teste_3_intermediario'::text,
        'teste_2_nivel_1'::text,
        'passed'::text,
        75.00::numeric,
        80.00::numeric,
        false
      ),
      (
        4,
        'c57f65fc-5084-501d-bbc1-b371d7fb5f02'::uuid,
        '22d2e41e-b5fc-5765-a1a8-edfde5c698ed'::uuid,
        'teste_4_nivel_2'::text,
        'teste_3_intermediario'::text,
        'passed'::text,
        80.00::numeric,
        85.00::numeric,
        false
      ),
      (
        5,
        'abe87462-d06b-5a84-8bc5-a4841bb17cb2'::uuid,
        '7004fc3c-a1e7-5e28-a66b-143d3bffb869'::uuid,
        'teste_5_nivel_3'::text,
        'teste_4_nivel_2'::text,
        'passed'::text,
        88.00::numeric,
        90.00::numeric,
        false
      )
  ) as x(
    sequence_no,
    test_id,
    version_id,
    test_code,
    prerequisite_test_code,
    prerequisite_result,
    passing_score,
    legal_min_score,
    prerequisite_expected
  )
),
target_inventory as (
  select
    target.sequence_no,
    target.test_id,
    target.version_id,
    target.test_code,
    target.prerequisite_test_code,
    target.prerequisite_result,
    target.passing_score,
    target.legal_min_score,
    target.prerequisite_expected,
    t.status as test_status,
    t.metadata as test_metadata,
    tv.status as version_status,
    tv.published_at,
    tv.valid_from,
    tv.metadata as version_metadata,
    count(distinct avq.question_id)
      filter (where avq.archived_at is null)::integer
      as linked_questions,
    count(distinct q.id)
      filter (
        where q.archived_at is null
          and q.status = 'reviewed'
      )::integer
      as reviewed_questions,
    count(distinct qo.id)
      filter (where qo.archived_at is null)::integer
      as active_options,
    count(distinct qk.question_id)::integer
      as private_keys,
    count(distinct avq.sequence_no)
      filter (where avq.archived_at is null)::integer
      as distinct_positions,
    min(avq.sequence_no)
      filter (where avq.archived_at is null)
      as first_position,
    max(avq.sequence_no)
      filter (where avq.archived_at is null)
      as last_position
  from targets target
  join public.assessment_tests t
    on t.id = target.test_id
   and t.organization_id =
       (select organization_id from constants)
   and t.archived_at is null
  join public.assessment_test_versions tv
    on tv.id = target.version_id
   and tv.organization_id = t.organization_id
   and tv.test_id = t.id
   and tv.archived_at is null
  left join public.assessment_version_questions avq
    on avq.organization_id = t.organization_id
   and avq.test_version_id = tv.id
  left join public.assessment_questions q
    on q.organization_id = avq.organization_id
   and q.id = avq.question_id
  left join public.assessment_question_options qo
    on qo.organization_id = q.organization_id
   and qo.question_id = q.id
  left join private.assessment_question_keys qk
    on qk.organization_id = q.organization_id
   and qk.question_id = q.id
  group by
    target.sequence_no,
    target.test_id,
    target.version_id,
    target.test_code,
    target.prerequisite_test_code,
    target.prerequisite_result,
    target.passing_score,
    target.legal_min_score,
    target.prerequisite_expected,
    t.status,
    t.metadata,
    tv.status,
    tv.published_at,
    tv.valid_from,
    tv.metadata
),
grant_inventory as (
  select
    target.sequence_no,
    count(access_grant.id)
      filter (
        where access_grant.access_scope = 'member'
          and access_grant.organization_member_id =
              (select pilot_member_id from constants)
          and access_grant.status = 'active'
          and access_grant.archived_at is null
          and access_grant.valid_from <= now()
          and (
            access_grant.valid_until is null
            or access_grant.valid_until > now()
          )
      )::integer as pilot_member_grants,
    count(access_grant.id)
      filter (
        where access_grant.access_scope = 'organization'
          and access_grant.status = 'active'
          and access_grant.archived_at is null
      )::integer as organization_grants
  from targets target
  left join private.assessment_test_access_grants access_grant
    on access_grant.organization_id =
       (select organization_id from constants)
   and access_grant.test_id = target.test_id
   and access_grant.test_version_id = target.version_id
  group by target.sequence_no
),
checks as (
  select '01_quatro_testes_alvo_encontrados'::text as check_name,
    case when (select count(*) from target_inventory) = 4
      then 'PASS' else 'FAIL' end as status

  union all
  select '02_quatro_testes_alvo_ativos',
    case when (
      select count(*)
      from target_inventory
      where test_status = 'active'
    ) = 4 then 'PASS' else 'FAIL' end

  union all
  select '03_quatro_versoes_publicadas',
    case when (
      select count(*)
      from target_inventory
      where version_status = 'published'
        and published_at is not null
        and valid_from is not null
        and valid_from <= now()
    ) = 4 then 'PASS' else 'FAIL' end

  union all
  select '04_scores_e_metadados_de_progressao_preservados',
    case when not exists (
      select 1
      from target_inventory
      where test_metadata ->> 'prerequisite_test_code'
            is distinct from prerequisite_test_code
         or test_metadata ->> 'prerequisite_result'
            is distinct from prerequisite_result
    ) then 'PASS' else 'FAIL' end

  union all
  select '05_notas_minimas_preservadas',
    case when not exists (
      select 1
      from target_inventory inventory
      join public.assessment_test_versions tv
        on tv.id = inventory.version_id
       and tv.organization_id =
           (select organization_id from constants)
      where tv.passing_score <> inventory.passing_score
         or tv.legal_min_score <> inventory.legal_min_score
    ) then 'PASS' else 'FAIL' end

  union all
  select '06_questoes_vinculadas_30_por_teste',
    case when not exists (
      select 1
      from target_inventory
      where linked_questions <> 30
    ) then 'PASS' else 'FAIL' end

  union all
  select '07_questoes_revisadas_30_por_teste',
    case when not exists (
      select 1
      from target_inventory
      where reviewed_questions <> 30
    ) then 'PASS' else 'FAIL' end

  union all
  select '08_alternativas_ativas_120_por_teste',
    case when not exists (
      select 1
      from target_inventory
      where active_options <> 120
    ) then 'PASS' else 'FAIL' end

  union all
  select '09_gabaritos_privados_30_por_teste',
    case when not exists (
      select 1
      from target_inventory
      where private_keys <> 30
    ) then 'PASS' else 'FAIL' end

  union all
  select '10_posicoes_1_a_30_por_teste',
    case when not exists (
      select 1
      from target_inventory
      where distinct_positions <> 30
         or first_position <> 1
         or last_position <> 30
    ) then 'PASS' else 'FAIL' end

  union all
  select '11_marcador_de_publicacao_fase1e_nos_testes',
    case when not exists (
      select 1
      from target_inventory
      where test_metadata ->> 'publication_phase' <> '1E'
         or test_metadata ->> 'publication_mode'
            <> 'individual_pilot_progressive'
    ) then 'PASS' else 'FAIL' end

  union all
  select '12_marcador_de_publicacao_fase1e_nas_versoes',
    case when not exists (
      select 1
      from target_inventory
      where version_metadata ->> 'publication_phase' <> '1E'
         or version_metadata ->> 'publication_mode'
            <> 'individual_pilot_progressive'
         or version_metadata ->> 'publication_status'
            <> 'homologation_published'
    ) then 'PASS' else 'FAIL' end

  union all
  select '13_um_grant_individual_ativo_por_teste',
    case when not exists (
      select 1
      from grant_inventory
      where pilot_member_grants <> 1
    ) then 'PASS' else 'FAIL' end

  union all
  select '14_quatro_grants_individuais_ativos',
    case when (
      select coalesce(sum(pilot_member_grants), 0)
      from grant_inventory
    ) = 4 then 'PASS' else 'FAIL' end

  union all
  select '15_sem_grants_organizacionais',
    case when (
      select coalesce(sum(organization_grants), 0)
      from grant_inventory
    ) = 0 then 'PASS' else 'FAIL' end

  union all
  select '16_piloto_tem_acesso_aos_quatro_testes',
    case when not exists (
      select 1
      from targets target
      where not private.assessment_test_access_allowed(
        (select organization_id from constants),
        (select pilot_member_id from constants),
        target.test_id,
        target.version_id
      )
    ) then 'PASS' else 'FAIL' end

  union all
  select '17_outros_membros_sem_acesso_aos_testes',
    case when not exists (
      select 1
      from public.organization_members om
      cross join targets target
      where om.organization_id =
            (select organization_id from constants)
        and om.id <> (select pilot_member_id from constants)
        and om.status = 'active'
        and om.archived_at is null
        and private.assessment_test_access_allowed(
          om.organization_id,
          om.id,
          target.test_id,
          target.version_id
        )
    ) then 'PASS' else 'FAIL' end

  union all
  select '18_teste2_liberado_pelo_diagnostico_corrigido',
    case when private.assessment_prerequisites_met(
      (select organization_id from constants),
      (select pilot_member_id from constants),
      '99f4b9fe-66c2-591e-a670-064675a64650'::uuid
    ) then 'PASS' else 'FAIL' end

  union all
  select '19_teste3_bloqueado_ate_aprovacao_teste2',
    case when not private.assessment_prerequisites_met(
      (select organization_id from constants),
      (select pilot_member_id from constants),
      '8a7754bc-7777-503c-a6aa-213b48f03f28'::uuid
    ) then 'PASS' else 'FAIL' end

  union all
  select '20_teste4_bloqueado_ate_aprovacao_teste3',
    case when not private.assessment_prerequisites_met(
      (select organization_id from constants),
      (select pilot_member_id from constants),
      'c57f65fc-5084-501d-bbc1-b371d7fb5f02'::uuid
    ) then 'PASS' else 'FAIL' end

  union all
  select '21_teste5_bloqueado_ate_aprovacao_teste4',
    case when not private.assessment_prerequisites_met(
      (select organization_id from constants),
      (select pilot_member_id from constants),
      'abe87462-d06b-5a84-8bc5-a4841bb17cb2'::uuid
    ) then 'PASS' else 'FAIL' end

  union all
  select '22_nenhuma_tentativa_criada_nos_testes2a5',
    case when (
      select count(*)
      from public.assessment_attempts a
      where a.organization_id =
            (select organization_id from constants)
        and a.test_id in (select test_id from targets)
        and a.archived_at is null
    ) = 0 then 'PASS' else 'FAIL' end

  union all
  select '23_cinco_testes_ativos_no_catalogo',
    case when (
      select count(*)
      from public.assessment_tests t
      where t.organization_id =
            (select organization_id from constants)
        and t.status = 'active'
        and t.archived_at is null
    ) = 5 then 'PASS' else 'FAIL' end

  union all
  select '24_cinco_versoes_publicadas_no_catalogo',
    case when (
      select count(*)
      from public.assessment_test_versions tv
      where tv.organization_id =
            (select organization_id from constants)
        and tv.status = 'published'
        and tv.archived_at is null
    ) = 5 then 'PASS' else 'FAIL' end

  union all
  select '25_publicacao_do_teste1_preservada',
    case when exists (
      select 1
      from public.assessment_tests t
      join public.assessment_test_versions tv
        on tv.organization_id = t.organization_id
       and tv.test_id = t.id
       and tv.id = (select diagnostic_version_id from constants)
       and tv.status = 'published'
       and tv.published_at is not null
       and tv.archived_at is null
      where t.id = (select diagnostic_test_id from constants)
        and t.organization_id =
            (select organization_id from constants)
        and t.status = 'active'
        and t.archived_at is null
    ) then 'PASS' else 'FAIL' end

  union all
  select '26_acesso_individual_ao_teste1_preservado',
    case when private.assessment_test_access_allowed(
      (select organization_id from constants),
      (select pilot_member_id from constants),
      (select diagnostic_test_id from constants),
      (select diagnostic_version_id from constants)
    ) then 'PASS' else 'FAIL' end

  union all
  select '27_tentativa_piloto_29_de_30_preservada',
    case when exists (
      select 1
      from public.assessment_attempts a
      cross join constants c
      where a.id = c.pilot_attempt_id
        and a.organization_id = c.organization_id
        and a.organization_member_id = c.pilot_member_id
        and a.test_id = c.diagnostic_test_id
        and a.test_version_id = c.diagnostic_version_id
        and a.status = 'graded'
        and a.attempt_no = 1
        and a.total_questions = 30
        and a.answered_questions = 30
        and a.correct_answers = 29
        and a.overall_score = 96.67
        and a.legal_score = 100.00
        and a.archived_at is null
    ) then 'PASS' else 'FAIL' end

  union all
  select '28_respostas_do_piloto_preservadas_30',
    case when (
      select count(*)
      from public.assessment_attempt_answers answer
      cross join constants c
      where answer.organization_id = c.organization_id
        and answer.attempt_id = c.pilot_attempt_id
        and answer.archived_at is null
    ) = 30 then 'PASS' else 'FAIL' end

  union all
  select '29_notas_privadas_do_piloto_preservadas_30',
    case when (
      select count(*)
      from private.assessment_attempt_grades grade
      cross join constants c
      where grade.organization_id = c.organization_id
        and grade.attempt_id = c.pilot_attempt_id
    ) = 30 then 'PASS' else 'FAIL' end

  union all
  select '30_diagnostico_continua_sem_certificacao',
    case when (
      select count(*)
      from public.member_certifications certification
      cross join constants c
      where certification.organization_id = c.organization_id
        and certification.organization_member_id = c.pilot_member_id
        and certification.archived_at is null
    ) = 0 then 'PASS' else 'FAIL' end
)
select check_name, status
from checks
order by check_name;
