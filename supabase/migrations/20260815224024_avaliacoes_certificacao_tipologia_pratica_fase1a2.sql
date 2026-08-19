begin;

-- ============================================================
-- Avaliações e Certificações
-- Arquitetura escalável — Fase 1A.2
--
-- Amplia a tipologia de avaliações práticas para distinguir
-- explicitamente "simulação completa" de role-play.
--
-- Nenhum registro é criado, removido ou alterado.
-- ============================================================


-- ============================================================
-- 0. PREFLIGHT
-- ============================================================

do $$
declare
  v_constraint_definition text;
  v_invalid_rows integer;
begin
  if to_regclass('public.practical_assessments') is null then
    raise exception
      'PRECONDITION_FAILED: public.practical_assessments missing';
  end if;

  select pg_get_constraintdef(c.oid)
    into v_constraint_definition
  from pg_constraint c
  where c.conrelid = 'public.practical_assessments'::regclass
    and c.conname = 'practical_assessments_type_check'
    and c.contype = 'c';

  if v_constraint_definition is null then
    raise exception
      'PRECONDITION_FAILED: practical_assessments_type_check missing';
  end if;

  if v_constraint_definition not ilike '%role_play%'
     or v_constraint_definition not ilike '%case_presentation%'
     or v_constraint_definition not ilike '%microtraining%' then
    raise exception
      'PRECONDITION_FAILED: unexpected practical assessment type constraint: %',
      v_constraint_definition;
  end if;

  select count(*)
    into v_invalid_rows
  from public.practical_assessments
  where assessment_type not in (
    'role_play',
    'case_presentation',
    'microtraining',
    'full_simulation'
  );

  if v_invalid_rows <> 0 then
    raise exception
      'PRECONDITION_FAILED: % practical assessments use unexpected assessment_type',
      v_invalid_rows;
  end if;
end;
$$;


-- ============================================================
-- 1. AMPLIAR TIPOLOGIA
-- ============================================================

alter table public.practical_assessments
  drop constraint practical_assessments_type_check;


alter table public.practical_assessments
  add constraint practical_assessments_type_check
  check (
    assessment_type in (
      'role_play',
      'case_presentation',
      'microtraining',
      'full_simulation'
    )
  );


comment on column public.practical_assessments.assessment_type is
  'Tipo de avaliação prática: role_play, case_presentation, microtraining ou full_simulation.';


-- ============================================================
-- 2. PÓS-CONDIÇÕES
-- ============================================================

do $$
declare
  v_constraint_definition text;
  v_invalid_rows integer;
begin
  select pg_get_constraintdef(c.oid)
    into v_constraint_definition
  from pg_constraint c
  where c.conrelid = 'public.practical_assessments'::regclass
    and c.conname = 'practical_assessments_type_check'
    and c.contype = 'c';

  if v_constraint_definition is null then
    raise exception
      'POSTCONDITION_FAILED: practical_assessments_type_check missing';
  end if;

  if v_constraint_definition not ilike '%role_play%'
     or v_constraint_definition not ilike '%case_presentation%'
     or v_constraint_definition not ilike '%microtraining%'
     or v_constraint_definition not ilike '%full_simulation%' then
    raise exception
      'POSTCONDITION_FAILED: practical assessment types incomplete: %',
      v_constraint_definition;
  end if;

  select count(*)
    into v_invalid_rows
  from public.practical_assessments
  where assessment_type not in (
    'role_play',
    'case_presentation',
    'microtraining',
    'full_simulation'
  );

  if v_invalid_rows <> 0 then
    raise exception
      'POSTCONDITION_FAILED: % practical assessments violate new type constraint',
      v_invalid_rows;
  end if;
end;
$$;

commit;