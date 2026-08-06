-- ============================================================================
-- RF Performance — Avaliações e Certificações — Fase 1D
-- Validador somente leitura da publicação controlada do diagnóstico piloto
-- ============================================================================

with constants as (
  select
    '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid as organization_id,
    '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid as test_id,
    'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid as version_id,
    '49239d09-0f85-471f-8f46-5c240cd98600'::uuid as pilot_member_id,
    'e88242b6-e44e-4de7-97cf-dbefc0605eaf'::uuid as pilot_user_id
),
checks as (
  select '01_tabela_privada_de_acesso_existe' as check_name,
    case when to_regclass('private.assessment_test_access_grants') is not null
      then 'PASS' else 'FAIL' end as status

  union all
  select '02_helper_privado_de_acesso_existe',
    case when to_regprocedure(
      'private.assessment_test_access_allowed(uuid,uuid,uuid,uuid)'
    ) is not null then 'PASS' else 'FAIL' end

  union all
  select '03_organizacao_piloto_ativa',
    case when exists (
      select 1 from public.organizations o, constants c
      where o.id = c.organization_id and o.status = 'active'
    ) then 'PASS' else 'FAIL' end

  union all
  select '04_membro_piloto_ativo_e_correspondente',
    case when exists (
      select 1
      from public.organization_members om
      join public.profiles p on p.id = om.user_id
      cross join constants c
      where om.id = c.pilot_member_id
        and om.organization_id = c.organization_id
        and om.user_id = c.pilot_user_id
        and om.role = 'salesperson'
        and om.status = 'active'
        and om.archived_at is null
        and p.status = 'active'
        and p.archived_at is null
    ) then 'PASS' else 'FAIL' end

  union all
  select '05_teste_1_ativo',
    case when exists (
      select 1 from public.assessment_tests t, constants c
      where t.id = c.test_id
        and t.organization_id = c.organization_id
        and t.code = 'teste_1_diagnostico'
        and t.sequence_no = 1
        and t.purpose = 'diagnostic'
        and t.status = 'active'
        and t.archived_at is null
    ) then 'PASS' else 'FAIL' end

  union all
  select '06_versao_1_publicada',
    case when exists (
      select 1 from public.assessment_test_versions tv, constants c
      where tv.id = c.version_id
        and tv.organization_id = c.organization_id
        and tv.test_id = c.test_id
        and tv.version_code = '2026.08-v1'
        and tv.status = 'published'
        and tv.archived_at is null
    ) then 'PASS' else 'FAIL' end

  union all
  select '07_publicacao_tem_datas_validas',
    case when exists (
      select 1 from public.assessment_test_versions tv, constants c
      where tv.id = c.version_id
        and tv.valid_from is not null
        and tv.valid_from <= now()
        and tv.published_at is not null
        and (tv.valid_until is null or tv.valid_until >= now())
    ) then 'PASS' else 'FAIL' end

  union all
  select '08_configuracao_de_notas_preservada',
    case when exists (
      select 1 from public.assessment_test_versions tv, constants c
      where tv.id = c.version_id
        and tv.question_count = 30
        and tv.passing_score = 60.00
        and tv.legal_min_score = 70.00
    ) then 'PASS' else 'FAIL' end

  union all
  select '09_configuracao_de_tentativas_preservada',
    case when exists (
      select 1 from public.assessment_tests t, constants c
      where t.id = c.test_id
        and t.max_attempts = 2
        and t.cooldown_hours = 24
        and t.time_limit_minutes is null
    ) then 'PASS' else 'FAIL' end

  union all
  select '10_configuracao_de_embaralhamento_preservada',
    case when exists (
      select 1 from public.assessment_test_versions tv, constants c
      where tv.id = c.version_id
        and tv.randomize_questions = false
        and tv.randomize_options = true
    ) then 'PASS' else 'FAIL' end

  union all
  select '11_revisao_diagnostica_imediata_preservada',
    case when exists (
      select 1 from public.assessment_test_versions tv, constants c
      where tv.id = c.version_id
        and tv.show_review_after_submit = true
    ) then 'PASS' else 'FAIL' end

  union all
  select '12_questoes_vinculadas_30',
    case when (
      select count(*)
      from public.assessment_version_questions avq, constants c
      where avq.organization_id = c.organization_id
        and avq.test_version_id = c.version_id
        and avq.archived_at is null
    ) = 30 then 'PASS' else 'FAIL' end

  union all
  select '13_gabaritos_privados_30',
    case when (
      select count(*)
      from public.assessment_version_questions avq
      join private.assessment_question_keys aqk
        on aqk.organization_id = avq.organization_id
       and aqk.question_id = avq.question_id
      cross join constants c
      where avq.organization_id = c.organization_id
        and avq.test_version_id = c.version_id
        and avq.archived_at is null
    ) = 30 then 'PASS' else 'FAIL' end

  union all
  select '14_criticos_eliminatorios_continuam_desativados',
    case when (
      select count(*)
      from public.assessment_version_questions avq
      join private.assessment_question_keys aqk
        on aqk.organization_id = avq.organization_id
       and aqk.question_id = avq.question_id
      cross join constants c
      where avq.organization_id = c.organization_id
        and avq.test_version_id = c.version_id
        and avq.archived_at is null
        and aqk.is_critical
    ) = 0 then 'PASS' else 'FAIL' end

  union all
  select '15_grant_individual_piloto_unico',
    case when (
      select count(*)
      from private.assessment_test_access_grants g, constants c
      where g.organization_id = c.organization_id
        and g.test_id = c.test_id
        and g.test_version_id = c.version_id
        and g.access_scope = 'member'
        and g.organization_member_id = c.pilot_member_id
        and g.status = 'active'
        and g.archived_at is null
        and (g.valid_from is null or g.valid_from <= now())
        and (g.valid_until is null or g.valid_until > now())
    ) = 1 then 'PASS' else 'FAIL' end

  union all
  select '16_sem_grant_organizacional',
    case when (
      select count(*)
      from private.assessment_test_access_grants g, constants c
      where g.organization_id = c.organization_id
        and g.test_id = c.test_id
        and g.test_version_id = c.version_id
        and g.access_scope = 'organization'
        and g.status = 'active'
        and g.archived_at is null
    ) = 0 then 'PASS' else 'FAIL' end

  union all
  select '17_helper_libera_piloto',
    case when private.assessment_test_access_allowed(
      (select organization_id from constants),
      (select pilot_member_id from constants),
      (select test_id from constants),
      (select version_id from constants)
    ) then 'PASS' else 'FAIL' end

  union all
  select '18_helper_bloqueia_outros_membros',
    case when not exists (
      select 1
      from public.organization_members om
      cross join constants c
      where om.organization_id = c.organization_id
        and om.id <> c.pilot_member_id
        and om.status = 'active'
        and om.archived_at is null
        and private.assessment_test_access_allowed(
          c.organization_id,
          om.id,
          c.test_id,
          c.version_id
        )
    ) then 'PASS' else 'FAIL' end

  union all
  select '19_outros_testes_continuam_rascunho',
    case when not exists (
      select 1 from public.assessment_tests t, constants c
      where t.organization_id = c.organization_id
        and t.id <> c.test_id
        and t.status <> 'draft'
        and t.archived_at is null
    ) then 'PASS' else 'FAIL' end

  union all
  select '20_outras_versoes_continuam_rascunho',
    case when not exists (
      select 1 from public.assessment_test_versions tv, constants c
      where tv.organization_id = c.organization_id
        and tv.id <> c.version_id
        and tv.status <> 'draft'
        and tv.archived_at is null
    ) then 'PASS' else 'FAIL' end

  union all
  select '21_apenas_um_teste_ativo',
    case when (
      select count(*) from public.assessment_tests t, constants c
      where t.organization_id = c.organization_id
        and t.status = 'active'
        and t.archived_at is null
    ) = 1 then 'PASS' else 'FAIL' end

  union all
  select '22_apenas_uma_versao_publicada',
    case when (
      select count(*) from public.assessment_test_versions tv, constants c
      where tv.organization_id = c.organization_id
        and tv.status = 'published'
        and tv.archived_at is null
    ) = 1 then 'PASS' else 'FAIL' end

  union all
  select '23_rpc_listagem_exige_grant',
    case when pg_get_functiondef(
      'public.get_available_assessments(uuid)'::regprocedure
    ) ilike '%assessment_test_access_allowed%'
      then 'PASS' else 'FAIL' end

  union all
  select '24_rpc_inicio_exige_grant',
    case when pg_get_functiondef(
      'public.start_assessment_attempt(uuid,uuid)'::regprocedure
    ) ilike '%assessment_test_access_allowed%'
      and pg_get_functiondef(
        'public.start_assessment_attempt(uuid,uuid)'::regprocedure
      ) ilike '%ASSESSMENT_ACCESS_NOT_GRANTED%'
      then 'PASS' else 'FAIL' end

  union all
  select '25_tabela_privada_inacessivel_ao_cliente',
    case when not has_table_privilege(
      'authenticated',
      'private.assessment_test_access_grants',
      'SELECT'
    ) and not has_table_privilege(
      'anon',
      'private.assessment_test_access_grants',
      'SELECT'
    ) then 'PASS' else 'FAIL' end

  union all
  select '26_helper_inacessivel_ao_cliente',
    case when not has_function_privilege(
      'authenticated',
      'private.assessment_test_access_allowed(uuid,uuid,uuid,uuid)',
      'EXECUTE'
    ) and not has_function_privilege(
      'anon',
      'private.assessment_test_access_allowed(uuid,uuid,uuid,uuid)',
      'EXECUTE'
    ) then 'PASS' else 'FAIL' end

  union all
  select '27_rpc_listagem_autenticado_sem_anon',
    case when has_function_privilege(
      'authenticated',
      'public.get_available_assessments(uuid)',
      'EXECUTE'
    ) and not has_function_privilege(
      'anon',
      'public.get_available_assessments(uuid)',
      'EXECUTE'
    ) then 'PASS' else 'FAIL' end

  union all
  select '28_rpc_inicio_autenticado_sem_anon',
    case when has_function_privilege(
      'authenticated',
      'public.start_assessment_attempt(uuid,uuid)',
      'EXECUTE'
    ) and not has_function_privilege(
      'anon',
      'public.start_assessment_attempt(uuid,uuid)',
      'EXECUTE'
    ) then 'PASS' else 'FAIL' end

  union all
  select '29_metadados_de_publicacao_registrados',
    case when exists (
      select 1
      from public.assessment_tests t
      join public.assessment_test_versions tv
        on tv.test_id = t.id
       and tv.organization_id = t.organization_id
      cross join constants c
      where t.id = c.test_id
        and tv.id = c.version_id
        and t.metadata ->> 'publication_mode' = 'individual_pilot'
        and tv.metadata ->> 'publication_mode' = 'individual_pilot'
        and tv.metadata ->> 'publication_status' = 'pilot_published'
    ) then 'PASS' else 'FAIL' end

  union all
  select '30_sem_tentativas_antes_do_teste_manual',
    case when (
      select count(*)
      from public.assessment_attempts aa, constants c
      where aa.organization_id = c.organization_id
        and aa.test_id = c.test_id
        and aa.archived_at is null
    ) = 0 then 'PASS' else 'FAIL' end
)
select check_name, status
from checks
order by check_name;
