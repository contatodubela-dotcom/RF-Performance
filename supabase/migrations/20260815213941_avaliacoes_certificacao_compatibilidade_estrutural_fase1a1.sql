begin;

-- ============================================================
-- Avaliações e Certificações
-- Arquitetura escalável — Fase 1A.1
--
-- Compatibilidade estrutural entre:
--   - modelo legado certification_levels;
--   - programas/versionamento de certificação;
--   - requisitos agrupáveis;
--   - avaliações práticas;
--   - certificações concedidas.
--
-- Nenhum dado é criado, removido ou migrado nesta fase.
-- ============================================================


-- ============================================================
-- 0. PREFLIGHT
-- ============================================================

do $$
begin
  if to_regclass('public.certification_programs') is null then
    raise exception
      'PRECONDITION_FAILED: public.certification_programs missing';
  end if;

  if to_regclass('public.certification_program_versions') is null then
    raise exception
      'PRECONDITION_FAILED: public.certification_program_versions missing';
  end if;

  if to_regclass('public.certification_requirements') is null then
    raise exception
      'PRECONDITION_FAILED: public.certification_requirements missing';
  end if;

  if to_regclass('public.member_certifications') is null then
    raise exception
      'PRECONDITION_FAILED: public.member_certifications missing';
  end if;

  if to_regclass('public.practical_assessments') is null then
    raise exception
      'PRECONDITION_FAILED: public.practical_assessments missing';
  end if;
end;
$$;


-- ============================================================
-- 1. GRUPOS LÓGICOS DE REQUISITOS
--
-- certification_program_versions.requirements_mode continua
-- sendo a regra de combinação no nível superior.
--
-- Cada grupo pode exigir:
--   all      -> todos os requisitos do grupo;
--   any      -> pelo menos um;
--   at_least -> quantidade mínima configurada.
--
-- Permite representar, por exemplo:
--
--   Grupo A: Teste 1                  [all]
--   Grupo B: Teste 2                  [all]
--   Grupo C: Caso prático / treinamento [any]
--
-- Programa: all
--
-- Resultado: A AND B AND (C OR D)
-- ============================================================

create table public.certification_requirement_groups (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  certification_program_version_id uuid not null,

  sequence_no integer not null,
  code text not null,
  name text not null,
  description text,

  group_mode text not null default 'all',
  minimum_required integer,
  is_required boolean not null default true,

  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,

  metadata jsonb not null default '{}'::jsonb,

  constraint certification_requirement_groups_version_org_fkey
    foreign key (
      certification_program_version_id,
      organization_id
    )
    references public.certification_program_versions(
      id,
      organization_id
    )
    on delete restrict,

  constraint certification_requirement_groups_created_by_fkey
    foreign key (created_by)
    references public.profiles(id)
    on delete set null,

  constraint certification_requirement_groups_updated_by_fkey
    foreign key (updated_by)
    references public.profiles(id)
    on delete set null,

  constraint certification_requirement_groups_code_key
    unique (
      organization_id,
      certification_program_version_id,
      code
    ),

  constraint certification_requirement_groups_sequence_key
    unique (
      organization_id,
      certification_program_version_id,
      sequence_no
    ),

  constraint certification_requirement_groups_id_org_key
    unique (
      id,
      organization_id
    ),

  constraint certification_requirement_groups_id_org_version_key
    unique (
      id,
      organization_id,
      certification_program_version_id
    ),

  constraint certification_requirement_groups_sequence_check
    check (sequence_no > 0),

  constraint certification_requirement_groups_code_not_blank
    check (btrim(code) <> ''),

  constraint certification_requirement_groups_name_not_blank
    check (btrim(name) <> ''),

  constraint certification_requirement_groups_mode_check
    check (
      group_mode in (
        'all',
        'any',
        'at_least'
      )
    ),

  constraint certification_requirement_groups_minimum_check
    check (
      (
        group_mode in ('all', 'any')
        and minimum_required is null
      )
      or
      (
        group_mode = 'at_least'
        and minimum_required is not null
        and minimum_required > 0
      )
    ),

  constraint certification_requirement_groups_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);


create index certification_requirement_groups_version_idx
  on public.certification_requirement_groups(
    organization_id,
    certification_program_version_id,
    sequence_no
  )
  where archived_at is null;


-- ============================================================
-- 2. VINCULAR REQUISITOS A GRUPOS
--
-- group_id permanece nullable nesta fase para compatibilidade.
-- Requisitos sem grupo podem continuar existindo até a camada
-- de avaliação dos programas ser implantada.
-- ============================================================

alter table public.certification_requirements
  add column requirement_group_id uuid;


alter table public.certification_requirements
  add constraint certification_requirements_id_org_version_key
    unique (
      id,
      organization_id,
      certification_program_version_id
    );


alter table public.certification_requirements
  add constraint certification_requirements_group_org_version_fkey
    foreign key (
      requirement_group_id,
      organization_id,
      certification_program_version_id
    )
    references public.certification_requirement_groups(
      id,
      organization_id,
      certification_program_version_id
    )
    on delete restrict;


create index certification_requirements_group_idx
  on public.certification_requirements(
    organization_id,
    requirement_group_id,
    sequence_no
  )
  where requirement_group_id is not null
    and archived_at is null;


-- ============================================================
-- 3. CERTIFICAÇÕES CONCEDIDAS
--
-- O modelo passa a suportar:
--
--   LEGADO
--   certification_level_id
--
--   NOVO
--   certification_program_id
--   certification_program_version_id
--
-- Ambos podem coexistir durante a transição.
-- Nenhuma coluna legada é removida.
-- ============================================================

alter table public.member_certifications
  add column certification_program_id uuid,
  add column certification_program_version_id uuid;


alter table public.member_certifications
  alter column certification_level_id drop not null;


alter table public.member_certifications
  add constraint member_certifications_program_org_fkey
    foreign key (
      certification_program_id,
      organization_id
    )
    references public.certification_programs(
      id,
      organization_id
    )
    on delete restrict;


alter table public.member_certifications
  add constraint member_certifications_program_version_org_program_fkey
    foreign key (
      certification_program_version_id,
      organization_id,
      certification_program_id
    )
    references public.certification_program_versions(
      id,
      organization_id,
      certification_program_id
    )
    on delete restrict;


alter table public.member_certifications
  add constraint member_certifications_program_pair_check
    check (
      (
        certification_program_id is null
        and certification_program_version_id is null
      )
      or
      (
        certification_program_id is not null
        and certification_program_version_id is not null
      )
    );


alter table public.member_certifications
  add constraint member_certifications_source_model_check
    check (
      certification_level_id is not null
      or certification_program_version_id is not null
    );


create unique index member_certifications_one_active_program_idx
  on public.member_certifications(
    organization_id,
    organization_member_id,
    certification_program_id
  )
  where status = 'active'
    and archived_at is null
    and certification_program_id is not null;


create index member_certifications_program_version_idx
  on public.member_certifications(
    organization_id,
    certification_program_version_id,
    status
  )
  where certification_program_version_id is not null;


-- ============================================================
-- 4. AVALIAÇÕES PRÁTICAS
--
-- Também passam a aceitar:
--
--   LEGADO
--   certification_level_id
--
--   NOVO
--   certification_program_id
--   certification_program_version_id
--   certification_requirement_id
--
-- O requisito, quando informado, obrigatoriamente pertence
-- à mesma versão do programa.
-- ============================================================

alter table public.practical_assessments
  add column certification_program_id uuid,
  add column certification_program_version_id uuid,
  add column certification_requirement_id uuid;


alter table public.practical_assessments
  alter column certification_level_id drop not null;


alter table public.practical_assessments
  add constraint practical_assessments_program_org_fkey
    foreign key (
      certification_program_id,
      organization_id
    )
    references public.certification_programs(
      id,
      organization_id
    )
    on delete restrict;


alter table public.practical_assessments
  add constraint practical_assessments_program_version_org_program_fkey
    foreign key (
      certification_program_version_id,
      organization_id,
      certification_program_id
    )
    references public.certification_program_versions(
      id,
      organization_id,
      certification_program_id
    )
    on delete restrict;


alter table public.practical_assessments
  add constraint practical_assessments_requirement_org_version_fkey
    foreign key (
      certification_requirement_id,
      organization_id,
      certification_program_version_id
    )
    references public.certification_requirements(
      id,
      organization_id,
      certification_program_version_id
    )
    on delete restrict;


alter table public.practical_assessments
  add constraint practical_assessments_program_pair_check
    check (
      (
        certification_program_id is null
        and certification_program_version_id is null
      )
      or
      (
        certification_program_id is not null
        and certification_program_version_id is not null
      )
    );


alter table public.practical_assessments
  add constraint practical_assessments_source_model_check
    check (
      certification_level_id is not null
      or certification_program_version_id is not null
    );


alter table public.practical_assessments
  add constraint practical_assessments_requirement_program_check
    check (
      certification_requirement_id is null
      or certification_program_version_id is not null
    );


create index practical_assessments_program_version_idx
  on public.practical_assessments(
    organization_id,
    certification_program_version_id,
    organization_member_id,
    assessed_at desc
  )
  where certification_program_version_id is not null;


create index practical_assessments_requirement_idx
  on public.practical_assessments(
    organization_id,
    certification_requirement_id,
    organization_member_id
  )
  where certification_requirement_id is not null;


-- ============================================================
-- 5. SEGURANÇA DA NOVA TABELA
-- ============================================================

alter table public.certification_requirement_groups
  enable row level security;

alter table public.certification_requirement_groups
  force row level security;


revoke all on table public.certification_requirement_groups
  from public, anon, authenticated;


-- ============================================================
-- 6. DOCUMENTAÇÃO
-- ============================================================

comment on table public.certification_requirement_groups is
  'Agrupa requisitos de uma versão de programa permitindo composição lógica all, any ou at_least.';


comment on column public.certification_requirements.requirement_group_id is
  'Grupo lógico opcional ao qual o requisito pertence.';


comment on column public.member_certifications.certification_program_id is
  'Programa genérico da certificação concedida. Nulo somente para compatibilidade com registros legados.';


comment on column public.member_certifications.certification_program_version_id is
  'Versão exata do programa sob a qual a certificação foi concedida.';


comment on column public.practical_assessments.certification_program_version_id is
  'Versão do programa à qual a avaliação prática pertence.';


comment on column public.practical_assessments.certification_requirement_id is
  'Requisito específico do programa atendido pela avaliação prática, quando aplicável.';


-- ============================================================
-- 7. PÓS-CONDIÇÕES
-- ============================================================

do $$
declare
  v_rls_invalid integer;
  v_direct_grants integer;
  v_missing_columns integer;
  v_invalid_nullability integer;
begin
  if to_regclass('public.certification_requirement_groups') is null then
    raise exception
      'POSTCONDITION_FAILED: certification_requirement_groups missing';
  end if;


  select count(*)
  into v_missing_columns
  from (
    values
      ('certification_requirements', 'requirement_group_id'),

      ('member_certifications', 'certification_program_id'),
      ('member_certifications', 'certification_program_version_id'),

      ('practical_assessments', 'certification_program_id'),
      ('practical_assessments', 'certification_program_version_id'),
      ('practical_assessments', 'certification_requirement_id')
  ) as expected(table_name, column_name)
  where not exists (
    select 1
    from information_schema.columns c
    where c.table_schema = 'public'
      and c.table_name = expected.table_name
      and c.column_name = expected.column_name
  );

  if v_missing_columns <> 0 then
    raise exception
      'POSTCONDITION_FAILED: % expected compatibility columns missing',
      v_missing_columns;
  end if;


  select count(*)
  into v_invalid_nullability
  from information_schema.columns c
  where c.table_schema = 'public'
    and (
      (
        c.table_name = 'member_certifications'
        and c.column_name = 'certification_level_id'
      )
      or
      (
        c.table_name = 'practical_assessments'
        and c.column_name = 'certification_level_id'
      )
    )
    and c.is_nullable <> 'YES';

  if v_invalid_nullability <> 0 then
    raise exception
      'POSTCONDITION_FAILED: legacy certification_level_id still NOT NULL';
  end if;


  select count(*)
  into v_rls_invalid
  from pg_class c
  join pg_namespace n
    on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'certification_requirement_groups'
    and (
      c.relrowsecurity is not true
      or c.relforcerowsecurity is not true
    );

  if v_rls_invalid <> 0 then
    raise exception
      'POSTCONDITION_FAILED: certification_requirement_groups without ENABLE+FORCE RLS';
  end if;


  select count(*)
  into v_direct_grants
  from information_schema.role_table_grants
  where table_schema = 'public'
    and table_name = 'certification_requirement_groups'
    and grantee in ('PUBLIC', 'anon', 'authenticated');

  if v_direct_grants <> 0 then
    raise exception
      'POSTCONDITION_FAILED: unexpected direct grants found: %',
      v_direct_grants;
  end if;
end;
$$;

commit;