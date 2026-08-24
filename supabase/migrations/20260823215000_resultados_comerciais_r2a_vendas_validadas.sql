-- ============================================================================
-- RF PERFORMANCE
-- RESULTADOS COMERCIAIS — R2A
-- FUNDAÇÃO TRANSACIONAL DE VENDAS VALIDADAS
--
-- Objetivo:
--   Criar a fonte transacional auditável que servirá de base para a apuração
--   de `validated_sales` por organização, PDV e equipe.
--
-- Princípios:
--   - commercial_sales é a fonte de verdade transacional.
--   - performance_goals.actual_value NÃO é atualizado por trigger nesta fase.
--   - nenhuma venda é apagada pelo fluxo normal; cancelamentos são status.
--   - competência mensal é explícita e independente da data de validação.
--   - RLS segue o padrão de escopo já existente no RF Performance.
--
-- Rollback:
--   A migration é transacional (BEGIN/COMMIT). Qualquer erro antes do COMMIT
--   reverte toda a execução. Depois de aplicada, eventual reversão deve ser
--   feita por migration compensatória própria; não executar DROP manualmente.
-- ============================================================================

begin;

-- ============================================================================
-- 0. PREFLIGHT
-- ============================================================================

do $$
begin
  if to_regclass('public.commercial_sales') is not null then
    raise exception
      'R2A abortada: public.commercial_sales já existe.';
  end if;

  if to_regclass('public.organizations') is null
     or to_regclass('public.operations') is null
     or to_regclass('public.sales_locations') is null
     or to_regclass('public.teams') is null
     or to_regclass('public.profiles') is null then
    raise exception
      'R2A abortada: uma ou mais tabelas-base obrigatórias não existem.';
  end if;

  if to_regprocedure('private.set_row_metadata()') is null then
    raise exception
      'R2A abortada: private.set_row_metadata() não existe.';
  end if;

  if to_regprocedure('private.guard_organization_scope()') is null then
    raise exception
      'R2A abortada: private.guard_organization_scope() não existe.';
  end if;

  if to_regprocedure('private.write_audit_log()') is null then
    raise exception
      'R2A abortada: private.write_audit_log() não existe.';
  end if;

  if to_regprocedure('private.is_platform_admin()') is null
     or to_regprocedure('private.has_org_role(uuid,text[])') is null
     or to_regprocedure('private.managed_team_ids()') is null
     or to_regprocedure('private.managed_location_ids()') is null then
    raise exception
      'R2A abortada: funções de autorização/escopo obrigatórias não existem.';
  end if;
end;
$$;

-- ============================================================================
-- 1. TABELA TRANSACIONAL
-- ============================================================================

create table public.commercial_sales (
  id uuid primary key default gen_random_uuid(),

  organization_id uuid not null,
  operation_id uuid not null,
  sales_location_id uuid not null,
  team_id uuid not null,

  sale_date date not null,
  competence_month date not null,

  -- Uma linha pode representar uma ou mais unidades/cotas da mesma origem.
  -- Na R2B, validated_sales deverá somar units_count das linhas validadas.
  units_count integer not null default 1,

  validation_status text not null default 'pending',
  validated_at timestamptz,
  validated_by uuid,
  status_reason text,

  source_system text not null default 'rf_performance',
  external_id text,

  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  archived_at timestamptz,

  metadata jsonb not null default '{}'::jsonb,

  constraint commercial_sales_organization_id_fkey
    foreign key (organization_id)
    references public.organizations(id)
    on delete restrict,

  constraint commercial_sales_operation_org_fkey
    foreign key (operation_id, organization_id)
    references public.operations(id, organization_id)
    on delete restrict,

  constraint commercial_sales_location_org_operation_fkey
    foreign key (sales_location_id, organization_id, operation_id)
    references public.sales_locations(id, organization_id, operation_id)
    on delete restrict,

  constraint commercial_sales_team_org_fkey
    foreign key (team_id, organization_id)
    references public.teams(id, organization_id)
    on delete restrict,

  constraint commercial_sales_validated_by_fkey
    foreign key (validated_by)
    references public.profiles(id)
    on delete set null,

  constraint commercial_sales_created_by_fkey
    foreign key (created_by)
    references public.profiles(id)
    on delete set null,

  constraint commercial_sales_updated_by_fkey
    foreign key (updated_by)
    references public.profiles(id)
    on delete set null,

  constraint commercial_sales_units_count_check
    check (units_count >= 1),

  constraint commercial_sales_competence_month_check
    check (
      competence_month =
      date_trunc('month', competence_month::timestamp)::date
    ),

  constraint commercial_sales_validation_status_check
    check (
      validation_status in (
        'pending',
        'validated',
        'rejected',
        'cancelled'
      )
    ),

  constraint commercial_sales_validated_timestamp_check
    check (
      validation_status <> 'validated'
      or validated_at is not null
    ),

  constraint commercial_sales_source_system_check
    check (
      source_system in (
        'rf_performance',
        'epsa_core',
        'mci_consorcio',
        'manual_import',
        'spreadsheet_import',
        'api'
      )
    ),

  constraint commercial_sales_metadata_object_check
    check (jsonb_typeof(metadata) = 'object')
);

comment on table public.commercial_sales is
  'Fonte transacional auditável das vendas/cotas comerciais usadas na apuração de validated_sales.';

comment on column public.commercial_sales.competence_month is
  'Primeiro dia do mês de competência comercial da venda.';

comment on column public.commercial_sales.units_count is
  'Quantidade de unidades/cotas representadas pela linha; validated_sales soma este campo apenas para registros validados.';

comment on column public.commercial_sales.validation_status is
  'Estado de validação da venda: pending, validated, rejected ou cancelled.';

-- ============================================================================
-- 2. ÍNDICES
-- ============================================================================

create index commercial_sales_org_competence_status_idx
  on public.commercial_sales (
    organization_id,
    competence_month,
    validation_status
  );

create index commercial_sales_org_location_competence_status_idx
  on public.commercial_sales (
    organization_id,
    sales_location_id,
    competence_month,
    validation_status
  );

create index commercial_sales_org_team_competence_status_idx
  on public.commercial_sales (
    organization_id,
    team_id,
    competence_month,
    validation_status
  );

create index commercial_sales_operation_competence_idx
  on public.commercial_sales (
    operation_id,
    competence_month
  );

create unique index commercial_sales_source_external_uidx
  on public.commercial_sales (
    organization_id,
    source_system,
    external_id
  )
  where external_id is not null;

-- ============================================================================
-- 3. VALIDAÇÃO DA HIERARQUIA COMERCIAL
-- ============================================================================

create or replace function private.validate_commercial_sale_scope()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1
    from public.operations o
    where o.id = new.operation_id
      and o.organization_id = new.organization_id
  ) then
    raise exception using
      errcode = '23514',
      message = 'Operação da venda não pertence à organização.';
  end if;

  if not exists (
    select 1
    from public.sales_locations sl
    where sl.id = new.sales_location_id
      and sl.organization_id = new.organization_id
      and sl.operation_id = new.operation_id
  ) then
    raise exception using
      errcode = '23514',
      message = 'PDV da venda não pertence à organização/operação informada.';
  end if;

  if not exists (
    select 1
    from public.teams t
    where t.id = new.team_id
      and t.organization_id = new.organization_id
      and t.operation_id = new.operation_id
  ) then
    raise exception using
      errcode = '23514',
      message = 'Equipe da venda não pertence à organização/operação informada.';
  end if;

  if not exists (
    select 1
    from public.teams t
    where t.id = new.team_id
      and t.organization_id = new.organization_id
      and t.operation_id = new.operation_id
      and t.sales_location_id = new.sales_location_id
  ) then
    raise exception using
      errcode = '23514',
      message = 'Equipe da venda não pertence ao PDV informado.';
  end if;

  return new;
end;
$$;

revoke all on function private.validate_commercial_sale_scope()
  from public, anon, authenticated;

-- ============================================================================
-- 4. VISIBILIDADE RLS
--
-- Nesta fundação:
--   - platform_admin vê todas as vendas;
--   - director vê as vendas da organização;
--   - supervisor vê somente vendas das equipes sob sua gestão;
--     (não ampliamos a leitura transacional para todo o PDV, evitando que um
--      supervisor veja vendas de outra equipe que compartilhe o mesmo PDV);
--   - salesperson NÃO recebe leitura transacional nesta fase.
-- ============================================================================

create or replace function private.can_view_commercial_sale(
  p_organization_id uuid,
  p_sales_location_id uuid,
  p_team_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    private.is_platform_admin()
    or private.has_org_role(
      p_organization_id,
      array['director']
    )
    or p_team_id in (
      select private.managed_team_ids()
    );
$$;

revoke all on function private.can_view_commercial_sale(uuid, uuid, uuid)
  from public, anon;

grant execute on function private.can_view_commercial_sale(uuid, uuid, uuid)
  to authenticated;

-- ============================================================================
-- 5. TRIGGERS DE METADADOS, ESCOPO E AUDITORIA
-- ============================================================================

create trigger commercial_sales_set_row_metadata
before insert or update on public.commercial_sales
for each row execute function private.set_row_metadata();

create trigger commercial_sales_guard_org
before update on public.commercial_sales
for each row execute function private.guard_organization_scope();

create trigger commercial_sales_validate_scope
before insert or update of
  organization_id,
  operation_id,
  sales_location_id,
  team_id
on public.commercial_sales
for each row execute function private.validate_commercial_sale_scope();

create trigger commercial_sales_audit
after insert or update or delete on public.commercial_sales
for each row execute function private.write_audit_log();

-- ============================================================================
-- 6. RLS, GRANTS E POLICIES
-- ============================================================================

alter table public.commercial_sales enable row level security;

revoke all on table public.commercial_sales
  from anon, authenticated;

grant select, insert, update on table public.commercial_sales
  to authenticated;

create policy commercial_sales_select_authorized
on public.commercial_sales
for select
to authenticated
using (
  private.can_view_commercial_sale(
    organization_id,
    sales_location_id,
    team_id
  )
);

create policy commercial_sales_manage_leadership
on public.commercial_sales
for all
to authenticated
using (
  private.is_platform_admin()
  or private.has_org_role(
    organization_id,
    array['director']
  )
)
with check (
  private.is_platform_admin()
  or private.has_org_role(
    organization_id,
    array['director']
  )
);

-- ============================================================================
-- 7. PÓS-CHECK ESTRUTURAL
-- ============================================================================

do $$
declare
  v_rls_enabled boolean;
  v_expected_policies integer;
  v_expected_triggers integer;
begin
  select c.relrowsecurity
    into v_rls_enabled
  from pg_class c
  join pg_namespace n
    on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'commercial_sales';

  if coalesce(v_rls_enabled, false) is not true then
    raise exception
      'R2A inválida: RLS não ficou habilitada em public.commercial_sales.';
  end if;

  select count(*)
    into v_expected_policies
  from pg_policies
  where schemaname = 'public'
    and tablename = 'commercial_sales'
    and policyname in (
      'commercial_sales_select_authorized',
      'commercial_sales_manage_leadership'
    );

  if v_expected_policies <> 2 then
    raise exception
      'R2A inválida: policies esperadas de commercial_sales não foram criadas.';
  end if;

  select count(*)
    into v_expected_triggers
  from pg_trigger t
  join pg_class c
    on c.oid = t.tgrelid
  join pg_namespace n
    on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'commercial_sales'
    and not t.tgisinternal
    and t.tgname in (
      'commercial_sales_set_row_metadata',
      'commercial_sales_guard_org',
      'commercial_sales_validate_scope',
      'commercial_sales_audit'
    );

  if v_expected_triggers <> 4 then
    raise exception
      'R2A inválida: triggers esperados de commercial_sales não foram criados.';
  end if;

  if to_regprocedure(
    'private.can_view_commercial_sale(uuid,uuid,uuid)'
  ) is null then
    raise exception
      'R2A inválida: private.can_view_commercial_sale() não foi criada.';
  end if;

  if to_regprocedure(
    'private.validate_commercial_sale_scope()'
  ) is null then
    raise exception
      'R2A inválida: private.validate_commercial_sale_scope() não foi criada.';
  end if;
end;
$$;

commit;
