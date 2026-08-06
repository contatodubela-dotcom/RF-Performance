-- ============================================================================
-- RF Performance — Avaliações e Certificações — Fase 1D
-- Validador somente leitura da exposição segura do último resultado
--
-- Resultado esperado: todas as linhas com status = PASS.
-- Não altera nenhum registro.
-- ============================================================================

with constants as (
  select
    '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid as organization_id,
    '49239d09-0f85-471f-8f46-5c240cd98600'::uuid as pilot_member_id,
    '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid as diagnostic_test_id,
    'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid as diagnostic_version_id,
    '72e1c6e0-2d62-47e3-85ec-6de2f4eaddbe'::uuid as pilot_attempt_id
),
function_inventory as (
  select
    p.oid,
    p.prosecdef,
    p.provolatile,
    coalesce(array_to_string(p.proconfig, ','), '') as settings,
    pg_get_functiondef(p.oid) as definition
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'get_available_assessments'
    and pg_get_function_identity_arguments(p.oid) = 'p_organization_id uuid'
),
latest_pilot_graded as (
  select a.id
  from public.assessment_attempts a
  cross join constants c
  where a.organization_id = c.organization_id
    and a.organization_member_id = c.pilot_member_id
    and a.test_id = c.diagnostic_test_id
    and a.test_version_id = c.diagnostic_version_id
    and a.status = 'graded'
    and a.archived_at is null
  order by a.attempt_no desc, a.started_at desc, a.id desc
  limit 1
),
checks as (
  select '01_rpc_listagem_existe'::text as check_name,
    case when (select count(*) from function_inventory) = 1
      then 'PASS' else 'FAIL' end as status

  union all
  select '02_rpc_security_definer',
    case when (select bool_and(prosecdef) from function_inventory)
      then 'PASS' else 'FAIL' end

  union all
  select '03_rpc_estavel',
    case when (select bool_and(provolatile = 's') from function_inventory)
      then 'PASS' else 'FAIL' end

  union all
  select '04_rpc_search_path_fixo',
    case when (
      select bool_and(settings like '%search_path=pg_catalog, public, private%')
      from function_inventory
    ) then 'PASS' else 'FAIL' end

  union all
  select '05_authenticated_mantem_execute',
    case when has_function_privilege(
      'authenticated',
      'public.get_available_assessments(uuid)',
      'EXECUTE'
    ) then 'PASS' else 'FAIL' end

  union all
  select '06_anon_sem_execute',
    case when not has_function_privilege(
      'anon',
      'public.get_available_assessments(uuid)',
      'EXECUTE'
    ) then 'PASS' else 'FAIL' end

  union all
  select '07_public_sem_execute',
    case when not has_function_privilege(
      'public',
      'public.get_available_assessments(uuid)',
      'EXECUTE'
    ) then 'PASS' else 'FAIL' end

  union all
  select '08_portao_de_acesso_individual_preservado',
    case when (
      select definition ilike '%private.assessment_test_access_allowed(%'
      from function_inventory
    ) then 'PASS' else 'FAIL' end

  union all
  select '09_campo_ultimo_resultado_exposto',
    case when (
      select definition ilike '%''last_graded_attempt_id''%'
        and definition ilike '%attempt_summary.last_graded_attempt_id%'
      from function_inventory
    ) then 'PASS' else 'FAIL' end

  union all
  select '10_ultimo_resultado_restrito_a_status_graded',
    case when (
      select definition ilike '%filter (where a.status = ''graded'')%'
      from function_inventory
    ) then 'PASS' else 'FAIL' end

  union all
  select '11_ultimo_resultado_ordenado_por_tentativa',
    case when (
      select definition ilike '%order by a.attempt_no desc, a.started_at desc, a.id desc%'
      from function_inventory
    ) then 'PASS' else 'FAIL' end

  union all
  select '12_escopo_da_organizacao_preservado',
    case when (
      select definition ilike '%a.organization_id = p_organization_id%'
      from function_inventory
    ) then 'PASS' else 'FAIL' end

  union all
  select '13_escopo_do_membro_preservado',
    case when (
      select definition ilike '%a.organization_member_id = v_member_id%'
      from function_inventory
    ) then 'PASS' else 'FAIL' end

  union all
  select '14_escopo_da_versao_preservado',
    case when (
      select definition ilike '%a.test_version_id = tv.id%'
      from function_inventory
    ) then 'PASS' else 'FAIL' end

  union all
  select '15_tentativas_arquivadas_excluidas',
    case when (
      select definition ilike '%a.archived_at is null%'
      from function_inventory
    ) then 'PASS' else 'FAIL' end

  union all
  select '16_tentativa_em_andamento_preservada',
    case when (
      select definition ilike '%''in_progress_attempt_id''%'
        and definition ilike '%where a.status = ''in_progress''%'
      from function_inventory
    ) then 'PASS' else 'FAIL' end

  union all
  select '17_estado_e_aprovacao_preservados',
    case when (
      select definition ilike '%''last_attempt_status''%'
        and definition ilike '%''last_attempt_passed''%'
      from function_inventory
    ) then 'PASS' else 'FAIL' end

  union all
  select '18_cooldown_preservado',
    case when (
      select definition ilike '%''next_attempt_at''%'
        and definition ilike '%make_interval(hours => t.cooldown_hours)%'
      from function_inventory
    ) then 'PASS' else 'FAIL' end

  union all
  select '19_piloto_possui_resultado_corrigido',
    case when exists (select 1 from latest_pilot_graded)
      then 'PASS' else 'FAIL' end

  union all
  select '20_ultimo_resultado_do_piloto_e_a_tentativa_preservada',
    case when (
      select id = (select pilot_attempt_id from constants)
      from latest_pilot_graded
    ) then 'PASS' else 'FAIL' end

  union all
  select '21_tentativa_piloto_continua_29_de_30',
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
  select '22_respostas_da_tentativa_preservadas_30',
    case when (
      select count(*)
      from public.assessment_attempt_answers answer
      cross join constants c
      where answer.attempt_id = c.pilot_attempt_id
        and answer.organization_id = c.organization_id
        and answer.archived_at is null
    ) = 30 then 'PASS' else 'FAIL' end

  union all
  select '23_notas_privadas_preservadas_30',
    case when (
      select count(*)
      from private.assessment_attempt_grades grade
      cross join constants c
      where grade.attempt_id = c.pilot_attempt_id
        and grade.organization_id = c.organization_id
    ) = 30 then 'PASS' else 'FAIL' end

  union all
  select '24_sem_escrita_em_tabelas_de_avaliacao',
    case when (
      select definition not ilike '%insert into%'
        and definition not ilike '%update %'
        and definition not ilike '%delete from%'
      from function_inventory
    ) then 'PASS' else 'FAIL' end
)
select check_name, status
from checks
order by check_name;
