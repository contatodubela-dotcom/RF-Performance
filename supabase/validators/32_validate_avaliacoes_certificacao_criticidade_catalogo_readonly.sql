-- ============================================================================
-- VALIDATOR READ-ONLY
-- Avaliações e Certificação
-- Criticidade catálogo 2026.08-v1
--
-- NÃO ALTERA DADOS
-- ============================================================================

with expected(test_no, question_no) as (
  select 1, x
  from unnest(array[
    5,7,8,9,10,11,12,13,14,15,16,17,18
  ]::integer[]) as x

  union all

  select 2, x
  from unnest(array[
    1,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,27
  ]::integer[]) as x

  union all

  select 3, x
  from unnest(array[
    1,2,3,4,6,9,10,11,12,13,14,15,16,17,18,19,21,22,24,30
  ]::integer[]) as x

  union all

  select 4, x
  from unnest(array[
    2,3,5,6,9,10,11,12,13,14,15,16,17,18,19,20,21,22,24,25,29
  ]::integer[]) as x

  union all

  select 5, x
  from unnest(array[
    1,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,26,30
  ]::integer[]) as x
),
catalog as (
  select
    t.sequence_no as test_no,
    avq.sequence_no as question_no,
    q.id as question_id,
    q.legal_review_date,
    qk.is_critical
  from public.assessment_version_questions avq
  join public.assessment_test_versions tv
    on tv.id = avq.test_version_id
   and tv.organization_id = avq.organization_id
  join public.assessment_tests t
    on t.id = tv.test_id
   and t.organization_id = tv.organization_id
  join public.assessment_questions q
    on q.id = avq.question_id
   and q.organization_id = avq.organization_id
  join private.assessment_question_keys qk
    on qk.question_id = q.id
   and qk.organization_id = q.organization_id
  where avq.organization_id =
    '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid
    and tv.version_code = '2026.08-v1'
    and avq.archived_at is null
    and tv.archived_at is null
    and t.archived_at is null
    and q.archived_at is null
),
checks as (

  select
    1 as check_no,
    'catalog_total_150'::text as check_name,
    (select count(*) from catalog) = 150 as passed,
    (select count(*)::text from catalog) as actual,
    '150'::text as expected

  union all

  select
    2,
    'catalog_distinct_questions_150',
    (select count(distinct question_id) from catalog) = 150,
    (select count(distinct question_id)::text from catalog),
    '150'

  union all

  select
    3,
    'expected_critical_definition_96',
    (select count(*) from expected) = 96,
    (select count(*)::text from expected),
    '96'

  union all

  select
    4,
    'total_critical_96',
    (select count(*) from catalog where is_critical) = 96,
    (select count(*)::text from catalog where is_critical),
    '96'

  union all

  select
    5,
    'all_expected_are_critical',
    (
      select count(*)
      from expected e
      join catalog c
        on c.test_no = e.test_no
       and c.question_no = e.question_no
      where c.is_critical
    ) = 96,
    (
      select count(*)::text
      from expected e
      join catalog c
        on c.test_no = e.test_no
       and c.question_no = e.question_no
      where c.is_critical
    ),
    '96'

  union all

  select
    6,
    'no_unexpected_critical',
    (
      select count(*)
      from catalog c
      where c.is_critical
        and not exists (
          select 1
          from expected e
          where e.test_no = c.test_no
            and e.question_no = c.question_no
        )
    ) = 0,
    (
      select count(*)::text
      from catalog c
      where c.is_critical
        and not exists (
          select 1
          from expected e
          where e.test_no = c.test_no
            and e.question_no = c.question_no
        )
    ),
    '0'

  union all

  select
    7,
    'noncritical_total_54',
    (select count(*) from catalog where not is_critical) = 54,
    (select count(*)::text from catalog where not is_critical),
    '54'

  union all

  select
    8,
    'legal_review_total_96',
    (select count(*) from catalog where legal_review_date is not null) = 96,
    (select count(*)::text from catalog where legal_review_date is not null),
    '96'

  union all

  select
    9,
    'test1_critical_13',
    (select count(*) from catalog where test_no = 1 and is_critical) = 13,
    (select count(*)::text from catalog where test_no = 1 and is_critical),
    '13'

  union all

  select
    10,
    'test2_critical_18',
    (select count(*) from catalog where test_no = 2 and is_critical) = 18,
    (select count(*)::text from catalog where test_no = 2 and is_critical),
    '18'

  union all

  select
    11,
    'test3_critical_20',
    (select count(*) from catalog where test_no = 3 and is_critical) = 20,
    (select count(*)::text from catalog where test_no = 3 and is_critical),
    '20'

  union all

  select
    12,
    'test4_critical_21',
    (select count(*) from catalog where test_no = 4 and is_critical) = 21,
    (select count(*)::text from catalog where test_no = 4 and is_critical),
    '21'

  union all

  select
    13,
    'test5_critical_24',
    (select count(*) from catalog where test_no = 5 and is_critical) = 24,
    (select count(*)::text from catalog where test_no = 5 and is_critical),
    '24'
)
select
  check_no,
  check_name,
  case when passed then 'PASS' else 'FAIL' end as result,
  actual,
  expected
from checks
order by check_no;