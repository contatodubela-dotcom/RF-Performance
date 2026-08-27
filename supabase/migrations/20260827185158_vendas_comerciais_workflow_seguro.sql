-- ============================================================================
-- VENDAS COMERCIAIS — WORKFLOW SEGURO
-- Migration: 20260827185158_vendas_comerciais_workflow_seguro.sql
--
-- Objetivos:
--   1. remover INSERT/UPDATE diretos de authenticated em commercial_sales;
--   2. preservar SELECT sujeito à RLS já existente;
--   3. manter service_role fora deste hardening para integrações/importações;
--   4. criar RPCs controladas para:
--        - lançar venda pendente;
--        - corrigir venda pendente;
--        - alterar status com transições explícitas;
--   5. garantir autoria de validação no backend;
--   6. preservar auditoria e validações estruturais já existentes.
--
-- Perfis humanos autorizados a escrever:
--   - platform_admin;
--   - director da organização da venda.
--
-- Supervisor permanece somente leitura conforme a RLS existente.
-- Salesperson permanece sem leitura transacional.
-- ============================================================================

begin;

-- ============================================================================
-- 0. PREFLIGHT
-- ============================================================================

do $$
declare
  v_missing_columns text[];
begin
  if pg_catalog.to_regclass('public.commercial_sales') is null then
    raise exception
      'WORKFLOW_VENDAS_ABORTADO: public.commercial_sales não existe.';
  end if;

  select pg_catalog.array_agg(required.column_name order by required.column_name)
  into v_missing_columns
  from (
    values
      ('id'),
      ('organization_id'),
      ('operation_id'),
      ('sales_location_id'),
      ('team_id'),
      ('salesperson_member_id'),
      ('sale_date'),
      ('competence_month'),
      ('units_count'),
      ('validation_status'),
      ('validated_at'),
      ('validated_by'),
      ('status_reason'),
      ('source_system'),
      ('external_id'),
      ('created_at'),
      ('created_by'),
      ('updated_at'),
      ('updated_by'),
      ('archived_at'),
      ('metadata')
  ) as required(column_name)
  where not exists (
    select 1
    from information_schema.columns c
    where c.table_schema = 'public'
      and c.table_name = 'commercial_sales'
      and c.column_name = required.column_name
  );

  if v_missing_columns is not null then
    raise exception
      'WORKFLOW_VENDAS_ABORTADO: colunas ausentes em public.commercial_sales: %',
      v_missing_columns;
  end if;

  if pg_catalog.to_regprocedure(
    'private.is_platform_admin()'
  ) is null then
    raise exception
      'WORKFLOW_VENDAS_ABORTADO: private.is_platform_admin() não existe.';
  end if;

  if pg_catalog.to_regprocedure(
    'private.has_org_role(uuid,text[])'
  ) is null then
    raise exception
      'WORKFLOW_VENDAS_ABORTADO: private.has_org_role(uuid,text[]) não existe.';
  end if;
end;
$$;

-- ============================================================================
-- 1. HARDENING DE PRIVILÉGIOS DIRETOS
--
-- authenticated continua podendo SELECT conforme as policies existentes.
-- Escritas humanas passam exclusivamente pelas RPCs abaixo.
-- service_role não é alterado por esta migration.
-- ============================================================================

revoke insert, update, delete, truncate, references, trigger
on table public.commercial_sales
from authenticated;

revoke all
on table public.commercial_sales
from anon;

grant select
on table public.commercial_sales
to authenticated;

-- ============================================================================
-- 2. RPC — LANÇAR VENDA PENDENTE
--
-- Regras:
--   - somente platform_admin ou director da organização;
--   - status nasce sempre como pending;
--   - validated_at / validated_by nascem NULL;
--   - competence_month é derivada de sale_date;
--   - source_system humano é fixado em rf_performance;
--   - integrações/importações continuam podendo usar service_role diretamente.
-- ============================================================================

create or replace function public.create_commercial_sale(
  p_organization_id uuid,
  p_operation_id uuid,
  p_sales_location_id uuid,
  p_team_id uuid,
  p_sale_date date,
  p_units_count integer default 1,
  p_salesperson_member_id uuid default null,
  p_external_id text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_actor uuid := auth.uid();
  v_created public.commercial_sales%rowtype;
  v_metadata jsonb := coalesce(p_metadata, '{}'::jsonb);
begin
  if v_actor is null then
    raise exception 'AUTH_REQUIRED'
      using errcode = '42501';
  end if;

  if p_organization_id is null then
    raise exception 'COMMERCIAL_SALE_ORGANIZATION_REQUIRED'
      using errcode = '22023';
  end if;

  if not (
    private.is_platform_admin()
    or private.has_org_role(
      p_organization_id,
      array['director']::text[]
    )
  ) then
    raise exception 'COMMERCIAL_SALE_MANAGEMENT_FORBIDDEN'
      using errcode = '42501';
  end if;

  if p_operation_id is null
     or p_sales_location_id is null
     or p_team_id is null
     or p_sale_date is null then
    raise exception 'COMMERCIAL_SALE_REQUIRED_FIELDS_MISSING'
      using errcode = '22023';
  end if;

  if p_units_count is null or p_units_count < 1 then
    raise exception 'COMMERCIAL_SALE_UNITS_INVALID'
      using errcode = '22023';
  end if;

  if pg_catalog.jsonb_typeof(v_metadata) <> 'object' then
    raise exception 'COMMERCIAL_SALE_METADATA_INVALID'
      using errcode = '22023';
  end if;

  insert into public.commercial_sales (
    organization_id,
    operation_id,
    sales_location_id,
    team_id,
    salesperson_member_id,
    sale_date,
    competence_month,
    units_count,
    validation_status,
    validated_at,
    validated_by,
    status_reason,
    source_system,
    external_id,
    created_by,
    updated_by,
    metadata
  )
  values (
    p_organization_id,
    p_operation_id,
    p_sales_location_id,
    p_team_id,
    p_salesperson_member_id,
    p_sale_date,
    pg_catalog.date_trunc(
      'month',
      p_sale_date::timestamp
    )::date,
    p_units_count,
    'pending',
    null,
    null,
    null,
    'rf_performance',
    nullif(pg_catalog.btrim(p_external_id), ''),
    v_actor,
    v_actor,
    v_metadata || pg_catalog.jsonb_build_object(
      'workflow_source',
      'public.create_commercial_sale'
    )
  )
  returning *
  into v_created;

  return pg_catalog.jsonb_build_object(
    'id', v_created.id,
    'organization_id', v_created.organization_id,
    'sale_date', v_created.sale_date,
    'competence_month', v_created.competence_month,
    'validation_status', v_created.validation_status,
    'affected', 1
  );
end;
$function$;

revoke all on function
  public.create_commercial_sale(
    uuid,
    uuid,
    uuid,
    uuid,
    date,
    integer,
    uuid,
    text,
    jsonb
  )
from public, anon, authenticated;

grant execute on function
  public.create_commercial_sale(
    uuid,
    uuid,
    uuid,
    uuid,
    date,
    integer,
    uuid,
    text,
    jsonb
  )
to authenticated;

comment on function public.create_commercial_sale(
  uuid,
  uuid,
  uuid,
  uuid,
  date,
  integer,
  uuid,
  text,
  jsonb
) is
  'Cria uma venda comercial pendente. Escrita humana restrita a platform_admin ou director; competência é derivada da data da venda.';

-- ============================================================================
-- 3. RPC — CORRIGIR VENDA PENDENTE
--
-- Regras:
--   - somente platform_admin ou director da organização da venda;
--   - somente registros pending podem ser corrigidos;
--   - não altera organization_id;
--   - não altera status/validated_at/validated_by;
--   - competence_month é recalculada a partir de sale_date.
-- ============================================================================

create or replace function public.update_pending_commercial_sale(
  p_sale_id uuid,
  p_operation_id uuid,
  p_sales_location_id uuid,
  p_team_id uuid,
  p_sale_date date,
  p_units_count integer,
  p_salesperson_member_id uuid default null,
  p_external_id text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_actor uuid := auth.uid();
  v_existing public.commercial_sales%rowtype;
  v_updated public.commercial_sales%rowtype;
  v_metadata jsonb := coalesce(p_metadata, '{}'::jsonb);
begin
  if v_actor is null then
    raise exception 'AUTH_REQUIRED'
      using errcode = '42501';
  end if;

  if p_sale_id is null then
    raise exception 'COMMERCIAL_SALE_ID_REQUIRED'
      using errcode = '22023';
  end if;

  select cs.*
  into v_existing
  from public.commercial_sales cs
  where cs.id = p_sale_id
    and cs.archived_at is null
  for update;

  if not found then
    raise exception 'COMMERCIAL_SALE_NOT_FOUND'
      using errcode = 'P0002';
  end if;

  if not (
    private.is_platform_admin()
    or private.has_org_role(
      v_existing.organization_id,
      array['director']::text[]
    )
  ) then
    raise exception 'COMMERCIAL_SALE_MANAGEMENT_FORBIDDEN'
      using errcode = '42501';
  end if;

  if v_existing.validation_status <> 'pending' then
    raise exception 'COMMERCIAL_SALE_UPDATE_REQUIRES_PENDING_STATUS'
      using errcode = '22023';
  end if;

  if p_operation_id is null
     or p_sales_location_id is null
     or p_team_id is null
     or p_sale_date is null then
    raise exception 'COMMERCIAL_SALE_REQUIRED_FIELDS_MISSING'
      using errcode = '22023';
  end if;

  if p_units_count is null or p_units_count < 1 then
    raise exception 'COMMERCIAL_SALE_UNITS_INVALID'
      using errcode = '22023';
  end if;

  if pg_catalog.jsonb_typeof(v_metadata) <> 'object' then
    raise exception 'COMMERCIAL_SALE_METADATA_INVALID'
      using errcode = '22023';
  end if;

  update public.commercial_sales cs
  set
    operation_id = p_operation_id,
    sales_location_id = p_sales_location_id,
    team_id = p_team_id,
    salesperson_member_id = p_salesperson_member_id,
    sale_date = p_sale_date,
    competence_month = pg_catalog.date_trunc(
      'month',
      p_sale_date::timestamp
    )::date,
    units_count = p_units_count,
    external_id = nullif(pg_catalog.btrim(p_external_id), ''),
    status_reason = null,
    updated_by = v_actor,
    metadata = v_metadata || pg_catalog.jsonb_build_object(
      'workflow_source',
      'public.update_pending_commercial_sale'
    )
  where cs.id = p_sale_id
  returning *
  into v_updated;

  return pg_catalog.jsonb_build_object(
    'id', v_updated.id,
    'organization_id', v_updated.organization_id,
    'sale_date', v_updated.sale_date,
    'competence_month', v_updated.competence_month,
    'validation_status', v_updated.validation_status,
    'affected', 1
  );
end;
$function$;

revoke all on function
  public.update_pending_commercial_sale(
    uuid,
    uuid,
    uuid,
    uuid,
    date,
    integer,
    uuid,
    text,
    jsonb
  )
from public, anon, authenticated;

grant execute on function
  public.update_pending_commercial_sale(
    uuid,
    uuid,
    uuid,
    uuid,
    date,
    integer,
    uuid,
    text,
    jsonb
  )
to authenticated;

comment on function public.update_pending_commercial_sale(
  uuid,
  uuid,
  uuid,
  uuid,
  date,
  integer,
  uuid,
  text,
  jsonb
) is
  'Corrige dados de uma venda enquanto ela permanece pending. Não permite alterar diretamente campos de validação.';

-- ============================================================================
-- 4. RPC — ALTERAR STATUS DA VENDA
--
-- Transições permitidas:
--   pending   -> validated | rejected | cancelled
--   rejected  -> pending
--   validated -> cancelled
--   cancelled -> terminal
--
-- A repetição do mesmo status é idempotente e retorna affected = 0.
--
-- Regras de autoria:
--   - validated preenche validated_at e validated_by no backend;
--   - rejected limpa validated_at/validated_by;
--   - pending reaberto limpa validated_at/validated_by e status_reason;
--   - cancelled exige motivo;
--   - ao cancelar uma venda já validada, validated_at/validated_by são
--     preservados como evidência histórica; o audit log registra a transição.
-- ============================================================================

create or replace function public.change_commercial_sale_status(
  p_sale_id uuid,
  p_target_status text,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_actor uuid := auth.uid();
  v_existing public.commercial_sales%rowtype;
  v_updated public.commercial_sales%rowtype;
  v_target_status text := pg_catalog.lower(
    pg_catalog.btrim(coalesce(p_target_status, ''))
  );
  v_reason text := nullif(
    pg_catalog.btrim(coalesce(p_reason, '')),
    ''
  );
begin
  if v_actor is null then
    raise exception 'AUTH_REQUIRED'
      using errcode = '42501';
  end if;

  if p_sale_id is null then
    raise exception 'COMMERCIAL_SALE_ID_REQUIRED'
      using errcode = '22023';
  end if;

  if v_target_status not in (
    'pending',
    'validated',
    'rejected',
    'cancelled'
  ) then
    raise exception 'COMMERCIAL_SALE_TARGET_STATUS_INVALID'
      using errcode = '22023';
  end if;

  select cs.*
  into v_existing
  from public.commercial_sales cs
  where cs.id = p_sale_id
    and cs.archived_at is null
  for update;

  if not found then
    raise exception 'COMMERCIAL_SALE_NOT_FOUND'
      using errcode = 'P0002';
  end if;

  if not (
    private.is_platform_admin()
    or private.has_org_role(
      v_existing.organization_id,
      array['director']::text[]
    )
  ) then
    raise exception 'COMMERCIAL_SALE_MANAGEMENT_FORBIDDEN'
      using errcode = '42501';
  end if;

  if v_existing.validation_status = v_target_status then
    return pg_catalog.jsonb_build_object(
      'id', v_existing.id,
      'organization_id', v_existing.organization_id,
      'previous_status', v_existing.validation_status,
      'validation_status', v_existing.validation_status,
      'validated_at', v_existing.validated_at,
      'validated_by', v_existing.validated_by,
      'affected', 0
    );
  end if;

  if not (
    (
      v_existing.validation_status = 'pending'
      and v_target_status in (
        'validated',
        'rejected',
        'cancelled'
      )
    )
    or (
      v_existing.validation_status = 'rejected'
      and v_target_status = 'pending'
    )
    or (
      v_existing.validation_status = 'validated'
      and v_target_status = 'cancelled'
    )
  ) then
    raise exception
      'COMMERCIAL_SALE_STATUS_TRANSITION_INVALID: % -> %',
      v_existing.validation_status,
      v_target_status
      using errcode = '22023';
  end if;

  if v_target_status in ('rejected', 'cancelled')
     and v_reason is null then
    raise exception 'COMMERCIAL_SALE_STATUS_REASON_REQUIRED'
      using errcode = '22023';
  end if;

  update public.commercial_sales cs
  set
    validation_status = v_target_status,

    validated_at = case
      when v_target_status = 'validated'
        then pg_catalog.now()
      when v_target_status in ('pending', 'rejected')
        then null
      else cs.validated_at
    end,

    validated_by = case
      when v_target_status = 'validated'
        then v_actor
      when v_target_status in ('pending', 'rejected')
        then null
      else cs.validated_by
    end,

    status_reason = case
      when v_target_status in ('rejected', 'cancelled')
        then v_reason
      else null
    end,

    updated_by = v_actor,

    metadata = cs.metadata || pg_catalog.jsonb_build_object(
      'workflow_source',
      'public.change_commercial_sale_status',
      'last_status_transition_at',
      pg_catalog.now(),
      'last_status_transition_by',
      v_actor
    )
  where cs.id = p_sale_id
  returning *
  into v_updated;

  return pg_catalog.jsonb_build_object(
    'id', v_updated.id,
    'organization_id', v_updated.organization_id,
    'previous_status', v_existing.validation_status,
    'validation_status', v_updated.validation_status,
    'validated_at', v_updated.validated_at,
    'validated_by', v_updated.validated_by,
    'status_reason', v_updated.status_reason,
    'affected', 1
  );
end;
$function$;

revoke all on function
  public.change_commercial_sale_status(
    uuid,
    text,
    text
  )
from public, anon, authenticated;

grant execute on function
  public.change_commercial_sale_status(
    uuid,
    text,
    text
  )
to authenticated;

comment on function public.change_commercial_sale_status(
  uuid,
  text,
  text
) is
  'Executa transições controladas do workflow de commercial_sales e registra autoria de validação no backend.';

-- ============================================================================
-- 5. PÓS-CHECK
-- ============================================================================

do $$
declare
  v_function regprocedure;
begin
  if not pg_catalog.has_table_privilege(
    'authenticated',
    'public.commercial_sales',
    'SELECT'
  ) then
    raise exception
      'WORKFLOW_VENDAS_INVALIDO: authenticated perdeu SELECT em commercial_sales.';
  end if;

  if pg_catalog.has_table_privilege(
    'authenticated',
    'public.commercial_sales',
    'INSERT'
  ) then
    raise exception
      'WORKFLOW_VENDAS_INVALIDO: authenticated ainda possui INSERT direto em commercial_sales.';
  end if;

  if pg_catalog.has_table_privilege(
    'authenticated',
    'public.commercial_sales',
    'UPDATE'
  ) then
    raise exception
      'WORKFLOW_VENDAS_INVALIDO: authenticated ainda possui UPDATE direto em commercial_sales.';
  end if;

  if pg_catalog.has_table_privilege(
    'anon',
    'public.commercial_sales',
    'SELECT'
  )
  or pg_catalog.has_table_privilege(
    'anon',
    'public.commercial_sales',
    'INSERT'
  )
  or pg_catalog.has_table_privilege(
    'anon',
    'public.commercial_sales',
    'UPDATE'
  ) then
    raise exception
      'WORKFLOW_VENDAS_INVALIDO: anon possui privilégio indevido em commercial_sales.';
  end if;

  foreach v_function in array array[
    pg_catalog.to_regprocedure(
      'public.create_commercial_sale(uuid,uuid,uuid,uuid,date,integer,uuid,text,jsonb)'
    ),
    pg_catalog.to_regprocedure(
      'public.update_pending_commercial_sale(uuid,uuid,uuid,uuid,date,integer,uuid,text,jsonb)'
    ),
    pg_catalog.to_regprocedure(
      'public.change_commercial_sale_status(uuid,text,text)'
    )
  ]
  loop
    if v_function is null then
      raise exception
        'WORKFLOW_VENDAS_INVALIDO: RPC esperada ausente.';
    end if;

    if not (
      select p.prosecdef
      from pg_catalog.pg_proc p
      where p.oid = v_function
    ) then
      raise exception
        'WORKFLOW_VENDAS_INVALIDO: RPC % não ficou SECURITY DEFINER.',
        v_function;
    end if;

    if not pg_catalog.has_function_privilege(
      'authenticated',
      v_function,
      'EXECUTE'
    ) then
      raise exception
        'WORKFLOW_VENDAS_INVALIDO: authenticated sem EXECUTE em %.',
        v_function;
    end if;

    if pg_catalog.has_function_privilege(
      'anon',
      v_function,
      'EXECUTE'
    ) then
      raise exception
        'WORKFLOW_VENDAS_INVALIDO: anon possui EXECUTE indevido em %.',
        v_function;
    end if;
  end loop;
end;
$$;

commit;
