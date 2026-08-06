-- ============================================================================
-- RF Performance — Avaliações e Certificações — Fase 1D
-- Validador somente leitura da correção de codificação dos gabaritos privados
-- ============================================================================

with constants as (
  select
    '414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid as organization_id,
    '4bbd0f10-5444-5826-860b-aed020cb6acc'::uuid as diagnostic_test_id,
    'fbfcb01b-c6ea-5f26-b61e-a5e37d1d3ea4'::uuid as diagnostic_version_id,
    '49239d09-0f85-471f-8f46-5c240cd98600'::uuid as pilot_member_id,
    '72e1c6e0-2d62-47e3-85ec-6de2f4eaddbe'::uuid as pilot_attempt_id,
    '20260806104500_win1252_to_utf8'::text as repair_code
),
checks as (
  select '01_tabela_privada_de_auditoria_existe' as check_name,
    case when to_regclass(
      'private.assessment_question_key_text_repairs'
    ) is not null then 'PASS' else 'FAIL' end as status

  union all
  select '02_tabela_de_auditoria_com_rls_ativa',
    case when exists (
      select 1
      from pg_class c
      join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'private'
        and c.relname = 'assessment_question_key_text_repairs'
        and c.relrowsecurity
    ) then 'PASS' else 'FAIL' end

  union all
  select '03_tabela_de_auditoria_com_rls_forcada',
    case when exists (
      select 1
      from pg_class c
      join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'private'
        and c.relname = 'assessment_question_key_text_repairs'
        and c.relforcerowsecurity
    ) then 'PASS' else 'FAIL' end

  union all
  select '04_public_sem_privilegios_na_auditoria',
    case when
      not has_table_privilege(
        'public', 'private.assessment_question_key_text_repairs', 'SELECT'
      )
      and not has_table_privilege(
        'public', 'private.assessment_question_key_text_repairs', 'INSERT'
      )
      and not has_table_privilege(
        'public', 'private.assessment_question_key_text_repairs', 'UPDATE'
      )
      and not has_table_privilege(
        'public', 'private.assessment_question_key_text_repairs', 'DELETE'
      )
    then 'PASS' else 'FAIL' end

  union all
  select '05_anon_sem_privilegios_na_auditoria',
    case when
      not has_table_privilege(
        'anon', 'private.assessment_question_key_text_repairs', 'SELECT'
      )
      and not has_table_privilege(
        'anon', 'private.assessment_question_key_text_repairs', 'INSERT'
      )
      and not has_table_privilege(
        'anon', 'private.assessment_question_key_text_repairs', 'UPDATE'
      )
      and not has_table_privilege(
        'anon', 'private.assessment_question_key_text_repairs', 'DELETE'
      )
    then 'PASS' else 'FAIL' end

  union all
  select '06_authenticated_sem_privilegios_na_auditoria',
    case when
      not has_table_privilege(
        'authenticated', 'private.assessment_question_key_text_repairs', 'SELECT'
      )
      and not has_table_privilege(
        'authenticated', 'private.assessment_question_key_text_repairs', 'INSERT'
      )
      and not has_table_privilege(
        'authenticated', 'private.assessment_question_key_text_repairs', 'UPDATE'
      )
      and not has_table_privilege(
        'authenticated', 'private.assessment_question_key_text_repairs', 'DELETE'
      )
    then 'PASS' else 'FAIL' end

  union all
  select '07_gabaritos_privados_continuam_150',
    case when (
      select count(*)
      from private.assessment_question_keys qk, constants c
      where qk.organization_id = c.organization_id
    ) = 150 then 'PASS' else 'FAIL' end

  union all
  select '08_registros_de_auditoria_150',
    case when (
      select count(*)
      from private.assessment_question_key_text_repairs repair, constants c
      where repair.organization_id = c.organization_id
        and repair.repair_code = c.repair_code
    ) = 150 then 'PASS' else 'FAIL' end

  union all
  select '09_questoes_unicas_na_auditoria_150',
    case when (
      select count(distinct repair.question_id)
      from private.assessment_question_key_text_repairs repair, constants c
      where repair.organization_id = c.organization_id
        and repair.repair_code = c.repair_code
    ) = 150 then 'PASS' else 'FAIL' end

  union all
  select '10_justificativas_antes_suspeitas_149',
    case when (
      select count(*)
      from private.assessment_question_key_text_repairs repair, constants c
      where repair.organization_id = c.organization_id
        and repair.repair_code = c.repair_code
        and coalesce(repair.justification_before, '') ~
          '(Ã.|Â.|â€”|â€“|â€œ|â€|â€™|â€¦|�)'
    ) = 149 then 'PASS' else 'FAIL' end

  union all
  select '11_referencias_antes_suspeitas_150',
    case when (
      select count(*)
      from private.assessment_question_key_text_repairs repair, constants c
      where repair.organization_id = c.organization_id
        and repair.repair_code = c.repair_code
        and coalesce(repair.source_reference_before, '') ~
          '(Ã.|Â.|â€”|â€“|â€œ|â€|â€™|â€¦|�)'
    ) = 150 then 'PASS' else 'FAIL' end

  union all
  select '12_justificativas_corrigidas_sem_mojibake',
    case when not exists (
      select 1
      from private.assessment_question_keys qk, constants c
      where qk.organization_id = c.organization_id
        and coalesce(qk.justification, '') ~
          '(Ã.|Â.|â€”|â€“|â€œ|â€|â€™|â€¦|�)'
    ) then 'PASS' else 'FAIL' end

  union all
  select '13_referencias_corrigidas_sem_mojibake',
    case when not exists (
      select 1
      from private.assessment_question_keys qk, constants c
      where qk.organization_id = c.organization_id
        and coalesce(qk.source_reference, '') ~
          '(Ã.|Â.|â€”|â€“|â€œ|â€|â€™|â€¦|�)'
    ) then 'PASS' else 'FAIL' end

  union all
  select '14_motivos_criticos_sem_mojibake',
    case when not exists (
      select 1
      from private.assessment_question_keys qk, constants c
      where qk.organization_id = c.organization_id
        and coalesce(qk.critical_reason, '') ~
          '(Ã.|Â.|â€”|â€“|â€œ|â€|â€™|â€¦|�)'
    ) then 'PASS' else 'FAIL' end

  union all
  select '15_auditoria_depois_sem_mojibake',
    case when not exists (
      select 1
      from private.assessment_question_key_text_repairs repair, constants c
      where repair.organization_id = c.organization_id
        and repair.repair_code = c.repair_code
        and (
          coalesce(repair.justification_after, '') ~
            '(Ã.|Â.|â€”|â€“|â€œ|â€|â€™|â€¦|�)'
          or coalesce(repair.source_reference_after, '') ~
            '(Ã.|Â.|â€”|â€“|â€œ|â€|â€™|â€¦|�)'
          or coalesce(repair.critical_reason_after, '') ~
            '(Ã.|Â.|â€”|â€“|â€œ|â€|â€™|â€¦|�)'
        )
    ) then 'PASS' else 'FAIL' end

  union all
  select '16_alternativas_corretas_preservadas',
    case when not exists (
      select 1
      from private.assessment_question_key_text_repairs repair
      join private.assessment_question_keys qk
        on qk.organization_id = repair.organization_id
       and qk.question_id = repair.question_id
      cross join constants c
      where repair.organization_id = c.organization_id
        and repair.repair_code = c.repair_code
        and qk.correct_option_code <> repair.correct_option_code_before
    ) then 'PASS' else 'FAIL' end

  union all
  select '17_distribuicao_do_gabarito_preservada',
    case when (
      select count(*) filter (where qk.correct_option_code = 'A') = 38
         and count(*) filter (where qk.correct_option_code = 'B') = 38
         and count(*) filter (where qk.correct_option_code = 'C') = 37
         and count(*) filter (where qk.correct_option_code = 'D') = 37
      from private.assessment_question_keys qk, constants c
      where qk.organization_id = c.organization_id
    ) is true then 'PASS' else 'FAIL' end

  union all
  select '18_criticos_eliminatorios_continuam_desativados',
    case when (
      select count(*)
      from private.assessment_question_keys qk, constants c
      where qk.organization_id = c.organization_id
        and qk.is_critical
    ) = 0 then 'PASS' else 'FAIL' end

  union all
  select '19_campos_nao_textuais_preservados',
    case when not exists (
      select 1
      from private.assessment_question_key_text_repairs repair
      join private.assessment_question_keys qk
        on qk.organization_id = repair.organization_id
       and qk.question_id = repair.question_id
      cross join constants c
      where repair.organization_id = c.organization_id
        and repair.repair_code = c.repair_code
        and (
          qk.correct_option_code <> repair.correct_option_code_before
          or qk.is_critical <> repair.is_critical_before
          or qk.critical_reason is distinct from repair.critical_reason_before
          or qk.reviewed_by is distinct from repair.reviewed_by_before
          or qk.reviewed_at is distinct from repair.reviewed_at_before
          or qk.created_at is distinct from repair.created_at_before
          or qk.created_by is distinct from repair.created_by_before
          or qk.updated_by is distinct from repair.updated_by_before
        )
    ) then 'PASS' else 'FAIL' end

  union all
  select '20_marcador_de_reparo_em_150_gabaritos',
    case when (
      select count(*)
      from private.assessment_question_keys qk, constants c
      where qk.organization_id = c.organization_id
        and qk.metadata ? 'encoding_repair_20260806104500'
    ) = 150 then 'PASS' else 'FAIL' end

  union all
  select '21_catalogo_publico_preservado',
    case when
      (select count(*) from public.assessment_tests t, constants c
       where t.organization_id = c.organization_id and t.archived_at is null) = 5
      and
      (select count(*) from public.assessment_test_versions tv, constants c
       where tv.organization_id = c.organization_id and tv.archived_at is null) = 5
      and
      (select count(*) from public.assessment_questions q, constants c
       where q.organization_id = c.organization_id and q.archived_at is null) = 150
      and
      (select count(*) from public.assessment_question_options o, constants c
       where o.organization_id = c.organization_id and o.archived_at is null) = 600
      and
      (select count(*) from public.assessment_version_questions vq, constants c
       where vq.organization_id = c.organization_id and vq.archived_at is null) = 150
    then 'PASS' else 'FAIL' end

  union all
  select '22_publicacao_piloto_preservada',
    case when
      (select count(*) from public.assessment_tests t, constants c
       where t.organization_id = c.organization_id
         and t.status = 'active'
         and t.archived_at is null) = 1
      and
      (select count(*) from public.assessment_test_versions tv, constants c
       where tv.organization_id = c.organization_id
         and tv.status = 'published'
         and tv.archived_at is null) = 1
      and exists (
        select 1
        from public.assessment_tests t, constants c
        where t.id = c.diagnostic_test_id
          and t.organization_id = c.organization_id
          and t.status = 'active'
      )
      and exists (
        select 1
        from public.assessment_test_versions tv, constants c
        where tv.id = c.diagnostic_version_id
          and tv.organization_id = c.organization_id
          and tv.status = 'published'
      )
    then 'PASS' else 'FAIL' end

  union all
  select '23_acesso_individual_piloto_preservado',
    case when (
      select count(*)
      from private.assessment_test_access_grants g, constants c
      where g.organization_id = c.organization_id
        and g.test_id = c.diagnostic_test_id
        and g.test_version_id = c.diagnostic_version_id
        and g.access_scope = 'member'
        and g.organization_member_id = c.pilot_member_id
        and g.status = 'active'
        and g.archived_at is null
    ) = 1 then 'PASS' else 'FAIL' end

  union all
  select '24_sem_acesso_organizacional_geral',
    case when not exists (
      select 1
      from private.assessment_test_access_grants g, constants c
      where g.organization_id = c.organization_id
        and g.test_id = c.diagnostic_test_id
        and g.test_version_id = c.diagnostic_version_id
        and g.access_scope = 'organization'
        and g.status = 'active'
        and g.archived_at is null
    ) then 'PASS' else 'FAIL' end

  union all
  select '25_tentativa_piloto_concluida_preservada',
    case when exists (
      select 1
      from public.assessment_attempts a, constants c
      where a.id = c.pilot_attempt_id
        and a.organization_id = c.organization_id
        and a.organization_member_id = c.pilot_member_id
        and a.test_id = c.diagnostic_test_id
        and a.test_version_id = c.diagnostic_version_id
        and a.attempt_no = 1
        and a.status = 'graded'
        and a.total_questions = 30
        and a.answered_questions = 30
        and a.correct_answers = 29
        and a.overall_score = 96.67
        and a.legal_score = 100.00
        and a.critical_errors = 0
        and a.submitted_at is not null
        and a.graded_at is not null
        and a.archived_at is null
    ) then 'PASS' else 'FAIL' end

  union all
  select '26_respostas_e_notas_da_tentativa_preservadas',
    case when
      (select count(*)
       from public.assessment_attempt_answers answer, constants c
       where answer.attempt_id = c.pilot_attempt_id
         and answer.organization_id = c.organization_id
         and answer.archived_at is null) = 30
      and
      (select count(*)
       from private.assessment_attempt_grades grade, constants c
       where grade.attempt_id = c.pilot_attempt_id
         and grade.organization_id = c.organization_id) = 30
    then 'PASS' else 'FAIL' end

  union all
  select '27_competencias_da_tentativa_preservadas',
    case when (
      select count(*)
      from public.assessment_competency_scores score, constants c
      where score.attempt_id = c.pilot_attempt_id
        and score.organization_id = c.organization_id
        and score.archived_at is null
    ) = 5 then 'PASS' else 'FAIL' end

  union all
  select '28_diagnostico_nao_emitiu_certificacao',
    case when not exists (
      select 1
      from public.member_certifications cert, constants c
      where cert.organization_id = c.organization_id
        and cert.source_attempt_id = c.pilot_attempt_id
        and cert.archived_at is null
    ) then 'PASS' else 'FAIL' end

  union all
  select '29_exemplo_t01_q01_justificativa_legivel',
    case when exists (
      select 1
      from public.assessment_questions q
      join private.assessment_question_keys qk
        on qk.question_id = q.id
       and qk.organization_id = q.organization_id
      cross join constants c
      where q.organization_id = c.organization_id
        and q.code = 't01_q01'
        and qk.justification like 'A Lei define consórcio exatamente como a reunião%'
    ) then 'PASS' else 'FAIL' end

  union all
  select '30_exemplo_t01_q01_referencia_legivel',
    case when exists (
      select 1
      from public.assessment_questions q
      join private.assessment_question_keys qk
        on qk.question_id = q.id
       and qk.organization_id = q.organization_id
      cross join constants c
      where q.organization_id = c.organization_id
        and q.code = 't01_q01'
        and qk.source_reference = 'Lei nº 11.795/2008 — art. 2º'
    ) then 'PASS' else 'FAIL' end
)
select check_name, status
from checks
order by check_name;
