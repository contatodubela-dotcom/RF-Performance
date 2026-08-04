-- RF Performance Comercial
-- Validador somente leitura - Avaliações e Certificação Fase 1A
-- Esperado: todos os testes com status PASS.

with
expected_public_tables(table_name) as (
  values
    ('certification_levels'),
    ('competency_domains'),
    ('assessment_tests'),
    ('assessment_test_versions'),
    ('assessment_questions'),
    ('assessment_question_options'),
    ('assessment_version_questions'),
    ('assessment_attempts'),
    ('assessment_attempt_items'),
    ('assessment_attempt_answers'),
    ('assessment_competency_scores'),
    ('practical_assessments'),
    ('member_certifications')
),
expected_private_tables(table_name) as (
  values
    ('assessment_question_keys'),
    ('assessment_attempt_grades')
),
checks as (
  select
    1 as check_no,
    '13 tabelas públicas existem'::text as check_name,
    case when (
      select count(*)
      from expected_public_tables e
      where to_regclass(format('public.%I', e.table_name)) is not null
    ) = 13 then 'PASS' else 'FAIL' end as status,
    format('%s/13 encontradas', (
      select count(*)
      from expected_public_tables e
      where to_regclass(format('public.%I', e.table_name)) is not null
    )) as details

  union all
  select
    2,
    '2 tabelas privadas sensíveis existem',
    case when (
      select count(*)
      from expected_private_tables e
      where to_regclass(format('private.%I', e.table_name)) is not null
    ) = 2 then 'PASS' else 'FAIL' end,
    format('%s/2 encontradas', (
      select count(*)
      from expected_private_tables e
      where to_regclass(format('private.%I', e.table_name)) is not null
    ))

  union all
  select
    3,
    'RLS habilitada nas 13 tabelas públicas',
    case when (
      select count(*)
      from expected_public_tables e
      join pg_class c on c.oid = to_regclass(format('public.%I', e.table_name))
      where c.relrowsecurity
    ) = 13 then 'PASS' else 'FAIL' end,
    format('%s/13 com RLS', (
      select count(*)
      from expected_public_tables e
      join pg_class c on c.oid = to_regclass(format('public.%I', e.table_name))
      where c.relrowsecurity
    ))

  union all
  select
    4,
    'FORCE RLS habilitado nas 13 tabelas públicas',
    case when (
      select count(*)
      from expected_public_tables e
      join pg_class c on c.oid = to_regclass(format('public.%I', e.table_name))
      where c.relforcerowsecurity
    ) = 13 then 'PASS' else 'FAIL' end,
    format('%s/13 com FORCE RLS', (
      select count(*)
      from expected_public_tables e
      join pg_class c on c.oid = to_regclass(format('public.%I', e.table_name))
      where c.relforcerowsecurity
    ))

  union all
  select
    5,
    'anon sem privilégios diretos nas tabelas públicas',
    case when not exists (
      select 1
      from expected_public_tables e
      where has_table_privilege('anon', format('public.%I', e.table_name), 'SELECT')
         or has_table_privilege('anon', format('public.%I', e.table_name), 'INSERT')
         or has_table_privilege('anon', format('public.%I', e.table_name), 'UPDATE')
         or has_table_privilege('anon', format('public.%I', e.table_name), 'DELETE')
    ) then 'PASS' else 'FAIL' end,
    'SELECT/INSERT/UPDATE/DELETE devem estar revogados'

  union all
  select
    6,
    'authenticated sem privilégios diretos nas tabelas públicas',
    case when not exists (
      select 1
      from expected_public_tables e
      where has_table_privilege('authenticated', format('public.%I', e.table_name), 'SELECT')
         or has_table_privilege('authenticated', format('public.%I', e.table_name), 'INSERT')
         or has_table_privilege('authenticated', format('public.%I', e.table_name), 'UPDATE')
         or has_table_privilege('authenticated', format('public.%I', e.table_name), 'DELETE')
    ) then 'PASS' else 'FAIL' end,
    'Acesso será exclusivamente por RPCs na próxima fase'

  union all
  select
    7,
    'anon e authenticated sem acesso ao gabarito privado',
    case when
      not has_table_privilege('anon', 'private.assessment_question_keys', 'SELECT')
      and not has_table_privilege('authenticated', 'private.assessment_question_keys', 'SELECT')
    then 'PASS' else 'FAIL' end,
    'private.assessment_question_keys'

  union all
  select
    8,
    'anon e authenticated sem acesso à correção privada',
    case when
      not has_table_privilege('anon', 'private.assessment_attempt_grades', 'SELECT')
      and not has_table_privilege('authenticated', 'private.assessment_attempt_grades', 'SELECT')
    then 'PASS' else 'FAIL' end,
    'private.assessment_attempt_grades'

  union all
  select
    9,
    'Tabela pública de questões não contém gabarito',
    case when not exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'assessment_questions'
        and column_name in (
          'answer', 'correct_answer', 'correct_option_code',
          'justification', 'source_reference', 'is_critical', 'critical_reason'
        )
    ) then 'PASS' else 'FAIL' end,
    'Campos sensíveis devem existir somente no schema private'

  union all
  select
    10,
    'Alternativas públicas não indicam resposta correta',
    case when not exists (
      select 1
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'assessment_question_options'
        and column_name in ('is_correct', 'correct', 'score', 'points_awarded')
    ) then 'PASS' else 'FAIL' end,
    'assessment_question_options'

  union all
  select
    11,
    'Tentativas usam versão e teste da mesma organização',
    case when exists (
      select 1
      from pg_constraint
      where conrelid = 'public.assessment_attempts'::regclass
        and conname = 'assessment_attempts_version_org_test_fkey'
        and contype = 'f'
    ) then 'PASS' else 'FAIL' end,
    'FK composta test_version_id + organization_id + test_id'

  union all
  select
    12,
    'Vínculo do participante respeita a organização',
    case when exists (
      select 1
      from pg_constraint
      where conrelid = 'public.assessment_attempts'::regclass
        and conname = 'assessment_attempts_member_org_fkey'
        and contype = 'f'
    ) then 'PASS' else 'FAIL' end,
    'FK composta organization_member_id + organization_id'

  union all
  select
    13,
    'Snapshot da tentativa está presente',
    case when (
      select count(*)
      from information_schema.columns
      where table_schema = 'public'
        and table_name = 'assessment_attempt_items'
        and column_name in ('prompt_snapshot', 'options_snapshot', 'option_order')
    ) = 3 then 'PASS' else 'FAIL' end,
    'Preserva o conteúdo efetivamente aplicado'

  union all
  select
    14,
    'Há no máximo uma versão publicada por teste',
    case when to_regclass('public.assessment_test_versions_one_published_per_test_idx') is not null
      then 'PASS' else 'FAIL' end,
    'Índice único parcial'

  union all
  select
    15,
    'Há no máximo uma certificação ativa por nível e membro',
    case when to_regclass('public.member_certifications_one_active_level_idx') is not null
      then 'PASS' else 'FAIL' end,
    'Índice único parcial'

  union all
  select
    16,
    'Funções de escopo existem',
    case when
      to_regprocedure('private.can_view_assessment_member(uuid,uuid)') is not null
      and to_regprocedure('private.can_manage_assessment_member(uuid,uuid)') is not null
    then 'PASS' else 'FAIL' end,
    'can_view_assessment_member e can_manage_assessment_member'

  union all
  select
    17,
    'Funções de escopo são SECURITY DEFINER',
    case when (
      select count(*)
      from pg_proc p
      where p.oid in (
        to_regprocedure('private.can_view_assessment_member(uuid,uuid)'),
        to_regprocedure('private.can_manage_assessment_member(uuid,uuid)')
      )
        and p.prosecdef
    ) = 2 then 'PASS' else 'FAIL' end,
    '2/2 esperadas'

  union all
  select
    18,
    'Funções de escopo possuem search_path fixo',
    case when (
      select count(*)
      from pg_proc p
      where p.oid in (
        to_regprocedure('private.can_view_assessment_member(uuid,uuid)'),
        to_regprocedure('private.can_manage_assessment_member(uuid,uuid)')
      )
        and exists (
          select 1
          from unnest(coalesce(p.proconfig, array[]::text[])) cfg
          where cfg like 'search_path=%'
        )
    ) = 2 then 'PASS' else 'FAIL' end,
    'Proteção contra sequestro de search_path'

  union all
  select
    19,
    'Funções auxiliares não são executáveis por anon',
    case when
      not has_function_privilege('anon', 'private.can_view_assessment_member(uuid,uuid)', 'EXECUTE')
      and not has_function_privilege('anon', 'private.can_manage_assessment_member(uuid,uuid)', 'EXECUTE')
    then 'PASS' else 'FAIL' end,
    'Sem superfície pública desnecessária'

  union all
  select
    20,
    'Fundação foi criada sem dados de teste',
    case when
      (select count(*) from public.assessment_tests) = 0
      and (select count(*) from public.assessment_questions) = 0
      and (select count(*) from public.assessment_attempts) = 0
    then 'PASS' else 'FAIL' end,
    'Importação das 150 questões ocorrerá em migration separada'
)
select
  check_no,
  check_name,
  status,
  details
from checks
order by check_no;
