-- Validador somente leitura — Avaliações e Certificações Fase 1C
-- Deve retornar 24 linhas com status PASS.

with rpc_oids as (
  select unnest(array[
    to_regprocedure('public.get_available_assessments(uuid)'),
    to_regprocedure('public.get_assessment_attempt(uuid)'),
    to_regprocedure('public.start_assessment_attempt(uuid,uuid)'),
    to_regprocedure('public.save_assessment_answer(uuid,uuid,text)'),
    to_regprocedure('public.get_assessment_attempt_result(uuid)'),
    to_regprocedure('public.submit_assessment_attempt(uuid)')
  ])::oid as oid
), helper_oids as (
  select unnest(array[
    to_regprocedure('private.assessment_prerequisites_met(uuid,uuid,uuid)'),
    to_regprocedure('private.assessment_review_available(uuid)')
  ])::oid as oid
), assessment_tables as (
  select unnest(array[
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
  ])::text as table_name
), checks as (
  select '01_rpc_publicas_6'::text as check_name,
    (select count(*) = 6 and count(*) filter (where oid <> 0) = 6 from rpc_oids) as ok

  union all
  select '02_helpers_privados_2',
    (select count(*) = 2 and count(*) filter (where oid <> 0) = 2 from helper_oids)

  union all
  select '03_rpc_security_definer',
    (select count(*) = 6 from pg_proc p join rpc_oids r on r.oid = p.oid where p.prosecdef)

  union all
  select '04_helpers_security_definer',
    (select count(*) = 2 from pg_proc p join helper_oids h on h.oid = p.oid where p.prosecdef)

  union all
  select '05_rpc_search_path_fixo',
    (select count(*) = 6
     from pg_proc p
     join rpc_oids r on r.oid = p.oid
     where coalesce(array_to_string(p.proconfig, ','), '') like '%search_path=pg_catalog, public, private%')

  union all
  select '06_helpers_search_path_fixo',
    (select count(*) = 2
     from pg_proc p
     join helper_oids h on h.oid = p.oid
     where coalesce(array_to_string(p.proconfig, ','), '') like '%search_path=pg_catalog, public, private%')

  union all
  select '07_authenticated_executa_6_rpc',
    (
      has_function_privilege('authenticated', 'public.get_available_assessments(uuid)', 'EXECUTE')
      and has_function_privilege('authenticated', 'public.get_assessment_attempt(uuid)', 'EXECUTE')
      and has_function_privilege('authenticated', 'public.start_assessment_attempt(uuid,uuid)', 'EXECUTE')
      and has_function_privilege('authenticated', 'public.save_assessment_answer(uuid,uuid,text)', 'EXECUTE')
      and has_function_privilege('authenticated', 'public.get_assessment_attempt_result(uuid)', 'EXECUTE')
      and has_function_privilege('authenticated', 'public.submit_assessment_attempt(uuid)', 'EXECUTE')
    )

  union all
  select '08_anon_sem_execute_rpc',
    (
      not has_function_privilege('anon', 'public.get_available_assessments(uuid)', 'EXECUTE')
      and not has_function_privilege('anon', 'public.get_assessment_attempt(uuid)', 'EXECUTE')
      and not has_function_privilege('anon', 'public.start_assessment_attempt(uuid,uuid)', 'EXECUTE')
      and not has_function_privilege('anon', 'public.save_assessment_answer(uuid,uuid,text)', 'EXECUTE')
      and not has_function_privilege('anon', 'public.get_assessment_attempt_result(uuid)', 'EXECUTE')
      and not has_function_privilege('anon', 'public.submit_assessment_attempt(uuid)', 'EXECUTE')
    )

  union all
  select '09_public_sem_execute_rpc',
    (select count(*) = 0
     from pg_proc p
     join rpc_oids r on r.oid = p.oid
     cross join lateral aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) acl
     where acl.grantee = 0
       and acl.privilege_type = 'EXECUTE')

  union all
  select '10_helpers_inacessiveis_ao_cliente',
    (
      not has_function_privilege('authenticated', 'private.assessment_prerequisites_met(uuid,uuid,uuid)', 'EXECUTE')
      and not has_function_privilege('authenticated', 'private.assessment_review_available(uuid)', 'EXECUTE')
      and not has_function_privilege('anon', 'private.assessment_prerequisites_met(uuid,uuid,uuid)', 'EXECUTE')
      and not has_function_privilege('anon', 'private.assessment_review_available(uuid)', 'EXECUTE')
    )

  union all
  select '11_tabelas_sem_privilegio_direto_authenticated',
    (select count(*) = 0
     from assessment_tables t
     where has_table_privilege('authenticated', format('public.%I', t.table_name), 'SELECT,INSERT,UPDATE,DELETE'))

  union all
  select '12_tabelas_sem_privilegio_direto_anon',
    (select count(*) = 0
     from assessment_tables t
     where has_table_privilege('anon', format('public.%I', t.table_name), 'SELECT,INSERT,UPDATE,DELETE'))

  union all
  select '13_progressao_metadados_5',
    (select count(*) = 5
     from public.assessment_tests t
     where t.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
       and t.metadata ->> 'flow_phase' = '1C'
       and t.archived_at is null)

  union all
  select '14_diagnostico_sem_pre_requisito',
    (select count(*) = 1
     from public.assessment_tests t
     where t.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
       and t.code = 'teste_1_diagnostico'
       and t.metadata ->> 'prerequisite_test_code' is null
       and t.metadata ->> 'review_policy' = 'immediate_after_grading'
       and t.archived_at is null)

  union all
  select '15_certificacoes_progressao_encadeada_4',
    (select count(*) = 4
     from public.assessment_tests t
     where t.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
       and t.code <> 'teste_1_diagnostico'
       and nullif(t.metadata ->> 'prerequisite_test_code', '') is not null
       and t.metadata ->> 'review_policy' = 'after_pass_or_final_attempt'
       and t.archived_at is null)

  union all
  select '16_testes_continuam_rascunho',
    (select count(*) = 5
     from public.assessment_tests
     where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
       and status = 'draft'
       and archived_at is null)

  union all
  select '17_versoes_continuam_rascunho',
    (select count(*) = 5
     from public.assessment_test_versions
     where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
       and status = 'draft'
       and archived_at is null)

  union all
  select '18_criticos_eliminatorios_desativados',
    (select count(*) = 0
     from private.assessment_question_keys
     where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
       and is_critical)

  union all
  select '19_marcacoes_criticas_pendentes_96',
    (select count(*) = 96
     from private.assessment_question_keys
     where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
       and metadata ->> 'source_critical_flag' = 'true'
       and metadata ->> 'critical_review_status' = 'pending_manual_homologation')

  union all
  select '20_sem_tentativas',
    (select count(*) = 0
     from public.assessment_attempts
     where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid)

  union all
  select '21_sem_respostas_notas_certificacoes',
    (
      (select count(*) = 0 from public.assessment_attempt_answers where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid)
      and (select count(*) = 0 from private.assessment_attempt_grades where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid)
      and (select count(*) = 0 from public.assessment_competency_scores where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid)
      and (select count(*) = 0 from public.member_certifications where organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid)
    )

  union all
  select '22_rpc_tentativa_nao_consulta_gabarito',
    (select pg_get_functiondef(to_regprocedure('public.get_assessment_attempt(uuid)'))
      not ilike '%assessment_question_keys%')

  union all
  select '23_rpc_inicio_exige_publicacao',
    (
      select
        pg_get_functiondef(to_regprocedure('public.start_assessment_attempt(uuid,uuid)')) ilike '%tv.status = ''published''%'
        and pg_get_functiondef(to_regprocedure('public.start_assessment_attempt(uuid,uuid)')) ilike '%t.status = ''active''%'
    )

  union all
  select '24_revisao_detalhada_tem_portao_seguro',
    (
      select
        pg_get_functiondef(to_regprocedure('public.get_assessment_attempt_result(uuid)')) ilike '%assessment_review_available%'
        and pg_get_functiondef(to_regprocedure('private.assessment_review_available(uuid)')) ilike '%t.purpose = ''diagnostic''%'
        and pg_get_functiondef(to_regprocedure('private.assessment_review_available(uuid)')) ilike '%a.attempt_no >= t.max_attempts%'
    )
)
select
  check_name,
  case when ok then 'PASS' else 'FAIL' end as status
from checks
order by check_name;
