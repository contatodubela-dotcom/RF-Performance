-- ============================================================================
-- RF Performance — Avaliações e Certificações — Fase 1D
-- Validador somente leitura do acesso piloto individual
--
-- Resultado esperado: todas as linhas com status = PASS.
-- ============================================================================

with function_inventory as (
  select
    p.oid,
    n.nspname as schema_name,
    p.proname,
    pg_get_function_identity_arguments(p.oid) as identity_arguments,
    p.prosecdef,
    coalesce(array_to_string(p.proconfig, ','), '') as settings,
    pg_get_functiondef(p.oid) as definition
  from pg_proc p
  join pg_namespace n
    on n.oid = p.pronamespace
  where (
      n.nspname = 'private'
      and p.proname = 'assessment_test_access_allowed'
    )
    or (
      n.nspname = 'public'
      and p.proname in (
        'get_available_assessments',
        'start_assessment_attempt'
      )
    )
),
checks as (
  select
    '01_tabela_privada_de_grants_existe'::text as check_name,
    to_regclass('private.assessment_test_access_grants') is not null as passed

  union all

  select
    '02_tabela_privada_sem_select_authenticated',
    not has_table_privilege(
      'authenticated',
      'private.assessment_test_access_grants',
      'SELECT'
    )

  union all

  select
    '03_tabela_privada_sem_escrita_authenticated',
    not has_table_privilege(
      'authenticated',
      'private.assessment_test_access_grants',
      'INSERT'
    )
    and not has_table_privilege(
      'authenticated',
      'private.assessment_test_access_grants',
      'UPDATE'
    )
    and not has_table_privilege(
      'authenticated',
      'private.assessment_test_access_grants',
      'DELETE'
    )

  union all

  select
    '04_tabela_privada_sem_privilegios_anon',
    not has_table_privilege(
      'anon',
      'private.assessment_test_access_grants',
      'SELECT'
    )
    and not has_table_privilege(
      'anon',
      'private.assessment_test_access_grants',
      'INSERT'
    )
    and not has_table_privilege(
      'anon',
      'private.assessment_test_access_grants',
      'UPDATE'
    )
    and not has_table_privilege(
      'anon',
      'private.assessment_test_access_grants',
      'DELETE'
    )

  union all

  select
    '05_helper_privado_existe',
    (
      select count(*) = 1
      from function_inventory
      where schema_name = 'private'
        and proname = 'assessment_test_access_allowed'
        and identity_arguments =
          'p_organization_id uuid, p_organization_member_id uuid, p_test_id uuid, p_test_version_id uuid'
    )

  union all

  select
    '06_helper_security_definer',
    (
      select bool_and(prosecdef)
      from function_inventory
      where schema_name = 'private'
        and proname = 'assessment_test_access_allowed'
    )

  union all

  select
    '07_helper_search_path_fixo',
    (
      select bool_and(
        settings like '%search_path=pg_catalog, public, private%'
      )
      from function_inventory
      where schema_name = 'private'
        and proname = 'assessment_test_access_allowed'
    )

  union all

  select
    '08_helper_inacessivel_authenticated',
    not has_function_privilege(
      'authenticated',
      'private.assessment_test_access_allowed(uuid,uuid,uuid,uuid)',
      'EXECUTE'
    )

  union all

  select
    '09_helper_inacessivel_anon',
    not has_function_privilege(
      'anon',
      'private.assessment_test_access_allowed(uuid,uuid,uuid,uuid)',
      'EXECUTE'
    )

  union all

  select
    '10_rpc_listagem_usa_portao_de_acesso',
    (
      select count(*) = 1
      from function_inventory
      where schema_name = 'public'
        and proname = 'get_available_assessments'
        and definition like '%private.assessment_test_access_allowed(%'
    )

  union all

  select
    '11_rpc_inicio_usa_portao_de_acesso',
    (
      select count(*) = 1
      from function_inventory
      where schema_name = 'public'
        and proname = 'start_assessment_attempt'
        and definition like '%private.assessment_test_access_allowed(%'
        and definition like '%ASSESSMENT_ACCESS_NOT_GRANTED%'
    )

  union all

  select
    '12_rpcs_continuam_security_definer',
    (
      select count(*) = 2 and bool_and(prosecdef)
      from function_inventory
      where schema_name = 'public'
        and proname in (
          'get_available_assessments',
          'start_assessment_attempt'
        )
    )

  union all

  select
    '13_rpcs_continuam_com_search_path_fixo',
    (
      select count(*) = 2
        and bool_and(
          settings like '%search_path=pg_catalog, public, private%'
        )
      from function_inventory
      where schema_name = 'public'
        and proname in (
          'get_available_assessments',
          'start_assessment_attempt'
        )
    )

  union all

  select
    '14_authenticated_executa_as_2_rpcs',
    has_function_privilege(
      'authenticated',
      'public.get_available_assessments(uuid)',
      'EXECUTE'
    )
    and has_function_privilege(
      'authenticated',
      'public.start_assessment_attempt(uuid,uuid)',
      'EXECUTE'
    )

  union all

  select
    '15_anon_sem_execute_nas_2_rpcs',
    not has_function_privilege(
      'anon',
      'public.get_available_assessments(uuid)',
      'EXECUTE'
    )
    and not has_function_privilege(
      'anon',
      'public.start_assessment_attempt(uuid,uuid)',
      'EXECUTE'
    )

  union all

  select
    '16_grant_piloto_exato_unico',
    (
      select count(*) = 1
      from private.assessment_test_access_grants access_grant
      where access_grant.id = '986fbc2a-bc95-4930-a827-25d92cdf3cf4'::uuid
        and access_grant.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
        and access_grant.test_id = '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
        and access_grant.test_version_id = 'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
        and access_grant.access_scope = 'member'
        and access_grant.organization_member_id = '49239d09-0f85-471f-8f46-5c240cd98600'::uuid
        and access_grant.status = 'active'
        and access_grant.archived_at is null
    )

  union all

  select
    '17_sem_grant_organizacional_ativo',
    not exists (
      select 1
      from private.assessment_test_access_grants access_grant
      where access_grant.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
        and access_grant.test_version_id = 'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
        and access_grant.access_scope = 'organization'
        and access_grant.status = 'active'
        and access_grant.archived_at is null
    )

  union all

  select
    '18_piloto_continua_ativo_e_salesperson',
    exists (
      select 1
      from public.organization_members om
      join public.profiles p
        on p.id = om.user_id
      where om.id = '49239d09-0f85-471f-8f46-5c240cd98600'::uuid
        and om.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
        and om.user_id = 'e88242b6-e44e-4de7-97cf-dbefc0605eaf'::uuid
        and om.role = 'salesperson'
        and om.status = 'active'
        and om.archived_at is null
        and p.status = 'active'
        and p.archived_at is null
    )

  union all

  select
    '19_helper_libera_piloto',
    private.assessment_test_access_allowed(
      '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
      '49239d09-0f85-471f-8f46-5c240cd98600'::uuid,
      '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid,
      'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
    )

  union all

  select
    '20_helper_bloqueia_outros_membros',
    not exists (
      select 1
      from public.organization_members om
      join public.profiles p
        on p.id = om.user_id
       and p.status = 'active'
       and p.archived_at is null
      where om.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
        and om.id <> '49239d09-0f85-471f-8f46-5c240cd98600'::uuid
        and om.status = 'active'
        and om.archived_at is null
        and private.assessment_test_access_allowed(
          '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid,
          om.id,
          '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid,
          'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
        )
    )

  union all

  select
    '21_teste_1_continua_draft',
    exists (
      select 1
      from public.assessment_tests t
      where t.id = '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
        and t.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
        and t.sequence_no = 1
        and t.purpose = 'diagnostic'
        and t.status = 'draft'
        and t.archived_at is null
    )

  union all

  select
    '22_versao_continua_draft',
    exists (
      select 1
      from public.assessment_test_versions tv
      where tv.id = 'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
        and tv.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
        and tv.test_id = '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
        and tv.status = 'draft'
        and tv.published_at is null
        and tv.archived_at is null
    )

  union all

  select
    '23_catalogo_piloto_30_questoes',
    (
      select count(*) = 30
      from public.assessment_version_questions avq
      where avq.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
        and avq.test_version_id = 'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
        and avq.archived_at is null
    )

  union all

  select
    '24_gabarito_privado_piloto_30',
    (
      select count(*) = 30
      from public.assessment_version_questions avq
      join private.assessment_question_keys aqk
        on aqk.organization_id = avq.organization_id
       and aqk.question_id = avq.question_id
      where avq.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
        and avq.test_version_id = 'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid
        and avq.archived_at is null
    )

  union all

  select
    '25_sem_tentativas_apos_migration',
    not exists (
      select 1
      from public.assessment_attempts aa
      where aa.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
        and aa.test_id = '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
        and aa.archived_at is null
    )

  union all

  select
    '26_demais_testes_continuam_sem_grants',
    not exists (
      select 1
      from private.assessment_test_access_grants access_grant
      where access_grant.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
        and access_grant.test_id <> '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid
        and access_grant.status = 'active'
        and access_grant.archived_at is null
    )

  union all

  select
    '27_nenhuma_versao_publicada',
    not exists (
      select 1
      from public.assessment_test_versions tv
      where tv.organization_id = '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
        and tv.status = 'published'
        and tv.archived_at is null
    )
)
select
  check_name,
  case when passed then 'PASS' else 'FAIL' end as status
from checks
order by check_name;
