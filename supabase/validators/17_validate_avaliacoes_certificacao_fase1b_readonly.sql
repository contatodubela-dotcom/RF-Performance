-- Validador somente leitura — Avaliações e Certificações Fase 1B
-- Deve retornar 20 linhas com status PASS.

with checks as (
  select '01_organizacao_rf'::text as check_name, (select count(*)=1 from public.organizations where id='414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid and slug='rf-consorcios' and status='active' and archived_at is null) as ok
  union all
  select '02_niveis_3'::text as check_name, (select count(*)=3 from public.certification_levels where organization_id='414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid and archived_at is null) as ok
  union all
  select '03_competencias_30'::text as check_name, (select count(*)=30 from public.competency_domains where organization_id='414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid and archived_at is null) as ok
  union all
  select '04_testes_5'::text as check_name, (select count(*)=5 from public.assessment_tests where organization_id='414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid and archived_at is null) as ok
  union all
  select '05_versoes_5'::text as check_name, (select count(*)=5 from public.assessment_test_versions where organization_id='414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid and archived_at is null) as ok
  union all
  select '06_questoes_150'::text as check_name, (select count(*)=150 from public.assessment_questions where organization_id='414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid and archived_at is null) as ok
  union all
  select '07_alternativas_600'::text as check_name, (select count(*)=600 from public.assessment_question_options where organization_id='414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid and archived_at is null) as ok
  union all
  select '08_vinculos_150'::text as check_name, (select count(*)=150 from public.assessment_version_questions where organization_id='414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid and archived_at is null) as ok
  union all
  select '09_gabaritos_150'::text as check_name, (select count(*)=150 from private.assessment_question_keys where organization_id='414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid) as ok
  union all
  select '10_quatro_opcoes_por_questao'::text as check_name, (select count(*)=0 from (select q.id from public.assessment_questions q left join public.assessment_question_options o on o.question_id=q.id and o.organization_id=q.organization_id and o.archived_at is null where q.organization_id='414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid and q.archived_at is null group by q.id having count(o.id)<>4) x) as ok
  union all
  select '11_trinta_questoes_por_teste'::text as check_name, (select count(*)=5 from (select tv.id from public.assessment_test_versions tv join public.assessment_version_questions vq on vq.test_version_id=tv.id and vq.organization_id=tv.organization_id and vq.archived_at is null where tv.organization_id='414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid and tv.archived_at is null group by tv.id having count(vq.id)=30) x) as ok
  union all
  select '12_nenhuma_versao_publicada'::text as check_name, (select count(*)=0 from public.assessment_test_versions where organization_id='414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid and status='published' and archived_at is null) as ok
  union all
  select '13_testes_em_rascunho'::text as check_name, (select count(*)=5 from public.assessment_tests where organization_id='414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid and status='draft' and archived_at is null) as ok
  union all
  select '14_questoes_revisadas'::text as check_name, (select count(*)=150 from public.assessment_questions where organization_id='414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid and status='reviewed' and archived_at is null) as ok
  union all
  select '15_criticos_eliminatorios_desativados'::text as check_name, (select count(*)=0 from private.assessment_question_keys where organization_id='414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid and is_critical) as ok
  union all
  select '16_marcacoes_criticas_pendentes_96'::text as check_name, (select count(*)=96 from private.assessment_question_keys where organization_id='414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid and metadata ->> 'source_critical_flag'='true' and metadata ->> 'critical_review_status'='pending_manual_homologation') as ok
  union all
  select '17_distribuicao_gabarito'::text as check_name, (select coalesce(bool_and(expected=actual),false) from (values ('A',38),('B',38),('C',37),('D',37)) e(code,expected) left join (select correct_option_code code,count(*)::int actual from private.assessment_question_keys where organization_id='414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid group by correct_option_code) a using(code)) as ok
  union all
  select '18_sem_tentativas'::text as check_name, (select count(*)=0 from public.assessment_attempts where organization_id='414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid) as ok
  union all
  select '19_sem_certificacoes'::text as check_name, (select count(*)=0 from public.member_certifications where organization_id='414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid) as ok
  union all
  select '20_sha_fonte_consistente'::text as check_name, (select count(*)=150 from public.assessment_questions where organization_id='414a2e84-bc62-4c64-99ee-76db1cbc4654'::uuid and metadata ->> 'source_sha256'='e3ba2f891bf274be34439dc3e0007f0d9d3768b91c45f1a44aecae5197c852ab') as ok
)
select check_name, case when ok then 'PASS' else 'FAIL' end as status
from checks
order by check_name;
